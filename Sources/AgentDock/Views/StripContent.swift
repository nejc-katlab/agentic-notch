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
            }
            .padding(.trailing, 0)
            .frame(width: sideWidth, height: topInset, alignment: .trailing)

            Color.clear.frame(width: notchWidth, height: topInset)

            HStack(spacing: 8) {
                if store.attentionCount > 0 {
                    AttentionChip(count: store.attentionCount)
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, 0)
            .frame(width: sideWidth, height: topInset, alignment: .leading)
        }
        .frame(width: bodyWidth, height: topInset)
    }
}

private struct WorkingChip: View {
    let count: Int
    let breath: Bool

    private let period: Double = 3.2

    private var active: Bool { count > 0 }

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if active {
                    TimelineView(.animation) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let phase = (t.truncatingRemainder(dividingBy: period)) / period
                        let eased = 1 - pow(1 - phase, 3)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .scaleEffect(1 + eased * 4.5)
                            .opacity(max(0, 1 - eased * 2.2) * 0.6)
                    }
                }
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .opacity(active ? 1.0 : 0.35)
                    .shadow(color: active ? Color.green.opacity(0.6) : .clear, radius: 3)
            }
            .frame(width: 6, height: 6)
            chipCount(count, active: active)
        }
    }
}

private struct AttentionChip: View {
    let count: Int

    @State private var angle: Double = 0

    private let shakeTimer = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.orange)
                .shadow(color: Color.orange.opacity(0.45), radius: 3)
                .rotationEffect(.degrees(angle))
            chipCount(count, active: true, tint: .orange)
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear(perform: shake)
        .onReceive(shakeTimer) { _ in shake() }
    }

    private func shake() {
        var kick = Transaction()
        kick.disablesAnimations = true
        withTransaction(kick) { angle = 14 }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.22)) { angle = 0 }
    }
}

@ViewBuilder
private func chipCount(_ count: Int, active: Bool, tint: Color? = nil) -> some View {
    Text("\(count)")
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(tint ?? Color.white.opacity(active ? 0.95 : 0.4))
        .monospacedDigit()
}
