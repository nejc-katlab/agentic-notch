import AppKit
import SwiftUI

struct SettingsPanel: View {
    @ObservedObject var store: AgentStore
    @ObservedObject var panel: PanelState
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    private let sleepOptions: [(String, SleepPreventionMode)] = [
        ("Off", .never),
        ("Active", [.active]),
        ("Attn", [.needsAttention]),
        ("Both", [.active, .needsAttention]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsCard {
                SettingRow(
                    symbol: "bell.badge.fill",
                    tint: Color(red: 1.0, green: 0.58, blue: 0.0),
                    title: "Expand on attention",
                    isOn: store.autoExpandOnAttention,
                    hoverPoint: panel.hoverPoint
                ) {
                    store.setAutoExpandOnAttention(!store.autoExpandOnAttention)
                }

                InsetDivider()

                SettingRow(
                    symbol: "bolt.fill",
                    tint: Color(red: 0.0, green: 0.62, blue: 1.0),
                    title: "Launch at login",
                    isOn: launchAtLogin,
                    hoverPoint: panel.hoverPoint
                ) {
                    launchAtLogin.toggle()
                    LaunchAtLogin.set(launchAtLogin)
                }

                InsetDivider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        IconTile(symbol: "cup.and.saucer.fill", tint: Color(red: 0.55, green: 0.45, blue: 0.95))
                        Text("Prevent sleep")
                            .font(.system(size: 12.5))
                            .foregroundStyle(.white.opacity(0.92))
                        Spacer(minLength: 0)
                    }
                    SegmentedControl(
                        options: sleepOptions,
                        selection: store.sleepPreventionMode,
                        hoverPoint: panel.hoverPoint
                    ) { mode in
                        store.setSleepPreventionMode(mode)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }

            QuitButton(hoverPoint: panel.hoverPoint) {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct InsetDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 42)
    }
}

private struct IconTile: View {
    let symbol: String
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [tint, tint.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 22, height: 22)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .shadow(color: tint.opacity(0.35), radius: 2, y: 1)
    }
}

private struct SettingRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let isOn: Bool
    let hoverPoint: CGPoint?
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                IconTile(symbol: symbol, tint: tint)
                Text(title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.92))
                Spacer(minLength: 0)
                SwitchView(isOn: isOn)
            }
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(Color.white.opacity(hovered ? 0.06 : 0.0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .panelHover(hoverPoint, $hovered)
    }
}

private struct SwitchView: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn
                    ? LinearGradient(colors: [Color(red: 0.2, green: 0.82, blue: 0.45), Color(red: 0.16, green: 0.72, blue: 0.4)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.14)], startPoint: .top, endPoint: .bottom))
                .frame(width: 32, height: 19)
            Circle()
                .fill(.white)
                .frame(width: 15, height: 15)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                .padding(2)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isOn)
    }
}

private struct SegmentedControl: View {
    let options: [(String, SleepPreventionMode)]
    let selection: SleepPreventionMode
    let hoverPoint: CGPoint?
    let onSelect: (SleepPreventionMode) -> Void

    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                Segment(
                    title: options[i].0,
                    isSelected: options[i].1 == selection,
                    namespace: ns,
                    hoverPoint: hoverPoint
                ) {
                    onSelect(options[i].1)
                }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.black.opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: selection)
    }
}

private struct Segment: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let hoverPoint: CGPoint?
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.22))
                        .matchedGeometryEffect(id: "segPill", in: namespace)
                }
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : (hovered ? 0.85 : 0.55)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .panelHover(hoverPoint, $hovered)
    }
}

private struct QuitButton: View {
    let hoverPoint: CGPoint?
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                Text("Quit AgentDock")
                    .font(.system(size: 12.5, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color(red: 1.0, green: 0.36, blue: 0.34).opacity(hovered ? 1.0 : 0.85))
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.27, blue: 0.27).opacity(hovered ? 0.16 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(red: 1.0, green: 0.27, blue: 0.27).opacity(hovered ? 0.3 : 0.14), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .panelHover(hoverPoint, $hovered)
    }
}
