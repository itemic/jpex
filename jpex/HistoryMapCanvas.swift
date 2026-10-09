import SwiftUI

/// The flat world partway between two eras. Colours flow from one power to the next, borders that
/// are going fade away, and new borders trace themselves in with a glow at the pen, while names
/// cross-fade. `position` runs through the eras: 3 is the fourth era, 3.5 halfway to the fifth.
/// Each era holds still for a little either side of its own mark, so a scrub reads as a series
/// of clean maps with changes between them.
///
/// It's drawn in layers, so a scrub only redraws what changes: the sea and its grid, and the
/// coasts, redraw only when the camera moves.
struct HistoryMapCanvas: View, Animatable {
    var atlas: TimeMachineAtlas
    var geometry: HistoryMapGeometry
    var blends: EraBlendCache
    var names: MapNameCache
    var position: Double
    var camera: HistoryCamera
    /// Turns the map toward old paper as the person pulls past the earliest era.
    var age: Double = 0

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<CGFloat, CGSize.AnimatableData>> {
        get { AnimatablePair(AnimatablePair(position, age), camera.animatableData) }
        set {
            position = newValue.first.first
            age = newValue.first.second
            camera.animatableData = newValue.second
        }
    }

    /// The two eras either side of a position, and how far from the first to the second the map
    /// has changed, holding still near each era's own mark.
    static func blend(at position: Double, eraCount: Int) -> (from: Int, to: Int, progress: Double) {
        let clamped = min(max(position, 0), Double(max(eraCount - 1, 0)))
        let from = Int(clamped.rounded(.down))
        let to = min(from + 1, max(eraCount - 1, 0))
        let fraction = clamped - Double(from)
        let held = min(max((fraction - 0.18) / 0.64, 0), 1)
        return (from, to, held * held * (3 - 2 * held))
    }

    var body: some View {
        let (from, to, t) = Self.blend(at: position, eraCount: geometry.styles.count)
        ZStack {
            HistorySea(geometry: geometry, camera: camera)
                .equatable()
            HistoryLand(atlas: atlas, geometry: geometry, blends: blends, from: from, to: to, progress: t,
                        camera: camera, age: age)
            HistoryCoasts(geometry: geometry, camera: camera)
                .equatable()
            HistoryNames(geometry: geometry, cache: names, from: from, to: to, progress: t, camera: camera)
        }
    }
}

/// The sea and its grid of latitude and longitude.
private struct HistorySea: View, Equatable {
    var geometry: HistoryMapGeometry
    var camera: HistoryCamera

    static func == (a: Self, b: Self) -> Bool { a.camera == b.camera && a.geometry.projection == b.geometry.projection }

    var body: some View {
        Canvas { context, size in
            let transform = geometry.transform(in: size, camera: camera)
            var map = context
            map.concatenate(transform)
            map.fill(geometry.outline, with: .linearGradient(
                Gradient(colors: [Color(red: 0.07, green: 0.12, blue: 0.24), Color(red: 0.03, green: 0.06, blue: 0.15)]),
                startPoint: CGPoint(x: geometry.bounds.midX, y: geometry.bounds.minY),
                endPoint: CGPoint(x: geometry.bounds.midX, y: geometry.bounds.maxY)))
            map.stroke(geometry.graticule, with: .color(.white.opacity(0.06)), lineWidth: 0.6 / max(transform.a, 0.0001))
        }
    }
}

/// Every coast, the same in every era.
private struct HistoryCoasts: View, Equatable {
    var geometry: HistoryMapGeometry
    var camera: HistoryCamera

    static func == (a: Self, b: Self) -> Bool { a.camera == b.camera && a.geometry.projection == b.geometry.projection }

    var body: some View {
        Canvas { context, size in
            let transform = geometry.transform(in: size, camera: camera)
            var map = context
            map.concatenate(transform)
            map.stroke(geometry.coasts, with: .color(.white.opacity(0.32)), lineWidth: 0.6 / max(transform.a, 0.0001))
        }
        .allowsHitTesting(false)
    }
}

/// The land, coloured by who held it, with the borders between them.
private struct HistoryLand: View {
    var atlas: TimeMachineAtlas
    var geometry: HistoryMapGeometry
    var blends: EraBlendCache
    var from: Int
    var to: Int
    var progress: Double
    var camera: HistoryCamera
    var age: Double

    var body: some View {
        Canvas { context, size in
            guard geometry.styles.indices.contains(from), geometry.styles.indices.contains(to) else { return }
            let transform = geometry.transform(in: size, camera: camera)
            let line = 1 / max(transform.a, 0.0001)
            let t = progress
            let blend = blends.blend(from: from, to: to, atlas: atlas, geometry: geometry)
            var map = context
            map.concatenate(transform)

            // Places that stay the same colour, then those changing hands, a group per change.
            for group in blend.steadyFills {
                map.fill(group.path, with: .color(Color(group.color)))
            }
            for group in blend.changingFills {
                map.fill(group.path, with: .color(Color(group.from.mixed(with: group.to, by: Float(t)))))
            }
            drawContested(in: &map, line: line, t: t)

            let dash = StrokeStyle(lineWidth: 0.5 * line, dash: [2 * line, 2 * line])
            map.stroke(blend.steadyInner, with: .color(.white.opacity(0.32)), style: dash)
            map.stroke(blend.steadyBorders, with: .color(.white.opacity(0.7)), lineWidth: 0.75 * line)
            if t < 1 {
                map.stroke(blend.fadingInner, with: .color(.white.opacity(0.32 * (1 - t))), style: dash)
                map.stroke(blend.fadingBorders, with: .color(.white.opacity(0.7 * (1 - t))), lineWidth: 0.75 * line)
            }
            if t > 0 {
                // New borders draw themselves in, glowing while the pen moves.
                var borders = Path()
                for index in blend.newBorders { borders.addPath(geometry.arcPaths[index].trimmedPath(from: 0, to: t)) }
                var inner = Path()
                for index in blend.newInner { inner.addPath(geometry.arcPaths[index].trimmedPath(from: 0, to: t)) }
                let glow = sin(t * .pi)
                if glow > 0.01 {
                    map.stroke(borders, with: .color(Color(red: 0.6, green: 0.9, blue: 1).opacity(0.5 * glow)), lineWidth: 3 * line)
                }
                map.stroke(borders, with: .color(.white.opacity(0.7)), lineWidth: 0.75 * line)
                map.stroke(inner, with: .color(.white.opacity(0.32)), style: dash)
            }
            if age > 0 {
                // Old paper creeping over the map as it's pulled back past its earliest era.
                map.fill(geometry.outline, with: .color(Color(red: 0.55, green: 0.42, blue: 0.25).opacity(0.45 * age)))
            }
        }
        .allowsHitTesting(false)
    }

    private func drawContested(in context: inout GraphicsContext, line: CGFloat, t: Double) {
        let pairs = [(geometry.styles[from].contested, 1 - t), (geometry.styles[to].contested, t)]
        for (path, opacity) in pairs where opacity > 0.01 && !path.isEmpty {
            var hatch = context
            hatch.clip(to: path)
            let box = path.boundingRect
            var lines = Path()
            let step = 4 * line
            var x = box.minX - box.height
            while x < box.maxX {
                lines.move(to: CGPoint(x: x, y: box.maxY))
                lines.addLine(to: CGPoint(x: x + box.height, y: box.minY))
                x += step
            }
            hatch.stroke(lines, with: .color(.white.opacity(0.35 * opacity)), lineWidth: 1 * line)
        }
    }
}

/// Names for places big enough on screen to hold them, cross-fading between eras. Where they go
/// is worked out once for each pair of eras and camera, then reused through a scrub.
private struct HistoryNames: View {
    var geometry: HistoryMapGeometry
    var cache: MapNameCache
    var from: Int
    var to: Int
    var progress: Double
    var camera: HistoryCamera

    var body: some View {
        Canvas { context, size in
            guard geometry.styles.indices.contains(from), geometry.styles.indices.contains(to) else { return }
            let transform = geometry.transform(in: size, camera: camera)
            let layout = cache.layout(from: from, to: to, size: size, camera: camera) {
                Self.place(geometry: geometry, from: from, to: to, transform: transform, size: size, context: context)
            }
            // Three layers, each with one shadow: names both eras share, and each era's own.
            let layers: [(names: [MapNameCache.Placed], opacity: Double)] = [
                (layout.filter { $0.era == .both }, 1),
                (layout.filter { $0.era == .from }, 1 - progress),
                (layout.filter { $0.era == .to }, progress),
            ]
            for layer in layers where layer.opacity > 0.01 && !layer.names.isEmpty {
                var names = context
                names.opacity = layer.opacity
                names.addFilter(.shadow(color: .black.opacity(0.6), radius: 2))
                for name in layer.names {
                    names.draw(Self.text(name.text, size: name.fontSize), in: name.box)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private static func text(_ string: String, size: CGFloat) -> Text {
        Text(string)
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.88))
    }

    /// Sets names for the two eras, largest first, skipping any that would crowd one already set.
    private static func place(
        geometry: HistoryMapGeometry, from: Int, to: Int, transform: CGAffineTransform, size: CGSize, context: GraphicsContext
    ) -> [MapNameCache.Placed] {
        let first = geometry.styles[from].names
        let second = from == to ? [] : geometry.styles[to].names
        let shared = Set(first).intersection(second)
        let scale = transform.a
        let visible = CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 8)
        var placed: [MapNameCache.Placed] = []
        func place(_ names: [EraStyle.MapName], era: MapNameCache.Era) {
            var boxes: [CGRect] = placed.filter { $0.era == .both || $0.era == era }.map(\.box)
            for name in names.prefix(80) {
                let screenArea = name.area * scale * scale
                guard screenArea > 2600 else { break }
                if era != .both, shared.contains(name) { continue }
                let point = name.anchor.applying(transform)
                guard visible.contains(point) else { continue }
                let fontSize = min(max((sqrt(screenArea) * 0.085).rounded(), 8), 13)
                let measured = context.resolve(text(name.text, size: fontSize)).measure(in: CGSize(width: 140, height: 40))
                let box = CGRect(x: point.x - measured.width / 2, y: point.y - measured.height / 2,
                                 width: measured.width, height: measured.height)
                guard measured.width < sqrt(screenArea) * 1.6,
                      !boxes.contains(where: { $0.insetBy(dx: -3, dy: -1).intersects(box) })
                else { continue }
                boxes.append(box)
                placed.append(MapNameCache.Placed(text: name.text, box: box, fontSize: fontSize, era: era))
            }
        }
        place(first.filter { shared.contains($0) }, era: .both)
        place(first, era: .from)
        place(second, era: .to)
        return placed
    }
}

/// Where names go for a pair of eras and a camera, kept while a scrub runs between them.
@MainActor
final class MapNameCache {
    enum Era { case both, from, to }

    struct Placed {
        var text: String
        var box: CGRect
        var fontSize: CGFloat
        var era: Era
    }

    private struct Key: Hashable {
        var from: Int
        var to: Int
        var width: Int
        var height: Int
        var scale: Int
        var x: Int
        var y: Int
    }

    private var layouts: [Key: [Placed]] = [:]

    func layout(from: Int, to: Int, size: CGSize, camera: HistoryCamera, make: () -> [Placed]) -> [Placed] {
        let key = Key(from: from, to: to, width: Int(size.width), height: Int(size.height),
                      scale: Int((camera.scale * 50).rounded()), x: Int(camera.offset.width.rounded()),
                      y: Int(camera.offset.height.rounded()))
        if let layout = layouts[key] { return layout }
        let layout = make()
        // A moving camera makes a new layout at every step; keep only the recent ones.
        if layouts.count > 24 { layouts.removeAll() }
        layouts[key] = layout
        return layout
    }
}

/// The work of drawing one era turning into another, done once per pair of eras: which places
/// keep their colour, which change and to what, and which borders stay, go or arrive.
struct EraBlend {
    var steadyFills: [(color: Color.Resolved, path: Path)]
    var changingFills: [(from: Color.Resolved, to: Color.Resolved, path: Path)]
    var steadyBorders: Path
    var steadyInner: Path
    var fadingBorders: Path
    var fadingInner: Path
    var newBorders: [Int]
    var newInner: [Int]
}

/// Keeps the blends already worked out, since a scrub crosses the same pairs again and again.
@MainActor
final class EraBlendCache {
    private var blends: [Int: EraBlend] = [:]

    private struct ColorChange: Hashable {
        var from: Color.Resolved
        var to: Color.Resolved
    }

    func blend(from: Int, to: Int, atlas: TimeMachineAtlas, geometry: HistoryMapGeometry) -> EraBlend {
        let key = from * 1000 + to
        if let blend = blends[key] { return blend }
        let first = geometry.styles[from]
        let second = geometry.styles[to]
        var steady: [Color.Resolved: Path] = [:]
        var changing: [ColorChange: Path] = [:]
        for index in first.fills.indices {
            let old = first.fills[index]
            let new = second.fills[index]
            if old == new {
                steady[old, default: Path()].addPath(geometry.unitPaths[index])
            } else {
                changing[ColorChange(from: old, to: new), default: Path()].addPath(geometry.unitPaths[index])
            }
        }
        var steadyBorders = Path(), steadyInner = Path(), fadingBorders = Path(), fadingInner = Path()
        var newBorders: [Int] = [], newInner: [Int] = []
        for index in first.arcKinds.indices {
            let old = first.arcKinds[index]
            let new = second.arcKinds[index]
            let path = geometry.arcPaths[index]
            if old == new {
                if old == .border { steadyBorders.addPath(path) }
                if old == .inner { steadyInner.addPath(path) }
                continue
            }
            if old == .border { fadingBorders.addPath(path) }
            if old == .inner { fadingInner.addPath(path) }
            if new == .border { newBorders.append(index) }
            if new == .inner { newInner.append(index) }
        }
        let blend = EraBlend(
            steadyFills: steady.map { (color: $0.key, path: $0.value) },
            changingFills: changing.map { (from: $0.key.from, to: $0.key.to, path: $0.value) },
            steadyBorders: steadyBorders, steadyInner: steadyInner,
            fadingBorders: fadingBorders, fadingInner: fadingInner, newBorders: newBorders, newInner: newInner)
        blends[key] = blend
        return blend
    }
}
