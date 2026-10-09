import Foundation

extension CountryCatalog {
    // 249 ISO 3166-1 entries plus Kosovo and Northern Cyprus (user-assigned XK and XC).
    // Names and continent groupings are display data; statuses use permanent WORLD-XX IDs,
    // except for places that also appear in another collection, which share that record.
    // The ID stays "WORLD"; the collection is shown as World, listing countries.
    static let world = Country(
        id: "WORLD", name: "World", localName: "World", divisionLabel: "Countries",
        groups: [
            DivisionGroup(id: "WORLD-africa", name: "Africa", divisions: [
                worldPlace("DZ", name: "Algeria", group: "africa"),
                worldPlace("AO", name: "Angola", group: "africa"),
                worldPlace("BJ", name: "Benin", group: "africa"),
                worldPlace("BW", name: "Botswana", group: "africa"),
                worldPlace("BF", name: "Burkina Faso", group: "africa"),
                worldPlace("BI", name: "Burundi", group: "africa"),
                worldPlace("CV", name: "Cabo Verde", group: "africa"),
                worldPlace("CM", name: "Cameroon", group: "africa"),
                worldPlace("CF", name: "Central African Republic", group: "africa"),
                worldPlace("TD", name: "Chad", group: "africa"),
                worldPlace("KM", name: "Comoros", group: "africa"),
                worldPlace("CI", name: "Côte d'Ivoire", group: "africa"),
                worldPlace("CD", name: "Democratic Republic of the Congo", group: "africa"),
                worldPlace("DJ", name: "Djibouti", group: "africa"),
                worldPlace("EG", name: "Egypt", group: "africa"),
                worldPlace("GQ", name: "Equatorial Guinea", group: "africa"),
                worldPlace("ER", name: "Eritrea", group: "africa"),
                worldPlace("SZ", name: "Eswatini", group: "africa"),
                worldPlace("ET", name: "Ethiopia", group: "africa"),
                worldPlace("TF", name: "French Southern Territories", group: "africa"),
                worldPlace("GA", name: "Gabon", group: "africa"),
                worldPlace("GM", name: "Gambia", group: "africa"),
                worldPlace("GH", name: "Ghana", group: "africa"),
                worldPlace("GN", name: "Guinea", group: "africa"),
                worldPlace("GW", name: "Guinea-Bissau", group: "africa"),
                worldPlace("KE", name: "Kenya", group: "africa"),
                worldPlace("LS", name: "Lesotho", group: "africa"),
                worldPlace("LR", name: "Liberia", group: "africa"),
                worldPlace("LY", name: "Libya", group: "africa"),
                worldPlace("MG", name: "Madagascar", group: "africa"),
                worldPlace("MW", name: "Malawi", group: "africa"),
                worldPlace("ML", name: "Mali", group: "africa"),
                worldPlace("MR", name: "Mauritania", group: "africa"),
                worldPlace("MU", name: "Mauritius", group: "africa"),
                worldPlace("YT", name: "Mayotte", group: "africa"),
                worldPlace("MA", name: "Morocco", group: "africa"),
                worldPlace("MZ", name: "Mozambique", group: "africa"),
                worldPlace("NA", name: "Namibia", group: "africa"),
                worldPlace("NE", name: "Niger", group: "africa"),
                worldPlace("NG", name: "Nigeria", group: "africa"),
                worldPlace("CG", name: "Republic of the Congo", group: "africa"),
                worldPlace("RW", name: "Rwanda", group: "africa"),
                worldPlace("RE", name: "Réunion", group: "africa"),
                worldPlace("SH", name: "Saint Helena, Ascension and Tristan da Cunha", group: "africa"),
                worldPlace("ST", name: "Sao Tome and Principe", group: "africa"),
                worldPlace("SN", name: "Senegal", group: "africa"),
                worldPlace("SC", name: "Seychelles", group: "africa"),
                worldPlace("SL", name: "Sierra Leone", group: "africa"),
                worldPlace("SO", name: "Somalia", group: "africa"),
                worldPlace("ZA", name: "South Africa", group: "africa"),
                worldPlace("SS", name: "South Sudan", group: "africa"),
                worldPlace("SD", name: "Sudan", group: "africa"),
                worldPlace("TZ", name: "Tanzania", group: "africa"),
                worldPlace("TG", name: "Togo", group: "africa"),
                worldPlace("TN", name: "Tunisia", group: "africa"),
                worldPlace("UG", name: "Uganda", group: "africa"),
                worldPlace("EH", name: "Western Sahara", group: "africa"),
                worldPlace("ZM", name: "Zambia", group: "africa"),
                worldPlace("ZW", name: "Zimbabwe", group: "africa"),
            ]),
            DivisionGroup(id: "WORLD-asia", name: "Asia", divisions: [
                worldPlace("AF", name: "Afghanistan", group: "asia"),
                worldPlace("AM", name: "Armenia", group: "asia"),
                worldPlace("AZ", name: "Azerbaijan", group: "asia"),
                worldPlace("BH", name: "Bahrain", group: "asia"),
                worldPlace("BD", name: "Bangladesh", group: "asia"),
                worldPlace("BT", name: "Bhutan", group: "asia"),
                worldPlace("IO", name: "British Indian Ocean Territory", group: "asia"),
                worldPlace("BN", name: "Brunei Darussalam", group: "asia"),
                worldPlace("KH", name: "Cambodia", group: "asia"),
                worldPlace("CN", name: "China", group: "asia"),
                worldPlace("CX", name: "Christmas Island", group: "asia"),
                worldPlace("CC", name: "Cocos (Keeling) Islands", group: "asia"),
                worldPlace("GE", name: "Georgia", group: "asia"),
                worldPlace("HK", name: "Hong Kong", group: "asia"),
                worldPlace("IN", name: "India", group: "asia"),
                worldPlace("ID", name: "Indonesia", group: "asia"),
                worldPlace("IR", name: "Iran", group: "asia"),
                worldPlace("IQ", name: "Iraq", group: "asia"),
                worldPlace("IL", name: "Israel", group: "asia"),
                worldPlace("JP", name: "Japan", group: "asia"),
                worldPlace("JO", name: "Jordan", group: "asia"),
                worldPlace("KZ", name: "Kazakhstan", group: "asia"),
                worldPlace("KW", name: "Kuwait", group: "asia"),
                worldPlace("KG", name: "Kyrgyzstan", group: "asia"),
                worldPlace("LA", name: "Laos", group: "asia"),
                worldPlace("LB", name: "Lebanon", group: "asia"),
                worldPlace("MO", name: "Macau", group: "asia"),
                worldPlace("MY", name: "Malaysia", group: "asia"),
                worldPlace("MV", name: "Maldives", group: "asia"),
                worldPlace("MN", name: "Mongolia", group: "asia"),
                worldPlace("MM", name: "Myanmar", group: "asia"),
                worldPlace("NP", name: "Nepal", group: "asia"),
                worldPlace("KP", name: "North Korea", group: "asia"),
                worldPlace("OM", name: "Oman", group: "asia"),
                worldPlace("PK", name: "Pakistan", group: "asia"),
                worldPlace("PS", name: "Palestine", group: "asia"),
                worldPlace("PH", name: "Philippines", group: "asia"),
                worldPlace("QA", name: "Qatar", group: "asia"),
                worldPlace("SA", name: "Saudi Arabia", group: "asia"),
                worldPlace("SG", name: "Singapore", group: "asia"),
                worldPlace("KR", name: "South Korea", group: "asia"),
                worldPlace("LK", name: "Sri Lanka", group: "asia"),
                worldPlace("SY", name: "Syria", group: "asia"),
                worldPlace("TW", name: "Taiwan", group: "asia"),
                worldPlace("TJ", name: "Tajikistan", group: "asia"),
                worldPlace("TH", name: "Thailand", group: "asia"),
                worldPlace("TL", name: "Timor-Leste", group: "asia"),
                worldPlace("TM", name: "Turkmenistan", group: "asia"),
                worldPlace("TR", name: "Türkiye", group: "asia"),
                worldPlace("AE", name: "United Arab Emirates", group: "asia"),
                worldPlace("UZ", name: "Uzbekistan", group: "asia"),
                worldPlace("VN", name: "Vietnam", group: "asia"),
                worldPlace("YE", name: "Yemen", group: "asia"),
            ]),
            DivisionGroup(id: "WORLD-europe", name: "Europe", divisions: [
                worldPlace("AL", name: "Albania", group: "europe"),
                worldPlace("AD", name: "Andorra", group: "europe"),
                worldPlace("AT", name: "Austria", group: "europe"),
                worldPlace("BY", name: "Belarus", group: "europe"),
                worldPlace("BE", name: "Belgium", group: "europe"),
                worldPlace("BA", name: "Bosnia and Herzegovina", group: "europe"),
                worldPlace("BG", name: "Bulgaria", group: "europe"),
                worldPlace("HR", name: "Croatia", group: "europe"),
                worldPlace("CY", name: "Cyprus", group: "europe"),
                worldPlace("CZ", name: "Czechia", group: "europe"),
                worldPlace("DK", name: "Denmark", group: "europe"),
                worldPlace("EE", name: "Estonia", group: "europe"),
                worldPlace("FO", name: "Faroe Islands", group: "europe"),
                worldPlace("FI", name: "Finland", group: "europe"),
                worldPlace("FR", name: "France", group: "europe"),
                worldPlace("DE", name: "Germany", group: "europe"),
                worldPlace("GI", name: "Gibraltar", group: "europe"),
                worldPlace("GR", name: "Greece", group: "europe"),
                worldPlace("GG", name: "Guernsey", group: "europe"),
                worldPlace("HU", name: "Hungary", group: "europe"),
                worldPlace("IS", name: "Iceland", group: "europe"),
                worldPlace("IE", name: "Ireland", group: "europe"),
                worldPlace("IM", name: "Isle of Man", group: "europe"),
                worldPlace("IT", name: "Italy", group: "europe"),
                worldPlace("JE", name: "Jersey", group: "europe"),
                worldPlace("XK", name: "Kosovo", group: "europe"),
                worldPlace("LV", name: "Latvia", group: "europe"),
                worldPlace("LI", name: "Liechtenstein", group: "europe"),
                worldPlace("LT", name: "Lithuania", group: "europe"),
                worldPlace("LU", name: "Luxembourg", group: "europe"),
                worldPlace("MT", name: "Malta", group: "europe"),
                worldPlace("MD", name: "Moldova", group: "europe"),
                worldPlace("MC", name: "Monaco", group: "europe"),
                worldPlace("ME", name: "Montenegro", group: "europe"),
                worldPlace("NL", name: "Netherlands", group: "europe"),
                worldPlace("MK", name: "North Macedonia", group: "europe"),
                worldPlace("XC", name: "Northern Cyprus", group: "europe"),
                worldPlace("NO", name: "Norway", group: "europe"),
                worldPlace("PL", name: "Poland", group: "europe"),
                worldPlace("PT", name: "Portugal", group: "europe"),
                worldPlace("RO", name: "Romania", group: "europe"),
                worldPlace("RU", name: "Russia", group: "europe"),
                worldPlace("SM", name: "San Marino", group: "europe"),
                worldPlace("RS", name: "Serbia", group: "europe"),
                worldPlace("SK", name: "Slovakia", group: "europe"),
                worldPlace("SI", name: "Slovenia", group: "europe"),
                worldPlace("ES", name: "Spain", group: "europe"),
                worldPlace("SJ", name: "Svalbard and Jan Mayen", group: "europe"),
                worldPlace("SE", name: "Sweden", group: "europe"),
                worldPlace("CH", name: "Switzerland", group: "europe"),
                worldPlace("UA", name: "Ukraine", group: "europe"),
                worldPlace("GB", name: "United Kingdom", group: "europe"),
                // Shown by the name people travel to; its formal name, the Holy See, is the state.
                worldPlace("VA", name: "Vatican City", group: "europe"),
                worldPlace("AX", name: "Åland Islands", group: "europe"),
            ]),
            DivisionGroup(id: "WORLD-north-america", name: "North America", divisions: [
                worldPlace("AI", name: "Anguilla", group: "north-america"),
                worldPlace("AG", name: "Antigua and Barbuda", group: "north-america"),
                worldPlace("AW", name: "Aruba", group: "north-america"),
                worldPlace("BS", name: "Bahamas", group: "north-america"),
                worldPlace("BB", name: "Barbados", group: "north-america"),
                worldPlace("BZ", name: "Belize", group: "north-america"),
                worldPlace("BM", name: "Bermuda", group: "north-america"),
                worldPlace("BQ", name: "Bonaire, Sint Eustatius and Saba", group: "north-america"),
                worldPlace("CA", name: "Canada", group: "north-america"),
                worldPlace("KY", name: "Cayman Islands", group: "north-america"),
                worldPlace("CR", name: "Costa Rica", group: "north-america"),
                worldPlace("CU", name: "Cuba", group: "north-america"),
                worldPlace("CW", name: "Curaçao", group: "north-america"),
                worldPlace("DM", name: "Dominica", group: "north-america"),
                worldPlace("DO", name: "Dominican Republic", group: "north-america"),
                worldPlace("SV", name: "El Salvador", group: "north-america"),
                worldPlace("GL", name: "Greenland", group: "north-america"),
                worldPlace("GD", name: "Grenada", group: "north-america"),
                worldPlace("GP", name: "Guadeloupe", group: "north-america"),
                worldPlace("GT", name: "Guatemala", group: "north-america"),
                worldPlace("HT", name: "Haiti", group: "north-america"),
                worldPlace("HN", name: "Honduras", group: "north-america"),
                worldPlace("JM", name: "Jamaica", group: "north-america"),
                worldPlace("MQ", name: "Martinique", group: "north-america"),
                worldPlace("MX", name: "Mexico", group: "north-america"),
                worldPlace("MS", name: "Montserrat", group: "north-america"),
                worldPlace("NI", name: "Nicaragua", group: "north-america"),
                worldPlace("PA", name: "Panama", group: "north-america"),
                worldPlace("PR", name: "Puerto Rico", group: "north-america"),
                worldPlace("BL", name: "Saint Barthélemy", group: "north-america"),
                worldPlace("KN", name: "Saint Kitts and Nevis", group: "north-america"),
                worldPlace("LC", name: "Saint Lucia", group: "north-america"),
                worldPlace("MF", name: "Saint Martin", group: "north-america"),
                worldPlace("PM", name: "Saint Pierre and Miquelon", group: "north-america"),
                worldPlace("VC", name: "Saint Vincent and the Grenadines", group: "north-america"),
                worldPlace("SX", name: "Sint Maarten", group: "north-america"),
                worldPlace("TC", name: "Turks and Caicos Islands", group: "north-america"),
                worldPlace("UM", name: "United States Minor Outlying Islands", group: "north-america"),
                worldPlace("US", name: "United States of America", group: "north-america"),
                worldPlace("VG", name: "Virgin Islands (British)", group: "north-america"),
                worldPlace("VI", name: "Virgin Islands (U.S.)", group: "north-america"),
            ]),
            DivisionGroup(id: "WORLD-south-america", name: "South America", divisions: [
                worldPlace("AR", name: "Argentina", group: "south-america"),
                worldPlace("BO", name: "Bolivia", group: "south-america"),
                worldPlace("BR", name: "Brazil", group: "south-america"),
                worldPlace("CL", name: "Chile", group: "south-america"),
                worldPlace("CO", name: "Colombia", group: "south-america"),
                worldPlace("EC", name: "Ecuador", group: "south-america"),
                worldPlace("FK", name: "Falkland Islands", group: "south-america"),
                worldPlace("GF", name: "French Guiana", group: "south-america"),
                worldPlace("GY", name: "Guyana", group: "south-america"),
                worldPlace("PY", name: "Paraguay", group: "south-america"),
                worldPlace("PE", name: "Peru", group: "south-america"),
                worldPlace("SR", name: "Suriname", group: "south-america"),
                worldPlace("TT", name: "Trinidad and Tobago", group: "south-america"),
                worldPlace("UY", name: "Uruguay", group: "south-america"),
                worldPlace("VE", name: "Venezuela", group: "south-america"),
            ]),
            DivisionGroup(id: "WORLD-oceania", name: "Oceania", divisions: [
                worldPlace("AS", name: "American Samoa", group: "oceania"),
                worldPlace("AU", name: "Australia", group: "oceania"),
                worldPlace("CK", name: "Cook Islands", group: "oceania"),
                worldPlace("FM", name: "Federated States of Micronesia", group: "oceania"),
                worldPlace("FJ", name: "Fiji", group: "oceania"),
                worldPlace("PF", name: "French Polynesia", group: "oceania"),
                worldPlace("GU", name: "Guam", group: "oceania"),
                worldPlace("KI", name: "Kiribati", group: "oceania"),
                worldPlace("MH", name: "Marshall Islands", group: "oceania"),
                worldPlace("NR", name: "Naoero", group: "oceania"),
                worldPlace("NC", name: "New Caledonia", group: "oceania"),
                worldPlace("NZ", name: "New Zealand", group: "oceania"),
                worldPlace("NU", name: "Niue", group: "oceania"),
                worldPlace("NF", name: "Norfolk Island", group: "oceania"),
                worldPlace("MP", name: "Northern Mariana Islands", group: "oceania"),
                worldPlace("PW", name: "Palau", group: "oceania"),
                worldPlace("PG", name: "Papua New Guinea", group: "oceania"),
                worldPlace("PN", name: "Pitcairn", group: "oceania"),
                worldPlace("WS", name: "Samoa", group: "oceania"),
                worldPlace("SB", name: "Solomon Islands", group: "oceania"),
                worldPlace("TK", name: "Tokelau", group: "oceania"),
                worldPlace("TO", name: "Tonga", group: "oceania"),
                worldPlace("TV", name: "Tuvalu", group: "oceania"),
                worldPlace("VU", name: "Vanuatu", group: "oceania"),
                worldPlace("WF", name: "Wallis and Futuna", group: "oceania"),
            ]),
            DivisionGroup(id: "WORLD-antarctica", name: "Antarctica", divisions: [
                worldPlace("AQ", name: "Antarctica", group: "antarctica"),
                worldPlace("BV", name: "Bouvet Island", group: "antarctica"),
                worldPlace("HM", name: "Heard Island and McDonald Islands", group: "antarctica"),
                worldPlace("GS", name: "South Georgia and the South Sandwich Islands", group: "antarctica"),
            ]),
        ]
    )

    private static func worldPlace(_ code: String, name: String, group: String) -> AdministrativeDivision {
        AdministrativeDivision(
            id: sharedPlaceIDs[code] ?? "WORLD-\(code)", countryID: "WORLD", name: name, abbreviation: code,
            groupID: "WORLD-\(group)", flagAssetName: "world_flag_\(code.lowercased())"
        )
    }

    /// Places listed in Countries and in another collection. Both lists show one shared status.
    static let sharedPlaceIDs: [String: String] = [
        "HK": "CN-HK", "MO": "CN-MO",
        "GP": "FR-971", "MQ": "FR-972", "GF": "FR-973", "RE": "FR-974", "YT": "FR-976",
        "AS": "US-AS", "GU": "US-GU", "MP": "US-MP", "PR": "US-PR", "VI": "US-VI",
        "CX": "AU-CX", "CC": "AU-CC", "NF": "AU-NF", "HM": "AU-HM",
        "AX": "FI-01",
    ]

    /// Before places were shared, Countries saved them under their own WORLD-XX IDs.
    /// Those statuses are still read when the shared record has never been set.
    static let legacyStatusIDs: [String: String] = Dictionary(
        uniqueKeysWithValues: sharedPlaceIDs.map { code, sharedID in (sharedID, "WORLD-\(code)") }
    )

    // ISO 3166-1 codes grouped by how often travellers count them as separate countries.
    private static let specialRegionCodes: Set<String> = ["HK", "MO"]
    private static let taiwanCodes: Set<String> = ["TW"]
    private static let remotePlaceCodes: Set<String> = ["AQ", "BV", "GS", "HM", "IO", "TF", "UM"]
    private static let territoryCodes: Set<String> = [
        "AI", "AS", "AW", "AX", "BL", "BM", "BQ", "CC", "CW", "CX", "FK", "FO", "GF",
        "GG", "GI", "GL", "GP", "GU", "IM", "JE", "KY", "MF", "MP", "MQ", "MS", "NC", "NF",
        "PF", "PM", "PN", "PR", "RE", "SH", "SJ", "SX", "TC", "TK", "VG", "VI", "WF", "YT",
    ]
    /// The two states with permanent observer status at the UN: the Holy See (Vatican City) and Palestine.
    private static let observerCodes: Set<String> = ["VA", "PS"]
    /// Places recognised as states by some UN members but not others, besides Taiwan.
    private static let partlyRecognisedCodes: Set<String> = ["XK", "EH"]
    /// Self-governing states in free association with New Zealand, outside the UN.
    private static let associatedStateCodes: Set<String> = ["CK", "NU"]
    /// States that govern themselves but are recognised by no UN member except the one backing
    /// them: Northern Cyprus, recognised only by Türkiye.
    private static let deFactoStateCodes: Set<String> = ["XC"]

    /// Countries whose main territory spans two continents, with the continents each can be listed
    /// under, its usual one first. Countries with outlying territory elsewhere, such as France with
    /// New Caledonia, are listed by their main territory and have no choice.
    static let transcontinentalPlaces: [(code: String, continents: [String])] = [
        ("RU", ["europe", "asia"]),
        ("TR", ["asia", "europe"]),
        ("KZ", ["asia", "europe"]),
        ("AZ", ["asia", "europe"]),
        ("GE", ["asia", "europe"]),
        ("EG", ["africa", "asia"]),
        ("ID", ["asia", "oceania"]),
    ]

    /// The continent a country is listed under: the person's choice where it spans two.
    static func continent(of code: String, rules: CountingRules) -> String? {
        if let choice = rules.continentChoices[code],
           transcontinentalPlaces.contains(where: { $0.code == code && $0.continents.contains(choice) }) {
            return choice
        }
        return world.divisions.first { $0.abbreviation == code }.map { $0.groupID.replacingOccurrences(of: "WORLD-", with: "") }
    }

    /// Countries as the counting rules define them.
    static func world(applying rules: CountingRules) -> Country {
        var countries = world
        // Countries spanning two continents move to the one the person chose.
        for (code, choice) in rules.continentChoices {
            guard transcontinentalPlaces.contains(where: { $0.code == code && $0.continents.contains(choice) }),
                  let from = countries.groups.firstIndex(where: { $0.divisions.contains { $0.abbreviation == code } }),
                  let to = countries.groups.firstIndex(where: { $0.id == "WORLD-\(choice)" }), from != to,
                  let index = countries.groups[from].divisions.firstIndex(where: { $0.abbreviation == code })
            else { continue }
            var place = countries.groups[from].divisions.remove(at: index)
            place.groupID = countries.groups[to].id
            let position = countries.groups[to].divisions.firstIndex {
                $0.name.localizedStandardCompare(place.name) == .orderedDescending
            } ?? countries.groups[to].divisions.endIndex
            countries.groups[to].divisions.insert(place, at: position)
        }
        let source = countries
        countries.groups = source.groups.compactMap { group in
            var group = group
            group.divisions.removeAll { !rules.includesWorldPlace(code: $0.abbreviation) }
            if rules.splitsUnitedKingdom, group.divisions.contains(where: { $0.abbreviation == "GB" }) {
                group.divisions.removeAll { $0.abbreviation == "GB" }
                for nation in unitedKingdom.divisions {
                    var place = nation
                    place.groupID = group.id
                    let index = group.divisions.firstIndex {
                        $0.name.localizedStandardCompare(place.name) == .orderedDescending
                    } ?? group.divisions.endIndex
                    group.divisions.insert(place, at: index)
                }
            }
            return group.divisions.isEmpty ? nil : group
        }
        return countries
    }

    /// The Countries entries a place belongs to under the counting rules, nearest first, such as
    /// Canada for Ontario. Empty for entries in Countries themselves, including places that count
    /// as countries of their own, such as Hong Kong or the UK nations when the rules list them.
    /// Taiwan's places belong to Taiwan, and through it to China while Taiwan isn't counted.
    static func countries(containing place: AdministrativeDivision, rules: CountingRules) -> [AdministrativeDivision] {
        let counted = world(applying: rules).divisions
        guard !counted.contains(where: { $0.id == place.id }) else { return [] }
        let owner: AdministrativeDivision? = if place.countryID == world.id {
            sovereignCodes[place.abbreviation].flatMap { code in world.divisions.first { $0.abbreviation == code } }
        } else {
            world.divisions.first { $0.abbreviation == place.countryID }
        }
        guard let owner, owner.id != place.id else { return [] }
        if counted.contains(where: { $0.id == owner.id }) { return [owner] }
        let above = countries(containing: owner, rules: rules)
        return above.isEmpty ? [] : [owner] + above
    }

    /// Map regions for places that don't count as countries under the rules, drawn and tapped as
    /// the country they belong to, such as Taiwan as China while Taiwan isn't counted.
    static func mapRegionOwners(applying rules: CountingRules) -> [String: String] {
        let counted = Set(world(applying: rules).divisions.map(\.id))
        var owners: [String: String] = [:]
        for place in world.divisions where !counted.contains(place.id) {
            guard let owner = countries(containing: place, rules: rules).last else { continue }
            owners[place.id] = owner.id
        }
        return owners
    }

    /// China's provinces and regions, with Taiwan among them while it isn't counted as a country.
    static func china(applying rules: CountingRules) -> Country {
        guard !rules.includesTaiwan, let taiwan = world.divisions.first(where: { $0.abbreviation == "TW" }) else {
            return china
        }
        var collection = china
        if let east = collection.groups.firstIndex(where: { $0.id == "CN-east" }) {
            var place = taiwan
            place.groupID = collection.groups[east].id
            place.localName = "台湾"
            collection.groups[east].divisions.append(place)
        }
        return collection
    }

    /// The name of the country a territory or region belongs to, such as France for Réunion.
    static func sovereignName(of code: String) -> String? {
        sovereignCodes[code].flatMap { owner in world.divisions.first { $0.abbreviation == owner }?.name }
    }

    /// A short code for the country a territory or region belongs to, such as FR for Réunion,
    /// with UK for the United Kingdom as people write it.
    static func sovereignShortCode(of code: String) -> String? {
        sovereignCodes[code].map { $0 == "GB" ? "UK" : $0 }
    }

    /// Where places outside the list of countries belong, by ISO code. Western Sahara is left
    /// out because its status is disputed; Antarctica belongs to no country. Northern Cyprus is
    /// part of Cyprus while it isn't counted on its own, as the UN holds.
    private static let sovereignCodes: [String: String] = [
        "TW": "CN", "HK": "CN", "MO": "CN",
        "GL": "DK", "FO": "DK", "AX": "FI", "SJ": "NO", "BV": "NO",
        "AW": "NL", "CW": "NL", "SX": "NL", "BQ": "NL",
        "AI": "GB", "BM": "GB", "VG": "GB", "KY": "GB", "FK": "GB", "GI": "GB", "GG": "GB", "JE": "GB",
        "IM": "GB", "MS": "GB", "PN": "GB", "SH": "GB", "TC": "GB", "IO": "GB", "GS": "GB",
        "GP": "FR", "MQ": "FR", "GF": "FR", "RE": "FR", "YT": "FR", "PM": "FR", "BL": "FR", "MF": "FR",
        "WF": "FR", "PF": "FR", "NC": "FR", "TF": "FR",
        "PR": "US", "GU": "US", "VI": "US", "AS": "US", "MP": "US", "UM": "US",
        "CX": "AU", "CC": "AU", "NF": "AU", "HM": "AU",
        "CK": "NZ", "NU": "NZ", "TK": "NZ",
        "XC": "CY",
    ]

    /// The group of places that may or may not count as countries a code belongs to, or nil for
    /// a place that always counts.
    static func optionalPlaceGroup(code: String) -> OptionalPlaceGroup? {
        if specialRegionCodes.contains(code) { return .specialRegions }
        if taiwanCodes.contains(code) { return .taiwan }
        if remotePlaceCodes.contains(code) { return .remotePlaces }
        if territoryCodes.contains(code) { return .territories }
        if observerCodes.contains(code) { return .observers }
        if partlyRecognisedCodes.contains(code) { return .partlyRecognised }
        if associatedStateCodes.contains(code) { return .associatedStates }
        if deFactoStateCodes.contains(code) { return .deFactoStates }
        return nil
    }

    /// The places in a group, by name.
    static func places(in group: OptionalPlaceGroup) -> [AdministrativeDivision] {
        let codes: Set<String> = switch group {
        case .specialRegions: specialRegionCodes
        case .taiwan: taiwanCodes
        case .territories: territoryCodes
        case .remotePlaces: remotePlaceCodes
        case .observers: observerCodes
        case .partlyRecognised: partlyRecognisedCodes
        case .associatedStates: associatedStateCodes
        case .deFactoStates: deFactoStateCodes
        }
        return world.divisions
            .filter { codes.contains($0.abbreviation) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

extension CountingRules {
    /// Whether a place in the World list counts as a country of its own: its group is switched on
    /// and the place itself hasn't been switched off.
    func includesWorldPlace(code: String) -> Bool {
        guard let group = CountryCatalog.optionalPlaceGroup(code: code) else { return true }
        return includes(group) && !excludedPlaces.contains(code)
    }
}
