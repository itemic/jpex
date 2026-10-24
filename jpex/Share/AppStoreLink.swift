import SwiftUI

/// The app as the App Store offers it: its name, for a shared map to say it was logged with it.
enum AppStoreLink {
    static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Prefectures"
}
