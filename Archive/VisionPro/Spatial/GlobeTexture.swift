#if os(visionOS)
import SwiftUI

/// The World flat and edge to edge, for wrapping round the globe: from 180° west down its left edge
/// to 180° east down its right, and from the North Pole along its top to the South Pole along its
/// foot. It wears the World's colours from space, as the welcome's globe does, with each country
/// that has a level in that level's colour.
@MainActor
enum GlobeTexture {
    /// Twice as wide as it's tall, as the Earth is round its middle and from pole to pole, in points.
    static let size = CGSize(width: 2048, height: 1024)

    static func image(statuses: [String: VisitLevel]) -> CGImage? {
        guard let map = Geography.world?.map(.equirectangular, centerLongitude: 0),
              let edge = map.outline?.boundingRect
        else { return nil }
        let canvas = Canvas { context, size in
            let scale = size.width / edge.width
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(SpaceGlobe.spaceSea))
            context.scaleBy(x: scale, y: size.height / edge.height)
            context.translateBy(x: -edge.minX, y: -edge.minY)
            if let graticule = map.graticule {
                context.stroke(graticule, with: .color(.white.opacity(0.08)), lineWidth: 1 / scale)
            }
            for region in map.regions {
                let level = statuses[region.id] ?? .never
                context.fill(
                    region.path, with: .color(level == .never ? SpaceGlobe.spaceLand : level.color),
                    style: FillStyle(eoFill: true))
            }
            // Borders between countries, but none down the cut at 180°, where the map's two edges
            // meet round the back of the globe.
            let border = 1 / scale
            context.clip(to: Path(edge.insetBy(dx: 2 * border, dy: 0)))
            for region in map.regions {
                context.stroke(region.path, with: .color(SpaceGlobe.spaceBorder), lineWidth: border)
            }
        }
        .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 2
        renderer.isOpaque = true
        return renderer.cgImage
    }
}
#endif
