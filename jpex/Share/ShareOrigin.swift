import SwiftUI
import UIKit

/// Where the share screen's card comes from: the list's map, exactly as it looked on screen as Share
/// was tapped, and where it lay, so the card can peel off the page from there and stick back down
/// there as the screen closes.
struct ShareOrigin {
    var image: UIImage
    /// The map's frame in the window.
    var frame: CGRect

    /// The window's picture inside a frame, as it is on screen now; nil where there's no window to
    /// take it from.
    @MainActor static func capture(_ frame: CGRect) -> ShareOrigin? {
        // The window in front: the key window of a scene in use, or failing that, any window showing.
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .sorted { ($0.activationState == .foregroundActive ? 0 : 1) < ($1.activationState == .foregroundActive ? 0 : 1) }
        let windows = scenes.flatMap(\.windows)
        guard frame.width > 1, frame.height > 1,
              let window = windows.first(where: \.isKeyWindow) ?? windows.first(where: { !$0.isHidden })
        else { return nil }
        let format = UIGraphicsImageRendererFormat(for: window.traitCollection)
        let image = UIGraphicsImageRenderer(size: frame.size, format: format).image { _ in
            window.drawHierarchy(
                in: CGRect(origin: CGPoint(x: -frame.minX, y: -frame.minY), size: window.bounds.size),
                afterScreenUpdates: false)
        }
        return ShareOrigin(image: image, frame: frame)
    }
}
