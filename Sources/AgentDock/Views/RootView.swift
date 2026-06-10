import SwiftUI

struct RootView: View {
    @ObservedObject var store: AgentStore
    @ObservedObject var panel: PanelState
    let topInset: CGFloat
    let notchWidth: CGFloat
    let isNotched: Bool

    @State private var breath = false

    private var expanded: Bool { panel.expanded }

    private var notchPanelShape: NotchPanelShape {
        NotchPanelShape(
            notchWidth: notchWidth,
            notchHeight: topInset,
            bodyWidth: panel.bodyWidth,
            bodyHeight: panel.bodyHeight,
            notchTopRadius: 6,
            notchBottomRadius: 14,
            bodyCornerRadius: 14
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            if isNotched {
                Color.black.clipShape(notchPanelShape)

                VStack(spacing: 0) {
                    Spacer().frame(height: topInset)
                    ExpandedPanel(store: store, panel: panel, breath: breath)
                        .frame(width: panel.bodyWidth, height: max(panel.bodyHeight, 0), alignment: .top)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipShape(notchPanelShape)
                .opacity(expanded ? 1 : 0)
            } else {
                fallbackBackground
            }

            StripContent(
                store: store,
                topInset: topInset,
                bodyWidth: panel.bodyWidth,
                notchWidth: notchWidth,
                breath: breath
            )
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .coordinateSpace(name: PanelSpace.name)
        .onAppear { startBreath() }
        .animation(.timingCurve(0.33, 1, 0.68, 1, duration: 0.35), value: panel.expanded)
        .animation(.timingCurve(0.33, 1, 0.68, 1, duration: 0.35), value: panel.bodyHeight)
        .animation(.easeOut(duration: 0.2), value: store.attentionCount)
    }

    @ViewBuilder
    private var fallbackBackground: some View {
        Color.black
            .frame(width: panel.bodyWidth, height: panel.bodyHeight + 6)
            .clipShape(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func startBreath() {
        breath = false
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            breath = true
        }
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    init<S: Shape>(_ shape: S) {
        self._path = { shape.path(in: $0) }
    }
    func path(in rect: CGRect) -> Path { _path(rect) }
}
