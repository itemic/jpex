import SwiftUI

/// Outlines in longitude and latitude, bundled as `geo_<ID>.json` — the world's countries, or one
/// country's subdivisions — and projected on the device in the person's projection and centre.
/// Every projection of a centre moves the same points, so one projection can morph into another.
@MainActor
final class Geography {
    /// The world's countries, with the globe's outline and lines of latitude and longitude.
    static let world = Geography(named: "geo_WORLD", isGlobe: true)

    private static var subdivisionCache: [String: Geography] = [:]
    private static var missing: Set<String> = []

    /// A country's subdivisions, such as Japan's prefectures, to draw over the World map.
    static func subdivisions(of collectionID: String) -> Geography? {
        if let geography = subdivisionCache[collectionID] { return geography }
        guard !missing.contains(collectionID),
              let geography = Geography(named: "geo_\(PlaceReorganisation.mapResourceID(for: collectionID))", isGlobe: false)
        else {
            missing.insert(collectionID)
            return nil
        }
        subdivisionCache[collectionID] = geography
        return geography
    }

    private let source: GeoSource
    private let isGlobe: Bool
    private var shapes: [MapCenter: GeoShapes] = [:]
    private var projectedPoints: [Key: [CGPoint]] = [:]
    private var maps: [Key: TravelMap] = [:]

    private struct Key: Hashable {
        var projection: MapProjection
        var center: MapCenter
    }

    private init?(named resource: String, isGlobe: Bool) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(GeoFile.self, from: data)
        else { return nil }
        source = GeoSource(file: file)
        self.isGlobe = isGlobe
    }

    /// The outlines in a projection and centre, projected once and kept.
    func map(_ projection: MapProjection, center: MapCenter) -> TravelMap {
        let key = Key(projection: projection, center: center)
        if let map = maps[key] { return map }
        let shapes = shapes(centeredOn: center)
        var map = shapes.map(points: points(in: projection, center: center), visible: visibility(in: projection, shapes: shapes))
        map.isSphere = projection == .globe
        map.projection = projection
        map.centerLongitude = center.longitude
        maps[key] = map
        return map
    }

    /// The outlines partway from one projection to another, each point gliding in a straight line.
    func map(from start: MapProjection, to end: MapProjection, progress: Double, center: MapCenter) -> TravelMap {
        let from = points(in: start, center: center)
        let to = points(in: end, center: center)
        let t = CGFloat(min(max(progress, 0), 1))
        var blended = from
        for index in blended.indices {
            blended[index].x += (to[index].x - from[index].x) * t
            blended[index].y += (to[index].y - from[index].y) * t
        }
        let shapes = shapes(centeredOn: center)
        var map = shapes.map(points: blended, visible: visibility(in: t < 0.5 ? start : end, shapes: shapes))
        map.isSphere = (start == .globe && t < 0.5) || (end == .globe && t >= 0.5)
        return map
    }

    /// The World turning to a new centre, cut afresh at every step. Uses lighter outlines so it
    /// can redraw at every frame.
    func turningMap(_ projection: MapProjection, centerLongitude: Double) -> TravelMap {
        let shapes = GeoShapes(source: lightSource, centerLongitude: centerLongitude, isGlobe: isGlobe)
        var points = shapes.geographic.map(projection.project)
        Self.shapeOutline(of: shapes, projection: projection, into: &points)
        var map = shapes.map(points: points, visible: visibility(in: projection, shapes: shapes))
        map.isSphere = projection == .globe
        map.projection = projection
        map.centerLongitude = centerLongitude
        return map
    }

    /// The outlines in full detail centred on any longitude, such as a globe turned by hand.
    /// The most recent few are kept, so flying in and out of a turned globe doesn't rebuild them.
    func map(_ projection: MapProjection, centerLongitude: Double) -> TravelMap {
        let key = TurnedKey(projection: projection, tenthsOfDegree: Int((centerLongitude * 10).rounded()))
        if let map = turnedMaps.first(where: { $0.key == key })?.map { return map }
        let shapes = GeoShapes(source: source, centerLongitude: centerLongitude, isGlobe: isGlobe)
        var points = shapes.geographic.map(projection.project)
        Self.shapeOutline(of: shapes, projection: projection, into: &points)
        var map = shapes.map(points: points, visible: visibility(in: projection, shapes: shapes))
        map.isSphere = projection == .globe
        map.projection = projection
        map.centerLongitude = centerLongitude
        turnedMaps = Array((turnedMaps + [(key, map)]).suffix(4))
        return map
    }

    private struct TurnedKey: Hashable {
        var projection: MapProjection
        var tenthsOfDegree: Int
    }

    private var turnedMaps: [(key: TurnedKey, map: TravelMap)] = []

    /// The outlines with every other point, for drawing while the map turns.
    private lazy var lightSource = source.thinned()

    /// Which points face the viewer, for projections with a far side.
    private func visibility(in projection: MapProjection, shapes: GeoShapes) -> [Bool]? {
        projection == .globe ? shapes.geographic.map(projection.isVisible) : nil
    }

    /// Mercator's outline becomes a rounded card and the globe's a circle, with the same number of
    /// points as every other projection's outline so they still morph into one another.
    private static func shapeOutline(of shapes: GeoShapes, projection: MapProjection, into points: inout [CGPoint]) {
        guard let range = shapes.outline?.rings.first?.range, !range.isEmpty else { return }
        switch projection {
        case .globe:
            for (offset, index) in range.enumerated() {
                let angle = 0.75 * Double.pi + 2 * Double.pi * Double(offset) / Double(range.count)
                points[index] = CGPoint(x: cos(angle), y: sin(angle))
            }
        case .mercator:
            let top = MapProjection.mercator.project(CGPoint(x: 0, y: MapProjection.mercatorLatitudes.north)).y
            let bottom = MapProjection.mercator.project(CGPoint(x: 0, y: MapProjection.mercatorLatitudes.south)).y
            let rect = CGRect(x: -Double.pi, y: top, width: 2 * Double.pi, height: bottom - top)
            let card = roundedRectPoints(in: rect, radius: rect.height * 0.07, count: range.count)
            for (offset, index) in range.enumerated() { points[index] = card[offset] }
        default:
            break
        }
    }

    /// Points evenly spaced around a rounded rectangle, clockwise from the bottom of its left side.
    private static func roundedRectPoints(in rect: CGRect, radius r: CGFloat, count: Int) -> [CGPoint] {
        let straightWidth = rect.width - 2 * r
        let straightHeight = rect.height - 2 * r
        let arc = CGFloat.pi / 2 * r
        let segments: [(length: CGFloat, point: (CGFloat) -> CGPoint)] = [
            (straightHeight, { CGPoint(x: rect.minX, y: rect.maxY - r - $0) }),
            (arc, { arcPoint(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, from: .pi, fraction: $0 / arc) }),
            (straightWidth, { CGPoint(x: rect.minX + r + $0, y: rect.minY) }),
            (arc, { arcPoint(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, from: 1.5 * .pi, fraction: $0 / arc) }),
            (straightHeight, { CGPoint(x: rect.maxX, y: rect.minY + r + $0) }),
            (arc, { arcPoint(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, from: 0, fraction: $0 / arc) }),
            (straightWidth, { CGPoint(x: rect.maxX - r - $0, y: rect.maxY) }),
            (arc, { arcPoint(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, from: 0.5 * .pi, fraction: $0 / arc) }),
        ]
        let total = segments.reduce(0) { $0 + $1.length }
        return (0..<count).map { index in
            var distance = total * CGFloat(index) / CGFloat(count)
            for segment in segments {
                if distance <= segment.length { return segment.point(distance) }
                distance -= segment.length
            }
            return segments[0].point(0)
        }
    }

    private static func arcPoint(center: CGPoint, radius: CGFloat, from start: CGFloat, fraction: CGFloat) -> CGPoint {
        let angle = start + fraction * .pi / 2
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    private func shapes(centeredOn center: MapCenter) -> GeoShapes {
        if let shapes = shapes[center] { return shapes }
        let built = GeoShapes(source: source, centerLongitude: center.longitude, isGlobe: isGlobe)
        shapes[center] = built
        return built
    }

    private func points(in projection: MapProjection, center: MapCenter) -> [CGPoint] {
        let key = Key(projection: projection, center: center)
        if let points = projectedPoints[key] { return points }
        let shapes = shapes(centeredOn: center)
        var points = shapes.geographic.map(projection.project)
        Self.shapeOutline(of: shapes, projection: projection, into: &points)
        projectedPoints[key] = points
        return points
    }
}

/// A geography file's outlines, read once.
private struct GeoSource {
    struct Feature {
        var id: String
        var rings: [MapRing]
        var label: CGPoint?
    }

    var regions: [Feature]
    var disputedAreas: [Feature]
    var disputedLines: [Feature]

    /// A copy keeping every other point of longer rings, for drawing while the map turns.
    func thinned() -> GeoSource {
        func thin(_ feature: Feature) -> Feature {
            var thinned = feature
            thinned.rings = feature.rings.map { ring in
                guard ring.points.count > 16 else { return ring }
                var points = stride(from: 0, to: ring.points.count, by: 2).map { ring.points[$0] }
                if !ring.isClosed, let last = ring.points.last, points.last != last { points.append(last) }
                return MapRing(points: points, isClosed: ring.isClosed)
            }
            return thinned
        }
        var copy = self
        copy.regions = regions.map(thin)
        copy.disputedAreas = disputedAreas.map(thin)
        copy.disputedLines = disputedLines.map(thin)
        return copy
    }

    init(file: GeoFile) {
        func label(of item: GeoFile.Feature) -> CGPoint? {
            item.c.flatMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
        }
        func feature(_ item: GeoFile.Feature) -> Feature {
            Feature(id: item.id, rings: TravelMap.rings(fromSVG: item.d), label: label(of: item))
        }
        // Lakes inside a place are filled in rather than shown as holes.
        let labels = file.regions.compactMap(label(of:))
        regions = file.regions.map { item in
            Feature(id: item.id, rings: TravelMap.fillingLakes(in: TravelMap.rings(fromSVG: item.d), labels: labels), label: label(of: item))
        }
        disputedAreas = (file.disputed ?? []).map(feature)
        disputedLines = (file.disputedLines ?? []).map(feature)
    }
}

/// Every outline for one centre in one run of points, so projecting is one pass over it.
private struct GeoShapes {
    struct Shape {
        var id: String
        var rings: [RingRange]
        var label: Int?
    }

    struct RingRange {
        var range: Range<Int>
        var isClosed: Bool
    }

    var geographic: [CGPoint]
    var regions: [Shape]
    var disputedAreas: [Shape]
    var disputedLines: [Shape]
    var outline: Shape?
    var graticule: Shape?

    init(source: GeoSource, centerLongitude center: Double, isGlobe: Bool) {
        var points: [CGPoint] = []
        func add(_ id: String, rings: [MapRing], label: CGPoint? = nil) -> Shape {
            var ranges: [RingRange] = []
            for ring in rings {
                let start = points.count
                points.append(contentsOf: ring.points)
                ranges.append(RingRange(range: start..<points.count, isClosed: ring.isClosed))
            }
            var labelIndex: Int?
            if let label {
                labelIndex = points.count
                points.append(label)
            }
            return Shape(id: id, rings: ranges, label: labelIndex)
        }
        func addFeature(_ feature: GeoSource.Feature) -> Shape {
            add(
                feature.id,
                rings: feature.rings.flatMap { Self.recentered($0, on: center) },
                label: feature.label.map { Self.recentered($0, on: center) })
        }
        regions = source.regions.map(addFeature)
        disputedAreas = source.disputedAreas.map(addFeature)
        disputedLines = source.disputedLines.map(addFeature)
        outline = isGlobe ? add("outline", rings: [Self.outlineRing]) : nil
        graticule = isGlobe ? add("graticule", rings: Self.graticuleLines(center: center)) : nil
        geographic = points
    }

    /// Builds a drawable map from these outlines' points, projected or partway between projections.
    /// With `visible`, shapes wholly on the far side of the globe are left out.
    func map(points: [CGPoint], visible: [Bool]? = nil) -> TravelMap {
        func faces(_ ring: RingRange) -> Bool {
            guard let visible else { return true }
            return ring.range.contains { visible[$0] }
        }
        func isShown(_ shape: Shape) -> Bool {
            shape.rings.contains(where: faces)
        }
        func path(of shape: Shape) -> Path {
            var path = Path()
            for ring in shape.rings where shape.id == "outline" || faces(ring) {
                path.addRing(points[ring.range], closed: ring.isClosed)
            }
            return path
        }
        func region(_ shape: Shape) -> MapRegion {
            let path = path(of: shape)
            let bounds = path.boundingRect
            let center = shape.label.map { points[$0] } ?? CGPoint(x: bounds.midX, y: bounds.midY)
            return MapRegion(id: shape.id, path: path, bounds: bounds, center: center)
        }
        let regions = regions.filter(isShown).map(region)
        let outlinePath = outline.map(path(of:))
        let extent = outlinePath?.boundingRect
            ?? regions.map(\.bounds).reduce(CGRect.null) { $0.union($1) }
        return TravelMap(
            size: extent.isNull ? .zero : extent.size,
            regions: regions,
            frames: [],
            outline: outlinePath,
            graticule: graticule.map(path(of:)),
            disputedAreas: disputedAreas.filter(isShown).map { shape in
                let region = region(shape)
                return DisputedArea(id: region.id, path: region.path, bounds: region.bounds, center: region.center)
            },
            disputedLines: disputedLines.filter(isShown).map(path(of:))
        )
    }

    // MARK: Recentring

    /// Moves a ring so the centre longitude sits in the middle of the map, splitting it where it
    /// crosses the map's new edge and wrapping the far part around to the other side.
    static func recentered(_ ring: MapRing, on center: Double) -> [MapRing] {
        guard center != 0, !ring.points.isEmpty else { return [ring] }
        let shifted = ring.points.map { CGPoint(x: $0.x - center, y: $0.y) }
        // Shifted longitudes run from -180 - centre to 180 - centre; what lies past the edge on
        // one side belongs on the other.
        let edge: CGFloat = center > 0 ? -180 : 180
        let wrap: CGFloat = center > 0 ? 360 : -360
        let isOnMap: (CGFloat) -> Bool = center > 0 ? { $0 >= edge } : { $0 <= edge }
        func wrapped(_ points: [CGPoint]) -> [CGPoint] { points.map { CGPoint(x: $0.x + wrap, y: $0.y) } }

        if shifted.allSatisfy({ isOnMap($0.x) }) { return [MapRing(points: shifted, isClosed: ring.isClosed)] }
        if !shifted.contains(where: { isOnMap($0.x) && $0.x != edge }) {
            return [MapRing(points: wrapped(shifted), isClosed: ring.isClosed)]
        }
        guard ring.isClosed else { return splitLine(shifted, at: edge, isOnMap: isOnMap, wrapping: wrapped) }
        let near = clipped(shifted, at: edge, keeping: isOnMap)
        let far = wrapped(clipped(shifted, at: edge, keeping: { !isOnMap($0) }))
        return [near, far]
            .filter { $0.count > 2 }
            .map { MapRing(points: densified($0, isClosed: true), isClosed: true) }
    }

    static func recentered(_ point: CGPoint, on center: Double) -> CGPoint {
        var longitude = point.x - center
        if longitude < -180 { longitude += 360 }
        if longitude > 180 { longitude -= 360 }
        return CGPoint(x: longitude, y: point.y)
    }

    /// The part of a polygon on one side of a meridian (Sutherland–Hodgman).
    private static func clipped(_ points: [CGPoint], at x: CGFloat, keeping keep: (CGFloat) -> Bool) -> [CGPoint] {
        var output: [CGPoint] = []
        var previous = points[points.count - 1]
        var previousKept = keep(previous.x)
        for point in points {
            let kept = keep(point.x)
            if kept != previousKept { output.append(crossing(previous, point, at: x)) }
            if kept { output.append(point) }
            previous = point
            previousKept = kept
        }
        return output
    }

    /// An open line cut into pieces where it crosses a meridian, the far pieces wrapped around.
    private static func splitLine(
        _ points: [CGPoint], at x: CGFloat, isOnMap: (CGFloat) -> Bool, wrapping wrapped: ([CGPoint]) -> [CGPoint]
    ) -> [MapRing] {
        var pieces: [MapRing] = []
        var current = [points[0]]
        var currentOnMap = isOnMap(points[0].x)
        for point in points.dropFirst() {
            let onMap = isOnMap(point.x)
            if onMap != currentOnMap, let last = current.last {
                let cut = crossing(last, point, at: x)
                current.append(cut)
                pieces.append(MapRing(points: currentOnMap ? current : wrapped(current)))
                current = [cut]
                currentOnMap = onMap
            }
            current.append(point)
        }
        pieces.append(MapRing(points: currentOnMap ? current : wrapped(current)))
        return pieces.filter { $0.points.count > 1 }
    }

    private static func crossing(_ a: CGPoint, _ b: CGPoint, at x: CGFloat) -> CGPoint {
        let t = (x - a.x) / (b.x - a.x)
        return CGPoint(x: x, y: a.y + (b.y - a.y) * t)
    }

    /// Adds points along edges longer than a degree, such as a cut along the map's edge, so curved
    /// projections bend them.
    private static func densified(_ points: [CGPoint], isClosed: Bool) -> [CGPoint] {
        var output: [CGPoint] = []
        output.reserveCapacity(points.count)
        let count = isClosed ? points.count : points.count - 1
        for index in 0..<count {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            output.append(a)
            let steps = Int((max(abs(b.x - a.x), abs(b.y - a.y))).rounded(.up))
            if steps > 1 {
                for step in 1..<steps {
                    let t = CGFloat(step) / CGFloat(steps)
                    output.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
                }
            }
        }
        if !isClosed, let last = points.last { output.append(last) }
        return output
    }

    // MARK: Globe

    /// The edge of the world, walked every two degrees so curved projections bend it smoothly.
    private static var outlineRing: MapRing {
        var points: [CGPoint] = []
        for latitude in stride(from: -90.0, through: 90, by: 2) { points.append(CGPoint(x: -180, y: latitude)) }
        for longitude in stride(from: -178.0, through: 178, by: 2) { points.append(CGPoint(x: longitude, y: 90)) }
        for latitude in stride(from: 90.0, through: -90, by: -2) { points.append(CGPoint(x: 180, y: latitude)) }
        for longitude in stride(from: 178.0, through: -178, by: -2) { points.append(CGPoint(x: longitude, y: -90)) }
        return MapRing(points: points, isClosed: true)
    }

    /// Meridians and parallels every 30 degrees, the meridians where they fall for this centre.
    private static func graticuleLines(center: Double) -> [MapRing] {
        let meridians = stride(from: -150.0, through: 180, by: 30).compactMap { longitude -> MapRing? in
            let x = recentered(CGPoint(x: longitude, y: 0), on: center).x
            guard abs(x) < 179.5 else { return nil }
            return MapRing(points: stride(from: -90.0, through: 90, by: 2).map { CGPoint(x: x, y: $0) })
        }
        let parallels = stride(from: -60.0, through: 60, by: 30).map { latitude in
            MapRing(points: stride(from: -180.0, through: 180, by: 2).map { CGPoint(x: $0, y: latitude) })
        }
        return meridians + parallels
    }
}

private struct GeoFile: Decodable {
    var regions: [Feature]
    var disputed: [Feature]?
    var disputedLines: [Feature]?

    struct Feature: Decodable {
        var id: String
        var d: String
        var c: [Double]?
    }
}
