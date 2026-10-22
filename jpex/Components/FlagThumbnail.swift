import SwiftUI
import UIKit

/// A flag drawn small, such as a sidebar badge, from a copy scaled down once to the size it's shown
/// at rather than the full artwork, which is 768 pixels wide, decoded for every badge on screen. It
/// fills its frame as `.aspectRatio(contentMode: .fill)` would, so wider flags crop at the sides.
struct FlagThumbnail: View {
    var name: String
    /// The size it's shown at, in points.
    var size: CGSize
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        if let image = FlagThumbnails.image(named: name, filling: size, scale: displayScale) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

/// Flags scaled down for small badges, kept until memory runs short.
enum FlagThumbnails {
    private static let cache = NSCache<NSString, UIImage>()

    /// The flag scaled to just cover `size` at this screen scale, keeping its shape.
    static func image(named name: String, filling size: CGSize, scale: CGFloat) -> UIImage? {
        let target = CGSize(width: max(size.width * scale, 1), height: max(size.height * scale, 1))
        let key = "\(name)@\(Int(target.width.rounded(.up)))x\(Int(target.height.rounded(.up)))" as NSString
        if let image = cache.object(forKey: key) { return image }
        guard let full = UIImage(named: name), full.size.width > 0, full.size.height > 0 else { return nil }
        let pixels = CGSize(width: full.size.width * full.scale, height: full.size.height * full.scale)
        let cover = max(target.width / pixels.width, target.height / pixels.height)
        // Never larger than the artwork itself.
        guard cover < 1 else { return full }
        let fitted = CGSize(width: (pixels.width * cover).rounded(.up), height: (pixels.height * cover).rounded(.up))
        guard let thumbnail = full.preparingThumbnail(of: fitted) else { return full }
        cache.setObject(thumbnail, forKey: key)
        return thumbnail
    }
}
