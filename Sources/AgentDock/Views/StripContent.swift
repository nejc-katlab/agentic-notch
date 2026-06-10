import SwiftUI

struct StripContent: View {
    @ObservedObject var store: AgentStore
    let topInset: CGFloat
    let bodyWidth: CGFloat
    let notchWidth: CGFloat
    let breath: Bool

    private var sideWidth: CGFloat {
        max(0, (bodyWidth - notchWidth) / 2)
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                WorkingChip(count: store.runningCount, breath: breath)
                if store.attentionCount > 0 {
                    AttentionChip(count: store.attentionCount)
                }
            }
            .padding(.trailing, 10)
            .frame(width: sideWidth, height: topInset, alignment: .trailing)

            Color.clear.frame(width: notchWidth, height: topInset)

            HStack(spacing: 8) {
                IdleChip(count: store.idleCount)
                Spacer(minLength: 0)
            }
            .padding(.leading, 10)
            .frame(width: sideWidth, height: topInset, alignment: .leading)
        }
        .frame(width: bodyWidth, height: topInset)
    }
}

private struct WorkingChip: View {
    let count: Int
    let breath: Bool

    private var active: Bool { count > 0 }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .opacity(active ? (breath ? 1.0 : 0.55) : 0.35)
                .shadow(color: active ? Color.green.opacity(breath ? 0.7 : 0.15) : .clear,
                        radius: breath ? 5 : 1)
            chipCount(count, active: active)
        }
    }
}

private struct AttentionChip: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.orange)
                .shadow(color: Color.orange.opacity(0.45), radius: 3)
            chipCount(count, active: true, tint: .orange)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

private struct IdleChip: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.gray)
                .frame(width: 6, height: 6)
                .opacity(0.55)
            chipCount(count, active: count > 0)
        }
    }
}

@ViewBuilder
private func chipCount(_ count: Int, active: Bool, tint: Color? = nil) -> some View {
    Text("\(count)")
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(tint ?? Color.white.opacity(active ? 0.95 : 0.4))
        .monospacedDigit()
}
