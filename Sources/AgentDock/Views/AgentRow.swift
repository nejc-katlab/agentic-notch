import SwiftUI

struct AgentRow: View {
    @ObservedObject var store: AgentStore
    @ObservedObject var panel: PanelState
    let session: AgentSession
    let breath: Bool

    @State private var rowHovered = false

    private var needsAttention: Bool { store.effectivelyNeedsAttention(session) }
    private var isWorking: Bool { session.state == .working }
    private var revealHelp: String {
        "Open terminal at \(session.cwd ?? "~")"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                if isWorking {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.green.opacity(breath ? 0.85 : 0.3), lineWidth: 1)
                        .shadow(color: Color.green.opacity(breath ? 0.45 : 0.0), radius: 4)
                        .frame(width: 24, height: 24)
                }
                toolIcon
                if needsAttention {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.orange)
                        .background(Circle().fill(Color.black))
                        .offset(x: 10, y: -10)
                        .shadow(color: .orange.opacity(0.55), radius: 3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.displayProject)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    stateChip
                    Spacer(minLength: 0)
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(session.ageDescription)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                Text(session.displayActivity)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }

            actions
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(rowHovered ? 0.07 : 0.0))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            TerminalLauncher.reveal(session: session)
        }
        .panelHover(panel.hoverPoint, $rowHovered)
        .help(revealHelp)
    }

    private var toolIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.white.opacity(0.08))
            Text(toolGlyph)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var toolGlyph: String {
        switch session.tool {
        case "claude-code": return "CC"
        case "cursor": return "Cu"
        case "codex": return "Cx"
        default: return String(session.tool.prefix(2)).uppercased()
        }
    }

    private var stateChip: some View {
        Text(session.state.label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(session.state.tint)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                Capsule().fill(session.state.tint.opacity(0.16))
            )
    }

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: 4) {
            if needsAttention {
                IconButton(symbol: "xmark", help: "Dismiss attention flag", hoverPoint: panel.hoverPoint) {
                    store.dismissAttention(for: session)
                }
            }
        }
    }
}

private struct IconButton: View {
    let symbol: String
    let help: String
    let hoverPoint: CGPoint?
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(hovered ? 1 : 0.7))
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(hovered ? 0.14 : 0.06))
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .panelHover(hoverPoint, $hovered)
    }
}
