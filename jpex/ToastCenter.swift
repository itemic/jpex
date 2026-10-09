import SwiftUI
import UIKit

/// A short note about a level: a country rising along with one of its places, a whole list
/// reaching a level, or a change just undone.
struct LevelToast: Identifiable, Equatable {
    let id = UUID()
    var placeName: String
    var flagAssetName: String?
    /// The level the place, or every place in the list, has now.
    var level: VisitLevel
    var kind = Kind.raised
    /// The person's levels, for showing the pills as their places do.
    var ladder = VisitLadder.standard
    /// Puts the change back, when it can be undone.
    var onUndo: (() -> Void)?

    enum Kind: Equatable {
        /// A country rose along with one of its places: "Canada set to STAYED".
        case raised
        /// Every place in a list has reached the level: "Japan VISITED", with confetti.
        case completed
        /// An undo or redo moved a place from one level to another.
        case changed(from: VisitLevel)
    }

    /// How long it stays: long enough to reach Undo when there is one, and to enjoy a finished list.
    var duration: Duration {
        switch kind {
        case .completed: .seconds(3.2)
        case .changed: .seconds(2.2)
        case .raised: .seconds(onUndo == nil ? 2.6 : 4)
        }
    }

    static func == (lhs: LevelToast, rhs: LevelToast) -> Bool {
        lhs.id == rhs.id
    }
}

/// A ring of light in a level's colour spreading across the whole screen from a place that has
/// just risen a level, carrying the map's ripple out over everything around the map.
struct ScreenRipple: Equatable {
    static let duration = 1.6

    var id = UUID()
    /// Where the place is, in the screen's coordinates.
    var origin: CGPoint
    var color: Color
    var start: Date
}

extension EnvironmentValues {
    /// Whether a map's level-up ripples carry on across the whole screen, as on the full map.
    @Entry var spreadsRipplesAcrossScreen = false
}

/// Shows toasts, and ripples of light, above everything, including sheets and full-screen maps,
/// from a window of its own. Touches outside the toast pass straight through to the app.
@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    private(set) var current: LevelToast?
    private(set) var ripple: ScreenRipple?
    /// Where the toast sits in its window, so only it takes touches.
    var toastFrame: CGRect = .zero

    @ObservationIgnored private var window: PassthroughWindow?
    @ObservationIgnored private var dismissal: Task<Void, Never>?

    func show(_ toast: LevelToast) {
        installWindowIfNeeded()
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.1)) { current = toast }
        dismissal?.cancel()
        dismissal = Task {
            try? await Task.sleep(for: toast.duration)
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    func dismiss() {
        withAnimation(.smooth(duration: 0.4)) { current = nil }
    }

    /// Sends a ring of light across the screen from a point in the screen's coordinates.
    func ripple(from origin: CGPoint, color: Color) {
        installWindowIfNeeded()
        let next = ScreenRipple(origin: origin, color: color, start: .now)
        ripple = next
        Task {
            try? await Task.sleep(for: .seconds(ScreenRipple.duration))
            if ripple == next { ripple = nil }
        }
    }

    /// Puts the overlay in the window being used: with several of the app's windows side by side,
    /// as on iPhone Duo's inner display, the one with the key window, and it follows the person
    /// from one window to another.
    private func installWindowIfNeeded() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.filter { $0.activationState == .foregroundActive }
        guard let scene = active.first(where: { $0.windows.contains(where: \.isKeyWindow) }) ?? active.first ?? scenes.first
        else { return }
        if let window {
            if window.windowScene !== scene { window.windowScene = scene }
            return
        }
        let window = PassthroughWindow(windowScene: scene)
        window.toasts = self
        window.windowLevel = .alert + 1
        let host = UIHostingController(rootView: ToastOverlay(center: self))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }
}

/// A window that only answers touches on the toast.
final class PassthroughWindow: UIWindow {
    weak var toasts: ToastCenter?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let toasts, toasts.current != nil, toasts.toastFrame.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}

private struct ToastOverlay: View {
    var center: ToastCenter

    var body: some View {
        ZStack {
            if let ripple = center.ripple {
                RippleLight(ripple: ripple)
            }
            toasts
        }
        // A window of its own, so it takes the app's Reduce Motion setting itself.
        .appliesMotionPreference()
    }

    private var toasts: some View {
        GeometryReader { proxy in
            VStack {
                if let toast = center.current {
                    LevelToastView(toast: toast)
                        .onTapGesture { center.dismiss() }
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { center.toastFrame = $0 }
                        .transition(.toast)
                        .id(toast.id)
                }
                Spacer()
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity)
            .padding(Self.roomForFold(in: proxy))
        }
    }

    /// Keeps the toast clear of a fold and its margins. Held like a book, it moves to the trailing
    /// page, where alerts appear in that pose. Set down like a laptop, it moves to the lower half,
    /// within reach, since its Undo is something to tap rather than read from a distance.
    private static func roomForFold(in proxy: GeometryProxy) -> EdgeInsets {
        guard #available(iOS 27.1, *), let fold = proxy.reservedRegions(kind: .division).first else {
            return EdgeInsets()
        }
        if fold.frame.height > fold.frame.width {
            return EdgeInsets(top: 0, leading: max(fold.frame.maxX + fold.margins.trailing, 0), bottom: 0, trailing: 0)
        }
        return EdgeInsets(top: max(fold.frame.maxY + fold.margins.bottom, 0), leading: 0, bottom: 0, trailing: 0)
    }
}

/// The ripple's light, filling the screen edge to edge, under the toast.
private struct RippleLight: View {
    var ripple: ScreenRipple

    var body: some View {
        TimelineView(.animation) { timeline in
            Rectangle()
                .colorEffect(ShaderLibrary.screenRipple(
                    .float2(ripple.origin), .float(timeline.date.timeIntervalSince(ripple.start)),
                    .float(14), .float(3.2), .float(700), .float(ScreenRipple.duration), .color(ripple.color)))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
