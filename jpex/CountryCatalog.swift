import Foundation

enum CountryCatalog {
    static let countries: [Country] = [
        world, seas, japan, australia, canada, china, france, frenchDepartments, germany, italy, spain, switzerland, unitedKingdom, unitedStates,
        southKorea, taiwan, austria, netherlands, belgium, poland, portugal, norway,
        brazil, argentina, mexico, malaysia, thailand, philippines, indonesia, india,
        ireland, sweden, denmark, finland, czechia, croatia, greece, hungary, chile, colombia, peru, turkey, unitedArabEmirates, sriLanka, newZealand, southAfrica,
        iceland, estonia, lithuania, slovakia, romania, bulgaria, ukraine, egypt, kenya, ecuador, bolivia, uruguay, cuba, nepal, mongolia, saudiArabia,
        russia,
        jordan, oman, qatar, kuwait, bahrain, iran, iraq, cambodia, laos, bangladesh, bhutan, papuaNewGuinea, fiji,
        venezuela, paraguay, guatemala, costaRica, panama, dominicanRepublic, jamaica, honduras, elSalvador, nigeria, tanzania, ghana, senegal, rwanda, namibia, tunisia, algeria,
        serbia, bosniaAndHerzegovina, albania, montenegro, latvia, luxembourg, malta, belarus, armenia, kazakhstan, uzbekistan, kyrgyzstan,
        vietnam, afghanistan, brunei, zambia, zimbabwe, mozambique, cameroon, botswana,
        georgia, tajikistan, moldova, lebanon, pakistan, belize, guyana, haiti, suriname, tonga, samoa,
        myanmar, trinidadAndTobago, nicaragua, vanuatu, solomonIslands,
    ] + subdivisionLists

    static func country(id: String) -> Country? {
        countries.first { $0.id == id }
    }

    /// Every collection, with Countries and China shaped by what the person counts as a country, and
    /// Seas by the names the person calls them.
    static func countries(applying rules: CountingRules) -> [Country] {
        countries.map { collection in
            switch collection.id {
            case world.id: world(applying: rules)
            case seas.id: seas(applying: rules)
            case china.id: china(applying: rules)
            default: collection
            }
        }
    }

    /// A country's lists, one for each level it's listed at, first level first, such as France's
    /// regions and then its departments. Just the list itself for every other list. Lists of one
    /// place's own subdivisions, such as Tasmania's, aren't levels of their country.
    static func levels(of collection: Country) -> [Country] {
        let levels = countries.filter { $0.countryListID == collection.countryListID && $0.parentPlace == nil }
        return levels.count > 1 ? levels : [collection]
    }

    /// The places a place lies within that rise with it, nearest first: where its country is listed
    /// at more than one level, its place on the first, such as Île-de-France for Paris; then the
    /// countries it belongs to under the counting rules, such as France.
    static func placesContaining(_ place: AdministrativeDivision, rules: CountingRules) -> [AdministrativeDivision] {
        guard let parent = place.parentID.flatMap({ countryPlaces[$0] }), parent.id != place.id else {
            return countries(containing: place, rules: rules)
        }
        return [parent] + placesContaining(parent, rules: rules)
    }

    /// A place in a country's own list, by ID, such as Île-de-France.
    static func countryPlace(id: String) -> AdministrativeDivision? {
        countryPlaces[id]
    }

    /// The IDs of the places other places lie within, such as France's regions.
    static let regionIDs = Set(countryPlaces.values.compactMap(\.parentID))

    /// Every place in countries' own lists, by ID, for finding the place another lies within.
    private static let countryPlaces: [String: AdministrativeDivision] = Dictionary(
        countries.filter { $0.id != world.id }.flatMap(\.divisions).map { ($0.id, $0) }
    ) { first, _ in first }

    /// Countries and Seas first, then every other collection by continent, alphabetically. A country listed
    /// at more than one level is listed once, by its first level. A list of one place's own
    /// subdivisions, such as Tasmania's, opens from that place instead.
    static func sections(applying rules: CountingRules) -> [CollectionSection] {
        let all = countries(applying: rules).filter { $0.firstLevelID == nil && $0.parentPlace == nil }
        let pinnedIDs = [world.id, seas.id]
        var sections = [CollectionSection(title: nil, countries: pinnedIDs.compactMap { id in all.first { $0.id == id } })]
        let others = all.filter { !pinnedIDs.contains($0.id) }
        for continent in ["Asia", "Europe", "Americas", "Africa", "Oceania"] {
            let members = others
                .filter { sectionTitle(for: $0.id, rules: rules) == continent }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            if !members.isEmpty { sections.append(CollectionSection(title: continent, countries: members)) }
        }
        let unplaced = others.filter { sectionTitle(for: $0.id, rules: rules) == nil }
        if !unplaced.isEmpty { sections.append(CollectionSection(title: "More", countries: unplaced)) }
        return sections
    }

    /// The sidebar section a country's list sits in: its continent, or for a country spanning two,
    /// the one the person chose.
    private static func sectionTitle(for id: String, rules: CountingRules) -> String? {
        if let choice = rules.continentChoices[id],
           transcontinentalPlaces.contains(where: { $0.code == id && $0.continents.contains(choice) }) {
            return choice.hasSuffix("america") ? "Americas" : choice.capitalized
        }
        return continents[id]
    }

    private static let continents: [String: String] = [
        "CN": "Asia", "IN": "Asia", "ID": "Asia", "JP": "Asia", "KR": "Asia", "MY": "Asia", "PH": "Asia", "TH": "Asia",
        "TW": "Asia",
        "AT": "Europe", "BE": "Europe", "CH": "Europe", "DE": "Europe", "ES": "Europe", "FR": "Europe", "GB": "Europe",
        "IT": "Europe", "NL": "Europe", "NO": "Europe", "PL": "Europe", "PT": "Europe",
        "AR": "Americas", "BR": "Americas", "CA": "Americas", "MX": "Americas", "US": "Americas",
        "AU": "Oceania",
        "IE": "Europe", "SE": "Europe", "DK": "Europe", "FI": "Europe", "CZ": "Europe", "HR": "Europe", "GR": "Europe", "HU": "Europe", "CL": "Americas", "CO": "Americas", "PE": "Americas", "TR": "Asia", "AE": "Asia", "LK": "Asia", "NZ": "Oceania", "ZA": "Africa",
        "IS": "Europe", "EE": "Europe", "LT": "Europe", "SK": "Europe", "RO": "Europe", "BG": "Europe", "UA": "Europe", "EG": "Africa", "KE": "Africa", "EC": "Americas", "BO": "Americas", "UY": "Americas", "CU": "Americas", "NP": "Asia", "MN": "Asia", "SA": "Asia",
        "RU": "Europe",
        "JO": "Asia", "OM": "Asia", "QA": "Asia", "KW": "Asia", "BH": "Asia", "IR": "Asia", "IQ": "Asia", "KH": "Asia", "LA": "Asia", "BD": "Asia", "BT": "Asia", "PG": "Oceania", "FJ": "Oceania",
        "VE": "Americas", "PY": "Americas", "GT": "Americas", "CR": "Americas", "PA": "Americas", "DO": "Americas", "JM": "Americas", "HN": "Americas", "SV": "Americas", "NG": "Africa", "TZ": "Africa", "GH": "Africa", "SN": "Africa", "RW": "Africa", "NA": "Africa", "TN": "Africa", "DZ": "Africa",
        "RS": "Europe", "BA": "Europe", "AL": "Europe", "ME": "Europe", "LV": "Europe", "LU": "Europe", "MT": "Europe", "BY": "Europe", "AM": "Asia", "KZ": "Asia", "UZ": "Asia", "KG": "Asia",
        "VN": "Asia", "AF": "Asia", "BN": "Asia", "ZM": "Africa", "ZW": "Africa", "MZ": "Africa", "CM": "Africa", "BW": "Africa",
        "GE": "Asia", "TJ": "Asia", "MD": "Europe", "LB": "Asia", "PK": "Asia", "BZ": "Americas", "GY": "Americas",
        "HT": "Americas", "SR": "Americas", "TO": "Oceania", "WS": "Oceania", "MM": "Asia", "TT": "Americas", "NI": "Americas", "VU": "Oceania", "SB": "Oceania",
    ]

    /// The collection that lists a place's own subdivisions: for a country, such as Japan, its
    /// prefectures; for a place in a country's list, such as Tasmania, its local government areas.
    static func collection(for place: AdministrativeDivision) -> Country? {
        guard place.countryID == world.id else { return listsBySubdividedPlace[place.id] }
        return countries.first { $0.id != world.id && $0.id == place.abbreviation }
    }

    /// Lists of one place's own subdivisions, by that place's ID.
    private static let listsBySubdividedPlace: [String: Country] = Dictionary(
        countries.compactMap { list in list.parentPlace.map { ($0.id, list) } }
    ) { first, _ in first }

    static let japan = Country(
        id: "JP",
        name: "Japan",
        localName: "日本",
        divisionLabel: "Prefectures",
        groups: Region.allCases.map { region in
            let groupID = "JP-\(region.rawValue)"
            return DivisionGroup(
                id: groupID,
                name: region.eng,
                localName: region.jpn,
                divisions: Prefecture.prefecturesFrom(region).map { prefecture in
                    AdministrativeDivision(
                        id: String(format: "JP-%02d", prefecture.id),
                        countryID: "JP",
                        name: prefecture.name,
                        localName: prefecture.localName,
                        abbreviation: String(format: "%02d", prefecture.id),
                        groupID: groupID,
                        flagAssetName: "jp_flag\(prefecture.id)",
                        legacyJapanIndex: prefecture.id - 1
                    )
                }
            )
        }
    )

    // Australian territories follow the Australian Government's territory list:
    // https://www.infrastructure.gov.au/territories-regions/australian-territories
    // AU-NSW…AU-WA and JP-01…JP-47 use ISO 3166-2 identifiers. Other AU
    // territory IDs are app identifiers and intentionally are not claimed as ISO.
    // Never rename existing IDs when adding countries or changing display names.
    static let australia = Country(
        id: "AU",
        name: "Australia",
        localName: "Australia",
        divisionLabel: "States & territories",
        groups: [
            DivisionGroup(
                id: "AU-states",
                name: "States",
                divisions: [
                    australianDivision("NSW", name: "New South Wales", group: "states", flag: "nsw"),
                    australianDivision("QLD", name: "Queensland", group: "states", flag: "qld"),
                    australianDivision("SA", name: "South Australia", group: "states", flag: "sa"),
                    australianDivision("TAS", name: "Tasmania", group: "states", flag: "tas"),
                    australianDivision("VIC", name: "Victoria", group: "states", flag: "vic"),
                    australianDivision("WA", name: "Western Australia", group: "states", flag: "wa")
                ]
            ),
            DivisionGroup(
                id: "AU-mainland",
                name: "Mainland territories",
                divisions: [
                    australianDivision("ACT", name: "Australian Capital Territory", group: "mainland", flag: "act"),
                    australianDivision("JBT", name: "Jervis Bay Territory", group: "mainland"),
                    australianDivision("NT", name: "Northern Territory", group: "mainland", flag: "nt")
                ]
            ),
            DivisionGroup(
                id: "AU-external",
                name: "External territories",
                divisions: [
                    australianDivision("AC", name: "Ashmore and Cartier Islands", group: "external"),
                    australianDivision("AAT", name: "Australian Antarctic Territory", group: "external"),
                    australianDivision("CX", name: "Christmas Island", group: "external", flag: "cx", flagNote: "The Christmas Island community flag is shown here."),
                    australianDivision("CC", name: "Cocos (Keeling) Islands", group: "external"),
                    australianDivision("CS", name: "Coral Sea Islands", group: "external"),
                    australianDivision("HM", name: "Heard Island and McDonald Islands", group: "external"),
                    australianDivision("NF", name: "Norfolk Island", group: "external", flag: "nf")
                ]
            )
        ]
    )

    private static func australianDivision(
        _ code: String,
        name: String,
        group: String,
        flag: String? = nil,
        flagNote: String? = nil
    ) -> AdministrativeDivision {
        AdministrativeDivision(
            id: "AU-\(code)",
            countryID: "AU",
            name: name,
            abbreviation: code,
            groupID: "AU-\(group)",
            flagAssetName: flag.map { "au_flag_\($0)" } ?? "au_flag",
            flagNote: flagNote ?? (flag == nil ? "The Australian national flag is shown; this territory has no separate official flag." : nil)
        )
    }
}
