import SwiftUI

/// The World reshaping between two of World Time's ways of showing it: curling up out of the list's
/// flat map into the dial or the flat time map, unrolling back into the list, or opening out from
/// the dial into the flat map and rolling back up. Every point glides from its place in one
/// projection to its place in the other, while the map flies between the two places on screen,
/// turns, trades the app's own colours for World Time's deep sea and pale land, and settles inside
/// the new shape's edge: a circle closing in for the dial, a card for the flat map. Antarctica,
/// which neither of World Time's shapes shows, fades as it goes.
struct CurlingWorld: View {
    /// Where one end of the reshaping sits on screen, and how it looks there.
    struct Placement {
        /// Points per unit of the map, where the map's origin lands, and the turn about it, in
        /// degrees clockwise.
        var scale: CGFloat
        var origin: CGPoint
        var rotation: Double = 0
        /// The edge the World keeps to, as a rounded rectangle on screen; nil for none, as on the list.
        var clip: CGRect?
        var cornerRadius: CGFloat = 0
        /// In the app's own colours, as on the list, rather than World Time's.
        var wearsAppColors = false
        /// The sea's depth deepening out from the North Pole, as on the dial, or towards both poles,
        /// as on the flat map.
        var hasPolarSea = false
        var hasBandedSea = false
        var showsAntarctica = false
    }

    /// The map partway between the two ends' projections.
    var map: TravelMap
    var statuses: [String: VisitLevel]
    /// The countries' offsets from UTC, by place ID, when World Time colours them by time zone: its
    /// own ends then wear the zones' colours rather than the levels'.
    var zoneOffsets: [String: Int]? = nil
    /// How far it has come, from 0 at `from` to 1 at `to`, already eased.
    var progress: Double
    var from: Placement
    var to: Placement
    /// The app's own appearance, which the map wears on the list.
    var appColorScheme: ColorScheme

    var body: some View {
        Canvas { context, size in
            let t = min(max(progress, 0), 1)
            func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * t }
            func share(_ test: (Placement) -> Bool) -> Double {
                (test(from) ? 1 - t : 0) + (test(to) ? t : 0)
            }
            var app = context.environment
            app.colorScheme = appColorScheme
            let own = context.environment
            let appShare = share(\.wearsAppColors)
            /// A colour as each end wears it, the app's own or World Time's, mixed by how far along it is.
            func color(app appColor: Color, own ownColor: Color) -> Color {
                Color(ownColor.resolve(in: own).mixed(with: appColor.resolve(in: app), by: appShare))
            }

            let scale = mix(from.scale, to.scale)
            let origin = CGPoint(x: mix(from.origin.x, to.origin.x), y: mix(from.origin.y, to.origin.y))
            let rotation = from.rotation + (to.rotation - from.rotation) * t
            let transform = CGAffineTransform(translationX: origin.x, y: origin.y)
                .rotated(by: rotation * .pi / 180)
                .scaledBy(x: scale, y: scale)

            // The edge closes in from the screen's edge, or opens out, between the two shapes.
            let everywhere = CGRect(origin: .zero, size: size).insetBy(dx: -size.width, dy: -size.height)
            let fromClip = from.clip ?? everywhere
            let toClip = to.clip ?? everywhere
            let clip = CGRect(
                x: mix(fromClip.minX, toClip.minX), y: mix(fromClip.minY, toClip.minY),
                width: mix(fromClip.width, toClip.width), height: mix(fromClip.height, toClip.height))
            let corner = min(mix(from.clip == nil ? 0 : from.cornerRadius, to.clip == nil ? 0 : to.cornerRadius), clip.height / 2)
            let edge = Path(roundedRect: clip, cornerRadius: corner, style: .continuous)

            var world = context
            world.clip(to: edge)
            let sea = color(app: Color(uiColor: .systemGray6), own: DialPalette.sea)
            if let outline = map.outline {
                var filled = world
                filled.concatenate(transform)
                filled.fill(outline, with: .color(sea))
            }
            // The dial's sea deepens out from the pole as it settles into the dial.
            let polar = share(\.hasPolarSea)
            if polar > 0.01 {
                var depth = world
                depth.opacity = polar
                depth.concatenate(transform)
                let extent = DialGeometry.extent
                depth.fill(
                    Path(ellipseIn: CGRect(x: -extent, y: -extent, width: extent * 2, height: extent * 2)),
                    with: .radialGradient(
                        Gradient(colors: [DialPalette.seaMiddle, DialPalette.seaEdge]), center: .zero, startRadius: 0, endRadius: extent))
            }
            // The flat map's sea deepens towards the poles as the World settles onto it.
            let banded = share(\.hasBandedSea)
            if banded > 0.01, let card = to.hasBandedSea ? to.clip : from.clip {
                var depth = world
                depth.opacity = banded
                let equator = -FlatGeometry.top / (FlatGeometry.bottom - FlatGeometry.top)
                depth.fill(
                    Path(card),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: DialPalette.seaEdge, location: 0),
                            .init(color: DialPalette.seaMiddle, location: equator),
                            .init(color: DialPalette.seaEdge, location: 1),
                        ]),
                        startPoint: CGPoint(x: card.midX, y: card.minY), endPoint: CGPoint(x: card.midX, y: card.maxY)))
            }
            var lines = world
            lines.concatenate(transform)
            if let graticule = map.graticule {
                lines.stroke(graticule, with: .color(color(app: .primary.opacity(0.06), own: DialPalette.graticule)), lineWidth: 0.6 / scale)
            }
            if let outline = map.outline {
                lines.clip(to: outline)
            }
            let land = color(app: Color(uiColor: .systemGray4), own: DialPalette.land)
            let border = color(app: Color(uiColor: .systemBackground), own: DialPalette.border)
            let antarctica = share(\.showsAntarctica)
            var fills: [String: Color] = [:]
            for region in map.regions {
                let level = statuses[region.id] ?? .never
                var fill = land
                if let offset = zoneOffsets?[region.id] {
                    // The level's colour, or land, on the list; the zone's own in World Time.
                    let key = "\(level.id)/\(offset)"
                    if fills[key] == nil {
                        fills[key] = color(
                            app: level == .never ? Color(uiColor: .systemGray4) : level.color, own: ZonePalette.color(forOffset: offset))
                    }
                    fill = fills[key] ?? land
                } else if level != .never {
                    if fills[level.id] == nil { fills[level.id] = color(app: level.color, own: level.color) }
                    fill = fills[level.id] ?? land
                }
                var layer = lines
                if region.id == DialPalette.antarcticaID { layer.opacity = antarctica }
                layer.fill(region.path, with: .color(fill), style: FillStyle(eoFill: true))
                layer.stroke(region.path, with: .color(border), lineWidth: (0.5 + 0.1 * appShare) / scale)
            }
            // The dial's rim sinks under its ring as the World settles into it.
            if polar > 0.8, let disc = to.hasPolarSea ? to.clip : from.clip {
                var shade = context
                shade.opacity = (polar - 0.8) * 5
                shade.fill(
                    Path(ellipseIn: disc),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: .clear, location: 0.86),
                            .init(color: .black.opacity(0.4), location: 1),
                        ]),
                        center: CGPoint(x: disc.midX, y: disc.midY), startRadius: 0, endRadius: disc.width / 2))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private extension Color.Resolved {
    /// Partway from this colour towards another, in linear light, so the blend doesn't muddy.
    func mixed(with other: Color.Resolved, by amount: Double) -> Color.Resolved {
        let t = Float(min(max(amount, 0), 1))
        var color = self
        color.linearRed += (other.linearRed - linearRed) * t
        color.linearGreen += (other.linearGreen - linearGreen) * t
        color.linearBlue += (other.linearBlue - linearBlue) * t
        color.opacity += (other.opacity - opacity) * t
        return color
    }
}
