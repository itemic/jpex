#if os(visionOS)
import RealityKit

/// How the globe turns about its axis: slowly east on its own, the way the Earth does, faster for a
/// while after a fling, and with the hand while it's held.
struct GlobeSpin: Component {
    /// How far it's turned, in radians.
    var angle: Float = 0
    /// How fast it turns, in radians a second.
    var speed: Float = GlobeSpin.drift
    /// The angle it was at when the hand took hold, while it's held.
    var heldFrom: Float?
    /// With Reduce Motion it turns only by hand, and stays where it's let go.
    var reducesMotion = false

    /// Once round every four minutes, west to east, so the land in front moves on and land from
    /// the west comes round.
    static let drift: Float = 2 * .pi / 240
}

/// Turns each globe by its `GlobeSpin` every frame, easing a fling back to the Earth's own pace.
struct GlobeSpinSystem: System {
    private static let query = EntityQuery(where: .has(GlobeSpin.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        let elapsed = Float(context.deltaTime)
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var spin = entity.components[GlobeSpin.self] else { continue }
            if spin.heldFrom == nil {
                let pace = spin.reducesMotion ? 0 : GlobeSpin.drift
                spin.speed = pace + (spin.speed - pace) * exp(-elapsed * 1.2)
                spin.angle += spin.speed * elapsed
                entity.components.set(spin)
            }
            entity.orientation = simd_quatf(angle: spin.angle, axis: [0, 1, 0])
        }
    }
}
#endif
