import SwiftUI

/// Everything a picture of a list's map shows, gathered on screen so that the same picture can be
/// drawn again to be sent, away from the screen and everything it knows.
struct MapShareContent: Sendable {
    var country: Country
    var map: TravelMap
    /// Every place in the list, at its level.
    var statuses: [String: VisitLevel]
    var ladder: VisitLadder
    /// How many of the list's places count.
    var counted: Int
    /// The app icon the person has chosen, as a picture, since an app icon set can't be loaded as one.
    var iconName: String
    var format: Format
    /// What the card shows: the map, or the places' names set in one of the typographic layouts.
    var layout: Layout
    /// How the names layout sets the names.
    var namesStyle: NamesStyle
    /// The places most newly been to, in the list's order, for the new layout's card.
    var newPlaceIDs: [String]
    /// What colours the places been to: their levels, their flags, or the card's one colour.
    var colouring: Colouring
    var design: Design
    /// The colour of the colourful designs, Candy and Plaid.
    var tint: ShareTint
    /// The stripes of the striped design.
    var stripes: ShareStripes
    /// Whether places go by their local names, such as 北海道, as the list is showing them.
    var localLanguage: Bool
    /// The part of the map in the picture, in the map's own units.
    var focus: CGRect
    /// Whether the levels' pills sit over the map, each with how many places are at it.
    var showsKey: Bool
    /// Whether the flags of the places been to are pinned on the map where they are.
    var showsFlags: Bool
    /// Whether the card wears a holographic foil, as a rare trading card does.
    var showsFoil: Bool
    /// Whether the pass says when the picture was taken.
    var showsDate: Bool
    /// The colour the places take when they're coloured plainly, or nil for the design's own.
    var plainColor: Color?
    /// Which order the smart colours are dealt in; 0 for the design's own order.
    var smartSeed: Int
    /// Which arrangement the names filling the count's figures take.
    var fillSeed: Int

    var palette: ShareCardPalette {
        var palette = design.palette(tint: tint, stripes: stripes)
        palette.plainOverride = plainColor
        return palette
    }

    /// The places for the typographic layouts: those been to, highest level first, then A to Z; or,
    /// before there are any, every place in the list, faint.
    var words: [ShareWord] {
        let steps = Double(max(ladder.levels.count - 1, 1))
        let smart = smartColors
        let all = country.divisions.map { place -> ShareWord in
            let level = statuses[place.id] ?? .never
            let rank = ladder.rank(of: level)
            return ShareWord(
                id: place.id, name: place.displayName(localLanguage: localLanguage), level: level,
                height: rank == 0 ? 0 : min(Double(rank - 1) / steps, 1), flag: place.flagAssetName,
                smart: smart[place.id])
        }
        let visited = all.filter(\.isVisited).sorted { first, second in
            first.height != second.height
                ? first.height > second.height
                : first.name.localizedStandardCompare(second.name) == .orderedAscending
        }
        return visited.isEmpty ? all : visited
    }

    /// Each place been to's own colour, when the places are coloured smartly: the design's lively
    /// colours dealt out in the list's order, so places next to each other mostly differ, in an
    /// order shuffled afresh at each turn of the seed.
    var smartColors: [String: Color] {
        let colors = smartPalette
        guard !colors.isEmpty else { return [:] }
        let visited = country.divisions.filter { (statuses[$0.id]?.id ?? VisitLevel.never.id) != VisitLevel.never.id }
        return Dictionary(visited.enumerated().map { ($1.id, colors[$0 % colors.count]) }) { first, _ in first }
    }

    /// The design's lively colours, in the order the seed deals them.
    var smartPalette: [Color] {
        var colors = palette.smart
        var random = SeededGenerator(seed: UInt64(truncatingIfNeeded: smartSeed))
        if smartSeed != 0 { colors.shuffle(using: &random) }
        return colors
    }

    /// The language local names are set in, for their own script's glyphs, such as Japanese for
    /// 京都府; nil for names in English.
    var language: Locale.Language? {
        localLanguage && country.supportsLocalNames ? PlaceTypesetting.language(forCode: country.countryListID) : nil
    }

    /// Each place's flag, by its ID, for the map in its flags' colours and the flags pinned on it.
    var flags: [String: String] {
        Dictionary(country.divisions.map { ($0.id, $0.flagAssetName) }) { first, _ in first }
    }

    /// What the card shows, as a League Card's photo: the map itself; the map with the places newly
    /// been to picked out, under "+3"; or the places' names set in type, every one of them: as a
    /// block of names, as a map of words, or filling the count.
    enum Layout: String, CaseIterable, Identifiable, Sendable {
        case map, new, names, wordMap, count

        static let storageKey = "shareLayout"

        var id: Self { self }

        var name: String {
            switch self {
            case .map: "Map"
            case .new: "New"
            case .names: "Names"
            case .wordMap: "Word map"
            case .count: "Count"
            }
        }

        var symbolName: String {
            switch self {
            case .map: "map"
            case .new: "plus.circle"
            case .names: "text.justify"
            case .wordMap: "character.textbox"
            case .count: "numbers"
            }
        }

        /// Whether it shows the map, which can be framed.
        var showsMap: Bool {
            self == .map || self == .new || self == .wordMap
        }
    }

    /// How the names layout sets the places' names: every one at one size, so none looks more
    /// important than another, in one of several kinds of type.
    enum NamesStyle: String, CaseIterable, Identifiable, Sendable {
        /// Heavy, narrow capitals, justified into a solid block.
        case block
        /// A sentence of names in a fashion magazine's italic: "Hokkaido, Aomori, Iwate & Miyagi".
        case editorial
        /// Heavy, wide capitals, every other name only outlined, as on a gig poster.
        case outline
        /// Each name on a pill of its own, like the app's level pills.
        case pills
        /// One line of names wound round and round into the middle.
        case spiral
        /// A typed list, every name ticked off.
        case checklist

        static let storageKey = "shareNamesStyle"

        var id: Self { self }

        var name: String {
            switch self {
            case .block: "Block"
            case .editorial: "Editorial"
            case .outline: "Outline"
            case .pills: "Pills"
            case .spiral: "Spiral"
            case .checklist: "Checklist"
            }
        }
    }

    /// The flags of the places been to, highest level first, for the flag design's patchwork; or,
    /// before there are any, the list's first few flags.
    var visitedFlags: [String] {
        let places = country.divisions
        let visited = places
            .filter { (statuses[$0.id]?.id ?? VisitLevel.never.id) != VisitLevel.never.id }
            .sorted { ladder.rank(of: statuses[$0.id] ?? .never) > ladder.rank(of: statuses[$1.id] ?? .never) }
        return (visited.isEmpty ? Array(places.prefix(24)) : visited).map(\.flagAssetName)
    }

    /// "32 prefectures": how many count, without what they're out of, since people count countries,
    /// and what makes one, differently.
    var countLabel: String {
        counted == 1 ? country.placeNoun : country.divisionLabel.lowercased()
    }

    /// "New prefecture" or "new prefectures", for the new layout's "+3".
    var newCountLabel: String {
        "new " + (newPlaceIDs.count == 1 ? country.placeNoun : country.divisionLabel.lowercased())
    }

    /// "Japan, 32 prefectures": the picture's title in the share sheet, and an email's subject.
    var summary: String {
        "\(country.name), \(counted.formatted()) \(countLabel)"
    }

    /// The levels with places at them, highest first, and how many each has, for the key.
    var levelCounts: [(level: VisitLevel, count: Int)] {
        let tally = statuses.values.reduce(into: [String: Int]()) { $0[$1.id, default: 0] += 1 }
        return ladder.levels.reversed().compactMap { level in tally[level.id].map { (level, $0) } }
    }

    /// The picture's shape, for where it's going: a post, a story, or a wide screen.
    enum Format: String, CaseIterable, Identifiable, Sendable {
        case square, tall, wide

        static let storageKey = "shareFormat"

        var id: Self { self }

        var name: String {
            switch self {
            case .square: "Square"
            case .tall: "Tall"
            case .wide: "Wide"
            }
        }

        /// The picture's size in points. It's drawn at three times this, 1080 pixels on its short side.
        var size: CGSize {
            switch self {
            case .square: CGSize(width: 360, height: 360)
            case .tall: CGSize(width: 360, height: 640)
            case .wide: CGSize(width: 640, height: 360)
            }
        }

        /// The shape that shows a map largest: wide for the World and other wide maps, and tall for
        /// the rest, since a square picture gives its map a band across the middle.
        static func suggested(for map: TravelMap) -> Format {
            let focus = map.focusRect(including: [String]())
            guard focus.height > 0 else { return .tall }
            return focus.width / focus.height >= 1.25 ? .wide : .tall
        }
    }

    /// What colours the places been to, on the map and in the names: their levels, as the app
    /// shows them; their flags, the map wearing each place's flag and each name its flag's stripes;
    /// smartly, each place its own lively colour that suits the design; or the card's one colour.
    enum Colouring: String, CaseIterable, Identifiable, Sendable {
        case levels, flags, smart, plain

        static let storageKey = "shareColouring"

        var id: Self { self }

        var name: String {
            switch self {
            case .levels: "Levels"
            case .flags: "Flags"
            case .smart: "Smart"
            case .plain: "Plain"
            }
        }

        var symbolName: String {
            switch self {
            case .levels: "swatchpalette"
            case .flags: "flag"
            case .smart: "wand.and.sparkles"
            case .plain: "circle.fill"
            }
        }
    }

    /// The card's design, like a League Card's background: its paper, colours and type.
    enum Design: String, CaseIterable, Identifiable, Sendable {
        /// Clean and light, in the app's own greys.
        case paper
        /// Deep blue space with stars, as the welcome's World hangs in, the places glowing.
        case night
        /// An old atlas's plate: cream paper, pale seas and a serif.
        case atlas
        /// Glossy as the app's candy, in a colour of the person's choosing.
        case candy
        /// A tartan in a colour of the person's choosing.
        case plaid
        /// Stripes of the person's own colours, width and angle, as in Aether's Deco.
        case stripes
        /// The place's own flag, or for the World, a patchwork of the flags of the places been to.
        case flag

        static let storageKey = "shareDesign"

        var id: Self { self }

        var name: String {
            switch self {
            case .paper: "Paper"
            case .night: "Night"
            case .atlas: "Atlas"
            case .candy: "Candy"
            case .plaid: "Plaid"
            case .stripes: "Stripes"
            case .flag: "Flag"
            }
        }

        /// Whether the person chooses its colour.
        var usesTint: Bool {
            self == .candy || self == .plaid
        }

        func palette(tint: ShareTint, stripes: ShareStripes) -> ShareCardPalette {
            switch self {
            case .paper: .paper
            case .night: .night
            case .atlas: .atlas
            case .candy: .candy(tint)
            case .plaid: .plaid(tint)
            case .stripes: .stripes(stripes)
            case .flag: .flag
            }
        }
    }
}

/// Numbers that look random but come out the same from the same seed, so smart colours dealt in a
/// shuffled order stay in it.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
