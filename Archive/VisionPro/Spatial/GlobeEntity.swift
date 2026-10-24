#if os(visionOS)
import RealityKit
import SwiftUI

/// The globe in its volume: the Earth leaning on its axis as it does, turned about that axis by
/// `GlobeSpin`, and painted from `GlobeTexture` as places change level.
@MainActor
final class GlobeEntity: Entity {
    /// A desk globe's size, with room round it in its volume.
    static let radius: Float = 0.18

    private static let registration: Void = {
        GlobeSpin.registerComponent()
        GlobeSpinSystem.registerSystem()
    }()

    /// Turns about the axis, carrying the Earth round.
    private let spinner = Entity()
    private let earth = ModelEntity(
        mesh: .generateSphere(radius: GlobeEntity.radius),
        materials: [SimpleMaterial(color: .systemGray5, roughness: 0.7, isMetallic: false)])
    private var texture: TextureResource?

    required init() {
        _ = Self.registration
        super.init()
        earth.components.set([
            InputTargetComponent(),
            CollisionComponent(shapes: [.generateSphere(radius: Self.radius)]),
            HoverEffectComponent(),
            GroundingShadowComponent(castsShadow: true),
        ])
        spinner.components.set(GlobeSpin())
        spinner.addChild(earth)
        addChild(spinner)
        // Leaning 23.4° on its axis, as the Earth does, the North Pole tipped to the right.
        orientation = simd_quatf(angle: -23.44 * .pi / 180, axis: [0, 0, 1])
    }

    /// With Reduce Motion it turns only by hand.
    var reducesMotion: Bool {
        get { spin.reducesMotion }
        set { spin.reducesMotion = newValue }
    }

    /// Paints each country in the colour of its level, as it is now.
    func paint(_ image: CGImage) async {
        let options = TextureResource.CreateOptions(semantic: .color)
        if let texture {
            try? await texture.replace(using: image, options: options)
            return
        }
        guard let made = try? await TextureResource(image: image, options: options) else { return }
        texture = made
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(made))
        material.roughness = 0.7
        material.metallic = 0.0
        earth.model?.materials = [material]
    }

    /// Says how much of the World counts, for VoiceOver.
    func describe(counted: Int, of total: Int) {
        var accessibility = AccessibilityComponent()
        accessibility.isAccessibilityElement = true
        accessibility.label = "Globe"
        accessibility.value = "\(counted) of \(total) countries"
        earth.components.set(accessibility)
    }

    /// Turns it with the hand from where it was when the hand took hold: half a turn as the hand
    /// crosses its width, so the land follows the fingers.
    func turn(by translation: Float, across width: Float) {
        let start = spin.heldFrom ?? spin.angle
        spin.heldFrom = start
        spin.angle = start + translation / max(width, 1) * .pi
    }

    /// Lets go at the hand's speed, in points a second, to carry on turning until it eases back to
    /// its own pace. With Reduce Motion it stays where it's let go.
    func letGo(speed: Float, across width: Float) {
        spin.heldFrom = nil
        spin.speed = spin.reducesMotion ? 0 : speed / max(width, 1) * .pi
    }

    private var spin: GlobeSpin {
        get { spinner.components[GlobeSpin.self] ?? GlobeSpin() }
        set { spinner.components.set(newValue) }
    }
}
#endif
