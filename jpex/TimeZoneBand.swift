import Foundation

/// Everywhere keeping one time at a moment, such as UTC+8: a card in World Time's list of zones.
/// One time can go by several names, each kept in its own places: UTC+8 is China Standard Time in
/// China, National Standard Time in Taiwan and Irkutsk time in part of Russia. The card leads with
/// one of them: the one the person picked, their own, the one kept where they've been highest, or
/// failing those the best known.
struct TimeZoneBand: Identifiable, Equatable {
    /// How far ahead of UTC its clocks are, in seconds.
    var offset: Int
    var id: Int { offset }
    /// Every name the time goes by, the best known first, and which of them the card leads with.
    var names: [ZoneName]
    var leading: Int
    /// Everywhere keeping the time, as cards to list: the places whose own time it is, then those
    /// keeping it in only part of their land, each in alphabetical order. Worked out once, as the
    /// zones are, so a list of them redrawn at every frame has nothing to work out.
    private(set) var sharers: [Sharer]

    init(offset: Int, names: [ZoneName], leading: Int) {
        self.offset = offset
        self.names = names
        self.leading = leading
        // A place keeps a time under one name only, so each is listed once.
        var seen: Set<String> = []
        let keepers = names.flatMap(\.keepers).filter { seen.insert($0.placeID).inserted }
        func sorted(_ keepers: [ZoneName.Keeper]) -> [Sharer] {
            keepers
                .map { Sharer(placeID: $0.placeID, name: $0.shortAddress, flagAssetName: $0.flagAssetName, isOwnTime: $0.isOwnTime) }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        sharers = sorted(keepers.filter(\.isOwnTime)) + sorted(keepers.filter { !$0.isOwnTime })
    }

    /// A place keeping a time, as its card in a list of them shows it.
    struct Sharer: Identifiable, Equatable {
        var placeID: String
        var id: String { placeID }
        /// The place's name, or for part of a country, where in it: "Irkutsk Oblast and Buryatia, Russia".
        var name: String
        var flagAssetName: String
        /// Whether it's the place's own time, rather than one of several it keeps across its land.
        var isOwnTime: Bool
    }

    /// The name the card leads with.
    var name: ZoneName { names[leading] }

    /// The place it's known by, and that place's clock keeping this time.
    var placeID: String { name.keepers[0].placeID }
    var flagAssetName: String { name.keepers[0].flagAssetName }
    var clock: ZoneClock { name.keepers[0].clock }

    /// The places whose own time it is, then those keeping it in only some of their zones.
    var placeIDs: [String] { names.flatMap { $0.keepers.filter(\.isOwnTime).map(\.placeID) } }
    var partlyPlaceIDs: [String] { names.flatMap { $0.keepers.filter { !$0.isOwnTime }.map(\.placeID) } }

    /// "UTC+9", "UTC+5:30", "UTC−3", or "UTC±0" itself.
    var utcName: String {
        ZoneClock.utcName(offset: offset)
    }

    /// The leading name, such as "Japan Standard Time" or "British Summer Time".
    func name(at date: Date) -> String {
        clock.name(at: date)
    }

    /// The letters the leading name goes by, such as JST, where it's widely known by any.
    func abbreviation(at date: Date) -> String? {
        clock.abbreviation(at: date)
    }

    /// The name after the leading one, going round, for the card to flip to.
    var nextName: ZoneName {
        names[(leading + 1) % names.count]
    }

    /// Where the zone's sky is: over the meridian its time is kept by, whichever of its names
    /// leads, so turning to another name never changes the sky it wears.
    var location: CGPoint {
        CGPoint(x: DayNight.normalized(Double(offset) / 240), y: 25)
    }

    /// How high the Sun stands over the zone, in degrees.
    func sunHeight(for sun: DayNight.Sun) -> Double {
        asin(min(max(sun.elevationSine(latitude: location.y, longitude: location.x), -1), 1)) * 180 / .pi
    }
}

/// One name a time goes by and the places keeping it under that name: China Standard Time in China
/// and Macao, or Irkutsk Standard Time in Irkutsk and Buryatia.
struct ZoneName: Identifiable, Equatable {
    /// Its name in the person's language, from the system's own: "China Standard Time".
    var name: String
    var id: String { name }
    /// Those keeping it, the best known first.
    var keepers: [Keeper]

    /// A place keeping a time under a name, and the clock it keeps it by.
    struct Keeper: Equatable {
        var placeID: String
        var placeName: String
        var flagAssetName: String
        var clock: ZoneClock
        /// Whether it's the place's own time, rather than one of several it keeps across its land.
        var isOwnTime: Bool

        /// Where it's kept, as an address: "Taiwan", or for part of a country, "Irkutsk, Russia".
        var label: String {
            guard !isOwnTime, let city = clock.city else { return placeName }
            return "\(city), \(placeName)"
        }

        /// For a country the atlas divides along its zones, the names of its subdivisions keeping
        /// this time, in its own list's order, and how many keep any time at all; nil for any other
        /// place. Worked out by the offset, not the clock, so a country with two clocks on one time,
        /// such as Sydney's and Hobart's, names every part keeping it, and none keeping another.
        var parts: [String]? = nil
        var partCount = 0

        /// Where it's kept, exactly: for a country divided along its zones, the provinces or states
        /// keeping it, a few by name, "Irkutsk Oblast and Buryatia, Russia", or many, "Alabama,
        /// Arkansas and 14 more, United States", or the country alone where all of it does;
        /// otherwise as `label` has it.
        var address: String {
            guard let parts else { return label }
            return Self.address(of: parts, count: partCount, in: placeName, naming: 3, isOwnTime: isOwnTime)
        }

        /// Where it's kept, short enough for a card in a list: for a country divided along its
        /// zones, the one or two provinces or states keeping it, "Queensland, Australia", or where
        /// more do, the first two and how many more, "New South Wales, Victoria and 3 more,
        /// Australia", or the country alone where all of it does; otherwise the place's name, or
        /// for part of it, the city its clock is set by.
        var shortAddress: String {
            guard let parts else { return label }
            return Self.address(of: parts, count: partCount, in: placeName, naming: 2, isOwnTime: isOwnTime)
        }

        /// The parts of a place keeping a time, as an address naming up to `limit` of them, then
        /// two and how many more; the place alone where every part, or none the atlas can name,
        /// keeps it, never a city or a part keeping another time. A country's own time kept by
        /// nearly all of it, as Spain's is by all but the Canaries, or by more parts than can be
        /// named, as Russia's Moscow time is, goes by the country's name alone, rather than a long
        /// run of its regions and how many more, which would read as one region rather than the
        /// country.
        private static func address(
            of parts: [String], count: Int, in placeName: String, naming limit: Int, isOwnTime: Bool
        ) -> String {
            guard !parts.isEmpty, parts.count < count,
                  !(isOwnTime && (parts.count * 4 >= count * 3 || parts.count > limit))
            else { return placeName }
            let shown = parts.count > limit ? Array(parts.prefix(2)) + ["\(parts.count - 2) more"] : parts
            return "\(shown.formatted(.list(type: .and))), \(placeName)"
        }
    }

    /// The clock it's best known by.
    var clock: ZoneClock { keepers[0].clock }

    /// Where it's kept, as addresses, down to the provinces of a country spanning zones: "China and
    /// Macao", or "Irkutsk Oblast and Buryatia, Russia"; kept in many places, the first two and how
    /// many more, "Iceland, Ghana and 14 more".
    var keptIn: String {
        let addresses = keepers.map(\.address)
        guard addresses.count > 3 else { return addresses.formatted(.list(type: .and)) }
        return (addresses.prefix(2) + ["\(addresses.count - 2) more"]).formatted(.list(type: .and))
    }

    /// Its zones in the tz database, such as Asia/Taipei, each once.
    var identifiers: [String] {
        var seen: Set<String> = []
        return keepers.map(\.clock.timeZone.identifier).filter { seen.insert($0).inserted }
    }
}

extension TimeZoneAtlas {
    /// Every time kept around the World at a moment, from the farthest behind UTC to the farthest
    /// ahead, each with every name it goes by. `rank` says how high the person's level is in a
    /// place, so their own places can lead; a name holding one of `preferred`'s zones, which the
    /// person flipped to, leads its card.
    static func bands(
        at date: Date, here: ZoneClock, preferred: Set<String> = [], rank: (AdministrativeDivision) -> Int
    ) -> [TimeZoneBand] {
        struct Member {
            var place: AdministrativeDivision
            var clock: ZoneClock
            var isOwnTime: Bool
            var parts: [String]?
            var partCount: Int
        }
        var members: [Int: [Member]] = [:]
        for place in CountryCatalog.world.divisions where place.id != DialPalette.antarcticaID {
            // A country divided along its zones names the parts of it keeping each of its times.
            let isDivided = dividedCountries.contains(place.abbreviation)
            let partCount = isDivided ? subdivisionCount(of: place) : 0
            var seen: Set<Int> = []
            for (index, clock) in clocks(of: place).enumerated() {
                let offset = clock.offset(at: date)
                // A place with two zones on one time, such as Phoenix and Los Angeles in summer, counts once.
                guard seen.insert(offset).inserted else { continue }
                let parts = isDivided ? subdivisionNames(of: place, atOffset: offset, date: date) : nil
                members[offset, default: []].append(
                    Member(place: place, clock: clock, isOwnTime: index == 0, parts: parts, partCount: partCount))
            }
        }
        func priority(_ member: Member) -> Int {
            leaders.firstIndex(of: member.place.abbreviation) ?? leaders.count
        }
        /// Higher ranked first, then the better known, then a place's own time before a part of it,
        /// then by name, so a card's names always come round in the same order.
        func comesFirst(_ a: Member, _ b: Member) -> Bool {
            let (rankA, rankB) = (rank(a.place), rank(b.place))
            if rankA != rankB { return rankA > rankB }
            if priority(a) != priority(b) { return priority(a) < priority(b) }
            if a.isOwnTime != b.isOwnTime { return a.isOwnTime }
            if a.place.name != b.place.name { return a.place.name < b.place.name }
            return a.clock.timeZone.identifier < b.clock.timeZone.identifier
        }
        let hereOffset = here.offset(at: date)
        let hereName = here.name(at: date)
        return members.keys.sorted().compactMap { offset in
            guard let group = members[offset], !group.isEmpty else { return nil }
            // One name for each zone name the system knows, its keepers in order.
            var byName: [String: [Member]] = [:]
            for member in group { byName[member.clock.name(at: date), default: []].append(member) }
            let named = byName.map { name, keepers in (name: name, keepers: keepers.sorted(by: comesFirst)) }
                .sorted { a, b in
                    a.keepers[0].place.id == b.keepers[0].place.id ? a.name < b.name : comesFirst(a.keepers[0], b.keepers[0])
                }
            let names = named.map { entry in
                ZoneName(name: entry.name, keepers: entry.keepers.map { member in
                    ZoneName.Keeper(
                        placeID: member.place.id, placeName: member.place.name, flagAssetName: member.place.flagAssetName,
                        clock: member.clock, isOwnTime: member.isOwnTime,
                        parts: member.parts, partCount: member.partCount)
                })
            }
            // The one the person flipped to; their own time, by its zone or failing that by its name;
            // otherwise the best known, first.
            let leading = names.firstIndex { !preferred.isDisjoint(with: $0.identifiers) }
                ?? (offset == hereOffset
                    ? names.firstIndex { $0.identifiers.contains(here.timeZone.identifier) } ?? names.firstIndex { $0.name == hereName }
                    : nil)
                ?? 0
            return TimeZoneBand(offset: offset, names: names, leading: leading)
        }
    }

    /// The best-known places, for leading a zone the person hasn't been to: the most populous and
    /// visited first, so UTC+8 is China's and UTC−5 in summer is the United States' Central time.
    private static let leaders = [
        "US", "CN", "IN", "JP", "GB", "FR", "DE", "RU", "BR", "AU", "CA", "MX", "ID", "KR", "IT", "ES", "TR", "SA", "ZA",
        "EG", "NG", "AR", "IR", "TH", "NZ", "PK", "BD", "VN", "PH", "KE", "ET", "CO", "PE", "CL", "VE", "UA", "PL", "AE",
        "MY", "SG", "MA", "DZ", "IQ", "AF", "MM", "NP", "LK", "KZ", "UZ", "MN", "FJ", "PG", "KI", "WS", "TO", "PF", "CK",
        "AS", "IS", "PT", "GL", "CV", "FK", "GS",
    ]
}
