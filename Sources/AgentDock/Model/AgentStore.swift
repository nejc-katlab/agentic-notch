import Combine
import SwiftUI

@MainActor
final class AgentStore: ObservableObject {
    @Published private(set) var sessions: [AgentSession] = []
    @Published var autoExpandOnAttention: Bool = true
    @Published var sleepPreventionMode: SleepPreventionMode = .never

    private var sources: [AgentSource] = []
    private var sessionsBySource: [String: [AgentSession]] = [:]
    private var dismissedAttention: Set<String> = []
    private let sleepManager = SleepManager()

    var runningCount: Int { sessions.filter { $0.state.isRunning && !$0.state.needsAttention }.count }
    var attentionCount: Int { sessions.filter { effectivelyNeedsAttention($0) }.count }
    var idleCount: Int { sessions.filter { $0.state == .idle }.count }
    var anyNeedsAttention: Bool { attentionCount > 0 }

    func register(_ source: AgentSource) {
        sources.append(source)
        source.onUpdate = { [weak self] tag, sessions in
            Task { @MainActor in self?.update(tag: tag, sessions: sessions) }
        }
        source.start()
    }

    func start() {
        let state = StatePersistence.shared.load()
        dismissedAttention = state.dismissed
        autoExpandOnAttention = state.autoExpandOnAttention
        sleepPreventionMode = state.sleepPrevention
        updateSleepAssertion()
    }

    func setAutoExpandOnAttention(_ value: Bool) {
        autoExpandOnAttention = value
        StatePersistence.shared.update { $0.autoExpandOnAttention = value }
    }

    func setSleepPreventionMode(_ value: SleepPreventionMode) {
        sleepPreventionMode = value
        StatePersistence.shared.update { $0.sleepPrevention = value }
        updateSleepAssertion()
    }

    func dismissAttention(for session: AgentSession) {
        dismissedAttention.insert(session.id)
        StatePersistence.shared.update { $0.dismissed = dismissedAttention }
        objectWillChange.send()
        recompute()
    }

    func effectivelyNeedsAttention(_ session: AgentSession) -> Bool {
        guard session.needsAttention || session.state.needsAttention else { return false }
        return !dismissedAttention.contains(session.id)
    }

    private func update(tag: String, sessions: [AgentSession]) {
        sessionsBySource[tag] = sessions
        let liveIds = Set(sessions.map { $0.id })
        dismissedAttention = dismissedAttention.filter { liveIds.contains($0) || !$0.hasPrefix("\(tag):") }
        recompute()
    }

    private func recompute() {
        let merged = sessionsBySource.values.flatMap { $0 }
        let sorted = merged.sorted { lhs, rhs in
            let la = effectivelyNeedsAttention(lhs)
            let ra = effectivelyNeedsAttention(rhs)
            if la != ra { return la }
            if lhs.state.isRunning != rhs.state.isRunning { return lhs.state.isRunning }
            return lhs.ts > rhs.ts
        }
        if sorted != sessions {
            sessions = sorted
        }
        updateSleepAssertion()
    }

    private func updateSleepAssertion() {
        let mode = sleepPreventionMode
        guard !mode.isEmpty else {
            sleepManager.releaseAssertion()
            return
        }
        var held: [AgentSession] = []
        if mode.contains(.active) {
            held += sessions.filter { $0.state.isRunning && !effectivelyNeedsAttention($0) }
        }
        if mode.contains(.needsAttention) {
            held += sessions.filter { effectivelyNeedsAttention($0) }
        }
        guard !held.isEmpty else {
            sleepManager.releaseAssertion()
            return
        }
        let names = held.prefix(3).map { $0.displayProject }.joined(separator: ", ")
        let suffix = held.count > 3 ? " +\(held.count - 3)" : ""
        sleepManager.assertIfNeeded(reason: "\(names)\(suffix) active")
    }
}
