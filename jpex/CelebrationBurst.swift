import SwiftUI

/// A burst of confetti in the levels' colours, for finishing a region or a whole list.
/// It leaps up from its centre, tumbles and falls away; Reduce Motion leaves it out.
struct CelebrationBurst: View {
    /// Bursts each time this changes.
    var trigger: Int
    var colors: [Color]
    var pieceCount = 34
    /// Whether it bursts as it first appears where `trigger` is already set, for something that
    /// arrives already worth celebrating, such as the line saying a quiz's answer was right first
    /// time, which only comes in once the answer's given.
    var burstsOnAppear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burst: Burst?

    var body: some View {
        TimelineView(.animation(paused: burst == nil)) { timeline in
            Canvas { context, size in
                guard let burst else { return }
                ConfettiPiece.draw(
                    burst.pieces, elapsed: timeline.date.timeIntervalSince(burst.start),
                    from: CGPoint(x: size.width / 2, y: size.height / 2), in: context)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { fire() }
        .onAppear {
            if burstsOnAppear, trigger != 0 { fire() }
        }
    }

    private func fire() {
        guard !reduceMotion, !colors.isEmpty else { return }
        let next = Burst(start: .now, pieces: (0..<pieceCount).map { _ in ConfettiPiece(colors: colors) })
        burst = next
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            if burst?.start == next.start { burst = nil }
        }
    }

    private struct Burst {
        var start: Date
        var pieces: [ConfettiPiece]
    }
}

/// One piece of confetti: thrown mostly upwards, fanning out to either side, it tumbles, flutters
/// and falls away.
struct ConfettiPiece {
    static let gravity = 900.0

    var velocity: CGVector
    var size: CGSize
    var color: Color
    var spin: Double
    var flutter: Double
    var delay: Double
    var life: Double

    /// `power` throws it harder and lets it fall for longer, for a burst with the whole screen to fill.
    init(colors: [Color], power: Double = 1) {
        // Mostly upwards, fanning out to either side.
        let angle = Double.random(in: -.pi * 0.92 ... -.pi * 0.08)
        let speed = Double.random(in: 240...520) * power
        velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
        size = CGSize(width: .random(in: 4...7), height: .random(in: 7...12))
        color = colors.randomElement() ?? .accentColor
        spin = .random(in: -9...9)
        flutter = .random(in: 6...14)
        delay = .random(in: 0...0.08)
        life = .random(in: 0.9...1.5) * max(power, 1)
    }

    /// The longest any piece of a burst thrown with this power lasts, in seconds.
    static func lifetime(power: Double) -> Double {
        0.08 + 1.5 * max(power, 1)
    }

    /// Draws a burst's pieces as they are `elapsed` seconds after leaving `origin`.
    static func draw(_ pieces: [ConfettiPiece], elapsed: Double, from origin: CGPoint, in context: GraphicsContext) {
        for piece in pieces {
            let time = elapsed - piece.delay
            guard time > 0, time < piece.life else { continue }
            var pieceContext = context
            pieceContext.opacity = 1 - pow(time / piece.life, 2)
            pieceContext.translateBy(
                x: origin.x + piece.velocity.dx * time,
                y: origin.y + piece.velocity.dy * time + 0.5 * gravity * time * time)
            pieceContext.rotate(by: .radians(piece.spin * time))
            // Confetti flutters by turning edge-on and back.
            pieceContext.scaleBy(x: cos(piece.flutter * time), y: 1)
            let rect = CGRect(x: -piece.size.width / 2, y: -piece.size.height / 2, width: piece.size.width, height: piece.size.height)
            pieceContext.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(piece.color))
        }
    }
}
