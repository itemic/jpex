import Foundation

extension CountryCatalog {
    // Cuba's 15 provinces from west to east, in the order of the national statistics office, then the special
    // municipality of Isla de la Juventud. IDs follow ISO 3166-2:CU.
    // The provinces have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_3.md.
    static let cuba = Country(
        id: "CU",
        name: "Cuba",
        localName: "Cuba",
        divisionLabel: "Provinces",
        groups: [
            cubanGroup("provinces", name: "Provinces", localName: "Provincias", divisions: [
                ("01", "Pinar del Río", nil),
                ("15", "Artemisa", nil),
                ("03", "Havana", "La Habana"),
                ("16", "Mayabeque", nil),
                ("04", "Matanzas", nil),
                ("05", "Villa Clara", nil),
                ("06", "Cienfuegos", nil),
                ("07", "Sancti Spíritus", nil),
                ("08", "Ciego de Ávila", nil),
                ("09", "Camagüey", nil),
                ("10", "Las Tunas", nil),
                ("11", "Holguín", nil),
                ("12", "Granma", nil),
                ("13", "Santiago de Cuba", nil),
                ("14", "Guantánamo", nil),
                ("99", "Isla de la Juventud", nil),
            ]),
        ]
    )

    private static func cubanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "CU-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "CU-\(place.code)",
                    countryID: "CU",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "CU-\(group)",
                    flagAssetName: "world_flag_cu",
                    flagNote: "Cuba's provinces have no official flags; the national flag is shown."
                )
            }
        )
    }
}
