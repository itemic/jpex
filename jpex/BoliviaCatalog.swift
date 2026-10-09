import Foundation

extension CountryCatalog {
    // Bolivia's nine departments. IDs follow ISO 3166-2:BO.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and BoliviaFlagCredits.json.
    static let bolivia = Country(
        id: "BO",
        name: "Bolivia",
        localName: "Bolivia",
        divisionLabel: "Departments",
        groups: [
            bolivianGroup("departments", name: "Departments", localName: "Departamentos", divisions: [
                ("B", "Beni"),
                ("H", "Chuquisaca"),
                ("C", "Cochabamba"),
                ("L", "La Paz"),
                ("O", "Oruro"),
                ("N", "Pando"),
                ("P", "Potosí"),
                ("S", "Santa Cruz"),
                ("T", "Tarija"),
            ]),
        ]
    )

    private static func bolivianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BO-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BO-\(place.code)",
                    countryID: "BO",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "BO-\(group)",
                    flagAssetName: "bo_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
