import SwiftUI

/// The far side of the Earth. Switched on, the World map shows every country again where its
/// antipodes are, mirrored and faint, so you can see what lies directly beneath your feet:
/// Spain's beneath New Zealand, Argentina's beneath China, and most land's beneath the sea.
enum Antipodes {
    static let symbolName = "circle.dotted.and.circle"

    /// The countries at their antipodes, drawn over a World map in a projection around a centre
    /// longitude. Kept for the last map asked about, as a map turning by hand asks at every frame.
    @MainActor
    static func map(_ projection: MapProjection, centerLongitude: Double) -> TravelMap? {
        let key = Key(projection: projection, tenthsOfDegree: Int((centerLongitude * 10).rounded()))
        if let last, last.key == key { return last.map }
        // Centred half way round, so each country comes out where its antipodes are on this map.
        guard let map = Geography.antipodes?.turningMap(
            projection, centerLongitude: DayNight.normalized(centerLongitude + 180))
        else { return nil }
        last = (key, map)
        return map
    }

    /// What lies on the far side of the Earth from a place: the country most of it lies over, by
    /// ID, or nil where it's nearly all sea.
    @MainActor
    static func opposite(ofRegion id: String) -> String? {
        if let known = opposites[id] { return known }
        let answer = findOpposite(ofRegion: id)
        opposites[id] = .some(answer)
        return answer
    }

    /// What `opposite(ofRegion:)` says, as the full map's callout shows it.
    @MainActor
    static func fact(aboutRegion id: String, name: (String) -> String?) -> MapFact {
        let land = opposite(ofRegion: id).flatMap(name) ?? "Open sea"
        return MapFact(
            symbolName: symbolName, tint: Color(light: (0.36, 0.30, 0.80), dark: (0.62, 0.58, 1.0)), label: "Antipodes",
            value: land, spoken: "Antipodes: \(land)")
    }

    /// Samples points across the place's largest piece of land and looks at the far side of the
    /// Earth from each.
    @MainActor
    private static func findOpposite(ofRegion id: String) -> String? {
        guard let world = Geography.world, let bounds = world.mainlandBounds(of: id) else { return nil }
        let steps = 16
        var inside = 0
        var landings: [String: Int] = [:]
        for column in 0..<steps {
            for row in 0..<steps {
                let longitude = bounds.minX + bounds.width * (Double(column) + 0.5) / Double(steps)
                let latitude = bounds.minY + bounds.height * (Double(row) + 0.5) / Double(steps)
                guard world.region(id, containsLongitude: longitude, latitude: latitude) else { continue }
                inside += 1
                if let other = world.regionID(atLongitude: DayNight.normalized(longitude + 180), latitude: -latitude) {
                    landings[other, default: 0] += 1
                }
            }
        }
        // A place too small for the samples to land in, such as an island, is judged by its middle.
        if inside == 0 {
            return world.regionID(
                atLongitude: DayNight.normalized(bounds.midX + 180), latitude: -bounds.midY)
        }
        guard let best = landings.max(by: { $0.value < $1.value }), best.value * 10 >= inside else { return nil }
        return best.key
    }

    private struct Key: Equatable {
        var projection: MapProjection
        var tenthsOfDegree: Int
    }

    @MainActor private static var last: (key: Key, map: TravelMap)?
    @MainActor private static var opposites: [String: String?] = [:]
}
