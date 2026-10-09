import SwiftUI

/// Guides over Game Mode's board: a veil washing back the places outside the round, and in Find
/// It, a ring around each place too small to see, so it can still be found and tapped. Moves with
/// the camera exactly as the map does.
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
            if !veiled.isEmpty {
                var veil = context
                veil.concatenate(geometry.transform)
                let wash = Color(uiColor: .systemBackground).opacity(0.62)
                for region in map.regions where veiled.contains(region.id) {
                    guard region.bounds.applying(geometry.transform).intersects(visible) else { continue }
                    veil.fill(region.path, with: .color(wash), style: FillStyle(eoFill: true))
                }
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
}
