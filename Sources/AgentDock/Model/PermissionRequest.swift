import Foundation

struct PermissionRequest: Identifiable, Codable, Hashable {
    let v: Int
    let tool: String
    let sessionId: String
    let requestId: String
    let toolName: String
    let summary: String?
    let toolInputPreview: String?
    let cwd: String?
    let project: String?
    let ts: TimeInterval
    let expiresAt: TimeInterval

    var id: String { requestId }

    var sessionKey: String { "\(tool):\(sessionId)" }

    var displaySummary: String {
        summary ?? "Wants to run \(toolName)"
    }
}

enum PermissionDecision: String, Codable {
    case allow
    case deny
    case ask
}
