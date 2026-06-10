import SwiftUI

enum PanelMetrics {
    static let rowHeight: CGFloat = 46
    static let dividerHeight: CGFloat = 1
    static let rowSpacing: CGFloat = 2
    static let topPadding: CGFloat = 28
    static let bottomPadding: CGFloat = 4
    static let emptyHeight: CGFloat = 96
    static let settingsHeight: CGFloat = 248

    static func contentHeight(forSessions count: Int) -> CGFloat {
        guard count > 0 else { return emptyHeight }
        let childCount = count * 2
        let blocks = CGFloat(count) * (rowHeight + dividerHeight)
        let spacing = CGFloat(childCount - 1) * rowSpacing
        return topPadding + blocks + spacing + bottomPadding
    }
}

@MainActor
final class PanelState: ObservableObject {
    @Published var expanded: Bool = false
    @Published var settingsOpen: Bool = false
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
        let base = settingsOpen ? max(contentHeight, PanelMetrics.settingsHeight) : contentHeight
        return min(max(base, minExpandedBodyHeight), maxExpandedBodyHeight)
    }

    var bodyWidth: CGFloat { expanded ? expandedBodyWidth : collapsedBodyWidth }
    var bodyHeight: CGFloat { expanded ? expandedBodyHeight : collapsedBodyHeight }
    var maxBodyWidth: CGFloat { expandedBodyWidth }
    var maxBodyHeight: CGFloat { maxExpandedBodyHeight }
}
