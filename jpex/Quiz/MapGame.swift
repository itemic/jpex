import SwiftUI
import UIKit

/// A round of the map quiz, and the choices for the next. Identify lights up a place and Capital
/// names one; you type its name or its capital, a small typo forgiven, or pick it from a list: four
/// dealt, or every one in play like a Sporcle quiz. Flag shows a place's flag to pick its name
/// from a list, and Find gives you a name to tap on the map; Flag and Capital go the other way
/// round too, a name to find the flag of and a capital to name the place of. List All asks for
/// every place at once, typed in any order, and on the World, Everything asks about the states,
/// provinces and regions of the countries in play, drawn onto the World as they come up. There's
/// no score and no lives: a wrong answer just says so, and you try again or ask to be shown. The
/// lobby's Learn tile leaves the quiz for the collection's full map, to browse its places there.
@MainActor
@Observable
final class MapGame: Identifiable {
    let collection: Country
    /// The map the board draws: on the World's map, turned so the place in view sits whole when
    /// the map's edge would cut it in two, as it would Russia or Fiji.
    private(set) var map: TravelMap
    /// The map as it rests, centred where the person keeps the World.
    private let homeMap: TravelMap
    /// Every place on the map that can come up, in list order.
    let places: [AdministrativeDivision]
    /// Places with a flag of their own, for Flags. Places shown with their country's flag are left out.
    let flagPlaces: [AdministrativeDivision]
    /// Each place's capitals, by place ID, for Capitals. Places without one are left out.
    let capitals: [String: [CapitalCity]]
    private let flagPlaceIDs: Set<String>
    /// The kinds of code these places have, for Code.
    let codeKinds: [CodeKind]
    /// How the map was projected from longitude and latitude, for placing cities on it. Nil for
    /// countries' own maps, which come already drawn.
    let projection: MapProjection?
    let center: MapCenter
    /// The longitude at the middle of the map the board draws: the usual centre's, or where the
    /// World has turned to keep a place whole.
    private(set) var centerLongitude: Double
    /// The place each region on the map stands for: its own outline, or for a territory that
    /// doesn't count as a country, the country it belongs to.
    let regionPlaces: [String: AdministrativeDivision]
    /// The regions standing for each place, by place ID.
    let placeRegions: [String: [String]]
    /// Regions on a country's map listed with it but not quizzed with it, such as Taiwan on
    /// China's while it counts as part of China: drawn faded, veiled, out of play.
    let fadedRegionIDs: Set<String>
    /// The main body of each place on the map, for the camera to frame, by place ID. On a group
    /// of countries' map, its near misses are framed too.
    private(set) var frames: [String: CGRect]
    /// For a group of countries, such as the EU, the countries outside it that Member? asks about
    /// alongside its members: its neighbours, and famous non-members such as Norway, in list order.
    private let collectionNearMisses: [AdministrativeDivision]
    /// The regions standing for each near miss, by place ID.
    private let nearMissRegions: [String: [String]]
    /// The near miss each region stands for, by region ID.
    private let nearMissPlaces: [String: AdministrativeDivision]
    /// On the World, the groups of countries that can be chosen as its region, such as the EU or
    /// one the person made: their own first, then the World's. Empty on every other map.
    let groupScopes: [Country]
    /// Near misses for each group chosen as the World's region, worked out as they're first needed.
    @ObservationIgnored private var groupNearMisses: [String: [AdministrativeDivision]] = [:]
    private let defaults: UserDefaults
    /// Each place's outline once it's been worked out, by place ID; nil where it has too little shape.
    @ObservationIgnored private var outlines: [String: Path?] = [:]
    /// In a round of Everything, the countries whose own places are drawn onto the World for it,
    /// such as Germany's states, by their lists, and those places' regions and the place each
    /// stands for, which come before the World's own. Empty otherwise.
    private var roundCountries: [Country] = []
    private var roundRegionPlaces: [String: AdministrativeDivision] = [:]
    private var roundPlaceRegions: [String: [String]] = [:]
    /// In List All, the places named so far, the newest last.
    private(set) var named: [AdministrativeDivision] = []

    var mode: MapGameMode {
        didSet { defaults.set(mode.rawValue, forKey: Key.mode) }
    }
    var length: MapGameLength {
        didSet { defaults.set(length.rawValue, forKey: Key.length) }
    }
    /// How many a round of the person's own size asks about, at most every place in play.
    var customCount: Int {
        didSet { defaults.set(customCount, forKey: Key.customCount) }
    }
    /// How the modes that can be are answered: typed, four to pick from, or every one in play.
    /// One choice for them all, set in the lobby; Flag, which can't be typed, picks from all instead.
    var answerStyle: AnswerStyle {
        didSet { defaults.set(answerStyle.rawValue, forKey: Key.answerStyle) }
    }
    /// Whether typing offers the ten names nearest what's typed, to pick from as you go.
    var autoFill: Bool {
        didSet { defaults.set(autoFill, forKey: Key.autoFill) }
    }
    /// In Code, which codes are shown: ISO codes, internet domains, calling codes and so on.
    var codeKind: CodeKind {
        didSet { defaults.set(codeKind.rawValue, forKey: Key.codeKind) }
    }
    /// In Outline, whether each shape comes turned at an angle, which makes it harder.
    var outlineRotated: Bool {
        didSet { defaults.set(outlineRotated, forKey: Key.outlineRotated) }
    }
    /// In Map, whether the borders are drawn. Hidden, a place to identify is marked with a dot on
    /// plain land, as Dot plays, and a place to find has to be found on it.
    var showsBorders: Bool {
        didSet { defaults.set(showsBorders, forKey: Key.showsBorders) }
    }
    /// Any time limit for the whole round, in minutes, one of `roundMinuteChoices`; nil for none.
    var roundMinutes: Int? {
        didSet { defaults.set(roundMinutes ?? 0, forKey: Key.roundMinutes) }
    }
    /// Any time limit for each question, in seconds, one of `questionSecondChoices`; nil for none.
    /// It can run alongside one for the round.
    var questionSeconds: Int? {
        didSet { defaults.set(questionSeconds ?? 0, forKey: Key.questionSeconds) }
    }
    static let roundMinuteChoices = [3, 5, 10]
    static let questionSecondChoices = [15, 30, 60]
    /// The group of places to play, such as Kantō or Europe. Nil plays every place.
    var scopeID: String?
    /// The set of places people usually mean, such as the fifty states, played whole in place of
    /// ten or all; nil for those. Kept for each list, since each has sets of its own.
    var placeSetID: String? {
        didSet { defaults.set(placeSetID, forKey: Key.placeSet(collection.id)) }
    }

    private(set) var phase = Phase.lobby
    private(set) var questions: [AdministrativeDivision] = []
    /// With four to pick from, what's dealt for each question, by the ID of the place in question.
    private var deals: [String: [Choice]] = [:]
    /// In Outline with Rotated on, the angle each shape comes at, in degrees, by place ID.
    private(set) var rotations: [String: Double] = [:]
    private(set) var index = 0
    /// How each place asked about this round went, by place ID.
    private(set) var outcomes: [String: Outcome] = [:]
    /// The wrong answers given for this question, newest last.
    private(set) var wrongGuesses: [AdministrativeDivision] = []
    /// How many typed answers named nothing in play, for this question.
    private(set) var wrongTyped = 0
    /// In Capital, the cities in the place in question picked or typed wrongly, as its capital.
    private(set) var wrongDecoys: [String] = []
    /// A gentle word about the last typed answer, such as that a city typed isn't the capital.
    private(set) var typedNote: String?
    /// The right answer's spelling, when a typed answer was let through with a typo.
    private(set) var correction: String?
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    /// When this round's time runs out, under a time limit for the round.
    private(set) var deadline: Date?
    /// When this question's time runs out, under a time limit for each question; nil once it's answered.
    private(set) var questionDeadline: Date?
    /// The places whose question ran out of time this round, by ID.
    private(set) var timedOutIDs: Set<String> = []
    /// In Member?, whether this question was answered in or out; nil until it's answered.
    private(set) var memberGuess: Bool?
    /// Whether this round ended because its time ran out.
    private(set) var isTimeUp = false

    init(
        collection: Country, map: TravelMap, regionOwners: [String: String] = [:], outsiders: [AdministrativeDivision] = [],
        faded: Set<String> = [], groupScopes: [Country] = [], projection: MapProjection? = nil, center: MapCenter = .current,
        defaults: UserDefaults = .standard
    ) {
        self.collection = collection
        self.map = map
        homeMap = map
        self.groupScopes = groupScopes
        centerLongitude = center.longitude
        self.projection = projection
        self.center = center
        self.defaults = defaults
        let regions = Dictionary(map.regions.map { ($0.id, $0) }) { first, _ in first }
        let divisions = Dictionary(collection.divisions.map { ($0.id, $0) }) { first, _ in first }
        var regionPlaces: [String: AdministrativeDivision] = [:]
        var placeRegions: [String: [String]] = [:]
        for place in collection.divisions where regions[place.id] != nil {
            regionPlaces[place.id] = place
            placeRegions[place.id, default: []].append(place.id)
        }
        // Territories that don't count as countries are drawn, and answered, as their country.
        for (regionID, ownerID) in regionOwners.sorted(by: { $0.key < $1.key })
        where regions[regionID] != nil && regionPlaces[regionID] == nil {
            guard let owner = divisions[ownerID] else { continue }
            regionPlaces[regionID] = owner
            placeRegions[ownerID, default: []].append(regionID)
        }
        // Countries outside a group, drawn the same way, for Member? to ask about.
        let outsiderIDs = Dictionary(outsiders.map { ($0.id, $0) }) { first, _ in first }
        var outsiderPlaces: [String: AdministrativeDivision] = [:]
        var outsiderRegions: [String: [String]] = [:]
        for place in outsiders where regions[place.id] != nil && regionPlaces[place.id] == nil {
            outsiderPlaces[place.id] = place
            outsiderRegions[place.id, default: []].append(place.id)
        }
        for (regionID, ownerID) in regionOwners.sorted(by: { $0.key < $1.key })
        where regions[regionID] != nil && regionPlaces[regionID] == nil && outsiderPlaces[regionID] == nil {
            guard let owner = outsiderIDs[ownerID] else { continue }
            outsiderPlaces[regionID] = owner
            outsiderRegions[ownerID, default: []].append(regionID)
        }
        let frames = Self.frames(of: placeRegions.merging(outsiderRegions, uniquingKeysWith: { first, _ in first }), in: map)
        self.regionPlaces = regionPlaces
        self.placeRegions = placeRegions
        fadedRegionIDs = faded.filter { regions[$0] != nil && regionPlaces[$0] == nil }
        self.frames = frames
        let places = collection.divisions.filter { placeRegions[$0.id] != nil }
        self.places = places
        nearMissPlaces = outsiderPlaces
        nearMissRegions = outsiderRegions
        collectionNearMisses = Self.nearMisses(
            famous: collection.worldGroup?.famousNonMembers ?? [], members: places,
            among: outsiders.filter { outsiderRegions[$0.id] != nil }, frames: frames)
        codeKinds = Self.codeKinds(of: places)
        // A flag shared by several places, such as Australia's on its territories, can't tell them apart.
        let flagCounts = Dictionary(grouping: places, by: \.flagAssetName).mapValues(\.count)
        let flagPlaces = places.filter { place in
            flagCounts[place.flagAssetName] == 1 && place.flagAssetName != collection.flagAssetName
                && UIImage(named: place.flagAssetName) != nil
        }
        self.flagPlaces = flagPlaces
        flagPlaceIDs = Set(flagPlaces.map(\.id))
        capitals = Dictionary(uniqueKeysWithValues: places.compactMap { place in
            let capitals = CapitalCities.capitals(of: place)
            return capitals.isEmpty ? nil : (place.id, capitals)
        })
        mode = defaults.string(forKey: Key.mode).flatMap(MapGameMode.init(rawValue:)) ?? .nameIt
        length = defaults.string(forKey: Key.length).flatMap(MapGameLength.init(rawValue:)) ?? .ten
        customCount = defaults.object(forKey: Key.customCount) == nil ? 20 : max(defaults.integer(forKey: Key.customCount), 1)
        autoFill = defaults.bool(forKey: Key.autoFill)
        placeSetID = defaults.string(forKey: Key.placeSet(collection.id))
        answerStyle = Self.storedAnswerStyle(in: defaults)
        codeKind = defaults.string(forKey: Key.codeKind).flatMap(CodeKind.init(rawValue:)) ?? .iso
        outlineRotated = defaults.bool(forKey: Key.outlineRotated)
        // Dot was a mode of its own before it became Map with the borders hidden.
        showsBorders = defaults.object(forKey: Key.showsBorders) == nil
            ? defaults.string(forKey: Key.mode) != MapGameMode.dot.rawValue : defaults.bool(forKey: Key.showsBorders)
        (roundMinutes, questionSeconds) = Self.storedTimeLimits(in: defaults)
        // Dot used to offer its borders; it's always a plain map now.
        defaults.removeObject(forKey: Key.retiredDotBorders)
        // Quiz and Learn used to be a choice of their own; Learn is a tile beside the quizzes now.
        defaults.removeObject(forKey: Key.retiredActivity)
    }

    /// A quiz on a collection's map, or nil when it has none. The World lies flat on Mercator's
    /// rectangle, so its edges meet and it can wrap around as it's dragged sideways. A group of
    /// countries, such as the EU, plays on the same World map, framed on its members, with the
    /// countries outside it veiled, and kept to hand for Member?.
    static func make(for collection: Country, rules: CountingRules) -> MapGame? {
        // A country is quizzed on its own places only. One listed with it while it isn't counted
        // as a country of its own, as Taiwan is with China, is still a country in the quiz, and is
        // quizzed with the World: China keeps its plates, and Taiwan its country's codes. It stays
        // on the map, faded, as in the list; counted as a country, it's left off, as in the list.
        let listed = collection
        let collection = collection.isOnWorldMap ? collection : collection.keepingOwnPlaces
        let faded = Set(listed.divisions.map(\.id)).subtracting(collection.divisions.map(\.id))
        let isOnWorldMap = collection.isOnWorldMap
        // The seas lie flat in the person's projection, as the World's list does, but never on the
        // globe, which would hide half of them.
        let projection: MapProjection = if isOnWorldMap {
            .mercator
        } else {
            collection.id == CountryCatalog.seas.id && MapProjection.current == .globe ? .standard : .current
        }
        guard let map = TravelMap.named(collection.id, projection: projection) else { return nil }
        let owners = isOnWorldMap ? CountryCatalog.mapRegionOwners(applying: rules) : [:]
        var outsiders: [AdministrativeDivision] = []
        if collection.isGroupOfCountries {
            let members = Set(collection.divisions.map(\.id))
            let codes = Set(collection.divisions.map(\.abbreviation))
            outsiders = CountryCatalog.world(applying: rules).divisions.filter {
                !members.contains($0.id) && !codes.contains($0.abbreviation)
            }
        }
        // The World's region can be a group of countries too, such as the EU.
        let groupScopes = collection.id == CountryCatalog.world.id ? groupCollections(applying: rules) : []
        return MapGame(
            collection: collection, map: map, regionOwners: owners, outsiders: outsiders, faded: faded,
            groupScopes: groupScopes, projection: isOnWorldMap ? .mercator : nil)
    }

    /// The collections there's a map to quiz on, in the sidebar's sections, with groups of
    /// countries, such as the EU, in their own section just after the World, the person's own first.
    static func sections(applying rules: CountingRules) -> [CollectionSection] {
        var sections: [CollectionSection] = CountryCatalog.sections(applying: rules).compactMap { section in
            var section = section
            // A country listed at more than one level is quizzed at each, such as France by its
            // regions and by its departments.
            section.countries = section.countries.flatMap(CountryCatalog.levels(of:))
            section.countries.removeAll { collection in
                ![CountryCatalog.world.id, CountryCatalog.seas.id].contains(collection.id)
                    && Bundle.main.url(forResource: "map_\(collection.id)", withExtension: "json") == nil
            }
            return section.countries.isEmpty ? nil : section
        }
        // Groups the person has hidden from the sidebar stay out of the choice here too.
        let hidden = HiddenWorldGroups.current
        sections.insert(
            CollectionSection(
                title: CollectionSection.worldGroupsTitle,
                countries: groupCollections(applying: rules).filter { !hidden.isHidden($0.id) }),
            at: min(1, sections.count))
        return sections
    }

    /// Every collection there's a map to quiz on, groups of countries included.
    static func collections(applying rules: CountingRules) -> [Country] {
        CountryCatalog.countries(applying: rules) + groupCollections(applying: rules)
    }

    /// Every group of countries, the person's own first, then the World's.
    private static func groupCollections(applying rules: CountingRules) -> [Country] {
        (CustomWorldGroups.shared.collections(applying: rules) + WorldGroup.collections).map { $0.hiding(rules.hiddenStates) }
    }

    /// Where a city sits on the map, when the map was projected here and the city's place is known.
    func mapPoint(of city: CapitalCity) -> CGPoint? {
        guard let projection, let location = city.location else { return nil }
        // Longitudes are measured from the map's centre, wrapping around at its edges.
        var longitude = location.x - centerLongitude
        if longitude < -180 { longitude += 360 }
        if longitude > 180 { longitude -= 360 }
        return projection.project(CGPoint(x: longitude, y: location.y))
    }

    /// The main body of each place, by place ID, from the regions standing for it on a map.
    private static func frames(of placeRegions: [String: [String]], in map: TravelMap) -> [String: CGRect] {
        let regions = Dictionary(map.regions.map { ($0.id, $0) }) { first, _ in first }
        var frames: [String: CGRect] = [:]
        for (placeID, regionIDs) in placeRegions {
            frames[placeID] = regions[placeID]?.coreBounds
                ?? regionIDs.compactMap { regions[$0]?.coreBounds }.reduce(CGRect.null) { $0.union($1) }
        }
        return frames
    }

    // MARK: Turning the World

    /// The longitude the World rests at, where the person keeps it.
    var homeLongitude: Double { center.longitude }

    /// Where the World would need to turn for a place to sit whole, clear of the map's edge, as
    /// the list's map does before diving into a country; nil where it already does, or on a map
    /// that isn't the World's.
    func wholeLongitude(for placeID: String) -> Double? {
        guard collection.isOnWorldMap, projection == .mercator, !map.isSphere,
              let edges = map.outline?.boundingRect, edges.width > 0 else { return nil }
        var degrees = Set<Int>()
        for regionID in mainRegions(of: placeID) {
            guard let region = map.region(id: regionID) else { continue }
            var previous: Double?
            func cover(_ point: CGPoint) {
                let longitude = MapJourney.normalized(centerLongitude + (point.x - edges.midX) / edges.width * 360)
                // Along an edge, every degree between its ends; an edge never spans half the Earth.
                if let previous, abs(longitude - previous) < 90 {
                    for degree in Int(min(previous, longitude).rounded(.down))...Int(max(previous, longitude).rounded(.down)) {
                        degrees.insert(degree)
                    }
                } else {
                    degrees.insert(Int(longitude.rounded(.down)))
                }
                previous = longitude
            }
            region.path.forEach { element in
                switch element {
                case .move(let point): previous = nil; cover(point)
                case .line(let point), .quadCurve(let point, _), .curve(let point, _, _): cover(point)
                case .closeSubpath: previous = nil
                }
            }
        }
        let best = MapJourney.bestLongitude(covering: degrees, from: centerLongitude, onGlobe: false)
        return MapJourney.turn(from: centerLongitude, to: best) == 0 ? nil : best
    }

    /// Settles the World at a new centre, in full detail, its places' frames worked out afresh for it.
    func settleTurn(at longitude: Double) {
        let isHome = MapJourney.turn(from: homeLongitude, to: longitude) == 0
        guard MapJourney.turn(from: centerLongitude, to: longitude) != 0 else { return }
        guard var turned = isHome ? homeMap : Geography.world?.map(.mercator, centerLongitude: longitude) else { return }
        turned.focusOverride = homeMap.focusOverride
        centerLongitude = isHome ? homeLongitude : MapJourney.normalized(longitude)
        // A round of Everything's countries are drawn onto the World afresh at its new centre.
        addRoundRegions(to: &turned)
        map = turned
        groupNearMisses = [:]
        frames = currentFrames(in: turned)
    }

    /// The main body of every place on a map, near misses and a round of Everything's places included.
    private func currentFrames(in map: TravelMap) -> [String: CGRect] {
        let regions = placeRegions
            .merging(nearMissRegions, uniquingKeysWith: { first, _ in first })
            .merging(roundPlaceRegions, uniquingKeysWith: { _, round in round })
        return Self.frames(of: regions, in: map)
    }

    // MARK: Choices

    /// The groups to choose between, such as the regions of Japan, when there's more than one.
    var scopes: [DivisionGroup] {
        let groups = collection.groups.filter { group in group.divisions.contains { placeRegions[$0.id] != nil } }
        return groups.count > 1 ? groups : []
    }

    var scope: DivisionGroup? {
        scopeID.flatMap { id in collection.groups.first { $0.id == id } }
    }

    /// On the World, the group of countries chosen as its region, such as the EU.
    var scopedGroup: Country? {
        scopeID.flatMap { id in groupScopes.first { $0.id == id } }
    }

    /// The group of countries in play: the one this quiz is for, such as the EU, or on the World,
    /// the one chosen as its region.
    var countryGroup: Country? {
        collection.isGroupOfCountries ? collection : scopedGroup
    }

    /// The group in play as it sits in a sentence, such as "the G20", "NATO" or "Trips with Mum".
    var groupNameInSentence: String? {
        countryGroup.map { $0.worldGroup?.nameInSentence ?? $0.name }
    }

    /// The region chosen, as its pill shows it, such as Kantō, Europe, or for a group of countries
    /// on the World, its short name, such as EU; nil for everywhere.
    func scopeName(localLanguage: Bool) -> String? {
        if let group = scopedGroup { return group.worldGroup?.shortName ?? group.name }
        return scope?.displayName(localLanguage: localLanguage)
    }

    /// The members of the group chosen as the World's region, by place ID; nil for any other region.
    private var scopedMemberIDs: Set<String>? {
        scopedGroup.map { Set($0.divisions.map(\.id)) }
    }

    /// Whether a mode has places to ask about, as Flags doesn't where no place has a flag of its
    /// own, Member? only for a group of countries with near misses to ask about too, and
    /// Everything only on the World.
    func isAvailable(_ mode: MapGameMode) -> Bool {
        switch mode {
        case .member: countryGroup != nil && !nearMisses.isEmpty && !pool(for: .member).isEmpty
        case .everything: collection.id == CountryCatalog.world.id && !everythingPool().isEmpty
        default: !pool(for: mode).isEmpty
        }
    }

    /// Whether a place is in the collection: for a group of countries, whether it's a member.
    func isMember(_ place: AdministrativeDivision) -> Bool {
        if let scopedMemberIDs { return scopedMemberIDs.contains(place.id) }
        return placeRegions[place.id] != nil
    }

    /// For a group of countries, the countries outside it that Member? asks about alongside its
    /// members: its neighbours, and famous non-members such as Norway, in list order.
    var nearMisses: [AdministrativeDivision] {
        guard let group = scopedGroup, let memberIDs = scopedMemberIDs else { return collectionNearMisses }
        if let misses = groupNearMisses[group.id] { return misses }
        let members = places.filter { memberIDs.contains($0.id) }
        let codes = Set(members.map(\.abbreviation))
        let outsiders = places.filter { !memberIDs.contains($0.id) && !codes.contains($0.abbreviation) }
        let misses = Self.nearMisses(
            famous: group.worldGroup?.famousNonMembers ?? [], members: members, among: outsiders, frames: frames)
        groupNearMisses[group.id] = misses
        return misses
    }

    /// The place a region stands for: a place in play, or one of a group's near misses. A place's
    /// own outline has the place's ID, so this finds a place by its ID too.
    func place(id: String) -> AdministrativeDivision? {
        roundRegionPlaces[id] ?? regionPlaces[id] ?? nearMissPlaces[id]
    }

    /// Whether a place is drawn with an outline of its own, rather than only through others.
    func hasOwnRegion(_ placeID: String) -> Bool {
        roundPlaceRegions[placeID]?.contains(placeID) == true || placeRegions[placeID]?.contains(placeID) == true
            || nearMissRegions[placeID]?.contains(placeID) == true
    }

    /// The places a round draws from.
    var scopedPlaces: [AdministrativeDivision] {
        pool(for: mode)
    }

    /// Every place in the chosen group, or on the whole map, and in the chosen set: what twinkles
    /// in the lobby, and where Learn, opened from it, starts.
    var placesInPlay: [AdministrativeDivision] {
        pool(for: .nameIt)
    }

    /// Every place in the chosen group, or on the whole map, whatever the set: what All plays.
    var placesInScope: [AdministrativeDivision] {
        pool(for: .nameIt, inSet: false)
    }

    /// The sets of places people usually mean, such as the fifty states, among those in the
    /// chosen group, each only where it leaves some of them out, and only where there are more than
    /// ten to choose how many from.
    var placeSets: [PlaceSet] {
        let places = placesInScope
        return places.count > 10 ? PlaceSet.sets(for: collection.id, among: places) : []
    }

    /// The chosen set, while the chosen group holds it.
    var placeSet: PlaceSet? {
        placeSetID.flatMap { id in placeSets.first { $0.id == id } }
    }

    /// How many to play: ten, a set of places, all of them, or as many as the person chooses.
    enum RoundSize: Hashable {
        case ten
        case set(String)
        case all
        case custom
    }

    /// How many to play, as one choice. A set the chosen group doesn't hold plays all of the group.
    var roundSize: RoundSize {
        get {
            if let placeSetID { return placeSet == nil ? .all : .set(placeSetID) }
            return switch length {
            case .ten: .ten
            case .every: .all
            case .custom: .custom
            }
        }
        set {
            switch newValue {
            case .ten: placeSetID = nil; length = .ten
            case .set(let id): placeSetID = id
            case .all: placeSetID = nil; length = .every
            case .custom: placeSetID = nil; length = .custom
            }
        }
    }

    /// How many questions a round asks, from how many places there are to ask about. List All asks
    /// about every one, and Everything about ten, which keeps what it draws onto the World light.
    private func questionCount(from available: Int) -> Int {
        switch mode {
        case .listAll: available
        case .everything: min(Self.everythingRoundSize, available)
        default: placeSetID == nil ? length.count(from: available, custom: customCount) : available
        }
    }

    /// How many places a round of Everything asks about.
    static let everythingRoundSize = 10

    /// Whether the round's size can be chosen for a mode: only where there are more than ten
    /// places, and not for List All, which plays every place, nor for Everything, which plays ten.
    func choosesRoundSize(for mode: MapGameMode) -> Bool {
        mode != .listAll && mode != .everything && placesInScope.count > 10
    }

    /// The answer style a mode is played with just now, from the one chosen for them all: Flag,
    /// which can't be typed, picks from the list instead, and Everything from four.
    func shownAnswerStyle(for mode: MapGameMode) -> AnswerStyle? {
        switch answerMethod(for: mode) {
        case .typing: mode.answerStyles.contains(.type) ? .type : nil
        case .four: .four
        case .list: .all
        case .map, .inOrOut: nil
        }
    }

    /// The regions that light up for a place: its own outline, leaving out the territories that
    /// only take its colour, such as France's overseas departments, so a spotlight stays on the
    /// country itself. A place drawn only through others keeps them all.
    func mainRegions(of placeID: String) -> [String] {
        guard let regions = roundPlaceRegions[placeID] ?? placeRegions[placeID] ?? nearMissRegions[placeID] else { return [] }
        return regions.contains(placeID) ? [placeID] : regions
    }

    /// The main body of a place's own outline, for a spotlight to keep to, leaving out far-flung
    /// islands drawn as part of it. Nil where the place is drawn only through others.
    func mainBody(of placeID: String) -> CGRect? {
        hasOwnRegion(placeID) ? frames[placeID] : nil
    }

    // MARK: Codes

    /// The kinds of code Code can show. The last one played is saved by these names, so keep them
    /// unchanged.
    enum CodeKind: String, CaseIterable, Identifiable {
        /// Two letters, such as DE, or a subdivision's own, such as CA for California.
        case iso
        /// An internet domain, such as .jp.
        case domain
        /// An international calling code, such as +81, or a Japanese prefecture's or a Korean
        /// province's area code, such as 03 for Tokyo.
        case phone
        /// The letters on the oval sticker cars carry abroad, such as D or CH.
        case car
        /// The letters a country competes under at the Olympics, such as JPN or SUI.
        case olympic
        /// The letters a national football team plays under, FIFA's code for it, such as GER, or
        /// for the United Kingdom, its four teams' ENG, SCO, WAL and NIR.
        case fifa
        /// The letter a Polish voivodeship's or a Czech region's number plates begin with, such as W
        /// for Masovia. It once took in China's characters, which are their short names now.
        case plate
        /// The one character a Chinese province, region or municipality goes by, its 简称, as its
        /// number plates begin: 京 for Beijing, 粤 for Guangdong.
        case shortName
        /// The number a place goes by, as French departments' and Japanese prefectures' do, such as
        /// 75 for Paris or 13 for Tokyo: on post codes, number plates and forms.
        case number
        /// The letters an aircraft's registration begins with, such as JA for Japan or N for the
        /// United States.
        case aircraft
        /// The letters a place's airports' ICAO codes begin with, such as RJ for Japan's, as in RJTT
        /// for Haneda, or K for the United States', as in KJFK.
        case airport
        /// The ISO 4217 code of a place's money, such as JPY or CHF.
        case currency
        /// The digit an Australian state's or territory's postcodes begin with, such as 2 for New
        /// South Wales.
        case postcode
        /// The time zone a country's capital keeps today, by its offset from UTC, such as UTC+9.
        case timeZone

        var id: Self { self }

        var name: String {
            switch self {
            case .iso: "ISO"
            case .domain: "Domain"
            case .phone: "Phone"
            case .car: "Car"
            case .olympic: "Olympic"
            case .fifa: "FIFA"
            case .plate: "Plate"
            case .shortName: "Short name"
            case .aircraft: "Aircraft"
            case .airport: "ICAO airport"
            case .currency: "Currency"
            case .number: "Number"
            case .postcode: "Postcode"
            case .timeZone: "Time zone"
            }
        }

        var summary: String {
            switch self {
            case .iso: "ISO codes"
            case .domain: "Domains"
            case .phone: "Phone codes"
            case .car: "Car codes"
            case .olympic: "Olympic codes"
            case .fifa: "FIFA codes"
            case .plate: "Number plates"
            case .shortName: "Short names"
            case .aircraft: "Aircraft prefixes"
            case .airport: "ICAO airport codes"
            case .currency: "Currencies"
            case .number: "Numbers"
            case .postcode: "Postcodes"
            case .timeZone: "Time zones"
            }
        }

        /// Its symbol, beside the code in Learn.
        var symbolName: String {
            switch self {
            case .iso: "tag"
            case .domain: "globe"
            case .phone: "phone"
            case .car: "car"
            case .olympic: "medal"
            case .fifa: "soccerball"
            case .plate: "licenseplate"
            case .shortName: "character.textbox"
            case .aircraft: "airplane"
            case .airport: "airplane.departure"
            case .currency: "banknote"
            case .number: "number"
            case .postcode: "envelope"
            case .timeZone: "clock"
            }
        }

        /// What VoiceOver calls it, before the code itself.
        var spokenName: String {
            switch self {
            case .iso: "ISO"
            case .domain: "domain"
            case .phone: "phone"
            case .car: "car"
            case .olympic: "Olympic"
            case .fifa: "FIFA"
            case .plate: "plate"
            case .shortName: "short name"
            case .aircraft: "aircraft"
            case .airport: "ICAO airport"
            case .currency: "currency"
            case .number: "number"
            case .postcode: "postcode"
            case .timeZone: "time zone"
            }
        }

        /// The question asked about a code of this kind, such as "Identify the place from this
        /// ISO code"; the code sits just beneath, so it isn't repeated. Several codes at once, as a
        /// country's airports or planes can have, are asked about as these.
        func question(isSeveral: Bool = false) -> String {
            let this = isSeveral ? "these" : "this"
            let name = switch self {
            case .iso: isSeveral ? "ISO codes" : "ISO code"
            case .domain: isSeveral ? "internet domains" : "internet domain"
            case .phone: isSeveral ? "dialling codes" : "dialling code"
            case .car: isSeveral ? "international vehicle registration codes" : "international vehicle registration code"
            case .olympic: isSeveral ? "Olympic codes" : "Olympic code"
            case .fifa: isSeveral ? "FIFA codes" : "FIFA code"
            case .plate: isSeveral ? "licence plate codes" : "licence plate code"
            case .shortName: isSeveral ? "short names" : "short name"
            case .aircraft: isSeveral ? "aircraft registration prefixes" : "aircraft registration prefix"
            case .airport: isSeveral ? "ICAO airport prefixes" : "ICAO airport prefix"
            case .currency: isSeveral ? "currency codes" : "currency code"
            case .number: isSeveral ? "numbers" : "number"
            case .postcode: isSeveral ? "postcode prefixes" : "postcode prefix"
            case .timeZone: isSeveral ? "time zones" : "time zone"
            }
            return "Identify the place from \(this) \(name)"
        }

        /// What's asked about a place in Code the other way round, before its name, such as "ISO
        /// code of" or "Calling code of".
        var placeQuestion: String {
            switch self {
            case .iso: "ISO code of"
            case .domain: "Domain of"
            case .phone: "Calling code of"
            case .car: "Car sticker of"
            case .olympic: "Olympic code of"
            case .fifa: "FIFA code of"
            case .plate: "Number plates of"
            case .shortName: "Short name of"
            case .number: "Number of"
            case .aircraft: "Aircraft prefix of"
            case .airport: "ICAO airport prefix of"
            case .currency: "Currency of"
            case .postcode: "Postcodes of"
            case .timeZone: "Time zone of"
            }
        }

        /// The kind standing in for it where places don't have it: China's short names for plates,
        /// which they were played as before, and plates for short names.
        fileprivate var counterpart: CodeKind? {
            switch self {
            case .plate: .shortName
            case .shortName: .plate
            default: nil
            }
        }
    }

    /// The kinds of code these places have, each only where it tells at least two of them apart,
    /// so a round never hangs on one code, as the euro would in the eurozone. For the World's
    /// countries, ISO codes, domains, calling codes, currencies, Olympic and FIFA codes, car
    /// stickers, aircraft prefixes and airports, the two sports' codes side by side; for a
    /// country's places, ISO codes wherever they read as codes rather than numbers, and any of
    /// their own: China's short names, Polish and Czech plates, French and Japanese numbers,
    /// Japanese and Korean area codes, the first digit of Australia's postcodes, and the UK's
    /// nations' football teams.
    static func codeKinds(of places: [AdministrativeDivision]) -> [CodeKind] {
        let kinds: [CodeKind]
        if places.contains(where: { $0.countryID == CountryCatalog.world.id }) {
            kinds = [.iso, .domain, .phone, .currency, .timeZone, .olympic, .fifa, .car, .aircraft, .airport]
        } else {
            let readable = !places.isEmpty && places.allSatisfy { place in
                (2...3).contains(place.abbreviation.count) && place.abbreviation.allSatisfy(\.isLetter)
            }
            kinds = (readable ? [.iso] : []) + [.shortName, .plate, .number, .phone, .postcode, .fifa]
        }
        return kinds.filter { kind in
            let codes = places.compactMap { lookUpCode(of: $0, kind: kind) }
            // Numbers tell places apart only where every one has one, as France's departments do
            // and its regions, all but the overseas ones, don't.
            if kind == .number, codes.count < places.count { return false }
            return Set(codes).count > 1
        }
    }

    /// Countries whose first-level places are widely known by number: France's departments, on
    /// post codes and older number plates, and Japan's prefectures.
    private static let numberedCountries: Set<String> = ["FR", "JP"]

    /// The kind of code shown: the one chosen; where these places don't have it, the kind standing
    /// in for it, as China's short names do for plates; otherwise the first they have.
    var shownCodeKind: CodeKind {
        let kinds = codeKinds
        if kinds.contains(codeKind) { return codeKind }
        if let counterpart = codeKind.counterpart, kinds.contains(counterpart) { return counterpart }
        return kinds.first ?? .iso
    }

    /// A place's code of the kind shown, such as "DE", ".de" or "+49"; nil where it has none.
    func code(of place: AdministrativeDivision) -> String? {
        code(of: place, kind: shownCodeKind)
    }

    /// A place's code of a kind, such as "DE", ".de", "+49", "D" or "GER"; nil where it has none.
    func code(of place: AdministrativeDivision, kind: CodeKind) -> String? {
        guard codeKinds.contains(kind) else { return nil }
        return Self.lookUpCode(of: place, kind: kind)
    }

    /// Australia's states and territories as ISO 3166-2 lists them.
    private static let australianStatesAndTerritories: Set<String> = ["NSW", "QLD", "SA", "TAS", "VIC", "WA", "ACT", "NT"]

    /// Every code a place has, whether or not any quiz asks about it, such as for the Atlas, which
    /// shows a country's card without a quiz.
    static func allCodes(of place: AdministrativeDivision) -> [(kind: CodeKind, code: String)] {
        CodeKind.allCases.compactMap { kind in lookUpCode(of: place, kind: kind).map { (kind, $0) } }
    }

    /// A place's code of a kind, whether or not these places are quizzed on it; nil where it has none.
    private static func lookUpCode(of place: AdministrativeDivision, kind: CodeKind) -> String? {
        let isWorld = place.countryID == CountryCatalog.world.id
        let country = place.countryID
        let code = place.abbreviation
        switch kind {
        case .iso:
            // Northern Cyprus's code is the app's own, not ISO's; so are Jervis Bay's and those of
            // Australia's external territories, which ISO doesn't list among its states and territories.
            if code == "XC" { return nil }
            if country == "AU", !australianStatesAndTerritories.contains(code) { return nil }
            return code.uppercased()
        case .domain:
            return isWorld ? PlaceCodes.domain(ofCode: code) : nil
        case .phone:
            return isWorld ? PlaceCodes.callingCode(ofCode: code) : PlaceCodes.areaCode(country: country, code: code)
        case .car:
            return isWorld ? PlaceCodes.vehicleCode(ofCode: code) : nil
        case .olympic:
            return isWorld ? PlaceCodes.olympicCode(ofCode: code) : nil
        case .fifa:
            // The UK's nations, listed as countries of their own, each play as their own team.
            if isWorld { return PlaceCodes.fifaCode(ofCode: code) }
            return country == "GB" ? PlaceCodes.fifaCode(ofNation: code) : nil
        case .plate:
            return PlaceCodes.plateCode(country: country, code: code)
        case .shortName:
            return PlaceCodes.shortName(country: country, code: code)
        case .number:
            // Corsica's departments are numbered 2A and 2B; France's regions go by letters.
            let isNumber = code.allSatisfy(\.isNumber) || code == "2A" || code == "2B"
            return numberedCountries.contains(country) && isNumber ? code : nil
        case .aircraft:
            return isWorld ? PlaceCodes.aircraftPrefix(ofCode: code) : nil
        case .airport:
            return isWorld ? PlaceCodes.airportPrefix(ofCode: code) : nil
        case .currency:
            return isWorld ? PlaceCodes.currency(ofCode: code) : nil
        case .postcode:
            return PlaceCodes.postcodeDigit(country: country, code: code)
        case .timeZone:
            // The capital's clock as it is today, summer time and all, by its offset from UTC, so
            // every one reads alike; places sharing an offset share the code.
            guard isWorld, let clock = TimeZoneAtlas.clocks(of: place).first else { return nil }
            return clock.utcName(at: .now)
        }
    }

    /// A code of a kind to show it by in the lobby, such as .jp: one of the places lighting up on
    /// the board, where it has one, otherwise one in play, `offset` picking a different place for
    /// each kind where there are enough, so they don't all show one country's.
    func sampleCode(of kind: CodeKind, preferring glowing: [AdministrativeDivision] = [], offset: Int = 0) -> String? {
        let lit = glowing.filter { code(of: $0, kind: kind) != nil }
        if !lit.isEmpty { return code(of: lit[offset % lit.count], kind: kind) }
        let inPlay = placesInPlay.filter { code(of: $0, kind: kind) != nil }
        guard !inPlay.isEmpty else { return nil }
        // Spread across the places, rather than neighbours in list order.
        return code(of: inPlay[(offset * 37) % inPlay.count], kind: kind)
    }

    /// The places that count as the answer: the place in question, or in Code, every place in
    /// play that shares its code, as many share +1, and in Whose capital?, every place whose
    /// capital it is, as two places can share a capital's name.
    var answerPlaces: [AdministrativeDivision] {
        guard let current else { return [] }
        switch mode {
        case .code where code(of: current) != nil, .pickCode where code(of: current) != nil:
            return places.filter { $0.id == current.id || sharesCode($0, with: current) }
        case .whoseCapital:
            return places.filter { $0.id == current.id || sharesCapital($0, with: current) }
        default:
            return [current]
        }
    }

    /// Whether a place counts as the answer to a question about another's capital, in Whose
    /// capital?: whether the capital shown is one of its capitals too.
    func sharesCapital(_ place: AdministrativeDivision, with other: AdministrativeDivision) -> Bool {
        guard let shown = capitalName(of: other).map(CapitalCities.normalized) else { return false }
        return (capitals[place.id] ?? []).flatMap(\.names).contains { CapitalCities.normalized($0) == shown }
    }

    /// Each of a place's codes of the kind shown: one, as most places have, or several, such as
    /// Brazil's aircraft prefixes.
    func codeValues(of place: AdministrativeDivision) -> Set<String> {
        guard let code = code(of: place) else { return [] }
        return Set(code.components(separatedBy: PlaceCodes.separator))
    }

    /// Whether a place counts as the answer to a question about another's code of the kind shown:
    /// whether it has every code shown, as places sharing +1 do. A question showing several codes,
    /// such as Malaysia's airports' WM and WB, isn't answered by a place with only some of them,
    /// such as Brunei, with WB alone, though Malaysia answers Brunei's.
    func sharesCode(_ place: AdministrativeDivision, with other: AdministrativeDivision) -> Bool {
        let shown = codeValues(of: other)
        return !shown.isEmpty && shown.isSubset(of: codeValues(of: place))
    }

    /// Whether a place counts as the answer to this question.
    func isAnswer(_ place: AdministrativeDivision) -> Bool {
        guard let current else { return false }
        if place.id == current.id { return true }
        switch mode {
        case .code, .pickCode: return sharesCode(place, with: current)
        case .whoseCapital: return sharesCapital(place, with: current)
        default: return false
        }
    }

    /// In Dot, where the dot goes: the point a place's name is set at, inside its main body.
    func dotPoint(of place: AdministrativeDivision) -> CGPoint? {
        let regionID = mainRegions(of: place.id).first
        return regionID.flatMap { map.region(id: $0)?.center }
    }

    // MARK: Outlines

    /// A place's shape alone, for Outline: the main body of its own outline, leaving out far-flung
    /// islands, true to its proportions and scaled to fit a unit square, centred in it. On the
    /// World, drawn in Mercator's projection, the shape is taken back to longitude and latitude and
    /// redrawn around its own middle, so places far from the equator aren't stretched. Nil where
    /// there's too little of a shape to know it by, such as a dot of an island.
    func outline(of place: AdministrativeDivision) -> Path? {
        if let outline = outlines[place.id] { return outline }
        let outline = makeOutline(of: place)
        outlines[place.id] = outline
        return outline
    }

    private func makeOutline(of place: AdministrativeDivision) -> Path? {
        guard placeRegions[place.id]?.contains(place.id) == true, let region = map.region(id: place.id),
              let core = frames[place.id], core.width > 0, core.height > 0
        else { return nil }
        // The rings that make up the main body: those lying within it.
        let reach = core.insetBy(dx: -core.width * 0.01, dy: -core.height * 0.01)
        var rings: [[CGPoint]] = []
        var ring: [CGPoint] = []
        func finish() {
            if ring.count >= 3 {
                let bounds = ring.reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
                if reach.contains(bounds) { rings.append(ring) }
            }
            ring = []
        }
        region.path.forEach { element in
            switch element {
            case .move(let point):
                finish()
                ring = [point]
            case .line(let point), .quadCurve(let point, _), .curve(let point, _, _):
                ring.append(point)
            case .closeSubpath:
                finish()
            }
        }
        finish()
        guard rings.map(\.count).reduce(0, +) >= 14 else { return nil }
        // Mercator's x is longitude and its y stretches with latitude; a sinusoidal projection
        // around the place's middle gives its true shape back.
        let middle = core.midX
        let isMercator = projection == .mercator
        func trueShape(_ point: CGPoint) -> CGPoint {
            guard isMercator else { return point }
            let latitude = 2 * atan(exp(-point.y)) - .pi / 2
            return CGPoint(x: (point.x - middle) * cos(latitude), y: -latitude)
        }
        let shaped = rings.map { $0.map(trueShape) }
        let bounds = shaped.joined().reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
        let side = max(bounds.width, bounds.height)
        guard side > 0 else { return nil }
        let scale = 1 / side
        let offset = CGPoint(x: (1 - bounds.width * scale) / 2, y: (1 - bounds.height * scale) / 2)
        var path = Path()
        for points in shaped {
            path.addLines(points.map { CGPoint(x: ($0.x - bounds.minX) * scale + offset.x, y: ($0.y - bounds.minY) * scale + offset.y) })
            path.closeSubpath()
        }
        return path
    }

    /// Whether a place has a flag of its own to show, rather than its country's or one it shares.
    func hasOwnFlag(_ place: AdministrativeDivision) -> Bool {
        flagPlaceIDs.contains(place.id)
    }

    /// A place's capital as it's offered to pick with four to pick from: the first, where it has several.
    func capitalName(of place: AdministrativeDivision) -> String? {
        capitals[place.id]?.first?.name
    }

    private func pool(for mode: MapGameMode, scoped: Bool = true, inSet: Bool = true) -> [AdministrativeDivision] {
        if mode == .everything { return everythingPool(scoped: scoped) }
        let all: [AdministrativeDivision] = switch mode {
        case .flags, .pickFlag: flagPlaces
        case .capitals, .whoseCapital: places.filter { capitals[$0.id] != nil }
        case .outline, .pickOutline: places.filter { outline(of: $0) != nil }
        case .code, .pickCode: places.filter { code(of: $0) != nil }
        case .nameIt, .findIt, .dot, .listAll, .everything: places
        // A group chosen as the World's region adds its near misses once it's narrowed to its members.
        case .member: scopedGroup == nil ? places + nearMisses : places
        }
        guard scoped else { return all }
        var scoped = all.filter(scopeTest(inSet: inSet))
        if mode == .member, scopedGroup != nil {
            let setIDs = inSet ? placeSet?.placeIDs : nil
            scoped += nearMisses.filter { setIDs?.contains($0.id) != false }
        }
        return scoped
    }

    // MARK: The board

    /// Whether this is a round of Member?, where the board mustn't give away which countries are members.
    var isMembershipRound: Bool {
        mode == .member && phase != .lobby
    }

    /// The board's colours: each region at the level for how its place went, the rest at never been.
    /// In Member?, every country on the map is drawn alike, members or not, so none gives itself away.
    var statuses: [String: VisitLevel] {
        var statuses = regionPlaces.mapValues { place in outcomes[place.id].map(Self.level(for:)) ?? .never }
        // A round of Everything's states and provinces, over their countries.
        for (regionID, place) in roundRegionPlaces {
            statuses[regionID] = outcomes[place.id].map(Self.level(for:)) ?? .never
        }
        // Land listed with a country but out of play, such as Taiwan on China's map while it
        // counts as part of China, still draws, veiled, rather than leaving a hole.
        for id in fadedRegionIDs where statuses[id] == nil {
            statuses[id] = .never
        }
        if isMembershipRound {
            for region in map.regions where statuses[region.id] == nil {
                statuses[region.id] = nearMissPlaces[region.id].flatMap { outcomes[$0.id] }.map(Self.level(for:)) ?? .never
            }
        }
        return statuses
    }

    /// Regions of places outside the round, veiled on the board: for a group of countries, every
    /// country that isn't a member too, except in Member?, where that would give the answer away.
    var veiledRegionIDs: Set<String> {
        if isMembershipRound {
            // In a group chosen as the World's region, any country could be asked about.
            guard let scopeID, scopedGroup == nil else { return [] }
            return Set(map.regions.map(\.id).filter { place(id: $0)?.groupID != scopeID })
        }
        var veiled = fadedRegionIDs
        if collection.isGroupOfCountries {
            veiled = Set(map.regions.map(\.id).filter { regionPlaces[$0] == nil })
        }
        // Everything plays the countries in the region whatever the set, which is for countries.
        let isInScope = scopeTest(inSet: mode != .everything)
        veiled.formUnion(regionPlaces.filter { !isInScope($0.value) }.keys)
        // A round of Everything's own places are in play, over countries that are.
        return veiled.subtracting(roundRegionPlaces.keys)
    }

    /// Regions of places in the chosen group and set, which answer taps.
    var scopedRegionIDs: Set<String> {
        let isInScope = scopeTest()
        return Set(regionPlaces.filter { isInScope($0.value) }.keys)
    }

    /// Whether a place is in the chosen region, a group of countries chosen as the World's
    /// included, or every place, and in the chosen set: the region and set looked up once, for
    /// testing every region against.
    private func scopeTest(inSet: Bool = true) -> (AdministrativeDivision) -> Bool {
        let scopeID = scopeID
        let memberIDs = scopedMemberIDs
        let setIDs = inSet ? placeSet?.placeIDs : nil
        return { place in
            let isInRegion = memberIDs.map { $0.contains(place.id) } ?? (scopeID == nil || place.groupID == scopeID)
            return isInRegion && setIDs?.contains(place.id) != false
        }
    }

    /// Regions in the chosen group still to be answered.
    var openRegionIDs: Set<String> {
        scopedRegionIDs.filter { id in regionPlaces[id].map { outcomes[$0.id] == nil } ?? false }
    }

    /// The area the round's places cover, for the camera to frame; nil for the whole map.
    var scopeFrame: CGRect? {
        guard scopeID != nil || placeSet != nil else { return nil }
        // Everything's places are framed by their countries.
        let framed = mode == .everything ? placesInPlay : scopedPlaces
        let frame = framed.compactMap { frames[$0.id] }.reduce(CGRect.null) { $0.union($1) }
        return frame.isNull ? nil : frame
    }

    // MARK: The round

    enum Phase {
        /// Choosing what to play.
        case lobby
        /// Waiting for the right answer.
        case asking
        /// Showing the answer.
        case answered
        /// The round is over.
        case finished
    }

    /// How the modes that can be are answered, one choice for them all in the lobby.
    enum AnswerStyle: String, CaseIterable, Identifiable {
        /// Typed, with a small slip of the keyboard forgiven.
        case type
        /// Four dealt to pick from: the answer, two of its near neighbours and one from further away.
        case four
        /// Every one in play, narrowed by typing, like a Sporcle quiz.
        case all

        var id: Self { self }

        var name: String {
            switch self {
            case .type: "Type"
            case .four: "Multiple-choice"
            case .all: "List"
            }
        }

        var symbolName: String {
            switch self {
            case .type: "character.cursor.ibeam"
            case .four: "square.grid.2x2"
            case .all: "list.bullet"
            }
        }

        /// What VoiceOver hears for it.
        var spokenName: String {
            switch self {
            case .type: "Type the answer"
            case .four: "Multiple choice, from four"
            case .all: "Choose from a list of all"
            }
        }
    }

    /// How a mode's question is answered, with the options as they are.
    enum AnswerMethod {
        /// A place tapped on the map, in Find.
        case map
        /// Typed.
        case typing
        /// Four dealt to pick from.
        case four
        /// Every one in play, as cards to pick from, narrowed by typing.
        case list
        /// In or out, in Member?.
        case inOrOut
    }

    enum Outcome: Equatable {
        /// Answered right, on this try.
        case right(tries: Int)
        /// Shown, after asking to see it.
        case shown

        var isRightFirstTime: Bool { self == .right(tries: 1) }
    }

    /// How an answer went.
    enum Answer {
        case right
        case wrong
        /// A wrong answer already given for this question.
        case again
        /// There was no question waiting for an answer.
        case ignored
    }

    var current: AdministrativeDivision? {
        // List All asks about every place at once, so no one place is in question.
        guard mode != .listAll, phase == .asking || phase == .answered, questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    var isLastQuestion: Bool {
        index + 1 >= questions.count
    }

    /// How a mode's question is answered, with the options as they are. A flag or a shape can't be
    /// typed, so with Type chosen they offer every one in play to pick from; and Everything, with
    /// too many places to deal four from fairly, is typed where four are chosen.
    func answerMethod(for mode: MapGameMode) -> AnswerMethod {
        switch mode {
        case .findIt: .map
        case .member: .inOrOut
        case .listAll: .typing
        case .nameIt, .capitals, .whoseCapital, .outline, .code, .dot:
            switch answerStyle {
            case .type: .typing
            case .four: .four
            case .all: .list
            }
        case .flags, .pickFlag, .pickOutline: answerStyle == .four ? .four : .list
        case .pickCode:
            switch answerStyle {
            case .type: .typing
            case .four: .four
            case .all: .list
            }
        case .everything: answerStyle == .all ? .list : .typing
        }
    }

    /// How this round's questions are answered.
    var answerMethod: AnswerMethod {
        answerMethod(for: mode)
    }

    /// Whether this round deals four to pick from.
    var isMultipleChoice: Bool {
        answerMethod == .four
    }

    /// Wrong answers to this question, of every kind.
    var misses: Int {
        wrongGuesses.count + wrongTyped + wrongDecoys.count
    }

    /// Names already tried, tried again: not another wrong answer, but still worth a shake.
    private(set) var retries = 0

    /// Every miss and every retry, so a field can shake at each one.
    var shakes: Int {
        misses + retries
    }

    /// One of four dealt to pick from: a place, standing for its name or its capital, or in Capital,
    /// a well-known city in the place in question that isn't its capital, as a tempting mistake.
    struct Choice: Identifiable, Equatable {
        var place: AdministrativeDivision
        /// The city, when it's one of these tempting mistakes.
        var decoy: String?

        var id: String { decoy.map { "decoy-\($0)" } ?? place.id }
    }

    /// Names to choose from in a list of all: every place in play not answered yet this round.
    var options: [AdministrativeDivision] {
        scopedPlaces.filter { place in outcomes[place.id] == nil || place.id == current?.id }
    }

    /// With four to pick from, this question's four: the place in question and three others, or in
    /// Capital, their capitals and perhaps a city or two in the place that isn't its capital, in
    /// the order they were dealt.
    var dealt: [Choice] {
        current.flatMap { deals[$0.id] } ?? []
    }

    /// Starts a round with the current choices, the places shuffled and, with four to pick from, each
    /// question's four dealt; or for a review, only the places given, every one of them.
    func start(only chosen: [AdministrativeDivision]? = nil) {
        // Only a round of Everything draws more onto the World, and only for itself.
        clearRoundRegions()
        let pool = scopedPlaces
        // List All keeps list order, for the places left to name at the end.
        let given = chosen ?? pool
        var candidates = mode == .listAll ? given : given.shuffled()
        switch mode {
        case .code:
            // A code shared by several places, such as +1, comes up once a round.
            var seen: Set<String> = []
            candidates = candidates.filter { place in
                let values = codeValues(of: place)
                guard !values.isEmpty, values.isDisjoint(with: seen) else { return false }
                seen.formUnion(values)
                return true
            }
        case .whoseCapital:
            // So does a capital's name shared by several places, as Kingston is.
            var seen: Set<String> = []
            candidates = candidates.filter { place in
                guard let name = capitalName(of: place) else { return false }
                return seen.insert(CapitalCities.normalized(name)).inserted
            }
        case .everything:
            candidates = everythingQuestions(from: candidates)
        default:
            break
        }
        if chosen != nil {
            questions = candidates
        } else if mode == .member {
            questions = membershipQuestions(from: candidates)
        } else {
            questions = Array(candidates.prefix(questionCount(from: candidates.count)))
        }
        // Everything deals from the places it's drawn onto the World, where each has a place to be near.
        let dealPool = mode == .everything ? roundPlaces : pool
        deals = isMultipleChoice ? Dictionary(uniqueKeysWithValues: questions.map { ($0.id, deal(for: $0, among: dealPool)) }) : [:]
        // Turned shapes: each asked about, or picking a shape, each that could be picked.
        let shown = mode == .pickOutline ? (isMultipleChoice ? deals.values.flatMap { $0.map(\.place) } : pool) : questions
        rotations = (mode == .outline || mode == .pickOutline) && outlineRotated
            ? Dictionary(shown.map { ($0.id, Self.randomTilt()) }) { first, _ in first } : [:]
        listAllNames = mode == .listAll ? Self.names(of: questions, by: typedNames(of:)) : [:]
        named = []
        skipped = [:]
        index = 0
        outcomes = [:]
        wrongGuesses = []
        wrongTyped = 0
        retries = 0
        correction = nil
        wrongDecoys = []
        typedNote = nil
        memberGuess = nil
        timedOutIDs = []
        startDate = .now
        deadline = roundMinutes.map { Date.now.addingTimeInterval(TimeInterval($0 * 60)) }
        isTimeUp = false
        endDate = nil
        phase = questions.isEmpty ? .lobby : .asking
        startQuestionClock()
    }

    /// Member?'s questions: about half members and half near misses, as many as the round asks
    /// for, shuffled together.
    private func membershipQuestions(from candidates: [AdministrativeDivision]) -> [AdministrativeDivision] {
        let members = candidates.filter(isMember)
        let others = candidates.filter { !isMember($0) }
        let total = questionCount(from: candidates.count)
        var outCount = min(others.count, total / 2)
        let inCount = min(members.count, total - outCount)
        outCount = min(others.count, total - inCount)
        return (Array(members.prefix(inCount)) + Array(others.prefix(outCount))).shuffled()
    }

    /// Under a time limit for each question, starts this question's clock.
    private func startQuestionClock(timeLeft: TimeInterval? = nil) {
        // List All has no questions of its own to time.
        guard mode != .listAll else {
            questionDeadline = nil
            return
        }
        // A question coming back from being skipped carries on with the time it had left.
        let seconds = timeLeft ?? questionSeconds.map(TimeInterval.init)
        questionDeadline = phase == .asking ? seconds.map { Date.now.addingTimeInterval($0) } : nil
    }

    /// Holds the question's clock back while the camera flies to its place, so the flight doesn't
    /// eat into the time: the clock stands full until it lands, then runs.
    func holdQuestionClock(for delay: TimeInterval) {
        guard delay > 0, phase == .asking, let deadline = questionDeadline else { return }
        questionDeadline = deadline.addingTimeInterval(delay)
    }

    /// Whether a place's question ran out of time.
    func ranOutOfTime(_ place: AdministrativeDivision) -> Bool {
        timedOutIDs.contains(place.id)
    }

    /// Answers Member?: in, or out. Either way the question is settled, as a second try would only
    /// be the other button: right, or a miss, which shows as the answer shown.
    @discardableResult
    func answer(isMember guess: Bool) -> Answer {
        guard phase == .asking, mode == .member, let current else { return .ignored }
        memberGuess = guess
        let isRight = isMember(current) == guess
        settle(as: isRight ? .right(tries: 1) : .shown)
        return isRight ? .right : .wrong
    }

    /// This question's time is up: its answer is shown, and Next waits as it always does.
    func runOutOfQuestionTime() {
        guard phase == .asking, let current else { return }
        timedOutIDs.insert(current.id)
        settle(as: .shown)
    }

    /// Answers with a name chosen, or in Find, a place tapped on the map. A wrong answer is
    /// noted and the question waits for another.
    @discardableResult
    func answer(_ place: AdministrativeDivision) -> Answer {
        guard phase == .asking, current != nil else { return .ignored }
        if isAnswer(place) {
            // Every miss counts, a tempting city picked in Capital as much as a wrong place.
            settle(as: .right(tries: misses + 1))
            return .right
        }
        guard !wrongGuesses.contains(place) else { return .again }
        wrongGuesses.append(place)
        return .wrong
    }

    /// How a typed answer went.
    enum Typed {
        case right
        /// Not the answer, nor any other place in play.
        case wrong
        /// Typed out in full as another place in play, or its capital.
        case other(AdministrativeDivision)
        /// Another place in play, already given for this question.
        case again(AdministrativeDivision)
        /// In Capital, a well-known city in the place that isn't its capital.
        case decoy(String)
        /// There was no question waiting for a typed answer.
        case ignored
    }

    /// Picks, in Capital, a city in the place in question that isn't its capital: wrong, and noted.
    @discardableResult
    func answer(decoy city: String) -> Answer {
        guard phase == .asking, mode == .capitals else { return .ignored }
        guard !wrongDecoys.contains(city) else { return .again }
        wrongDecoys.append(city)
        return .wrong
    }

    /// Answers with a typed name, or in Capital, a typed capital, letting a small typo through and
    /// noting the right spelling when it does. Any one of several capitals will do. Typed out in
    /// full as another place in play, it counts as that place, wrongly.
    @discardableResult
    func answer(typed: String) -> Typed {
        guard phase == .asking, answerMethod == .typing, let current else { return .ignored }
        typedNote = nil
        // Spelt out exactly as another place, it's that place, not a slip for the answer.
        let exactOther = scopedPlaces.first { place in
            !isAnswer(place) && CapitalCities.closest(typed, among: typedNames(of: place))?.isExact == true
        }
        let match = CapitalCities.closest(typed, among: answerPlaces.flatMap(typedNames(of:)))
        if let match, match.isExact || exactOther == nil {
            correction = match.isExact ? nil : match.name
            settle(as: .right(tries: misses + 1))
            return .right
        }
        if let other = exactOther {
            guard !wrongGuesses.contains(other) else {
                retries += 1
                return .again(other)
            }
            wrongGuesses.append(other)
            return .other(other)
        }
        if mode == .capitals, let city = CapitalCities.closest(typed, among: CapitalCities.notableCities(of: current))?.name {
            wrongTyped += 1
            typedNote = "\(city) is in \(current.name), but it isn’t the capital."
            return .decoy(city)
        }
        wrongTyped += 1
        return .wrong
    }

    /// Whether a typed answer already spells out the answer in full, so it can be taken as it's typed.
    func isExactAnswer(_ typed: String) -> Bool {
        CapitalCities.closest(typed, among: answerPlaces.flatMap(typedNames(of:)))?.isExact == true
    }

    /// The names a place is answered by when typed: in Capital, every name of each of its
    /// capitals; otherwise its own name, its local name and its formal name.
    private func typedNames(of place: AdministrativeDivision) -> [String] {
        switch mode {
        case .capitals: return (capitals[place.id] ?? []).flatMap(\.names)
        // A code's own marks, such as the dot of .jp or the plus of +81, aren't needed.
        case .pickCode: return Array(codeValues(of: place))
        default: return [place.name, place.localName, place.formalName].compactMap { $0 }
        }
    }

    /// Shows the answer to this question.
    func reveal() {
        guard phase == .asking else { return }
        settle(as: .shown)
    }

    /// On to the next place, or to the results after the last.
    func advance() {
        guard phase == .answered else { return }
        guard index + 1 < questions.count else {
            endDate = .now
            deadline = nil
            phase = .finished
            return
        }
        index += 1
        beginQuestion()
    }

    /// Whether this question can be skipped for now: while it waits, with another after it to go to.
    var canSkip: Bool {
        phase == .asking && mode != .listAll && index + 1 < questions.count
    }

    /// Leaves this question for later: it goes to the end of the round, keeping its wrong answers and
    /// whatever time it had left, and the next one comes up.
    func skip() {
        guard canSkip, let current else { return }
        skipped[current.id] = SkippedQuestion(
            wrongGuesses: wrongGuesses, wrongTyped: wrongTyped, wrongDecoys: wrongDecoys, retries: retries,
            timeLeft: questionDeadline.map { max($0.timeIntervalSinceNow, 1) })
        questions.remove(at: index)
        questions.append(current)
        beginQuestion()
    }

    /// A question skipped for later, as it was left.
    private struct SkippedQuestion {
        var wrongGuesses: [AdministrativeDivision]
        var wrongTyped: Int
        var wrongDecoys: [String]
        var retries: Int
        /// Any time it had left, under a time limit for each question.
        var timeLeft: TimeInterval?
    }

    /// Questions skipped for later this round, by place ID, until they come back.
    private var skipped: [String: SkippedQuestion] = [:]

    /// Brings up the question at `index`: fresh, or one skipped earlier, as it was left.
    private func beginQuestion() {
        let resumed = current.flatMap { skipped.removeValue(forKey: $0.id) }
        wrongGuesses = resumed?.wrongGuesses ?? []
        wrongTyped = resumed?.wrongTyped ?? 0
        retries = resumed?.retries ?? 0
        correction = nil
        wrongDecoys = resumed?.wrongDecoys ?? []
        typedNote = nil
        memberGuess = nil
        phase = .asking
        startQuestionClock(timeLeft: resumed?.timeLeft)
    }

    /// Time's up: the places not yet answered are shown, and the round is over.
    func runOutOfTime() {
        guard phase == .asking || phase == .answered else { return }
        for place in questions where outcomes[place.id] == nil {
            outcomes[place.id] = .shown
        }
        endDate = .now
        deadline = nil
        questionDeadline = nil
        isTimeUp = true
        phase = .finished
    }

    func returnToLobby() {
        deadline = nil
        questionDeadline = nil
        memberGuess = nil
        timedOutIDs = []
        isTimeUp = false
        phase = .lobby
        questions = []
        deals = [:]
        outcomes = [:]
        wrongGuesses = []
        wrongTyped = 0
        retries = 0
        correction = nil
        wrongDecoys = []
        typedNote = nil
        named = []
        listAllNames = [:]
        clearRoundRegions()
        skipped = [:]
    }

    private func settle(as outcome: Outcome) {
        guard let current else { return }
        outcomes[current.id] = outcome
        // The clock stops once the question's answered.
        questionDeadline = nil
        phase = .answered
    }

    /// The place and three others to pick from: two of its near neighbours, which make it a real
    /// question, and one from further away, shuffled. In Capital, one or two of the others may be
    /// well-known cities in the place itself that aren't its capital, the most tempting mistakes,
    /// such as Sydney for Australia; neighbours' capitals make up the rest. No two read the same,
    /// so two places sharing a capital's name are never dealt together.
    private func deal(for place: AdministrativeDivision, among pool: [AdministrativeDivision]) -> [Choice] {
        var others = pool.filter { $0.id != place.id }
        if others.count < 3 {
            // A small group borrows from the rest of the map.
            others += self.pool(for: mode, scoped: false).filter { $0.id != place.id && !others.contains($0) }
        }
        let origin = frames[place.id].map { CGPoint(x: $0.midX, y: $0.midY) }
        let nearestFirst = others
            .map { other -> (place: AdministrativeDivision, distance: CGFloat) in
                guard let origin, let frame = frames[other.id] else { return (other, .greatestFiniteMagnitude) }
                return (other, hypot(frame.midX - origin.x, frame.midY - origin.y))
            }
            .sorted { $0.distance < $1.distance }
            .map(\.place)
        var picked: [Choice] = []
        var labels: Set<String> = [choiceLabel(for: place)]
        if mode == .capitals {
            // Every capital of the place reads as the right answer, so none of them can be a decoy.
            labels.formUnion((capitals[place.id] ?? []).flatMap(\.names).map(CapitalCities.normalized))
            for city in CapitalCities.notableCities(of: place).shuffled().prefix(Int.random(in: 1...2))
            where labels.insert(CapitalCities.normalized(city)).inserted {
                picked.append(Choice(place: place, decoy: city))
            }
        }
        let isCode = mode == .code || mode == .pickCode
        let isWhoseCapital = mode == .whoseCapital
        func pick(_ other: AdministrativeDivision) {
            // In Code, nothing else that shares any of its codes, which would be right too, and in
            // Whose capital?, nothing else whose capital it is.
            guard picked.count < 3, !isCode || !sharesCode(other, with: place),
                  !isWhoseCapital || !sharesCapital(other, with: place),
                  labels.insert(choiceLabel(for: other)).inserted else { return }
            picked.append(Choice(place: other))
        }
        for other in nearestFirst.prefix(6).shuffled() where picked.count < 2 {
            pick(other)
        }
        if let far = nearestFirst.dropFirst(6).shuffled().first(where: { !labels.contains(choiceLabel(for: $0)) }) {
            pick(far)
        }
        for other in nearestFirst where picked.count < 3 {
            pick(other)
        }
        return ([Choice(place: place)] + picked).shuffled()
    }

    /// What a dealt place reads as, folded so that names differing only in case or accents count as the same.
    private func choiceLabel(for place: AdministrativeDivision) -> String {
        if mode == .capitals, let capital = capitalName(of: place) {
            return CapitalCities.normalized(capital)
        }
        if mode == .pickCode, let code = code(of: place) {
            return CapitalCities.normalized(code)
        }
        return place.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    private enum Key {
        static let mode = "gameMode"
        static let length = "gameLength"
        /// The set of places chosen for a list, by the list's ID.
        static func placeSet(_ collectionID: String) -> String { "gamePlaceSet.\(collectionID)" }
        static let answerStyle = "gameAnswerStyle"
        /// Where how many a list offered was kept, for every mode and then for each, before one
        /// answer style took over.
        static let retiredChoices = "gameChoices"
        /// Where typing or a list was kept, for every mode and then for each, before one answer
        /// style took over.
        static let retiredAnswerBy = "gameAnswerBy"
        static let codeKind = "gameCodeKind"
        /// Where Dot's borders were kept, before Dot became a plain map only.
        static let retiredDotBorders = "gameDotBorders"
        static let outlineRotated = "gameOutlineRotated"
        static let customCount = "gameCustomCount"
        static let showsBorders = "gameShowsBorders"
        static let autoFill = "gameAutoFill"
        static let roundMinutes = "gameRoundMinutes"
        static let questionSeconds = "gameQuestionSeconds"
        /// Where the one time limit there could be was kept, by its kind and amount, before the
        /// round and each question could have one at once.
        static let retiredTimerKind = "gameTimerKind"
        static let retiredTimerAmount = "gameTimerAmount"
        /// Where a round's time limit was kept, before there were limits for each question too.
        static let retiredTimeLimit = "gameTimeLimit"
        /// Where Quiz or Learn was kept, before Learn became a tile of its own.
        static let retiredActivity = "gameActivity"
    }

    /// The answer style, or before there was one, as the last mode played was answered, its own
    /// choice or the one every mode shared before that. The old keys are cleared once it's moved over.
    private static func storedAnswerStyle(in defaults: UserDefaults) -> AnswerStyle {
        if let style = defaults.string(forKey: Key.answerStyle).flatMap(AnswerStyle.init(rawValue:)) { return style }
        let lastMode = defaults.string(forKey: Key.mode) ?? MapGameMode.nameIt.rawValue
        func stored(_ key: String) -> String? {
            defaults.string(forKey: key + "." + lastMode) ?? defaults.string(forKey: key)
        }
        let style: AnswerStyle = stored(Key.retiredAnswerBy) == "type" ? .type : stored(Key.retiredChoices) == "multiple" ? .four : .all
        defaults.set(style.rawValue, forKey: Key.answerStyle)
        for key in [Key.retiredAnswerBy, Key.retiredChoices] {
            defaults.removeObject(forKey: key)
            for mode in MapGameMode.allCases { defaults.removeObject(forKey: key + "." + mode.rawValue) }
        }
        return style
    }

    /// The time limit, or before there were two kinds, a round's limit as it was saved.
    /// The round's and each question's time limits, or before both could be on at once, the one
    /// limit as it was saved, moved over and its old keys cleared. A limit no longer offered, such
    /// as a minute for the round, moves to the nearest one that is.
    private static func storedTimeLimits(in defaults: UserDefaults) -> (round: Int?, question: Int?) {
        func nearest(_ amount: Int, in choices: [Int]) -> Int? {
            amount > 0 ? choices.min { abs($0 - amount) < abs($1 - amount) } : nil
        }
        if defaults.object(forKey: Key.roundMinutes) != nil || defaults.object(forKey: Key.questionSeconds) != nil {
            return (
                nearest(defaults.integer(forKey: Key.roundMinutes), in: roundMinuteChoices),
                nearest(defaults.integer(forKey: Key.questionSeconds), in: questionSecondChoices))
        }
        var round: Int?
        var question: Int?
        let amount = defaults.integer(forKey: Key.retiredTimerAmount)
        switch defaults.string(forKey: Key.retiredTimerKind) {
        case "round": round = nearest(amount, in: roundMinuteChoices)
        case "question": question = nearest(amount, in: questionSecondChoices)
        case nil:
            let minutes = ["one": 1, "three": 3, "five": 5, "ten": 10][defaults.string(forKey: Key.retiredTimeLimit) ?? ""]
            round = minutes.flatMap { nearest($0, in: roundMinuteChoices) }
        default: break
        }
        defaults.set(round ?? 0, forKey: Key.roundMinutes)
        defaults.set(question ?? 0, forKey: Key.questionSeconds)
        for key in [Key.retiredTimerKind, Key.retiredTimerAmount, Key.retiredTimeLimit] {
            defaults.removeObject(forKey: key)
        }
        return (round, question)
    }

    /// An angle well away from upright, either way round, for a turned outline.
    private static func randomTilt() -> Double {
        let tilt = Double.random(in: 35...150)
        return Bool.random() ? tilt : -tilt
    }

    // MARK: Auto-fill

    /// A name offered as it's typed, with Auto-fill on, and the place picking it answers with.
    struct Suggestion: Identifiable, Equatable {
        var name: String
        var place: AdministrativeDivision

        var id: String { "\(place.id)|\(name)" }
    }

    /// The names nearest what's typed, at most ten, best first: those that start with it, then
    /// those with a word that does, then those that hold it, then those it's a slip or two away
    /// from. Each place in play not answered yet comes once, by its best name: its name, or in
    /// Capital, its capital.
    func suggestions(for typed: String, limit: Int = 10) -> [Suggestion] {
        let typed = CapitalCities.normalized(typed)
        guard !typed.isEmpty, phase == .asking else { return [] }
        var best: [String: (suggestion: Suggestion, score: Int)] = [:]
        for place in options {
            for name in typedNames(of: place) {
                let folded = CapitalCities.normalized(name)
                let score: Int
                if folded.hasPrefix(typed) {
                    score = 0
                } else if name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .contains(where: { !$0.isEmpty && $0.hasPrefix(typed) }) {
                    score = 1
                } else if folded.contains(typed) {
                    score = 2
                } else if typed.count >= 3,
                          CapitalCities.editDistance(typed, String(folded.prefix(typed.count))) <= (typed.count >= 6 ? 2 : 1) {
                    score = 3
                } else {
                    continue
                }
                if let found = best[place.id], found.score <= score { continue }
                best[place.id] = (Suggestion(name: name, place: place), score)
            }
        }
        return best.values
            .sorted { $0.score != $1.score ? $0.score < $1.score : $0.suggestion.name.localizedStandardCompare($1.suggestion.name) == .orderedAscending }
            .prefix(limit)
            .map(\.suggestion)
    }

    /// Whether Auto-fill helps with a mode just now: names typed, not codes, as the answer type is.
    func offersAutoFill(for mode: MapGameMode) -> Bool {
        mode.offersAutoFill && answerMethod(for: mode) == .typing
    }

    // MARK: List All

    /// In List All, the places each name is answered by, the name as `CapitalCities` normalizes it.
    @ObservationIgnored private var listAllNames: [String: [AdministrativeDivision]] = [:]

    /// Each place under every name it's answered by, normalized, in the order given.
    private static func names(
        of places: [AdministrativeDivision], by names: (AdministrativeDivision) -> [String]
    ) -> [String: [AdministrativeDivision]] {
        var byName: [String: [AdministrativeDivision]] = [:]
        for place in places {
            for name in Set(names(place).map(CapitalCities.normalized)) where !name.isEmpty {
                byName[name, default: []].append(place)
            }
        }
        return byName
    }

    /// Names a place in List All from what's typed, once it's spelt out in full: a place in play
    /// not named yet. Returns it, or nil where what's typed names none of them. Naming the last
    /// one ends the round.
    @discardableResult
    func answer(listAll typed: String) -> AdministrativeDivision? {
        guard phase == .asking, mode == .listAll,
              let place = listAllNames[CapitalCities.normalized(typed)]?.first(where: { outcomes[$0.id] == nil })
        else { return nil }
        outcomes[place.id] = .right(tries: 1)
        named.append(place)
        if outcomes.count == questions.count { finish() }
        return place
    }

    /// In List All, the place already named that what's typed names, if it's one.
    func alreadyNamed(_ typed: String) -> AdministrativeDivision? {
        guard mode == .listAll else { return nil }
        return listAllNames[CapitalCities.normalized(typed)]?.first { outcomes[$0.id] != nil }
    }

    /// Gives up on List All: the places not named yet are shown, and the round is over.
    func giveUp() {
        guard phase == .asking, mode == .listAll else { return }
        for place in questions where outcomes[place.id] == nil {
            outcomes[place.id] = .shown
        }
        finish()
    }

    /// The round is over, with every place answered or shown.
    private func finish() {
        endDate = .now
        deadline = nil
        questionDeadline = nil
        phase = .finished
    }

    // MARK: Everything

    /// Everything's places for each region chosen, worked out as each is first needed.
    @ObservationIgnored private var everythingPools: [String: [AdministrativeDivision]] = [:]
    /// Each country's list of its own places for Everything, such as Germany's states, by the
    /// country's code; nil where it has none to draw onto the World.
    @ObservationIgnored private var everythingLists: [String: Country?] = [:]

    /// The smallest a place's main body can be, in the World's units, for Everything to ask about
    /// it: about half a degree across, big enough to make out once the camera's close. Malta's
    /// local councils, say, are left out.
    private static let smallestEverythingPlace: CGFloat = 0.008

    /// The federal districts of Russia's east, whose places are Asia's, though Russia is listed
    /// in Europe, and only theirs.
    private static let asianRussianDistricts: Set<String> = ["RU-ural", "RU-siberian", "RU-far-eastern"]

    /// Everything's places in the region chosen: the states, provinces and regions of its
    /// countries, from each one's own list, where it has one to draw onto the World. A
    /// continent's are those on it, as Siberia's are Asia's, whichever continent their country is
    /// listed in; a group's are its members'. A place the World counts as one of its own, such as
    /// Guadeloupe, comes up only in its own region.
    private func everythingPool(scoped: Bool = true) -> [AdministrativeDivision] {
        guard collection.id == CountryCatalog.world.id else { return [] }
        let key = scoped ? scopeID ?? "everywhere" : "unscoped"
        if let pool = everythingPools[key] { return pool }
        let continentID = scoped && scopedGroup == nil ? scopeID : nil
        let countries = scoped && continentID == nil ? pool(for: .nameIt, inSet: false) : places
        let isInScope = scopeTest(inSet: false)
        var pool: [AdministrativeDivision] = []
        // Each list once, though two of the World's places might lead to it.
        var listed: Set<String> = []
        for country in countries {
            guard let list = everythingList(of: country), listed.insert(list.id).inserted else { continue }
            for place in list.divisions where place.countryID == list.countryListID {
                if let continentID {
                    let continent = country.abbreviation == "RU"
                        ? (Self.asianRussianDistricts.contains(place.groupID) ? "WORLD-asia" : "WORLD-europe")
                        : country.groupID
                    guard continent == continentID else { continue }
                }
                if scoped, let own = regionPlaces[place.id], own.id == place.id, !isInScope(own) { continue }
                pool.append(place)
            }
        }
        everythingPools[key] = pool
        return pool
    }

    /// A World country's list of its own places for Everything, such as Germany's states.
    private func everythingList(of country: AdministrativeDivision) -> Country? {
        if let list = everythingLists[country.abbreviation] { return list }
        let list = CountryCatalog.collection(for: country).flatMap { list -> Country? in
            let resource = "geo_\(PlaceReorganisation.mapResourceID(for: list.id))"
            return Bundle.main.url(forResource: resource, withExtension: "json") == nil ? nil : list
        }
        everythingLists[country.abbreviation] = .some(list)
        return list
    }

    /// The flag of the country an Everything place is in, such as Belgium's for its Limburg, to
    /// tell it apart from the Netherlands' at a glance.
    func countryFlagAssetName(of place: AdministrativeDivision) -> String? {
        guard mode == .everything, let list = everythingLists[place.countryID] ?? nil else { return nil }
        return list.flagAssetName
    }

    /// The country an Everything place is in, such as Germany for Bavaria, to tell apart places
    /// sharing a name, such as Limburg in Belgium and in the Netherlands.
    func countryName(of place: AdministrativeDivision) -> String? {
        guard mode == .everything, let list = everythingLists[place.countryID] ?? nil else { return nil }
        return list.name
    }

    /// The places a round of Everything has drawn onto the World.
    private var roundPlaces: [AdministrativeDivision] {
        var seen: Set<String> = []
        return roundRegionPlaces.values.filter { seen.insert($0.id).inserted }
    }

    /// Everything's questions, from its places shuffled: as many as a round asks, each big enough
    /// to make out, drawing each one's country onto the World as it's first needed, and never more
    /// countries than questions, so the World stays light to draw.
    private func everythingQuestions(from candidates: [AdministrativeDivision]) -> [AdministrativeDivision] {
        let total = questionCount(from: candidates.count)
        var picked: [AdministrativeDivision] = []
        for place in candidates where picked.count < total {
            guard let list = everythingLists[place.countryID] ?? nil else { continue }
            if !roundCountries.contains(where: { $0.id == list.id }) {
                guard roundCountries.count < total else { continue }
                drawOntoWorld(list)
            }
            guard let frame = frames[place.id], max(frame.width, frame.height) >= Self.smallestEverythingPlace else { continue }
            picked.append(place)
        }
        return picked
    }

    /// Draws a country's own places onto the World for a round of Everything, such as Germany's
    /// states over Germany, with the main body of each.
    private func drawOntoWorld(_ list: Country) {
        roundCountries.append(list)
        var world = map
        let added = addRegions(of: list, to: &world)
        map = world
        for placeID in added {
            let body = mainRegions(of: placeID).compactMap { world.region(id: $0)?.coreBounds }.reduce(CGRect.null) { $0.union($1) }
            if !body.isNull { frames[placeID] = body }
        }
    }

    /// Draws a list's own places onto a World map, at the World's centre now, noting the place
    /// each region stands for. A place the World already draws, such as Scotland, keeps its region.
    /// Returns the places' IDs.
    @discardableResult
    private func addRegions(of list: Country, to world: inout TravelMap) -> [String] {
        guard let geography = Geography.subdivisions(of: list.id) else { return [] }
        let isHome = MapJourney.turn(from: homeLongitude, to: centerLongitude) == 0
        let drawn = isHome ? geography.map(.mercator, center: center) : geography.map(.mercator, centerLongitude: centerLongitude)
        let places = Dictionary(list.divisions.map { ($0.id, $0) }) { first, _ in first }
        var existing = Set(world.regions.map(\.id))
        var added: [String] = []
        for region in drawn.regions {
            guard let place = places[region.id], place.countryID == list.countryListID else { continue }
            if existing.insert(region.id).inserted { world.regions.append(region) }
            roundRegionPlaces[region.id] = place
            roundPlaceRegions[place.id, default: []].append(region.id)
            added.append(place.id)
        }
        return added
    }

    /// Draws a round of Everything's countries onto a World map afresh, as when the World turns.
    private func addRoundRegions(to world: inout TravelMap) {
        guard !roundCountries.isEmpty else { return }
        roundRegionPlaces = [:]
        roundPlaceRegions = [:]
        for list in roundCountries {
            addRegions(of: list, to: &world)
        }
    }

    /// Takes a round of Everything's places off the World again.
    private func clearRoundRegions() {
        guard !roundCountries.isEmpty else { return }
        roundCountries = []
        roundRegionPlaces = [:]
        roundPlaceRegions = [:]
        let isHome = MapJourney.turn(from: homeLongitude, to: centerLongitude) == 0
        var world = isHome ? homeMap : Geography.world?.map(.mercator, centerLongitude: centerLongitude) ?? homeMap
        world.focusOverride = homeMap.focusOverride
        map = world
        frames = currentFrames(in: world)
    }

    // MARK: Results

    var rightCount: Int {
        outcomes.values.filter(\.isRightFirstTime).count
    }

    /// Starts a round of the last one's places worth another look, in the same mode.
    func startReview() {
        let places = placesToReview
        guard !places.isEmpty else { return }
        start(only: places)
    }

    /// The places that took more than one try, or were shown: the ones worth another look.
    var placesToReview: [AdministrativeDivision] {
        questions.filter { outcomes[$0.id].map { !$0.isRightFirstTime } ?? false }
    }

    var elapsed: TimeInterval? {
        guard let startDate else { return nil }
        return (endDate ?? .now).timeIntervalSince(startDate)
    }
}

extension MapGame {
    /// Where Auto Zoom is kept: whether the camera flies to each place, or keeps the whole board in view.
    nonisolated static let autoZoomKey = "gameAutoZoom"

    /// Learn's colour, on the lobby's Learn tile and Learn's cards on the full map: a calm indigo
    /// apart from the quizzes' candy, for browsing rather than playing.
    nonisolated static let learnColor = LevelColor.indigo.color

    /// Levels for how answers went, so the board colours them the way maps colour places you've
    /// been, with the same flood and ripple as each one lands: green for right first time, yellow
    /// for right after a wrong answer, red for shown.
    nonisolated static let ladder = VisitLadder(levels: [shown, right, gotThere])

    nonisolated static func level(for outcome: Outcome) -> VisitLevel {
        switch outcome {
        case .right(tries: 1): right
        case .right: gotThere
        case .shown: shown
        }
    }

    private nonisolated static let shown = VisitLevel(id: shownLevelID, name: "Shown", tint: .red, symbolName: "eye")
    /// The level of a place whose answer was shown, or ran out of time, rather than earned.
    nonisolated static let shownLevelID = "game.shown"
    private nonisolated static let right = VisitLevel(id: "game.right", name: "Correct", tint: .green, symbolName: "checkmark")
    private nonisolated static let gotThere = VisitLevel(
        id: "game.later", name: "After a miss", tint: .yellow, symbolName: "arrow.uturn.right")
}

// MARK: Groups of countries

extension MapGame {
    /// A group's near misses for Member?: its famous non-members, by ISO code, such as Norway and
    /// Switzerland for the EU, and the countries nearest its members, up to a dozen of them, in
    /// list order. A group the person made has only its neighbours.
    fileprivate static func nearMisses(
        famous famousCodes: [String], members: [AdministrativeDivision], among outsiders: [AdministrativeDivision],
        frames: [String: CGRect]
    ) -> [AdministrativeDivision] {
        guard !members.isEmpty, !outsiders.isEmpty else { return [] }
        let famous = Set(famousCodes)
        let memberFrames = members.compactMap { frames[$0.id] }
        // How far apart two places' main bodies are, in map units: nought where they touch.
        func gap(_ a: CGRect, _ b: CGRect) -> CGFloat {
            hypot(max(0, max(a.minX - b.maxX, b.minX - a.maxX)), max(0, max(a.minY - b.maxY, b.minY - a.maxY)))
        }
        let nearest = outsiders
            .compactMap { place -> (id: String, gap: CGFloat)? in
                guard let frame = frames[place.id] else { return nil }
                return (place.id, memberFrames.map { gap(frame, $0) }.min() ?? .greatestFiniteMagnitude)
            }
            // About three degrees of longitude: across a border, or a narrow sea such as the Channel.
            .filter { $0.gap < 0.05 }
            .sorted { $0.gap < $1.gap }
            .prefix(12)
            .map(\.id)
        let neighbours = Set(nearest)
        return outsiders.filter { famous.contains($0.abbreviation) || neighbours.contains($0.id) }
    }
}

extension Country {
    /// Whether its quiz plays on the World map: the World's, and every group of countries'.
    var isOnWorldMap: Bool {
        id == CountryCatalog.world.id || isGroupOfCountries
    }
}

extension WorldGroup {
    /// Its name as the region pill shows it, short where it has a short form: EU, GCC, Nordics.
    var shortName: String {
        switch self {
        case .unitedNations: "UN"
        case .europeanUnion: "EU"
        case .schengen: "Schengen"
        case .africanUnion: "AU"
        case .gulfCooperation: "GCC"
        case .nordic: "Nordics"
        case .baltic: "Baltics"
        default: name
        }
    }

    /// Its name as it sits in a sentence, with "the" where it takes one: "the European Union", "NATO".
    var nameInSentence: String {
        switch self {
        case .nato, .asean, .brics, .opec, .mercosur, .caricom, .efta, .benelux: name
        default: "the \(name)"
        }
    }

    /// Countries outside the group that people often take to be in it, by ISO code, for Member?
    /// to ask about alongside its neighbours. As of 2026.
    var famousNonMembers: [String] {
        let codes: String = switch self {
        case .unitedNations: "TW XK VA PS EH GL"
        case .g7: "MX CN RU IN AU KR ES BR NL CH"
        case .g20: "ES NL CH PL NG EG TH NZ SG"
        case .europeanUnion: "NO CH GB IS UA TR RS AL MD BA ME MK LI"
        case .schengen: "GB IE CY UA RS AL TR BA MD"
        case .eurozone: "DK SE PL CZ HU RO GB CH NO ME XK"
        case .nato: "IE AT CH UA CY MT RS GE BA MD AU JP"
        case .commonwealth: "IE US ZW MM EG IL SD ET"
        case .asean: "PG CN TW IN BD AU LK KR JP"
        case .africanUnion: "SA YE IL JO MT ES OM"
        case .arabLeague: "IR TR IL ER TD SS ET ML NE"
        case .oecd: "BR AR RU CN IN BG RO HR SG PE"
        case .brics: "SA AR MX TR NG KZ TH PK"
        case .gulfCooperation: "IQ YE IR JO"
        case .opec: "QA EC AO RU NO MX OM KZ BR"
        case .mercosur: "CL CO PE VE EC GY SR"
        case .caricom: "CU DO PR BM KY AW CW PA"
        case .efta: "GB DK SE AT FI PT IE"
        case .nordic: "EE LV LT DE GB NL IE"
        case .baltic: "FI PL BY RU SE DK"
        case .benelux: "FR DE LI CH DK AT"
        }
        return codes.split(separator: " ").map(String.init)
    }
}

private extension Country {
    /// The list with only the country's own places, leaving out any from the World listed with it.
    var keepingOwnPlaces: Country {
        var own = self
        own.groups = groups.compactMap { group in
            var group = group
            group.divisions = group.divisions.filter { $0.countryID == countryListID }
            return group.divisions.isEmpty ? nil : group
        }
        return own
    }
}
