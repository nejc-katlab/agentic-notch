import SwiftUI

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

    var commandText: String {
        guard let preview = toolInputPreview,
              let data = preview.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return summary ?? toolName }
        for key in ["command", "file_path", "path", "url", "pattern", "query", "prompt"] {
            if let value = obj[key] as? String, !value.isEmpty {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return summary ?? toolName
    }

    var riskTier: RiskTier {
        let lowered = commandText.lowercased()
        let destructive = [
            "rm ", "rm -", "sudo", "--force", "-f ", " > ", ">>", "mkfs", "dd ",
            "kill ", "pkill", "drop table", "delete from", "git push", "reset --hard",
            "chmod", "chown", "truncate", ":>", "shutdown", "reboot", "> /",
        ]
        if destructive.contains(where: lowered.contains) { return .destructive }
        let readOnly: Set<String> = [
            "Read", "Grep", "Glob", "LS", "NotebookRead", "WebFetch", "WebSearch", "TodoWrite",
        ]
        if readOnly.contains(toolName) { return .read }
        return .mutate
    }
}

enum RiskTier {
    case read
    case mutate
    case destructive

    var tint: Color {
        switch self {
        case .read: return .secondary
        case .mutate: return .orange
        case .destructive: return .red
        }
    }

    var label: String {
        switch self {
        case .read: return "Read-only"
        case .mutate: return "Modifies"
        case .destructive: return "Destructive"
        }
    }
}

enum PermissionDecision: String, Codable {
    case allow
    case deny
    case ask
}
