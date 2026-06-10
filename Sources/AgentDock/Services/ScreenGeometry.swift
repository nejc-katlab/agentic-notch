import AppKit

enum NotchLayout {
    case notched(notchWidth: CGFloat, notchHeight: CGFloat)
    case fallback(menuBarHeight: CGFloat)

    var topInset: CGFloat {
        switch self {
        case .notched(_, let h): return h
        case .fallback(let h): return h
        }
    }

    var collapsedWidth: CGFloat {
        switch self {
        case .notched(let w, _): return min(max(w + 160, 320), 440)
        case .fallback: return 360
        }
    }

    func expandedWidth(for screen: NSScreen) -> CGFloat {
        let target: CGFloat = 420
        let maxAllowed = screen.frame.width - 64
        return min(target, maxAllowed)
    }
}

enum ScreenGeometry {
    static var primary: NSScreen? {
        NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.main
    }

    static func layout(for screen: NSScreen) -> NotchLayout {
        let inset = screen.safeAreaInsets.top
        if inset > 0 {
            let leftAux = screen.auxiliaryTopLeftArea?.width ?? 0
            let rightAux = screen.auxiliaryTopRightArea?.width ?? 0
            let notchWidth = max(0, screen.frame.width - leftAux - rightAux)
            let effectiveNotch = notchWidth > 60 ? notchWidth : 200
            return .notched(notchWidth: effectiveNotch, notchHeight: inset)
        }
        let visibleTop = screen.frame.maxY - screen.visibleFrame.maxY
        return .fallback(menuBarHeight: max(visibleTop, 24))
    }

    static let notchCenterOffsetX: CGFloat = 0

    static func frame(for screen: NSScreen, width: CGFloat, height: CGFloat) -> NSRect {
        let frame = screen.frame
        let notchCx: CGFloat
        if let leftAux = screen.auxiliaryTopLeftArea,
           let rightAux = screen.auxiliaryTopRightArea {
            notchCx = (leftAux.origin.x + leftAux.width + rightAux.origin.x) / 2
        } else {
            notchCx = frame.width / 2
        }
        let targetMidX = frame.origin.x + notchCx + notchCenterOffsetX
        let x = targetMidX - width / 2
        let y = frame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
