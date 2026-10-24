import LinkPresentation
import SwiftUI
import UIKit

/// A list's map as a picture to share: the card drawn at three times its size in points, 1080 pixels
/// on its short side. It goes to the share sheet as a picture, as a photo from Photos does, so every
/// app that posts photos offers to take it, such as Instagram, WhatsApp or Threads. Mail and Files
/// take it as a PNG named for the place, such as Japan.png.
final class MapSharePicture: NSObject, UIActivityItemSource {
    let image: UIImage
    /// What the picture shows, such as "Japan, 32 prefectures", heading the share sheet and as an
    /// email's subject.
    let title: String
    /// The place's name, for the picture's file.
    private let name: String
    /// The picture's file once saved, kept for each later time it's asked for.
    private var file: URL?

    /// Where the picture goes as a file named for the place, rather than as a photo named by the app
    /// it goes to.
    private static let fileActivities: Set<UIActivity.ActivityType> = [
        .mail, UIActivity.ActivityType("com.apple.DocumentManagerUICore.SaveToFiles"),
    ]

    /// The card drawn to send, or nil where it couldn't be drawn.
    @MainActor init?(content: MapShareContent) {
        guard let image = Self.image(of: content, scale: 3) else { return nil }
        self.image = image
        title = content.summary
        name = content.country.name.replacingOccurrences(of: "/", with: "-")
    }

    /// The card drawn as an image, edge to edge, at `scale` pixels to the point.
    @MainActor static func image(of content: MapShareContent, scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: MapShareCard(content: content).environment(\.displayScale, scale))
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    /// The card as a sticker for an Instagram story: its corners rounded, as a card in the hand, with
    /// a soft shadow beneath it and nothing around it.
    @MainActor static func sticker(of content: MapShareContent) -> Data? {
        let card = MapShareCard(content: content)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(24)
            .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
            .environment(\.displayScale, 3)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = false
        return renderer.uiImage?.pngData()
    }

    // MARK: The share sheet

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        guard let activityType, Self.fileActivities.contains(activityType) else { return image }
        return (try? savedFile()) ?? image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        title
    }

    /// The share sheet's heading: the picture, beside what it shows.
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }

    /// Saves the picture as a PNG named for the place, into a folder of its own among the temporary
    /// files, so one share never writes over another's file while it's still being sent.
    private func savedFile() throws -> URL {
        if let file { return file }
        guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
        let folder = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "\(name).png")
        try data.write(to: file)
        self.file = file
        return file
    }
}
