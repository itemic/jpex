import SwiftUI
import UIKit

/// Learn's deck: the places to browse, in list order, and the one being shown. It knows what each
/// place's card holds, its own flag where it has one, its capitals and its codes, and how the
/// places fall into runs by region, for the scrubber's marks, the header and the list to jump
/// from. It's made from a collection alone, so any map can learn with it, not only the quiz's:
/// the World's countries, Japan's prefectures, the EU's members, or just the places in one region.
/// Moving through it is all it does; whoever shows it lights the map, flies the camera and
/// gives the feedback.
@MainActor
@Observable
final class LearnDeck: Identifiable {
    /// A run of places in one region, in the deck's order.
    struct Section: Identifiable, Equatable {
        /// The region, or nil for the single run of a deck not told apart by region.
        var group: DivisionGroup?
        /// The region's ID, empty for the single run.
        var groupID: String
        /// Where the run begins in the deck.
        var start: Int
        var count: Int
        var id: Int { start }
        /// The places it holds, by their positions in the deck.
        var range: Range<Int> { start..<(start + count) }

        /// The region's name, in the language the places are shown in; empty for a run with no region.
        func name(localLanguage: Bool) -> String {
            group?.displayName(localLanguage: localLanguage) ?? ""
        }
    }

    /// A way into Learn on a collection's full map from elsewhere, such as the quiz lobby's Learn
    /// tile: the collection, and the place to start at, such as the first in the region the quiz
    /// was set to. Each is new, so asking again for the same one still opens it.
    struct Request: Equatable {
        var collectionID: String
        /// The place to start at; nil starts at the first.
        var placeID: String?
        var token = UUID()
    }

    /// The collection the places are from, such as the World or Japan.
    let collection: Country
    /// Every place to browse, in list order.
    let places: [AdministrativeDivision]
    /// The places in runs by region where they're told apart by region, otherwise one run of them all.
    let sections: [Section]
    /// The position of the place shown.
    private(set) var index = 0
    /// A place just arrived at from the search, the list or a surprise, and what it was found by,
    /// for its card to pop and light up; cleared once it has.
    private(set) var landing: LearnSearch.Landing?
    /// Each place's capitals, by place ID. Places without one are left out.
    private let capitals: [String: [CapitalCity]]
    /// The kinds of code the cards show, in the order Code offers them.
    private let codeKinds: [MapGame.CodeKind]
    /// Places with a flag of their own, rather than their country's or one they share.
    private let flagPlaceIDs: Set<String>
    /// Each place's position, by place ID, for jumping to a place tapped on the map.
    private let positions: [String: Int]

    /// A deck of places already worked out, such as the quiz's, which knows their capitals, codes
    /// and flags. `showsRegions` tells the places apart by region, where there's more than one;
    /// off, as when the quiz is playing a single region, they're one run.
    init(
        collection: Country, places: [AdministrativeDivision], capitals: [String: [CapitalCity]],
        codeKinds: [MapGame.CodeKind], flagPlaceIDs: Set<String>, showsRegions: Bool = true, startingAt placeID: String? = nil
    ) {
        self.collection = collection
        self.places = places
        self.capitals = capitals
        self.codeKinds = codeKinds
        self.flagPlaceIDs = flagPlaceIDs
        positions = Dictionary(places.enumerated().map { ($1.id, $0) }) { first, _ in first }
        sections = Self.sections(of: places, in: collection, showsRegions: showsRegions)
        if let placeID, let start = positions[placeID] { index = start }
    }

    /// A deck of a collection's places, as its list counts them under the person's rules, such
    /// as the World with or without Taiwan: every one, or those `including` lets in, such as the
    /// ones its map draws or one region's. A country's deck keeps to its own places, leaving out any
    /// from the World listed with it, as its quiz does. Nil where there's nothing to browse.
    convenience init?(
        collection: Country, rules: CountingRules? = nil, including: ((AdministrativeDivision) -> Bool)? = nil,
        startingAt placeID: String? = nil
    ) {
        var counted = rules.flatMap { rules in MapGame.collections(applying: rules).first { $0.id == collection.id } } ?? collection
        if !counted.isOnWorldMap {
            let ownID = counted.countryListID
            counted.groups = counted.groups.compactMap { group in
                var group = group
                group.divisions = group.divisions.filter { $0.countryID == ownID }
                return group.divisions.isEmpty ? nil : group
            }
        }
        let all = counted.divisions
        let places = including.map { all.filter($0) } ?? all
        guard !places.isEmpty else { return nil }
        // A flag shared by several places, such as Australia's on its territories, can't tell
        // them apart, so only a place's very own counts, as in the quiz.
        let flagCounts = Dictionary(grouping: all, by: \.flagAssetName).mapValues(\.count)
        let flagPlaceIDs = places.filter { place in
            flagCounts[place.flagAssetName] == 1 && place.flagAssetName != counted.flagAssetName
                && UIImage(named: place.flagAssetName) != nil
        }.map(\.id)
        let capitals = Dictionary(uniqueKeysWithValues: places.compactMap { place in
            let capitals = CapitalCities.capitals(of: place)
            return capitals.isEmpty ? nil : (place.id, capitals)
        })
        self.init(
            collection: counted, places: places, capitals: capitals, codeKinds: MapGame.codeKinds(of: all),
            flagPlaceIDs: Set(flagPlaceIDs), startingAt: placeID)
    }

    /// The place shown.
    var current: AdministrativeDivision? {
        places.indices.contains(index) ? places[index] : nil
    }

    var count: Int { places.count }

    /// Whether the deck is told apart by region.
    var showsRegions: Bool { sections.count > 1 }

    /// Whether any place has a flag of its own, so lists keep room for one.
    var showsFlags: Bool { !flagPlaceIDs.isEmpty }

    var isAtStart: Bool { index == 0 }
    var isAtEnd: Bool { index + 1 >= places.count }

    // MARK: Moving

    /// Moves on or back through the places, stopping at the first and the last, as a row of cards
    /// does. Returns whether it moved.
    @discardableResult
    func step(by offset: Int) -> Bool {
        jump(to: index + offset)
    }

    /// Jumps to a place by its position, kept within the deck. Returns whether it moved.
    @discardableResult
    func jump(to position: Int) -> Bool {
        guard !places.isEmpty else { return false }
        let clamped = min(max(position, 0), places.count - 1)
        guard clamped != index else { return false }
        index = clamped
        return true
    }

    /// Jumps to a place, such as one tapped on the map. Returns whether it's in the deck.
    @discardableResult
    func jump(to place: AdministrativeDivision) -> Bool {
        jump(toPlaceID: place.id)
    }

    /// Jumps to a place by its ID. Returns whether it's in the deck.
    @discardableResult
    func jump(toPlaceID id: String) -> Bool {
        guard let position = positions[id] else { return false }
        index = position
        return true
    }

    /// Arrives at a place picked from the search, the list or a surprise, and lights up what it was
    /// found by on its card.
    func land(on result: LearnSearch.Result) {
        jump(to: result.place)
        landing = LearnSearch.Landing(placeID: result.place.id, match: result.match)
    }

    /// Once the landing has lit up and faded, so it doesn't light again when scrolled back to.
    func clearLanding() {
        landing = nil
    }

    // MARK: Looking up

    /// Whether a place is in the deck.
    func contains(_ place: AdministrativeDivision) -> Bool {
        positions[place.id] != nil
    }

    /// A place's position in the deck.
    func position(of place: AdministrativeDivision) -> Int? {
        positions[place.id]
    }

    /// The run a position falls in.
    func section(containing position: Int) -> Section? {
        sections.first { $0.range.contains(position) }
    }

    /// The run the place shown is in.
    var currentSection: Section? {
        section(containing: index)
    }

    /// The region a place is in, by name, where the collection has several, whether or not the
    /// deck tells its places apart by them.
    func regionName(of place: AdministrativeDivision, localLanguage: Bool) -> String? {
        guard collection.groups.count > 1 else { return nil }
        return collection.groups.first { $0.id == place.groupID }?.displayName(localLanguage: localLanguage)
    }

    /// The groups of the collection, by ID, for the search.
    var groupsByID: [String: DivisionGroup] {
        Dictionary(collection.groups.map { ($0.id, $0) }) { first, _ in first }
    }

    /// A place's capitals, where they're known.
    func capitals(of place: AdministrativeDivision) -> [CapitalCity] {
        capitals[place.id] ?? []
    }

    /// Every code a place has, in the order Code offers them.
    func codes(of place: AdministrativeDivision) -> [(kind: MapGame.CodeKind, code: String)] {
        let all = MapGame.allCodes(of: place)
        return codeKinds.compactMap { kind in all.first { $0.kind == kind } }
    }

    /// Whether a place has a flag of its own to show.
    func hasOwnFlag(_ place: AdministrativeDivision) -> Bool {
        flagPlaceIDs.contains(place.id)
    }

    /// A place's own flag, by asset name, or nil where it only has its country's or shares one.
    func flag(of place: AdministrativeDivision) -> String? {
        hasOwnFlag(place) ? place.flagAssetName : nil
    }

    /// What a place has of its own to learn, such as Japan's prefectures for the World's Japan,
    /// where there's a map to learn them on, as the person's rules count it: the hook behind
    /// the "Prefectures ›" link on its card.
    static func subcollection(of place: AdministrativeDivision, rules: CountingRules) -> Country? {
        guard let collection = CountryCatalog.collection(for: place), TravelMap.named(collection.id) != nil else { return nil }
        return MapGame.collections(applying: rules).first { $0.id == collection.id }
    }

    /// The places in runs by region, in the deck's order: one run of them all where they aren't
    /// told apart, or only one region turns up.
    private static func sections(of places: [AdministrativeDivision], in collection: Country, showsRegions: Bool) -> [Section] {
        let whole = [Section(group: nil, groupID: "", start: 0, count: places.count)]
        guard showsRegions, collection.groups.count > 1 else { return whole }
        let groups = Dictionary(collection.groups.map { ($0.id, $0) }) { first, _ in first }
        var sections: [Section] = []
        for (index, place) in places.enumerated() {
            if let last = sections.last, last.groupID == place.groupID {
                sections[sections.count - 1].count += 1
            } else {
                sections.append(Section(group: groups[place.groupID], groupID: place.groupID, start: index, count: 1))
            }
        }
        return sections.count > 1 ? sections : whole
    }
}
