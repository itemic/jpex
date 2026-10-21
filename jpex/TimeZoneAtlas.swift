import Foundation

/// The time kept somewhere: a time zone, the city it's known by, and where that city is.
struct ZoneClock: Hashable, Sendable {
    var timeZone: TimeZone
    /// Such as Chicago, or for a country's own time, its capital. Nil for a clock known only by
    /// its offset, such as the device set to UTC.
    var city: String?
    /// Longitude as x and latitude as y, in degrees, when known.
    var location: CGPoint?

    /// How far ahead of UTC the clock is at a moment, in seconds, summer time included.
    func offset(at date: Date) -> Int {
        timeZone.secondsFromGMT(for: date)
    }

    /// The clock's time of day at a moment, in hours from midnight.
    func hours(at date: Date) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        return Double(parts.hour ?? 0) + Double(parts.minute ?? 0) / 60 + Double(parts.second ?? 0) / 3600
    }
}

/// One time a place keeps at a moment, and the clocks keeping it: UTC−7 for the United States in
/// summer, kept by Phoenix and Los Angeles alike.
struct KeptTime: Identifiable, Hashable {
    /// How far ahead of UTC it is, in seconds.
    var offset: Int
    var id: Int { offset }
    /// The clocks keeping it, in the atlas's order, so the first is the one it's best known by.
    var clocks: [ZoneClock]

    /// Where in the place it's kept, by the cities its clocks are known by, as an address within
    /// it: "Easter Island", or where two share it, "Phoenix and Los Angeles". A time with no city
    /// to its name goes by its offset, "UTC+11".
    var cities: String {
        var seen: Set<String> = []
        let names = clocks.compactMap(\.city).filter { seen.insert($0).inserted }
        return names.isEmpty ? ZoneClock.utcName(offset: offset) : names.formatted(.list(type: .and))
    }
}

/// The time zones of the World's countries and territories, for World Time: each place's own time
/// first, kept in its capital, then any others it spans, such as the United States' Central and
/// Pacific time. Offsets and summer time come from the system's time zone database, so they're
/// right for any date, past or future.
enum TimeZoneAtlas {
    /// A World place's clocks, its capital's first. Empty for Antarctica, whose stations keep the
    /// times of the countries that run them.
    static func clocks(of place: AdministrativeDivision) -> [ZoneClock] {
        guard place.countryID == CountryCatalog.world.id else { return [] }
        return clocks[place.abbreviation] ?? []
    }

    /// Every time a place keeps at a moment, from the farthest behind UTC to the farthest ahead,
    /// each once with the clocks keeping it: seven for the United States in summer, when Phoenix
    /// and Los Angeles keep the same time, eleven for Russia. `lead`, the clock a pick leads with,
    /// heads its time's clocks, whether or not the table lists it: alone where none of the table's
    /// clocks keeps that time, and otherwise first among them, so the lit chip agrees with the
    /// card's header ("Krasnoyarsk and Novosibirsk" for a tap on Krasnoyarsk Krai, not Novosibirsk
    /// alone; "Los Angeles and Phoenix" for a tap on California) and a tap on it hands back the
    /// lead. Every other time reads the same wherever in the place it was picked.
    static func times(of place: AdministrativeDivision, at date: Date, including lead: ZoneClock? = nil) -> [KeptTime] {
        var byOffset: [Int: [ZoneClock]] = [:]
        for clock in Self.clocks(of: place) {
            byOffset[clock.offset(at: date), default: []].append(clock)
        }
        if let lead {
            let offset = lead.offset(at: date)
            // First among its time's clocks, once: where the table already keeps the lead's zone,
            // as it keeps Los Angeles after Phoenix, it's moved to the front rather than repeated.
            let others = (byOffset[offset] ?? []).filter { $0.timeZone.identifier != lead.timeZone.identifier }
            byOffset[offset] = [lead] + others
        }
        return byOffset.keys.sorted().map { KeptTime(offset: $0, clocks: byOffset[$0] ?? []) }
    }

    /// The person's own clock: the device's time zone, with its city and where that is when the
    /// atlas knows it, such as Taipei.
    static var here: ZoneClock {
        let zone = TimeZone.current
        let known = clocks.values.lazy.flatMap { $0 }.first { $0.timeZone.identifier == zone.identifier }
        // Places are named by their capitals, but here is the zone's own city: Sydney, not Canberra.
        return ZoneClock(timeZone: zone, city: cityName(of: zone.identifier), location: known?.location)
    }

    /// Every place's clocks, by ISO code, read once from the table.
    private static let clocks: [String: [ZoneClock]] = {
        let world = Dictionary(CountryCatalog.world.divisions.map { ($0.abbreviation, $0) }) { first, _ in first }
        var clocks: [String: [ZoneClock]] = [:]
        for (code, entry) in table {
            let capital = world[code].flatMap { CapitalCities.capitals(of: $0).first }
            let parsed = entry.components(separatedBy: ";").enumerated().compactMap { index, part in
                parse(part, capital: index == 0 ? capital : nil)
            }
            clocks[code] = parsed
        }
        return clocks
    }()

    /// One zone from the table: its identifier, then optionally the city it's known by, then
    /// optionally "@latitude,longitude". A country's first zone is kept in its capital, unless
    /// the table says otherwise.
    private static func parse(_ part: String, capital: CapitalCity?) -> ZoneClock? {
        var text = part.trimmingCharacters(in: .whitespaces)
        var location: CGPoint?
        if let at = text.firstIndex(of: "@") {
            let numbers = text[text.index(after: at)...].components(separatedBy: ",").compactMap { Double($0) }
            if numbers.count == 2 { location = CGPoint(x: numbers[1], y: numbers[0]) }
            text = String(text[..<at]).trimmingCharacters(in: .whitespaces)
        }
        let identifier = String(text.prefix { $0 != " " })
        let name = text.dropFirst(identifier.count).trimmingCharacters(in: .whitespaces)
        guard let zone = TimeZone(identifier: identifier) else { return nil }
        return ZoneClock(
            timeZone: zone,
            city: name.isEmpty ? capital?.name ?? cityName(of: identifier) : name,
            location: location ?? capital?.location)
    }

    /// The city a zone is named after, such as Los Angeles for America/Los_Angeles, or nil for a
    /// zone named only by its offset.
    static func cityName(of identifier: String) -> String? {
        guard identifier.contains("/"), !identifier.hasPrefix("Etc/"),
              let last = identifier.split(separator: "/").last
        else { return nil }
        return last.replacingOccurrences(of: "_", with: " ")
    }

    /// By ISO code: each place's time zones, separated by ";". A zone can carry the name it's known
    /// by and "@latitude,longitude", for zones away from the capital and places without one.
    /// Only zones keeping a time of their own are listed, so Argentina, China and India each keep one.
    private static let table: [String: String] = [
        // Africa
        "DZ": "Africa/Algiers", "AO": "Africa/Luanda", "BJ": "Africa/Porto-Novo", "BW": "Africa/Gaborone",
        "BF": "Africa/Ouagadougou", "BI": "Africa/Bujumbura", "CV": "Atlantic/Cape_Verde", "CM": "Africa/Douala",
        "CF": "Africa/Bangui", "TD": "Africa/Ndjamena", "KM": "Indian/Comoro", "CI": "Africa/Abidjan",
        "CD": "Africa/Kinshasa; Africa/Lubumbashi@-11.66,27.48", "DJ": "Africa/Djibouti", "EG": "Africa/Cairo",
        "GQ": "Africa/Malabo", "ER": "Africa/Asmara", "SZ": "Africa/Mbabane", "ET": "Africa/Addis_Ababa",
        "TF": "Indian/Kerguelen Port-aux-Français@-49.35,70.22", "GA": "Africa/Libreville", "GM": "Africa/Banjul",
        "GH": "Africa/Accra", "GN": "Africa/Conakry", "GW": "Africa/Bissau", "KE": "Africa/Nairobi",
        "LS": "Africa/Maseru", "LR": "Africa/Monrovia", "LY": "Africa/Tripoli", "MG": "Indian/Antananarivo",
        "MW": "Africa/Blantyre", "ML": "Africa/Bamako", "MR": "Africa/Nouakchott", "MU": "Indian/Mauritius",
        "YT": "Indian/Mayotte", "MA": "Africa/Casablanca", "MZ": "Africa/Maputo", "NA": "Africa/Windhoek",
        "NE": "Africa/Niamey", "NG": "Africa/Lagos", "CG": "Africa/Brazzaville", "RW": "Africa/Kigali",
        "RE": "Indian/Reunion", "SH": "Atlantic/St_Helena", "ST": "Africa/Sao_Tome", "SN": "Africa/Dakar",
        "SC": "Indian/Mahe", "SL": "Africa/Freetown", "SO": "Africa/Mogadishu", "ZA": "Africa/Johannesburg",
        "SS": "Africa/Juba", "SD": "Africa/Khartoum", "TZ": "Africa/Dar_es_Salaam", "TG": "Africa/Lome",
        "TN": "Africa/Tunis", "UG": "Africa/Kampala", "EH": "Africa/El_Aaiun", "ZM": "Africa/Lusaka",
        "ZW": "Africa/Harare",
        // Asia
        "AF": "Asia/Kabul", "AM": "Asia/Yerevan", "AZ": "Asia/Baku", "BH": "Asia/Bahrain", "BD": "Asia/Dhaka",
        "BT": "Asia/Thimphu", "IO": "Indian/Chagos Diego Garcia@-7.31,72.41", "BN": "Asia/Brunei",
        "KH": "Asia/Phnom_Penh", "CN": "Asia/Shanghai", "CX": "Indian/Christmas", "CC": "Indian/Cocos",
        "GE": "Asia/Tbilisi", "HK": "Asia/Hong_Kong Hong Kong@22.32,114.17", "IN": "Asia/Kolkata",
        "ID": "Asia/Jakarta; Asia/Makassar@-5.15,119.43; Asia/Jayapura@-2.53,140.72", "IR": "Asia/Tehran",
        "IQ": "Asia/Baghdad", "IL": "Asia/Jerusalem", "JP": "Asia/Tokyo", "JO": "Asia/Amman", "KZ": "Asia/Almaty",
        "KW": "Asia/Kuwait", "KG": "Asia/Bishkek", "LA": "Asia/Vientiane", "LB": "Asia/Beirut",
        "MO": "Asia/Macau Macao@22.20,113.54", "MY": "Asia/Kuala_Lumpur", "MV": "Indian/Maldives",
        "MN": "Asia/Ulaanbaatar; Asia/Hovd Khovd@48.01,91.64", "MM": "Asia/Yangon", "NP": "Asia/Kathmandu",
        "KP": "Asia/Pyongyang", "OM": "Asia/Muscat", "PK": "Asia/Karachi", "PS": "Asia/Hebron", "PH": "Asia/Manila",
        "QA": "Asia/Qatar", "SA": "Asia/Riyadh", "SG": "Asia/Singapore", "KR": "Asia/Seoul", "LK": "Asia/Colombo",
        "SY": "Asia/Damascus", "TW": "Asia/Taipei", "TJ": "Asia/Dushanbe", "TH": "Asia/Bangkok", "TL": "Asia/Dili",
        "TM": "Asia/Ashgabat", "TR": "Europe/Istanbul", "AE": "Asia/Dubai", "UZ": "Asia/Tashkent",
        "VN": "Asia/Ho_Chi_Minh", "YE": "Asia/Aden",
        // Europe
        "AL": "Europe/Tirane", "AD": "Europe/Andorra", "AT": "Europe/Vienna", "BY": "Europe/Minsk",
        "BE": "Europe/Brussels", "BA": "Europe/Sarajevo", "BG": "Europe/Sofia", "HR": "Europe/Zagreb",
        "CY": "Asia/Nicosia", "CZ": "Europe/Prague", "DK": "Europe/Copenhagen", "EE": "Europe/Tallinn",
        "FO": "Atlantic/Faroe", "FI": "Europe/Helsinki", "FR": "Europe/Paris", "DE": "Europe/Berlin",
        "GI": "Europe/Gibraltar", "GR": "Europe/Athens", "GG": "Europe/Guernsey", "HU": "Europe/Budapest",
        "IS": "Atlantic/Reykjavik", "IE": "Europe/Dublin", "IM": "Europe/Isle_of_Man", "IT": "Europe/Rome",
        "JE": "Europe/Jersey", "XK": "Europe/Belgrade", "LV": "Europe/Riga", "LI": "Europe/Vaduz",
        "LT": "Europe/Vilnius", "LU": "Europe/Luxembourg", "MT": "Europe/Malta", "MD": "Europe/Chisinau",
        "MC": "Europe/Monaco", "ME": "Europe/Podgorica", "NL": "Europe/Amsterdam", "MK": "Europe/Skopje",
        "XC": "Asia/Famagusta", "NO": "Europe/Oslo", "PL": "Europe/Warsaw",
        "PT": "Europe/Lisbon; Atlantic/Azores Azores@37.74,-25.67", "RO": "Europe/Bucharest",
        "RU": """
            Europe/Moscow; Europe/Kaliningrad@54.71,20.51; Europe/Samara@53.20,50.15; \
            Asia/Yekaterinburg@56.84,60.61; Asia/Omsk@54.99,73.37; Asia/Novosibirsk@55.03,82.92; \
            Asia/Irkutsk@52.29,104.30; Asia/Yakutsk@62.03,129.73; Asia/Vladivostok@43.12,131.89; \
            Asia/Magadan@59.56,150.80; Asia/Kamchatka Petropavlovsk-Kamchatsky@53.02,158.65
            """,
        "SM": "Europe/San_Marino", "RS": "Europe/Belgrade", "SK": "Europe/Bratislava", "SI": "Europe/Ljubljana",
        "ES": "Europe/Madrid; Atlantic/Canary Canary Islands@28.10,-15.41", "SJ": "Arctic/Longyearbyen",
        "SE": "Europe/Stockholm", "CH": "Europe/Zurich", "UA": "Europe/Kyiv", "GB": "Europe/London",
        "VA": "Europe/Vatican", "AX": "Europe/Mariehamn",
        // North America
        "AI": "America/Anguilla", "AG": "America/Antigua", "AW": "America/Aruba", "BS": "America/Nassau",
        "BB": "America/Barbados", "BZ": "America/Belize", "BM": "Atlantic/Bermuda", "BQ": "America/Kralendijk",
        "CA": """
            America/Toronto; America/Halifax@44.65,-63.57; America/St_Johns St. John’s@47.56,-52.71; \
            America/Winnipeg@49.90,-97.14; America/Regina@50.45,-104.61; America/Edmonton@53.55,-113.49; \
            America/Vancouver@49.28,-123.12; America/Whitehorse@60.72,-135.06
            """,
        "KY": "America/Cayman", "CR": "America/Costa_Rica", "CU": "America/Havana", "CW": "America/Curacao",
        "DM": "America/Dominica", "DO": "America/Santo_Domingo", "SV": "America/El_Salvador",
        "GL": "America/Nuuk; America/Danmarkshavn@76.77,-18.67; America/Thule Pituffik@76.53,-68.70",
        "GD": "America/Grenada", "GP": "America/Guadeloupe", "GT": "America/Guatemala", "HT": "America/Port-au-Prince",
        "HN": "America/Tegucigalpa", "JM": "America/Jamaica", "MQ": "America/Martinique",
        "MX": "America/Mexico_City; America/Cancun Cancún@21.16,-86.85; America/Mazatlan Mazatlán@23.25,-106.41; America/Tijuana@32.51,-117.04",
        "MS": "America/Montserrat", "NI": "America/Managua", "PA": "America/Panama", "PR": "America/Puerto_Rico",
        "BL": "America/St_Barthelemy", "KN": "America/St_Kitts", "LC": "America/St_Lucia", "MF": "America/Marigot",
        "PM": "America/Miquelon", "VC": "America/St_Vincent", "SX": "America/Lower_Princes",
        "TC": "America/Grand_Turk", "UM": "Pacific/Wake Wake Island@19.28,166.65; Pacific/Midway Midway Atoll@28.21,-177.38",
        "US": """
            America/New_York; America/Chicago@41.88,-87.63; America/Denver@39.74,-104.99; \
            America/Phoenix@33.45,-112.07; America/Los_Angeles@34.05,-118.24; America/Anchorage@61.22,-149.90; \
            America/Adak@51.88,-176.66; Pacific/Honolulu@21.31,-157.86
            """,
        "VG": "America/Tortola", "VI": "America/St_Thomas",
        // South America
        "AR": "America/Argentina/Buenos_Aires", "BO": "America/La_Paz",
        "BR": "America/Sao_Paulo; America/Manaus@-3.12,-60.02; America/Rio_Branco@-9.97,-67.81; America/Noronha Fernando de Noronha@-3.85,-32.42",
        "CL": "America/Santiago; America/Punta_Arenas@-53.16,-70.91; Pacific/Easter Easter Island@-27.15,-109.43",
        "CO": "America/Bogota", "EC": "America/Guayaquil; Pacific/Galapagos Galápagos@-0.90,-89.61",
        "FK": "Atlantic/Stanley", "GF": "America/Cayenne", "GY": "America/Guyana", "PY": "America/Asuncion",
        "PE": "America/Lima", "SR": "America/Paramaribo", "TT": "America/Port_of_Spain", "UY": "America/Montevideo",
        "VE": "America/Caracas",
        // Oceania
        "AS": "Pacific/Pago_Pago",
        "AU": """
            Australia/Sydney; Australia/Brisbane@-27.47,153.03; Australia/Adelaide@-34.93,138.60; \
            Australia/Darwin@-12.46,130.84; Australia/Perth@-31.95,115.86; Australia/Eucla@-31.68,128.88; \
            Australia/Lord_Howe Lord Howe Island@-31.55,159.08
            """,
        "CK": "Pacific/Rarotonga", "FM": "Pacific/Pohnpei; Pacific/Chuuk@7.45,151.85", "FJ": "Pacific/Fiji",
        "PF": "Pacific/Tahiti; Pacific/Marquesas Marquesas Islands@-9.00,-139.50; Pacific/Gambier Gambier Islands@-23.12,-134.97",
        "GU": "Pacific/Guam", "KI": "Pacific/Tarawa; Pacific/Kanton@-2.81,-171.67; Pacific/Kiritimati@1.87,-157.40",
        "MH": "Pacific/Majuro", "NR": "Pacific/Nauru", "NC": "Pacific/Noumea",
        "NZ": "Pacific/Auckland; Pacific/Chatham Chatham Islands@-43.95,-176.55", "NU": "Pacific/Niue",
        "NF": "Pacific/Norfolk", "MP": "Pacific/Saipan", "PW": "Pacific/Palau",
        "PG": "Pacific/Port_Moresby; Pacific/Bougainville@-6.23,155.57", "PN": "Pacific/Pitcairn",
        "WS": "Pacific/Apia", "SB": "Pacific/Guadalcanal", "TK": "Pacific/Fakaofo@-9.38,-171.22",
        "TO": "Pacific/Tongatapu", "TV": "Pacific/Funafuti", "VU": "Pacific/Efate", "WF": "Pacific/Wallis",
        // Uninhabited islands keep the time of their longitude.
        "BV": "Etc/GMT-1 Bouvet Island@-54.42,3.36", "HM": "Indian/Kerguelen Heard Island@-53.10,73.52",
        "GS": "Atlantic/South_Georgia King Edward Point@-54.28,-36.49",
    ]
}
