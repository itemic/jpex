import Foundation

extension TimeZoneAtlas {
    /// The clock a subdivision of a country spanning several zones keeps, such as Pacific time for
    /// California or Irkutsk time for Buryatia, so a map coloured by time zone splits those
    /// countries where their zones divide them. Nil for places that keep their country's own time.
    static func clock(ofSubdivision id: String) -> ZoneClock? {
        subdivisionClocks[id]
    }

    /// The subdivisions of a country keeping a zone, by ID, such as RU-IRK and RU-BU, Irkutsk Oblast
    /// and Buryatia, for Irkutsk time.
    static func subdivisions(of country: String, keeping identifier: String) -> [String] {
        subdivisionClocks.filter { id, clock in id.hasPrefix("\(country)-") && clock.timeZone.identifier == identifier }
            .keys.sorted()
    }

    /// The names of a country's subdivisions keeping a zone, from its own list of them: Irkutsk
    /// Oblast and Buryatia for Russia's Irkutsk time. Empty for a country whose zones the atlas
    /// doesn't divide it by.
    static func subdivisionNames(of place: AdministrativeDivision, keeping identifier: String) -> [String] {
        guard dividedCountries.contains(place.abbreviation), let list = CountryCatalog.collection(for: place) else { return [] }
        let ids = Set(subdivisions(of: place.abbreviation, keeping: identifier))
        return list.divisions.filter { ids.contains($0.id) }.map(\.name)
    }

    /// The names of a country's subdivisions whose clocks stand at `offset` seconds ahead of UTC at
    /// a moment, in the order of its own list of them: New South Wales, Victoria, Tasmania and the
    /// rest of Australia's south east for UTC+11 in October, but not the Northern Territory, which
    /// keeps UTC+9:30 all year. A subdivision the table leaves out keeps the country's own time
    /// where the table lists only the exceptions, as Spain's does the Canaries; where it lists them
    /// all, one left out, such as Ashmore and Cartier Islands, keeps no time worth naming. Empty
    /// for a country the atlas doesn't divide by its zones.
    static func subdivisionNames(of place: AdministrativeDivision, atOffset offset: Int, date: Date) -> [String] {
        subdivisions(of: place, atOffset: offset, date: date).map(\.name)
    }

    /// How many of a country's subdivisions keep any time at all, for telling whether all of them
    /// keep one: those `subdivisionNames(of:atOffset:date:)` can name.
    static func subdivisionCount(of place: AdministrativeDivision) -> Int {
        guard dividedCountries.contains(place.abbreviation), let list = CountryCatalog.collection(for: place) else { return 0 }
        let main = clocks(of: place).first
        return list.divisions.filter { (clock(ofSubdivision: $0.id) ?? keptTime(of: place, main: main)) != nil }.count
    }

    /// A clock a place keeps at `offset` seconds ahead of UTC at a moment: one of its own, or for a
    /// country spanning zones, one of its subdivisions'. Nil where it keeps no such time.
    static func clock(of place: AdministrativeDivision, atOffset offset: Int, date: Date) -> ZoneClock? {
        if let own = clocks(of: place).first(where: { $0.offset(at: date) == offset }) { return own }
        guard dividedCountries.contains(place.abbreviation) else { return nil }
        return subdivisionIDs.lazy
            .filter { $0.hasPrefix("\(place.abbreviation)-") }
            .compactMap { clock(ofSubdivision: $0) }
            .first { $0.offset(at: date) == offset }
    }

    /// A country's subdivisions keeping a time at a moment, in the order of its list.
    private static func subdivisions(of place: AdministrativeDivision, atOffset offset: Int, date: Date) -> [AdministrativeDivision] {
        guard dividedCountries.contains(place.abbreviation), let list = CountryCatalog.collection(for: place) else { return [] }
        let main = clocks(of: place).first
        return list.divisions.filter { division in
            (clock(ofSubdivision: division.id) ?? keptTime(of: place, main: main))?.offset(at: date) == offset
        }
    }

    /// The time a subdivision the table leaves out keeps: its country's own, where the table lists
    /// only the exceptions to it; none, where it lists every subdivision keeping a time.
    private static func keptTime(of place: AdministrativeDivision, main: ZoneClock?) -> ZoneClock? {
        fullyListedCountries.contains(place.abbreviation) ? nil : main
    }

    /// The countries whose every subdivision keeping a time is in the table, rather than only those
    /// keeping another time than the country's own.
    private static let fullyListedCountries: Set<String> = ["US", "CA", "AU", "BR", "RU", "MX", "ID"]

    /// Every subdivision whose clock the atlas knows, by ID, in order.
    static let subdivisionIDs: [String] = subdivisionClocks.keys.sorted()

    /// Every subdivision's clock, read once from the table.
    private static let subdivisionClocks: [String: ZoneClock] = {
        var clocks: [String: ZoneClock] = [:]
        for (country, entries) in subdivisionTable {
            for entry in entries.split(separator: ";") {
                let parts = entry.split(separator: "=").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                guard parts.count == 2 else { continue }
                // A zone that may be newer than the system's time zone database names an older one after "|".
                let identifiers = parts[1].split(separator: "|").map(String.init)
                guard let zone = identifiers.lazy.compactMap(TimeZone.init(identifier:)).first else { continue }
                for code in parts[0].split(whereSeparator: \.isWhitespace) {
                    clocks["\(country)-\(code)"] = ZoneClock(timeZone: zone, city: cityName(of: zone.identifier))
                }
            }
        }
        return clocks
    }()

    /// By country: subdivision codes, then "=" and the zone they keep, each group separated by ";".
    /// Where a subdivision spans zones, such as Texas or Nunavut, it keeps the one most of its
    /// people do.
    private static let subdivisionTable: [String: String] = [
        "US": """
            CT DE DC FL GA IN KY ME MD MA MI NH NJ NY NC OH PA RI SC VT VA WV = America/New_York;
            AL AR IL IA KS LA MN MS MO NE ND OK SD TN TX WI = America/Chicago;
            CO MT NM UT WY ID = America/Denver; AZ = America/Phoenix; CA NV OR WA = America/Los_Angeles;
            AK = America/Anchorage; HI = Pacific/Honolulu; AS = Pacific/Pago_Pago; GU = Pacific/Guam;
            MP = Pacific/Saipan; PR = America/Puerto_Rico; VI = America/St_Thomas
            """,
        "CA": """
            BC = America/Vancouver; YT = America/Whitehorse; AB NT = America/Edmonton; SK = America/Regina;
            MB = America/Winnipeg; ON QC NU = America/Toronto; NB NS PE = America/Halifax; NL = America/St_Johns
            """,
        "AU": """
            NSW ACT VIC TAS JBT = Australia/Sydney; QLD CS = Australia/Brisbane; SA = Australia/Adelaide;
            NT = Australia/Darwin; WA = Australia/Perth; CX = Indian/Christmas; CC = Indian/Cocos;
            NF = Pacific/Norfolk; HM = Indian/Kerguelen
            """,
        "BR": """
            AL AP BA CE DF ES GO MA MG PA PB PE PI PR RJ RN RS SC SE SP TO = America/Sao_Paulo;
            AM = America/Manaus; MS = America/Campo_Grande; MT = America/Cuiaba; RO = America/Porto_Velho;
            RR = America/Boa_Vista; AC = America/Rio_Branco
            """,
        "RU": """
            KGD = Europe/Kaliningrad;
            AD ARK BEL BRY CE CU DA IN IVA KB KC KDA KIR KL KLU KO KOS KR KRS LEN LIP ME MO MOS MOW MUR NEN
            NGR NIZ ORL PNZ PSK ROS RYA SE SMO SPE STA TA TAM TUL TVE VLA VLG VOR VGG YAR = Europe/Moscow;
            SAM UD = Europe/Samara; AST = Europe/Astrakhan; SAR = Europe/Saratov; ULY = Europe/Ulyanovsk;
            BA CHE KGN ORE PER SVE TYU KHM YAN = Asia/Yekaterinburg; OMS = Asia/Omsk;
            NVS = Asia/Novosibirsk; TOM = Asia/Tomsk; KEM = Asia/Novokuznetsk; ALT AL = Asia/Barnaul;
            KK KYA TY = Asia/Krasnoyarsk; IRK BU = Asia/Irkutsk; ZAB = Asia/Chita; AMU SA = Asia/Yakutsk;
            PRI KHA YEV = Asia/Vladivostok; MAG = Asia/Magadan; SAK = Asia/Sakhalin;
            KAM = Asia/Kamchatka; CHU = Asia/Anadyr
            """,
        "MX": """
            AGU CAM CHP CMX COA COL DUR GRO GUA HID JAL MEX MIC MOR NLE OAX PUE QUE SLP TAB TAM TLA VER YUC
            ZAC CHH = America/Mexico_City; ROO = America/Cancun; BCS SIN NAY = America/Mazatlan;
            SON = America/Hermosillo; BCN = America/Tijuana
            """,
        "ID": """
            AC SU SB RI KR JA SS BB BE LA BT JK JB JT YO JI KB KT = Asia/Jakarta;
            BA NB NT KS KI KU SA GO ST SR SN SG = Asia/Makassar; MA MU PA PB PD PE PS PT = Asia/Jayapura
            """,
        "MN": "071 065 043 046 057 = Asia/Hovd",
        "CL": "MA = America/Punta_Arenas; AI = America/Coyhaique|America/Santiago",
        "EC": "W = Pacific/Galapagos",
        "ES": "CN = Atlantic/Canary",
        "PT": "20 = Atlantic/Azores; 30 = Atlantic/Madeira",
        "PG": "NSB = Pacific/Bougainville",
    ]

    /// The countries whose subdivisions keep more than one time, for colouring maps by zone.
    static let dividedCountries = ["US", "CA", "AU", "BR", "RU", "MX", "ID", "MN", "CL", "EC", "ES", "PT", "PG"]
}
