import SwiftUI

/// The sea's time zones, for World Time's time zone colours. Each stretch of sea wears the time of
/// the nearest land, so the zones run out from the coasts and meet in the open ocean, bending round
/// islands as the date line bends round Kiribati and Samoa, rather than running in tidy bands from
/// pole to pole; beyond the reach of any land, it keeps the nautical zone of its fifteen degrees of
/// longitude, as ships do on the high seas. Worked out once for each map, away from the main thread,
/// as a raster the map tints its sea with.
struct SeaZoneField: Sendable {
    /// How the raster's pixels stand to longitude, for the nautical zones of the open sea.
    enum Longitudes: Sendable {
        /// Across, as on a flat map: the longitude at the raster's left edge, and degrees per pixel.
        case across(west: Double, degreesPerPixel: Double)
        /// Round the middle, as on the dial: the longitude of points along the map's x axis, in
        /// degrees, and whether longitude grows with the angle or against it.
        case around(atZero: Double, turn: Double)
    }

    var width: Int
    var height: Int
    /// The places and subdivisions the land is, by ID, which the raster refers to from 1.
    var keys: [String]
    /// For each pixel, row by row from the top: the land it is or keeps the time of, from 1, or 0
    /// for the open sea; and whether it's land itself.
    private var nearest: [UInt16]
    private var isLand: [Bool]
    /// For each pixel, its nautical zone, in hours from UTC.
    private var nautical: [Int8]
    /// Every border on land between two of the lands, traced along one of their outlines, for
    /// drawing those between lands keeping different times.
    private var borders: [LandBorder] = []

    /// A stretch of border on land between two of the lands, by their places in `keys`, in the
    /// map's units.
    struct LandBorder: Sendable {
        var first: Int
        var second: Int
        var path: Path
    }

    /// Works out the field from the land's outlines in the map's units: `bounds` is the part of the
    /// map the raster covers, `reach` how far land's time carries out to sea, in pixels, and `wraps`
    /// whether the raster's sides meet, as a flat map's do round the back of the World.
    nonisolated static func make(
        lands: [(key: String, path: Path)], bounds: CGRect, width: Int, height: Int, longitudes: Longitudes,
        reach: Int, wraps: Bool
    ) -> SeaZoneField {
        let count = width * height
        // Each land filled in its own colour, its index, without smoothing, so every pixel says
        // exactly which land it is.
        var bytes = [UInt8](repeating: 0, count: count * 4)
        bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return }
            context.setShouldAntialias(false)
            context.setAllowsAntialiasing(false)
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: CGFloat(width) / bounds.width, y: -CGFloat(height) / bounds.height)
            context.translateBy(x: -bounds.minX, y: -bounds.minY)
            for (index, land) in lands.enumerated() {
                let number = index + 1
                context.setFillColor(red: CGFloat(number & 0xFF) / 255, green: CGFloat(number >> 8 & 0xFF) / 255, blue: 0, alpha: 1)
                context.addPath(land.path.cgPath)
                context.fillPath(using: .evenOdd)
            }
        }
        var landIndex = [UInt16](repeating: 0, count: count)
        var isLand = [Bool](repeating: false, count: count)
        for pixel in 0..<count where bytes[pixel * 4 + 3] > 0 {
            landIndex[pixel] = UInt16(bytes[pixel * 4]) | UInt16(bytes[pixel * 4 + 1]) << 8
            isLand[pixel] = true
        }

        // Out from every shore at once, each sea pixel taking the nearest land's time, as far as `reach`.
        var source = [Int32](repeating: -1, count: count)
        var best = [Int32](repeating: .max, count: count)
        var queue: [Int32] = []
        queue.reserveCapacity(count)
        for pixel in 0..<count where isLand[pixel] {
            source[pixel] = Int32(pixel)
            best[pixel] = 0
            queue.append(Int32(pixel))
        }
        let limit = Int32(reach * reach)
        var head = 0
        while head < queue.count {
            let pixel = Int(queue[head])
            head += 1
            let from = Int(source[pixel])
            let (fromX, fromY) = (from % width, from / width)
            let (x, y) = (pixel % width, pixel / width)
            for dy in -1...1 {
                let ny = y + dy
                guard ny >= 0, ny < height else { continue }
                for dx in -1...1 where dx != 0 || dy != 0 {
                    var nx = x + dx
                    if nx < 0 || nx >= width {
                        guard wraps else { continue }
                        nx = (nx + width) % width
                    }
                    let next = ny * width + nx
                    guard !isLand[next] else { continue }
                    var across = abs(nx - fromX)
                    if wraps { across = min(across, width - across) }
                    let down = ny - fromY
                    let distance = Int32(across * across + down * down)
                    guard distance <= limit, distance < best[next] else { continue }
                    best[next] = distance
                    source[next] = Int32(from)
                    queue.append(Int32(next))
                }
            }
        }

        var nearest = [UInt16](repeating: 0, count: count)
        var nautical = [Int8](repeating: 0, count: count)
        for pixel in 0..<count {
            if source[pixel] >= 0 { nearest[pixel] = landIndex[Int(source[pixel])] }
            let (x, y) = (pixel % width, pixel / width)
            let longitude: Double
            switch longitudes {
            case let .across(west, degreesPerPixel):
                longitude = west + (Double(x) + 0.5) * degreesPerPixel
            case let .around(atZero, turn):
                let mapX = bounds.minX + (CGFloat(x) + 0.5) * bounds.width / CGFloat(width)
                let mapY = bounds.minY + (CGFloat(y) + 0.5) * bounds.height / CGFloat(height)
                longitude = atZero + turn * atan2(Double(mapY), Double(mapX)) * 180 / .pi
            }
            var normal = (longitude + 180).truncatingRemainder(dividingBy: 360)
            if normal < 0 { normal += 360 }
            nautical[pixel] = Int8(((normal - 180) / 15).rounded())
        }
        let borders = landBorders(
            lands: lands, landIndex: landIndex, isLand: isLand, bounds: bounds, width: width, height: height, wraps: wraps)
        return SeaZoneField(
            width: width, height: height, keys: lands.map(\.key), nearest: nearest, isLand: isLand, nautical: nautical,
            borders: borders)
    }

    /// Every border on land between two lands, found by walking each land's outline and looking a
    /// pixel or so to either side of it in the raster: where another land lies across the line,
    /// it's a border. Each border is traced along one of the two outlines only, so it's drawn once,
    /// crisply, in the outline's own detail, even where two sets of outlines don't quite meet, as
    /// a country's provinces and its neighbour's may not. A country split into its subdivisions is
    /// traced along theirs rather than its own outline.
    nonisolated private static func landBorders(
        lands: [(key: String, path: Path)], landIndex: [UInt16], isLand: [Bool], bounds: CGRect, width: Int, height: Int,
        wraps: Bool
    ) -> [LandBorder] {
        let across = CGFloat(width) / bounds.width
        let down = CGFloat(height) / bounds.height
        // The countries drawn by their parts, whose own outlines are left for their parts'. Only
        // those the atlas divides count: a place shared with another collection, such as Hong
        // Kong's CN-HK, is a World land in its own right and leaves China's outline traced.
        let divided = Set(lands.compactMap { land in land.key.hasPrefix("WORLD-") ? nil : String(land.key.prefix { $0 != "-" }) })
            .intersection(TimeZoneAtlas.dividedCountries)
        let traced = lands.map { land in
            !(land.key.hasPrefix("WORLD-") && divided.contains(String(land.key.dropFirst(6))))
        }
        /// The land at a point of the map, from 1, or 0 for the sea.
        func land(at point: CGPoint) -> Int {
            var x = Int(((point.x - bounds.minX) * across).rounded(.down))
            let y = Int(((point.y - bounds.minY) * down).rounded(.down))
            guard y >= 0, y < height else { return 0 }
            if x < 0 || x >= width {
                guard wraps else { return 0 }
                x = (x % width + width) % width
            }
            let pixel = y * width + x
            return isLand[pixel] ? Int(landIndex[pixel]) : 0
        }
        var borders: [LandBorder] = []
        for (index, outline) in lands.enumerated() where traced[index] {
            let own = index + 1
            // The border being traced: the land across it, and the line so far.
            var current: (other: Int, path: Path, end: CGPoint)?
            func finish() {
                if let current { borders.append(LandBorder(first: own - 1, second: current.other - 1, path: current.path)) }
                current = nil
            }
            func visit(from start: CGPoint, to end: CGPoint) {
                let dx = (end.x - start.x) * across
                let dy = (end.y - start.y) * down
                let length = hypot(dx, dy)
                // Nothing to trace, or a jump across the map's edge.
                guard length > 0, abs(end.x - start.x) < bounds.width / 2 else {
                    finish()
                    return
                }
                // A pixel and a bit to either side, square to the line.
                let normal = CGPoint(x: -dy / length * 1.3 / across, y: dx / length * 1.3 / down)
                let steps = max(Int((length / 2).rounded(.up)), 1)
                for step in 0..<steps {
                    let from = CGFloat(step) / CGFloat(steps)
                    let to = CGFloat(step + 1) / CGFloat(steps)
                    let a = CGPoint(x: start.x + (end.x - start.x) * from, y: start.y + (end.y - start.y) * from)
                    let b = CGPoint(x: start.x + (end.x - start.x) * to, y: start.y + (end.y - start.y) * to)
                    let middle = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                    let left = land(at: CGPoint(x: middle.x + normal.x, y: middle.y + normal.y))
                    let right = land(at: CGPoint(x: middle.x - normal.x, y: middle.y - normal.y))
                    let neighbour = left != 0 && left != own ? left : right != 0 && right != own ? right : 0
                    // Traced from the outline of the earlier of the two, or where the land across
                    // isn't traced itself, from this one.
                    guard neighbour != 0, neighbour > own || !traced[neighbour - 1] else {
                        finish()
                        continue
                    }
                    if var line = current, line.other == neighbour, line.end == a {
                        line.path.addLine(to: b)
                        line.end = b
                        current = line
                    } else {
                        finish()
                        var path = Path()
                        path.move(to: a)
                        path.addLine(to: b)
                        current = (neighbour, path, b)
                    }
                }
            }
            var first: CGPoint?
            var last: CGPoint?
            outline.path.forEach { element in
                switch element {
                case .move(let point):
                    finish()
                    first = point
                    last = point
                case .line(let point), .quadCurve(let point, _), .curve(let point, _, _):
                    if let last { visit(from: last, to: point) }
                    last = point
                case .closeSubpath:
                    if let last, let first { visit(from: last, to: first) }
                    last = first
                    finish()
                }
            }
            finish()
        }
        return borders
    }

    /// The borders on land between places keeping different times, `offsets` giving each land's
    /// offset from UTC by its key: those of the time in `focus` apart from the rest, to stand out
    /// as the rest step back.
    nonisolated func zoneBorders(offsets: [String: Int], focus: Int?, key: String) -> ZoneBorders {
        let landOffsets = keys.map { key in offsets[key] ?? offsets["WORLD-\(key.prefix { $0 != "-" })"] }
        var lines = Path()
        var focused = Path()
        for border in borders {
            guard let first = landOffsets[border.first], let second = landOffsets[border.second], first != second else { continue }
            if let focus, first == focus || second == focus {
                focused.addPath(border.path)
            } else {
                lines.addPath(border.path)
            }
        }
        return ZoneBorders(key: key, lines: lines, focused: focused)
    }

    /// The offset from UTC kept at a point of the map, in its units: the time of the land there or
    /// nearest it, `offsets` giving each land's offset by its key, or out at sea beyond the reach of
    /// land, the nautical zone's. Nil off the raster.
    nonisolated func offset(at point: CGPoint, bounds: CGRect, offsets: [String: Int]) -> Int? {
        let x = Int((point.x - bounds.minX) / bounds.width * CGFloat(width))
        let y = Int((point.y - bounds.minY) / bounds.height * CGFloat(height))
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        let pixel = y * width + x
        let land = Int(nearest[pixel])
        guard land > 0 else { return Int(nautical[pixel]) * 3600 }
        let key = keys[land - 1]
        return offsets[key] ?? offsets["WORLD-\(key.prefix { $0 != "-" })"] ?? Int(nautical[pixel]) * 3600
    }

    /// The sea tinted with the colours of the times kept on it, `offsets` giving each land's offset
    /// from UTC by its key. With a time in `focus`, its stretches of sea come forward and the rest
    /// step back, as the land does. Land is left clear, for the map to draw over.
    nonisolated func image(offsets: [String: Int], opacity: Double, focus: Int? = nil) -> CGImage? {
        let count = width * height
        var tints: [Int: (UInt8, UInt8, UInt8, UInt8)] = [:]
        func tint(_ offset: Int) -> (UInt8, UInt8, UInt8, UInt8) {
            if let known = tints[offset] { return known }
            let strength = focus.map { $0 == offset ? min(opacity * 1.6, 1) : opacity * 0.3 } ?? opacity
            let shade = ZonePalette.components(forOffset: offset) * strength
            let made = (UInt8(shade.x * 255), UInt8(shade.y * 255), UInt8(shade.z * 255), UInt8(strength * 255))
            tints[offset] = made
            return made
        }
        // A subdivision the atlas doesn't give a time of its own keeps its country's.
        let landOffsets = keys.map { key in offsets[key] ?? offsets["WORLD-\(key.prefix { $0 != "-" })"] }
        var bytes = [UInt8](repeating: 0, count: count * 4)
        for pixel in 0..<count where !isLand[pixel] {
            let land = Int(nearest[pixel])
            let offset = land > 0 ? landOffsets[land - 1] ?? Int(nautical[pixel]) * 3600 : Int(nautical[pixel]) * 3600
            let (red, green, blue, alpha) = tint(offset)
            bytes[pixel * 4] = red
            bytes[pixel * 4 + 1] = green
            bytes[pixel * 4 + 2] = blue
            bytes[pixel * 4 + 3] = alpha
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}

extension SeaZoneField {
    /// The raster for one of World Time's maps: the area it covers, in the map's units, its size in
    /// pixels, how its pixels stand to longitude, how far land's time carries out to sea, and
    /// whether its sides meet.
    struct Raster: Sendable {
        var bounds: CGRect
        var width: Int
        var height: Int
        var longitudes: Longitudes
        var reach: Int
        var wraps: Bool
    }

    /// How far land's time carries out to sea, in degrees: across every ocean, so the zones meet
    /// between the coasts.
    static let reachDegrees = 60.0

    /// The raster for the dial's disc or the flat map, about half a degree to a pixel.
    static func raster(for projection: MapProjection, centerLongitude: Double) -> Raster {
        if projection == .polar {
            let extent = DialGeometry.extent
            let side = 560
            // Which way longitude runs round the pole, from two points on the equator a quarter apart.
            let start = MapProjection.polar.project(CGPoint(x: 0, y: 0))
            let quarter = MapProjection.polar.project(CGPoint(x: 90, y: 0))
            let startAngle = atan2(Double(start.y), Double(start.x)) * 180 / .pi
            let quarterAngle = atan2(Double(quarter.y), Double(quarter.x)) * 180 / .pi
            let turn: Double = DayNight.normalized(quarterAngle - startAngle) > 0 ? 1 : -1
            let pixelsPerUnit = Double(side) / (2 * extent)
            return Raster(
                bounds: CGRect(x: -extent, y: -extent, width: extent * 2, height: extent * 2), width: side, height: side,
                longitudes: .around(atZero: centerLongitude - turn * startAngle, turn: turn),
                reach: Int((reachDegrees * .pi / 180 * pixelsPerUnit).rounded()), wraps: false)
        }
        let width = 720
        let degreesPerPixel = 360 / Double(width)
        return Raster(
            bounds: CGRect(x: -Double.pi, y: FlatGeometry.top, width: 2 * .pi, height: FlatGeometry.bottom - FlatGeometry.top),
            width: width, height: Int((Double(width) / FlatGeometry.aspect).rounded()),
            longitudes: .across(west: centerLongitude - 180, degreesPerPixel: degreesPerPixel),
            reach: Int((reachDegrees / degreesPerPixel).rounded()), wraps: true)
    }
}

/// The sea tinted with its time zones as the clocks stand, ready to draw: told apart by the map it
/// was made for and the clocks it shows.
struct SeaTint: Equatable {
    var key: String
    var image: CGImage

    nonisolated static func == (a: SeaTint, b: SeaTint) -> Bool {
        a.key == b.key
    }
}

/// The borders on land between places keeping different times, ready to draw in a map's units:
/// those of the time in focus, if any, and the rest. Told apart by the map and clocks they were
/// made for.
struct ZoneBorders: Equatable {
    var key: String
    var lines: Path
    var focused: Path

    nonisolated static func == (a: ZoneBorders, b: ZoneBorders) -> Bool {
        a.key == b.key
    }
}

/// The days either side of the date line at a moment: to its west, where each day comes first, and
/// to its east, a day behind, such as Sat and Fri.
struct DateLineDays: Equatable {
    var west: String
    var east: String

    init(at date: Date) {
        func day(hoursAhead hours: Int) -> String {
            let zone = TimeZone(secondsFromGMT: hours * 3600) ?? .gmt
            return date.formatted(Date.FormatStyle(timeZone: zone).weekday(.abbreviated))
        }
        west = day(hoursAhead: 12)
        east = day(hoursAhead: -12)
    }
}

extension WorldPainting {
    /// The International Date Line, as Natural Earth draws it, in longitude and latitude from the
    /// North Pole to the South: down the 180th meridian, bending east round Chukotka, west of the
    /// Aleutians, east round Kiribati's Line Islands and between Samoa and American Samoa, and
    /// east of Tonga and New Zealand's Chatham Islands.
    static let dateLine: [CGPoint] = {
        let degrees: [(Double, Double)] = [
            (180, 90), (180, 75), (-173.66, 71.24), (-169, 68), (-169, 65.5), (-173.79, 63.05), (-179.49, 59.81),
            (170, 53), (180, 48), (180, -2.51), (-158.49, -2.51), (-158.49, -0.23), (-160.64, 1.5), (-160.64, 4.94),
            (-155.53, 4.94), (-150, -9.91), (-150, -11.65), (-154.57, -11.65), (-156.08, -5.84), (-169.4, -5.84),
            (-170.99, -9.43), (-171.29, -11.06), (-171, -13.97), (-171.24, -14.43), (-172.5, -15), (-172.5, -45),
            (180, -51), (180, -90),
        ]
        return degrees.map { CGPoint(x: $0.0, y: $0.1) }
    }()

    /// The date line in a map's units, in as many pieces as the map's edges cut it into: points no
    /// more than a degree apart, so it curves where the projection curves it.
    static func dateLine(in projection: MapProjection, centerLongitude: Double, south: Double = -90) -> [Path] {
        var pieces: [Path] = []
        var piece = Path()
        var last: CGPoint?
        for (start, end) in zip(dateLine, dateLine.dropFirst()) {
            // The shorter way between the two, across the 180th meridian where that's shorter.
            var east = end.x - start.x
            if east > 180 { east -= 360 }
            if east < -180 { east += 360 }
            let steps = max(Int(max(abs(east), abs(end.y - start.y))), 1)
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let latitude = start.y + (end.y - start.y) * t
                guard latitude >= south else { continue }
                let relative = DayNight.normalized(start.x + east * t - centerLongitude)
                let point = projection.project(CGPoint(x: relative, y: latitude))
                // A jump across the map's edge starts a new piece.
                if let last, abs(point.x - last.x) > .pi {
                    pieces.append(piece)
                    piece = Path()
                }
                if piece.isEmpty { piece.move(to: point) } else { piece.addLine(to: point) }
                last = point
            }
        }
        pieces.append(piece)
        return pieces.filter { !$0.isEmpty }
    }

    /// The meridians the time zones would follow if every place kept the time of its longitude, as
    /// ships at sea do: every fifteen degrees, half way between the hours, in a map's units, from
    /// `north` down to `south`, each with its longitude, sampled closely enough to curve wherever
    /// the projection curves them.
    static func zoneMeridians(
        in projection: MapProjection, centerLongitude: Double, south: Double, north: Double
    ) -> [(longitude: Double, path: Path)] {
        stride(from: -172.5, through: 172.5, by: 15).map { longitude in
            let relative = DayNight.normalized(longitude - centerLongitude)
            var path = Path()
            for latitude in stride(from: north, through: south, by: -4) {
                let point = projection.project(CGPoint(x: relative, y: latitude))
                if path.isEmpty { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.addLine(to: projection.project(CGPoint(x: relative, y: south)))
            return (longitude, path)
        }
    }

    /// The time zones' meridians, dashed across the sea and left out over `land`, where the borders
    /// the places really keep are drawn instead: a white dash over a wider stroke of the zones' ink,
    /// so they hold on the palest tints as well as the deep sea. With a time in `focus`, the two
    /// edging its zone come forward, a little bolder, and the rest step back. They're drawn before
    /// the date line, which lies over them in its own dashes. `scale` is points per unit of the map the
    /// context draws in.
    static func paintZoneMeridians(
        _ meridians: [(longitude: Double, path: Path)], land: Path, focus: Int?, scale: CGFloat, in context: GraphicsContext
    ) {
        var sea = context
        sea.clip(to: land, options: .inverse)
        // The meridians edging the focused zone, half way to the hours either side of its own.
        let edges: Set<Double> = focus.flatMap { offset -> Set<Double>? in
            guard offset % 3600 == 0 else { return nil }
            let middle = Double(offset / 3600) * 15
            return [DayNight.normalized(middle - 7.5), DayNight.normalized(middle + 7.5)]
        } ?? []
        let dash = [6 / scale, 4 / scale]
        for meridian in meridians {
            let isEdge = edges.contains { abs(DayNight.normalized($0 - meridian.longitude)) < 0.1 }
            let (opacity, width): (Double, CGFloat) = isEdge ? (0.75, 1.4) : focus == nil ? (0.34, 1) : (0.16, 1)
            // The ink beneath steps back with the line it carries.
            let ink = 0.25 * min(opacity / 0.34, 1)
            sea.stroke(
                meridian.path, with: .color(zoneInk.opacity(ink)),
                style: StrokeStyle(lineWidth: (width + 1.2) / scale, lineCap: .round, dash: dash))
            sea.stroke(
                meridian.path, with: .color(.white.opacity(opacity)),
                style: StrokeStyle(lineWidth: width / scale, lineCap: .round, dash: dash))
        }
    }

    /// The borders on land between places keeping different times: a fine white core over a wider
    /// halo of the zones' ink, so they read across pale and deep colours alike, bolder than a
    /// country's border, as an atlas's time zone map draws them. With a time in focus, its zone's
    /// borders stand out, brighter and a touch wider, and the rest step back with the land they run
    /// through. `scale` is points per unit of the map the context draws in.
    static func paintZoneBorders(_ borders: ZoneBorders, hasFocus: Bool, scale: CGFloat, in context: GraphicsContext) {
        func stroke(_ path: Path, core: Double, width: CGFloat) {
            guard !path.isEmpty else { return }
            // The halo fades with the core, so a stepped-back border doesn't leave a dark trace.
            context.stroke(
                path, with: .color(zoneInk.opacity(0.5 * min(core / 0.5, 1.2))),
                style: StrokeStyle(lineWidth: (width + 1.4) / scale, lineCap: .round, lineJoin: .round))
            context.stroke(
                path, with: .color(.white.opacity(core)),
                style: StrokeStyle(lineWidth: width / scale, lineCap: .round, lineJoin: .round))
        }
        stroke(borders.lines, core: hasFocus ? 0.2 : 0.5, width: 1)
        stroke(borders.focused, core: 0.85, width: 1.4)
    }

    /// The ink of the zones' borders on land: the sea's own deep blue, darker.
    private static let zoneInk = Color(red: 0.02, green: 0.06, blue: 0.16)

    /// All a map's land as one outline, for keeping the sea's lines off it.
    static func land(of map: TravelMap) -> Path {
        var land = Path()
        for region in map.regions where region.id != DialPalette.antarcticaID {
            land.addPath(region.path)
        }
        return land
    }
}
