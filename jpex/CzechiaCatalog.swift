import Foundation

extension CountryCatalog {
    // Czechia's 13 regions and the capital, Prague. IDs follow ISO 3166-2:CZ; districts are not included.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and CzechiaFlagCredits.json.
    static let czechia = Country(
        id: "CZ",
        name: "Czechia",
        localName: "Česko",
        divisionLabel: "Regions",
        groups: [
            czechGroup("regions", name: "Regions", localName: "Kraje", divisions: [
                ("20", "Central Bohemian", "Středočeský kraj"),
                ("52", "Hradec Králové", "Královéhradecký kraj"),
                ("41", "Karlovy Vary", "Karlovarský kraj"),
                ("51", "Liberec", "Liberecký kraj"),
                ("80", "Moravian-Silesian", "Moravskoslezský kraj"),
                ("71", "Olomouc", "Olomoucký kraj"),
                ("53", "Pardubice", "Pardubický kraj"),
                ("32", "Plzeň", "Plzeňský kraj"),
                ("10", "Prague", "Praha"),
                ("31", "South Bohemian", "Jihočeský kraj"),
                ("64", "South Moravian", "Jihomoravský kraj"),
                ("42", "Ústí nad Labem", "Ústecký kraj"),
                ("63", "Vysočina", "Kraj Vysočina"),
                ("72", "Zlín", "Zlínský kraj"),
            ]),
        ]
    )

    private static func czechGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "CZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "CZ-\(place.code)",
                    countryID: "CZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "CZ-\(group)",
                    flagAssetName: "cz_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
