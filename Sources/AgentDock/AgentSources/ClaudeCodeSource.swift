import Foundation

final class ClaudeCodeSource: AgentSource {
    let tag = "claude-code"
    var onUpdate: ((String, [AgentSession]) -> Void)?

    private let directory: URL
    private let queue = DispatchQueue(label: "agentdock.claude-code.watch")
    private var dirSource: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1
    private var pollTimer: DispatchSourceTimer?
    private let staleAfter: TimeInterval = 600

    init() {
        directory = AgentDockPaths.sourceDir("sessions")
        AgentDockPaths.ensureExists(AgentDockPaths.root)
        AgentDockPaths.ensureExists(directory)
    }

    func start() {
        scan()
        watchDirectory()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(500), repeating: .milliseconds(500))
        timer.setEventHandler { [weak self] in self?.scan() }
        timer.resume()
        pollTimer = timer
    }

    func stop() {
        pollTimer?.cancel(); pollTimer = nil
        dirSource?.cancel(); dirSource = nil
        if dirFD >= 0 { close(dirFD); dirFD = -1 }
    }

    private func watchDirectory() {
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        dirFD = fd
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .delete, .rename, .extend], queue: queue
        )
        src.setEventHandler { [weak self] in self?.scan() }
        src.setCancelHandler { [fd] in close(fd) }
        src.resume()
        dirSource = src
    }

    private func scan() {
        let fm = FileManager.default
        let now = Date()
        guard let entries = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            onUpdate?(tag, [])
            return
        }

        var sessions: [AgentSession] = []
        let decoder = JSONDecoder()
        for url in entries where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  var session = try? decoder.decode(AgentSession.self, from: data) else { continue }
            let age = now.timeIntervalSince1970 - session.ts
            if age > staleAfter {
                try? fm.removeItem(at: url)
                continue
            }
            if session.state.isRunning, age > 120 {
                session.state = .idle
            }
            sessions.append(session)
        }
        onUpdate?(tag, sessions)
    }
}
