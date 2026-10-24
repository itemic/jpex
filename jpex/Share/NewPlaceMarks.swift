import SwiftUI

/// The places just been to, marked on the card's map for the new layout: a sparkle in each one's
/// colour where it is, and its name beside it, above or below or to one side, wherever it covers no
/// other, with a soft halo so it reads over the map. They glide with the map as it's framed.
struct NewPlaceMarks: View, Animatable {
    var map: TravelMap
    var places: [Mark]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var focus: CGRect
    var insets: EdgeInsets

    struct Mark {
        var id: String
        var name: String
        var color: Color
    }

    var animatableData: CGRect.AnimatableData {
        get { focus.animatableData }
        set { focus.animatableData = newValue }
    }

    /// The most places named, so a long list of new places marks the map rather than covers it.
    private static let most = 12

    var body: some View {
        Canvas { context, size in
            let transform = ShareCardMap.transform(fitting: focus, into: ShareCardMap.fitRect(in: size, insets: insets))
            guard transform.a > 0, transform.a.isFinite else { return }
            let card = CGRect(origin: .zero, size: size).insetBy(dx: 12, dy: 12)
            let regions = Dictionary(map.regions.map { ($0.id, $0) }) { first, _ in first }
            let halo = palette.halo ?? (palette.colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.9))
            var marked = context
            marked.addFilter(.shadow(color: halo, radius: 2.5))
            marked.addFilter(.shadow(color: halo, radius: 0.8))
            marked.drawLayer { layer in
                var taken: [CGRect] = []
                for place in places.prefix(Self.most) {
                    guard let region = regions[place.id] else { continue }
                    let point = region.center.applying(transform)
                    guard card.contains(point) else { continue }
                    layer.fill(Self.sparkle(at: point, radius: 7), with: .color(place.color))
                    taken.append(CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14))
                    let name = layer.resolve(
                        Text(place.name)
                            .placeName(language)
                            .font(.system(size: 13, weight: .bold, design: palette.fontDesign))
                            .foregroundStyle(palette.text))
                    let measured = name.measure(in: CGSize(width: 240, height: 60))
                    // Above the sparkle, below it, or beside it, wherever it fits.
                    let spots = [
                        CGRect(x: point.x - measured.width / 2, y: point.y - 10 - measured.height, width: measured.width, height: measured.height),
                        CGRect(x: point.x - measured.width / 2, y: point.y + 10, width: measured.width, height: measured.height),
                        CGRect(x: point.x + 11, y: point.y - measured.height / 2, width: measured.width, height: measured.height),
                        CGRect(x: point.x - 11 - measured.width, y: point.y - measured.height / 2, width: measured.width, height: measured.height),
                    ]
                    guard let spot = spots.first(where: { spot in
                        card.contains(spot) && !taken.contains { $0.intersects(spot.insetBy(dx: -2, dy: -1)) }
                    }) else { continue }
                    layer.draw(name, in: spot)
                    taken.append(spot)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// A four-pointed star, its points long and its waist narrow.
    private static func sparkle(at center: CGPoint, radius: CGFloat) -> Path {
        let waist = radius * 0.24
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y - waist))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y + waist))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y + waist))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y - waist))
        path.closeSubpath()
        return path
    }
}
