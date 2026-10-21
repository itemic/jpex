import SwiftUI

/// Tap to climb to the next level. At the highest level a tap goes no further, so one stray tap
/// can never undo a place; it gives a little shake instead. Touch and hold the row for every level.
/// Rising, however it was set, the pill pops and the new level's badge floats up out of it, over
/// the rows around; falling, as after an undo, it only dips a little and settles.
struct VisitPillView: View {
    @Binding var status: VisitLevel
    var placeName: String
    /// Smaller, for extra compact rows, though still comfortably big enough to tap.
    var isSmall = false
    /// What a tap does at the highest level, such as showing every level to choose from. Without
    /// it, the pill gives a little shake.
    var onTopTap: (() -> Void)? = nil
    /// What touching and holding the pill does, such as showing every level, as holding the row does.
    var onHold: (() -> Void)? = nil
    /// Whether every level is showing, as after a hold: lifting the finger then climbs nothing.
    var isShowingLevels = false
    @Environment(\.visitLadder) private var ladder
    @Environment(\.breaksOutOntoScreen) private var breaksOutOntoScreen
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts taps at the highest level, each answered with a shake.
    @State private var topTaps = 0
    /// Counts the times the place has risen a level, each popping the pill.
    @State private var rises = 0
    /// Counts the times the place has fallen a level, each dipping the pill.
    @State private var falls = 0
    /// Where the pill is on screen, for a new level's badge to float up from.
    @State private var frame = ScreenFrame()

    var body: some View {
        let next = ladder.higher(than: status)
        Button {
            if isShowingLevels {
                return
            } else if let next {
                status = next
            } else if let onTopTap {
                onTopTap()
            } else {
                topTaps += 1
            }
        } label: {
            VisitPillLabel(status: status, isSmall: isSmall)
                .trackingScreenFrame(frame)
                .pop(on: rises)
                .modifier(Dip(trigger: falls))
                .shake(on: topTaps)
                .frame(minHeight: isSmall ? 34 : 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PillButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: DivisionListRow.holdDuration).onEnded { _ in onHold?() },
            isEnabled: onHold != nil)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.45), trigger: topTaps)
        .onChange(of: status) { old, new in
            guard old.id != new.id else { return }
            if ladder.rank(of: new) > ladder.rank(of: old) {
                rises += 1
            } else if ladder.rank(of: new) < ladder.rank(of: old) {
                falls += 1
            }
            floatBadge(from: old, to: new)
        }
        .accessibilityLabel("Visit status for \(placeName)")
        .accessibilityValue(status.name)
        .accessibilityHint(
            next.map { "Changes to \($0.name)." } ?? (onTopTap == nil ? "Already at the highest level." : "Shows every level."))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if let higher = ladder.higher(than: status) { status = higher }
            case .decrement: if let lower = ladder.lower(than: status) { status = lower }
            @unknown default: break
            }
        }
    }

    /// Rising to another level, from a tap here or anywhere else, its badge floats up out of the
    /// pill. Renaming or reordering levels moves no place, so floats nothing. While every level is
    /// showing, the badge chosen there floats up out of the picker itself instead, so nothing
    /// rises from under it, through it.
    private func floatBadge(from old: VisitLevel, to new: VisitLevel) {
        guard breaksOutOntoScreen, !reduceMotion, !isShowingLevels, old.id != new.id,
              ladder.rank(of: new) > ladder.rank(of: old), !frame.rect.isNull
        else { return }
        ToastCenter.shared.float(LevelFloat(
            origin: CGPoint(x: frame.rect.midX, y: frame.rect.minY), color: new.color, symbolName: new.symbolName,
            isTop: ladder.higher(than: new) == nil))
    }
}

extension View {
    /// The pop, only each time `count` goes up, never as it goes back down: so a count beside a
    /// list or a region pops as a place comes to count, as the pill does, and holds still for an undo.
    func pop(onRiseOf count: Int) -> some View {
        modifier(RisingPop(count: count))
    }
}

/// Counts each rise of a count, to pop on, so it never pops as the count falls back.
private struct RisingPop: ViewModifier {
    var count: Int
    @State private var rises = 0

    func body(content: Content) -> some View {
        content
            .pop(on: rises)
            .onChange(of: count) { old, new in
                if new > old { rises += 1 }
            }
    }
}

/// A small dip whenever `trigger` changes, for a level going down: the pill gives a little, quickly,
/// and settles back gently, rather than popping as it does for a rise. Still with Reduce Motion,
/// where the name rolling down to the lower level says it alone.
private struct Dip<Trigger: Equatable>: ViewModifier {
    var trigger: Trigger
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isStill = reduceMotion
        content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(isStill ? 1 : scale)
        } keyframes: { _ in
            SpringKeyframe(0.92, duration: 0.1, spring: .snappy)
            SpringKeyframe(1, duration: 0.3, spring: .smooth)
        }
    }
}
