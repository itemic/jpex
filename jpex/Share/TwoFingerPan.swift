import SwiftUI
import UIKit

/// Two fingers moving together across a view, alongside SwiftUI's own pinch and drag, which can't
/// tell one finger from two. Tells how far they've moved since it last told, in the view's own
/// points, and nil as they lift.
struct TwoFingerPan: UIGestureRecognizerRepresentable {
    var isEnabled = true
    var onMove: (CGSize?) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = context.coordinator
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed:
            let moved = context.converter.localTranslation ?? recognizer.translation(in: recognizer.view)
            recognizer.setTranslation(.zero, in: recognizer.view)
            // As one finger lifts, the middle of the touches leaps to the other, which isn't a move.
            guard recognizer.numberOfTouches == 2 else { return }
            onMove(CGSize(width: moved.x, height: moved.y))
        case .ended, .cancelled, .failed:
            onMove(nil)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Fingers pinching can turn as they pinch.
        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
