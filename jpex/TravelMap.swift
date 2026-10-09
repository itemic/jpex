import SwiftUI

/// A collection's map: projected outlines for each place, ready to draw.
/// Map files are bundled as `map_<collection id>.json`, with SVG path data per place.
/// The Countries map is projected on the device instead, in the projection the person chooses.
struct TravelMap: Sendable {
    var size: CGSize
    /// Largest first, so small places and enclaves draw on top.
    var regions: [MapRegion]
    /// Boxes around inset areas, such as Alaska or the French overseas departments.
    var frames: [CGRect]
    /// The edge of the world, for maps of the whole globe.
    var outline: Path?
    /// Lines of latitude and longitude every 30 degrees, for maps of the whole globe.
    var graticule: Path?
    /// Whether the map shows the Earth as a sphere, lit from the upper left.
    var isSphere = false
    /// Areas whose status is disputed, drawn hatched with soft edges rather than hard borders.
    var disputedAreas: [DisputedArea] = []
    /// Contested boundaries, such as Kashmir's Line of Control, drawn as soft lines.
    var disputedLines: [Path] = []
    /// The area to show instead of the whole map, as for a group of countries on the World map.
    var focusOverride: CGRect? = nil
    /// For a map projected on the device: its projection, and the longitude at its middle, so things
    /// given in longitude and latitude, such as the Sun's light, can be drawn over it. Nil for maps
    /// bundled ready-projected, and for one partway between projections.
    var projection: MapProjection? = nil
    var centerLongitude: Double? = nil

    func region(id: String) -> MapRegion? {
        regions.first { $0.id == id }
    }

    /// The area to fit on screen: the given places plus any inset boxes, with a little room around them.
    /// A map of the whole globe always shows the whole globe.
    func focusRect(including ids: some Collection<String>) -> CGRect {
        if let focusOverride { return focusOverride }
        if let outline {
            let rect = outline.boundingRect
            return rect.insetBy(dx: -rect.width * 0.015, dy: -rect.height * 0.015)
        }
        let wanted = Set(ids)
        let places = regions.filter { wanted.contains($0.id) }
        let rects = (places.isEmpty ? regions : places).map(\.bounds) + frames
        guard var rect = rects.first else { return CGRect(origin: .zero, size: size) }
        for other in rects.dropFirst() { rect = rect.union(other) }
        return rect.insetBy(dx: -rect.width * 0.03, dy: -rect.height * 0.03)
    }

    /// The part of the World map to show for a group of countries, such as the EU: around the main
    /// body of each member, or nil for the whole World when they're spread across most of it, or
    /// on the globe, which is always whole.
    func focus(onMembers members: Set<String>) -> CGRect? {
        guard !isSphere, let edge = outline?.boundingRect else { return nil }
        let bounds = regions.filter { members.contains($0.id) }.map(\.coreBounds)
        guard var rect = bounds.first else { return nil }
        for other in bounds.dropFirst() { rect = rect.union(other) }
        guard rect.width < edge.width * 0.75 else { return nil }
        let margin = max(rect.width, rect.height) * 0.08
        return rect.insetBy(dx: -margin, dy: -margin).intersection(edge)
    }

    /// The place drawn at a point, checking small places first because they sit on top.
    func hitTest(_ point: CGPoint, among ids: Set<String>) -> MapRegion? {
        regions.reversed().first { ids.contains($0.id) && $0.bounds.contains(point) && $0.path.contains(point, eoFill: true) }
    }

    /// The place under a point on screen. Places too small to see are drawn as dots, so they get
    /// a generous touch target.
    func place(at location: CGPoint, geometry: MapGeometry, among ids: Set<String>) -> MapRegion? {
        if let region = hitTest(geometry.toMap(location), among: ids) { return region }
        return regions
            .filter { ids.contains($0.id) }
            .map { region in
                let center = geometry.toScreen(region.center)
                return (region, hypot(center.x - location.x, center.y - location.y))
            }
            .filter { candidate, distance in
                let size = candidate.bounds.applying(geometry.transform)
                return distance < 22 && max(size.width, size.height) < 16
            }
            .min { $0.1 < $1.1 }?.0
    }
}

extension MapRegion {
    /// The main body of a place for flying the camera to it: its largest landmass plus the land
    /// near it, leaving out far-flung islands such as Hawaii or the Aleutians.
    var coreBounds: CGRect {
        var parts: [CGRect] = []
        var current: CGRect?
        path.forEach { element in
            switch element {
            case .move(let point):
                if let current { parts.append(current) }
                current = CGRect(origin: point, size: .zero)
            case .line(let point), .quadCurve(let point, _), .curve(let point, _, _):
                current = current?.union(CGRect(origin: point, size: .zero))
            case .closeSubpath:
                break
            }
        }
        if let current { parts.append(current) }
        guard var core = parts.max(by: { $0.width * $0.height < $1.width * $1.height }) else { return bounds }
        let mainArea = core.width * core.height
        // Large islands join when they sit within reach of the land gathered so far, so chains such
        // as Indonesia's join up; small ones only when they lie right beside it, such as Tasmania.
        let reach = hypot(core.width, core.height) * 0.6
        var remaining = parts.filter { $0 != core }
        var grew = true
        while grew {
            grew = false
            remaining.removeAll { part in
                let isLarge = part.width * part.height >= mainArea * 0.01
                let margin = isLarge ? reach : max(core.width, core.height) * 0.1
                guard gap(between: part, and: core) <= margin else { return false }
                core = core.union(part)
                grew = true
                return true
            }
        }
        return core
    }

    private func gap(between a: CGRect, and b: CGRect) -> CGFloat {
        let dx = max(0, max(a.minX - b.maxX, b.minX - a.maxX))
        let dy = max(0, max(a.minY - b.maxY, b.minY - a.maxY))
        return hypot(dx, dy)
    }
}

struct MapRegion: Identifiable, Sendable {
    let id: String
    var path: Path
    var bounds: CGRect
    /// A point inside the place for markers and ripples.
    var center: CGPoint
}

/// An area whose status is disputed, such as the Golan Heights or Aksai Chin.
struct DisputedArea: Identifiable, Sendable {
    let id: String
    var path: Path
    var bounds: CGRect
    var center: CGPoint
}

extension TravelMap {
    @MainActor private static var cache: [String: TravelMap] = [:]
    @MainActor private static var missing: Set<String> = []

    /// The bundled map for a collection, decoded once and kept in memory.
    /// The World comes in the given projection and centre, falling back to its bundled flat map.
    @MainActor static func named(
        _ collectionID: String, projection: MapProjection = .current, center: MapCenter = .current
    ) -> TravelMap? {
        if collectionID == CountryCatalog.world.id, let world = Geography.world?.map(projection, center: center) {
            return world
        }
        // A group of countries, such as the EU, is the World map zoomed to its members.
        if WorldGroup(collectionID: collectionID) != nil {
            let key = "\(collectionID)-\(projection.rawValue)-\(center.rawValue)"
            if let map = cache[key] { return map }
            guard var world = Geography.world?.map(projection, center: center),
                  let group = WorldGroup.collections.first(where: { $0.id == collectionID })
            else { return nil }
            world.focusOverride = world.focus(onMembers: Set(group.divisions.map(\.id)))
            cache[key] = world
            return world
        }
        if let map = cache[collectionID] { return map }
        guard !missing.contains(collectionID),
              // A reorganised country, such as Denmark from 2027, draws its newer map.
              let url = Bundle.main.url(
                  forResource: "map_\(PlaceReorganisation.mapResourceID(for: collectionID))", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(MapFile.self, from: data)
        else {
            missing.insert(collectionID)
            return nil
        }
        let labels = file.regions.compactMap { $0.c.count == 2 ? CGPoint(x: $0.c[0], y: $0.c[1]) : nil }
        let map = TravelMap(
            size: CGSize(width: file.width, height: file.height),
            regions: file.regions.map { region in
                var path = Path()
                for ring in Self.fillingLakes(in: Self.rings(fromSVG: region.d), labels: labels) {
                    path.addRing(ring.points, closed: ring.isClosed)
                }
                let bounds = path.boundingRect
                let center = region.c.count == 2
                    ? CGPoint(x: region.c[0], y: region.c[1])
                    : CGPoint(x: bounds.midX, y: bounds.midY)
                return MapRegion(id: region.id, path: path, bounds: bounds, center: center)
            },
            frames: (file.frames ?? []).compactMap { values in
                values.count == 4 ? CGRect(x: values[0], y: values[1], width: values[2], height: values[3]) : nil
            },
            disputedAreas: (file.disputed ?? []).map { area in
                let path = Self.path(fromSVG: area.d)
                let bounds = path.boundingRect
                let center = area.c?.count == 2 ? CGPoint(x: area.c![0], y: area.c![1]) : CGPoint(x: bounds.midX, y: bounds.midY)
                return DisputedArea(id: area.id, path: path, bounds: bounds, center: center)
            },
            disputedLines: (file.disputedLines ?? []).map { Self.path(fromSVG: $0.d) }
        )
        cache[collectionID] = map
        return map
    }

    /// Leaves out lakes: rings lying inside another ring of the same place, which would otherwise
    /// show as holes, such as Lake Eyre in Australia. A hole with another place drawn in it, such as
    /// Lesotho inside South Africa or Brussels inside Flemish Brabant, stays.
    static func fillingLakes(in rings: [MapRing], labels: [CGPoint]) -> [MapRing] {
        guard rings.count > 1 else { return rings }
        func bounds(of ring: MapRing) -> CGRect {
            var minX = CGFloat.infinity, minY = CGFloat.infinity, maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
            for point in ring.points {
                minX = min(minX, point.x); maxX = max(maxX, point.x)
                minY = min(minY, point.y); maxY = max(maxY, point.y)
            }
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        func path(of ring: MapRing) -> Path {
            var path = Path()
            path.addRing(ring.points, closed: true)
            return path
        }
        let boxes = rings.map(bounds(of:))
        let largestFirst = rings.indices.sorted { boxes[$0].width * boxes[$0].height > boxes[$1].width * boxes[$1].height }
        var outlines: [(box: CGRect, path: Path)] = []
        var kept = Set<Int>()
        for index in largestFirst {
            let ring = rings[index]
            let box = boxes[index]
            guard ring.isClosed, let point = ring.points.first else {
                kept.insert(index)
                continue
            }
            let isInside = outlines.contains { $0.box.contains(box) && $0.path.contains(point) }
            if !isInside {
                kept.insert(index)
                outlines.append((box, path(of: ring)))
            } else {
                let hole = path(of: ring)
                if labels.contains(where: { box.contains($0) && hole.contains($0) }) { kept.insert(index) }
            }
        }
        return rings.indices.filter(kept.contains).map { rings[$0] }
    }

    /// Parses SVG path data that uses absolute `M`, `L` and `Z` commands.
    static func path(fromSVG data: String) -> Path {
        var path = Path()
        for ring in rings(fromSVG: data) {
            path.addRing(ring.points, closed: ring.isClosed)
        }
        return path
    }

    /// The point lists in SVG path data that uses absolute `M`, `L` and `Z` commands.
    /// Reads the bytes directly, since map files hold tens of thousands of numbers.
    static func rings(fromSVG data: String) -> [MapRing] {
        var rings: [MapRing] = []
        var current = MapRing()
        var pendingX: Double?
        var value = 0.0
        var divisor = 1.0
        var isNegative = false
        var isFraction = false
        var hasDigits = false

        func flushNumber() {
            guard hasDigits else {
                isNegative = false
                isFraction = false
                return
            }
            let number = isNegative ? -value : value
            if let x = pendingX {
                current.points.append(CGPoint(x: x, y: number))
                pendingX = nil
            } else {
                pendingX = number
            }
            value = 0
            divisor = 1
            isNegative = false
            isFraction = false
            hasDigits = false
        }

        func finishRing(closed: Bool) {
            if !current.points.isEmpty {
                current.isClosed = closed
                rings.append(current)
            }
            current = MapRing()
        }

        for byte in data.utf8 {
            switch byte {
            case UInt8(ascii: "0")...UInt8(ascii: "9"):
                let digit = Double(byte - UInt8(ascii: "0"))
                if isFraction {
                    divisor *= 10
                    value += digit / divisor
                } else {
                    value = value * 10 + digit
                }
                hasDigits = true
            case UInt8(ascii: "."):
                isFraction = true
            case UInt8(ascii: "-"):
                flushNumber()
                isNegative = true
            case UInt8(ascii: "M"), UInt8(ascii: "m"):
                flushNumber()
                finishRing(closed: false)
            case UInt8(ascii: "Z"), UInt8(ascii: "z"):
                flushNumber()
                finishRing(closed: true)
            default:
                // L, spaces and commas all end a number.
                flushNumber()
            }
        }
        flushNumber()
        finishRing(closed: false)
        return rings
    }
}

/// One run of points in a shape: a closed ring of an outline, or an open line.
struct MapRing: Sendable {
    var points: [CGPoint] = []
    var isClosed = false
}

extension Path {
    mutating func addRing(_ points: some Collection<CGPoint>, closed: Bool) {
        guard let first = points.first else { return }
        move(to: first)
        for point in points.dropFirst() { addLine(to: point) }
        if closed { closeSubpath() }
    }
}

private struct MapFile: Decodable {
    var width: Double
    var height: Double
    var regions: [RegionFile]
    var frames: [[Double]]?
    var disputed: [OverlayFile]?
    var disputedLines: [OverlayFile]?

    struct RegionFile: Decodable {
        var id: String
        var d: String
        var c: [Double]
    }

    struct OverlayFile: Decodable {
        var id: String
        var d: String
        var c: [Double]?
    }
}
