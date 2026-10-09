import SwiftUI

/// Time Machine's world flattened in one projection: every unit and border as a path in map
/// units, and how each era colours and divides them, ready to draw at every frame of a scrub.
struct HistoryMapGeometry: Sendable {
    var projection: MapProjection
    /// The edge of the world, and the area it covers.
    var outline: Path
    var bounds: CGRect
    /// The edge of the world as points, for morphing it into the globe's rim.
    var outlinePoints: [CGPoint]
    /// Lines of latitude and longitude every 30 degrees.
    var graticule: Path
    var unitPaths: [Path]
    var unitBounds: [CGRect]
    var unitAreas: [CGFloat]
    var unitLabels: [CGPoint]
    /// Each unit's lighter rings, projected point for point, for morphing into the globe.
    var unitLightPoints: [[[CGPoint]]]
    var arcPaths: [Path]
    /// Every coast, drawn the same in every era.
    var coasts: Path
    /// How each era colours and divides the map, in the atlas's order.
    var styles: [EraStyle]

    /// The projection Time Machine flattens the world in: the person's own, unless that's the
    /// globe, which Time Machine keeps for deep time.
    static var preferredProjection: MapProjection {
        let projection = MapProjection.current
        return projection == .globe ? .winkelTripel : projection
    }

    nonisolated init(atlas: TimeMachineAtlas, projection: MapProjection) {
        self.projection = projection
        let outlineRing = Self.outlineRing
        outlinePoints = outlineRing.map(projection.project)
        var outline = Path()
        outline.addRing(outlinePoints, closed: true)
        self.outline = outline
        bounds = outline.boundingRect
        var graticule = Path()
        for longitude in stride(from: -150.0, through: 150, by: 30) {
            graticule.addRing(stride(from: -90.0, through: 90, by: 3).map { projection.project(CGPoint(x: longitude, y: $0)) }, closed: false)
        }
        for latitude in stride(from: -60.0, through: 60, by: 30) {
            graticule.addRing(stride(from: -180.0, through: 180, by: 3).map { projection.project(CGPoint(x: $0, y: latitude)) }, closed: false)
        }
        self.graticule = graticule

        var paths: [Path] = []
        var lightPoints: [[[CGPoint]]] = []
        var areas: [CGFloat] = []
        for unit in atlas.units {
            var path = Path()
            var area: CGFloat = 0
            for ring in unit.rings {
                let points = ring.points.map(projection.project)
                path.addRing(points, closed: true)
                area += abs(Self.signedArea(of: points))
            }
            paths.append(path)
            areas.append(area)
            lightPoints.append(unit.lightRings.map { $0.points.map(projection.project) })
        }
        unitPaths = paths
        unitAreas = areas
        unitBounds = paths.map(\.boundingRect)
        unitLabels = atlas.units.map { projection.project($0.label) }
        unitLightPoints = lightPoints

        var arcPaths: [Path] = []
        var coasts = Path()
        for arc in atlas.arcs {
            var path = Path()
            path.addRing(arc.ring.points.map(projection.project), closed: arc.ring.isClosed)
            arcPaths.append(path)
            if arc.b == nil { coasts.addPath(path) }
        }
        self.arcPaths = arcPaths
        self.coasts = coasts

        styles = atlas.eras.indices.map { era in
            EraStyle(atlas: atlas, era: era, unitPaths: paths, unitAreas: areas,
                     unitLabels: atlas.units.map { projection.project($0.label) })
        }
    }

    /// How far past the sides of a narrow view the world may run, so it fills a tall card at a
    /// size worth looking at rather than shrinking to its width; it pans to show the rest.
    static let overflow: CGFloat = 1.5

    /// Fits the world into a view, centred, filling its height and running past its sides by up
    /// to `overflow` in a narrow view, then applies the camera's zoom and pan.
    func transform(in size: CGSize, camera: HistoryCamera, inset: CGFloat = 12) -> CGAffineTransform {
        guard bounds.width > 0, bounds.height > 0 else { return .identity }
        let fit = min((size.width - inset * 2) * Self.overflow / bounds.width, (size.height - inset * 2) / bounds.height)
        let scale = max(fit, 0.0001) * camera.scale
        return CGAffineTransform(
            a: scale, b: 0, c: 0, d: scale,
            tx: size.width / 2 + camera.offset.width - scale * bounds.midX,
            ty: size.height / 2 + camera.offset.height - scale * bounds.midY)
    }

    /// The unit drawn under a point on screen.
    func unit(at location: CGPoint, in size: CGSize, camera: HistoryCamera) -> Int? {
        let point = location.applying(transform(in: size, camera: camera).inverted())
        // Small places draw on top, so they're found first.
        let candidates = unitBounds.indices.filter { unitBounds[$0].contains(point) }
            .sorted { unitAreas[$0] < unitAreas[$1] }
        return candidates.first { unitPaths[$0].contains(point) }
    }

    /// The edge of the world, walked every two degrees so curved projections bend it smoothly.
    nonisolated static var outlineRing: [CGPoint] {
        var points: [CGPoint] = []
        for latitude in stride(from: -90.0, through: 90, by: 2) { points.append(CGPoint(x: -180, y: latitude)) }
        for longitude in stride(from: -178.0, through: 178, by: 2) { points.append(CGPoint(x: longitude, y: 90)) }
        for latitude in stride(from: 90.0, through: -90, by: -2) { points.append(CGPoint(x: 180, y: latitude)) }
        for longitude in stride(from: 178.0, through: -178, by: -2) { points.append(CGPoint(x: longitude, y: -90)) }
        return points
    }

    private nonisolated static func signedArea(of points: [CGPoint]) -> CGFloat {
        guard points.count > 2 else { return 0 }
        var sum: CGFloat = 0
        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            sum += a.x * b.y - b.x * a.y
        }
        return sum / 2
    }
}

/// Where the flat map's camera is: how far it has zoomed in, and how far it has moved, in points.
struct HistoryCamera: Equatable {
    var scale: CGFloat = 1
    var offset: CGSize = .zero

    static let whole = HistoryCamera()

    var animatableData: AnimatablePair<CGFloat, CGSize.AnimatableData> {
        get { AnimatablePair(scale, offset.animatableData) }
        set {
            scale = newValue.first
            offset.animatableData = newValue.second
        }
    }
}

/// How one era colours and divides the map.
struct EraStyle: Sendable {
    /// Each unit's fill.
    var fills: [Color.Resolved]
    /// What each arc is in this era: a border, a fine line inside one power, or nothing.
    var arcKinds: [ArcKind]
    /// Names to set on the map, largest first.
    var names: [MapName]
    /// Land held by one power and claimed by another, hatched over its fill.
    var contested: Path

    enum ArcKind: UInt8, Sendable {
        case none, inner, border, coast
    }

    /// A name for a place or power on the map, at a point inside its largest part.
    struct MapName: Sendable, Hashable {
        var text: String
        var anchor: CGPoint
        /// Its area in map units, to tell whether it's large enough to hold its name on screen.
        var area: CGFloat
    }

    nonisolated init(atlas: TimeMachineAtlas, era: Int, unitPaths: [Path], unitAreas: [CGFloat], unitLabels: [CGPoint]) {
        let placements = atlas.placements[era]
        let polities = placements.map { atlas.polity($0.polity) }
        fills = polities.map { atlas.color(of: $0).resolved }
        arcKinds = atlas.arcs.map { arc in
            guard let b = arc.b else { return .coast }
            let first = placements[arc.a]
            let second = placements[b]
            if first.polity != second.polity { return .border }
            if first.label != second.label, polities[arc.a].kind != .indigenous { return .inner }
            return .none
        }
        var contested = Path()
        for index in polities.indices where polities[index].kind == .contested {
            contested.addPath(unitPaths[index])
        }
        self.contested = contested

        // One name per place as it was then, at its largest part, such as "French West Africa".
        var groups: [String: (area: CGFloat, anchor: CGPoint, anchorArea: CGFloat, text: String)] = [:]
        for index in placements.indices {
            let placement = placements[index]
            let key = placement.polity + "|" + placement.label
            let area = unitAreas[index]
            var group = groups[key] ?? (0, unitLabels[index], 0, placement.label)
            group.area += area
            if area > group.anchorArea {
                group.anchorArea = area
                group.anchor = unitLabels[index]
            }
            groups[key] = group
        }
        names = groups.values
            .map { MapName(text: $0.text, anchor: $0.anchor, area: $0.area) }
            .sorted { $0.area > $1.area }
    }
}
