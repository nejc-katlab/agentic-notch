import Foundation

final class FileWatchingSource: AgentSource {
    let tag: String
    var onUpdate: ((String, [AgentSession]) -> Void)?

    private let watcher: DirectoryWatcher<AgentSession>
    private let staleAfter: TimeInterval

    init(tag: String, directory: URL, staleAfter: TimeInterval = 1800) {
        self.tag = tag
        self.staleAfter = staleAfter
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
            if processIsDead(session.pid) || now - session.ts > staleAfter {
                try? FileManager.default.removeItem(at: url)
                continue
            }
            sessions.append(session)
        }
        onUpdate?(tag, sessions)
    }

    private func processIsDead(_ pid: Int?) -> Bool {
        guard let pid, pid > 1 else { return false }
        if kill(pid_t(pid), 0) == 0 { return false }
        return errno == ESRCH
    }
}
