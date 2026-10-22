import SwiftUI

/// Guides over Game Mode's board: a veil washing back the places outside the round, and in Find
/// It, a ring around each place too small to see, so it can still be found and tapped, and the
/// places already tried faded out and struck through with fine lines, so they aren't tapped again.
/// Moves with the camera exactly as the map does.
struct GameMapGuides: View, Animatable {
    var map: TravelMap
    var focus: CGRect
    var zoom: CGFloat
    var pan: CGSize
    var insets: EdgeInsets
    /// Regions of places outside the round.
    var veiled: Set<String>
    /// Regions to ring when they're too small to see.
    var ringed: Set<String>
    /// Regions of places already tried for this question, in Find.
    var tried: Set<String> = []
    /// Regions drawn as plain land with no borders between them, as Dot shows the map.
    var plain: Set<String> = []

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGSize.AnimatableData>, EdgeInsets.AnimatableData> {
        get { AnimatablePair(AnimatablePair(zoom, pan.animatableData), insets.animatableData) }
        set {
            zoom = newValue.first.first
            pan.animatableData = newValue.first.second
            insets.animatableData = newValue.second
        }
    }

    var body: some View {
        Canvas { context, size in
            let geometry = MapGeometry(focus: focus, size: size, zoom: zoom, pan: pan, insets: insets)
            let visible = CGRect(origin: .zero, size: size).insetBy(dx: -12, dy: -12)
            let wash = Color(uiColor: .systemBackground)
            if !plain.isEmpty {
                // Land the colour the map gives places not yet answered, its borders covered over.
                var land = context
                land.concatenate(geometry.transform)
                let fill = Color(uiColor: .systemGray4)
                for region in map.regions where plain.contains(region.id) {
                    guard region.bounds.applying(geometry.transform).intersects(visible) else { continue }
                    land.fill(region.path, with: .color(fill), style: FillStyle(eoFill: true))
                    land.stroke(region.path, with: .color(fill), lineWidth: 1.4 / geometry.scale)
                }
            }
            if !veiled.isEmpty {
                var veil = context
                veil.concatenate(geometry.transform)
                for region in map.regions where veiled.contains(region.id) {
                    guard region.bounds.applying(geometry.transform).intersects(visible) else { continue }
                    veil.fill(region.path, with: .color(wash.opacity(0.62)), style: FillStyle(eoFill: true))
                }
            }
            for region in map.regions where tried.contains(region.id) {
                let box = region.bounds.applying(geometry.transform)
                guard box.intersects(visible) else { continue }
                var faded = context
                faded.clip(to: region.path.applying(geometry.transform), style: FillStyle(eoFill: true))
                faded.fill(Path(box), with: .color(wash.opacity(0.72)))
                faded.stroke(Self.hatch(over: box.intersection(visible), from: box.minX), with: .color(.secondary.opacity(0.4)), lineWidth: 1)
            }
            for region in map.regions where ringed.contains(region.id) {
                let box = region.bounds.applying(geometry.transform)
                let center = geometry.toScreen(region.center)
                guard max(box.width, box.height) < 7, visible.contains(center) else { continue }
                let ring = Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
                context.stroke(ring, with: .color(.secondary), lineWidth: 1.25)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Fine lines leaning like a strike-through, hung from `start` so they travel with the place,
    /// covering `area`.
    private static func hatch(over area: CGRect, from start: CGFloat, spacing: CGFloat = 7) -> Path {
        var lines = Path()
        guard !area.isNull, !area.isEmpty else { return lines }
        var x = start + ((area.minX - area.height - start) / spacing).rounded(.down) * spacing
        while x < area.maxX {
            lines.move(to: CGPoint(x: x, y: area.maxY))
            lines.addLine(to: CGPoint(x: x + area.height, y: area.minY))
            x += spacing
        }
        return lines
    }
}
