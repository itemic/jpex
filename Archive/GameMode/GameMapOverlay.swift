import SwiftUI

/// Game Mode's lights over its board. The place in question is striped like a stick of candy, the
/// stripes drifting and its glow breathing; an answer being pointed out glows in the colour it
/// went; a place too small to see sends out rings; a place tapped by mistake flashes red and fades.
/// Moves with the camera exactly as the map does.
struct GameMapOverlay: View, Animatable {
    var map: TravelMap
    var focus: CGRect
    var zoom: CGFloat
    var pan: CGSize
    var insets: EdgeInsets
    var spotlight: GameSpotlight?
    var flash: GameFlash?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGSize.AnimatableData>, EdgeInsets.AnimatableData> {
        get { AnimatablePair(AnimatablePair(zoom, pan.animatableData), insets.animatableData) }
        set {
            zoom = newValue.first.first
            pan.animatableData = newValue.first.second
            insets.animatableData = newValue.second
        }
    }

    var body: some View {
        TimelineView(.animation(paused: !isMoving)) { timeline in
            Canvas { context, size in
                let geometry = MapGeometry(focus: focus, size: size, zoom: zoom, pan: pan, insets: insets)
                if let flash {
                    draw(flash, in: context, geometry: geometry, now: timeline.date)
                }
                if let spotlight {
                    draw(spotlight, in: context, geometry: geometry, now: timeline.date)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Still lights only need drawing again when the camera moves.
    private var isMoving: Bool {
        flash != nil || spotlight?.start != nil || (spotlight != nil && !reduceMotion)
    }

    private func draw(_ spotlight: GameSpotlight, in context: GraphicsContext, geometry: MapGeometry, now: Date) {
        let seconds = now.timeIntervalSinceReferenceDate
        // A slow breath in and out, from 0 to 1 and back.
        let breath = reduceMotion ? 0.5 : (sin(seconds * 2 * .pi / 1.6) + 1) / 2
        var lit = context
        if let start = spotlight.start {
            // A twinkle lights up and fades once.
            let progress = now.timeIntervalSince(start) / GameSpotlight.twinkleDuration
            guard progress < 1 else { return }
            lit.opacity = sin(.pi * min(max(progress, 0), 1))
        }
        let visible = CGRect(origin: .zero, size: geometry.size)
        for id in spotlight.regionIDs {
            guard let region = map.region(id: id) else { continue }
            let box = region.bounds.applying(geometry.transform)
            guard box.intersects(visible.insetBy(dx: -48, dy: -48)) else { continue }
            let isTiny = max(box.width, box.height) < 10
            if !isTiny {
                let path = region.path.applying(geometry.transform)
                switch spotlight.style {
                case .question, .twinkle:
                    drawCandy(path, box: box, visible: visible, color: spotlight.color, breath: breath, seconds: seconds, in: lit)
                case .answer:
                    drawGlow(path, color: spotlight.color, breath: breath, in: lit)
                }
            }
            if spotlight.style != .twinkle, max(box.width, box.height) < 28 {
                drawRings(
                    around: geometry.toScreen(region.center), color: spotlight.color, seconds: seconds, marksSpot: isTiny,
                    in: lit)
            }
        }
    }

    /// Fills a place with candy: its colour, white stripes drifting across, a shine from above,
    /// and a halo that breathes around its edge.
    private func drawCandy(
        _ path: Path, box: CGRect, visible: CGRect, color: Color, breath: Double, seconds: Double, in context: GraphicsContext
    ) {
        context.drawLayer { halo in
            halo.addFilter(.blur(radius: 4 + 4 * breath))
            halo.stroke(path, with: .color(color), lineWidth: 5 + 3 * breath)
        }
        var inside = context
        inside.clip(to: path, style: FillStyle(eoFill: true))
        let area = box.intersection(visible.insetBy(dx: -16, dy: -16))
        guard !area.isNull else { return }
        inside.fill(Path(area), with: .color(color))
        let drift = reduceMotion ? 0 : (seconds * 9).truncatingRemainder(dividingBy: 12)
        inside.fill(Self.stripes(over: area, from: box.minX + drift, period: 12), with: .color(.white.opacity(0.32)))
        inside.fill(
            Path(box),
            with: .linearGradient(
                Gradient(colors: [.white.opacity(0.3), .clear, .black.opacity(0.1)]),
                startPoint: CGPoint(x: box.midX, y: box.minY), endPoint: CGPoint(x: box.midX, y: box.maxY)))
        context.stroke(path, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
    }

    /// A glow around an answer, over its colour on the board.
    private func drawGlow(_ path: Path, color: Color, breath: Double, in context: GraphicsContext) {
        context.drawLayer { glow in
            glow.addFilter(.blur(radius: 5 + 4 * breath))
            glow.stroke(path, with: .color(color), lineWidth: 6 + 3 * breath)
        }
        context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
    }

    /// Rings spreading from a place too small to find at a glance, with a dot to mark the spot
    /// when there's nothing to see at all.
    private func drawRings(around center: CGPoint, color: Color, seconds: Double, marksSpot: Bool, in context: GraphicsContext) {
        for ring in 0..<(reduceMotion ? 1 : 3) {
            let phase = reduceMotion ? 0.45 : (seconds / 1.8 + Double(ring) / 3).truncatingRemainder(dividingBy: 1)
            let radius = 7 + 30 * phase
            let circle = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.stroke(circle, with: .color(color.opacity(0.9 * (1 - phase))), lineWidth: 2.5)
        }
        guard marksSpot else { return }
        let dot = Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10))
        context.fill(dot, with: .color(color))
        context.stroke(dot, with: .color(.white), lineWidth: 1.5)
    }

    /// A place tapped by mistake, red at first and fading.
    private func draw(_ flash: GameFlash, in context: GraphicsContext, geometry: MapGeometry, now: Date) {
        let fade = 1 - min(max(now.timeIntervalSince(flash.start) / GameFlash.duration, 0), 1)
        guard fade > 0 else { return }
        let red = LevelColor.red.color
        for id in flash.regionIDs {
            guard let region = map.region(id: id) else { continue }
            let box = region.bounds.applying(geometry.transform)
            if max(box.width, box.height) < 10 {
                let center = geometry.toScreen(region.center)
                context.fill(Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)), with: .color(red.opacity(fade)))
                continue
            }
            let path = region.path.applying(geometry.transform)
            context.fill(path, with: .color(red.opacity(0.4 * fade)), style: FillStyle(eoFill: true))
            context.stroke(path, with: .color(red.opacity(fade)), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
        }
    }

    /// Bands leaning like the stripes on the app's progress bars, hung from `start` so they travel
    /// with the place, covering `area`.
    private static func stripes(over area: CGRect, from start: CGFloat, period: CGFloat) -> Path {
        var stripes = Path()
        let first = start + ((area.minX - area.height - start) / period).rounded(.down) * period
        var x = first - period
        while x < area.maxX {
            stripes.move(to: CGPoint(x: x, y: area.maxY))
            stripes.addLine(to: CGPoint(x: x + area.height, y: area.minY))
            stripes.addLine(to: CGPoint(x: x + area.height + period / 2, y: area.minY))
            stripes.addLine(to: CGPoint(x: x + period / 2, y: area.maxY))
            stripes.closeSubpath()
            x += period
        }
        return stripes
    }
}
