import SwiftUI

struct ExpandedPanel: View {
    @ObservedObject var store: AgentStore
    @ObservedObject var panel: PanelState

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if panel.mode == .settings {
                    SettingsPanel(store: store, panel: panel)
                        .padding(.top, 4)
                } else if panel.mode == .stats {
                    StatsPanel(panel: panel)
                        .padding(.top, 4)
                } else if store.sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: PanelMetrics.rowSpacing) {
                            ForEach(store.sessions) { session in
                                AgentRow(store: store, panel: panel, session: session)
                                    .frame(height: store.pendingRequest(for: session) != nil
                                        ? PanelMetrics.permissionRowHeight
                                        : PanelMetrics.rowHeight)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(store.effectivelyNeedsAttention(session)
                                                ? Color.orange.opacity(0.08)
                                                : Color.white.opacity(0.0))
                                    )
                            }
                        }
                        .padding(.top, PanelMetrics.topPadding)
                        .padding(.bottom, PanelMetrics.bottomPadding)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            PanelModeButtons(panel: panel)
                .padding(.top, 4)
                .padding(.trailing, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.35))
            Text("No agents running")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .frame(height: PanelMetrics.emptyHeight)
    }
}
