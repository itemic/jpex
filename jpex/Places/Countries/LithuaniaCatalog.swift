import Foundation

extension CountryCatalog {
    // Lithuania's ten counties (apskritys); municipalities are not listed. IDs follow ISO 3166-2:LT.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and LithuaniaFlagCredits.json.
    static let lithuania = Country(
        id: "LT",
        name: "Lithuania",
        localName: "Lietuva",
        divisionLabel: "Counties",
        groups: [
            lithuanianGroup("counties", name: "Counties", localName: "Apskritys", divisions: [
                ("AL", "Alytus", "Alytaus apskritis"),
                ("KU", "Kaunas", "Kauno apskritis"),
                ("KL", "Klaipėda", "Klaipėdos apskritis"),
                ("MR", "Marijampolė", "Marijampolės apskritis"),
                ("PN", "Panevėžys", "Panevėžio apskritis"),
                ("SA", "Šiauliai", "Šiaulių apskritis"),
                ("TA", "Tauragė", "Tauragės apskritis"),
                ("TE", "Telšiai", "Telšių apskritis"),
                ("UT", "Utena", "Utenos apskritis"),
                ("VL", "Vilnius", "Vilniaus apskritis"),
            ]),
        ]
    )

    private static func lithuanianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "LT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "LT-\(place.code)",
                    countryID: "LT",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "LT-\(group)",
                    flagAssetName: "lt_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
