import AppKit
import SwiftUI

enum PanelSpace {
    static let name = "agenticNotchPanel"
}

@MainActor
final class HoverCursor {
    static let shared = HoverCursor()
    private var hoveredIds: Set<String> = []
    private var pointing = false

    func set(_ id: String, _ hovering: Bool) {
        if hovering { hoveredIds.insert(id) } else { hoveredIds.remove(id) }
        apply()
    }

    func clear() {
        hoveredIds.removeAll()
        apply()
    }

    func apply() {
        if hoveredIds.isEmpty {
            if pointing {
                pointing = false
                NSCursor.arrow.set()
            }
        } else {
            pointing = true
            NSCursor.pointingHand.set()
        }
    }
}

private struct PanelHoverCursor: ViewModifier {
    let point: CGPoint?
    let isHovered: Binding<Bool>
    @State private var id = UUID().uuidString

    func body(content: Content) -> some View {
        content
            .panelHover(point, isHovered) { HoverCursor.shared.set(id, $0) }
            .onDisappear { HoverCursor.shared.set(id, false) }
    }
}

extension View {
    func panelHover(
        _ point: CGPoint?,
        _ isHovered: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) -> some View {
        overlay(
            GeometryReader { geo -> Color in
                let inside = point.map { geo.frame(in: .named(PanelSpace.name)).contains($0) } ?? false
                if isHovered.wrappedValue != inside {
                    DispatchQueue.main.async {
                        isHovered.wrappedValue = inside
                        onChange?(inside)
                    }
                }
                return Color.clear
            }
            .allowsHitTesting(false)
        )
    }

    func panelHoverCursor(_ point: CGPoint?, _ isHovered: Binding<Bool>) -> some View {
        modifier(PanelHoverCursor(point: point, isHovered: isHovered))
    }
}
