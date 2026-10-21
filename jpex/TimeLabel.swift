import SwiftUI

/// A time set large and light, the part of the day beside it smaller, as on a watch. Where it
/// `rolls`, a change made with an animation, such as another place picked, rolls the digits over
/// to the new time; with Reduce Motion, they fade across instead.
struct TimeLabel: View {
    var time: ClockWords.Time
    var digits: TypeStyle
    var period: TypeStyle
    var rolls = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.contentTransition) private var inherited

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if time.periodFirst, let text = time.period {
                Text(text).typeStyle(period)
            }
            Text(time.digits)
                .typeStyle(digits)
                .monospacedDigit()
                .contentTransition(rolls ? (reduceMotion ? .opacity : .numericText()) : inherited)
            if !time.periodFirst, let text = time.period {
                Text(text).typeStyle(period)
            }
        }
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(time.spoken)
    }
}
