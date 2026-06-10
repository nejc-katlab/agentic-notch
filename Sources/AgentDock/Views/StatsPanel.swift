import SwiftUI

struct StatsPanel: View {
    @ObservedObject var panel: PanelState
    @State private var range: StatsRange = .today
    @State private var stats: [ProjectStats] = []

    private var totalLabel: String {
        ProjectStats.duration(stats.reduce(0) { $0 + $1.workingSeconds })
    }

    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 8) {
                Text("Stats")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                if !stats.isEmpty {
                    Text(totalLabel)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.green.opacity(0.85))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(height: 24)

            rangePicker
                .padding(.horizontal, 6)
                .padding(.bottom, 4)

            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(height: 1)

            if stats.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(stats) { project in
                            ProjectStatsRow(stats: project, hoverPoint: panel.hoverPoint)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { reload() }
        .onChange(of: range) { _ in reload() }
    }

    private func reload() {
        stats = StatsAggregator.aggregate(range: range)
    }

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(StatsRange.allCases, id: \.self) { option in
                RangeSegment(
                    title: option.rawValue,
                    isSelected: option == range,
                    hoverPoint: panel.hoverPoint
                ) {
                    range = option
                }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.bar")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.35))
            Text("No activity recorded yet")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
    }
}

private struct RangeSegment: View {
    let title: String
    let isSelected: Bool
    let hoverPoint: CGPoint?
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.16))
                }
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : (hovered ? 0.85 : 0.5)))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .panelHoverCursor(hoverPoint, $hovered)
    }
}

private struct ProjectStatsRow: View {
    let stats: ProjectStats
    let hoverPoint: CGPoint?
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.project)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(stats.sessions) session\(stats.sessions == 1 ? "" : "s") · \(stats.attentionWaits) wait\(stats.attentionWaits == 1 ? "" : "s")")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer(minLength: 0)
            Text(stats.workingLabel)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.green.opacity(0.85))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(hovered ? 0.07 : 0.0))
        )
        .panelHoverCursor(hoverPoint, $hovered)
    }
}
