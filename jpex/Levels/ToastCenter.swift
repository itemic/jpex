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
    /// With VoiceOver, long enough to hear it and move to Undo.
    var duration: Duration {
        if UIAccessibility.isVoiceOverRunning { return .seconds(onUndo == nil ? 5 : 10) }
        return switch kind {
        case .completed: .seconds(3.2)
        case .changed: .seconds(2.2)
        case .raised: .seconds(onUndo == nil ? 2.6 : 4)
        }
    }

    /// What it says, for VoiceOver.
    var spokenDescription: String {
        switch kind {
        case .raised: "\(placeName) set to \(level.name)"
        case .completed: "All of \(placeName) at \(level.name)"
        case .changed(let from): "\(placeName), \(from.name) to \(level.name)"
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
    /// Whether a place rising a level here breaks out over the whole screen: lifting off its map,
    /// throwing sparks and sending its ripple of light across everything around it. On only where
    /// these views are the ones in front, so nothing bursts out from beneath a sheet or the full map.
    @Entry var breaksOutOntoScreen = false
    /// Whether a place rising here also sends its ripple of light across the whole screen as it
    /// lands, as on the full map and on a list's map, whose ripple runs on down the list.
    @Entry var spreadsRipplesAcrossScreen = false
}

/// A place landing back on its map after its lift, felt as a tap.
struct LiftLanding: Equatable {
    var id = UUID()
    /// How high the place's new level is, from just above 0 to 1 for the top, which lands hardest.
    var height: Double
}

/// Shows toasts, ripples of light, and the effects that break out of the views they start in, above
/// everything, including sheets and full-screen maps, from a window of its own. Touches outside the
/// toast pass straight through to the app.
@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    private(set) var current: LevelToast?
    private(set) var ripple: ScreenRipple?
    private(set) var lifts: [PlaceLift] = []
    private(set) var floats: [LevelFloat] = []
    private(set) var bursts: [ScreenBurst] = []
    private(set) var landing: LiftLanding?
    /// When a place last lifted off its map, for telling whether one is on its way back down.
    @ObservationIgnored private(set) var lastLiftDate: Date?
    /// Where the toast sits in its window, so only it takes touches.
    var toastFrame: CGRect = .zero

    var hasEffects: Bool {
        !lifts.isEmpty || !floats.isEmpty || !bursts.isEmpty
    }

    @ObservationIgnored private var window: PassthroughWindow?
    @ObservationIgnored private var dismissal: Task<Void, Never>?
    /// A toast waiting for the one before to lift away, so the two never pass through each other.
    @ObservationIgnored private var arrival: Task<Void, Never>?

    /// How long a toast already showing has to start lifting away before the next drops in.
    private static let handover = 0.12

    /// Shows a toast. One already showing lifts away first, quickly, and the new one drops in just
    /// behind it, as Undo following a change does, rather than the two crossing on the same spring.
    func show(_ toast: LevelToast) {
        installWindowIfNeeded()
        arrival?.cancel()
        guard current != nil else {
            present(toast)
            return
        }
        dismissal?.cancel()
        withAnimation(.smooth(duration: 0.2)) { current = nil }
        arrival = Task {
            try? await Task.sleep(for: .seconds(Self.handover))
            guard !Task.isCancelled else { return }
            present(toast)
        }
    }

    /// Drops a toast in, says it for VoiceOver, and lets it go after its time.
    private func present(_ toast: LevelToast) {
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.1)) { current = toast }
        // Its window is apart from the app's, so VoiceOver wouldn't otherwise hear it arrive.
        AccessibilityNotification.Announcement(toast.spokenDescription).post()
        dismissal?.cancel()
        dismissal = Task {
            try? await Task.sleep(for: toast.duration)
            guard !Task.isCancelled else { return }
            dismiss()
        }
        if toast.kind == .completed {
            // A finished list throws its confetti from the note once it has dropped in and landed,
            // out across the whole screen.
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                guard current?.id == toast.id, let window else { return }
                let origin = toastFrame.isEmpty
                    ? CGPoint(x: window.bounds.midX, y: window.safeAreaInsets.top + 28)
                    : CGPoint(x: toastFrame.midX, y: toastFrame.midY)
                burst(from: origin, colors: toast.ladder.levels.map(\.color), pieceCount: 90, power: 1.6)
            }
        }
    }

    func dismiss() {
        arrival?.cancel()
        withAnimation(.smooth(duration: 0.4)) { current = nil }
    }

    /// Sends a ring of light across the screen from a point in the screen's coordinates, starting
    /// now or a moment later, such as when a lifted place lands.
    func ripple(from origin: CGPoint, color: Color, start: Date = .now) {
        installWindowIfNeeded()
        let next = ScreenRipple(origin: origin, color: color, start: start)
        ripple = next
        Task {
            try? await Task.sleep(for: .seconds(max(start.timeIntervalSinceNow, 0) + ScreenRipple.duration))
            if ripple == next { ripple = nil }
        }
    }

    /// Lifts a place off its map and over everything, landing it back a moment later with a tap
    /// and a shower of sparks. Shows nothing, and says so, when the place isn't on screen.
    @discardableResult
    func lift(_ lift: PlaceLift) -> Bool {
        guard isOnScreen(lift.center) else { return false }
        lastLiftDate = .now
        lifts = Array((lifts + [lift]).suffix(4))
        Task {
            try? await Task.sleep(for: .seconds(max(lift.start.timeIntervalSinceNow, 0) + PlaceLift.landing))
            // Marking places quickly, only the latest to lift lands with a tap, so the taps never
            // fall out of step with what the eye sees land.
            if lifts.last?.id == lift.id {
                landing = LiftLanding(height: lift.height)
            }
            try? await Task.sleep(for: .seconds(lift.duration - PlaceLift.landing))
            lifts.removeAll { $0.id == lift.id }
        }
        return true
    }

    /// Floats a level's badge up out of a pill that has just risen to it.
    func float(_ float: LevelFloat) {
        guard isOnScreen(float.origin) else { return }
        floats = Array((floats + [float]).suffix(6))
        Task {
            try? await Task.sleep(for: .seconds(LevelFloat.duration))
            floats.removeAll { $0.id == float.id }
        }
    }

    /// Throws confetti from a point in the screen's coordinates out across the whole screen.
    /// `power` throws it harder and lets it fall for longer.
    func burst(from origin: CGPoint, colors: [Color], pieceCount: Int = 56, power: Double = 1.25) {
        guard !colors.isEmpty, isOnScreen(origin) else { return }
        let burst = ScreenBurst(
            origin: origin, start: .now, pieces: (0..<pieceCount).map { _ in ConfettiPiece(colors: colors, power: power) },
            duration: ConfettiPiece.lifetime(power: power))
        bursts = Array((bursts + [burst]).suffix(3))
        Task {
            try? await Task.sleep(for: .seconds(burst.duration))
            bursts.removeAll { $0.id == burst.id }
        }
    }

    /// Whether a point in the screen's coordinates is on screen. An effect starting anywhere else
    /// would only spill in from past an edge, as if from nowhere.
    func isOnScreen(_ point: CGPoint) -> Bool {
        installWindowIfNeeded()
        return window?.bounds.contains(point) == true
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
            if center.hasEffects {
                ScreenEffectsLayer(lifts: center.lifts, floats: center.floats, bursts: center.bursts)
            }
            toasts
        }
        // A window of its own, so it takes the app's Reduce Motion setting itself.
        .appliesMotionPreference()
        // A lifted place lands with a tap, harder the higher its level.
        .sensoryFeedback(trigger: center.landing) { _, landing in
            landing.map { .impact(weight: .light, intensity: 0.45 + 0.45 * $0.height) }
        }
    }

    private var toasts: some View {
        GeometryReader { proxy in
            // One slot at the top, so a toast lifting away and the next dropping in share the same
            // place rather than standing one above the other while they trade.
            ZStack(alignment: .top) {
                if let toast = center.current {
                    LevelToastView(toast: toast)
                        .onTapGesture { center.dismiss() }
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { center.toastFrame = $0 }
                        .transition(.toast)
                        .id(toast.id)
                }
            }
            .padding(.top, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(Self.roomForFold(in: proxy))
        }
    }

    /// Keeps the toast clear of a fold and its margins, on its near side. Held like a book, it moves
    /// to the trailing page, where alerts appear in that pose. Set down like a laptop, it moves to
    /// the lower half, within reach, since its Undo is something to tap rather than read from a
    /// distance. A fold at the window's edge, as beside another app, leaves it where it is.
    private static func roomForFold(in proxy: GeometryProxy) -> EdgeInsets {
        guard let fold = FoldRegions(in: proxy) else { return EdgeInsets() }
        return EdgeInsets(top: fold.near.minY, leading: fold.near.minX, bottom: 0, trailing: 0)
    }
}

/// The ripple's light, filling the screen edge to edge, under the toast.
private struct RippleLight: View {
    var ripple: ScreenRipple

    var body: some View {
        // A soft ring of light needs no more than 60 frames a second, even on a 120 Hz display.
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
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
