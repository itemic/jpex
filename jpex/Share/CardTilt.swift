import CoreMotion
import Observation

/// Which way the device leans, for a card on screen to tilt with it and catch the light, as a
/// trading card does in the hand. It's measured from however the device is held, settling slowly to
/// a new way of holding it, so the card rests flat until it's moved.
@MainActor @Observable
final class CardTilt {
    /// From -1 to 1: the right side lowered is positive, the top tipped away is positive.
    private(set) var x = 0.0
    private(set) var y = 0.0
    @ObservationIgnored private let motion = CMMotionManager()
    @ObservationIgnored private var rest: (pitch: Double, roll: Double)?

    /// Whether the device can tell how it's held. Simulator can't.
    var isAvailable: Bool { motion.isDeviceMotionAvailable }

    func start() {
        guard isAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let attitude = data?.attitude else { return }
            let (pitch, roll) = (attitude.pitch, attitude.roll)
            MainActor.assumeIsolated { self?.lean(pitch: pitch, roll: roll) }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        rest = nil
        x = 0
        y = 0
    }

    /// The farthest lean that tilts the card all the way, in radians.
    private static let reach = 0.35

    private func lean(pitch: Double, roll: Double) {
        var rest = rest ?? (pitch, roll)
        // The resting hold drifts towards the current one, so a new way of holding the device
        // becomes flat again in a few seconds.
        rest.pitch += (pitch - rest.pitch) * 0.01
        rest.roll += (roll - rest.roll) * 0.01
        self.rest = rest
        let targetX = max(-1, min(1, (roll - rest.roll) / Self.reach))
        let targetY = max(-1, min(1, (pitch - rest.pitch) / Self.reach))
        // Smoothed, so the card glides rather than jitters.
        x += (targetX - x) * 0.25
        y += (targetY - y) * 0.25
    }
}
