import SwiftUI
import UIKit

/// The list's map as a sticker, peeled off the page and flown to where the share card stands. As it
/// peels, its bottom trailing corner folds back over the map, showing the sticker's pale backing and
/// casting a soft shadow, the page showing through where the corner lay. Then it lifts away, arcing
/// over to its landing place and turning a little as it goes, its shadow deepening as it rises and
/// its corners rounding into a card's. Run backwards, it flies home and sticks back down.
struct PeelingSticker: View {
    var image: UIImage
    /// Where it lies on the page, and where it lands.
    var from: CGRect
    var to: CGRect
    /// How far it's flown, from 0 on the page to 1 landed.
    var flight: Double
    /// How far its corner has folded back, from 0, flat, to 1, folded a little under half way across.
    var peel: Double
    /// How round its corners are once it's landed, as the card's.
    var landedCornerRadius: CGFloat

    var body: some View {
        // The fold and the flight move apart, each on its own curve, so neither cuts the other short.
        StickerFace(image: image, peel: peel)
            .modifier(StickerFlight(from: from, to: to, flight: flight, landedCornerRadius: landedCornerRadius))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The sticker itself: the map, its bottom trailing corner folded back over it as far as it's
/// peeled, the sticker's pale backing showing and casting a soft shadow, the page showing through
/// where the corner lay.
private struct StickerFace: View, Animatable {
    var image: UIImage
    var peel: Double

    var animatableData: Double {
        get { peel }
        set { peel = newValue }
    }

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        // Coming away from the page as its corner lifts.
        .shadow(color: .black.opacity(0.16 * min(peel * 1.5, 1)), radius: 6, y: 4)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        let fold = Fold(size: size, peel: peel)
        var face = context
        if let fold { face.clip(to: fold.flat) }
        face.draw(Image(uiImage: image), in: bounds)
        guard let fold else { return }
        // The folded corner's shadow, falling on the map beneath it.
        var shadow = context
        shadow.clip(to: fold.flat)
        shadow.addFilter(.blur(radius: 5))
        shadow.fill(fold.flap.offsetBy(dx: 3, dy: 4), with: .color(.black.opacity(0.3)))
        // The sticker's pale backing, darker in the fold and lightest where it curls over.
        context.fill(
            fold.flap,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(white: 0.74), location: 0),
                    .init(color: Color(white: 0.98), location: 0.35),
                    .init(color: Color(white: 0.9), location: 1),
                ]),
                startPoint: fold.crease, endPoint: fold.tip))
        context.stroke(fold.flap, with: .color(.black.opacity(0.08)), lineWidth: 0.5)
    }
}

/// The sticker's flight from the page to the card's place: lifting off, arcing over and landing,
/// turning a little as it goes, its shadow deepening as it rises and its corners rounding into a
/// card's. Square on the page, as the list's map is.
private struct StickerFlight: ViewModifier, Animatable {
    var from: CGRect
    var to: CGRect
    var flight: Double
    var landedCornerRadius: CGFloat

    var animatableData: Double {
        get { flight }
        set { flight = newValue }
    }

    func body(content: Content) -> some View {
        // Highest half way over, where it also turns furthest and comes nearest.
        let arc = sin(flight * .pi)
        let rect = CGRect(
            x: from.minX + (to.minX - from.minX) * flight, y: from.minY + (to.minY - from.minY) * flight,
            width: from.width + (to.width - from.width) * flight,
            height: from.height + (to.height - from.height) * flight)
        content
            .frame(width: rect.width, height: rect.height)
            .clipShape(RoundedRectangle(cornerRadius: landedCornerRadius * min(1, flight * 1.6), style: .continuous))
            .scaleEffect(1 + 0.06 * arc)
            .rotationEffect(.degrees(-7 * arc))
            .shadow(color: .black.opacity(0.24 * min(1, flight * 2)), radius: 4 + 18 * flight + 8 * arc, y: 2 + 14 * flight + 10 * arc)
            .position(x: rect.midX, y: rect.midY - 36 * arc)
    }
}

/// The fold across a sticker's bottom trailing corner: the part still lying flat, and the corner
/// folded back over it.
private struct Fold {
    var flat: Path
    var flap: Path
    /// The middle of the fold, and the folded corner's tip, for shading the backing between them.
    var crease: CGPoint
    var tip: CGPoint

    init?(size: CGSize, peel: Double) {
        guard peel > 0.001 else { return nil }
        let reach = min(size.width, size.height) * 0.46 * peel
        // A little further along the foot than up the side, as a corner pulled up and across.
        let side = CGPoint(x: size.width, y: size.height - reach)
        let foot = CGPoint(x: size.width - min(reach * 1.25, size.width * 0.9), y: size.height)
        let corner = CGPoint(x: size.width, y: size.height)
        // The corner reflected over the fold, through the nearest point of the fold to it.
        let along = CGVector(dx: foot.x - side.x, dy: foot.y - side.y)
        let length = max(hypot(along.dx, along.dy), 0.001)
        let unit = CGVector(dx: along.dx / length, dy: along.dy / length)
        let distance = (corner.x - side.x) * unit.dx + (corner.y - side.y) * unit.dy
        let nearest = CGPoint(x: side.x + unit.dx * distance, y: side.y + unit.dy * distance)
        tip = CGPoint(x: 2 * nearest.x - corner.x, y: 2 * nearest.y - corner.y)
        crease = CGPoint(x: (side.x + foot.x) / 2, y: (side.y + foot.y) / 2)
        var flat = Path()
        flat.move(to: .zero)
        flat.addLine(to: CGPoint(x: size.width, y: 0))
        flat.addLine(to: side)
        flat.addLine(to: foot)
        flat.addLine(to: CGPoint(x: 0, y: size.height))
        flat.closeSubpath()
        self.flat = flat
        var flap = Path()
        flap.move(to: side)
        flap.addLine(to: tip)
        flap.addLine(to: foot)
        flap.closeSubpath()
        self.flap = flap
    }
}
