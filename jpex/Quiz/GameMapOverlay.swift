import SwiftUI

/// Game Mode's lights over its board. The place in question is striped like a stick of candy, the
/// stripes drifting and its glow breathing; an answer being pointed out glows in the colour it
/// went; either comes up as it lights rather than appearing, sending one ring out; a place too
/// small to see sends out rings; a place tapped by mistake flashes red and fades.
/// Cities are marked with dots, their names set where they keep clear of each other and of the
/// places' names on the board. Moves with the camera exactly as the map does.
struct GameMapOverlay: View, Animatable {
    var map: TravelMap
    var focus: CGRect
    var zoom: CGFloat
    var pan: CGSize
    var insets: EdgeInsets
    var spotlights: [GameSpotlight]
    var flash: GameFlash?
    /// The places' names on the board beneath, for cities' names to keep clear of.
    var labels: [String: MapLabel] = [:]
    /// Whether copies of the World sit side by side, so outlines aren't traced down the joins.
    var wrapsAround = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether decoration may move by itself, as a glow breathing does: not in Low Power Mode, nor
    /// while the app isn't in front.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    /// Cities' names follow the text size, within reason for a map.
    @ScaledMetric(relativeTo: .footnote) private var cityNameSize = 14
    /// The places' names' frames, kept while the view of the board and the names stay the same.
    @State private var nameFrames = NameFrames()

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGSize.AnimatableData>, EdgeInsets.AnimatableData> {
        get { AnimatablePair(AnimatablePair(zoom, pan.animatableData), insets.animatableData) }
        set {
            zoom = newValue.first.first
            pan.animatableData = newValue.first.second
            insets.animatableData = newValue.second
        }
    }

    var body: some View {
        // The lights breathe and drift slowly, so a gentler pace than the display's is plenty; the
        // camera's own moves still redraw at full speed, as they change the view itself.
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isMoving)) { timeline in
            Canvas { context, size in
                let geometry = MapGeometry(focus: focus, size: size, zoom: zoom, pan: pan, insets: insets)
                let seams = seamEdges
                if let flash {
                    draw(flash, in: context, geometry: geometry, now: timeline.date, seams: seams)
                }
                for spotlight in spotlights {
                    draw(spotlight, in: context, geometry: geometry, now: timeline.date, seams: seams)
                }
                let cities = spotlights.flatMap { spotlight in spotlight.cities.map { ($0, spotlight.color) } }
                if !cities.isEmpty {
                    let names = nameFrames.frames(of: labels, regions: map.regions, in: context, geometry: geometry)
                    draw(cities, avoiding: names, in: context, geometry: geometry)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Where a wrapping World is cut, in map units: its left and right edges.
    private var seamEdges: [CGFloat] {
        guard wrapsAround, let box = map.outline?.boundingRect else { return [] }
        return [box.minX, box.maxX]
    }

    /// Still lights only need drawing again when the camera moves. A flash and a twinkle fade, and a
    /// glow comes up, whatever happens; the place in question's breath and stripes rest where
    /// decoration may not move.
    private var isMoving: Bool {
        flash != nil || spotlights.contains { $0.start != nil || $0.litAt != nil }
            || (!spotlights.isEmpty && !reduceMotion && allowsAmbientMotion)
    }

    private func draw(_ spotlight: GameSpotlight, in context: GraphicsContext, geometry: MapGeometry, now: Date, seams: [CGFloat]) {
        if spotlight.style == .marker {
            if let marker = spotlight.marker {
                drawMarker(at: geometry.toScreen(marker), color: spotlight.color, start: spotlight.start, now: now, in: context)
            }
            return
        }
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
        // An answer's glow, or the place in question's candy, comes up rather than appearing:
        // swelling in over a marker's drop and sending one ring out as it lands, as the dot does, or
        // with Reduce Motion, fading in quickly. Until it's time to light, as while the camera is
        // still flying there, it stays dark.
        var rise = 1.0
        var ring: Double?
        if spotlight.style == .answer || spotlight.style == .question, let litAt = spotlight.litAt {
            let age = max(now.timeIntervalSince(litAt), 0)
            if reduceMotion {
                lit.opacity *= min(age / 0.15, 1)
            } else {
                let t = min(age / GameSpotlight.markerDrop, 1)
                rise = 1 - (1 - t) * (1 - t)
                ring = Self.landingRing(age: age)
            }
        }
        let visible = CGRect(origin: .zero, size: geometry.size)
        // A place with a main body keeps its lights there: far-flung islands drawn as part of it,
        // such as a country's overseas departments, stay dark, and its size is its main body's.
        let body = spotlight.regionIDs.count == 1 ? spotlight.mainBody.map { $0.applying(geometry.transform) } : nil
        var kept = lit
        if let body {
            let reach = max(body.width, body.height) * 0.25 + 24
            kept.clip(to: Path(body.insetBy(dx: -reach, dy: -reach)))
        }
        for id in spotlight.regionIDs {
            guard let region = map.region(id: id) else { continue }
            let box = region.bounds.applying(geometry.transform)
            let size = body ?? box
            guard size.intersects(visible.insetBy(dx: -48, dy: -48)) else { continue }
            let isTiny = max(size.width, size.height) < 10
            if !isTiny {
                let path = region.path.applying(geometry.transform)
                let edge = Self.outline(of: region.path, without: seams).applying(geometry.transform)
                switch spotlight.style {
                case .question, .twinkle:
                    // The candy fades in as it lights, its colour blooming once off the outline as
                    // an answer's glow does.
                    if let ring { drawBloom(edge, color: spotlight.color, ring: ring, in: kept) }
                    var candy = kept
                    candy.opacity *= rise
                    drawCandy(
                        path, edge: edge, box: box, visible: visible, color: spotlight.color, breath: breath, seconds: seconds,
                        in: candy)
                case .answer:
                    drawGlow(edge, color: spotlight.color, breath: breath, rise: rise, ring: ring, in: kept)
                case .marker:
                    break
                }
            }
            if spotlight.style != .twinkle, max(size.width, size.height) < 28 {
                let center = body.map { CGPoint(x: $0.midX, y: $0.midY) } ?? geometry.toScreen(region.center)
                var rings = lit
                rings.opacity *= rise
                drawRings(around: center, color: spotlight.color, seconds: seconds, marksSpot: isTiny, in: rings)
                if let ring { drawLandingRing(around: center, color: spotlight.color, phase: ring, in: lit) }
            }
        }
    }

    /// Dot's marker, which also marks where a place was tapped in Find with the borders hidden: a
    /// candy dot ringed in white, with rings spreading from it so it's found at a glance. Given when
    /// it dropped in, it lands rather than appearing: it swells from nothing a touch past its size
    /// and settles, sending one ring out as it lands, before the steady rings take over. With
    /// Reduce Motion, it only fades in.
    private func drawMarker(at center: CGPoint, color: Color, start: Date?, now: Date, in context: GraphicsContext) {
        let seconds = now.timeIntervalSinceReferenceDate
        let age = start.map { max(now.timeIntervalSince($0), 0) } ?? .infinity
        var context = context
        var scale = 1.0
        if reduceMotion {
            context.opacity = min(age / 0.15, 1)
        } else if age < GameSpotlight.markerDrop {
            // Out to 1.15 over the first 60%, easing out, then back to 1, easing in and out.
            let progress = age / GameSpotlight.markerDrop
            if progress < 0.6 {
                let t = progress / 0.6
                scale = 1.15 * (1 - (1 - t) * (1 - t))
            } else {
                let t = (progress - 0.6) / 0.4
                scale = 1.15 - 0.15 * (t * t * (3 - 2 * t))
            }
        }
        let landing = GameSpotlight.markerDrop * 0.6
        if !reduceMotion, let phase = Self.landingRing(age: age) {
            drawLandingRing(around: center, color: color, phase: phase, in: context)
        }
        // The steady rings wait until it's landed, so the drop reads on its own.
        if reduceMotion || age >= landing {
            drawRings(around: center, color: color, seconds: seconds, marksSpot: false, in: context)
        }
        let breath = reduceMotion ? 0.5 : (sin(seconds * 2 * .pi / 1.6) + 1) / 2
        let radius = (7 + 1.2 * breath) * scale
        guard radius > 0.5 else { return }
        let dot = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.drawLayer { glow in
            glow.addFilter(.shadow(color: color.opacity(0.6), radius: 6))
            glow.fill(dot, with: .color(color))
        }
        context.fill(
            dot,
            with: .linearGradient(
                Gradient(colors: [.white.opacity(0.45), .clear]),
                startPoint: CGPoint(x: center.x, y: center.y - radius), endPoint: CGPoint(x: center.x, y: center.y + radius)))
        context.stroke(dot, with: .color(.white), lineWidth: 2.5)
    }

    /// Fills a place with candy: its colour, white stripes drifting across, a shine from above,
    /// and a halo that breathes around its edge.
    private func drawCandy(
        _ path: Path, edge: Path, box: CGRect, visible: CGRect, color: Color, breath: Double, seconds: Double,
        in context: GraphicsContext
    ) {
        context.drawLayer { halo in
            halo.addFilter(.blur(radius: 4 + 4 * breath))
            halo.stroke(edge, with: .color(color), lineWidth: 5 + 3 * breath)
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
        context.stroke(edge, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
    }

    /// Where the one ring a dot or a glow sends out on landing has got to, from 0 to 1, `age`
    /// seconds after the dot began to drop in or the glow to come up; nil before it lands and once
    /// it's faded.
    private static func landingRing(age: Double) -> Double? {
        let landing = GameSpotlight.markerDrop * 0.6
        guard age >= landing, age < landing + GameSpotlight.markerRing else { return nil }
        return (age - landing) / GameSpotlight.markerRing
    }

    /// The one ring sent out as a dot lands, or a small place's glow comes up: wider and quicker
    /// than the steady ones, `phase` running from 0 as it leaves to 1 as it fades away.
    private func drawLandingRing(around center: CGPoint, color: Color, phase: Double, in context: GraphicsContext) {
        let eased = 1 - (1 - phase) * (1 - phase)
        let reach = 8 + 44 * eased
        let ring = Path(ellipseIn: CGRect(x: center.x - reach, y: center.y - reach, width: reach * 2, height: reach * 2))
        context.stroke(ring, with: .color(color.opacity(0.95 * (1 - phase))), lineWidth: 3 * (1 - phase) + 1)
    }

    /// A glow around an answer, over its colour on the board. Coming up, it swells in as `rise`
    /// runs from 0 to 1; while `ring` runs from 0 to 1, its colour blooms once off the outline and
    /// fades, as the ring a dot sends out on landing.
    private func drawGlow(
        _ path: Path, color: Color, breath: Double, rise: Double = 1, ring: Double? = nil, in context: GraphicsContext
    ) {
        if let ring { drawBloom(path, color: color, ring: ring, in: context) }
        var context = context
        context.opacity *= rise
        context.drawLayer { glow in
            glow.addFilter(.blur(radius: 5 + 4 * breath))
            glow.stroke(path, with: .color(color), lineWidth: (6 + 3 * breath) * (0.5 + 0.5 * rise))
        }
        context.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
    }

    /// A place's colour blooming once off its outline and fading as it lights, as `ring` runs from
    /// 0 to 1, as the ring a dot sends out on landing.
    private func drawBloom(_ path: Path, color: Color, ring: Double, in context: GraphicsContext) {
        let eased = 1 - (1 - ring) * (1 - ring)
        context.drawLayer { bloom in
            bloom.addFilter(.blur(radius: 2 + 6 * eased))
            bloom.stroke(path, with: .color(color.opacity(0.7 * (1 - ring))), lineWidth: 4 + 18 * eased)
        }
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

    /// Cities: white dots ringed in their spotlight's colour, each with its name on a soft halo.
    /// A name goes beside its dot where it keeps clear of the other cities and the places' names,
    /// trying the right, the left, above and below; failing that, it stands a little way off with a
    /// fine line back to its dot.
    private func draw(
        _ cities: [(city: GameSpotlight.City, color: Color)], avoiding names: [CGRect], in context: GraphicsContext,
        geometry: MapGeometry
    ) {
        let screen = CGRect(origin: .zero, size: geometry.size)
        let shown = cities.compactMap { city, color -> (name: String, center: CGPoint, color: Color)? in
            let center = geometry.toScreen(city.point)
            return screen.insetBy(dx: -40, dy: -40).contains(center) ? (city.name, center, color) : nil
        }
        guard !shown.isEmpty else { return }
        var taken = names + shown.map { CGRect(x: $0.center.x - 7, y: $0.center.y - 7, width: 14, height: 14) }
        var label = context
        // A light name needs a firmer halo to read over land.
        label.addFilter(.shadow(color: Color(uiColor: .systemBackground), radius: 1))
        label.addFilter(.shadow(color: Color(uiColor: .systemBackground).opacity(0.95), radius: 2))
        label.addFilter(.shadow(color: Color(uiColor: .systemBackground).opacity(0.6), radius: 5))
        for city in shown {
            let dot = Path(ellipseIn: CGRect(x: city.center.x - 5, y: city.center.y - 5, width: 10, height: 10))
            context.fill(dot, with: .color(.white))
            context.stroke(dot, with: .color(city.color), lineWidth: 3)
        }
        let room = screen.insetBy(dx: 4, dy: 4)
        let size = min(cityNameSize, 22)
        for city in shown {
            let name = label.resolve(
                Text(city.name).font(.system(size: size, weight: .regular)).foregroundStyle(.primary))
            let measured = name.measure(in: CGSize(width: 400, height: 100))
            let spot = Self.spot(for: measured, beside: city.center, clear: taken, within: room)
            taken.append(spot.rect.insetBy(dx: -2, dy: -1))
            if spot.isAway {
                // A fine line from the edge of the dot to the nearest point of the name.
                let target = CGPoint(
                    x: min(max(city.center.x, spot.rect.minX), spot.rect.maxX),
                    y: min(max(city.center.y, spot.rect.minY), spot.rect.maxY))
                let distance = max(hypot(target.x - city.center.x, target.y - city.center.y), 1)
                let start = CGPoint(
                    x: city.center.x + (target.x - city.center.x) / distance * 6,
                    y: city.center.y + (target.y - city.center.y) / distance * 6)
                var leader = Path()
                leader.move(to: start)
                leader.addLine(to: target)
                context.stroke(leader, with: .color(city.color.opacity(0.8)), style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
            }
            label.draw(name, in: spot.rect)
        }
    }

    /// Where to set a city's name: the first place beside its dot that's clear and on screen,
    /// then the same a step further away, or else just to the right.
    private static func spot(
        for size: CGSize, beside center: CGPoint, clear taken: [CGRect], within room: CGRect
    ) -> (rect: CGRect, isAway: Bool) {
        func rect(dx: CGFloat, dy: CGFloat, gap: CGFloat) -> CGRect {
            // dx and dy pick a side: -1 for left or above, 0 for centred, 1 for right or below.
            let x = dx > 0 ? center.x + gap : dx < 0 ? center.x - gap - size.width : center.x - size.width / 2
            let y = dy > 0 ? center.y + gap * 0.6 : dy < 0 ? center.y - gap * 0.6 - size.height : center.y - size.height / 2
            return CGRect(x: x, y: y, width: size.width, height: size.height)
        }
        let sides: [(CGFloat, CGFloat)] = [(1, 0), (-1, 0), (0, -1), (0, 1), (1, -1), (1, 1), (-1, -1), (-1, 1)]
        for gap in [9.0, 26.0, 44.0] {
            for (dx, dy) in sides {
                let spot = rect(dx: dx, dy: dy, gap: dy != 0 && dx == 0 ? max(gap, 8) : gap)
                if room.contains(spot), !taken.contains(where: { $0.intersects(spot) }) {
                    return (spot, gap > 9)
                }
            }
        }
        return (rect(dx: 1, dy: 0, gap: 9), false)
    }

    /// A place's outline without the straight cuts down a wrapping World's edges, where the place
    /// carries on across the join on the next copy.
    private static func outline(of path: Path, without seams: [CGFloat]) -> Path {
        guard !seams.isEmpty else { return path }
        let tolerance = 0.0001 * max(abs(seams[1] - seams[0]), 1)
        func onSeam(_ a: CGPoint, _ b: CGPoint) -> Bool {
            seams.contains { abs(a.x - $0) < tolerance && abs(b.x - $0) < tolerance }
        }
        var result = Path()
        var start = CGPoint.zero
        var current = CGPoint.zero
        path.forEach { element in
            switch element {
            case .move(let point):
                result.move(to: point)
                start = point
                current = point
            case .line(let point):
                if onSeam(current, point) { result.move(to: point) } else { result.addLine(to: point) }
                current = point
            case .quadCurve(let point, let control):
                result.addQuadCurve(to: point, control: control)
                current = point
            case .curve(let point, let control1, let control2):
                result.addCurve(to: point, control1: control1, control2: control2)
                current = point
            case .closeSubpath:
                if onSeam(current, start) { result.move(to: start) } else { result.addLine(to: start) }
                current = start
            }
        }
        return result
    }

    /// A place tapped by mistake, red at first and fading.
    private func draw(_ flash: GameFlash, in context: GraphicsContext, geometry: MapGeometry, now: Date, seams: [CGFloat]) {
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
            let edge = Self.outline(of: region.path, without: seams).applying(geometry.transform)
            context.fill(path, with: .color(red.opacity(0.4 * fade)), style: FillStyle(eoFill: true))
            context.stroke(edge, with: .color(red.opacity(fade)), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
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

/// The frames of the places' names on the board, for cities' names to keep clear of: worked out once
/// for each view of the board and set of names, rather than every name measured again at every
/// frame while the lights breathe.
private final class NameFrames {
    private var key: Key?
    private var frames: [CGRect] = []

    private struct Key: Equatable {
        var labels: [String: MapLabel]
        var regionCount: Int
        var focus: CGRect
        var size: CGSize
        var zoom: CGFloat
        var pan: CGSize
        var insets: EdgeInsets
    }

    func frames(
        of labels: [String: MapLabel], regions: [MapRegion], in context: GraphicsContext, geometry: MapGeometry
    ) -> [CGRect] {
        let key = Key(
            labels: labels, regionCount: regions.count, focus: geometry.focus, size: geometry.size, zoom: geometry.zoom,
            pan: geometry.pan, insets: geometry.insets)
        if key == self.key { return frames }
        frames = MapLabels.frames(labels, regions: regions, in: context, geometry: geometry)
        self.key = key
        return frames
    }
}
