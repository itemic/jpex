import SwiftUI
import simd

/// The Earth in deep time: a globe in space whose continents ride their plates back toward
/// Pangaea as `ma` grows, lit from the upper left with a halo of atmosphere. While `morph` runs
/// from 0 to 1, the flat map of the earliest era curls into the globe, each point gliding from
/// its place on the map to its place on the sphere, as its countries' colours turn to earth.
struct DeepTimeGlobe: View, Animatable {
    var atlas: TimeMachineAtlas
    var geometry: HistoryMapGeometry
    var deepTime: DeepTime
    var mesh: GlobeMesh
    /// Millions of years ago.
    var ma: Double
    /// From the flat map, at 0, to the globe, at 1.
    var morph: Double
    /// The era the flat map shows as it curls up.
    var era: Int
    /// Where the flat map's card sits in this view, for the map to curl up from.
    var mapFrame: CGRect
    /// Which way the globe faces, in degrees: the longitude and latitude at its centre.
    var spin: GlobeSpin
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// When the globe as drawn last passed the asteroid, to play its fall, flash and shock wave.
    @State private var impact = ImpactClock()

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(ma, morph) }
        set {
            ma = newValue.first
            morph = newValue.second
        }
    }

    var body: some View {
        // Smooth while held, gliding or striking; otherwise the slow drift needs only a gentle rate.
        let isLively = spin.isHeld || spin.isGliding(at: .now) || impact.isPlaying(at: .now)
        TimelineView(.animation(minimumInterval: isLively ? nil : 1.0 / 30, paused: reduceMotion && !spin.isHeld)) { timeline in
            Canvas { context, size in
                impact.notice(ma: ma, events: deepTime.events, at: timeline.date, isShown: morph >= 1 && !reduceMotion)
                draw(in: &context, size: size, now: timeline.date)
            }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, now: Date) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.43
        let flat = geometry.transform(in: mapFrame.size, camera: .whole)
            .concatenating(CGAffineTransform(translationX: mapFrame.minX, y: mapFrame.minY))
        let facing = spin.facing(at: now, reduceMotion: reduceMotion)
        let view = Self.viewRotation(longitude: facing.longitude, latitude: facing.latitude)
        let plateTurns = deepTime.rotations(at: ma)
        let turns = plateTurns.map { view * $0 }
        let identity = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
        let m = CGFloat(morph)
        let eased = morph * morph * (3 - 2 * morph)

        func onGlobe(_ v: simd_double3) -> CGPoint {
            if v.x >= 0 { return CGPoint(x: center.x + radius * v.y, y: center.y - radius * v.z) }
            let length = max((v.y * v.y + v.z * v.z).squareRoot(), 1e-9)
            return CGPoint(x: center.x + radius * v.y / length, y: center.y - radius * v.z / length)
        }

        // A halo of atmosphere, then the sea: the flat map's ocean shape curling into a disc.
        if morph > 0.3 {
            let halo = Path(ellipseIn: CGRect(x: center.x - radius * 1.25, y: center.y - radius * 1.25, width: radius * 2.5, height: radius * 2.5))
            context.fill(halo, with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 0.35, green: 0.6, blue: 1).opacity(0.45 * (morph - 0.3) / 0.7), location: 0.78),
                    .init(color: Color(red: 0.25, green: 0.4, blue: 1).opacity(0.12 * (morph - 0.3) / 0.7), location: 0.86),
                    .init(color: .clear, location: 1),
                ]),
                center: center, startRadius: 0, endRadius: radius * 1.25))
        }
        var sea = Path()
        let rim = geometry.outlinePoints.indices.map { index -> CGPoint in
            // The map's edge starts at its lower left and runs up, across and round, as the rim does.
            let angle = 1.25 * Double.pi - 2 * Double.pi * Double(index) / Double(geometry.outlinePoints.count)
            return CGPoint(x: center.x + radius * cos(angle), y: center.y - radius * sin(angle))
        }
        sea.addRing(zip(geometry.outlinePoints, rim).map { mapPoint, globePoint in
            let a = mapPoint.applying(flat)
            return CGPoint(x: a.x + (globePoint.x - a.x) * m, y: a.y + (globePoint.y - a.y) * m)
        }, closed: true)
        context.fill(sea, with: .radialGradient(
            Gradient(colors: [Color(red: 0.12, green: 0.27, blue: 0.48), Color(red: 0.04, green: 0.09, blue: 0.22), Color(red: 0.02, green: 0.04, blue: 0.11)]),
            center: CGPoint(x: center.x - radius * 0.35, y: center.y - radius * 0.4),
            startRadius: 0, endRadius: radius * 1.6))

        // Land.
        var outlines = Path()
        var byPlate: [Int: Path] = [:]
        for unit in atlas.units.indices {
            let presence = deepTime.presence(ofUnit: unit, at: ma)
            guard presence > 0.01 else { continue }
            let plate = deepTime.unitPlates[unit]
            let turn = plate.map { turns[$0] } ?? (view * identity)
            var path = Path()
            for (ringIndex, ring) in mesh.vectors[unit].enumerated() {
                let globePoints = ring.map { onGlobe(turn.act($0)) }
                if morph >= 1 {
                    // Rings wholly on the far side stay hidden.
                    guard ring.contains(where: { turn.act($0).x >= 0 }) else { continue }
                    path.addRing(globePoints, closed: true)
                } else {
                    let mapPoints = geometry.unitLightPoints[unit][ringIndex]
                    path.addRing(zip(mapPoints, globePoints).map { mapPoint, globePoint in
                        let a = mapPoint.applying(flat)
                        return CGPoint(x: a.x + (globePoint.x - a.x) * m, y: a.y + (globePoint.y - a.y) * m)
                    }, closed: true)
                }
            }
            guard !path.isEmpty else { continue }
            let earth = plate.map { deepTime.plates[$0].color } ?? HistoryColor.sand.resolved
            if morph >= 1, presence >= 1, let plate {
                byPlate[plate, default: Path()].addPath(path)
            } else {
                let political = geometry.styles.indices.contains(era) ? geometry.styles[era].fills[unit] : earth
                var layer = context
                layer.opacity = presence
                layer.fill(path, with: .color(Color(political.mixed(with: earth, by: Float(eased)))))
            }
            outlines.addPath(path)
        }
        for (plate, path) in byPlate {
            context.fill(path, with: .color(Color(deepTime.plates[plate].color)))
        }
        context.stroke(outlines, with: .color(.white.opacity(0.5 - 0.36 * eased)), lineWidth: 0.5)

        guard morph > 0.05 else { return }
        // Shade: the night side, a soft rim and a highlight where the Sun catches the sea.
        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        var shade = context
        shade.opacity = eased
        shade.fill(disc, with: .radialGradient(
            Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .clear, location: 0.55),
                .init(color: .black.opacity(0.55), location: 1),
            ]),
            center: CGPoint(x: center.x - radius * 0.45, y: center.y - radius * 0.5),
            startRadius: 0, endRadius: radius * 2.1))
        shade.fill(disc, with: .radialGradient(
            Gradient(colors: [.white.opacity(0.16), .clear]),
            center: CGPoint(x: center.x - radius * 0.4, y: center.y - radius * 0.45),
            startRadius: 0, endRadius: radius * 0.55))
        shade.stroke(disc, with: .linearGradient(
            Gradient(colors: [Color(red: 0.6, green: 0.8, blue: 1).opacity(0.7), .clear]),
            startPoint: CGPoint(x: center.x - radius, y: center.y - radius),
            endPoint: CGPoint(x: center.x + radius * 0.6, y: center.y + radius * 0.6)), lineWidth: 1.5)

        guard morph >= 1 else { return }
        drawLabels(in: context, bounds: size, turns: turns, onGlobe: onGlobe)
        drawEvents(in: context, turns: turns, view: view, onGlobe: onGlobe, now: now, radius: radius)
    }

    /// Continents' names, and the grand names of supercontinents and oceans while they last.
    private func drawLabels(in context: GraphicsContext, bounds: CGSize, turns: [simd_quatd], onGlobe: (simd_double3) -> CGPoint) {
        var shown: [(String, simd_double3, Double, Bool)] = []
        for label in deepTime.labels {
            let presence = deepTime.presence(of: label, at: ma)
            guard presence > 0.02, turns.indices.contains(label.plate) else { continue }
            let v = turns[label.plate].act(DeepTime.unitVector(lon: label.location.x, lat: label.location.y))
            shown.append((label.name, v, presence, label.isGrand))
        }
        // Grand names first, then continents, each skipped where it would crowd one already set.
        var placed: [CGRect] = []
        for (name, v, presence, isGrand) in shown.sorted(by: { $0.3 && !$1.3 }) where v.x > 0.15 {
            let point = onGlobe(v)
            let text = context.resolve(Text(isGrand ? name.uppercased() : name)
                .font(.system(size: isGrand ? 13 : 11, weight: isGrand ? .semibold : .medium, design: .rounded))
                .tracking(isGrand ? 3 : 0.5)
                .foregroundStyle(.white.opacity(isGrand ? 0.92 : 0.8)))
            let size = text.measure(in: CGSize(width: 300, height: 40))
            // Kept on screen, so a name near the edge of the view isn't cut off.
            let x = min(max(point.x - size.width / 2, 6), bounds.width - size.width - 6)
            let box = CGRect(x: x, y: point.y - size.height / 2, width: size.width, height: size.height)
            guard !placed.contains(where: { $0.insetBy(dx: -4, dy: -2).intersects(box) }) else { continue }
            placed.append(box)
            var layer = context
            layer.opacity = presence * min((v.x - 0.15) / 0.25, 1)
            layer.addFilter(.shadow(color: .black.opacity(0.7), radius: 3))
            layer.draw(text, in: box)
        }
    }

    /// Marks for the moments of deep time near now: a glow where it happened, and for the asteroid,
    /// its fall, flash and shock wave.
    private func drawEvents(
        in context: GraphicsContext, turns: [simd_quatd], view: simd_quatd, onGlobe: (simd_double3) -> CGPoint,
        now: Date, radius: CGFloat
    ) {
        for event in deepTime.events {
            guard let location = event.location else { continue }
            let nearness = max(0, 1 - abs(event.ma - ma) / 6)
            guard nearness > 0 else { continue }
            let turn = event.plate.map { turns[$0] } ?? view
            let v = turn.act(DeepTime.unitVector(lon: location.x, lat: location.y))
            guard v.x > 0 else { continue }
            let point = onGlobe(v)
            let pulse = reduceMotion ? 0.5 : 0.5 + 0.5 * sin(now.timeIntervalSinceReferenceDate * 3)
            let color: Color = event.kind == .extinction ? .red : event.kind == .impact ? .orange : Color(red: 0.6, green: 0.9, blue: 1)
            let size = 10 + 8 * pulse
            context.fill(Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2)),
                         with: .radialGradient(Gradient(colors: [color.opacity(0.8 * nearness), .clear]),
                                               center: point, startRadius: 0, endRadius: size))
            if event.kind == .impact, let start = impact.start {
                let elapsed = now.timeIntervalSince(start)
                drawImpact(at: point, elapsed: elapsed, in: context, radius: radius)
            }
        }
    }

    /// The asteroid streaking in from the upper right, a white flash, and a ring racing outward.
    private func drawImpact(at point: CGPoint, elapsed: Double, in context: GraphicsContext, radius: CGFloat) {
        let fall = 0.55
        if elapsed < fall {
            let t = elapsed / fall
            let start = CGPoint(x: point.x + radius * 1.4, y: point.y - radius * 1.2)
            let head = CGPoint(x: start.x + (point.x - start.x) * t, y: start.y + (point.y - start.y) * t)
            let tail = CGPoint(x: start.x + (point.x - start.x) * max(t - 0.25, 0), y: start.y + (point.y - start.y) * max(t - 0.25, 0))
            var streak = Path()
            streak.move(to: tail)
            streak.addLine(to: head)
            context.stroke(streak, with: .linearGradient(Gradient(colors: [.clear, .orange, .white]), startPoint: tail, endPoint: head),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: head.x - 4, y: head.y - 4, width: 8, height: 8)), with: .color(.white))
            return
        }
        let after = elapsed - fall
        guard after < 2.2 else { return }
        let flash = max(0, 1 - after / 0.5)
        if flash > 0 {
            let size = radius * 0.5 * (0.4 + after)
            context.fill(Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2)),
                         with: .radialGradient(Gradient(colors: [.white.opacity(flash), Color.orange.opacity(0.6 * flash), .clear]),
                                               center: point, startRadius: 0, endRadius: size))
        }
        let ring = radius * 0.08 + radius * 0.6 * after / 2.2
        context.stroke(Path(ellipseIn: CGRect(x: point.x - ring, y: point.y - ring, width: ring * 2, height: ring * 2)),
                       with: .color(.orange.opacity(0.7 * (1 - after / 2.2))), lineWidth: 2)
    }

    /// Turns the globe so the point at a longitude and latitude, in degrees, faces the viewer.
    static func viewRotation(longitude: Double, latitude: Double) -> simd_quatd {
        let yaw = simd_quatd(angle: -longitude * .pi / 180, axis: simd_double3(0, 0, 1))
        let pitch = simd_quatd(angle: latitude * .pi / 180, axis: simd_double3(0, 1, 0))
        return pitch * yaw
    }
}

/// Watches the globe's age as drawn, frame by frame, to start the asteroid's strike the moment the
/// globe passes it, whether scrubbed or flown there.
final class ImpactClock {
    private(set) var start: Date?
    private var lastMa: Double?

    func notice(ma: Double, events: [DeepTime.Event], at date: Date, isShown: Bool) {
        defer { lastMa = ma }
        guard isShown, let lastMa, lastMa != ma else { return }
        for event in events where event.kind == .impact {
            if (lastMa < event.ma) != (ma < event.ma) || ma == event.ma { start = date }
        }
    }

    func isPlaying(at date: Date) -> Bool {
        guard let start else { return false }
        return date.timeIntervalSince(start) < 2.8
    }
}

/// Every unit's lighter rings as points on the unit sphere, worked out once, so turning the globe
/// is only a rotation per point.
struct GlobeMesh: Sendable {
    var vectors: [[[simd_double3]]]

    nonisolated init(atlas: TimeMachineAtlas) {
        vectors = atlas.units.map { unit in
            unit.lightRings.map { ring in ring.points.map { DeepTime.unitVector(lon: $0.x, lat: $0.y) } }
        }
    }
}

/// Which way the globe faces: where a turn by hand left it, gliding on after a flick and turning
/// slowly on its own, worked out from the time so nothing needs updating frame by frame.
struct GlobeSpin: Equatable {
    var longitude: Double = 15
    var latitude: Double = 12
    /// How fast it was turning when let go, in degrees a second.
    var velocity: Double = 0
    var since: Date = .distantPast
    /// Whether a finger holds it, so it stays where it's put.
    var isHeld = false

    /// How fast the globe turns on its own, in degrees a second.
    static let drift = 2.5

    /// Whether a flick is still carrying it round.
    func isGliding(at date: Date) -> Bool {
        abs(velocity) * exp(-2.2 * max(date.timeIntervalSince(since), 0)) > 0.5
    }

    func facing(at date: Date, reduceMotion: Bool) -> (longitude: Double, latitude: Double) {
        guard !isHeld else { return (longitude, latitude) }
        let elapsed = max(date.timeIntervalSince(since), 0)
        // A flick glides on, slowing like a wheel; then the globe turns slowly on its own, west to
        // east as the Earth does.
        let damping = 2.2
        let glide = velocity * (1 - exp(-damping * elapsed)) / damping
        let drifting = reduceMotion ? 0 : -Self.drift * elapsed
        return (longitude + glide + drifting, latitude)
    }
}
