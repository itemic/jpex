import SwiftUI

/// A striped progress bar. The stripes drift until every place is counted,
/// then the bar settles to solid colour with a single shine.
struct ProgressBarView: View {
    var percentage: Double
    var color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shineCount = 0

    private var progress: Double { min(max(percentage, 0), 1) }
    private var isComplete: Bool { progress >= 1 }

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(color.opacity(0.2))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(color)
                        .overlay {
                            StripeOverlay(isMoving: progress > 0 && !isComplete && !reduceMotion)
                                .opacity(isComplete ? 0 : 1)
                        }
                        .overlay(alignment: .leading) {
                            ShineSweep(width: geometry.size.width, trigger: shineCount)
                        }
                        .frame(width: geometry.size.width * progress)
                        .clipShape(Capsule())
                }
        }
        .animation(.smooth, value: progress)
        .onChange(of: isComplete) { _, complete in
            if complete && !reduceMotion { shineCount += 1 }
        }
        .accessibilityHidden(true)
    }
}

/// A band of light that crosses the bar once each time the trigger changes.
struct ShineSweep: View {
    var width: Double
    var trigger: Int

    var body: some View {
        LinearGradient(colors: [.clear, .white.opacity(0.75), .clear], startPoint: .leading, endPoint: .trailing)
            .frame(width: max(width * 0.45, 24))
            .keyframeAnimator(initialValue: -1.0, trigger: trigger) { content, position in
                content.offset(x: position * width)
            } keyframes: { _ in
                MoveKeyframe(-0.5)
                CubicKeyframe(1.1, duration: 0.9)
                MoveKeyframe(-1)
            }
            .allowsHitTesting(false)
    }
}
