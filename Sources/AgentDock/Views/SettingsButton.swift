import SwiftUI

struct SettingsButton: View {
    @ObservedObject var panel: PanelState
    @State private var hovered = false

    var body: some View {
        Button {
            panel.settingsOpen.toggle()
        } label: {
            Image(systemName: panel.settingsOpen ? "xmark" : "gearshape.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(hovered || panel.settingsOpen ? 1.0 : 0.8))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(hovered || panel.settingsOpen ? 0.22 : 0.12))
                )
        }
        .buttonStyle(.plain)
        .panelHoverCursor(panel.hoverPoint, $hovered)
    }
}
