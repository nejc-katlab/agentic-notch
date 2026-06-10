import SwiftUI

struct NotchPanelShape: Shape {
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    var bodyWidth: CGFloat
    var bodyHeight: CGFloat
    let notchTopRadius: CGFloat
    let notchBottomRadius: CGFloat
    let bodyCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(bodyWidth, bodyHeight) }
        set {
            bodyWidth = newValue.first
            bodyHeight = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let nL = cx - notchWidth / 2
        let nR = cx + notchWidth / 2
        let minBodyW = notchWidth + 2 * notchBottomRadius
        let bw = max(bodyWidth, minBodyW)
        let bL = cx - bw / 2
        let bR = cx + bw / 2
        let topY = rect.minY
        let notchBottomY = topY + notchHeight
        let bodyBottomY = notchBottomY + max(bodyHeight, 0)
        let tR = notchTopRadius
        let nbR = notchBottomRadius
        let br = min(bodyCornerRadius, bw / 2, bodyBottomY)

        p.move(to: CGPoint(x: bL, y: topY))
        p.addLine(to: CGPoint(x: nL, y: topY))

        p.addQuadCurve(
            to: CGPoint(x: nL + tR, y: topY + tR),
            control: CGPoint(x: nL + tR, y: topY)
        )
        p.addLine(to: CGPoint(x: nL + tR, y: notchBottomY - nbR))
        p.addQuadCurve(
            to: CGPoint(x: nL + tR + nbR, y: notchBottomY),
            control: CGPoint(x: nL + tR, y: notchBottomY)
        )
        p.addLine(to: CGPoint(x: nR - tR - nbR, y: notchBottomY))
        p.addQuadCurve(
            to: CGPoint(x: nR - tR, y: notchBottomY - nbR),
            control: CGPoint(x: nR - tR, y: notchBottomY)
        )
        p.addLine(to: CGPoint(x: nR - tR, y: topY + tR))
        p.addQuadCurve(
            to: CGPoint(x: nR, y: topY),
            control: CGPoint(x: nR - tR, y: topY)
        )

        p.addLine(to: CGPoint(x: bR, y: topY))
        p.addLine(to: CGPoint(x: bR, y: bodyBottomY - br))
        p.addQuadCurve(
            to: CGPoint(x: bR - br, y: bodyBottomY),
            control: CGPoint(x: bR, y: bodyBottomY)
        )
        p.addLine(to: CGPoint(x: bL + br, y: bodyBottomY))
        p.addQuadCurve(
            to: CGPoint(x: bL, y: bodyBottomY - br),
            control: CGPoint(x: bL, y: bodyBottomY)
        )

        p.closeSubpath()
        return p
    }
}
