import SwiftUI

enum AgentState: String, Codable, CaseIterable {
    case working
    case idle
    case needsPermission = "needs-permission"
    case needsInput = "needs-input"
    case done

    var needsAttention: Bool {
        self == .needsPermission || self == .needsInput
    }

    var isRunning: Bool {
        self == .working || self == .needsPermission || self == .needsInput
    }

    var label: String {
        switch self {
        case .working: return "Working"
        case .idle: return "Idle"
        case .needsPermission: return "Needs permission"
        case .needsInput: return "Needs input"
        case .done: return "Done"
        }
    }

    var tint: Color {
        switch self {
        case .working: return .green
        case .idle: return .secondary
        case .needsPermission, .needsInput: return .orange
        case .done: return .blue
        }
    }
}
