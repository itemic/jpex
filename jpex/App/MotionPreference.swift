import Combine
import SwiftUI

/// The app's own Reduce Motion setting. It follows the system's whenever that changes, and can
/// then be turned either way in Settings, so motion can come back even with the system's on.
enum MotionPreference {
    /// Whether the app reduces motion.
    static let storageKey = "reducesMotion"
    /// The system's setting as last seen, to tell when it changes.
    static let systemKey = "lastSystemReducesMotion"
}

/// The app's words for how things move, so a press, a hop or a page coming in feels the same
/// wherever it happens. Springs answer whatever a person did; eased curves are kept for things that
/// simply fade or leave. With Reduce Motion, a spring that moves or scales something becomes a short
/// ease (`still`), and scrolls and zooms happen at once rather than gliding.
enum Motion {
    /// A finger pressing a control, which gives a little and springs back.
    static let press = Animation.bouncy(duration: 0.3, extraBounce: 0.15)
    /// A marker hopping from one choice to the next, such as a ring between badges.
    static let hop = Animation.snappy(duration: 0.3, extraBounce: 0.12)
    /// Something arriving: a picker opening, a badge landing.
    static let arrive = Animation.bouncy(duration: 0.45, extraBounce: 0.1)
    /// Something going away, quietly, so it never pulls the eye.
    static let leave = Animation.smooth(duration: 0.25)
    /// A number rolling to its new value, and the tally bar beside it.
    static let count = Animation.snappy(duration: 0.4)
    /// A colour washing to a new level's.
    static let recolour = Animation.smooth(duration: 0.6)
    /// Rows and panels changing size or place, such as the rows after a pinch.
    static let layout = Animation.smooth(duration: 0.45)
    /// The list gliding to a place or region it was asked to show.
    static let glide = Animation.smooth(duration: 0.6)
    /// A camera pulling back out to the whole map.
    static let pullBack = Animation.smooth(duration: 0.8)
    /// A light settling back after it has been seen.
    static let afterglow = Animation.smooth(duration: 1.2)
    /// One page slipping away before the next comes in.
    static let pageOut = Animation.easeOut(duration: 0.15)
    /// The next page rising gently into the room the last one left.
    static let pageIn = Animation.smooth(duration: 0.4).delay(0.1)
    /// What a spring that moves or scales something becomes with Reduce Motion: a short ease,
    /// so the change still reads as a change without anything travelling.
    static let still = Animation.easeOut(duration: 0.2)

    /// How far behind the one before each of a row of things arrives, such as badges, never
    /// holding the last back more than four tenths of a second.
    static func stagger(_ index: Int) -> Double {
        min(Double(index) * 0.03, 0.4)
    }

    /// A spring that moves or scales something, or `still` with Reduce Motion.
    static func moving(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? still : animation
    }

    /// A scroll or a zoom, which with Reduce Motion happens at once rather than gliding there.
    static func travelling(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

extension EnvironmentValues {
    /// Whether the system's own Reduce Motion is on, whatever the app's setting says.
    @Entry var systemReducesMotion = false
    /// Whether decoration that moves by itself may play: a globe turning on its own, names gliding
    /// to show their ends, a glow breathing. Off while the app isn't in front, in Low Power Mode,
    /// and with Reduce Motion, so nothing animates for no one or at the battery's expense.
    @Entry var allowsAmbientMotion = true
}

extension View {
    /// Applies the app's Reduce Motion setting to everything inside, in place of the system's,
    /// so views that read `accessibilityReduceMotion` follow the app's choice.
    func appliesMotionPreference() -> some View {
        modifier(MotionPreferenceModifier())
    }
}

private struct MotionPreferenceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReducesMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(MotionPreference.storageKey) private var reducesMotion = false
    @AppStorage(MotionPreference.systemKey) private var lastSystemReducesMotion = false
    @State private var isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    func body(content: Content) -> some View {
        content
            .environment(\.allowsAmbientMotion, scenePhase != .background && scenePhase != .inactive && !isLowPower && !reducesMotion)
            .onReceive(
                NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange).receive(on: RunLoop.main)
            ) { _ in
                isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
            // The underscored value is the one that can be set; `accessibilityReduceMotion` reads it.
            .environment(\._accessibilityReduceMotion, reducesMotion)
            .environment(\.systemReducesMotion, systemReducesMotion)
            .onChange(of: systemReducesMotion, initial: true) { _, system in
                // Turning the system's setting on or off carries the app's with it; a choice made in
                // Settings stays until the system's changes again.
                guard system != lastSystemReducesMotion else { return }
                lastSystemReducesMotion = system
                reducesMotion = system
            }
    }
}
