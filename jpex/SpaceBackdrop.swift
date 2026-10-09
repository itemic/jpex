import SwiftUI

/// The deep space Time Machine floats in: a field of stars that twinkle and slowly wheel, washed
/// with nebulae. As `warp` rises the stars streak outward from the middle, as if flying through
/// them, for travelling far in time.
struct SpaceBackdrop: View, Animatable {
    /// From 0, still, to 1, streaking past.
    var warp: Double
    /// Tints the nebulae warmer, toward deep time.
    var deepTime: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(warp, deepTime) }
        set {
            warp = newValue.first
            deepTime = newValue.second
        }
    }

    private static let stars: [Star] = {
        var generator = SeededGenerator(seed: 1914)
        return (0..<320).map { _ in
            Star(
                angle: Double.random(in: 0..<(2 * .pi), using: &generator),
                distance: pow(Double.random(in: 0.02...1, using: &generator), 0.7) * 1.15,
                depth: Double.random(in: 0.15...1, using: &generator),
                size: Double.random(in: 0.4...1.6, using: &generator),
                twinkle: Double.random(in: 0.6...2.4, using: &generator),
                phase: Double.random(in: 0..<(2 * .pi), using: &generator),
                color: Color(red: 1, green: 0.92 + 0.08 * Double.random(in: 0...1, using: &generator), blue: 0.85))
        }
    }()

    var body: some View {
        ZStack {
            // The nebulae change only with the tint, so they're drawn once and kept.
            NebulaLayer(deepTime: deepTime)
                .equatable()
            // Stars twinkle at a gentle rate, and run at full speed only while streaking.
            TimelineView(.animation(minimumInterval: warp > 0.02 ? nil : 1.0 / 20, paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    drawStars(in: context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .background {
            LinearGradient(colors: [Color(red: 0.01, green: 0.01, blue: 0.04), Color(red: 0.03, green: 0.02, blue: 0.08)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawStars(in context: GraphicsContext, size: CGSize, time: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.45)
        let span = hypot(size.width, size.height) / 2
        let wheel = reduceMotion ? 0 : time * 0.004
        let warp = reduceMotion ? 0 : min(max(self.warp, 0), 1)
        for star in Self.stars {
            let angle = star.angle + wheel * star.depth
            let direction = CGPoint(x: cos(angle), y: sin(angle))
            // Flying forward pushes near stars out from the middle, stretching them into streaks.
            let reach = star.distance * (1 + warp * 0.9 * star.depth)
            let head = CGPoint(x: center.x + direction.x * reach * span, y: center.y + direction.y * reach * span)
            let twinkle = reduceMotion ? 1 : 0.65 + 0.35 * sin(time * star.twinkle + star.phase)
            let brightness = (0.35 + 0.65 * star.depth) * twinkle
            let color = star.color
            if warp > 0.02 {
                let length = warp * star.depth * star.distance * span * 0.45
                let tail = CGPoint(x: head.x - direction.x * length, y: head.y - direction.y * length)
                var streak = Path()
                streak.move(to: tail)
                streak.addLine(to: head)
                context.stroke(streak, with: .linearGradient(Gradient(colors: [.clear, color.opacity(brightness)]), startPoint: tail, endPoint: head),
                               style: StrokeStyle(lineWidth: star.size * (1 + warp), lineCap: .round))
            } else {
                let radius = star.size * 0.6
                context.fill(Path(ellipseIn: CGRect(x: head.x - radius, y: head.y - radius, width: radius * 2, height: radius * 2)),
                             with: .color(color.opacity(brightness)))
            }
        }
    }
}

/// Washes of colour across the sky and a faint band of the galaxy, drawn only when the tint changes.
private struct NebulaLayer: View, Equatable {
    var deepTime: Double

    var body: some View {
        Canvas { context, size in
            draw(in: context, size: size)
        }
        .drawingGroup()
    }

    private func draw(in context: GraphicsContext, size: CGSize) {
        let span = max(size.width, size.height)
        let warm = deepTime
        let clouds: [(x: Double, y: Double, r: Double, color: Color)] = [
            (0.18, 0.22, 0.75, Color(red: 0.35 + 0.25 * warm, green: 0.2, blue: 0.75 - 0.35 * warm)),
            (0.85, 0.35, 0.6, Color(red: 0.1, green: 0.35 + 0.1 * warm, blue: 0.7 - 0.3 * warm)),
            (0.55, 0.9, 0.8, Color(red: 0.45 + 0.3 * warm, green: 0.15 + 0.1 * warm, blue: 0.55 - 0.3 * warm)),
        ]
        for cloud in clouds {
            let center = CGPoint(x: size.width * cloud.x, y: size.height * cloud.y)
            let radius = span * cloud.r
            context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                         with: .radialGradient(Gradient(colors: [cloud.color.opacity(0.22), cloud.color.opacity(0.06), .clear]),
                                               center: center, startRadius: 0, endRadius: radius))
        }
        // A faint band of the galaxy across the sky.
        var band = context
        band.translateBy(x: size.width / 2, y: size.height / 2)
        band.rotate(by: .degrees(-28))
        let bandRect = CGRect(x: -span, y: -span * 0.09, width: span * 2, height: span * 0.18)
        band.fill(Path(ellipseIn: bandRect), with: .linearGradient(
            Gradient(colors: [.clear, .white.opacity(0.045), .clear]),
            startPoint: CGPoint(x: 0, y: bandRect.minY), endPoint: CGPoint(x: 0, y: bandRect.maxY)))
    }
}

private struct Star {
    var angle: Double
    /// From the middle of the screen, as a fraction of the way to a corner.
    var distance: Double
    /// Near stars are brighter and streak further.
    var depth: Double
    var size: Double
    var twinkle: Double
    var phase: Double
    var color: Color
}

/// Random numbers that come out the same every launch, so the sky doesn't change.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
