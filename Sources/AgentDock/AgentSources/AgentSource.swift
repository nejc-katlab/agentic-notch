import Foundation

protocol AgentSource: AnyObject {
    var tag: String { get }
    var onUpdate: ((String, [AgentSession]) -> Void)? { get set }
    func start()
    func stop()
}

enum AgentDockPaths {
    static let root: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".agentdock", isDirectory: true)
    }()

    static func sourceDir(_ name: String) -> URL {
        root.appendingPathComponent(name, isDirectory: true)
    }

    static var stateFile: URL { root.appendingPathComponent("state.json") }

    static func ensureExists(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
