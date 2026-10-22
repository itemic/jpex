import Foundation

/// The seas each place on the World map has coasts on, longest coast first, worked out from where
/// its land runs along each sea's waters; see SEA_SOURCES.md.
enum SeaCoasts {
    /// The seas a country's list has coasts on: the country's own, then any more that its places
    /// drawn on the World map of their own have, such as the Caribbean for France's Guadeloupe.
    /// Nil for lists that aren't a country's own, such as the World, Seas, a group of countries
    /// or Tasmania's local government areas.
    static func seaIDs(of list: Country) -> [String]? {
        guard list.parentPlace == nil, !list.isGroupOfCountries,
              let country = CountryCatalog.world.divisions.first(where: { $0.abbreviation == list.countryListID }),
              var seas = coasts[country.id]
        else { return nil }
        for place in list.divisions {
            for sea in coasts[place.id] ?? [] where !seas.contains(sea) {
                seas.append(sea)
            }
        }
        return seas
    }

    /// Whether a country with coasts on these seas is landlocked: they're all inland seas, such as
    /// the Caspian, or there are none.
    static func isLandlocked(_ seaIDs: [String]) -> Bool {
        seaIDs.allSatisfy(inlandSeaIDs.contains)
    }

    private static let inlandSeaIDs: Set<String> = ["SEAS-caspian-sea", "SEAS-dead-sea"]

    // MARK: The Atlas

    /// What the Atlas colours a region by: for one of the World's places, the oceans it has coasts
    /// on, that of its longest coast first, or landlocked, with any inland sea it lies on after; for
    /// a sea, its own ocean. Empty for anything else.
    static func oceanKeyIDs(ofRegion id: String) -> [String] {
        if let group = seaGroupIDs[id] { return CoastKey(seaGroupID: group).map { [$0.rawValue] } ?? [] }
        guard let seas = coasts[id] else { return [] }
        var keys = isLandlocked(seas) ? [CoastKey.landlocked.rawValue] : []
        for sea in seas {
            guard let key = seaGroupIDs[sea].flatMap(CoastKey.init(seaGroupID:)), !keys.contains(key.rawValue) else { continue }
            keys.append(key.rawValue)
        }
        return keys
    }

    /// What Learn's and the Atlas's cards say about one of the World's places' coasts, by its ISO
    /// 3166 code: the oceans, as the Atlas's key has them, such as "Atlantic, Mediterranean", short
    /// enough for one line, with every sea by name for VoiceOver. The Black Sea goes by its own
    /// name where it's all of the Mediterranean's a place has, and the inland seas by theirs.
    /// A place with no coast is landlocked.
    static func summary(ofPlace code: String) -> (value: String, spoken: String)? {
        guard let place = CountryCatalog.world.divisions.first(where: { $0.abbreviation == code }),
              let seas = coasts[place.id]
        else { return nil }
        let named = CountryCatalog.seas(applying: CountingRules(defaults: .standard)).divisions
        let names = seas.compactMap { id in named.first { $0.id == id }?.name }
        var tags = isLandlocked(seas) ? [CoastKey.landlocked.name] : []
        for sea in seas {
            let tag: String
            if inlandSeaIDs.contains(sea) || blackSeaIDs.contains(sea) {
                tag = named.first { $0.id == sea }?.name ?? sea
                if sea == "SEAS-sea-of-azov", tags.contains("Black Sea") { continue }
            } else if let key = seaGroupIDs[sea].flatMap(CoastKey.init(seaGroupID:)) {
                tag = key.shortName
            } else {
                continue
            }
            if !tags.contains(tag) { tags.append(tag) }
        }
        let spoken = names.isEmpty ? "Landlocked" : "Coasts on the \(names.formatted(.list(type: .and)))"
        return (tags.joined(separator: ", "), spoken)
    }

    /// The Black Sea and the Sea of Azov, which go by the Black Sea's name rather than the
    /// Mediterranean's where they're all of it a place has.
    private static let blackSeaIDs: Set<String> = ["SEAS-black-sea", "SEAS-sea-of-azov"]

    /// Each sea's ocean, as the Seas list groups them, by the sea's ID.
    private static let seaGroupIDs: [String: String] = Dictionary(
        CountryCatalog.seas.divisions.map { ($0.id, $0.groupID) }) { first, _ in first }

    /// Each place's seas by the place's ID on the World map, written as the seas' IDs without
    /// their "SEAS-", longest coast first. An empty line is a place with no coast.
    private static let coasts: [String: [String]] = table.mapValues { line in
        line.split(separator: " ").map { "SEAS-\($0)" }
    }

    private static let table: [String: String] = [
        "AU-CC": "indian-ocean",
        "AU-CX": "indian-ocean",
        "AU-HM": "indian-ocean",
        "AU-NF": "south-pacific-ocean",
        "CN-HK": "south-china-sea",
        "CN-MO": "south-china-sea",
        "FI-01": "gulf-of-bothnia",
        "FR-971": "caribbean-sea",
        "FR-972": "caribbean-sea",
        "FR-973": "north-atlantic-ocean",
        "FR-974": "indian-ocean",
        "FR-976": "mozambique-channel",
        "GB-ENG": "north-sea english-channel irish-sea bristol-channel celtic-sea",
        "GB-NIR": "inner-seas-off-the-west-coast-of-scotland irish-sea",
        "GB-SCT": "inner-seas-off-the-west-coast-of-scotland north-sea north-atlantic-ocean irish-sea",
        "GB-WLS": "irish-sea bristol-channel celtic-sea",
        "US-AS": "south-pacific-ocean",
        "US-GU": "north-pacific-ocean philippine-sea",
        "US-MP": "philippine-sea north-pacific-ocean",
        "US-PR": "caribbean-sea north-atlantic-ocean",
        "US-VI": "caribbean-sea",
        "WORLD-AD": "",
        "WORLD-AE": "persian-gulf gulf-of-oman",
        "WORLD-AF": "",
        "WORLD-AG": "caribbean-sea north-atlantic-ocean",
        "WORLD-AI": "caribbean-sea",
        "WORLD-AL": "adriatic-sea ionian-sea",
        "WORLD-AM": "",
        "WORLD-AO": "south-atlantic-ocean",
        "WORLD-AQ": "southern-ocean",
        "WORLD-AR": "south-atlantic-ocean rio-de-la-plata south-pacific-ocean",
        "WORLD-AT": "",
        "WORLD-AU": "indian-ocean great-australian-bight coral-sea arafura-sea timor-sea bass-strait tasman-sea south-pacific-ocean",
        "WORLD-AW": "caribbean-sea",
        "WORLD-AZ": "caspian-sea",
        "WORLD-BA": "adriatic-sea",
        "WORLD-BB": "caribbean-sea north-atlantic-ocean",
        "WORLD-BD": "bay-of-bengal",
        "WORLD-BE": "north-sea",
        "WORLD-BF": "",
        "WORLD-BG": "black-sea",
        "WORLD-BH": "persian-gulf",
        "WORLD-BI": "",
        "WORLD-BJ": "gulf-of-guinea",
        "WORLD-BL": "caribbean-sea",
        "WORLD-BM": "north-atlantic-ocean",
        "WORLD-BN": "south-china-sea",
        "WORLD-BO": "",
        "WORLD-BQ": "caribbean-sea",
        "WORLD-BR": "south-atlantic-ocean north-atlantic-ocean",
        "WORLD-BS": "north-atlantic-ocean",
        "WORLD-BT": "",
        "WORLD-BV": "south-atlantic-ocean",
        "WORLD-BW": "",
        "WORLD-BY": "",
        "WORLD-BZ": "caribbean-sea",
        "WORLD-CA": "northwestern-passages hudson-bay gulf-of-st-lawrence coastal-waters-of-southeast-alaska-and-british-columbia labrador-sea davis-strait hudson-strait baffin-bay beaufort-sea north-atlantic-ocean arctic-ocean north-pacific-ocean bay-of-fundy lincoln-sea",
        "WORLD-CD": "south-atlantic-ocean",
        "WORLD-CF": "",
        "WORLD-CG": "south-atlantic-ocean",
        "WORLD-CH": "",
        "WORLD-CI": "gulf-of-guinea",
        "WORLD-CK": "south-pacific-ocean",
        "WORLD-CL": "south-pacific-ocean south-atlantic-ocean",
        "WORLD-CM": "gulf-of-guinea",
        "WORLD-CN": "south-china-sea yellow-sea east-china-sea",
        "WORLD-CO": "caribbean-sea north-pacific-ocean",
        "WORLD-CR": "north-pacific-ocean caribbean-sea",
        "WORLD-CU": "caribbean-sea north-atlantic-ocean gulf-of-mexico",
        "WORLD-CV": "north-atlantic-ocean",
        "WORLD-CW": "caribbean-sea",
        "WORLD-CY": "mediterranean-eastern-basin",
        "WORLD-CZ": "",
        "WORLD-DE": "baltic-sea north-sea kattegat",
        "WORLD-DJ": "gulf-of-aden red-sea",
        "WORLD-DK": "kattegat north-sea baltic-sea skagerrak",
        "WORLD-DM": "caribbean-sea",
        "WORLD-DO": "north-atlantic-ocean caribbean-sea",
        "WORLD-DZ": "mediterranean-western-basin alboran-sea",
        "WORLD-EC": "south-pacific-ocean north-pacific-ocean",
        "WORLD-EE": "gulf-of-riga gulf-of-finland baltic-sea",
        "WORLD-EG": "mediterranean-eastern-basin red-sea gulf-of-suez gulf-of-aqaba",
        "WORLD-EH": "north-atlantic-ocean",
        "WORLD-ER": "red-sea",
        "WORLD-ES": "north-atlantic-ocean balearic-sea bay-of-biscay mediterranean-western-basin alboran-sea strait-of-gibraltar",
        "WORLD-ET": "",
        "WORLD-FI": "gulf-of-bothnia gulf-of-finland",
        "WORLD-FJ": "south-pacific-ocean",
        "WORLD-FK": "south-atlantic-ocean",
        "WORLD-FM": "north-pacific-ocean",
        "WORLD-FO": "north-atlantic-ocean",
        "WORLD-FR": "english-channel mediterranean-western-basin bay-of-biscay tyrrhenian-sea celtic-sea north-sea",
        "WORLD-GA": "south-atlantic-ocean gulf-of-guinea",
        "WORLD-GB": "inner-seas-off-the-west-coast-of-scotland north-sea irish-sea english-channel bristol-channel north-atlantic-ocean celtic-sea",
        "WORLD-GD": "caribbean-sea",
        "WORLD-GE": "black-sea",
        "WORLD-GG": "english-channel",
        "WORLD-GH": "gulf-of-guinea",
        "WORLD-GI": "alboran-sea strait-of-gibraltar",
        "WORLD-GL": "greenland-sea baffin-bay davis-strait north-atlantic-ocean lincoln-sea arctic-ocean labrador-sea",
        "WORLD-GM": "north-atlantic-ocean",
        "WORLD-GN": "north-atlantic-ocean",
        "WORLD-GQ": "gulf-of-guinea",
        "WORLD-GR": "aegean-sea ionian-sea mediterranean-eastern-basin adriatic-sea",
        "WORLD-GS": "south-atlantic-ocean",
        "WORLD-GT": "north-pacific-ocean caribbean-sea",
        "WORLD-GW": "north-atlantic-ocean",
        "WORLD-GY": "north-atlantic-ocean",
        "WORLD-HN": "caribbean-sea north-pacific-ocean",
        "WORLD-HR": "adriatic-sea",
        "WORLD-HT": "caribbean-sea north-atlantic-ocean",
        "WORLD-HU": "",
        "WORLD-ID": "indian-ocean banda-sea java-sea south-china-sea arafura-sea south-pacific-ocean makassar-strait seram-sea savu-sea molucca-sea strait-of-malacca celebes-sea flores-sea halmahera-sea gulf-of-tomini bali-sea gulf-of-bone timor-sea philippine-sea andaman-sea singapore-strait",
        "WORLD-IE": "north-atlantic-ocean celtic-sea irish-sea inner-seas-off-the-west-coast-of-scotland",
        "WORLD-IL": "mediterranean-eastern-basin dead-sea gulf-of-aqaba",
        "WORLD-IM": "irish-sea",
        "WORLD-IN": "bay-of-bengal arabian-sea laccadive-sea andaman-sea",
        "WORLD-IO": "indian-ocean",
        "WORLD-IQ": "persian-gulf",
        "WORLD-IR": "persian-gulf caspian-sea gulf-of-oman",
        "WORLD-IS": "north-atlantic-ocean greenland-sea",
        "WORLD-IT": "tyrrhenian-sea adriatic-sea ionian-sea mediterranean-western-basin mediterranean-eastern-basin ligurian-sea",
        "WORLD-JE": "english-channel",
        "WORLD-JM": "caribbean-sea",
        "WORLD-JO": "dead-sea gulf-of-aqaba",
        "WORLD-JP": "japan-sea philippine-sea north-pacific-ocean east-china-sea seto-inland-sea sea-of-okhotsk",
        "WORLD-KE": "indian-ocean",
        "WORLD-KG": "",
        "WORLD-KH": "gulf-of-thailand",
        "WORLD-KI": "north-pacific-ocean",
        "WORLD-KM": "mozambique-channel",
        "WORLD-KN": "caribbean-sea",
        "WORLD-KP": "japan-sea yellow-sea",
        "WORLD-KR": "japan-sea yellow-sea east-china-sea",
        "WORLD-KW": "persian-gulf",
        "WORLD-KY": "caribbean-sea",
        "WORLD-KZ": "caspian-sea",
        "WORLD-LA": "",
        "WORLD-LB": "mediterranean-eastern-basin",
        "WORLD-LC": "caribbean-sea",
        "WORLD-LI": "",
        "WORLD-LK": "bay-of-bengal laccadive-sea",
        "WORLD-LR": "north-atlantic-ocean gulf-of-guinea",
        "WORLD-LS": "",
        "WORLD-LT": "baltic-sea",
        "WORLD-LU": "",
        "WORLD-LV": "gulf-of-riga baltic-sea",
        "WORLD-LY": "mediterranean-eastern-basin",
        "WORLD-MA": "north-atlantic-ocean alboran-sea strait-of-gibraltar",
        "WORLD-MC": "mediterranean-western-basin",
        "WORLD-MD": "",
        "WORLD-ME": "adriatic-sea",
        "WORLD-MF": "caribbean-sea",
        "WORLD-MG": "mozambique-channel indian-ocean",
        "WORLD-MH": "north-pacific-ocean",
        "WORLD-MK": "",
        "WORLD-ML": "",
        "WORLD-MM": "andaman-sea bay-of-bengal",
        "WORLD-MN": "",
        "WORLD-MR": "north-atlantic-ocean",
        "WORLD-MS": "caribbean-sea",
        "WORLD-MT": "mediterranean-eastern-basin",
        "WORLD-MU": "indian-ocean",
        "WORLD-MV": "laccadive-sea",
        "WORLD-MW": "",
        "WORLD-MX": "north-pacific-ocean gulf-of-california gulf-of-mexico caribbean-sea",
        "WORLD-MY": "south-china-sea strait-of-malacca sulu-sea celebes-sea singapore-strait gulf-of-thailand",
        "WORLD-MZ": "mozambique-channel indian-ocean",
        "WORLD-NA": "south-atlantic-ocean",
        "WORLD-NC": "coral-sea",
        "WORLD-NE": "",
        "WORLD-NG": "gulf-of-guinea",
        "WORLD-NI": "caribbean-sea north-pacific-ocean",
        "WORLD-NL": "north-sea",
        "WORLD-NO": "norwegian-sea north-sea barents-sea skagerrak",
        "WORLD-NP": "",
        "WORLD-NR": "south-pacific-ocean",
        "WORLD-NU": "south-pacific-ocean",
        "WORLD-NZ": "tasman-sea south-pacific-ocean",
        "WORLD-OM": "arabian-sea gulf-of-oman persian-gulf",
        "WORLD-PA": "north-pacific-ocean caribbean-sea",
        "WORLD-PE": "south-pacific-ocean",
        "WORLD-PF": "south-pacific-ocean",
        "WORLD-PG": "solomon-sea bismarck-sea coral-sea south-pacific-ocean arafura-sea",
        "WORLD-PH": "philippine-sea sulu-sea south-china-sea celebes-sea",
        "WORLD-PK": "arabian-sea gulf-of-oman",
        "WORLD-PL": "baltic-sea",
        "WORLD-PM": "gulf-of-st-lawrence",
        "WORLD-PN": "south-pacific-ocean",
        "WORLD-PS": "mediterranean-eastern-basin dead-sea",
        "WORLD-PT": "north-atlantic-ocean",
        "WORLD-PW": "philippine-sea north-pacific-ocean",
        "WORLD-PY": "",
        "WORLD-QA": "persian-gulf",
        "WORLD-RO": "black-sea",
        "WORLD-RS": "",
        "WORLD-RU": "kara-sea sea-of-okhotsk barents-sea laptev-sea east-siberian-sea bering-sea white-sea japan-sea chukchi-sea north-pacific-ocean caspian-sea sea-of-azov gulf-of-finland black-sea baltic-sea arctic-ocean",
        "WORLD-RW": "",
        "WORLD-SA": "red-sea persian-gulf gulf-of-aqaba",
        "WORLD-SB": "solomon-sea south-pacific-ocean coral-sea",
        "WORLD-SC": "indian-ocean",
        "WORLD-SD": "red-sea",
        "WORLD-SE": "baltic-sea gulf-of-bothnia kattegat skagerrak",
        "WORLD-SG": "singapore-strait",
        "WORLD-SH": "south-atlantic-ocean",
        "WORLD-SI": "adriatic-sea",
        "WORLD-SJ": "barents-sea greenland-sea arctic-ocean norwegian-sea",
        "WORLD-SK": "",
        "WORLD-SL": "north-atlantic-ocean",
        "WORLD-SM": "",
        "WORLD-SN": "north-atlantic-ocean",
        "WORLD-SO": "indian-ocean gulf-of-aden arabian-sea",
        "WORLD-SR": "north-atlantic-ocean",
        "WORLD-SS": "",
        "WORLD-ST": "gulf-of-guinea",
        "WORLD-SV": "north-pacific-ocean",
        "WORLD-SX": "caribbean-sea",
        "WORLD-SY": "mediterranean-eastern-basin",
        "WORLD-SZ": "",
        "WORLD-TC": "north-atlantic-ocean",
        "WORLD-TD": "",
        "WORLD-TF": "indian-ocean",
        "WORLD-TG": "gulf-of-guinea",
        "WORLD-TH": "gulf-of-thailand strait-of-malacca andaman-sea",
        "WORLD-TJ": "",
        "WORLD-TK": "south-pacific-ocean",
        "WORLD-TL": "banda-sea timor-sea savu-sea",
        "WORLD-TM": "caspian-sea",
        "WORLD-TN": "mediterranean-eastern-basin mediterranean-western-basin",
        "WORLD-TO": "south-pacific-ocean",
        "WORLD-TR": "black-sea aegean-sea mediterranean-eastern-basin sea-of-marmara",
        "WORLD-TT": "caribbean-sea north-atlantic-ocean",
        "WORLD-TV": "south-pacific-ocean",
        "WORLD-TW": "south-china-sea philippine-sea east-china-sea",
        "WORLD-TZ": "indian-ocean",
        "WORLD-UA": "black-sea sea-of-azov",
        "WORLD-UG": "",
        "WORLD-UM": "north-pacific-ocean",
        "WORLD-US": "bering-sea coastal-waters-of-southeast-alaska-and-british-columbia north-atlantic-ocean gulf-of-alaska gulf-of-mexico north-pacific-ocean chukchi-sea beaufort-sea bay-of-fundy",
        "WORLD-UY": "rio-de-la-plata south-atlantic-ocean",
        "WORLD-UZ": "",
        "WORLD-VA": "",
        "WORLD-VC": "caribbean-sea",
        "WORLD-VE": "caribbean-sea north-atlantic-ocean",
        "WORLD-VG": "caribbean-sea",
        "WORLD-VN": "south-china-sea gulf-of-thailand",
        "WORLD-VU": "coral-sea south-pacific-ocean",
        "WORLD-WF": "south-pacific-ocean",
        "WORLD-WS": "south-pacific-ocean",
        "WORLD-XC": "mediterranean-eastern-basin",
        "WORLD-XK": "",
        "WORLD-YE": "gulf-of-aden arabian-sea red-sea",
        "WORLD-ZA": "indian-ocean south-atlantic-ocean",
        "WORLD-ZM": "",
        "WORLD-ZW": "",
    ]
}
