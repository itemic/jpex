import SwiftUI
import UIKit

/// The share sheet for a picture of the map, shown while `picture` is set, from where this view
/// stands: on iPhone it rises from the foot of the screen, and on iPad it points to the view. The
/// picture goes back to nil once the sheet has closed.
///
/// It's UIKit's share sheet, given the picture as an image. A ShareLink hands over a file of it
/// instead, and apps that post photos, such as Instagram and WhatsApp, don't offer to take one.
struct ShareSheetPresenter: UIViewRepresentable {
    @Binding var picture: MapSharePicture?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onClose = { picture = nil }
        guard let picture else { return }
        // Shown once SwiftUI has finished this update, as UIKit shouldn't present in the middle of one.
        DispatchQueue.main.async { coordinator.show(picture, from: view) }
    }

    @MainActor
    final class Coordinator {
        /// Lets the picture go, once its sheet has closed or couldn't be shown.
        var onClose: () -> Void = {}
        /// The picture last shown, so that it's never shown twice.
        private weak var shown: MapSharePicture?
        private weak var sheet: UIActivityViewController?

        func show(_ picture: MapSharePicture, from view: UIView) {
            guard picture !== shown, sheet == nil else { return }
            // Over whatever's in front, as the share screen is itself presented over the list.
            guard var front = view.window?.rootViewController else {
                onClose()
                return
            }
            while let presented = front.presentedViewController {
                front = presented
            }
            let sheet = UIActivityViewController(activityItems: [picture], applicationActivities: nil)
            sheet.popoverPresentationController?.sourceView = view
            sheet.popoverPresentationController?.sourceRect = view.bounds
            sheet.completionWithItemsHandler = { [weak self] _, _, _, _ in
                self?.onClose()
            }
            shown = picture
            self.sheet = sheet
            front.present(sheet, animated: true)
        }
    }
}
