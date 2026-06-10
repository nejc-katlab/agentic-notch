import Foundation

final class PermissionResponder {
    var onChange: (([String: PermissionRequest]) -> Void)?

    private let root = AgentDockPaths.sourceDir("permissions")
    private var requestsDir: URL { root.appendingPathComponent("requests", isDirectory: true) }
    private var responsesDir: URL { root.appendingPathComponent("responses", isDirectory: true) }
    private var enabledMarker: URL { root.appendingPathComponent("enabled") }
    private let watcher: DirectoryWatcher<PermissionRequest>
    private var answered: Set<String> = []
    private let answeredLock = NSLock()

    init() {
        watcher = DirectoryWatcher(
            directory: AgentDockPaths.sourceDir("permissions").appendingPathComponent("requests", isDirectory: true),
            label: "agentdock.permissions.watch",
            pollInterval: .milliseconds(200)
        )
        watcher.onChange = { [weak self] entries in self?.process(entries) }
        ensureDirectories()
    }

    func start() { watcher.start() }

    func stop() { watcher.stop() }

    func setEnabled(_ enabled: Bool) {
        ensureDirectories()
        if enabled {
            FileManager.default.createFile(atPath: enabledMarker.path, contents: Data())
        } else {
            try? FileManager.default.removeItem(at: enabledMarker)
        }
    }

    func respond(to request: PermissionRequest, decision: PermissionDecision) {
        struct Response: Encodable {
            let requestId: String
            let decision: String
            let ts: TimeInterval
        }
        let response = Response(requestId: request.requestId, decision: decision.rawValue, ts: Date().timeIntervalSince1970)
        guard let data = try? JSONEncoder().encode(response) else { return }
        answeredLock.lock()
        answered.insert(request.requestId)
        answeredLock.unlock()
        let target = responsesDir.appendingPathComponent("\(request.requestId).json")
        let tmp = responsesDir.appendingPathComponent("\(request.requestId).json.tmp")
        try? data.write(to: tmp, options: .atomic)
        try? FileManager.default.moveItem(at: tmp, to: target)
    }

    private func ensureDirectories() {
        let fm = FileManager.default
        for dir in [root, requestsDir, responsesDir] {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        }
    }

    private func process(_ entries: [(url: URL, value: PermissionRequest)]) {
        let now = Date().timeIntervalSince1970
        answeredLock.lock()
        let answeredIds = answered
        answeredLock.unlock()
        var pending: [String: PermissionRequest] = [:]
        for (url, request) in entries {
            if now > request.expiresAt + 60 {
                try? FileManager.default.removeItem(at: url)
                continue
            }
            if now > request.expiresAt || answeredIds.contains(request.requestId) { continue }
            pending[request.sessionKey] = request
        }
        let liveIds = Set(entries.map { $0.value.requestId })
        answeredLock.lock()
        answered.formIntersection(liveIds)
        answeredLock.unlock()
        sweepResponses(now: now)
        onChange?(pending)
    }

    private func sweepResponses(now: TimeInterval) {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: responsesDir, includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        for url in entries {
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modified = values.contentModificationDate else { continue }
            if now - modified.timeIntervalSince1970 > 120 {
                try? fm.removeItem(at: url)
            }
        }
    }
}
