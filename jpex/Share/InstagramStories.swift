import SwiftUI
import UIKit

/// Instagram's stories, which a card can go straight into as a sticker over a background of two
/// colours, for the person to move, size and post. Instagram takes a story only from an app that
/// gives its Meta app ID, made at developers.facebook.com. Where Instagram isn't installed, the
/// Instagram button stays hidden and stories go through the share sheet like everything else.
enum InstagramStories {
    /// The app's Meta app ID, which Instagram checks before taking a story.
    static let appID: String? = "1096709973338005"

    private static var url: URL? {
        appID.flatMap { URL(string: "instagram-stories://share?source_application=\($0)") }
    }

    /// Whether Instagram is on this device and the app can send stories to it.
    @MainActor static var isAvailable: Bool {
        guard let url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Opens Instagram's story editor with the card as a sticker over the colours, top to bottom.
    @MainActor static func share(sticker: Data, top: Color, bottom: Color) async -> Bool {
        guard let url else { return false }
        UIPasteboard.general.setItems(
            [[
                "com.instagram.sharedSticker.stickerImage": sticker,
                "com.instagram.sharedSticker.backgroundTopColor": hex(top),
                "com.instagram.sharedSticker.backgroundBottomColor": hex(bottom),
            ]],
            // Instagram reads it straight away; it shouldn't linger on the pasteboard after.
            options: [.expirationDate: Date.now.addingTimeInterval(5 * 60)])
        return await UIApplication.shared.open(url)
    }

    /// A colour as Instagram reads one, such as #172F6B.
    private static func hex(_ color: Color) -> String {
        let resolved = color.resolve(in: EnvironmentValues())
        func byte(_ component: Float) -> Int { Int((max(0, min(1, component)) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(resolved.red), byte(resolved.green), byte(resolved.blue))
    }
}
