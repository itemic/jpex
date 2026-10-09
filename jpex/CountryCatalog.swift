import Foundation

enum CountryCatalog {
    static let countries: [Country] = [
        world, japan, australia, canada, china, france, germany, italy, spain, switzerland, unitedKingdom, unitedStates,
        southKorea, taiwan, austria, netherlands, belgium, poland, portugal, norway,
        brazil, argentina, mexico, malaysia, thailand, philippines, indonesia, india,
        ireland, sweden, denmark, finland, czechia, croatia, greece, hungary, chile, colombia, peru, turkey, unitedArabEmirates, sriLanka, newZealand, southAfrica,
        iceland, estonia, lithuania, slovakia, romania, bulgaria, ukraine, egypt, kenya, ecuador, bolivia, uruguay, cuba, nepal, mongolia, saudiArabia,
        russia,
        jordan, oman, qatar, kuwait, bahrain, iran, iraq, cambodia, laos, bangladesh, bhutan, papuaNewGuinea, fiji,
        venezuela, paraguay, guatemala, costaRica, panama, dominicanRepublic, jamaica, honduras, elSalvador, nigeria, tanzania, ghana, senegal, rwanda, namibia, tunisia, algeria,
        serbia, bosniaAndHerzegovina, albania, montenegro, latvia, luxembourg, malta, belarus, armenia, kazakhstan, uzbekistan, kyrgyzstan,
    ]

    static func country(id: String) -> Country? {
        countries.first { $0.id == id }
    }

    /// Every collection, with Countries and China shaped by what the person counts as a country.
    static func countries(applying rules: CountingRules) -> [Country] {
        countries.map { collection in
            switch collection.id {
            case world.id: world(applying: rules)
            case china.id: china(applying: rules)
            default: collection
            }
        }
    }

    /// Countries first, then every other collection by continent, alphabetically.
    static func sections(applying rules: CountingRules) -> [CollectionSection] {
        let all = countries(applying: rules)
        let pinnedIDs = [world.id]
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
    ]

    /// The collection that lists a country's own subdivisions, such as Japan's prefectures.
    static func collection(for place: AdministrativeDivision) -> Country? {
        guard place.countryID == world.id else { return nil }
        return countries.first { $0.id != world.id && $0.id == place.abbreviation }
    }

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
