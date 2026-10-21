import SwiftUI

/// The World as it looks from space: a globe of deep sea lit from the upper left, its land pale,
/// wrapped in a glow of atmosphere. A country's subdivisions can lie over it, traced in white and
/// lit in their levels' colours, and rings of colour spread from places as they light up. As
/// `daylight` runs from 0 to 1, the colours of space give way to the app's own map colours, so a
/// globe unrolling into the World's map can land on a list's map without a seam.
struct SpaceGlobe: View {
    var map: TravelMap
    /// Where the map is drawn, in this view's space.
    var frame: CGRect
    /// How far the view is zoomed in on the map, and where.
    var camera = MapCamera()
    /// Countries' levels; others draw as plain land.
    var statuses: [String: VisitLevel]
    /// A country's subdivisions in the same projection, laid over it.
    var detail: TravelMap?
    var detailStatuses: [String: VisitLevel] = [:]
    /// How much the subdivisions show, from 0 to 1, as they trace in and fade away.
    var detailOpacity: Double = 0
    /// How strongly the subdivisions' levels show, from 1 down to 0 as they drain back to plain land.
    var detailFill: Double = 1
    /// From space's colours at 0 to the app's own map colours at 1.
    var daylight: Double
    /// How much the map still looks like a ball, lit and shaded, from 1 down to 0 as it unrolls flat.
    var roundness: Double
    var ripples: [GlobeRipple] = []
    /// Countries whose borders glow, as Game Mode's lobby lights them.
    var glows: [GlobeGlow] = []

    var body: some View {
        Canvas { context, _ in
            draw(in: &context)
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        guard frame.width > 1, frame.height > 1, let outline = map.outline else { return }
        let geometry = MapGeometry(
            focus: map.focusRect(including: []), size: frame.size, zoom: camera.zoom, pan: camera.pan)
        let transform = geometry.transform.concatenating(CGAffineTransform(translationX: frame.minX, y: frame.minY))
        let scale = geometry.scale
        let ball = outline.boundingRect.applying(transform)
        let night = 1 - daylight
        let environment = context.environment

        let spaceSea = Color(red: 0.07, green: 0.17, blue: 0.36).resolve(in: environment)
        let daySea = Color(uiColor: .systemGray6).resolve(in: environment)
        let spaceLand = Color(red: 0.80, green: 0.86, blue: 0.94).resolve(in: environment)
        let dayLand = Color(uiColor: .systemGray4).resolve(in: environment)
        let spaceBorder = Color(red: 0.05, green: 0.12, blue: 0.27).resolve(in: environment)
        let dayBorder = Color(uiColor: .systemBackground).resolve(in: environment)
        let landResolved = dayLand.blended(toward: spaceLand, by: night)
        let land = Color(landResolved)
        let border = Color(dayBorder.blended(toward: spaceBorder, by: night))

        // Atmosphere: a soft blue haze rising straight off the edge of the world.
        if night * roundness > 0.01 {
            let haze = ball.insetBy(dx: -ball.width * 0.11, dy: -ball.height * 0.11)
            context.fill(
                Path(ellipseIn: haze),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.6),
                        .init(color: Color(red: 0.35, green: 0.62, blue: 1).opacity(0.42 * night * roundness), location: 0.83),
                        .init(color: Color(red: 0.3, green: 0.55, blue: 1).opacity(0.12 * night * roundness), location: 0.92),
                        .init(color: .clear, location: 1),
                    ]),
                    center: CGPoint(x: ball.midX, y: ball.midY), startRadius: 0, endRadius: haze.width / 2))
        }

        var mapContext = context
        mapContext.transform = transform

        // The sea: lit towards the upper left in space, flat grey by day.
        mapContext.fill(outline, with: .color(Color(daySea)))
        if night > 0.01 {
            var sea = context
            sea.opacity = night * roundness
            sea.fill(
                Path(ellipseIn: ball),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.16, green: 0.36, blue: 0.68), Color(spaceSea), Color(red: 0.02, green: 0.05, blue: 0.13),
                    ]),
                    center: CGPoint(x: ball.minX + ball.width * 0.36, y: ball.minY + ball.height * 0.32),
                    startRadius: 0, endRadius: max(ball.width, ball.height) * 0.78))
            // Flattening, the sea takes the map's own shape.
            if roundness < 1 {
                var flat = mapContext
                flat.opacity = night * (1 - roundness)
                flat.fill(outline, with: .color(Color(spaceSea)))
            }
        }
        if let graticule = map.graticule {
            let line = Color.white.opacity(0.08).resolve(in: environment)
                .blended(toward: Color.primary.opacity(0.06).resolve(in: environment), by: daylight)
            mapContext.stroke(graticule, with: .color(Color(line)), lineWidth: 0.5 / scale)
        }

        // Land, each country in its level's colour where it has one.
        for region in map.regions {
            let level = statuses[region.id] ?? .never
            mapContext.fill(region.path, with: .color(level == .never ? land : level.color), style: FillStyle(eoFill: true))
        }
        for region in map.regions {
            mapContext.stroke(region.path, with: .color(border), lineWidth: 0.6 / scale)
        }

        // A country's subdivisions, traced in light and lit in their levels' colours.
        if let detail, detailOpacity > 0.01 {
            var layer = mapContext
            layer.opacity = detailOpacity
            if detailFill > 0.01 {
                for region in detail.regions {
                    let level = detailStatuses[region.id] ?? .never
                    guard level != .never else { continue }
                    let lit = landResolved.blended(toward: level.color.resolve(in: environment), by: detailFill)
                    layer.fill(region.path, with: .color(Color(lit)), style: FillStyle(eoFill: true))
                }
            }
            let trace = Color.white.opacity(0.75).resolve(in: environment).blended(toward: dayBorder, by: daylight)
            for region in detail.regions {
                layer.stroke(region.path, with: .color(Color(trace)), lineWidth: 0.7 / scale)
            }
        }

        // Light and shade, so the ball looks round: dusk towards the lower right, a gleam up top.
        let shading = night * roundness
        if shading > 0.01 {
            context.fill(
                Path(ellipseIn: ball),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.45),
                        .init(color: .black.opacity(0.62 * shading), location: 1),
                    ]),
                    center: CGPoint(x: ball.minX + ball.width * 0.36, y: ball.minY + ball.height * 0.32),
                    startRadius: 0, endRadius: max(ball.width, ball.height) * 0.82))
            context.fill(
                Path(ellipseIn: ball),
                with: .radialGradient(
                    Gradient(colors: [.white.opacity(0.22 * shading), .clear]),
                    center: CGPoint(x: ball.minX + ball.width * 0.3, y: ball.minY + ball.height * 0.24),
                    startRadius: 0, endRadius: ball.width * 0.32))
            // A thin rim of atmosphere catching the light.
            var rim = context
            rim.addFilter(.blur(radius: 2))
            rim.stroke(
                Path(ellipseIn: ball.insetBy(dx: 0.5, dy: 0.5)),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.6, green: 0.82, blue: 1).opacity(0.9 * shading),
                        Color(red: 0.3, green: 0.5, blue: 1).opacity(0.15 * shading),
                    ]),
                    startPoint: CGPoint(x: ball.minX, y: ball.minY), endPoint: CGPoint(x: ball.maxX, y: ball.maxY)),
                lineWidth: 2.5)
        }

        // By day, the map's edge as the lists draw it.
        if daylight > 0.01 {
            mapContext.stroke(outline, with: .color(.primary.opacity(0.12 * daylight)), lineWidth: 0.75 / scale)
        }

        // Glowing borders, over the shading, as if lit from within: a soft halo in the glow's colour,
        // a wash of it inside, and a fine white edge, kept to the country's main body.
        for glow in glows where glow.strength > 0.01 {
            guard let region = map.region(id: glow.regionID) else { continue }
            let edge = region.path.applying(transform)
            var lit = context
            lit.opacity = glow.strength * (1 - daylight)
            if let body = glow.body?.applying(transform) {
                let reach = max(body.width, body.height) * 0.25 + 16
                lit.clip(to: Path(body.insetBy(dx: -reach, dy: -reach)))
            }
            lit.drawLayer { halo in
                halo.addFilter(.blur(radius: 5))
                halo.stroke(edge, with: .color(glow.color), lineWidth: 6)
            }
            lit.fill(edge, with: .color(glow.color.opacity(0.4)), style: FillStyle(eoFill: true))
            lit.stroke(edge, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
        }

        // Rings of colour spreading out from places as they light up, fading as they go.
        for ripple in ripples where ripple.progress > 0 && ripple.progress < 1 {
            let eased = 1 - pow(1 - ripple.progress, 3)
            let center = ripple.center.applying(transform)
            let radius = 6 + ripple.reach * eased
            var ring = context
            ring.addFilter(.blur(radius: 1.5))
            ring.stroke(
                Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                with: .color(ripple.color.opacity(0.9 * (1 - ripple.progress))),
                lineWidth: 1.5 + 4 * (1 - ripple.progress))
        }
    }
}

/// A ring of colour spreading out from a place as it lights up.
struct GlobeRipple {
    /// Where it starts, in the map's own units.
    var center: CGPoint
    var color: Color
    /// From 0 as it starts to 1 as it fades away.
    var progress: Double
    /// How far it spreads, in points.
    var reach: Double = 60
}

/// A country whose borders glow on the globe.
struct GlobeGlow {
    var regionID: String
    var color: Color
    /// How brightly, from 0 for not at all to 1.
    var strength: Double
    /// The country's main body, in the map's own units, for the glow to keep to, leaving
    /// far-flung islands dark.
    var body: CGRect?
}

private extension Color.Resolved {
    /// Partway from this colour towards another, in linear light, so the blend doesn't muddy.
    func blended(toward other: Color.Resolved, by amount: Double) -> Color.Resolved {
        let t = Float(min(max(amount, 0), 1))
        var color = self
        color.linearRed += (other.linearRed - linearRed) * t
        color.linearGreen += (other.linearGreen - linearGreen) * t
        color.linearBlue += (other.linearBlue - linearBlue) * t
        color.opacity += (other.opacity - opacity) * t
        return color
    }
}
