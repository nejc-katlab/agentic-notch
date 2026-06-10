import SwiftUI

enum PanelMetrics {
    static let rowHeight: CGFloat = 46
    static let rowSpacing: CGFloat = 2
    static let topPadding: CGFloat = 28
    static let bottomPadding: CGFloat = 4
    static let emptyHeight: CGFloat = 96
    static let settingsHeight: CGFloat = 217
    static let statsHeight: CGFloat = 260

    static func contentHeight(forSessions count: Int) -> CGFloat {
        guard count > 0 else { return emptyHeight }
        let rows = CGFloat(count) * rowHeight
        let spacing = CGFloat(count - 1) * rowSpacing
        return topPadding + rows + spacing + bottomPadding
    }
}

enum PanelMode {
    case sessions
    case settings
    case stats
}

@MainActor
final class PanelState: ObservableObject {
    @Published var expanded: Bool = false
    @Published var mode: PanelMode = .sessions
    @Published var hoverPoint: CGPoint?
    @Published var contentHeight: CGFloat = PanelMetrics.emptyHeight

    let collapsedBodyWidth: CGFloat
    let expandedBodyWidth: CGFloat
    let collapsedBodyHeight: CGFloat = 0
    let minExpandedBodyHeight: CGFloat
    let maxExpandedBodyHeight: CGFloat

    init(
        collapsedBodyWidth: CGFloat,
        expandedBodyWidth: CGFloat,
        minExpandedBodyHeight: CGFloat = 60,
        maxExpandedBodyHeight: CGFloat = 600
    ) {
        self.collapsedBodyWidth = collapsedBodyWidth
        self.expandedBodyWidth = expandedBodyWidth
        self.minExpandedBodyHeight = minExpandedBodyHeight
        self.maxExpandedBodyHeight = maxExpandedBodyHeight
    }

    var expandedBodyHeight: CGFloat {
        let base: CGFloat
        switch mode {
        case .sessions: base = contentHeight
        case .settings: base = PanelMetrics.settingsHeight
        case .stats: base = PanelMetrics.statsHeight
        }
        return min(max(base, minExpandedBodyHeight), maxExpandedBodyHeight)
    }

    var bodyWidth: CGFloat { expanded ? expandedBodyWidth : collapsedBodyWidth }
    var bodyHeight: CGFloat { expanded ? expandedBodyHeight : collapsedBodyHeight }
    var maxBodyWidth: CGFloat { expandedBodyWidth }
    var maxBodyHeight: CGFloat { maxExpandedBodyHeight }
}
