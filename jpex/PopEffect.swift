import SwiftUI

extension View {
    /// A quick, springy pop whenever `trigger` changes.
    func pop<Trigger: Equatable>(on trigger: Trigger) -> some View {
        modifier(PopEffect(trigger: trigger))
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
