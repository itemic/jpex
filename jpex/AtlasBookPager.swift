import SwiftUI
import UIKit

/// The Atlas book's pages, one sheet sliding over to the next as a swipe carries it. A place chosen
/// any other way, tapped on the map, picked from the list or stepped to with the keys, doesn't
/// slide through the pages between: the page simply gives way to it in a short fade, the map's
/// glide being the motion.
struct AtlasBookPager<Page: View>: UIViewControllerRepresentable {
    var count: Int
    /// The page on show.
    var index: Int
    var reduceMotion: Bool
    var page: (Int) -> Page
    /// Turned to another page by hand.
    var onTurn: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pages = UIPageViewController(
            transitionStyle: .scroll, navigationOrientation: .horizontal,
            options: [.interPageSpacing: NSNumber(value: 0)])
        pages.dataSource = context.coordinator
        pages.delegate = context.coordinator
        pages.view.backgroundColor = .clear
        context.coordinator.shown = index
        pages.setViewControllers([context.coordinator.page(at: index)], direction: .forward, animated: false)
        return pages
    }

    func updateUIViewController(_ pages: UIPageViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        // The page on show drawn afresh, as when the names switch language.
        if let shown = pages.viewControllers?.first as? AtlasBookPageController, shown.index == index {
            shown.rootView = coordinator.content(at: index)
            return
        }
        coordinator.turn(pages, to: index)
    }

    @MainActor
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: AtlasBookPager
        /// The page on show, or being turned to by hand.
        var shown = 0
        /// Whether a page is turning, by hand or by itself; a place chosen meanwhile waits for it.
        private var isTurning = false
        /// A place chosen while a page was turning, turned to once it has.
        private var waiting: Int?

        init(_ parent: AtlasBookPager) {
            self.parent = parent
        }

        func content(at index: Int) -> AnyView {
            // Hosted apart from the rest of the screen, the page takes the app's own motion setting.
            AnyView(parent.page(index).appliesMotionPreference())
        }

        func page(at index: Int) -> AtlasBookPageController {
            let controller = AtlasBookPageController(rootView: content(at: index))
            controller.index = index
            // Paper all the way to the page's edges, so the curl lifts a whole page.
            controller.view.backgroundColor = UIColor(AtlasBook.paper)
            return controller
        }

        /// Shows a place chosen other than by swiping: the page gives way to it in a short fade,
        /// however far through the book it is.
        func turn(_ pages: UIPageViewController, to index: Int) {
            guard index != shown, (0..<parent.count).contains(index) else { return }
            guard !isTurning else {
                waiting = index
                return
            }
            let direction: UIPageViewController.NavigationDirection = index > shown ? .forward : .reverse
            shown = index
            UIView.transition(with: pages.view, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                pages.setViewControllers([self.page(at: index)], direction: direction, animated: false)
            }
        }

        /// Turns to a place chosen while a page was turning.
        private func catchUp(_ pages: UIPageViewController) {
            guard let waiting else { return }
            self.waiting = nil
            turn(pages, to: waiting)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = (viewController as? AtlasBookPageController)?.index, index > 0 else { return nil }
            return page(at: index - 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = (viewController as? AtlasBookPageController)?.index, index + 1 < parent.count else {
                return nil
            }
            return page(at: index + 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            isTurning = true
        }

        func pageViewController(
            _ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController], transitionCompleted completed: Bool
        ) {
            isTurning = false
            if completed, let index = (pageViewController.viewControllers?.first as? AtlasBookPageController)?.index {
                shown = index
                parent.onTurn(index)
            }
            catchUp(pageViewController)
        }
    }
}

/// One page of the Atlas book, knowing which place it shows.
final class AtlasBookPageController: UIHostingController<AnyView> {
    var index = 0
}
