import Foundation

struct AgentSession: Identifiable, Codable, Hashable {
    let tool: String
    let sessionId: String
    var state: AgentState
    var project: String?
    var cwd: String?
    var activity: String?
    var needsAttention: Bool
    var ts: TimeInterval
    var tty: String?
    var pid: Int?
    var termProgram: String?
    var warpFocusUrl: String?
    var termSessionId: String?

    var id: String { "\(tool):\(sessionId)" }

    var timestamp: Date { Date(timeIntervalSince1970: ts) }

    var ageDescription: String {
        let seconds = Int(Date().timeIntervalSince(timestamp))
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        return "\(seconds / 3600)h"
    }

    var displayProject: String {
        project ?? cwd.map { ($0 as NSString).lastPathComponent } ?? "—"
    }

    var displayActivity: String {
        activity ?? state.label
    }
}
