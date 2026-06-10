import SwiftUI

struct CollapsedBar: View {
    @ObservedObject var store: AgentStore
    let attention: Bool

    var body: some View {
        HStack(spacing: 8) {
            segment(count: store.runningCount, label: "running", color: .green)
            divider
            segment(
                count: store.attentionCount,
                label: "needs you",
                color: .orange,
                emphasized: attention
            )
            divider
            segment(count: store.idleCount, label: "idle", color: .secondary)
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(.white.opacity(0.9))
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Text("·").foregroundStyle(.white.opacity(0.3))
    }

    private func segment(count: Int, label: String, color: Color, emphasized: Bool = false) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(count > 0 ? 1 : 0.35)
            Text("\(count)")
                .monospacedDigit()
                .foregroundStyle(emphasized && count > 0 ? color : .white.opacity(0.9))
            Text(label)
                .foregroundStyle(emphasized && count > 0 ? color : .white.opacity(0.55))
        }
    }
}
