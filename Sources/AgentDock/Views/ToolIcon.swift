import SwiftUI

struct ToolIcon: View {
    let tool: String

    var body: some View {
        if let spec = ToolIconCatalog.spec(for: tool) {
            SVGPathShape(path: spec.path)
                .fill(spec.style)
        } else {
            Text(String(tool.prefix(2)).uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

struct SVGPathShape: Shape {
    let path: Path

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        let transform = CGAffineTransform(
            translationX: rect.midX - 12 * scale,
            y: rect.midY - 12 * scale
        ).scaledBy(x: scale, y: scale)
        return path.applying(transform)
    }
}

enum ToolIconCatalog {
    struct Spec {
        let path: Path
        let style: AnyShapeStyle
    }

    static func spec(for tool: String) -> Spec? { specs[tool] }

    private static let white = AnyShapeStyle(Color.white.opacity(0.92))

    private static let specs: [String: Spec] = [
        "claude-code": Spec(
            path: SVGPathParser.parse(claude),
            style: AnyShapeStyle(Color(red: 0.851, green: 0.467, blue: 0.341))
        ),
        "codex": Spec(path: SVGPathParser.parse(openAI), style: white),
        "gemini": Spec(
            path: SVGPathParser.parse(gemini),
            style: AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.59, blue: 0.96),
                    Color(red: 0.66, green: 0.52, blue: 0.91),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        ),
        "opencode": Spec(path: SVGPathParser.parse(openCode), style: white),
        "cursor": Spec(path: SVGPathParser.parse(cursor), style: white),
    ]

    private static let claude = "m4.7144 15.9555 4.7174-2.6471.079-.2307-.079-.1275h-.2307l-.7893-.0486-2.6956-.0729-2.3375-.0971-2.2646-.1214-.5707-.1215-.5343-.7042.0546-.3522.4797-.3218.686.0608 1.5179.1032 2.2767.1578 1.6514.0972 2.4468.255h.3886l.0546-.1579-.1336-.0971-.1032-.0972L6.973 9.8356l-2.55-1.6879-1.3356-.9714-.7225-.4918-.3643-.4614-.1578-1.0078.6557-.7225.8803.0607.2246.0607.8925.686 1.9064 1.4754 2.4893 1.8336.3643.3035.1457-.1032.0182-.0728-.164-.2733-1.3539-2.4467-1.445-2.4893-.6435-1.032-.17-.6194c-.0607-.255-.1032-.4674-.1032-.7285L6.287.1335 6.6997 0l.9957.1336.419.3642.6192 1.4147 1.0018 2.2282 1.5543 3.0296.4553.8985.2429.8318.091.255h.1579v-.1457l.1275-1.706.2368-2.0947.2307-2.6957.0789-.7589.3764-.9107.7468-.4918.5828.2793.4797.686-.0668.4433-.2853 1.8517-.5586 2.9021-.3643 1.9429h.2125l.2429-.2429.9835-1.3053 1.6514-2.0643.7286-.8196.85-.9046.5464-.4311h1.0321l.759 1.1293-.34 1.1657-1.0625 1.3478-.8804 1.1414-1.2628 1.7-.7893 1.36.0729.1093.1882-.0183 2.8535-.607 1.5421-.2794 1.8396-.3157.8318.3886.091.3946-.3278.8075-1.967.4857-2.3072.4614-3.4364.8136-.0425.0304.0486.0607 1.5482.1457.6618.0364h1.621l3.0175.2247.7892.522.4736.6376-.079.4857-1.2142.6193-1.6393-.3886-3.825-.9107-1.3113-.3279h-.1822v.1093l1.0929 1.0686 2.0035 1.8092 2.5075 2.3314.1275.5768-.3218.4554-.34-.0486-2.2039-1.6575-.85-.7468-1.9246-1.621h-.1275v.17l.4432.6496 2.3436 3.5214.1214 1.0807-.17.3521-.6071.2125-.6679-.1214-1.3721-1.9246L14.38 17.959l-1.1414-1.9428-.1397.079-.674 7.2552-.3156.3703-.7286.2793-.6071-.4614-.3218-.7468.3218-1.4753.3886-1.9246.3157-1.53.2853-1.9004.17-.6314-.0121-.0425-.1397.0182-1.4328 1.9672-2.1796 2.9446-1.7243 1.8456-.4128.164-.7164-.3704.0667-.6618.4008-.5889 2.386-3.0357 1.4389-1.882.929-1.0868-.0062-.1579h-.0546l-6.3385 4.1164-1.1293.1457-.4857-.4554.0608-.7467.2307-.2429 1.9064-1.3114Z"

    private static let openAI = "M22.2819 9.8211a5.9847 5.9847 0 0 0-.5157-4.9108 6.0462 6.0462 0 0 0-6.5098-2.9A6.0651 6.0651 0 0 0 4.9807 4.1818a5.9847 5.9847 0 0 0-3.9977 2.9 6.0462 6.0462 0 0 0 .7427 7.0966 5.98 5.98 0 0 0 .511 4.9107 6.051 6.051 0 0 0 6.5146 2.9001A5.9847 5.9847 0 0 0 13.2599 24a6.0557 6.0557 0 0 0 5.7718-4.2058 5.9894 5.9894 0 0 0 3.9977-2.9001 6.0557 6.0557 0 0 0-.7475-7.0729zm-9.022 12.6081a4.4755 4.4755 0 0 1-2.8764-1.0408l.1419-.0804 4.7783-2.7582a.7948.7948 0 0 0 .3927-.6813v-6.7369l2.02 1.1686a.071.071 0 0 1 .038.052v5.5826a4.504 4.504 0 0 1-4.4945 4.4944zm-9.6607-4.1254a4.4708 4.4708 0 0 1-.5346-3.0137l.142.0852 4.783 2.7582a.7712.7712 0 0 0 .7806 0l5.8428-3.3685v2.3324a.0804.0804 0 0 1-.0332.0615L9.74 19.9502a4.4992 4.4992 0 0 1-6.1408-1.6464zM2.3408 7.8956a4.485 4.485 0 0 1 2.3655-1.9728V11.6a.7664.7664 0 0 0 .3879.6765l5.8144 3.3543-2.0201 1.1685a.0757.0757 0 0 1-.071 0l-4.8303-2.7865A4.504 4.504 0 0 1 2.3408 7.872zm16.5963 3.8558L13.1038 8.364 15.1192 7.2a.0757.0757 0 0 1 .071 0l4.8303 2.7913a4.4944 4.4944 0 0 1-.6765 8.1042v-5.6772a.79.79 0 0 0-.407-.667zm2.0107-3.0231l-.142-.0852-4.7735-2.7818a.7759.7759 0 0 0-.7854 0L9.409 9.2297V6.8974a.0662.0662 0 0 1 .0284-.0615l4.8303-2.7866a4.4992 4.4992 0 0 1 6.6802 4.66zM8.3065 12.863l-2.02-1.1638a.0804.0804 0 0 1-.038-.0567V6.0742a4.4992 4.4992 0 0 1 7.3757-3.4537l-.142.0805L8.704 5.459a.7948.7948 0 0 0-.3927.6813zm1.0976-2.3654l2.602-1.4998 2.6069 1.4998v2.9994l-2.5974 1.4997-2.6067-1.4997Z"

    private static let gemini = "M11.04 19.32Q12 21.51 12 24q0-2.49.93-4.68.96-2.19 2.58-3.81t3.81-2.55Q21.51 12 24 12q-2.49 0-4.68-.93a12.3 12.3 0 0 1-3.81-2.58 12.3 12.3 0 0 1-2.58-3.81Q12 2.49 12 0q0 2.49-.96 4.68-.93 2.19-2.55 3.81a12.3 12.3 0 0 1-3.81 2.58Q2.49 12 0 12q2.49 0 4.68.96 2.19.93 3.81 2.55t2.55 3.81"

    private static let openCode = "M22 24H2V0h20zM17 4.8H7v14.4h10z"

    private static let cursor = "M11.503.131 1.891 5.678a.84.84 0 0 0-.42.726v11.188c0 .3.162.575.42.724l9.609 5.55a1 1 0 0 0 .998 0l9.61-5.55a.84.84 0 0 0 .42-.724V6.404a.84.84 0 0 0-.42-.726L12.497.131a1.01 1.01 0 0 0-.996 0M2.657 6.338h18.55c.263 0 .43.287.297.515L12.23 22.918c-.062.107-.229.064-.229-.06V12.335a.59.59 0 0 0-.295-.51l-9.11-5.257c-.109-.063-.064-.23.061-.23"
}

enum SVGPathParser {
    static func parse(_ d: String) -> Path {
        var path = Path()
        let chars = Array(d)
        var i = 0
        var command: Character = " "
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControl: CGPoint?
        var lastQuadControl: CGPoint?

        func skipSeparators() {
            while i < chars.count, chars[i] == " " || chars[i] == "," || chars[i].isNewline || chars[i] == "\t" {
                i += 1
            }
        }

        func number() -> CGFloat? {
            skipSeparators()
            var j = i
            if j < chars.count, chars[j] == "+" || chars[j] == "-" { j += 1 }
            var seenDigit = false
            var seenDot = false
            while j < chars.count {
                let c = chars[j]
                if c.isNumber {
                    seenDigit = true
                    j += 1
                } else if c == ".", !seenDot {
                    seenDot = true
                    j += 1
                } else {
                    break
                }
            }
            if j < chars.count, seenDigit, chars[j] == "e" || chars[j] == "E" {
                var k = j + 1
                if k < chars.count, chars[k] == "+" || chars[k] == "-" { k += 1 }
                var seenExpDigit = false
                while k < chars.count, chars[k].isNumber {
                    seenExpDigit = true
                    k += 1
                }
                if seenExpDigit { j = k }
            }
            guard seenDigit, let value = Double(String(chars[i..<j])) else { return nil }
            i = j
            return CGFloat(value)
        }

        func flag() -> Bool? {
            skipSeparators()
            guard i < chars.count, chars[i] == "0" || chars[i] == "1" else { return nil }
            defer { i += 1 }
            return chars[i] == "1"
        }

        func point(_ x: CGFloat, _ y: CGFloat, relative: Bool) -> CGPoint {
            relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while i < chars.count {
            skipSeparators()
            guard i < chars.count else { break }
            if chars[i].isLetter {
                command = chars[i]
                i += 1
            }
            let relative = command.isLowercase
            switch Character(command.lowercased()) {
            case "m":
                guard let x = number(), let y = number() else { return path }
                current = point(x, y, relative: relative)
                path.move(to: current)
                subpathStart = current
                command = relative ? "l" : "L"
                lastCubicControl = nil
                lastQuadControl = nil
            case "l":
                guard let x = number(), let y = number() else { return path }
                current = point(x, y, relative: relative)
                path.addLine(to: current)
                lastCubicControl = nil
                lastQuadControl = nil
            case "h":
                guard let x = number() else { return path }
                current = CGPoint(x: relative ? current.x + x : x, y: current.y)
                path.addLine(to: current)
                lastCubicControl = nil
                lastQuadControl = nil
            case "v":
                guard let y = number() else { return path }
                current = CGPoint(x: current.x, y: relative ? current.y + y : y)
                path.addLine(to: current)
                lastCubicControl = nil
                lastQuadControl = nil
            case "c":
                guard let x1 = number(), let y1 = number(),
                      let x2 = number(), let y2 = number(),
                      let x = number(), let y = number() else { return path }
                let c1 = point(x1, y1, relative: relative)
                let c2 = point(x2, y2, relative: relative)
                current = point(x, y, relative: relative)
                path.addCurve(to: current, control1: c1, control2: c2)
                lastCubicControl = c2
                lastQuadControl = nil
            case "s":
                guard let x2 = number(), let y2 = number(),
                      let x = number(), let y = number() else { return path }
                let c1 = lastCubicControl.map {
                    CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y)
                } ?? current
                let c2 = point(x2, y2, relative: relative)
                current = point(x, y, relative: relative)
                path.addCurve(to: current, control1: c1, control2: c2)
                lastCubicControl = c2
                lastQuadControl = nil
            case "q":
                guard let x1 = number(), let y1 = number(),
                      let x = number(), let y = number() else { return path }
                let control = point(x1, y1, relative: relative)
                current = point(x, y, relative: relative)
                path.addQuadCurve(to: current, control: control)
                lastQuadControl = control
                lastCubicControl = nil
            case "t":
                guard let x = number(), let y = number() else { return path }
                let control = lastQuadControl.map {
                    CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y)
                } ?? current
                current = point(x, y, relative: relative)
                path.addQuadCurve(to: current, control: control)
                lastQuadControl = control
                lastCubicControl = nil
            case "a":
                guard let rx = number(), let ry = number(), let rotationDegrees = number(),
                      let largeArc = flag(), let sweep = flag(),
                      let x = number(), let y = number() else { return path }
                let end = point(x, y, relative: relative)
                addArc(
                    &path, from: current, to: end,
                    rx: abs(rx), ry: abs(ry),
                    rotation: rotationDegrees * .pi / 180,
                    largeArc: largeArc, sweep: sweep
                )
                current = end
                lastCubicControl = nil
                lastQuadControl = nil
            case "z":
                path.closeSubpath()
                current = subpathStart
                lastCubicControl = nil
                lastQuadControl = nil
            default:
                return path
            }
        }
        return path
    }

    private static func addArc(
        _ path: inout Path, from p1: CGPoint, to p2: CGPoint,
        rx rxIn: CGFloat, ry ryIn: CGFloat,
        rotation: CGFloat, largeArc: Bool, sweep: Bool
    ) {
        if p1 == p2 { return }
        if rxIn == 0 || ryIn == 0 {
            path.addLine(to: p2)
            return
        }
        var rx = rxIn
        var ry = ryIn
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let dx = (p1.x - p2.x) / 2
        let dy = (p1.y - p2.y) / 2
        let x1p = cosR * dx + sinR * dy
        let y1p = -sinR * dx + cosR * dy
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 {
            let s = sqrt(lambda)
            rx *= s
            ry *= s
        }
        let rx2 = rx * rx
        let ry2 = ry * ry
        let numerator = max(0, rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p)
        let denominator = rx2 * y1p * y1p + ry2 * x1p * x1p
        var coefficient = sqrt(numerator / denominator)
        if largeArc == sweep { coefficient = -coefficient }
        let cxp = coefficient * rx * y1p / ry
        let cyp = -coefficient * ry * x1p / rx
        let cx = cosR * cxp - sinR * cyp + (p1.x + p2.x) / 2
        let cy = sinR * cxp + cosR * cyp + (p1.y + p2.y) / 2

        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let dot = ux * vx + uy * vy
            let lengths = sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy))
            var a = acos(min(1, max(-1, dot / lengths)))
            if ux * vy - uy * vx < 0 { a = -a }
            return a
        }

        let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
        var delta = angle(
            (x1p - cxp) / rx, (y1p - cyp) / ry,
            (-x1p - cxp) / rx, (-y1p - cyp) / ry
        )
        if !sweep, delta > 0 { delta -= 2 * .pi }
        if sweep, delta < 0 { delta += 2 * .pi }

        let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
        let step = delta / CGFloat(segments)
        let alpha = 4 / 3 * tan(step / 4)
        var theta = theta1

        func ellipsePoint(_ angle: CGFloat) -> CGPoint {
            CGPoint(
                x: cx + rx * cos(angle) * cosR - ry * sin(angle) * sinR,
                y: cy + rx * cos(angle) * sinR + ry * sin(angle) * cosR
            )
        }

        func ellipseDerivative(_ angle: CGFloat) -> CGPoint {
            CGPoint(
                x: -rx * sin(angle) * cosR - ry * cos(angle) * sinR,
                y: -rx * sin(angle) * sinR + ry * cos(angle) * cosR
            )
        }

        for _ in 0..<segments {
            let start = ellipsePoint(theta)
            let end = ellipsePoint(theta + step)
            let d1 = ellipseDerivative(theta)
            let d2 = ellipseDerivative(theta + step)
            path.addCurve(
                to: end,
                control1: CGPoint(x: start.x + alpha * d1.x, y: start.y + alpha * d1.y),
                control2: CGPoint(x: end.x - alpha * d2.x, y: end.y - alpha * d2.y)
            )
            theta += step
        }
    }
}
