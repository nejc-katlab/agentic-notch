import SwiftUI

enum PanelSpace {
    static let name = "agenticNotchPanel"
}

extension View {
    func panelHover(_ point: CGPoint?, _ isHovered: Binding<Bool>) -> some View {
        overlay(
            GeometryReader { geo -> Color in
                let inside = point.map { geo.frame(in: .named(PanelSpace.name)).contains($0) } ?? false
                if isHovered.wrappedValue != inside {
                    DispatchQueue.main.async { isHovered.wrappedValue = inside }
                }
                return Color.clear
            }
            .allowsHitTesting(false)
        )
    }
}
