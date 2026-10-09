import SwiftUI

/// What sits over the flat map and moves on its own: the places of the event in focus glowing
/// and breathing, a pin where it happened, and an outline round the place the person tapped,
/// as it was in the era on show.
struct HistoryMapOverlay: View, Animatable {
    var geometry: HistoryMapGeometry
    var camera: HistoryCamera
    /// The event's units, and where its pin goes, in longitude and latitude.
    var eventUnits: [Int]
    var eventLocation: CGPoint?
    /// Every unit of the tapped place as it was then, such as all of French West Africa.
    var selectedUnits: [Int]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Follows the camera as it glides, so the glow stays on its places.
    var animatableData: AnimatablePair<CGFloat, CGSize.AnimatableData> {
        get { camera.animatableData }
        set { camera.animatableData = newValue }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || eventUnits.isEmpty && eventLocation == nil)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let transform = geometry.transform(in: size, camera: camera)
                let line = 1 / max(transform.a, 0.0001)
                let breath = reduceMotion ? 0.6 : 0.5 + 0.5 * sin(time * 2.6)
                var map = context
                map.concatenate(transform)

                if !eventUnits.isEmpty {
                    var places = Path()
                    for unit in eventUnits { places.addPath(geometry.unitPaths[unit]) }
                    map.fill(places, with: .color(.white.opacity(0.12 + 0.14 * breath)))
                    var glow = map
                    glow.addFilter(.shadow(color: TimeScrubber.glow.opacity(0.9), radius: 4 + 4 * breath))
                    glow.stroke(places, with: .color(TimeScrubber.glow.opacity(0.9)), lineWidth: 1.2 * line)
                }
                if !selectedUnits.isEmpty {
                    var place = Path()
                    for unit in selectedUnits { place.addPath(geometry.unitPaths[unit]) }
                    var outline = map
                    outline.addFilter(.shadow(color: .black.opacity(0.6), radius: 3))
                    outline.stroke(place, with: .color(.white), lineWidth: 1.6 * line)
                }
                if let eventLocation {
                    let point = geometry.projection.project(eventLocation).applying(transform)
                    let ring = 6 + 10 * (reduceMotion ? 0.5 : (time * 0.8).truncatingRemainder(dividingBy: 1))
                    let fade = reduceMotion ? 0.5 : 1 - (time * 0.8).truncatingRemainder(dividingBy: 1)
                    context.stroke(Path(ellipseIn: CGRect(x: point.x - ring, y: point.y - ring, width: ring * 2, height: ring * 2)),
                                   with: .color(TimeScrubber.glow.opacity(0.8 * fade)), lineWidth: 1.5)
                    var dot = context
                    dot.addFilter(.shadow(color: TimeScrubber.glow, radius: 5))
                    dot.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(.white))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
