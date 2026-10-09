import SwiftUI

/// The app's own Reduce Motion setting. It follows the system's whenever that changes, and can
/// then be turned either way in Settings, so motion can come back even with the system's on.
enum MotionPreference {
    /// Whether the app reduces motion.
    static let storageKey = "reducesMotion"
    /// The system's setting as last seen, to tell when it changes.
    static let systemKey = "lastSystemReducesMotion"
}

extension EnvironmentValues {
    /// Whether the system's own Reduce Motion is on, whatever the app's setting says.
    @Entry var systemReducesMotion = false
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
    @AppStorage(MotionPreference.storageKey) private var reducesMotion = false
    @AppStorage(MotionPreference.systemKey) private var lastSystemReducesMotion = false

    func body(content: Content) -> some View {
        content
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
