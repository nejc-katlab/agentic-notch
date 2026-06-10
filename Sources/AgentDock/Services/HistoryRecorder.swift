import Foundation

struct HistoryInterval: Codable {
    var v = 1
    var type = "interval"
    let tool: String
    let sessionId: String
    let project: String?
    let cwd: String?
    let kind: String
    let start: TimeInterval
    let end: TimeInterval
}

struct HistorySession: Codable {
    var v = 1
    var type = "session"
    let tool: String
    let sessionId: String
    let project: String?
    let startedAt: TimeInterval
    let endedAt: TimeInterval
    let workingSeconds: Double
    let attentionWaits: Int
    let attentionSeconds: Double
}

final class HistoryRecorder {
    static let maxFileBytes = 5 * 1024 * 1024

    private struct Tracked {
        var session: AgentSession
        var startedAt: TimeInterval
        var workingSeconds: Double = 0
        var attentionSeconds: Double = 0
        var attentionWaits: Int = 0
        var openKind: String?
        var openStart: TimeInterval = 0
    }

    private var tracked: [String: Tracked] = [:]
    private let queue = DispatchQueue(label: "agentdock.history")
    private let fileURL = AgentDockPaths.root.appendingPathComponent("history.jsonl")

    func observe(_ sessions: [AgentSession]) {
        queue.async { [weak self] in self?.process(sessions) }
    }

    private func process(_ sessions: [AgentSession]) {
        let now = Date().timeIntervalSince1970
        let live = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })

        for (id, session) in live {
            if var entry = tracked[id] {
                let kind = intervalKind(session)
                if kind != entry.openKind {
                    closeInterval(&entry, at: now)
                    if let kind {
                        entry.openKind = kind
                        entry.openStart = now
                        if kind == "attention" { entry.attentionWaits += 1 }
                    }
                }
                entry.session = session
                tracked[id] = entry
                if session.state == .done {
                    finish(id: id, at: now)
                }
            } else if session.state != .done {
                var entry = Tracked(session: session, startedAt: min(session.ts, now))
                if let kind = intervalKind(session) {
                    entry.openKind = kind
                    entry.openStart = now
                    if kind == "attention" { entry.attentionWaits = 1 }
                }
                tracked[id] = entry
            }
        }

        for id in tracked.keys where live[id] == nil {
            finish(id: id, at: now)
        }
    }

    private func intervalKind(_ session: AgentSession) -> String? {
        if session.state == .working { return "working" }
        if session.state.needsAttention || session.needsAttention { return "attention" }
        return nil
    }

    private func closeInterval(_ entry: inout Tracked, at now: TimeInterval) {
        guard let kind = entry.openKind, now > entry.openStart else {
            entry.openKind = nil
            return
        }
        let interval = HistoryInterval(
            tool: entry.session.tool,
            sessionId: entry.session.sessionId,
            project: entry.session.project,
            cwd: entry.session.cwd,
            kind: kind,
            start: entry.openStart,
            end: now
        )
        let seconds = now - entry.openStart
        if kind == "working" { entry.workingSeconds += seconds } else { entry.attentionSeconds += seconds }
        entry.openKind = nil
        append(interval)
    }

    private func finish(id: String, at now: TimeInterval) {
        guard var entry = tracked.removeValue(forKey: id) else { return }
        closeInterval(&entry, at: now)
        let record = HistorySession(
            tool: entry.session.tool,
            sessionId: entry.session.sessionId,
            project: entry.session.project,
            startedAt: entry.startedAt,
            endedAt: now,
            workingSeconds: entry.workingSeconds,
            attentionWaits: entry.attentionWaits,
            attentionSeconds: entry.attentionSeconds
        )
        append(record)
    }

    private func append(_ record: some Encodable) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        AgentDockPaths.ensureExists(AgentDockPaths.root)
        rotateIfNeeded()
        if let handle = FileHandle(forWritingAtPath: fileURL.path) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data + Data("\n".utf8))
        } else {
            try? (data + Data("\n".utf8)).write(to: fileURL)
        }
    }

    private func rotateIfNeeded() {
        let fm = FileManager.default
        guard let size = (try? fm.attributesOfItem(atPath: fileURL.path))?[.size] as? Int,
              size > Self.maxFileBytes else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM-HHmmss"
        let archived = AgentDockPaths.root.appendingPathComponent("history-\(formatter.string(from: Date())).jsonl")
        try? fm.moveItem(at: fileURL, to: archived)
    }
}
