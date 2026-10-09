import Foundation

/// A place's capital city: its name, other names it's known by, and its part in governing when a
/// place shares the role between several, such as South Africa's three.
struct CapitalCity: Hashable, Sendable {
    var name: String
    var otherNames: [String] = []
    /// Such as "executive" or "seat of government", when there's more than one capital.
    var role: String?
    /// Where it is: longitude as x and latitude as y, in degrees. Known for the World's capitals.
    var location: CGPoint?

    /// Every name the city answers to.
    var names: [String] { [name] + otherNames }
}

/// The capitals of the World's countries and territories, and of the subdivisions of a few
/// countries where they're well known, for the Capitals quiz. Answers are forgiving: case, accents,
/// punctuation and "St" for "Saint" don't matter, and a small slip of the keyboard is let through.
enum CapitalCities {
    /// A place's capitals; empty when it has none, such as Antarctica.
    static func capitals(of place: AdministrativeDivision) -> [CapitalCity] {
        guard place.countryID == CountryCatalog.world.id else {
            return subdivisions[place.countryID]?[place.abbreviation] ?? []
        }
        var capitals = world[place.abbreviation] ?? []
        for (index, location) in (worldLocations[place.abbreviation] ?? []).enumerated() where capitals.indices.contains(index) {
            capitals[index].location = location
        }
        return capitals
    }

    /// The capital an answer names, allowing for a typo or two in longer names.
    static func match(_ answer: String, in capitals: [CapitalCity]) -> CapitalCity? {
        let typed = normalized(answer)
        guard !typed.isEmpty else { return nil }
        return capitals.first { capital in
            capital.names.contains { name in
                let target = normalized(name)
                return editDistance(typed, target) <= allowedSlips(for: target)
            }
        }
    }

    /// A name a typed answer matches: exactly, once case, accents and punctuation are set aside, or
    /// near enough, within a small typo.
    struct Match {
        var name: String
        var isExact: Bool
    }

    /// The name among several that a typed answer matches, exactly if it can, otherwise the nearest
    /// within a typo or two. Used for capitals and for places' own names alike.
    static func closest(_ answer: String, among names: [String]) -> Match? {
        let typed = normalized(answer)
        guard !typed.isEmpty else { return nil }
        if let exact = names.first(where: { normalized($0) == typed }) {
            return Match(name: exact, isExact: true)
        }
        let near = names
            .map { name in (name: name, target: normalized(name)) }
            .filter { !$0.target.isEmpty }
            .map { candidate in (name: candidate.name, slips: editDistance(typed, candidate.target), allowed: allowedSlips(for: candidate.target)) }
            .filter { $0.slips <= $0.allowed }
            .min { $0.slips < $1.slips }
        return near.map { Match(name: $0.name, isExact: false) }
    }

    /// Whether an answer already spells out a capital in full, so it can be taken as typed.
    static func isExact(_ answer: String, in capitals: [CapitalCity]) -> Bool {
        let typed = normalized(answer)
        return !typed.isEmpty && capitals.contains { $0.names.contains { normalized($0) == typed } }
    }

    /// Well-known cities in a place that aren't its capital, such as Sydney and Melbourne for
    /// Australia: the tempting wrong answers. None of a place's capitals is ever among them.
    static func notableCities(of place: AdministrativeDivision) -> [String] {
        let entry = place.countryID == CountryCatalog.world.id
            ? worldCities[place.abbreviation]
            : subdivisionCities[place.countryID]?[place.abbreviation]
        let capitalNames = Set(capitals(of: place).flatMap(\.names).map(normalized))
        return (entry ?? []).filter { !capitalNames.contains(normalized($0)) }
    }

    /// About one slip in every four letters: none for three letters or fewer, one from four, two
    /// from eight, three from twelve. Close enough counts as right; the right spelling is shown.
    private static func allowedSlips(for name: String) -> Int {
        name.count < 4 ? 0 : name.count / 4
    }

    /// Lowercased letters and digits only, without accents, with "saint" as "st".
    static func normalized(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        let words = folded
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { $0 == "saint" ? "st" : $0 }
        return words.joined()
    }

    /// The fewest single-letter changes, including swapping two neighbours, between two words.
    static func editDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { table[i][0] = i }
        for j in 0...b.count { table[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                table[i][j] = min(table[i - 1][j] + 1, table[i][j - 1] + 1, table[i - 1][j - 1] + cost)
                if i > 1, j > 1, a[i - 1] == b[j - 2], a[i - 2] == b[j - 1] {
                    table[i][j] = min(table[i][j], table[i - 2][j - 2] + 1)
                }
            }
        }
        return table[a.count][b.count]
    }

    // MARK: Tables

    /// Read from a compact form: capitals separated by ";", other names after "/", and a role in brackets.
    private static func table(_ entries: [String: String]) -> [String: [CapitalCity]] {
        entries.mapValues { entry in
            entry.components(separatedBy: ";").map { part in
                var text = part.trimmingCharacters(in: .whitespaces)
                var role: String?
                if let open = text.firstIndex(of: "("), text.hasSuffix(")") {
                    role = String(text[text.index(after: open)..<text.index(before: text.endIndex)])
                    text = text[..<open].trimmingCharacters(in: .whitespaces)
                }
                let names = text.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
                return CapitalCity(name: names[0], otherNames: Array(names.dropFirst()), role: role)
            }
        }
    }

    /// Read from a compact form: cities separated by ";".
    private static func cities(_ entries: [String: String]) -> [String: [String]] {
        entries.mapValues { entry in
            entry.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    }

    /// By ISO code. Places with no capital, such as Antarctica or Tokelau, whose seat rotates, are left out.
    private static let world = table([
        // Africa
        "DZ": "Algiers/Alger", "AO": "Luanda", "BJ": "Porto-Novo (official); Cotonou (seat of government)",
        "BW": "Gaborone", "BF": "Ouagadougou", "BI": "Gitega (political); Bujumbura (economic)", "CV": "Praia",
        "CM": "Yaoundé", "CF": "Bangui", "TD": "N'Djamena/Ndjamena", "KM": "Moroni",
        "CI": "Yamoussoukro (official); Abidjan (seat of government)", "CD": "Kinshasa", "DJ": "Djibouti/Djibouti City",
        "EG": "Cairo", "GQ": "Malabo", "ER": "Asmara", "SZ": "Mbabane (executive); Lobamba (legislative and royal)",
        "ET": "Addis Ababa", "GA": "Libreville", "GM": "Banjul", "GH": "Accra", "GN": "Conakry", "GW": "Bissau",
        "KE": "Nairobi", "LS": "Maseru", "LR": "Monrovia", "LY": "Tripoli", "MG": "Antananarivo", "MW": "Lilongwe",
        "ML": "Bamako", "MR": "Nouakchott", "MU": "Port Louis", "YT": "Mamoudzou", "MA": "Rabat", "MZ": "Maputo",
        "NA": "Windhoek", "NE": "Niamey", "NG": "Abuja", "CG": "Brazzaville", "RW": "Kigali", "RE": "Saint-Denis",
        "SH": "Jamestown", "ST": "São Tomé", "SN": "Dakar", "SC": "Victoria", "SL": "Freetown", "SO": "Mogadishu",
        "ZA": "Pretoria (executive); Cape Town (legislative); Bloemfontein (judicial)", "SS": "Juba",
        "SD": "Khartoum (official); Port Sudan (seat of government during the war)",
        "TZ": "Dodoma (official); Dar es Salaam (largest city and former capital)", "TG": "Lomé", "TN": "Tunis",
        "UG": "Kampala", "EH": "Laayoune/El Aaiún (administered by Morocco); Tifariti (claimed by the Sahrawi Republic)",
        "ZM": "Lusaka", "ZW": "Harare",
        // Asia
        "AF": "Kabul", "AM": "Yerevan", "AZ": "Baku", "BH": "Manama", "BD": "Dhaka", "BT": "Thimphu",
        "BN": "Bandar Seri Begawan", "KH": "Phnom Penh", "CN": "Beijing/Peking", "CX": "Flying Fish Cove",
        "CC": "West Island", "GE": "Tbilisi", "IN": "New Delhi",
        "ID": "Jakarta (official); Nusantara (designated, being built)", "IR": "Tehran", "IQ": "Baghdad",
        "IL": "Jerusalem (proclaimed; not recognised by most countries)", "JP": "Tokyo", "JO": "Amman",
        "KZ": "Astana/Nur-Sultan", "KW": "Kuwait City", "KG": "Bishkek", "LA": "Vientiane", "LB": "Beirut",
        "MY": "Kuala Lumpur (official); Putrajaya (administrative)", "MV": "Malé", "MN": "Ulaanbaatar/Ulan Bator",
        "MM": "Naypyidaw/Nay Pyi Taw", "NP": "Kathmandu", "KP": "Pyongyang", "OM": "Muscat", "PK": "Islamabad",
        "PS": "East Jerusalem/Jerusalem (proclaimed); Ramallah (administrative)", "PH": "Manila", "QA": "Doha",
        "SA": "Riyadh", "SG": "Singapore", "KR": "Seoul",
        "LK": "Sri Jayawardenepura Kotte/Kotte (legislative); Colombo (executive and commercial)",
        "SY": "Damascus", "TW": "Taipei", "TJ": "Dushanbe", "TH": "Bangkok", "TL": "Dili", "TM": "Ashgabat",
        "TR": "Ankara", "AE": "Abu Dhabi", "UZ": "Tashkent", "VN": "Hanoi",
        "YE": "Sanaa/Sana'a (constitutional); Aden (temporary seat of government)",
        // Europe
        "AL": "Tirana", "AD": "Andorra la Vella", "AT": "Vienna/Wien", "BY": "Minsk", "BE": "Brussels/Bruxelles/Brussel",
        "BA": "Sarajevo", "BG": "Sofia", "HR": "Zagreb", "CY": "Nicosia", "CZ": "Prague/Praha",
        "DK": "Copenhagen/København", "EE": "Tallinn", "FO": "Tórshavn", "FI": "Helsinki", "FR": "Paris",
        "DE": "Berlin", "GI": "Gibraltar", "GR": "Athens", "GG": "St Peter Port", "VA": "Vatican City",
        "HU": "Budapest", "IS": "Reykjavík", "IE": "Dublin", "IM": "Douglas", "IT": "Rome/Roma", "JE": "St Helier",
        "XK": "Pristina/Prishtina", "XC": "North Nicosia/Lefkoşa", "LV": "Riga", "LI": "Vaduz", "LT": "Vilnius", "LU": "Luxembourg/Luxembourg City",
        "MT": "Valletta", "MD": "Chișinău", "MC": "Monaco", "ME": "Podgorica (official); Cetinje (old royal capital)",
        "NL": "Amsterdam (constitutional); The Hague/Den Haag (seat of government)", "MK": "Skopje", "NO": "Oslo",
        "PL": "Warsaw/Warszawa", "PT": "Lisbon/Lisboa", "RO": "Bucharest", "RU": "Moscow", "SM": "San Marino",
        "RS": "Belgrade", "SK": "Bratislava", "SI": "Ljubljana", "ES": "Madrid", "SJ": "Longyearbyen",
        "SE": "Stockholm", "CH": "Bern/Berne (federal city)", "UA": "Kyiv/Kiev", "GB": "London", "AX": "Mariehamn",
        // The Americas
        "AI": "The Valley", "AG": "St. John's", "AW": "Oranjestad", "BS": "Nassau", "BB": "Bridgetown",
        "BZ": "Belmopan", "BM": "Hamilton", "BQ": "Kralendijk", "CA": "Ottawa", "KY": "George Town",
        "CR": "San José", "CU": "Havana/La Habana", "CW": "Willemstad", "DM": "Roseau", "DO": "Santo Domingo",
        "SV": "San Salvador", "GL": "Nuuk", "GD": "St. George's", "GP": "Basse-Terre", "GT": "Guatemala City",
        "HT": "Port-au-Prince", "HN": "Tegucigalpa", "JM": "Kingston", "MQ": "Fort-de-France",
        "MX": "Mexico City/Ciudad de México", "MS": "Plymouth (official, abandoned after the eruption); Brades (in use)",
        "NI": "Managua", "PA": "Panama City", "PR": "San Juan", "BL": "Gustavia", "KN": "Basseterre",
        "LC": "Castries", "MF": "Marigot", "PM": "Saint-Pierre", "VC": "Kingstown", "SX": "Philipsburg",
        "TC": "Cockburn Town", "US": "Washington, D.C./Washington/Washington DC", "VG": "Road Town",
        "VI": "Charlotte Amalie", "AR": "Buenos Aires", "BO": "Sucre (constitutional); La Paz (seat of government)",
        "BR": "Brasília", "CL": "Santiago", "CO": "Bogotá", "EC": "Quito", "FK": "Stanley", "GF": "Cayenne",
        "GY": "Georgetown", "PY": "Asunción", "PE": "Lima", "SR": "Paramaribo", "TT": "Port of Spain",
        "UY": "Montevideo", "VE": "Caracas",
        // Oceania
        "AS": "Pago Pago", "AU": "Canberra", "CK": "Avarua", "FM": "Palikir", "FJ": "Suva", "PF": "Papeete",
        "GU": "Hagåtña/Agana", "KI": "South Tarawa/Tarawa", "MH": "Majuro", "NR": "Yaren (seat of government)",
        "NC": "Nouméa", "NZ": "Wellington", "PG": "Port Moresby", "NU": "Alofi", "NF": "Kingston", "MP": "Saipan", "PW": "Ngerulmud",
        "PN": "Adamstown", "WS": "Apia", "SB": "Honiara", "TO": "Nukuʻalofa/Nuku'alofa", "TV": "Funafuti",
        "VU": "Port Vila", "WF": "Mata-Utu",
    ])

    /// Where the World's capitals are, as "latitude,longitude", in the same order as their capitals.
    private static let worldLocations: [String: [CGPoint]] = ([
        "DZ": "36.75,3.06", "AO": "-8.84,13.23", "BJ": "6.50,2.60;6.37,2.39", "BW": "-24.65,25.91", "BF": "12.37,-1.53", "BI": "-3.43,29.92;-3.38,29.36",
        "CV": "14.93,-23.51", "CM": "3.87,11.52", "CF": "4.39,18.56", "TD": "12.13,15.06", "KM": "-11.70,43.26", "CI": "6.82,-5.28;5.36,-4.01",
        "CD": "-4.32,15.31", "DJ": "11.59,43.15", "EG": "30.04,31.24", "GQ": "3.75,8.78", "ER": "15.32,38.93", "SZ": "-26.31,31.14;-26.45,31.21",
        "ET": "9.03,38.74", "GA": "0.42,9.47", "GM": "13.45,-16.58", "GH": "5.60,-0.19", "GN": "9.64,-13.58", "GW": "11.86,-15.60",
        "KE": "-1.29,36.82", "LS": "-29.31,27.48", "LR": "6.30,-10.80", "LY": "32.89,13.19", "MG": "-18.88,47.51", "MW": "-13.96,33.79",
        "ML": "12.64,-8.00", "MR": "18.08,-15.98", "MU": "-20.16,57.50", "YT": "-12.78,45.23", "MA": "34.02,-6.83", "MZ": "-25.97,32.57",
        "NA": "-22.56,17.08", "NE": "13.51,2.11", "NG": "9.08,7.40", "CG": "-4.26,15.24", "RW": "-1.94,30.06", "RE": "-20.88,55.45",
        "SH": "-15.92,-5.72", "ST": "0.34,6.73", "SN": "14.72,-17.47", "SC": "-4.62,55.45", "SL": "8.48,-13.23", "SO": "2.05,45.32",
        "ZA": "-25.75,28.19;-33.92,18.42;-29.12,26.21", "SS": "4.85,31.58", "SD": "15.50,32.56;19.62,37.22", "TZ": "-6.16,35.75;-6.79,39.21", "TG": "6.13,1.22", "TN": "36.81,10.18",
        "UG": "0.35,32.58", "EH": "27.15,-13.20;26.16,-10.57", "ZM": "-15.39,28.32", "ZW": "-17.83,31.05", "AF": "34.53,69.17", "AM": "40.18,44.51",
        "AZ": "40.41,49.87", "BH": "26.23,50.59", "BD": "23.81,90.41", "BT": "27.47,89.64", "BN": "4.89,114.94", "KH": "11.56,104.92",
        "CN": "39.90,116.41", "CX": "-10.42,105.68", "CC": "-12.19,96.83", "GE": "41.72,44.79", "IN": "28.61,77.21", "ID": "-6.21,106.85;-0.97,116.70",
        "IR": "35.69,51.39", "IQ": "33.31,44.36", "IL": "31.77,35.21", "JP": "35.68,139.69", "JO": "31.95,35.93", "KZ": "51.17,71.43",
        "KW": "29.38,47.99", "KG": "42.87,74.59", "LA": "17.98,102.63", "LB": "33.89,35.50", "MY": "3.14,101.69;2.93,101.69", "MV": "4.18,73.51",
        "MN": "47.89,106.91", "MM": "19.76,96.08", "NP": "27.72,85.32", "KP": "39.04,125.76", "OM": "23.59,58.41", "PK": "33.68,73.05",
        "PS": "31.78,35.23;31.90,35.20", "PH": "14.60,120.98", "QA": "25.29,51.53", "SA": "24.71,46.68", "SG": "1.35,103.82", "KR": "37.57,126.98",
        "LK": "6.89,79.92;6.93,79.86", "SY": "33.51,36.28", "TW": "25.03,121.57", "TJ": "38.56,68.79", "TH": "13.76,100.50", "TL": "-8.56,125.57",
        "TM": "37.96,58.33", "TR": "39.93,32.86", "AE": "24.45,54.38", "UZ": "41.30,69.24", "VN": "21.03,105.85", "YE": "15.37,44.19;12.79,45.03",
        "AL": "41.33,19.82", "AD": "42.51,1.52", "AT": "48.21,16.37", "BY": "53.90,27.56", "BE": "50.85,4.35", "BA": "43.86,18.41",
        "BG": "42.70,23.32", "HR": "45.81,15.98", "CY": "35.19,33.38", "CZ": "50.08,14.44", "DK": "55.68,12.57", "EE": "59.44,24.75",
        "FO": "62.01,-6.77", "FI": "60.17,24.94", "FR": "48.86,2.35", "DE": "52.52,13.40", "GI": "36.14,-5.35", "GR": "37.98,23.73",
        "GG": "49.46,-2.54", "VA": "41.90,12.45", "HU": "47.50,19.04", "IS": "64.15,-21.94", "IE": "53.35,-6.26", "IM": "54.15,-4.48",
        "IT": "41.90,12.50", "JE": "49.19,-2.11", "XK": "42.66,21.17", "XC": "35.20,33.36", "LV": "56.95,24.11", "LI": "47.14,9.52", "LT": "54.69,25.28",
        "LU": "49.61,6.13", "MT": "35.90,14.51", "MD": "47.01,28.86", "MC": "43.74,7.42", "ME": "42.44,19.26;42.39,18.92", "NL": "52.37,4.90;52.08,4.30",
        "MK": "41.99,21.43", "NO": "59.91,10.75", "PL": "52.23,21.01", "PT": "38.72,-9.14", "RO": "44.43,26.10", "RU": "55.76,37.62",
        "SM": "43.94,12.45", "RS": "44.79,20.45", "SK": "48.15,17.11", "SI": "46.06,14.51", "ES": "40.42,-3.70", "SJ": "78.22,15.65",
        "SE": "59.33,18.07", "CH": "46.95,7.45", "UA": "50.45,30.52", "GB": "51.51,-0.13", "AX": "60.10,19.93", "AI": "18.22,-63.06",
        "AG": "17.12,-61.85", "AW": "12.52,-70.03", "BS": "25.05,-77.35", "BB": "13.10,-59.62", "BZ": "17.25,-88.76", "BM": "32.29,-64.78",
        "BQ": "12.15,-68.27", "CA": "45.42,-75.70", "KY": "19.29,-81.38", "CR": "9.93,-84.08", "CU": "23.11,-82.37", "CW": "12.11,-68.93",
        "DM": "15.30,-61.39", "DO": "18.49,-69.93", "SV": "13.69,-89.22", "GL": "64.18,-51.69", "GD": "12.06,-61.75", "GP": "16.00,-61.73",
        "GT": "14.63,-90.51", "HT": "18.59,-72.31", "HN": "14.07,-87.19", "JM": "18.02,-76.80", "MQ": "14.62,-61.06", "MX": "19.43,-99.13",
        "MS": "16.71,-62.22;16.79,-62.21", "NI": "12.11,-86.24", "PA": "8.98,-79.52", "PR": "18.47,-66.11", "BL": "17.90,-62.85", "KN": "17.30,-62.72",
        "LC": "14.01,-60.99", "MF": "18.07,-63.08", "PM": "46.78,-56.18", "VC": "13.16,-61.23", "SX": "18.03,-63.05", "TC": "21.46,-71.14",
        "US": "38.91,-77.04", "VG": "18.43,-64.62", "VI": "18.34,-64.93", "AR": "-34.60,-58.38", "BO": "-19.04,-65.26;-16.50,-68.15", "BR": "-15.79,-47.88",
        "CL": "-33.45,-70.67", "CO": "4.71,-74.07", "EC": "-0.18,-78.47", "FK": "-51.70,-57.85", "GF": "4.92,-52.33", "GY": "6.80,-58.16",
        "PY": "-25.26,-57.58", "PE": "-12.05,-77.04", "SR": "5.85,-55.20", "TT": "10.66,-61.51", "UY": "-34.90,-56.16", "VE": "10.48,-66.90",
        "AS": "-14.28,-170.70", "AU": "-35.28,149.13", "CK": "-21.21,-159.78", "FM": "6.92,158.16", "FJ": "-18.14,178.44", "PF": "-17.54,-149.57",
        "GU": "13.48,144.75", "KI": "1.33,172.98", "MH": "7.09,171.38", "NR": "-0.55,166.92", "NC": "-22.28,166.46", "NZ": "-41.29,174.78",
        "NU": "-19.06,-169.92", "NF": "-29.05,167.96", "MP": "15.18,145.75", "PW": "7.50,134.62", "PN": "-25.07,-130.10", "WS": "-13.83,-171.76",
        "SB": "-9.43,159.95", "TO": "-21.14,-175.20", "TV": "-8.52,179.20", "VU": "-17.73,168.32", "WF": "-13.28,-176.17", "PG": "-9.44,147.18",
    ] as [String: String]).mapValues { entry in
        entry.components(separatedBy: ";").compactMap { pair in
            let numbers = pair.components(separatedBy: ",").compactMap { Double($0) }
            return numbers.count == 2 ? CGPoint(x: numbers[1], y: numbers[0]) : nil
        }
    }

    /// By country, then by each subdivision's abbreviation.
    private static let subdivisions: [String: [String: [CapitalCity]]] = [
        "JP": table([
            "01": "Sapporo/札幌", "02": "Aomori/青森", "03": "Morioka/盛岡", "04": "Sendai/仙台", "05": "Akita/秋田",
            "06": "Yamagata/山形", "07": "Fukushima/福島", "08": "Mito/水戸", "09": "Utsunomiya/宇都宮",
            "10": "Maebashi/前橋", "11": "Saitama/さいたま", "12": "Chiba/千葉", "13": "Tokyo/Shinjuku/東京/新宿",
            "14": "Yokohama/横浜", "15": "Niigata/新潟", "16": "Toyama/富山", "17": "Kanazawa/金沢", "18": "Fukui/福井",
            "19": "Kofu/Kōfu/甲府", "20": "Nagano/長野", "21": "Gifu/岐阜", "22": "Shizuoka/静岡", "23": "Nagoya/名古屋",
            "24": "Tsu/津", "25": "Otsu/Ōtsu/大津", "26": "Kyoto/京都", "27": "Osaka/大阪", "28": "Kobe/神戸",
            "29": "Nara/奈良", "30": "Wakayama/和歌山", "31": "Tottori/鳥取", "32": "Matsue/松江", "33": "Okayama/岡山",
            "34": "Hiroshima/広島", "35": "Yamaguchi/山口", "36": "Tokushima/徳島", "37": "Takamatsu/高松",
            "38": "Matsuyama/松山", "39": "Kochi/Kōchi/高知", "40": "Fukuoka/福岡", "41": "Saga/佐賀",
            "42": "Nagasaki/長崎", "43": "Kumamoto/熊本", "44": "Oita/Ōita/大分", "45": "Miyazaki/宮崎",
            "46": "Kagoshima/鹿児島", "47": "Naha/那覇",
        ]),
        "US": table([
            "AL": "Montgomery", "AK": "Juneau", "AZ": "Phoenix", "AR": "Little Rock", "CA": "Sacramento",
            "CO": "Denver", "CT": "Hartford", "DE": "Dover", "FL": "Tallahassee", "GA": "Atlanta", "HI": "Honolulu",
            "ID": "Boise", "IL": "Springfield", "IN": "Indianapolis", "IA": "Des Moines", "KS": "Topeka",
            "KY": "Frankfort", "LA": "Baton Rouge", "ME": "Augusta", "MD": "Annapolis", "MA": "Boston",
            "MI": "Lansing", "MN": "Saint Paul", "MS": "Jackson", "MO": "Jefferson City", "MT": "Helena",
            "NE": "Lincoln", "NV": "Carson City", "NH": "Concord", "NJ": "Trenton", "NM": "Santa Fe",
            "NY": "Albany", "NC": "Raleigh", "ND": "Bismarck", "OH": "Columbus", "OK": "Oklahoma City",
            "OR": "Salem", "PA": "Harrisburg", "RI": "Providence", "SC": "Columbia", "SD": "Pierre",
            "TN": "Nashville", "TX": "Austin", "UT": "Salt Lake City", "VT": "Montpelier", "VA": "Richmond",
            "WA": "Olympia", "WV": "Charleston", "WI": "Madison", "WY": "Cheyenne", "DC": "Washington",
            "AS": "Pago Pago", "GU": "Hagåtña/Agana", "MP": "Saipan", "PR": "San Juan", "VI": "Charlotte Amalie",
        ]),
        "AU": table([
            "NSW": "Sydney", "QLD": "Brisbane", "SA": "Adelaide", "TAS": "Hobart", "VIC": "Melbourne", "WA": "Perth",
            "ACT": "Canberra", "NT": "Darwin", "CX": "Flying Fish Cove", "CC": "West Island", "NF": "Kingston",
        ]),
        "CA": table([
            "AB": "Edmonton", "BC": "Victoria", "MB": "Winnipeg", "NB": "Fredericton", "NL": "St. John's",
            "NS": "Halifax", "ON": "Toronto", "PE": "Charlottetown", "QC": "Quebec City/Québec", "SK": "Regina",
            "NT": "Yellowknife", "NU": "Iqaluit", "YT": "Whitehorse",
        ]),
        "GB": table(["ENG": "London", "SCT": "Edinburgh", "WLS": "Cardiff", "NIR": "Belfast"]),
    ]

    // MARK: Cities that aren't capitals

    /// Two or three well-known cities in each place that aren't any of its capitals, by ISO code,
    /// for Capital's tempting wrong answers. Places without well-known cities beyond their capital
    /// are left out.
    private static let worldCities = cities([
        // Africa
        "DZ": "Oran; Constantine; Annaba", "AO": "Huambo; Lobito; Benguela", "BJ": "Parakou; Abomey; Djougou",
        "BW": "Francistown; Maun; Serowe", "BF": "Bobo-Dioulasso; Koudougou; Banfora", "BI": "Ngozi; Muyinga",
        "CV": "Mindelo; Santa Maria", "CM": "Douala; Garoua; Bamenda", "CF": "Bimbo; Berbérati; Bambari",
        "TD": "Moundou; Sarh; Abéché", "KM": "Mutsamudu; Fomboni", "CI": "Bouaké; Daloa; San-Pédro",
        "CD": "Lubumbashi; Kisangani; Goma", "DJ": "Ali Sabieh; Tadjourah", "EG": "Alexandria; Giza; Luxor",
        "GQ": "Bata; Ebebiyín", "ER": "Massawa; Keren; Assab", "SZ": "Manzini; Nhlangano",
        "ET": "Dire Dawa; Gondar; Mekelle", "GA": "Port-Gentil; Franceville", "GM": "Serekunda; Brikama",
        "GH": "Kumasi; Tamale; Takoradi", "GN": "Nzérékoré; Kankan; Kindia", "GW": "Bafatá; Gabú",
        "KE": "Mombasa; Kisumu; Nakuru", "LS": "Teyateyaneng; Mafeteng", "LR": "Gbarnga; Buchanan",
        "LY": "Benghazi; Misrata; Sirte", "MG": "Toamasina; Antsirabe; Mahajanga", "MW": "Blantyre; Mzuzu",
        "ML": "Timbuktu; Sikasso; Mopti", "MR": "Nouadhibou; Kiffa", "MU": "Curepipe; Quatre Bornes",
        "MA": "Casablanca; Marrakesh; Fez", "MZ": "Beira; Nampula; Matola", "NA": "Walvis Bay; Swakopmund; Rundu",
        "NE": "Maradi; Agadez; Tahoua", "NG": "Lagos; Kano; Ibadan", "CG": "Pointe-Noire; Dolisie",
        "RW": "Huye; Musanze; Rubavu", "RE": "Saint-Pierre; Saint-Paul; Le Tampon", "SN": "Touba; Thiès; Saint-Louis",
        "SL": "Bo; Kenema; Makeni", "SO": "Kismayo; Bosaso; Baidoa", "ZA": "Johannesburg; Durban",
        "SS": "Wau; Malakal", "SD": "Omdurman; Kassala; Nyala", "TZ": "Arusha; Mwanza; Mbeya",
        "TG": "Sokodé; Kara; Kpalimé", "TN": "Sfax; Sousse; Kairouan", "UG": "Entebbe; Gulu; Jinja",
        "ZM": "Ndola; Kitwe; Livingstone", "ZW": "Bulawayo; Mutare; Victoria Falls",
        // Asia
        "AF": "Kandahar; Herat; Mazar-i-Sharif", "AM": "Gyumri; Vanadzor", "AZ": "Ganja; Sumgait",
        "BH": "Muharraq; Riffa", "BD": "Chittagong; Khulna; Sylhet", "BT": "Paro; Phuntsholing; Punakha",
        "BN": "Kuala Belait; Seria", "KH": "Siem Reap; Battambang; Sihanoukville", "CN": "Shanghai; Guangzhou; Shenzhen",
        "GE": "Batumi; Kutaisi; Rustavi", "IN": "Mumbai; Kolkata; Bengaluru", "ID": "Surabaya; Bandung; Medan",
        "IR": "Isfahan; Mashhad; Shiraz", "IQ": "Basra; Mosul; Erbil", "IL": "Tel Aviv; Haifa; Eilat",
        "JP": "Osaka; Kyoto; Yokohama", "JO": "Aqaba; Irbid; Zarqa", "KZ": "Almaty; Shymkent; Karaganda",
        "KW": "Salmiya; Jahra", "KG": "Osh; Jalal-Abad; Karakol", "LA": "Luang Prabang; Pakse; Savannakhet",
        "LB": "Tripoli; Sidon; Byblos", "MY": "Johor Bahru; George Town; Kota Kinabalu", "MV": "Addu City; Fuvahmulah",
        "MN": "Erdenet; Darkhan", "MM": "Yangon; Mandalay; Bagan", "NP": "Pokhara; Lalitpur; Biratnagar",
        "KP": "Hamhung; Chongjin; Kaesong", "OM": "Salalah; Sohar; Nizwa", "PK": "Karachi; Lahore; Peshawar",
        "PH": "Quezon City; Cebu City; Davao City", "QA": "Al Wakrah; Al Rayyan; Lusail", "SA": "Jeddah; Mecca; Medina",
        "KR": "Busan; Incheon; Daegu", "LK": "Kandy; Galle; Jaffna", "SY": "Aleppo; Homs; Latakia",
        "TW": "Kaohsiung; Taichung; Tainan", "TJ": "Khujand; Kulob", "TH": "Chiang Mai; Phuket; Pattaya",
        "TL": "Baucau; Maliana", "TM": "Türkmenabat; Mary; Dashoguz", "TR": "Istanbul; Izmir; Antalya",
        "AE": "Dubai; Sharjah; Al Ain", "UZ": "Samarkand; Bukhara; Namangan", "VN": "Ho Chi Minh City; Da Nang; Haiphong",
        "YE": "Taiz; Mukalla; Hodeidah",
        // Europe
        "AL": "Durrës; Vlorë; Shkodër", "AD": "Escaldes-Engordany; Encamp", "AT": "Salzburg; Graz; Innsbruck",
        "BY": "Brest; Gomel; Grodno", "BE": "Antwerp; Ghent; Bruges", "BA": "Mostar; Banja Luka; Tuzla",
        "BG": "Plovdiv; Varna; Burgas", "HR": "Split; Dubrovnik; Rijeka", "CY": "Limassol; Larnaca; Paphos",
        "CZ": "Brno; Ostrava; Pilsen", "DK": "Aarhus; Odense; Aalborg", "EE": "Tartu; Pärnu; Narva",
        "FO": "Klaksvík", "FI": "Tampere; Turku; Oulu", "FR": "Lyon; Marseille; Toulouse",
        "DE": "Munich; Hamburg; Frankfurt", "GR": "Thessaloniki; Patras; Heraklion", "HU": "Debrecen; Szeged; Pécs",
        "IS": "Akureyri; Kópavogur", "IE": "Cork; Galway; Limerick", "IT": "Milan; Naples; Venice",
        "XK": "Prizren; Gjakova", "LV": "Daugavpils; Liepāja; Jūrmala", "LI": "Schaan; Triesen",
        "LT": "Kaunas; Klaipėda; Šiauliai", "LU": "Esch-sur-Alzette; Differdange", "MT": "Sliema; Birkirkara; Mdina",
        "MD": "Bălți; Cahul; Orhei", "ME": "Nikšić; Budva; Kotor", "NL": "Rotterdam; Utrecht; Eindhoven",
        "MK": "Bitola; Ohrid; Kumanovo", "NO": "Bergen; Trondheim; Stavanger", "PL": "Kraków; Gdańsk; Wrocław",
        "PT": "Porto; Braga; Faro", "RO": "Cluj-Napoca; Timișoara; Iași", "RU": "Saint Petersburg; Novosibirsk; Yekaterinburg",
        "RS": "Novi Sad; Niš; Kragujevac", "SK": "Košice; Žilina; Nitra", "SI": "Maribor; Celje; Koper",
        "ES": "Barcelona; Seville; Valencia", "SE": "Gothenburg; Malmö; Uppsala", "CH": "Zurich; Geneva; Basel",
        "UA": "Kharkiv; Odesa; Lviv", "GB": "Manchester; Birmingham; Glasgow",
        // The Americas
        "BS": "Freeport; Marsh Harbour", "BB": "Speightstown; Holetown", "BZ": "Belize City; San Ignacio; Orange Walk Town",
        "CA": "Toronto; Montreal; Vancouver", "CR": "Limón; Alajuela; Puntarenas", "CU": "Santiago de Cuba; Camagüey; Holguín",
        "DO": "Santiago de los Caballeros; Puerto Plata; La Romana", "SV": "Santa Ana; San Miguel",
        "GL": "Sisimiut; Ilulissat", "GP": "Pointe-à-Pitre; Les Abymes", "GT": "Antigua Guatemala; Quetzaltenango; Escuintla",
        "HT": "Cap-Haïtien; Gonaïves; Les Cayes", "HN": "San Pedro Sula; La Ceiba; Comayagua",
        "JM": "Montego Bay; Spanish Town; Ocho Rios", "MQ": "Le Lamentin; Le Robert", "MX": "Guadalajara; Monterrey; Cancún",
        "NI": "León; Granada; Masaya", "PA": "Colón; David", "PR": "Ponce; Bayamón; Mayagüez", "LC": "Vieux Fort; Gros Islet",
        "VI": "Christiansted; Frederiksted", "US": "New York City; Los Angeles; Chicago",
        "AR": "Córdoba; Rosario; Mendoza", "BO": "Santa Cruz de la Sierra; Cochabamba; El Alto",
        "BR": "Rio de Janeiro; São Paulo; Salvador", "CL": "Concepción; Antofagasta; Viña del Mar",
        "CO": "Medellín; Cali; Cartagena", "EC": "Guayaquil; Cuenca; Manta", "GF": "Kourou; Saint-Laurent-du-Maroni",
        "GY": "Linden; New Amsterdam", "PY": "Ciudad del Este; Encarnación", "PE": "Cusco; Arequipa; Trujillo",
        "SR": "Lelydorp; Nieuw Nickerie", "TT": "San Fernando; Chaguanas; Arima", "UY": "Salto; Paysandú; Punta del Este",
        "VE": "Maracaibo; Valencia; Barquisimeto",
        // Oceania
        "AU": "Sydney; Melbourne; Brisbane", "FM": "Kolonia; Weno", "FJ": "Nadi; Lautoka; Levuka",
        "PF": "Faaa; Punaauia", "GU": "Dededo; Tamuning", "MH": "Ebeye", "NC": "Dumbéa; Mont-Dore",
        "NZ": "Auckland; Christchurch; Queenstown", "PG": "Lae; Mount Hagen; Madang", "PW": "Koror",
        "SB": "Gizo; Auki", "TO": "Neiafu", "VU": "Luganville",
    ])

    /// By country, then by each subdivision's abbreviation, as the capitals are.
    private static let subdivisionCities: [String: [String: [String]]] = [
        "JP": cities([
            "01": "Hakodate; Asahikawa; Otaru", "02": "Hachinohe; Hirosaki", "03": "Hanamaki; Ichinoseki; Kitakami",
            "04": "Ishinomaki; Kesennuma", "05": "Yokote; Odate", "06": "Sakata; Yonezawa; Tsuruoka",
            "07": "Koriyama; Iwaki; Aizuwakamatsu", "08": "Tsukuba; Hitachi; Tsuchiura", "09": "Nikko; Oyama; Ashikaga",
            "10": "Takasaki; Kiryu; Ota", "11": "Kawagoe; Kawaguchi; Tokorozawa", "12": "Funabashi; Narita; Kashiwa",
            "13": "Hachioji; Machida; Tachikawa", "14": "Kawasaki; Sagamihara; Kamakura", "15": "Nagaoka; Joetsu",
            "16": "Takaoka; Tonami", "17": "Komatsu; Kaga; Wajima", "18": "Tsuruga; Obama", "19": "Fujiyoshida; Kai",
            "20": "Matsumoto; Ueda", "21": "Takayama; Ogaki; Tajimi", "22": "Hamamatsu; Numazu; Fuji",
            "23": "Toyota; Okazaki; Toyohashi", "24": "Yokkaichi; Ise; Suzuka", "25": "Hikone; Kusatsu; Nagahama",
            "26": "Uji; Maizuru; Fukuchiyama", "27": "Sakai; Higashiosaka; Toyonaka", "28": "Himeji; Nishinomiya; Amagasaki",
            "29": "Kashihara; Ikoma", "30": "Tanabe; Shingu", "31": "Yonago; Kurayoshi", "32": "Izumo; Hamada",
            "33": "Kurashiki; Tsuyama", "34": "Fukuyama; Kure; Onomichi", "35": "Shimonoseki; Ube; Iwakuni",
            "36": "Naruto; Anan", "37": "Marugame; Sakaide", "38": "Imabari; Niihama; Uwajima", "39": "Shimanto; Nankoku",
            "40": "Kitakyushu; Kurume; Dazaifu", "41": "Karatsu; Imari; Tosu", "42": "Sasebo; Isahaya; Shimabara",
            "43": "Yatsushiro; Amakusa; Aso", "44": "Beppu; Nakatsu; Yufu", "45": "Miyakonojo; Nobeoka",
            "46": "Kirishima; Kanoya; Amami", "47": "Okinawa City; Urasoe; Nago",
        ]),
        "US": cities([
            "AL": "Birmingham; Mobile; Huntsville", "AK": "Anchorage; Fairbanks", "AZ": "Tucson; Mesa; Flagstaff",
            "AR": "Fort Smith; Fayetteville", "CA": "Los Angeles; San Francisco; San Diego",
            "CO": "Colorado Springs; Boulder; Aurora", "CT": "Bridgeport; New Haven; Stamford", "DE": "Wilmington; Newark",
            "FL": "Miami; Orlando; Tampa", "GA": "Savannah; Augusta; Macon", "HI": "Hilo; Kailua",
            "ID": "Idaho Falls; Pocatello; Coeur d'Alene", "IL": "Chicago; Aurora; Peoria",
            "IN": "Fort Wayne; Evansville; Bloomington", "IA": "Cedar Rapids; Davenport; Iowa City",
            "KS": "Wichita; Kansas City; Overland Park", "KY": "Louisville; Lexington",
            "LA": "New Orleans; Shreveport; Lafayette", "ME": "Portland; Bangor; Lewiston", "MD": "Baltimore; Frederick",
            "MA": "Worcester; Springfield; Cambridge", "MI": "Detroit; Grand Rapids; Ann Arbor",
            "MN": "Minneapolis; Duluth; Rochester", "MS": "Gulfport; Biloxi; Hattiesburg",
            "MO": "Kansas City; St. Louis; Springfield", "MT": "Billings; Missoula; Bozeman", "NE": "Omaha; Grand Island",
            "NV": "Las Vegas; Reno; Henderson", "NH": "Manchester; Nashua; Portsmouth",
            "NJ": "Newark; Jersey City; Atlantic City", "NM": "Albuquerque; Las Cruces; Roswell",
            "NY": "New York City; Buffalo; Rochester", "NC": "Charlotte; Greensboro; Durham",
            "ND": "Fargo; Grand Forks; Minot", "OH": "Cleveland; Cincinnati; Toledo", "OK": "Tulsa; Norman",
            "OR": "Portland; Eugene; Bend", "PA": "Philadelphia; Pittsburgh; Allentown", "RI": "Warwick; Newport; Cranston",
            "SC": "Charleston; Greenville; Myrtle Beach", "SD": "Sioux Falls; Rapid City",
            "TN": "Memphis; Knoxville; Chattanooga", "TX": "Houston; Dallas; San Antonio", "UT": "Provo; Ogden; St. George",
            "VT": "Burlington; Rutland", "VA": "Virginia Beach; Norfolk; Arlington", "WA": "Seattle; Spokane; Tacoma",
            "WV": "Huntington; Morgantown; Wheeling", "WI": "Milwaukee; Green Bay", "WY": "Casper; Laramie; Jackson",
            "PR": "Ponce; Bayamón; Mayagüez", "GU": "Dededo; Tamuning", "VI": "Christiansted; Frederiksted",
        ]),
        "AU": cities([
            "NSW": "Newcastle; Wollongong", "QLD": "Gold Coast; Cairns; Townsville", "SA": "Mount Gambier; Whyalla",
            "TAS": "Launceston; Devonport", "VIC": "Geelong; Ballarat; Bendigo", "WA": "Fremantle; Bunbury; Broome",
            "NT": "Alice Springs; Katherine",
        ]),
        "CA": cities([
            "AB": "Calgary; Red Deer; Lethbridge", "BC": "Vancouver; Kelowna; Surrey", "MB": "Brandon; Churchill",
            "NB": "Moncton; Saint John", "NL": "Corner Brook; Gander", "NS": "Truro; Sydney; Yarmouth",
            "ON": "Mississauga; Hamilton; Sudbury", "PE": "Summerside", "QC": "Montreal; Gatineau; Laval",
            "SK": "Saskatoon; Moose Jaw; Prince Albert", "NT": "Inuvik; Hay River", "NU": "Rankin Inlet; Cambridge Bay",
            "YT": "Dawson City; Watson Lake",
        ]),
        "GB": cities([
            "ENG": "Manchester; Birmingham; Liverpool", "SCT": "Glasgow; Aberdeen; Dundee",
            "WLS": "Swansea; Newport; Wrexham", "NIR": "Derry; Lisburn; Armagh",
        ]),
    ]
}

/// The codes places go by, for Code: World countries' two-letter ISO codes and their internet
/// domains, their international calling codes, their airports' prefixes and their currencies,
/// several places sometimes sharing one; and a few countries' codes for their own places, such as
/// Chinese provinces' short names, Japanese and Korean area codes, and the first digit of
/// Australian postcodes.
enum PlaceCodes {
    /// A place's internet domain, such as ".de": its ISO code, except where the domain differs, as
    /// the UK's .uk does, and nil where it has none in use.
    static func domain(ofCode code: String) -> String? {
        guard code.count == 2, !domainless.contains(code) else { return nil }
        return "." + (domainExceptions[code] ?? code.lowercased())
    }

    /// A place's international calling code, such as "+44", by ISO code; nil where it isn't known here.
    static func callingCode(ofCode code: String) -> String? {
        callingCodes[code].map { "+" + $0 }
    }

    /// The letters on the oval sticker a place's cars carry abroad, by ISO code; nil where it isn't known here.
    static func vehicleCode(ofCode code: String) -> String? {
        vehicleCodes[code]
    }

    /// The letters a place competes under at the Olympic Games, by ISO code; nil where it has no
    /// national Olympic committee or isn't known here.
    static func olympicCode(ofCode code: String) -> String? {
        olympicCodes[code]
    }

    /// The letters a place's national football team plays under, by ISO code: FIFA's code for its
    /// member association, such as "GER" for Germany. The United Kingdom plays as four teams, so it
    /// has all four of theirs; nil for places outside FIFA, such as Greenland, Monaco or the Vatican.
    static func fifaCode(ofCode code: String) -> String? {
        code == "GB" ? britishFIFACodes.map(\.team).joined(separator: separator) : fifaCodes[code]
    }

    /// The team one of the United Kingdom's nations plays as, by its abbreviation in the app, as
    /// when the four count as countries of their own: SCO for Scotland, WAL for Wales.
    static func fifaCode(ofNation code: String) -> String? {
        britishFIFACodes.first { $0.nation == code }?.team
    }

    /// The United Kingdom's four teams, in the order FIFA lists them, by their nations' abbreviations.
    private static let britishFIFACodes: [(nation: String, team: String)] = [
        ("ENG", "ENG"), ("SCT", "SCO"), ("WLS", "WAL"), ("NIR", "NIR"),
    ]

    /// A Chinese province's, region's or municipality's short name, its 简称, by its country and
    /// its abbreviation: the one character it goes by, on its number plates and in names such as
    /// 京沪, the line between Beijing and Shanghai, or 川菜, Sichuan's cooking.
    static func shortName(country: String, code: String) -> String? {
        country == "CN" ? chineseShortNames[code] : nil
    }

    /// What a first-level place's number plates begin with, by its country and its own code: the
    /// letter on a Polish voivodeship's or a Czech region's, such as W for Masovia or A for Prague.
    static func plateCode(country: String, code: String) -> String? {
        switch country {
        case "PL": polishPlateLetters[code]
        case "CZ": czechPlateLetters[code]
        default: nil
        }
    }

    /// A first-level place's telephone area code, as dialled at home with its leading 0, by its
    /// country and its own code: a Japanese prefecture's, its capital's, such as 03 for Tokyo, or a
    /// Korean province's or city's, such as 02 for Seoul; nil where it isn't known here.
    static func areaCode(country: String, code: String) -> String? {
        switch country {
        case "JP": japaneseAreaCodes[code]
        case "KR": koreanAreaCodes[code]
        default: nil
        }
    }

    /// Each prefecture's capital's area code, by its ISO 3166-2:JP number. A prefecture dials
    /// several; its capital's is the one it's known by. Toyama and Kanazawa share 076, so Toyama
    /// and Ishikawa do, as Tokushima and Kōchi share 088.
    private static let japaneseAreaCodes: [String: String] = [
        "01": "011", "02": "017", "03": "019", "04": "022", "05": "018", "06": "023", "07": "024", "08": "029",
        "09": "028", "10": "027", "11": "048", "12": "043", "13": "03", "14": "045", "15": "025", "16": "076",
        "17": "076", "18": "0776", "19": "055", "20": "026", "21": "058", "22": "054", "23": "052", "24": "059",
        "25": "077", "26": "075", "27": "06", "28": "078", "29": "0742", "30": "073", "31": "0857", "32": "0852",
        "33": "086", "34": "082", "35": "083", "36": "088", "37": "087", "38": "089", "39": "088", "40": "092",
        "41": "0952", "42": "095", "43": "096", "44": "097", "45": "0985", "46": "099", "47": "098",
    ]

    /// Each Korean province's and city's area code, by its ISO 3166-2:KR number, or for
    /// Jeonnam-Gwangju, formed in July 2026 and not yet given one, the app's JG. It dials both
    /// South Jeolla's 061 and Gwangju's 062, which the two kept when they joined.
    private static let koreanAreaCodes: [String: String] = [
        "11": "02", "26": "051", "27": "053", "28": "032", "30": "042", "31": "052", "50": "044",
        "JG": ["061", "062"].joined(separator: separator), "41": "031", "42": "033", "43": "043",
        "44": "041", "45": "063", "47": "054", "48": "055", "49": "064",
    ]

    /// The digit an Australian state's or territory's postcodes begin with, by its country and its
    /// abbreviation, such as 2 for New South Wales or 0 for the Northern Territory; nil where it
    /// has no postcode of its own.
    static func postcodeDigit(country: String, code: String) -> String? {
        country == "AU" ? australianPostcodeDigits[code] : nil
    }

    /// The first digit of the postcodes on a place's streets, by its abbreviation. The ACT shares
    /// New South Wales's 2, its own running 2600 to 2618 and 2900 to 2920, and so do Jervis Bay, on
    /// 2540, and Norfolk Island, on 2899; Christmas Island and the Cocos Islands take Western
    /// Australia's 6, on 6798 and 6799; and the Antarctic bases and Heard Island take Tasmania's 7,
    /// on 7151. Post-office boxes and big mail rooms have ranges of their own, such as New South
    /// Wales's 1 and the ACT's 02, which aren't asked about. The Coral Sea Islands and Ashmore and
    /// Cartier have no postcode.
    private static let australianPostcodeDigits: [String: String] = [
        "NSW": "2", "ACT": "2", "VIC": "3", "QLD": "4", "SA": "5", "WA": "6", "TAS": "7", "NT": "0",
        "JBT": "2", "NF": "2", "CX": "6", "CC": "6", "AAT": "7", "HM": "7",
    ]

    /// The letter a voivodeship's plates begin with, by its ISO 3166-2:PL number.
    private static let polishPlateLetters: [String: String] = [
        "02": "D", "04": "C", "06": "L", "08": "F", "10": "E", "12": "K", "14": "W", "16": "O",
        "18": "R", "20": "B", "22": "G", "24": "S", "26": "T", "28": "N", "30": "P", "32": "Z",
    ]

    /// The letter a region's plates carry, by its ISO 3166-2:CZ number.
    private static let czechPlateLetters: [String: String] = [
        "10": "A", "20": "S", "31": "C", "32": "P", "41": "K", "42": "U", "51": "L", "52": "H",
        "53": "E", "63": "J", "64": "B", "71": "M", "72": "Z", "80": "T",
    ]

    /// The nationality mark an aircraft's registration begins with, by ISO code, such as "JA" for
    /// Japan; nil where it isn't known here.
    static func aircraftPrefix(ofCode code: String) -> String? {
        severalAircraftPrefixes[code]?.joined(separator: separator) ?? aircraftPrefixes[code]
    }

    /// What separates a place's codes where it genuinely has several of one kind, such as
    /// Brazil's aircraft prefixes: "PP, PR, PS, PT, PU".
    static let separator = ", "

    /// Read from codes each followed by the ISO code it belongs to, such as "D DE".
    private static func pairs(_ text: String) -> [String: String] {
        var codes: [String: String] = [:]
        for pair in text.split(separator: ",") {
            let parts = pair.split(separator: " ")
            guard parts.count == 2 else { continue }
            codes[String(parts[1])] = String(parts[0])
        }
        return codes
    }

    /// International distinguishing signs under the Vienna and Geneva conventions, as they stand:
    /// the UK's has been UK since 2021, North Macedonia's NMK since 2019. Places whose current sign
    /// isn't certain here are left out.
    private static let vehicleCodes = pairs("""
        A AT,AFG AF,AL AL,AM AM,AND AD,ANG AO,AUS AU,AZ AZ,B BE,BD BD,BDS BB,BF BF,BG BG,BIH BA,\
        BOL BO,BR BR,BRN BH,BRU BN,BS BS,BY BY,C CU,CDN CA,CH CH,CI CI,CL LK,CO CO,CR CR,CY CY,CZ CZ,\
        D DE,DK DK,DOM DO,DY BJ,DZ DZ,E ES,EAK KE,EAT TZ,EAU UG,EC EC,ER ER,ES SV,EST EE,ET EG,ETH ET,\
        F FR,FIN FI,FJI FJ,FL LI,FO FO,G GA,UK GB,GBA GG,GBJ JE,GBM IM,GBZ GI,GCA GT,GE GE,GH GH,\
        GR GR,GUY GY,H HU,HKJ JO,HR HR,I IT,IL IL,IND IN,IR IR,IRL IE,IRQ IQ,IS IS,J JP,JA JM,K KH,\
        KS KG,KSA SA,KWT KW,KZ KZ,L LU,LAO LA,LAR LY,LB LR,LS LS,LT LT,LV LV,M MT,MA MA,MAL MY,MC MC,\
        MD MD,MEX MX,MGL MN,MNE ME,MOC MZ,MS MU,MW MW,N NO,NAM NA,NEP NP,NIC NI,NL NL,NMK MK,NZ NZ,\
        OM OM,P PT,PA PA,PE PE,PK PK,PL PL,PNG PG,PY PY,Q QA,RA AR,RC TW,RCA CF,RCB CG,RCH CL,RG GN,\
        RH HT,RI ID,RIM MR,RKS XK,RL LB,RM MG,RMM ML,RN NE,RO RO,ROK KR,ROU UY,RSM SM,RU BI,RUS RU,\
        RWA RW,S SE,SGP SG,SK SK,SLO SI,SME SR,SN SN,SO SO,SRB RS,SUD SD,SY SC,SYR SY,T TH,TG TG,\
        TJ TJ,TM TM,TN TN,TR TR,TT TT,UA UA,UAE AE,USA US,UZ UZ,V VA,VN VN,WAG GM,WAL SL,WD DM,\
        WG GD,WL LC,WS WS,WV VC,YV VE,Z ZM,ZA ZA,ZW ZW
        """)

    /// ICAO nationality marks, the letters or figures an aircraft's registration begins with, as
    /// painted on its tail or fuselage: JA for Japan, N for the United States, G for the UK. China
    /// and Taiwan both register under B, so they share it as places share +1; Hong Kong and Macau
    /// are told apart by their own letter after it, B-H and B-M, as their registrations read.
    /// Places whose mark isn't certain here are left out.
    /// Places that register aircraft under several nationality marks: Brazil under five, Mexico
    /// under three, by use, and Argentina under LV, with LQ for its government's.
    private static let severalAircraftPrefixes: [String: [String]] = [
        "BR": ["PP", "PR", "PS", "PT", "PU"],
        "MX": ["XA", "XB", "XC"],
        "AR": ["LV", "LQ"],
    ]

    private static let aircraftPrefixes = pairs("""
        JA JP,N US,G GB,D DE,F FR,VH AU,C CA,B CN,B TW,B-H HK,B-M MO,HL KR,I IT,EC ES,PH NL,OO BE,\
        LX LU,HB CH,OE AT,SE SE,LN NO,OY DK,OH FI,TF IS,EI IE,CS PT,SX GR,SP PL,OK CZ,OM SK,HA HU,\
        YR RO,LZ BG,9A HR,S5 SI,YU RS,Z3 MK,ZA AL,E7 BA,4O ME,ES EE,YL LV,LY LT,EW BY,UR UA,ER MD,\
        RA RU,4X IL,TC TR,5B CY,9H MT,A6 AE,A7 QA,A9C BH,9K KW,A4O OM,HZ SA,JY JO,OD LB,YK SY,YI IQ,\
        EP IR,7O YE,YA AF,AP PK,VT IN,4R LK,S2 BD,9N NP,A5 BT,8Q MV,9M MY,9V SG,PK ID,RP PH,HS TH,\
        XU KH,RDPL LA,XY MM,VN VN,V8 BN,4W TL,P2 PG,DQ FJ,ZK NZ,YJ VU,H4 SB,A3 TO,5W WS,T3 KI,C2 NR,\
        T2 TV,V7 MH,V6 FM,T8A PW,ZS ZA,5Y KE,5H TZ,5X UG,9XR RW,9U BI,ET ET,SU EG,CN MA,7T DZ,TS TN,\
        5A LY,ST SD,Z8 SS,5N NG,9G GH,6V SN,TU CI,TJ CM,9Q CD,TN CG,TR GA,TL CF,3C GQ,S9 ST,D2 AO,\
        C9 MZ,9J ZM,Z ZW,A2 BW,V5 NA,7P LS,3D SZ,7Q MW,5R MG,3B MU,S7 SC,D6 KM,J2 DJ,6O SO,E3 ER,\
        5T MR,TZ ML,5U NE,TT TD,XT BF,TY BJ,5V TG,3X GN,9L SL,A8 LR,C5 GM,J5 GW,D4 CV,CC CL,\
        HK CO,OB PE,HC EC,YV VE,CP BO,ZP PY,CX UY,TI CR,HP PA,YS SV,TG GT,HR HN,YN NI,CU CU,HI DO,\
        HH HT,6Y JM,8P BB,C6 BS,9Y TT,8R GY,PZ SR,V3 BZ,J6 LC,J8 VC,J3 GD,J7 DM,V4 KN,V2 AG,UP KZ,\
        UK UZ,EX KG,EY TJ,EZ TM,4L GE,EK AM,4K AZ,JU MN,P KP,T7 SM,3A MC,HV VA,C3 AD,M IM,VP-B BM,\
        VP-C KY,P4 AW,PJ CW
        """)

    /// The letters a place's airports' four-letter ICAO codes begin with, by ISO code, such as "RJ"
    /// for Japan's, as in RJTT for Haneda, or "K" for the United States', as in KJFK; nil where it
    /// has no airport or isn't known here.
    static func airportPrefix(ofCode code: String) -> String? {
        severalAirportPrefixes[code]?.joined(separator: separator) ?? airportPrefixes[code]
    }

    /// Places whose airports take several prefixes, the main one first: the United States K, with
    /// Alaska's four and Hawaii's PH; China ten blocks of Z, North Korea's ZK and Mongolia's ZM
    /// being theirs; Russia ten blocks of U, and Belarus's UM for Kaliningrad; Spain LE, with GC
    /// for the Canaries and GE for Ceuta and Melilla; Malaysia WM, and WB for Borneo, which it
    /// shares with Brunei. South Sudan has had HJ since 2021, though many of its airfields still
    /// carry Sudan's HS, and Western Sahara's carry Morocco's GM as well as their own GS.
    private static let severalAirportPrefixes: [String: [String]] = [
        "US": ["K", "PA", "PF", "PH", "PO", "PP"],
        "CN": ["ZB", "ZG", "ZH", "ZJ", "ZL", "ZP", "ZS", "ZU", "ZW", "ZY"],
        "RU": ["UE", "UH", "UI", "UL", "UM", "UN", "UO", "UR", "US", "UU", "UW"],
        "BR": ["SB", "SD", "SI", "SJ", "SN", "SS", "SW"], "IN": ["VA", "VE", "VI", "VO"],
        "ID": ["WA", "WI", "WQ", "WR"], "JP": ["RJ", "RO"], "DE": ["ED", "ET"], "ES": ["LE", "GC", "GE"],
        "MY": ["WM", "WB"], "KI": ["NG", "PC", "PL"], "UM": ["PM", "PW"], "SS": ["HJ", "HS"],
        "EH": ["GS", "GM"],
    ]

    /// By ISO code, read from prefixes each followed by the places whose airports take it, as
    /// calling codes are. A prefix several places share counts for any of them, as +1 does: Fiji
    /// and Tonga share NF, and Australia's islands its Y. Liechtenstein's and Monaco's are their
    /// heliports', and Palestine's LV its airport's at Gaza, closed since 2001. Left out: places
    /// with no airport known here, such as Andorra, the Vatican, Pitcairn and Tokelau, and
    /// Antarctica, whose bases take their own countries' prefixes.
    private static let airportPrefixes: [String: String] = {
        let table: [String: String] = [
            "C": "CA", "Y": "AU CX CC NF", "AG": "SB", "AN": "NR", "AY": "PG", "BG": "GL", "BI": "IS", "BK": "XK",
            "DA": "DZ", "DB": "BJ", "DF": "BF", "DG": "GH", "DI": "CI", "DN": "NG", "DR": "NE", "DT": "TN", "DX": "TG",
            "EB": "BE", "EE": "EE", "EF": "FI AX", "EG": "GB GG JE IM", "EH": "NL", "EI": "IE", "EK": "DK FO",
            "EL": "LU", "EN": "NO SJ", "EP": "PL", "ES": "SE", "EV": "LV", "EY": "LT",
            "FA": "ZA", "FB": "BW", "FC": "CG", "FD": "SZ", "FE": "CF", "FG": "GQ", "FH": "SH", "FI": "MU",
            "FJ": "IO", "FK": "CM", "FL": "ZM", "FM": "KM MG RE YT", "FN": "AO", "FO": "GA", "FP": "ST", "FQ": "MZ",
            "FS": "SC", "FT": "TD", "FV": "ZW", "FW": "MW", "FX": "LS", "FY": "NA", "FZ": "CD",
            "GA": "ML", "GB": "GM", "GF": "SL", "GG": "GW", "GL": "LR", "GM": "MA", "GO": "SN", "GQ": "MR",
            "GU": "GN", "GV": "CV", "HA": "ET", "HB": "BI", "HC": "SO", "HD": "DJ", "HE": "EG", "HH": "ER",
            "HK": "KE", "HL": "LY", "HR": "RW", "HS": "SD", "HT": "TZ", "HU": "UG",
            "LA": "AL", "LB": "BG", "LC": "CY XC", "LD": "HR", "LF": "FR PM", "LG": "GR", "LH": "HU", "LI": "IT SM",
            "LJ": "SI", "LK": "CZ", "LL": "IL", "LM": "MT", "LN": "MC", "LO": "AT", "LP": "PT", "LQ": "BA",
            "LR": "RO", "LS": "CH LI", "LT": "TR", "LU": "MD", "LV": "PS", "LW": "MK", "LX": "GI", "LY": "RS ME",
            "LZ": "SK", "MB": "TC", "MD": "DO", "MG": "GT", "MH": "HN", "MK": "JM", "MM": "MX", "MN": "NI",
            "MP": "PA", "MR": "CR", "MS": "SV", "MT": "HT", "MU": "CU", "MW": "KY", "MY": "BS", "MZ": "BZ",
            "NC": "CK", "NF": "FJ TO", "NG": "TV", "NI": "NU", "NL": "WF", "NS": "WS AS", "NT": "PF", "NV": "VU",
            "NW": "NC", "NZ": "NZ", "OA": "AF", "OB": "BH", "OE": "SA", "OI": "IR", "OJ": "JO", "OK": "KW",
            "OL": "LB", "OM": "AE", "OO": "OM", "OP": "PK", "OR": "IQ", "OS": "SY", "OT": "QA", "OY": "YE",
            "PG": "GU MP", "PK": "MH", "PT": "FM PW", "RC": "TW", "RK": "KR", "RP": "PH",
            "SA": "AR", "SC": "CL", "SE": "EC", "SF": "FK", "SG": "PY", "SK": "CO", "SL": "BO", "SM": "SR",
            "SO": "GF", "SP": "PE", "SU": "UY", "SV": "VE", "SY": "GY", "TA": "AG", "TB": "BB", "TD": "DM",
            "TF": "GP MQ BL MF", "TG": "GD", "TI": "VI", "TJ": "PR", "TK": "KN", "TL": "LC", "TN": "AW CW SX BQ",
            "TQ": "AI", "TR": "MS", "TT": "TT", "TU": "VG", "TV": "VC", "TX": "BM",
            "UA": "KZ", "UB": "AZ", "UC": "KG", "UD": "AM", "UG": "GE", "UK": "UA", "UM": "BY", "UT": "TJ TM",
            "UZ": "UZ", "VC": "LK", "VD": "KH", "VG": "BD", "VH": "HK", "VL": "LA", "VM": "MO", "VN": "NP",
            "VQ": "BT", "VR": "MV", "VT": "TH", "VV": "VN", "VY": "MM", "WB": "BN", "WP": "TL", "WS": "SG",
            "ZK": "KP", "ZM": "MN",
        ]
        var prefixes: [String: String] = [:]
        for (prefix, places) in table {
            for place in places.split(separator: " ") { prefixes[String(place)] = prefix }
        }
        return prefixes
    }()

    /// The ISO 4217 code of a place's main money, by ISO code, such as "JPY" for Japan; nil where
    /// it isn't certain here.
    static func currency(ofCode code: String) -> String? {
        currencies[code]
    }

    /// By ISO code, read from currencies each followed by the places using it, as calling codes
    /// are: the euro across the eurozone and the places that use it besides, the CFA francs of west
    /// and central Africa, the East Caribbean dollar, and the dollars of the US, Australia and New
    /// Zealand with the islands and countries that use them. Where a place has two, its own is
    /// taken: Panama's balboa over the US dollar notes it circulates with, Bhutan's ngultrum over
    /// the Indian rupee. Left out: Palestine, Antarctica and South Georgia, given none of their own
    /// by ISO 4217; Venezuela, its bolívar coded both VES and VED; and Zimbabwe, where the ZiG and
    /// the US dollar share the work.
    private static let currencies: [String: String] = {
        let table: [String: String] = [
            "EUR": "AT BE BG HR CY EE FI FR DE GR IE IT LV LT LU MT NL PT SK SI ES AD MC SM VA ME XK AX GF GP MQ RE YT PM BL MF TF",
            "USD": "US EC SV TL FM MH PW VG TC BQ PR VI GU AS MP UM IO", "XOF": "BJ BF CI GW ML NE SN TG",
            "XAF": "CM CF TD CG GQ GA", "XCD": "AG DM GD KN LC VC AI MS", "XPF": "PF NC WF", "XCG": "CW SX",
            "AUD": "AU KI NR TV CX CC NF HM", "NZD": "NZ CK NU PN TK", "GBP": "GB GG JE IM", "CHF": "CH LI",
            "DKK": "DK FO GL", "NOK": "NO SJ BV", "MAD": "MA EH", "TRY": "TR XC",
            "AED": "AE", "AFN": "AF", "ALL": "AL", "AMD": "AM", "AOA": "AO", "ARS": "AR", "AWG": "AW", "AZN": "AZ",
            "BAM": "BA", "BBD": "BB", "BDT": "BD", "BHD": "BH", "BIF": "BI", "BMD": "BM", "BND": "BN", "BOB": "BO",
            "BRL": "BR", "BSD": "BS", "BTN": "BT", "BWP": "BW", "BYN": "BY", "BZD": "BZ", "CAD": "CA", "CDF": "CD",
            "CLP": "CL", "CNY": "CN", "COP": "CO", "CRC": "CR", "CUP": "CU", "CVE": "CV", "CZK": "CZ", "DJF": "DJ",
            "DOP": "DO", "DZD": "DZ", "EGP": "EG", "ERN": "ER", "ETB": "ET", "FJD": "FJ", "FKP": "FK", "GEL": "GE",
            "GHS": "GH", "GIP": "GI", "GMD": "GM", "GNF": "GN", "GTQ": "GT", "GYD": "GY", "HKD": "HK", "HNL": "HN",
            "HTG": "HT", "HUF": "HU", "IDR": "ID", "ILS": "IL", "INR": "IN", "IQD": "IQ", "IRR": "IR", "ISK": "IS",
            "JMD": "JM", "JOD": "JO", "JPY": "JP", "KES": "KE", "KGS": "KG", "KHR": "KH", "KMF": "KM", "KPW": "KP",
            "KRW": "KR", "KWD": "KW", "KYD": "KY", "KZT": "KZ", "LAK": "LA", "LBP": "LB", "LKR": "LK", "LRD": "LR",
            "LSL": "LS", "LYD": "LY", "MDL": "MD", "MGA": "MG", "MKD": "MK", "MMK": "MM", "MNT": "MN", "MOP": "MO",
            "MRU": "MR", "MUR": "MU", "MVR": "MV", "MWK": "MW", "MXN": "MX", "MYR": "MY", "MZN": "MZ", "NAD": "NA",
            "NGN": "NG", "NIO": "NI", "NPR": "NP", "OMR": "OM", "PAB": "PA", "PEN": "PE", "PGK": "PG", "PHP": "PH",
            "PKR": "PK", "PLN": "PL", "PYG": "PY", "QAR": "QA", "RON": "RO", "RSD": "RS", "RUB": "RU", "RWF": "RW",
            "SAR": "SA", "SBD": "SB", "SCR": "SC", "SDG": "SD", "SEK": "SE", "SGD": "SG", "SHP": "SH", "SLE": "SL",
            "SOS": "SO", "SRD": "SR", "SSP": "SS", "STN": "ST", "SYP": "SY", "SZL": "SZ", "THB": "TH", "TJS": "TJ",
            "TMT": "TM", "TND": "TN", "TOP": "TO", "TTD": "TT", "TWD": "TW", "TZS": "TZ", "UAH": "UA", "UGX": "UG",
            "UYU": "UY", "UZS": "UZ", "VND": "VN", "VUV": "VU", "WST": "WS", "YER": "YE", "ZAR": "ZA", "ZMW": "ZM",
        ]
        var currencies: [String: String] = [:]
        for (currency, places) in table {
            for place in places.split(separator: " ") { currencies[String(place)] = currency }
        }
        return currencies
    }()

    /// The codes national Olympic committees compete under today, by ISO code: Germany's GER, the
    /// Netherlands' NED, Taiwan's TPE for Chinese Taipei.
    private static let olympicCodes = pairs("""
        AFG AF,ALB AL,ALG DZ,AND AD,ANG AO,ANT AG,ARG AR,ARM AM,ARU AW,ASA AS,AUS AU,AUT AT,AZE AZ,\
        BAH BS,BAN BD,BAR BB,BDI BI,BEL BE,BEN BJ,BER BM,BHU BT,BIH BA,BIZ BZ,BLR BY,BOL BO,BOT BW,\
        BRA BR,BRN BH,BRU BN,BUL BG,BUR BF,CAF CF,CAM KH,CAN CA,CAY KY,CGO CG,CHA TD,CHI CL,CHN CN,\
        CIV CI,CMR CM,COD CD,COK CK,COL CO,COM KM,CPV CV,CRC CR,CRO HR,CUB CU,CYP CY,CZE CZ,DEN DK,\
        DJI DJ,DMA DM,DOM DO,ECU EC,EGY EG,ERI ER,ESA SV,ESP ES,EST EE,ETH ET,FIJ FJ,FIN FI,FRA FR,\
        FSM FM,GAB GA,GAM GM,GBR GB,GBS GW,GEO GE,GEQ GQ,GER DE,GHA GH,GRE GR,GRN GD,GUA GT,GUI GN,\
        GUM GU,GUY GY,HAI HT,HKG HK,HON HN,HUN HU,INA ID,IND IN,IRI IR,IRL IE,IRQ IQ,ISL IS,ISR IL,\
        ISV VI,ITA IT,IVB VG,JAM JM,JOR JO,JPN JP,KAZ KZ,KEN KE,KGZ KG,KIR KI,KOR KR,KOS XK,KSA SA,\
        KUW KW,LAO LA,LAT LV,LBA LY,LBN LB,LBR LR,LCA LC,LES LS,LIE LI,LTU LT,LUX LU,MAD MG,MAR MA,\
        MAS MY,MAW MW,MDA MD,MDV MV,MEX MX,MGL MN,MHL MH,MKD MK,MLI ML,MLT MT,MNE ME,MON MC,MOZ MZ,\
        MRI MU,MTN MR,MYA MM,NAM NA,NCA NI,NED NL,NEP NP,NGR NG,NIG NE,NOR NO,NRU NR,NZL NZ,OMA OM,\
        PAK PK,PAN PA,PAR PY,PER PE,PHI PH,PLE PS,PLW PW,PNG PG,POL PL,POR PT,PRK KP,PUR PR,QAT QA,\
        ROU RO,RSA ZA,RUS RU,RWA RW,SAM WS,SEN SN,SEY SC,SGP SG,SKN KN,SLE SL,SLO SI,SMR SM,SOL SB,\
        SOM SO,SRB RS,SRI LK,SSD SS,STP ST,SUD SD,SUI CH,SUR SR,SVK SK,SWE SE,SWZ SZ,SYR SY,TAN TZ,\
        TGA TO,THA TH,TJK TJ,TKM TM,TLS TL,TOG TG,TPE TW,TTO TT,TUN TN,TUR TR,TUV TV,UAE AE,UGA UG,\
        UKR UA,URU UY,USA US,UZB UZ,VAN VU,VEN VE,VIE VN,VIN VC,YEM YE,ZAM ZM,ZIM ZW
        """)

    /// The codes FIFA's 211 member associations play under, by ISO code, as FIFA itself lists them;
    /// England, Scotland, Wales and Northern Ireland are kept apart above. Most match the Olympic
    /// codes, but not all: Indonesia is IDN, not INA, Iran IRN, Mongolia MNG, Latvia LVA, Slovenia
    /// SVN, Nigeria NGA, Trinidad and Tobago TRI. Taiwan plays as Chinese Taipei, TPE, and French
    /// Polynesia as Tahiti, TAH. Members FIFA counts that the Olympics don't include the Faroe
    /// Islands, Gibraltar, New Caledonia, Curaçao, Macau and several Caribbean islands.
    private static let fifaCodes = pairs("""
        AFG AF,AIA AI,ALB AL,ALG DZ,AND AD,ANG AO,ARG AR,ARM AM,ARU AW,ASA AS,ATG AG,AUS AU,AUT AT,\
        AZE AZ,BAH BS,BAN BD,BDI BI,BEL BE,BEN BJ,BER BM,BFA BF,BHR BH,BHU BT,BIH BA,BLR BY,BLZ BZ,\
        BOL BO,BOT BW,BRA BR,BRB BB,BRU BN,BUL BG,CAM KH,CAN CA,CAY KY,CGO CG,CHA TD,CHI CL,CHN CN,\
        CIV CI,CMR CM,COD CD,COK CK,COL CO,COM KM,CPV CV,CRC CR,CRO HR,CTA CF,CUB CU,CUW CW,CYP CY,\
        CZE CZ,DEN DK,DJI DJ,DMA DM,DOM DO,ECU EC,EGY EG,EQG GQ,ERI ER,ESP ES,EST EE,ETH ET,FIJ FJ,\
        FIN FI,FRA FR,FRO FO,GAB GA,GAM GM,GEO GE,GER DE,GHA GH,GIB GI,GNB GW,GRE GR,GRN GD,GUA GT,\
        GUI GN,GUM GU,GUY GY,HAI HT,HKG HK,HON HN,HUN HU,IDN ID,IND IN,IRL IE,IRN IR,IRQ IQ,ISL IS,\
        ISR IL,ITA IT,JAM JM,JOR JO,JPN JP,KAZ KZ,KEN KE,KGZ KG,KOR KR,KOS XK,KSA SA,KUW KW,LAO LA,\
        LBN LB,LBR LR,LBY LY,LCA LC,LES LS,LIE LI,LTU LT,LUX LU,LVA LV,MAC MO,MAD MG,MAR MA,MAS MY,\
        MDA MD,MDV MV,MEX MX,MKD MK,MLI ML,MLT MT,MNE ME,MNG MN,MOZ MZ,MRI MU,MSR MS,MTN MR,MWI MW,\
        MYA MM,NAM NA,NCA NI,NCL NC,NED NL,NEP NP,NGA NG,NIG NE,NOR NO,NZL NZ,OMA OM,PAK PK,PAN PA,\
        PAR PY,PER PE,PHI PH,PLE PS,PNG PG,POL PL,POR PT,PRK KP,PUR PR,QAT QA,ROU RO,RSA ZA,RUS RU,\
        RWA RW,SAM WS,SDN SD,SEN SN,SEY SC,SGP SG,SKN KN,SLE SL,SLV SV,SMR SM,SOL SB,SOM SO,SRB RS,\
        SRI LK,SSD SS,STP ST,SUI CH,SUR SR,SVK SK,SVN SI,SWE SE,SWZ SZ,SYR SY,TAH PF,TAN TZ,TCA TC,\
        TGA TO,THA TH,TJK TJ,TKM TM,TLS TL,TOG TG,TPE TW,TRI TT,TUN TN,TUR TR,UAE AE,UGA UG,UKR UA,\
        URU UY,USA US,UZB UZ,VAN VU,VEN VE,VGB VG,VIE VN,VIN VC,VIR VI,YEM YE,ZAM ZM,ZIM ZW
        """)

    /// By each Chinese province's, region's and municipality's abbreviation in the app, its short
    /// name as the State Council lists it, and as its number plates begin. Where it lists two, the
    /// first, which the plates carry: Sichuan's 川 rather than 蜀, Guizhou's 贵 rather than 黔,
    /// Yunnan's 云 rather than 滇, Shaanxi's 陕 rather than 秦 and Gansu's 甘 rather than 陇. Inner
    /// Mongolia's is listed as 内蒙古 in full; 蒙, on its plates and in pairings such as 京蒙, is the
    /// one character it goes by. Hong Kong and Macao go by 港 and 澳.
    private static let chineseShortNames: [String: String] = [
        "BJ": "京", "TJ": "津", "HE": "冀", "SX": "晋", "NM": "蒙", "LN": "辽", "JL": "吉", "HL": "黑",
        "SH": "沪", "JS": "苏", "ZJ": "浙", "AH": "皖", "FJ": "闽", "JX": "赣", "SD": "鲁", "HA": "豫",
        "HB": "鄂", "HN": "湘", "GD": "粤", "GX": "桂", "HI": "琼", "CQ": "渝", "SC": "川", "GZ": "贵",
        "YN": "云", "XZ": "藏", "SN": "陕", "GS": "甘", "QH": "青", "NX": "宁", "XJ": "新",
        "HK": "港", "MO": "澳",
    ]

    /// Domains that differ from the ISO code.
    private static let domainExceptions = ["GB": "uk"]

    /// Codes with no internet domain of their own in use: Bonaire's, Saint Barthélemy's, Saint
    /// Martin's and Svalbard's are reserved but unused, Western Sahara's was never assigned, and
    /// Kosovo's and Northern Cyprus's codes aren't ISO's.
    private static let domainless: Set<String> = ["BQ", "BL", "MF", "SJ", "EH", "XK", "XC"]

    /// By ISO code, read from calling codes each followed by the places that share it. Places
    /// within the North American plan dial +1 with an area code of their own; Northern Cyprus
    /// dials Türkiye's +90; the Vatican is reached through Italy's +39.
    private static let callingCodes: [String: String] = {
        let table = [
            "1": "US CA AS AI AG BS BB BM VG KY DM DO GD GU JM MS MP PR KN LC VC SX TT TC VI",
            "7": "RU KZ", "20": "EG", "27": "ZA", "30": "GR", "31": "NL", "32": "BE", "33": "FR", "34": "ES",
            "36": "HU", "39": "IT VA", "40": "RO", "41": "CH", "43": "AT", "44": "GB GG JE IM", "45": "DK",
            "46": "SE", "47": "NO SJ", "48": "PL", "49": "DE", "51": "PE", "52": "MX", "53": "CU", "54": "AR",
            "55": "BR", "56": "CL", "57": "CO", "58": "VE", "60": "MY", "61": "AU CX CC", "62": "ID", "63": "PH",
            "64": "NZ PN", "65": "SG", "66": "TH", "81": "JP", "82": "KR", "84": "VN", "86": "CN", "90": "TR XC",
            "91": "IN", "92": "PK", "93": "AF", "94": "LK", "95": "MM", "98": "IR",
            "211": "SS", "212": "MA EH", "213": "DZ", "216": "TN", "218": "LY", "220": "GM", "221": "SN",
            "222": "MR", "223": "ML", "224": "GN", "225": "CI", "226": "BF", "227": "NE", "228": "TG", "229": "BJ",
            "230": "MU", "231": "LR", "232": "SL", "233": "GH", "234": "NG", "235": "TD", "236": "CF", "237": "CM",
            "238": "CV", "239": "ST", "240": "GQ", "241": "GA", "242": "CG", "243": "CD", "244": "AO", "245": "GW",
            "248": "SC", "249": "SD", "250": "RW", "251": "ET", "252": "SO", "253": "DJ", "254": "KE", "255": "TZ",
            "256": "UG", "257": "BI", "258": "MZ", "260": "ZM", "261": "MG", "262": "RE YT", "263": "ZW",
            "264": "NA", "265": "MW", "266": "LS", "267": "BW", "268": "SZ", "269": "KM", "290": "SH", "291": "ER",
            "297": "AW", "298": "FO", "299": "GL", "350": "GI", "351": "PT", "352": "LU", "353": "IE", "354": "IS",
            "355": "AL", "356": "MT", "357": "CY", "358": "FI AX", "359": "BG", "370": "LT", "371": "LV", "372": "EE",
            "373": "MD", "374": "AM", "375": "BY", "376": "AD", "377": "MC", "378": "SM", "380": "UA", "381": "RS",
            "382": "ME", "383": "XK", "385": "HR", "386": "SI", "387": "BA", "389": "MK", "420": "CZ", "421": "SK",
            "423": "LI", "500": "FK", "501": "BZ", "502": "GT", "503": "SV", "504": "HN", "505": "NI", "506": "CR",
            "507": "PA", "508": "PM", "509": "HT", "590": "GP BL MF", "591": "BO", "592": "GY", "593": "EC",
            "594": "GF", "595": "PY", "596": "MQ", "597": "SR", "598": "UY", "599": "CW BQ", "670": "TL",
            "672": "NF", "673": "BN", "674": "NR", "675": "PG", "676": "TO", "677": "SB", "678": "VU", "679": "FJ",
            "680": "PW", "681": "WF", "682": "CK", "683": "NU", "685": "WS", "686": "KI", "687": "NC", "688": "TV",
            "689": "PF", "690": "TK", "691": "FM", "692": "MH", "850": "KP", "852": "HK", "853": "MO", "855": "KH",
            "856": "LA", "880": "BD", "886": "TW", "960": "MV", "961": "LB", "962": "JO", "963": "SY", "964": "IQ",
            "965": "KW", "966": "SA", "967": "YE", "968": "OM", "970": "PS", "971": "AE", "972": "IL", "973": "BH",
            "974": "QA", "975": "BT", "976": "MN", "977": "NP", "992": "TJ", "993": "TM", "994": "AZ", "995": "GE",
            "996": "KG", "998": "UZ",
        ]
        var codes: [String: String] = [:]
        for (callingCode, places) in table {
            for place in places.split(separator: " ") { codes[String(place)] = callingCode }
        }
        return codes
    }()
}
