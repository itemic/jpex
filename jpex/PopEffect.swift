import SwiftUI

extension View {
    /// A quick, springy pop whenever `trigger` changes.
    func pop<Trigger: Equatable>(on trigger: Trigger) -> some View {
        modifier(PopEffect(trigger: trigger))
    }

    /// A quick side-to-side shake whenever `trigger` changes, for "no further" or "not that one":
    /// out to `amplitude` points one way, nearly as far back the other, and settling in two smaller
    /// swings, or with Reduce Motion, a short nod of the opacity in place of the shake. Fields and
    /// the cards in a list shake at 8 points; the quiz's four big choices, and In and Out, at 10.
    func shake<Trigger: Equatable>(on trigger: Trigger, amplitude: CGFloat = 5) -> some View {
        modifier(ShakeEffect(trigger: trigger, amplitude: amplitude))
    }

    /// The same shake, only each time `count` goes up, never as it goes back down: so a card that
    /// was wrong for the last question, set right again for the next, stays still rather than
    /// shaking a second time. A wrong pick counts as `isWrong ? 1 : 0`.
    func shake(onRiseOf count: Int, amplitude: CGFloat) -> some View {
        modifier(RisingShake(count: count, amplitude: amplitude))
    }
}

extension AnyTransition {
    /// How one thing gives way to the next in the same slot, as a question's prompt does: softening
    /// out of focus as the next comes into it, or with Reduce Motion, a plain cross-fade. Kept to a
    /// ZStack slot, so the two never stand one above the other while they trade places.
    static func slotSwap(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : AnyTransition(.blurReplace)
    }

    /// How a small control or tag arrives and leaves, such as Skip, Now or a name just given: in
    /// from 0.6 of its size on a lively spring, out in a quick, smooth fade; with Reduce Motion, a
    /// fade alone. It carries its own timing, so it moves the same however it's shown or hidden.
    static func arrive(reduceMotion: Bool, anchor: UnitPoint = .center) -> AnyTransition {
        guard !reduceMotion else { return AnyTransition.opacity.animation(.easeInOut(duration: 0.2)) }
        return .asymmetric(
            insertion: AnyTransition.scale(scale: 0.6, anchor: anchor).combined(with: .opacity)
                .animation(.bouncy(duration: 0.4, extraBounce: 0.2)),
            removal: AnyTransition.opacity.animation(.smooth(duration: 0.25)))
    }
}

extension Animation {
    /// One thing trading places with the next in its slot: a snappy spring, or with Reduce Motion,
    /// a short fade.
    static func swap(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .snappy(duration: 0.35)
    }
}

private struct ShakeEffect<Trigger: Equatable>: ViewModifier {
    var trigger: Trigger
    var amplitude: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isStill = reduceMotion
        // The nod dips as deep for any amplitude: about 40% at the first swing.
        let depth = max(amplitude, 1) * 2.4
        content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, offset in
            view
                .offset(x: isStill ? 0 : offset)
                .opacity(isStill ? 1 - abs(offset) / depth : 1)
        } keyframes: { _ in
            CubicKeyframe(-amplitude, duration: 0.06)
            CubicKeyframe(amplitude * 0.9, duration: 0.09)
            CubicKeyframe(-amplitude * 0.6, duration: 0.08)
            CubicKeyframe(amplitude * 0.4, duration: 0.07)
            SpringKeyframe(0, duration: 0.25, spring: .snappy)
        }
    }
}

/// Counts each rise of a count, to shake on, so it never shakes as the count falls back.
private struct RisingShake: ViewModifier {
    var count: Int
    var amplitude: CGFloat
    @State private var rises = 0

    func body(content: Content) -> some View {
        content
            .shake(on: rises, amplitude: amplitude)
            .onChange(of: count) { old, new in
                if new > old { rises += 1 }
            }
    }
}

private struct PopEffect<Trigger: Equatable>: ViewModifier {
    var trigger: Trigger
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isStill = reduceMotion
        content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(isStill ? 1 : scale)
        } keyframes: { _ in
            SpringKeyframe(1.14, duration: 0.12, spring: .snappy)
            SpringKeyframe(1, duration: 0.4, spring: .bouncy)
        }
    }
}
