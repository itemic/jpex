import SwiftUI

/// The pins of a kind of plug, as you'd see them looking at its face: Britain's three bars, Europe's
/// two round pins, Australia's slanted blades. Fills a square, centred in the rect it's given.
struct PlugFace: Shape {
    var type: PlugType

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        var path = Path()
        /// A point given as a share of the square.
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * side, y: origin.y + y * side)
        }
        func pin(_ x: CGFloat, _ y: CGFloat, _ diameter: CGFloat) {
            let center = at(x, y)
            let radius = diameter * side / 2
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        }
        /// A flat pin, `width` across and `height` tall, turned `degrees` clockwise about its middle.
        func blade(_ x: CGFloat, _ y: CGFloat, width: CGFloat, height: CGFloat, degrees: CGFloat = 0) {
            let center = at(x, y)
            let bar = CGRect(x: -width * side / 2, y: -height * side / 2, width: width * side, height: height * side)
            let turn = CGAffineTransform(rotationAngle: degrees * .pi / 180)
                .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
            path.addPath(Path(roundedRect: bar, cornerRadius: min(bar.width, bar.height) * 0.3).applying(turn))
        }
        switch type {
        case .a:
            blade(0.34, 0.5, width: 0.09, height: 0.34)
            blade(0.66, 0.5, width: 0.09, height: 0.34)
        case .b:
            blade(0.34, 0.4, width: 0.09, height: 0.3)
            blade(0.66, 0.4, width: 0.09, height: 0.3)
            pin(0.5, 0.76, 0.15)
        case .c:
            pin(0.32, 0.5, 0.15)
            pin(0.68, 0.5, 0.15)
        case .d:
            pin(0.5, 0.3, 0.2)
            pin(0.32, 0.66, 0.14)
            pin(0.68, 0.66, 0.14)
        case .e:
            pin(0.3, 0.56, 0.15)
            pin(0.7, 0.56, 0.15)
            // The socket's earth pin meets a hole in the plug: a ring.
            let center = at(0.5, 0.26)
            let outer = 0.1 * side
            let inner = 0.05 * side
            path.addEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
            path.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
        case .f:
            pin(0.3, 0.5, 0.15)
            pin(0.7, 0.5, 0.15)
            // Earthing clips on either side of the plug.
            blade(0.5, 0.12, width: 0.26, height: 0.07)
            blade(0.5, 0.88, width: 0.26, height: 0.07)
        case .g:
            blade(0.5, 0.3, width: 0.1, height: 0.26)
            blade(0.28, 0.7, width: 0.24, height: 0.1)
            blade(0.72, 0.7, width: 0.24, height: 0.1)
        case .h:
            blade(0.33, 0.38, width: 0.09, height: 0.28, degrees: 35)
            blade(0.67, 0.38, width: 0.09, height: 0.28, degrees: -35)
            blade(0.5, 0.74, width: 0.09, height: 0.26)
        case .i:
            blade(0.33, 0.4, width: 0.09, height: 0.3, degrees: 30)
            blade(0.67, 0.4, width: 0.09, height: 0.3, degrees: -30)
            blade(0.5, 0.76, width: 0.09, height: 0.24)
        case .j:
            pin(0.28, 0.42, 0.14)
            pin(0.72, 0.42, 0.14)
            pin(0.5, 0.68, 0.14)
        case .k:
            pin(0.3, 0.4, 0.15)
            pin(0.7, 0.4, 0.15)
            // Denmark's earth pin is a half-round, flat side up.
            let center = at(0.5, 0.66)
            let radius = 0.11 * side
            path.move(to: CGPoint(x: center.x - radius, y: center.y))
            path.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            path.closeSubpath()
        case .l:
            pin(0.24, 0.5, 0.13)
            pin(0.5, 0.5, 0.13)
            pin(0.76, 0.5, 0.13)
        case .m:
            pin(0.5, 0.28, 0.24)
            pin(0.3, 0.68, 0.17)
            pin(0.7, 0.68, 0.17)
        case .n:
            pin(0.3, 0.58, 0.14)
            pin(0.7, 0.58, 0.14)
            pin(0.5, 0.32, 0.14)
        case .o:
            pin(0.3, 0.38, 0.14)
            pin(0.7, 0.38, 0.14)
            pin(0.5, 0.74, 0.14)
        }
        return path
    }
}

/// A plug's face on a socket plate of its colour, large, as the Atlas's gallery shows it: a soft
/// rounded square, lit from above, with the pins in white.
struct PlugFaceplate: View {
    var type: PlugType

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                    .fill(type.color.gradient)
                    .shadow(color: type.color.opacity(0.35), radius: 4, y: 2)
                // The socket's recess, a shade deeper than the plate.
                Circle()
                    .fill(.black.opacity(0.12))
                    .padding(side * 0.1)
                PlugFace(type: type)
                    .fill(.white, style: FillStyle(eoFill: true))
                    .shadow(color: .black.opacity(0.18), radius: 0.5, y: 0.5)
                    .padding(side * 0.18)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}
