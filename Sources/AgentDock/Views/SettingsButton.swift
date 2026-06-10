import SwiftUI

struct PanelModeButtons: View {
    @ObservedObject var panel: PanelState

    var body: some View {
        HStack(spacing: 4) {
            ModeButton(panel: panel, mode: .stats, symbol: "chart.bar.fill", activeSymbol: "xmark")
            ModeButton(panel: panel, mode: .settings, symbol: "gearshape.fill", activeSymbol: "xmark")
        }
    }
}

private struct ModeButton: View {
    @ObservedObject var panel: PanelState
    let mode: PanelMode
    let symbol: String
    let activeSymbol: String
    @State private var hovered = false

    private var isActive: Bool { panel.mode == mode }

    var body: some View {
        Button {
            panel.mode = isActive ? .sessions : mode
        } label: {
            Image(systemName: isActive ? activeSymbol : symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(hovered || isActive ? 1.0 : 0.8))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(hovered || isActive ? 0.22 : 0.12))
                )
        }
        .buttonStyle(.plain)
        .panelHoverCursor(panel.hoverPoint, $hovered)
    }
}
