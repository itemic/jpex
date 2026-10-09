import SwiftUI

/// Everything Time Machine draws, read once from bundled files: the world cut into units — today's
/// countries, some cut into pieces where history's borders ran through them — the borders between
/// them, the moments in history and who held each unit then, and how the continents drifted in
/// deep time.
struct TimeMachineAtlas: Sendable {
    /// The world's pieces, in longitude and latitude.
    var units: [Unit]
    /// Every stretch of border or coast, each shared by the one or two units either side of it.
    var arcs: [Arc]
    /// The moments in history, earliest first, ending with today.
    var eras: [HistoricalEra]
    var polities: [String: HistoricalPolity]
    /// For each era, where each unit belonged then, in the order of `units`.
    var placements: [[Placement]]
    /// Each country's colour, chosen so neighbours differ.
    var countryColors: [String: HistoryColor]
    /// How the continents moved, when the plates file is bundled.
    var deepTime: DeepTime?

    struct Unit: Sendable {
        var id: String
        /// The country it's part of today, such as DE for Bavaria, or its own code.
        var country: String
        var name: String
        var rings: [MapRing]
        /// Fewer points, for the globe, which redraws every frame as it turns and drifts.
        var lightRings: [MapRing]
        /// A point inside it to label it at.
        var label: CGPoint
    }

    struct Arc: Sendable {
        var a: Int
        /// The unit on the other side, or nil along a coast.
        var b: Int?
        var ring: MapRing
    }

    /// Who held a unit in an era, and what the place itself was called then.
    struct Placement: Sendable, Equatable {
        var polity: String
        var label: String
    }

    func polity(_ id: String) -> HistoricalPolity {
        polities[id] ?? HistoricalPolity(id: id, name: id, flagAssetName: nil, colorKey: id, kind: .state)
    }

    /// A polity's colour: its own named colour, or the colour of the country it takes after.
    func color(of polity: HistoricalPolity) -> HistoryColor {
        switch polity.kind {
        case .unclaimed: return .ice
        case .indigenous: return .earth
        default: break
        }
        return HistoryColor(rawValue: polity.colorKey) ?? countryColors[polity.colorKey] ?? .slate
    }

    /// The units a list of unit ids or country codes stands for, as in an event.
    func unitIndices(for ids: [String]) -> [Int] {
        let wanted = Set(ids)
        return units.indices.filter { index in
            let unit = units[index]
            return wanted.contains(unit.id) || wanted.contains(unit.country)
                || wanted.contains(Self.parentCode(of: unit.country))
        }
    }

    /// A sub-region's country, such as GB for GB-SCT or FR for FR-973.
    nonisolated static func parentCode(of code: String) -> String {
        code.split(separator: "-").first.map(String.init) ?? code
    }
}

// MARK: Loading

extension TimeMachineAtlas {
    /// Reads the bundled files. Slow enough to keep off the main thread.
    nonisolated static func load() -> TimeMachineAtlas? {
        guard let geometry: GeometryFile = decode("geo_TIMEMACHINE"),
              let history: ErasFile = decode("TimeMachineEras")
        else { return nil }

        let units = geometry.units.map { item in
            let rings = TravelMap.rings(fromSVG: item.d)
            let label = item.c.flatMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
                ?? Self.centroid(of: rings)
            return Unit(id: item.id, country: item.country, name: item.name, rings: rings,
                        lightRings: rings.map(Self.thinned), label: label)
        }
        var unitIndex: [String: Int] = [:]
        for (index, unit) in units.enumerated() { unitIndex[unit.id] = index }
        let arcs: [Arc] = geometry.arcs.flatMap { item -> [Arc] in
            guard let a = unitIndex[item.a] else { return [] }
            let b = item.b.flatMap { unitIndex[$0] }
            return TravelMap.rings(fromSVG: item.d).map { Arc(a: a, b: b, ring: $0) }
        }

        // Every country stands for itself until an era says otherwise.
        var polities: [String: HistoricalPolity] = [:]
        let names = Self.countryNames
        for unit in units {
            let code = parentCode(of: unit.country)
            guard polities[code] == nil else { continue }
            polities[code] = HistoricalPolity(
                id: code, name: names[code] ?? unit.name, flagAssetName: "world_flag_\(code.lowercased())",
                colorKey: code, kind: code == "AQ" ? .unclaimed : .state)
        }
        for (id, item) in history.polities {
            polities[id] = HistoricalPolity(
                id: id, name: item.name, flagAssetName: item.flag.flatMap(Self.assetName(fromFlag:)),
                colorKey: item.color ?? id, kind: item.kind.flatMap(PolityKind.init(rawValue:)) ?? .state)
        }

        let eras = history.eras.map { era in
            HistoricalEra(
                id: era.id, year: era.year, title: era.title, summary: era.summary ?? "",
                events: (era.events ?? []).map { event in
                    HistoricalEvent(
                        year: event.year, title: event.title, detail: event.detail ?? "",
                        location: event.at.flatMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil },
                        unitIDs: event.units ?? [], from: event.from ?? [], to: event.to ?? [],
                        kind: HistoricalEvent.Kind(rawValue: event.kind ?? "") ?? .treaty)
                })
        }
        let placements = history.eras.map { era in
            units.map { unit in
                Self.placement(of: unit, assign: era.assign ?? [:], polities: polities)
            }
        }
        let colors = geometry.colors.compactMapValues(HistoryColor.init(rawValue:))
        let deepTime: PlatesFile? = decode("TimeMachinePlates")
        return TimeMachineAtlas(
            units: units, arcs: arcs, eras: eras, polities: polities, placements: placements,
            countryColors: colors, deepTime: deepTime.map { DeepTime(file: $0, units: units) })
    }

    /// Where a unit belonged under an era's assignments: by its own id first, then its country's,
    /// then its parent country's, or else itself.
    private nonisolated static func placement(
        of unit: Unit, assign: [String: String], polities: [String: HistoricalPolity]
    ) -> Placement {
        let parent = parentCode(of: unit.country)
        let own = assign[unit.id] ?? assign[unit.country]
        if let value = own ?? assign[parent] {
            let parts = value.split(separator: "|", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            let polity = parts[0]
            // A sub-region such as Scotland, going along with its country, keeps its own name.
            let inherits = own == nil && unit.country.contains("-")
            let label = inherits ? unit.name
                : parts.count > 1 && !parts[1].isEmpty ? parts[1] : (polities[polity]?.name ?? polity)
            return Placement(polity: polity, label: label)
        }
        // A sub-region such as Scotland is part of its country, under its own name.
        let label = unit.country.contains("-") ? unit.name : (polities[parent]?.name ?? unit.name)
        return Placement(polity: parent, label: label)
    }

    private nonisolated static func assetName(fromFlag flag: String) -> String? {
        flag.hasPrefix("asset:") ? String(flag.dropFirst("asset:".count)) : nil
    }

    private nonisolated static var countryNames: [String: String] {
        var names: [String: String] = [:]
        for place in CountryCatalog.world.divisions {
            names[place.abbreviation] = place.name
        }
        return names
    }

    private nonisolated static func decode<T: Decodable>(_ resource: String) -> T? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Every other point of a long ring, keeping its ends.
    private nonisolated static func thinned(_ ring: MapRing) -> MapRing {
        guard ring.points.count > 12 else { return ring }
        var points = stride(from: 0, to: ring.points.count, by: 2).map { ring.points[$0] }
        if !ring.isClosed, let last = ring.points.last, points.last != last { points.append(last) }
        return MapRing(points: points, isClosed: ring.isClosed)
    }

    private nonisolated static func centroid(of rings: [MapRing]) -> CGPoint {
        let points = rings.max { $0.points.count < $1.points.count }?.points ?? []
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}

// MARK: Files

private struct GeometryFile: Decodable {
    var units: [UnitItem]
    var arcs: [ArcItem]
    var colors: [String: String]

    struct UnitItem: Decodable {
        var id: String
        var country: String
        var name: String
        var d: String
        var c: [Double]?
    }

    struct ArcItem: Decodable {
        var a: String
        var b: String?
        var d: String
    }
}

private struct ErasFile: Decodable {
    var polities: [String: PolityItem]
    var eras: [EraItem]

    struct PolityItem: Decodable {
        var name: String
        var flag: String?
        var color: String?
        var kind: String?
    }

    struct EraItem: Decodable {
        var id: String
        var year: Int
        var title: String
        var summary: String?
        var assign: [String: String]?
        var events: [EventItem]?
    }

    struct EventItem: Decodable {
        var year: Int
        var title: String
        var detail: String?
        var at: [Double]?
        var units: [String]?
        var from: [String]?
        var to: [String]?
        var kind: String?
    }
}

struct PlatesFile: Decodable {
    var maxMa: Double
    var plates: [PlateItem]
    var rotations: [String: [RotationItem]]
    var emerged: [String: Double]?
    var periods: [PeriodItem]?
    var labels: [LabelItem]?
    var events: [EventItem]?

    struct PlateItem: Decodable {
        var id: String
        var name: String
        var units: [String]
    }

    struct RotationItem: Decodable {
        var ma: Double
        var lat: Double
        var lon: Double
        var angle: Double
    }

    struct PeriodItem: Decodable {
        var name: String
        var start: Double
        var end: Double
        var color: String
    }

    struct LabelItem: Decodable {
        var name: String
        var from: Double
        var to: Double
        var plate: String
        var at: [Double]
    }

    struct EventItem: Decodable {
        var ma: Double
        var title: String
        var detail: String?
        var plate: String?
        var at: [Double]?
        var kind: String?
    }
}
