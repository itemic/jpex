import SwiftUI
import UIKit

/// A round of the map quiz, and the choices for the next. Identify lights up a place and Capital
/// names one; you type its name or its capital, a small typo forgiven, or pick it from a list: four
/// dealt, or every one in play like a Sporcle quiz. Flag shows a place's flag to pick its name
/// from a list, and Find gives you a name to tap on the map. There's no score and no lives: a wrong
/// answer just says so, and you try again or ask to be shown. Learn browses every place in play
/// instead, one at a time, with nothing to answer.
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
    let nearMisses: [AdministrativeDivision]
    /// The regions standing for each near miss, by place ID.
    private let nearMissRegions: [String: [String]]
    /// The near miss each region stands for, by region ID.
    private let nearMissPlaces: [String: AdministrativeDivision]
    private let defaults: UserDefaults
    /// Each place's outline once it's been worked out, by place ID; nil where it has too little shape.
    @ObservationIgnored private var outlines: [String: Path?] = [:]

    var mode: MapGameMode {
        didSet { defaults.set(mode.rawValue, forKey: Key.mode) }
    }
    var length: MapGameLength {
        didSet { defaults.set(length.rawValue, forKey: Key.length) }
    }
    /// How the modes that can be are answered: typed, four to pick from, or every one in play.
    /// One choice for them all, set in the lobby; Flag, which can't be typed, picks from all instead.
    var answerStyle: AnswerStyle {
        didSet { defaults.set(answerStyle.rawValue, forKey: Key.answerStyle) }
    }
    /// In Code, which codes are shown: ISO codes, internet domains, calling codes and so on.
    var codeKind: CodeKind {
        didSet { defaults.set(codeKind.rawValue, forKey: Key.codeKind) }
    }
    /// In Outline, whether each shape comes turned at an angle, which makes it harder.
    var outlineRotated: Bool {
        didSet { defaults.set(outlineRotated, forKey: Key.outlineRotated) }
    }
    /// Any time limit: off, for the whole round, or for each question.
    var timeLimit: TimeLimit {
        didSet {
            defaults.set(timeLimit.kind, forKey: Key.timerKind)
            defaults.set(timeLimit.amount, forKey: Key.timerAmount)
        }
    }
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
    /// In Learn, the places to browse, in list order, and the one shown.
    private(set) var learnPlaces: [AdministrativeDivision] = []
    private(set) var learnIndex = 0
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
        faded: Set<String> = [], projection: MapProjection? = nil, center: MapCenter = .current,
        defaults: UserDefaults = .standard
    ) {
        self.collection = collection
        self.map = map
        homeMap = map
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
        nearMisses = Self.nearMisses(
            of: collection.worldGroup, members: places, among: outsiders.filter { outsiderRegions[$0.id] != nil }, frames: frames)
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
        placeSetID = defaults.string(forKey: Key.placeSet(collection.id))
        answerStyle = Self.storedAnswerStyle(in: defaults)
        codeKind = defaults.string(forKey: Key.codeKind).flatMap(CodeKind.init(rawValue:)) ?? .iso
        outlineRotated = defaults.bool(forKey: Key.outlineRotated)
        timeLimit = Self.storedTimeLimit(in: defaults)
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
        let collection = collection.id == CountryCatalog.world.id || collection.worldGroup != nil
            ? collection : collection.keepingOwnPlaces
        let faded = Set(listed.divisions.map(\.id)).subtracting(collection.divisions.map(\.id))
        let isOnWorldMap = collection.isOnWorldMap
        guard let map = TravelMap.named(collection.id, projection: isOnWorldMap ? .mercator : .current) else { return nil }
        let owners = isOnWorldMap ? CountryCatalog.mapRegionOwners(applying: rules) : [:]
        var outsiders: [AdministrativeDivision] = []
        if collection.worldGroup != nil {
            let members = Set(collection.divisions.map(\.id))
            let codes = Set(collection.divisions.map(\.abbreviation))
            outsiders = CountryCatalog.world(applying: rules).divisions.filter {
                !members.contains($0.id) && !codes.contains($0.abbreviation)
            }
        }
        return MapGame(
            collection: collection, map: map, regionOwners: owners, outsiders: outsiders, faded: faded,
            projection: isOnWorldMap ? .mercator : nil)
    }

    /// The collections there's a map to quiz on, in the sidebar's sections, with groups of
    /// countries, such as the EU, in their own section just after the World.
    static func sections(applying rules: CountingRules) -> [CollectionSection] {
        var sections: [CollectionSection] = CountryCatalog.sections(applying: rules).compactMap { section in
            var section = section
            section.countries.removeAll { collection in
                collection.id != CountryCatalog.world.id
                    && Bundle.main.url(forResource: "map_\(collection.id)", withExtension: "json") == nil
            }
            return section.countries.isEmpty ? nil : section
        }
        sections.insert(
            CollectionSection(title: CollectionSection.worldGroupsTitle, countries: WorldGroup.collections),
            at: min(1, sections.count))
        return sections
    }

    /// Every collection there's a map to quiz on, groups of countries included.
    static func collections(applying rules: CountingRules) -> [Country] {
        CountryCatalog.countries(applying: rules) + WorldGroup.collections
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
        map = turned
        centerLongitude = isHome ? homeLongitude : MapJourney.normalized(longitude)
        frames = Self.frames(of: placeRegions.merging(nearMissRegions, uniquingKeysWith: { first, _ in first }), in: turned)
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

    /// Whether a mode has places to ask about, as Flags doesn't where no place has a flag of its
    /// own, and Member? only for a group of countries with near misses to ask about too.
    func isAvailable(_ mode: MapGameMode) -> Bool {
        if mode == .member { return collection.worldGroup != nil && !nearMisses.isEmpty && !places.isEmpty }
        return !pool(for: mode).isEmpty
    }

    /// Whether a place is in the collection: for a group of countries, whether it's a member.
    func isMember(_ place: AdministrativeDivision) -> Bool {
        placeRegions[place.id] != nil
    }

    /// The place a region stands for: a place in play, or one of a group's near misses. A place's
    /// own outline has the place's ID, so this finds a place by its ID too.
    func place(id: String) -> AdministrativeDivision? {
        regionPlaces[id] ?? nearMissPlaces[id]
    }

    /// Whether a place is drawn with an outline of its own, rather than only through others.
    func hasOwnRegion(_ placeID: String) -> Bool {
        placeRegions[placeID]?.contains(placeID) == true || nearMissRegions[placeID]?.contains(placeID) == true
    }

    /// The places a round draws from.
    var scopedPlaces: [AdministrativeDivision] {
        pool(for: mode)
    }

    /// Every place in the chosen group, or on the whole map, and in the chosen set: what Learn
    /// browses, and what twinkles in the lobby.
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

    /// How many to play: ten, a set of places, or all of them.
    enum RoundSize: Hashable {
        case ten
        case set(String)
        case all
    }

    /// How many to play, as one choice. A set the chosen group doesn't hold plays all of the group.
    var roundSize: RoundSize {
        get {
            if let placeSetID { return placeSet == nil ? .all : .set(placeSetID) }
            return length == .ten ? .ten : .all
        }
        set {
            switch newValue {
            case .ten: placeSetID = nil; length = .ten
            case .set(let id): placeSetID = id
            case .all: placeSetID = nil; length = .every
            }
        }
    }

    /// How many questions a round asks, from how many places there are to ask about.
    private func questionCount(from available: Int) -> Int {
        placeSetID == nil ? length.count(from: available) : available
    }

    /// The regions that light up for a place: its own outline, leaving out the territories that
    /// only take its colour, such as France's overseas departments, so a spotlight stays on the
    /// country itself. A place drawn only through others keeps them all.
    func mainRegions(of placeID: String) -> [String] {
        guard let regions = placeRegions[placeID] ?? nearMissRegions[placeID] else { return [] }
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
            case .airport: "Airport"
            case .currency: "Currency"
            case .number: "Number"
            case .postcode: "Postcode"
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
            case .airport: "Airport codes"
            case .currency: "Currencies"
            case .number: "Numbers"
            case .postcode: "Postcodes"
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
            case .airport: "airport"
            case .currency: "currency"
            case .number: "number"
            case .postcode: "postcode"
            }
        }

        /// The question asked about a code of this kind, in a collection's own terms, such as
        /// "Which country has this code?"; the code sits just beneath, so it isn't repeated. Several
        /// codes at once, as a country's airports or planes can have, are asked about as these.
        func question(placeNoun: String, isSeveral: Bool = false) -> String {
            switch self {
            case .iso: "Which \(placeNoun) has this code?"
            case .domain: "Which \(placeNoun)’s domain is this?"
            case .phone: "Where does this number ring?"
            case .car: "Which \(placeNoun)’s car sticker is this?"
            case .olympic: "Which team is this?"
            // Several are the United Kingdom's four teams: one place, not one team.
            case .fifa: isSeveral ? "Whose teams play as these?" : "Which team plays as this?"
            case .plate: "Which \(placeNoun)’s plates are these?"
            case .shortName: "Which \(placeNoun) goes by this?"
            case .aircraft: isSeveral ? "Whose planes have these codes?" : "Whose planes have this code?"
            case .airport: isSeveral ? "Whose airports start with these?" : "Whose airports start with this?"
            case .currency: "Whose money is this?"
            case .number: "Which \(placeNoun) has this number?"
            case .postcode: "Where do these postcodes start?"
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
    private static func codeKinds(of places: [AdministrativeDivision]) -> [CodeKind] {
        let kinds: [CodeKind]
        if places.contains(where: { $0.countryID == CountryCatalog.world.id }) {
            kinds = [.iso, .domain, .phone, .currency, .olympic, .fifa, .car, .aircraft, .airport]
        } else {
            let readable = !places.isEmpty && places.allSatisfy { place in
                (2...3).contains(place.abbreviation.count) && place.abbreviation.allSatisfy(\.isLetter)
            }
            kinds = (readable ? [.iso] : []) + [.shortName, .plate, .number, .phone, .postcode, .fifa]
        }
        return kinds.filter { kind in Set(places.compactMap { lookUpCode(of: $0, kind: kind) }).count > 1 }
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
            return numberedCountries.contains(country) ? code : nil
        case .aircraft:
            return isWorld ? PlaceCodes.aircraftPrefix(ofCode: code) : nil
        case .airport:
            return isWorld ? PlaceCodes.airportPrefix(ofCode: code) : nil
        case .currency:
            return isWorld ? PlaceCodes.currency(ofCode: code) : nil
        case .postcode:
            return PlaceCodes.postcodeDigit(country: country, code: code)
        }
    }

    /// Every code a place has, for Learn, in the order Code offers them.
    func codes(of place: AdministrativeDivision) -> [(kind: CodeKind, code: String)] {
        codeKinds.compactMap { kind in code(of: place, kind: kind).map { (kind, $0) } }
    }

    /// The places that count as the answer: the place in question, or in Code, every place in
    /// play that shares its code, as many share +1.
    var answerPlaces: [AdministrativeDivision] {
        guard let current else { return [] }
        guard mode == .code, code(of: current) != nil else { return [current] }
        return places.filter { $0.id == current.id || sharesCode($0, with: current) }
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
        return mode == .code && sharesCode(place, with: current)
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
        let all: [AdministrativeDivision] = switch mode {
        case .flags: flagPlaces
        case .capitals: places.filter { capitals[$0.id] != nil }
        case .outline: places.filter { outline(of: $0) != nil }
        case .code: places.filter { code(of: $0) != nil }
        case .nameIt, .findIt, .dot: places
        case .member: places + nearMisses
        }
        guard scoped else { return all }
        let scoped = scopeID.map { scopeID in all.filter { $0.groupID == scopeID } } ?? all
        guard inSet, let placeSet else { return scoped }
        return scoped.filter { placeSet.placeIDs.contains($0.id) }
    }

    // MARK: The board

    /// Whether this is a round of Member?, where the board mustn't give away which countries are members.
    var isMembershipRound: Bool {
        mode == .member && phase != .lobby && phase != .learning
    }

    /// The board's colours: each region at the level for how its place went, the rest at never been.
    /// In Member?, every country on the map is drawn alike, members or not, so none gives itself away.
    var statuses: [String: VisitLevel] {
        var statuses = regionPlaces.mapValues { place in outcomes[place.id].map(Self.level(for:)) ?? .never }
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
            guard let scopeID else { return [] }
            return Set(map.regions.map(\.id).filter { place(id: $0)?.groupID != scopeID })
        }
        var veiled = fadedRegionIDs
        if collection.worldGroup != nil {
            veiled = Set(map.regions.map(\.id).filter { regionPlaces[$0] == nil })
        }
        let isInScope = scopeTest
        return veiled.union(regionPlaces.filter { !isInScope($0.value) }.keys)
    }

    /// Regions of places in the chosen group and set, which answer taps.
    var scopedRegionIDs: Set<String> {
        let isInScope = scopeTest
        return Set(regionPlaces.filter { isInScope($0.value) }.keys)
    }

    /// Whether a place is in the chosen group, or every place, and in the chosen set: the group
    /// and set looked up once, for testing every region against.
    private var scopeTest: (AdministrativeDivision) -> Bool {
        let scopeID = scopeID
        let setIDs = placeSet?.placeIDs
        return { place in (scopeID == nil || place.groupID == scopeID) && setIDs?.contains(place.id) != false }
    }

    /// Regions in the chosen group still to be answered.
    var openRegionIDs: Set<String> {
        scopedRegionIDs.filter { id in regionPlaces[id].map { outcomes[$0.id] == nil } ?? false }
    }

    /// The area the round's places cover, for the camera to frame; nil for the whole map.
    var scopeFrame: CGRect? {
        guard scopeID != nil || placeSet != nil else { return nil }
        let frame = scopedPlaces.compactMap { frames[$0.id] }.reduce(CGRect.null) { $0.union($1) }
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
        /// Browsing places one at a time, in Learn.
        case learning
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

    /// Any time limit: none, one for the whole round, or one for each question. Saved as its kind
    /// and its amount, minutes for a round and seconds for a question.
    enum TimeLimit: Hashable, Identifiable {
        case off
        /// The whole round, against the clock: when it runs out, the round is over.
        case round(minutes: Int)
        /// Each question, against the clock: when it runs out, the answer's shown, and Next waits.
        case question(seconds: Int)

        static let roundMinutes = [3, 5, 10]
        static let questionSeconds = [15, 30, 60]
        static let roundChoices: [TimeLimit] = roundMinutes.map { .round(minutes: $0) }
        static let questionChoices: [TimeLimit] = questionSeconds.map { .question(seconds: $0) }

        var id: Self { self }

        var minutes: Int? {
            if case .round(let minutes) = self { minutes } else { nil }
        }

        var seconds: Int? {
            if case .question(let seconds) = self { seconds } else { nil }
        }

        /// As the lobby's pill shows it, such as "3 min total" or "15 s each".
        var name: String {
            switch self {
            case .off: "Off"
            case .round(let minutes): "\(minutes) min total"
            case .question(let seconds): seconds % 60 == 0 ? "\(seconds / 60) min each" : "\(seconds) s each"
            }
        }

        /// As its menu lists it, saying whether it's for the whole game or each question, such as
        /// "3 minutes per game" or "15 seconds per question".
        var menuName: String {
            switch self {
            case .off: "No time limit"
            case .round(let minutes): "\(Self.spelledOut(seconds: minutes * 60)) per game"
            case .question(let seconds): "\(Self.spelledOut(seconds: seconds)) per question"
            }
        }

        /// What VoiceOver hears for it.
        var spokenName: String {
            switch self {
            case .off: "Off"
            case .round(let minutes): "\(Self.spelledOut(seconds: minutes * 60)) per game"
            case .question(let seconds): "\(Self.spelledOut(seconds: seconds)) per question"
            }
        }

        /// "3 minutes", "1 minute" or "15 seconds".
        private static func spelledOut(seconds: Int) -> String {
            guard seconds % 60 == 0 else { return seconds == 1 ? "1 second" : "\(seconds) seconds" }
            let minutes = seconds / 60
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }

        var kind: String {
            switch self {
            case .off: "off"
            case .round: "round"
            case .question: "question"
            }
        }

        var amount: Int {
            minutes ?? seconds ?? 0
        }

        /// A saved limit, moved to the nearest one offered now if it's one no longer offered,
        /// such as a minute for the round, which becomes three.
        init(kind: String?, amount: Int) {
            func nearest(to amount: Int, in choices: [Int]) -> Int {
                choices.min { abs($0 - amount) < abs($1 - amount) } ?? amount
            }
            switch kind {
            case "round" where amount > 0: self = .round(minutes: nearest(to: amount, in: Self.roundMinutes))
            case "question" where amount > 0: self = .question(seconds: nearest(to: amount, in: Self.questionSeconds))
            default: self = .off
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
        guard phase == .asking || phase == .answered, questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    var isLastQuestion: Bool {
        index + 1 >= questions.count
    }

    /// How a mode's question is answered, with the options as they are. Flag can't be typed, so
    /// with Type chosen it offers every flag's name to pick from.
    func answerMethod(for mode: MapGameMode) -> AnswerMethod {
        switch mode {
        case .findIt: .map
        case .member: .inOrOut
        case .nameIt, .capitals, .outline, .code, .dot:
            switch answerStyle {
            case .type: .typing
            case .four: .four
            case .all: .list
            }
        case .flags: answerStyle == .four ? .four : .list
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
    /// question's four dealt.
    func start() {
        let pool = scopedPlaces
        var candidates = pool.shuffled()
        if mode == .code {
            // A code shared by several places, such as +1, comes up once a round.
            var seen: Set<String> = []
            candidates = candidates.filter { place in
                let values = codeValues(of: place)
                guard !values.isEmpty, values.isDisjoint(with: seen) else { return false }
                seen.formUnion(values)
                return true
            }
        }
        if mode == .member {
            questions = membershipQuestions(from: candidates)
        } else {
            questions = Array(candidates.prefix(questionCount(from: candidates.count)))
        }
        rotations = mode == .outline && outlineRotated
            ? Dictionary(uniqueKeysWithValues: questions.map { ($0.id, Self.randomTilt()) }) : [:]
        deals = isMultipleChoice ? Dictionary(uniqueKeysWithValues: questions.map { ($0.id, deal(for: $0, among: pool)) }) : [:]
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
        deadline = timeLimit.minutes.map { Date.now.addingTimeInterval(TimeInterval($0 * 60)) }
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
    private func startQuestionClock() {
        questionDeadline = phase == .asking ? timeLimit.seconds.map { Date.now.addingTimeInterval(TimeInterval($0)) } : nil
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
            settle(as: .right(tries: wrongGuesses.count + 1))
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
        if mode == .capitals { return (capitals[place.id] ?? []).flatMap(\.names) }
        return [place.name, place.localName, place.formalName].compactMap { $0 }
    }

    // MARK: Learning

    /// Starts browsing every place in play, in list order, from the first.
    func startLearning() {
        deadline = nil
        questionDeadline = nil
        learnPlaces = placesInPlay
        learnIndex = 0
        outcomes = [:]
        phase = learnPlaces.isEmpty ? .lobby : .learning
    }

    /// The place being browsed.
    var learnPlace: AdministrativeDivision? {
        guard phase == .learning, learnPlaces.indices.contains(learnIndex) else { return nil }
        return learnPlaces[learnIndex]
    }

    /// Moves on or back through the places, stopping at the first and the last, as a row of cards does.
    func step(by offset: Int) {
        guard phase == .learning, !learnPlaces.isEmpty else { return }
        learnIndex = min(max(learnIndex + offset, 0), learnPlaces.count - 1)
    }

    /// Jumps to a place, such as one tapped on the map.
    func learn(_ place: AdministrativeDivision) {
        guard let index = learnPlaces.firstIndex(of: place) else { return }
        learnIndex = index
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
        wrongGuesses = []
        wrongTyped = 0
        retries = 0
        correction = nil
        wrongDecoys = []
        typedNote = nil
        memberGuess = nil
        phase = .asking
        startQuestionClock()
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
        learnPlaces = []
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
        let isCode = mode == .code
        func pick(_ other: AdministrativeDivision) {
            // In Code, nothing else that shares any of its codes, which would be right too.
            guard picked.count < 3, !isCode || !sharesCode(other, with: place),
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
        static let timerKind = "gameTimerKind"
        static let timerAmount = "gameTimerAmount"
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
    private static func storedTimeLimit(in defaults: UserDefaults) -> TimeLimit {
        if let kind = defaults.string(forKey: Key.timerKind) {
            return TimeLimit(kind: kind, amount: defaults.integer(forKey: Key.timerAmount))
        }
        let minutes = ["one": 1, "three": 3, "five": 5, "ten": 10][defaults.string(forKey: Key.retiredTimeLimit) ?? ""]
        let limit = minutes.map { TimeLimit(kind: "round", amount: $0) } ?? .off
        defaults.set(limit.kind, forKey: Key.timerKind)
        defaults.set(limit.amount, forKey: Key.timerAmount)
        defaults.removeObject(forKey: Key.retiredTimeLimit)
        return limit
    }

    /// An angle well away from upright, either way round, for a turned outline.
    private static func randomTilt() -> Double {
        let tilt = Double.random(in: 35...150)
        return Bool.random() ? tilt : -tilt
    }

    // MARK: Results

    var rightCount: Int {
        outcomes.values.filter(\.isRightFirstTime).count
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

    /// Learn's colour, on its tile, its cards and the place it lights up: a calm indigo apart from
    /// the quizzes' candy, for browsing rather than playing.
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
    /// A group's near misses for Member?: its famous non-members, such as Norway and Switzerland
    /// for the EU, and the countries nearest its members, up to a dozen of them, in list order.
    fileprivate static func nearMisses(
        of group: WorldGroup?, members: [AdministrativeDivision], among outsiders: [AdministrativeDivision],
        frames: [String: CGRect]
    ) -> [AdministrativeDivision] {
        guard let group, !members.isEmpty else { return [] }
        let famous = Set(group.famousNonMembers)
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
        id == CountryCatalog.world.id || worldGroup != nil
    }
}

extension WorldGroup {
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
            group.divisions = group.divisions.filter { $0.countryID == id }
            return group.divisions.isEmpty ? nil : group
        }
        return own
    }
}
