import UIKit

/// Puts the whole app back as it was when first opened: every place's level and the levels
/// themselves, the groups of countries and counting presets the person made, their pinned lists,
/// how they like to quiz, the app icon and every other setting. Only the record of what has
/// already happened stays: that the welcome has been seen, the one-time updates to saved places,
/// which would otherwise run again, what's already happened with iCloud, and whether iCloud sync
/// is on. With iCloud sync on, the person's other devices are reset too.
@MainActor
enum AppReset {
    /// Saved values kept through a reset, by key.
    static let keptKeys: Set<String> = [
        "hasSeenWelcome", "raisedCountriesToTheirPlaces", "regionsRaisedToTheirPlaces",
        SaveModel.appliedReorganisationsKey, CloudSync.choiceKey,
    ]

    static func resetEverything(
        saveModel: SaveModel, counting: CountingPreferences, groups: CustomWorldGroups,
        defaults: UserDefaults = .standard
    ) {
        // Every setting the app has saved, so each one, those still to come included, goes back
        // to its default. Settings that views show change in front of the person as they go.
        if let domain = Bundle.main.bundleIdentifier, let saved = defaults.persistentDomain(forName: domain) {
            for key in saved.keys
            where !keptKeys.contains(key) && !key.hasPrefix(CloudSync.recordKeyPrefix) && !isSystemKey(key) {
                defaults.removeObject(forKey: key)
            }
        }
        // Reduce Motion follows the system's again, as it does from the first launch.
        let systemReducesMotion = UIAccessibility.isReduceMotionEnabled
        defaults.set(systemReducesMotion, forKey: MotionPreference.storageKey)
        defaults.set(systemReducesMotion, forKey: MotionPreference.systemKey)
        // What's held in memory too.
        counting.reset()
        groups.deleteAll()
        saveModel.resetEverything()
        NotificationCenter.default.post(name: .everythingDidReset, object: nil)
        // The system tells the person their icon changed.
        if AppIcon.isSupported, AppIcon.current != .japan {
            Task { try? await AppIcon.japan.apply() }
        }
    }

    /// Whether a key is one the system keeps among the app's settings, such as its split view's
    /// state, which is left for the system to manage.
    private static func isSystemKey(_ key: String) -> Bool {
        key.hasPrefix("com.apple.") || key.hasPrefix("Apple") || key.hasPrefix("NS")
    }
}

extension Notification.Name {
    /// Everything was put back as it was when the app was first opened, so screens start afresh.
    static let everythingDidReset = Notification.Name("everythingDidReset")
}
