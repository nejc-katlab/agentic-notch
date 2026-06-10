import Foundation

final class FileWatchingSource: AgentSource {
    let tag: String
    var onUpdate: ((String, [AgentSession]) -> Void)?

    private let watcher: DirectoryWatcher<AgentSession>
    private let staleAfter: TimeInterval
    private let idleAfter: TimeInterval

    init(tag: String, directory: URL, staleAfter: TimeInterval = 600, idleAfter: TimeInterval = 120) {
        self.tag = tag
        self.staleAfter = staleAfter
        self.idleAfter = idleAfter
        AgentDockPaths.ensureExists(AgentDockPaths.root)
        watcher = DirectoryWatcher(directory: directory, label: "agentdock.\(tag).watch")
        watcher.onChange = { [weak self] entries in self?.process(entries) }
    }

    func start() { watcher.start() }

    func stop() { watcher.stop() }

    private func process(_ entries: [(url: URL, value: AgentSession)]) {
        let now = Date().timeIntervalSince1970
        var sessions: [AgentSession] = []
        for (url, session) in entries {
            var session = session
            let age = now - session.ts
            if age > staleAfter {
                try? FileManager.default.removeItem(at: url)
                continue
            }
            if session.state.isRunning, age > idleAfter {
                session.state = .idle
            }
            sessions.append(session)
        }
        onUpdate?(tag, sessions)
    }
}
