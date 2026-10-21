import SwiftUI

/// A place that has just risen a level, lifted off its map into the screen above everything. It
/// rises out of the map like a sticker peeled up, past the card's edges, the panel and the callout,
/// its new colour flooding across it; wobbles there a moment; then drops back into its place. As it
/// lands, sparks in its level's colour fly out across the screen. The map beneath keeps the place's
/// old colour until then, so the two meet without a seam.
struct PlaceLift: Identifiable {
    /// Seconds from the start until the place lands back on its map.
    static let landing = 0.7
    /// Seconds after landing for the place to settle and give way to the map beneath it.
    static let settle = 0.14

    let id = UUID()
    /// The place's main body, in the screen's coordinates.
    var outline: Path
    /// A point inside the place, which it lifts around and its new colour floods out from.
    var center: CGPoint
    var from: Color
    var to: Color
    var symbolName: String
    /// How high the new level is on the ladder: above 0 for the lowest, 1 for the top. Higher
    /// levels grow larger and throw more sparks.
    var height: Double
    var start: Date
    var sparks: [Spark]
    /// The outline's bounds, measured once rather than every frame.
    let bounds: CGRect
    /// How much larger the place grows at the height of its lift: a lot for a small place, so it can
    /// be made out, and only a little for a large one.
    let peakScale: CGFloat

    init(outline: Path, center: CGPoint, from: Color, to: Color, symbolName: String, height: Double, start: Date) {
        self.outline = outline
        self.center = center
        self.from = from
        self.to = to
        self.symbolName = symbolName
        self.height = height
        self.start = start
        bounds = outline.boundingRect
        let size = max(bounds.width, bounds.height)
        peakScale = min(max(1 + (20 + 12 * height) / max(size, 1), 1.05), 2.6)
        sparks = Spark.burst(
            dots: 6 + Int(14 * height), badges: max(1, Int((3 * height).rounded())),
            reach: min(max(size / 2, 6), 44),
            speed: (170 * (0.8 + 0.5 * height))...(360 * (0.8 + 0.5 * height)))
    }

    /// Seconds from the start until the last spark has gone.
    var duration: Double {
        Self.landing + max(Self.settle, sparks.map { $0.delay + $0.life }.max() ?? 0)
    }

    /// How far up the place is, `time` seconds in: it springs up with a little overshoot, hangs
    /// there, then drops back faster and faster, as if it fell.
    static func rise(at time: Double) -> Double {
        let up = 0.26
        let fall = 0.2
        guard time > 0 else { return 0 }
        if time < up { return backOut(time / up) }
        if time < landing - fall { return 1 }
        guard time < landing else { return 0 }
        let fallen = (time - (landing - fall)) / fall
        return 1 - fallen * fallen
    }
}

/// A level's badge floating up out of a pill that has just risen to it, over the rows around the
/// row it belongs to. The top level throws a few sparks as well.
struct LevelFloat: Identifiable {
    static let duration = 0.95

    let id = UUID()
    /// The top of the pill, in the screen's coordinates.
    var origin: CGPoint
    var color: Color
    var symbolName: String
    var start: Date
    var sparks: [Spark]

    init(origin: CGPoint, color: Color, symbolName: String, isTop: Bool, start: Date = .now) {
        self.origin = origin
        self.color = color
        self.symbolName = symbolName
        self.start = start
        sparks = isTop ? Spark.burst(dots: 12, badges: 0, reach: 10, speed: 120...260) : []
    }
}

/// Confetti thrown from a point on screen across everything around it, such as a finished region's
/// count or a finished list's note.
struct ScreenBurst: Identifiable {
    let id = UUID()
    var origin: CGPoint
    var start: Date
    var pieces: [ConfettiPiece]
    var duration: Double
}

/// A fleck flung out when a place rises: a glossy dot of the level's colour or white, or a small
/// badge with the level's symbol, thrown outwards and falling away.
struct Spark {
    static let gravity = 760.0

    /// Where it starts, from the middle of what threw it.
    var offset: CGVector
    var velocity: CGVector
    var radius: CGFloat
    var isBadge: Bool
    var isWhite: Bool
    var delay: Double
    var life: Double
    var spin: Double

    /// Sparks thrown all around but mostly upwards, the way a splash goes, from within `reach` of
    /// the middle.
    static func burst(dots: Int, badges: Int, reach: CGFloat, speed: ClosedRange<Double>) -> [Spark] {
        (0..<(dots + badges)).map { index in
            let isBadge = index < badges
            let angle = -Double.pi / 2 + .random(in: -1...1) * .pi * (isBadge ? 0.5 : 0.9)
            let start = reach * .random(in: 0.25...0.7)
            let speed = Double.random(in: speed) * (isBadge ? 0.85 : 1)
            return Spark(
                offset: CGVector(dx: cos(angle) * start, dy: sin(angle) * start),
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                radius: isBadge ? .random(in: 8...10) : .random(in: 1.8...3.4),
                isBadge: isBadge,
                isWhite: !isBadge && index % 4 == 0,
                delay: .random(in: 0...0.07),
                life: isBadge ? .random(in: 0.85...1.15) : .random(in: 0.55...1.05),
                spin: .random(in: -4...4))
        }
    }
}

/// Draws every effect breaking out over the screen, in one canvas the size of the window, above
/// sheets and full-screen maps alike. Reduce Motion leaves them all out.
struct ScreenEffectsLayer: View {
    var lifts: [PlaceLift]
    var floats: [LevelFloat]
    var bursts: [ScreenBurst]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, _ in
                guard !reduceMotion else { return }
                let now = timeline.date
                var symbols = SymbolCache()
                for burst in bursts {
                    ConfettiPiece.draw(burst.pieces, elapsed: now.timeIntervalSince(burst.start), from: burst.origin, in: context)
                }
                for lift in lifts {
                    draw(lift, at: now, in: context, symbols: &symbols)
                }
                for float in floats {
                    draw(float, at: now, in: context, symbols: &symbols)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(_ lift: PlaceLift, at now: Date, in context: GraphicsContext, symbols: inout SymbolCache) {
        let time = now.timeIntervalSince(lift.start)
        guard time >= 0 else { return }
        if time < PlaceLift.landing + PlaceLift.settle {
            drawPiece(of: lift, at: time, in: context)
        }
        guard time >= PlaceLift.landing else { return }
        let symbol = symbols.symbol(lift.symbolName, in: context)
        for spark in lift.sparks {
            Self.draw(spark, elapsed: time - PlaceLift.landing, from: lift.center, color: lift.to, symbol: symbol, in: context)
        }
    }

    /// The place itself, lifted off its map: in its shadow, its new colour flooding out across it,
    /// with a sheen and a white edge, like a sticker, for as long as it's in the air.
    private func drawPiece(of lift: PlaceLift, at time: Double, in context: GraphicsContext) {
        let rise = PlaceLift.rise(at: time)
        let settled = time > PlaceLift.landing ? min((time - PlaceLift.landing) / PlaceLift.settle, 1) : 0
        let scale = (1 + (lift.peakScale - 1) * rise) * (1 - 0.04 * sin(.pi * settled))
        let box = lift.bounds
        let distance = min(6 + max(box.width, box.height) * 0.04, 14)
        let style = FillStyle(eoFill: true)
        var piece = context
        piece.opacity = 1 - settled
        piece.translateBy(x: lift.center.x, y: lift.center.y - distance * rise)
        piece.rotate(by: .degrees(2.5 * sin(time * 13) * rise))
        piece.scaleBy(x: scale, y: scale)
        piece.translateBy(x: -lift.center.x, y: -lift.center.y)
        var shadowed = piece
        shadowed.addFilter(.shadow(
            color: .black.opacity(0.3 * min(rise, 1)), radius: (3 + 12 * rise) / scale, y: (2 + 12 * rise) / scale))
        shadowed.fill(lift.outline, with: .color(lift.from), style: style)
        var surface = piece
        surface.clip(to: lift.outline, style: style)
        // The new colour floods out from the middle as it rises.
        let flood = smoothstep((time - 0.04) / 0.38)
        if flood > 0 {
            let reach = [
                CGPoint(x: box.minX, y: box.minY), CGPoint(x: box.maxX, y: box.minY),
                CGPoint(x: box.minX, y: box.maxY), CGPoint(x: box.maxX, y: box.maxY),
            ].map { hypot($0.x - lift.center.x, $0.y - lift.center.y) }.max() ?? 0
            let radius = max(reach * 1.2 * flood, 0.001)
            surface.fill(
                Path(ellipseIn: CGRect(x: lift.center.x - radius, y: lift.center.y - radius, width: radius * 2, height: radius * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: lift.to, location: 0), .init(color: lift.to, location: 0.82),
                        .init(color: lift.to.opacity(0), location: 1),
                    ]),
                    center: lift.center, startRadius: 0, endRadius: radius))
        }
        surface.fill(
            Path(box),
            with: .linearGradient(
                Gradient(colors: [.white.opacity(0.4 * min(rise, 1)), .white.opacity(0)]),
                startPoint: CGPoint(x: box.minX, y: box.minY),
                endPoint: CGPoint(x: box.minX + box.width * 0.3, y: box.midY)))
        piece.stroke(
            lift.outline, with: .color(.white.opacity(0.95 * min(rise, 1))),
            style: StrokeStyle(lineWidth: 2.2 / scale, lineJoin: .round))
    }

    /// The badge springs out of the pill, rises over the rows above it, and fades as it goes.
    private func draw(_ float: LevelFloat, at now: Date, in context: GraphicsContext, symbols: inout SymbolCache) {
        let time = now.timeIntervalSince(float.start)
        guard time >= 0, time < LevelFloat.duration else { return }
        let symbol = symbols.symbol(float.symbolName, in: context)
        for spark in float.sparks {
            Self.draw(spark, elapsed: time, from: float.origin, color: float.color, symbol: symbol, in: context)
        }
        let climbed = 1 - pow(1 - min(time / 0.6, 1), 3)
        let grown = 0.35 + 0.65 * backOut(min(time / 0.3, 1))
        var badge = context
        badge.opacity = time < 0.55 ? 1 : max(1 - (time - 0.55) / 0.4, 0)
        Self.drawBadge(
            symbol: symbol, color: float.color, radius: 12 * grown,
            at: CGPoint(x: float.origin.x, y: float.origin.y - 4 - 46 * climbed), rotation: .zero, in: badge)
    }

    private static func draw(
        _ spark: Spark, elapsed: Double, from origin: CGPoint, color: Color,
        symbol: GraphicsContext.ResolvedText, in context: GraphicsContext
    ) {
        let time = elapsed - spark.delay
        guard time > 0, time < spark.life else { return }
        let point = CGPoint(
            x: origin.x + spark.offset.dx + spark.velocity.dx * time,
            y: origin.y + spark.offset.dy + spark.velocity.dy * time + 0.5 * Spark.gravity * time * time)
        // Each one pops into being, then fades as it falls.
        let radius = spark.radius * min(time / 0.08, 1)
        var fleck = context
        fleck.opacity = 1 - pow(time / spark.life, 2)
        if spark.isBadge {
            drawBadge(symbol: symbol, color: color, radius: radius, at: point, rotation: .radians(spark.spin * time), in: fleck)
            return
        }
        fleck.fill(circle(at: point, radius: radius), with: .color(spark.isWhite ? .white : color))
        if !spark.isWhite {
            fleck.fill(
                circle(at: CGPoint(x: point.x - radius * 0.3, y: point.y - radius * 0.3), radius: radius * 0.4),
                with: .color(.white.opacity(0.7)))
        }
    }

    /// A small round badge in the level's colour with its symbol, glossy like the level badges.
    private static func drawBadge(
        symbol: GraphicsContext.ResolvedText, color: Color, radius: CGFloat, at point: CGPoint, rotation: Angle,
        in context: GraphicsContext
    ) {
        guard radius > 0.1 else { return }
        var badge = context
        badge.translateBy(x: point.x, y: point.y)
        badge.rotate(by: rotation)
        let shape = circle(at: .zero, radius: radius)
        var shadowed = badge
        shadowed.addFilter(.shadow(color: .black.opacity(0.25), radius: 2, y: 1))
        shadowed.fill(shape, with: .color(color))
        badge.fill(shape, with: .linearGradient(
            Gradient(colors: [.white.opacity(0.5), .white.opacity(0)]),
            startPoint: CGPoint(x: 0, y: -radius), endPoint: .zero))
        badge.fill(shape, with: .linearGradient(
            Gradient(colors: [.black.opacity(0), .black.opacity(0.18)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: radius)))
        let scale = radius / SymbolCache.badgeRadius
        badge.scaleBy(x: scale, y: scale)
        badge.draw(symbol, at: .zero, anchor: .center)
    }

    private static func circle(at point: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }
}

/// Levels' symbols, set white and bold for their badges, resolved once a frame each.
private struct SymbolCache {
    /// The badge size the symbols are set for; badges of other sizes scale them.
    static let badgeRadius: CGFloat = 10

    private var resolved: [String: GraphicsContext.ResolvedText] = [:]

    mutating func symbol(_ name: String, in context: GraphicsContext) -> GraphicsContext.ResolvedText {
        if let symbol = resolved[name] { return symbol }
        let symbol = context.resolve(
            Text(Image(systemName: name))
                .font(.system(size: Self.badgeRadius * 0.95, weight: .heavy))
                .foregroundStyle(.white))
        resolved[name] = symbol
        return symbol
    }
}

/// Rises past 1 a little before settling there, as `progress` runs from 0 to 1.
private func backOut(_ progress: Double) -> Double {
    let x = min(max(progress, 0), 1) - 1
    let overshoot = 1.4
    return x * x * ((overshoot + 1) * x + overshoot) + 1
}

private func smoothstep(_ progress: Double) -> Double {
    let t = min(max(progress, 0), 1)
    return t * t * (3 - 2 * t)
}

/// Where a view sits on screen, kept up to date as it moves without redrawing it, so an effect can
/// start from it.
@MainActor
final class ScreenFrame {
    var rect: CGRect = .null

    /// The middle of the view, or nil before it has been laid out.
    var center: CGPoint? {
        rect.isNull || rect.isEmpty ? nil : CGPoint(x: rect.midX, y: rect.midY)
    }
}

extension View {
    /// Keeps `frame` up to date with where this view sits on screen.
    func trackingScreenFrame(_ frame: ScreenFrame) -> some View {
        onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame.rect = $0 }
    }
}

/// A mask that fades towards its edges, so a map dissolves into the page around it instead of
/// ending at a line. The map's sea is the page's own colour, so only the land and its lines fade.
struct EdgeFade: View {
    /// How far in from the leading and trailing edges the fade reaches.
    var horizontal: CGFloat = 28
    /// How far in from the top and bottom edges the fade reaches.
    var vertical: CGFloat = 18

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: horizontal)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: horizontal)
        }
        .mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: vertical)
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: vertical)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Bobs as the ring of light from a place rising on the map passes over it, so the wave
    /// carries on visibly from the map through the page around it: rows, headers and panels each
    /// lift in turn, a little less the further the wave has come.
    func feelsRipples() -> some View {
        modifier(RippleBob())
    }
}

private struct RippleBob: ViewModifier {
    /// How far the wave reaches across the page before it has died away, in points.
    private static let reach: CGFloat = 1100
    /// How fast the wave crosses the screen, as the ring of light does, in points a second.
    private static let speed = 700.0

    @Environment(\.breaksOutOntoScreen) private var breaksOutOntoScreen
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frame = ScreenFrame()
    @State private var wave = Wave()

    func body(content: Content) -> some View {
        content
            .trackingScreenFrame(frame)
            .keyframeAnimator(initialValue: 0.0, trigger: wave.count) { view, lift in
                view.offset(y: -lift)
            } keyframes: { _ in
                KeyframeTrack {
                    // Waits for the wave to arrive, then rides up on its first crest and settles.
                    LinearKeyframe(0, duration: wave.delay)
                    CubicKeyframe(wave.height, duration: 0.12)
                    SpringKeyframe(0, duration: 0.7, spring: .bouncy(extraBounce: 0.35))
                }
            }
            .onChange(of: ToastCenter.shared.ripple?.id) { _, id in
                guard id != nil, breaksOutOntoScreen, !reduceMotion, let ripple = ToastCenter.shared.ripple,
                      let center = frame.center
                else { return }
                let distance = hypot(center.x - ripple.origin.x, center.y - ripple.origin.y)
                guard distance < Self.reach else { return }
                wave = Wave(
                    count: wave.count + 1,
                    delay: max(ripple.start.timeIntervalSinceNow, 0) + Double(distance) / Self.speed + 0.08,
                    height: 0.8 + 2.4 * (1 - distance / Self.reach))
            }
    }

    private struct Wave {
        var count = 0
        var delay = 0.0
        var height: CGFloat = 0
    }
}
