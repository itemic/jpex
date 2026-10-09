import Foundation

extension CountryCatalog {
    // Poland's 16 voivodeships. IDs follow ISO 3166-2:PL.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and PolandFlagCredits.json.
    static let poland = Country(
        id: "PL",
        name: "Poland",
        localName: "Polska",
        divisionLabel: "Voivodeships",
        groups: [
            polishGroup("voivodeships", name: "Voivodeships", localName: "Województwa", divisions: [
                ("30", "Greater Poland", "Wielkopolskie"),
                ("04", "Kuyavian-Pomeranian", "Kujawsko-Pomorskie"),
                ("12", "Lesser Poland", "Małopolskie"),
                ("10", "Łódź", "Łódzkie"),
                ("02", "Lower Silesian", "Dolnośląskie"),
                ("06", "Lublin", "Lubelskie"),
                ("08", "Lubusz", "Lubuskie"),
                ("14", "Masovian", "Mazowieckie"),
                ("16", "Opole", "Opolskie"),
                ("18", "Podkarpackie", nil),
                ("20", "Podlaskie", nil),
                ("22", "Pomeranian", "Pomorskie"),
                ("24", "Silesian", "Śląskie"),
                ("26", "Świętokrzyskie", nil),
                ("28", "Warmian-Masurian", "Warmińsko-Mazurskie"),
                ("32", "West Pomeranian", "Zachodniopomorskie"),
            ]),
        ]
    )

    private static func polishGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PL-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "PL-\(place.code)",
                    countryID: "PL",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "PL-\(group)",
                    flagAssetName: "pl_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
