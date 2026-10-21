import SwiftUI

/// What the countries on a World map are coloured by: the person's own levels, as every travel map
/// is, or, in the Atlas, something a traveller wants to know before going, such as the side of the
/// road, the shape of the plugs, or the ocean its coast is on.
enum MapColouring: String, CaseIterable, Identifiable {
    case travels, drivingSide, plugs, voltage, coasts

    var id: Self { self }

    /// The colourings the Atlas offers: everything but the person's travels.
    static let facts: [MapColouring] = [.drivingSide, .plugs, .voltage, .coasts]

    var name: String {
        switch self {
        case .travels: "Your travels"
        case .drivingSide: "Driving side"
        case .plugs: "Plugs"
        case .voltage: "Voltage"
        case .coasts: "Coasts"
        }
    }

    var symbolName: String {
        switch self {
        case .travels: "mappin.and.ellipse"
        case .drivingSide: "steeringwheel"
        case .plugs: "powerplug"
        case .voltage: "bolt"
        case .coasts: "water.waves"
        }
    }

    /// Every colour it can give a country, in the order the legend lists them. Travels uses the
    /// person's levels instead.
    var keys: [MapKey] {
        switch self {
        case .travels: []
        case .drivingSide: DrivingSide.allCases.map(\.key)
        case .plugs: PlugType.allCases.map(\.key)
        case .voltage: MainsVoltage.allCases.map(\.key)
        case .coasts: CoastKey.allCases.map(\.key)
        }
    }

    func key(id: String) -> MapKey? {
        keys.first { $0.id == id }
    }

    /// The keys a region of the World map has, by ID, the one it's coloured with first: a plug
    /// type for each kind of socket in use there, most common first. Empty where there's nothing
    /// to say, such as Antarctica, which has no public roads or mains.
    func keyIDs(ofRegion regionID: String) -> [String] {
        // Coasts colour the seas too, by their ocean.
        if self == .coasts { return SeaCoasts.oceanKeyIDs(ofRegion: regionID) }
        guard let code = WorldLayers.code(ofRegion: regionID) else { return [] }
        switch self {
        case .travels:
            return []
        case .drivingSide:
            return DrivingSide.of(code).map { [$0.rawValue] } ?? []
        case .plugs:
            return MainsPower.of(code)?.plugs.map(\.rawValue) ?? []
        case .voltage:
            return MainsPower.of(code).map { [$0.voltage.rawValue] } ?? []
        case .coasts:
            return []
        }
    }

    /// What it says about a place, by its ISO 3166 code, such as Drives, Left.
    func fact(about code: String) -> MapFact? {
        switch self {
        case .travels:
            return nil
        case .drivingSide:
            guard let side = DrivingSide.of(code) else { return nil }
            return MapFact(
                symbolName: symbolName, tint: Self.drivingTint, label: "Drives", value: side.name, spoken: side.fact)
        case .plugs:
            guard let power = MainsPower.of(code) else { return nil }
            return MapFact(
                symbolName: symbolName, tint: Self.plugTint, label: "Plugs",
                value: power.plugs.map(\.rawValue).joined(separator: ", "), spoken: power.plugSummary)
        case .voltage:
            guard let power = MainsPower.of(code) else { return nil }
            return MapFact(
                symbolName: symbolName, tint: Self.mainsTint, label: "Voltage", value: power.powerSummary,
                spoken: power.powerSummary.replacingOccurrences(of: " V", with: " volts")
                    .replacingOccurrences(of: " Hz", with: " hertz"))
        case .coasts:
            guard let coasts = SeaCoasts.summary(ofPlace: code) else { return nil }
            return MapFact(
                symbolName: symbolName, tint: Self.coastTint, label: "Coasts", value: coasts.value, spoken: coasts.spoken)
        }
    }

    /// The colour of its fact's symbol, and of its card in the full map's layer chooser. Nil for
    /// the person's travels, which wear their own levels' colours.
    var tint: Color? {
        switch self {
        case .travels: nil
        case .drivingSide: Self.drivingTint
        case .plugs: Self.plugTint
        case .voltage: Self.mainsTint
        case .coasts: Self.coastTint
        }
    }

    /// The facts' symbols' colours, from the same deep-on-light, lifted-on-dark palette as Learn's codes.
    static let drivingTint = Color(light: (0.33, 0.40, 0.50), dark: (0.66, 0.73, 0.84))
    static let plugTint = Color(light: (0.0, 0.56, 0.48), dark: (0.30, 0.85, 0.74))
    static let mainsTint = Color(light: (0.90, 0.60, 0.0), dark: (1.0, 0.78, 0.25))
    static let coastTint = Color(light: (0.0, 0.42, 0.78), dark: (0.35, 0.70, 1.0))

    /// Everything the Atlas knows about one of the World's places: the side of the road, its plugs,
    /// its mains and its coasts, as the Atlas and Learn list them. Empty for anything else, such as a prefecture.
    static func facts(about place: AdministrativeDivision) -> [MapFact] {
        guard place.countryID == CountryCatalog.world.id else { return [] }
        return facts.compactMap { $0.fact(about: place.abbreviation) }
    }

    /// How many of these regions of the World map have each key, by ID: a place with two kinds of
    /// socket counts for both.
    func tally(ofRegions ids: some Sequence<String>) -> [String: Int] {
        var tally: [String: Int] = [:]
        for regionID in ids {
            for id in Set(keyIDs(ofRegion: regionID)) { tally[id, default: 0] += 1 }
        }
        return tally
    }
}

/// What the full map of the World can show, as its layer chooser lists them: the person's travels,
/// the World's time zones, or the countries coloured by a fact about them. Time zones aren't a
/// colouring of the map: choosing them opens World Time, the World curling up into its dial.
enum MapLayer: Hashable, Identifiable {
    case colouring(MapColouring)
    /// A card for each place to swipe through, its flag, capitals, codes and facts, over the
    /// person's travels.
    case atlas
    case timeZones

    var id: String {
        switch self {
        case .colouring(let colouring): colouring.rawValue
        case .atlas: "atlas"
        case .timeZones: "timeZones"
        }
    }

    /// Every layer of the World, in the order the chooser lists them: the person's own travels
    /// first, then the Atlas's cards, the time, and the facts.
    static let all: [MapLayer] = [.colouring(.travels), .atlas, .timeZones] + MapColouring.facts.map(MapLayer.colouring)

    /// The layers of any other map, such as Japan's: the person's travels, and the Atlas's cards.
    static let everywhere: [MapLayer] = [.colouring(.travels), .atlas]

    var name: String {
        switch self {
        case .colouring(let colouring): colouring.name
        case .atlas: "Atlas"
        case .timeZones: "Time zones"
        }
    }

    var symbolName: String {
        switch self {
        case .colouring(let colouring): colouring.symbolName
        case .atlas: "book.fill"
        case .timeZones: WorldTimeScreen.symbolName
        }
    }

    /// The colour its symbol wears, and its card when chosen. Nil for the person's travels, which
    /// wear their own levels' colours.
    var tint: Color? {
        switch self {
        case .colouring(let colouring): colouring.tint
        case .atlas: MapGame.learnColor
        case .timeZones: MapLayer.timeTint
        }
    }

    /// The deep blue of a night sky, after World Time's.
    static let timeTint = Color(light: (0.24, 0.32, 0.72), dark: (0.55, 0.64, 1.0))
}

/// A colour in a layer's legend, such as Left for driving side, or plug type G.
struct MapKey: Identifiable, Equatable {
    var id: String
    /// Its name in the legend, such as "Left" or "220–240 V".
    var name: String
    var color: Color
    /// What VoiceOver reads, where the name alone would be cryptic, such as "Type G plugs".
    var spokenName: String
    /// A plug's face, for plug types.
    var plug: PlugType? = nil
}

/// Something the Atlas knows about a place, such as its plugs, listed like Learn's codes: a small
/// coloured symbol, a short label and its value, on Learn's cards, the Atlas's and the full map's
/// callout alike.
struct MapFact: Identifiable, Equatable {
    var symbolName: String
    var tint: Color
    /// Its name beside its value, short enough to sit in a column, such as "Plugs".
    var label: String
    /// Such as "Left", "C, F" or "230 V, 50 Hz".
    var value: String
    /// What VoiceOver hears, such as "Drives on the left".
    var spoken: String

    var id: String { label }
}

extension Color {
    /// A colour that takes one shade in light mode and another in dark.
    init(light: (Double, Double, Double), dark: (Double, Double, Double)) {
        self.init(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }
}
