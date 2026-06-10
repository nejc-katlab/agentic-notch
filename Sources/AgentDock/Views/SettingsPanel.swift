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
        VStack(spacing: 1) {
            HStack(spacing: 0) {
                Text("Settings")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(height: 24)

            RowDivider()

            SettingRow(
                symbol: "bell.badge.fill",
                tint: Color(red: 1.0, green: 0.58, blue: 0.0),
                title: "Expand on attention",
                isOn: store.autoExpandOnAttention,
                hoverPoint: panel.hoverPoint
            ) {
                store.setAutoExpandOnAttention(!store.autoExpandOnAttention)
            }

            RowDivider()

            SettingRow(
                symbol: "checkmark.shield.fill",
                tint: Color(red: 0.24, green: 0.84, blue: 0.47),
                title: "Approve in notch",
                isOn: store.permissionInterception,
                hoverPoint: panel.hoverPoint
            ) {
                store.setPermissionInterception(!store.permissionInterception)
            }

            RowDivider()

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

            RowDivider()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    IconTile(symbol: "cup.and.saucer.fill", tint: Color(red: 0.55, green: 0.45, blue: 0.95))
                    Text("Prevent sleep")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
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
            .padding(.horizontal, 6)
            .padding(.top, 6)
            .padding(.bottom, 8)

            Spacer(minLength: 0)

            RowDivider()

            QuitRow(hoverPoint: panel.hoverPoint) {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.04))
            .frame(height: 1)
    }
}

private struct IconTile: View {
    let symbol: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 20, height: 20)
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
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                SwitchView(isOn: isOn)
            }
            .padding(.horizontal, 6)
            .frame(height: 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(hovered ? 0.07 : 0.0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .panelHoverCursor(hoverPoint, $hovered)
    }
}

private struct SwitchView: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn
                ? LinearGradient(colors: [Color(red: 0.24, green: 0.84, blue: 0.47), Color(red: 0.13, green: 0.7, blue: 0.38)], startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom))
            .frame(width: 28, height: 16)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isOn ? 0.0 : 0.06), lineWidth: 0.5)
            )
            .overlay(
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.22), radius: 1, y: 0.5)
                    .padding(2)
                    .frame(maxWidth: .infinity, alignment: isOn ? .trailing : .leading)
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isOn)
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
                .fill(Color.white.opacity(0.05))
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
                        .fill(Color.white.opacity(0.16))
                        .matchedGeometryEffect(id: "segPill", in: namespace)
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : (hovered ? 0.85 : 0.5)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .panelHoverCursor(hoverPoint, $hovered)
    }
}

private struct QuitRow: View {
    let hoverPoint: CGPoint?
    let action: () -> Void
    @State private var hovered = false

    private let red = Color(red: 1.0, green: 0.36, blue: 0.34)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 20, height: 20)
                Text("Quit AgentDock")
                    .font(.system(size: 11))
                Spacer(minLength: 0)
            }
            .foregroundStyle(red.opacity(hovered ? 1.0 : 0.85))
            .padding(.horizontal, 6)
            .frame(height: 24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(red.opacity(hovered ? 0.1 : 0.0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .panelHoverCursor(hoverPoint, $hovered)
    }
}
