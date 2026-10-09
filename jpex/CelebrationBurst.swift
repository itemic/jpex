import SwiftUI

/// A burst of confetti in the levels' colours, for finishing a region or a whole list.
/// It leaps up from its centre, tumbles and falls away; Reduce Motion leaves it out.
struct CelebrationBurst: View {
    /// Bursts each time this changes.
    var trigger: Int
    var colors: [Color]
    var pieceCount = 34
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burst: Burst?

    var body: some View {
        TimelineView(.animation(paused: burst == nil)) { timeline in
            Canvas { context, size in
                guard let burst else { return }
                let elapsed = timeline.date.timeIntervalSince(burst.start)
                let origin = CGPoint(x: size.width / 2, y: size.height / 2)
                for piece in burst.pieces {
                    let time = elapsed - piece.delay
                    guard time > 0, time < piece.life else { continue }
                    var piecesContext = context
                    piecesContext.opacity = 1 - pow(time / piece.life, 2)
                    piecesContext.translateBy(
                        x: origin.x + piece.velocity.dx * time,
                        y: origin.y + piece.velocity.dy * time + 0.5 * Burst.gravity * time * time)
                    piecesContext.rotate(by: .radians(piece.spin * time))
                    // Confetti flutters by turning edge-on and back.
                    piecesContext.scaleBy(x: cos(piece.flutter * time), y: 1)
                    let rect = CGRect(x: -piece.size.width / 2, y: -piece.size.height / 2, width: piece.size.width, height: piece.size.height)
                    piecesContext.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { fire() }
    }

    private func fire() {
        guard !reduceMotion, !colors.isEmpty else { return }
        let next = Burst(start: .now, pieces: (0..<pieceCount).map { _ in Piece(colors: colors) })
        burst = next
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            if burst?.start == next.start { burst = nil }
        }
    }

    private struct Burst {
        static let gravity = 900.0
        var start: Date
        var pieces: [Piece]
    }

    private struct Piece {
        var velocity: CGVector
        var size: CGSize
        var color: Color
        var spin: Double
        var flutter: Double
        var delay: Double
        var life: Double

        init(colors: [Color]) {
            // Mostly upwards, fanning out to either side.
            let angle = Double.random(in: -.pi * 0.92 ... -.pi * 0.08)
            let speed = Double.random(in: 240...520)
            velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            size = CGSize(width: .random(in: 4...7), height: .random(in: 7...12))
            color = colors.randomElement() ?? .accentColor
            spin = .random(in: -9...9)
            flutter = .random(in: 6...14)
            delay = .random(in: 0...0.08)
            life = .random(in: 0.9...1.5)
        }
    }
}
