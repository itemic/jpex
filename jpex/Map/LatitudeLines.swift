import SwiftUI

/// The Equator, the tropics and the polar circles: the lines of latitude the Earth's tilt draws.
/// Between the tropics the Sun passes straight overhead at least once a year; beyond the polar
/// circles it stays up all day at midsummer and down all day at midwinter.
enum LatitudeLines {
    struct Line: Identifiable {
        var id: String
        var name: String
        var latitude: Double
        var kind: Kind
    }

    enum Kind {
        case equator, tropic, polar
    }

    /// The Earth's tilt in 2026, 23° 26′ 09″, which sets where the tropics and polar circles lie.
    /// It shrinks by about half a second of arc a year, far too little to see on a map.
    static let tilt = 23.4358

    static let all: [Line] = [
        Line(id: "arctic", name: "Arctic Circle", latitude: 90 - tilt, kind: .polar),
        Line(id: "cancer", name: "Tropic of Cancer", latitude: tilt, kind: .tropic),
        Line(id: "equator", name: "Equator", latitude: 0, kind: .equator),
        Line(id: "capricorn", name: "Tropic of Capricorn", latitude: -tilt, kind: .tropic),
        Line(id: "antarctic", name: "Antarctic Circle", latitude: tilt - 90, kind: .polar),
    ]

    /// A line drawn on a map: its path in the map's units, in pieces where it passes behind the globe.
    struct Drawn {
        var line: Line
        var path: Path
        /// The pieces' points, in the map's units, for finding where to set its name.
        var pieces: [[CGPoint]]
    }

    /// Every line on a map in a projection, running `edge` degrees of longitude either side of its
    /// middle: a little past the sides of a World laid side by side with copies of itself, so the
    /// lines run on across the joins. A line of latitude is the same at any centre, so a projection
    /// has only one set.
    @MainActor
    static func drawn(in projection: MapProjection, edge: Double) -> [Drawn] {
        let key = "\(projection.rawValue) \(Int(edge))"
        if let cached = cache[key] { return cached }
        let lines = all.map { line in
            var pieces: [[CGPoint]] = []
            var piece: [CGPoint] = []
            for longitude in stride(from: -edge, through: edge, by: 1) {
                let point = CGPoint(x: longitude, y: line.latitude)
                if projection.isVisible(point) {
                    piece.append(projection.project(point))
                } else if !piece.isEmpty {
                    pieces.append(piece)
                    piece = []
                }
            }
            if !piece.isEmpty { pieces.append(piece) }
            // On the globe, a line seen all the way round closes on itself.
            if projection == .globe, pieces.count == 2, let first = pieces.first, let last = pieces.last,
               projection.isVisible(CGPoint(x: -edge, y: line.latitude)) {
                pieces = [last + first]
            }
            var path = Path()
            for piece in pieces where piece.count > 1 { path.addLines(piece) }
            return Drawn(line: line, path: path, pieces: pieces)
        }
        cache[key] = lines
        return lines
    }

    @MainActor private static var cache: [String: [Drawn]] = [:]
}
