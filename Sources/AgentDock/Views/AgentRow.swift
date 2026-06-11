import SwiftUI

struct AgentRow: View {
    @ObservedObject var store: AgentStore
    @ObservedObject var panel: PanelState
    let session: AgentSession

    @State private var rowHovered = false
    @State private var beamVisible = false

    private var needsAttention: Bool { store.effectivelyNeedsAttention(session) }
    private var isWorking: Bool { session.state == .working }
    private var revealHelp: String {
        "Open terminal at \(session.cwd ?? "~")"
    }

    var body: some View {
        Group {
            if let request = store.pendingRequest(for: session) {
                permissionCard(request)
            } else {
                compactRow
            }
        }
        .onAppear {
            beamVisible = isWorking
        }
        .onChange(of: isWorking) { working in
            withAnimation(working ? .easeIn(duration: 0.25) : .easeOut(duration: 0.9)) {
                beamVisible = working
            }
        }
    }

    private var compactRow: some View {
        HStack(alignment: .center, spacing: 10) {
            iconStack
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
            if needsAttention { store.dismissAttention(for: session) }
            TerminalLauncher.reveal(session: session)
        }
        .panelHoverCursor(panel.hoverPoint, $rowHovered)
        .help(revealHelp)
    }

    private var iconStack: some View {
        ZStack {
            if beamVisible {
                Group {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.green.opacity(0.22), lineWidth: 1)
                    BorderBeam()
                }
                .frame(width: 24, height: 24)
                .transition(.opacity)
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
    }

    private func permissionCard(_ request: PermissionRequest) -> some View {
        let tint = request.riskTier.tint
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                toolIcon
                    .frame(width: 20, height: 20)
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

            HStack(spacing: 6) {
                Image(systemName: riskIcon(request.riskTier))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                Text(request.toolName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                Text(request.commandText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(tint.opacity(0.4), lineWidth: 1)
                    )
            )
            .help(request.commandText)

            ExpiryBar(request: request, tint: tint)

            HStack(spacing: 6) {
                WideButton(symbol: "checkmark", title: "Allow", tint: .green, hoverPoint: panel.hoverPoint) {
                    store.respond(to: request, decision: .allow)
                }
                WideButton(symbol: "xmark", title: "Deny", tint: .red, hoverPoint: panel.hoverPoint) {
                    store.respond(to: request, decision: .deny)
                }
                WideButton(symbol: "terminal", title: "Terminal", tint: .white, fixedWidth: 92, hoverPoint: panel.hoverPoint) {
                    store.respond(to: request, decision: .ask)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .contentShape(Rectangle())
        .panelHoverCursor(panel.hoverPoint, $rowHovered)
    }

    private func riskIcon(_ tier: RiskTier) -> String {
        switch tier {
        case .read: return "eye"
        case .mutate: return "pencil"
        case .destructive: return "exclamationmark.triangle.fill"
        }
    }

    private var toolIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.white.opacity(0.08))
            ToolIcon(tool: session.tool)
                .padding(4)
        }
    }

    private var chipTint: Color {
        session.state.needsAttention && !needsAttention ? .secondary : session.state.tint
    }

    private var stateChip: some View {
        Text(session.state.label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(chipTint)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                Capsule().fill(chipTint.opacity(0.16))
            )
    }

    @ViewBuilder
    private var actions: some View {
        if needsAttention {
            IconButton(symbol: "xmark", help: "Dismiss attention flag", hoverPoint: panel.hoverPoint) {
                store.dismissAttention(for: session)
            }
        }
    }
}

private struct ExpiryBar: View {
    let request: PermissionRequest
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            TimelineView(.periodic(from: .now, by: 0.5)) { context in
                let total = max(request.expiresAt - request.ts, 0.001)
                let remaining = request.expiresAt - context.date.timeIntervalSince1970
                let fraction = min(max(remaining / total, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(tint.opacity(0.8))
                        .frame(width: geo.size.width * fraction)
                }
            }
        }
        .frame(height: 3)
    }
}

private struct WideButton: View {
    let symbol: String
    let title: String
    let tint: Color
    var fixedWidth: CGFloat? = nil
    let hoverPoint: CGPoint?
    let action: () -> Void

    @State private var hovered = false

    private var neutral: Bool { tint == .white }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(neutral
                ? Color.white.opacity(hovered ? 1 : 0.7)
                : tint.opacity(hovered ? 1 : 0.95))
            .frame(maxWidth: fixedWidth == nil ? .infinity : nil)
            .frame(width: fixedWidth, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(neutral
                        ? Color.white.opacity(hovered ? 0.14 : 0.06)
                        : tint.opacity(hovered ? 0.3 : 0.18))
            )
        }
        .buttonStyle(.plain)
        .help(title)
        .panelHoverCursor(hoverPoint, $hovered)
    }
}

private struct BorderBeam: View {
    private static let segments = 8
    private static let tailLength: CGFloat = 0.3
    private static let cycleDuration: Double = 2.2

    var body: some View {
        TimelineView(.animation) { context in
            let phase = CGFloat(
                (context.date.timeIntervalSinceReferenceDate / Self.cycleDuration)
                    .truncatingRemainder(dividingBy: 1)
            )
            ZStack {
                ForEach(0..<Self.segments, id: \.self) { index in
                    let brightness = CGFloat(index + 1) / CGFloat(Self.segments)
                    BeamSegment(
                        phase: phase,
                        offset: CGFloat(index) / CGFloat(Self.segments) * Self.tailLength,
                        length: Self.tailLength / CGFloat(Self.segments)
                    )
                    .stroke(
                        Color.green.opacity(0.9 * pow(brightness, 1.5)),
                        style: StrokeStyle(lineWidth: 0.8 + 0.7 * brightness, lineCap: .butt)
                    )
                }
            }
            .compositingGroup()
            .shadow(color: Color.green.opacity(0.55), radius: 3)
        }
    }
}

private struct BeamSegment: Shape {
    let phase: CGFloat
    let offset: CGFloat
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        let base = Path(roundedRect: rect, cornerRadius: 6, style: .continuous)
        let start = (phase + offset).truncatingRemainder(dividingBy: 1)
        let end = start + length
        if end <= 1 {
            return base.trimmedPath(from: start, to: end)
        }
        var wrapped = base.trimmedPath(from: start, to: 1)
        wrapped.addPath(base.trimmedPath(from: 0, to: end - 1))
        return wrapped
    }
}

private struct IconButton: View {
    let symbol: String
    let help: String
    var tint: Color = .white
    let hoverPoint: CGPoint?
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint == .white ? Color.white.opacity(hovered ? 1 : 0.7) : tint.opacity(hovered ? 1 : 0.85))
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint == .white ? Color.white.opacity(hovered ? 0.14 : 0.06) : tint.opacity(hovered ? 0.22 : 0.12))
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .panelHoverCursor(hoverPoint, $hovered)
    }
}
