import SwiftUI

/// The eras before the one on show, as faint maps stacked away into space behind it like
/// windows in macOS Time Machine, each tagged with its year. Scrubbing back draws the stack
/// forward; the newer eras' maps sweep out past the viewer as they're left behind. With Reduce
/// Motion on, the maps stay put and simply fade.
struct TimeStack: View, Animatable {
    var eras: [HistoricalEra]
    var position: Double
    /// The map card's frame in this view's space, which the stack recedes behind.
    var cardFrame: CGRect
    var silhouette: Image?
    var opacity: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var animatableData: Double {
        get { position }
        set { position = newValue }
    }

    /// How many maps show behind the one in front.
    private static let depth = 6.0

    var body: some View {
        ZStack {
            ForEach(Array(eras.enumerated()).reversed(), id: \.element.id) { index, era in
                let depth = position - Double(index)
                if depth > -1, depth < Self.depth, abs(depth) > 0.01 {
                    ghost(era: era, depth: depth)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func ghost(era: HistoricalEra, depth: Double) -> some View {
        let steady = reduceMotion ? 0 : 1.0
        let recede = pow(0.86, max(depth, 0))
        let scale = depth >= 0 ? 1 - (1 - recede) * steady : 1 + 0.55 * -depth * steady
        // Each map's top edge rises above the one in front, the deepest almost to the top of the
        // room above the card; the maps leaving sweep down and out toward the viewer.
        let room = max(cardFrame.minY - 26, 30)
        let rise = (depth >= 0 ? room * (1 - recede) / (1 - pow(0.86, Self.depth)) : -cardFrame.height * 0.35 * -depth) * steady
        let fade = depth >= 0 ? min(depth, 1) * max(0, 1 - depth / Self.depth) * 0.6 : (1 + depth) * 0.45
        return GhostCard(title: era.isToday ? "Today" : String(era.year), size: cardFrame.size, silhouette: silhouette)
            .scaleEffect(scale, anchor: depth >= 0 ? .top : .center)
            .position(x: cardFrame.midX, y: cardFrame.midY - 10 - rise)
            .opacity(fade * opacity)
            .blur(radius: reduceMotion ? 0 : depth < 0 ? 6 * -depth : max(depth - 3, 0))
    }

    /// The world's land in white, at twice the size it's shown, to fill the stacked maps. Drawn
    /// once, off the main thread, as one shape.
    nonisolated static func silhouette(of geometry: HistoryMapGeometry, width: CGFloat = 640) -> CGImage? {
        let bounds = geometry.bounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let size = CGSize(width: width * 2, height: (width * bounds.height / bounds.width).rounded() * 2)
        guard let context = CGContext(
            data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        // Core Graphics counts up from the bottom; maps count down from the top.
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.concatenate(geometry.transform(in: size, camera: .whole, inset: 0))
        let land = CGMutablePath()
        for path in geometry.unitPaths { land.addPath(path.cgPath) }
        context.addPath(land)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fillPath()
        return context.makeImage()
    }
}

/// One of the faint maps in the stack: its year above a dark card of the world's land.
private struct GhostCard: View {
    var title: String
    var size: CGSize
    var silhouette: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .padding(.leading, 6)
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.09, blue: 0.2).opacity(0.85))
                if let silhouette {
                    silhouette
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width - 24, height: size.height - 24)
                        .clipped()
                        .opacity(0.45)
                }
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            }
            .frame(width: size.width, height: size.height)
        }
    }
}
