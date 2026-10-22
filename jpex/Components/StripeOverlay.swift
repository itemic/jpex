import SwiftUI

/// Diagonal stripes on a progress bar while there is more to discover. They drift for a moment
/// when the bar appears or changes, then slow to a stop, rather than moving all the time.
struct StripeOverlay: View {
    /// Whether there's more to discover, so the stripes have somewhere to go.
    var isMoving: Bool
    /// Changes whenever the bar does, setting the stripes drifting again for a while.
    var trigger: Int = 0
    /// Where the stripes rest, along their repeat.
    @State private var restingPhase = 0.0
    /// When the current drift began, while there is one.
    @State private var driftStart: Date?

    private static let period = 10.0
    private static let speed = 7.0
    /// How long the stripes drift at full speed before they start to slow.
    private static let cruise = 1.6
    /// How quickly they then slow: they've all but stopped after a few of these.
    private static let settle = 0.9
    private static var duration: Double { cruise + 5 * settle }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: driftStart == nil)) { context in
            let drift = phase(at: context.date)
            Canvas { graphics, size in
                let stripeWidth = 5.0
                var stripes = Path()
                var x = -size.height - Self.period + drift
                while x < size.width {
                    stripes.move(to: CGPoint(x: x, y: size.height))
                    stripes.addLine(to: CGPoint(x: x + size.height, y: 0))
                    stripes.addLine(to: CGPoint(x: x + size.height + stripeWidth, y: 0))
                    stripes.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                    stripes.closeSubpath()
                    x += Self.period
                }
                graphics.fill(stripes, with: .color(.white.opacity(0.28)))
            }
        }
        .task(id: Kick(trigger: trigger, isMoving: isMoving)) {
            // Carries on from wherever the stripes are, so a new drift never jumps.
            let now = Date.now
            restingPhase = phase(at: now)
            guard isMoving else {
                driftStart = nil
                return
            }
            driftStart = now
            try? await Task.sleep(for: .seconds(Self.duration))
            guard !Task.isCancelled else { return }
            restingPhase = phase(at: .now)
            driftStart = nil
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Where the stripes are at a moment, along their repeat.
    private func phase(at date: Date) -> Double {
        guard let driftStart else { return restingPhase }
        let travelled = Self.distance(after: date.timeIntervalSince(driftStart))
        return (restingPhase + travelled).truncatingRemainder(dividingBy: Self.period)
    }

    /// How far the stripes have drifted: steadily at first, then easing to a stop.
    private static func distance(after time: Double) -> Double {
        let time = max(time, 0)
        guard time > cruise else { return speed * time }
        let slowing = min(time - cruise, 5 * settle)
        return speed * cruise + speed * settle * (1 - exp(-slowing / settle))
    }

    private struct Kick: Equatable {
        var trigger: Int
        var isMoving: Bool
    }
}
