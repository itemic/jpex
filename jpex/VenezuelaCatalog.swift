import Foundation

extension CountryCatalog {
    // Venezuela's 23 states, the Capital District and the Federal Dependencies. IDs follow ISO 3166-2:VE.
    // Guayana Esequiba is not an ISO 3166-2 subdivision of Venezuela and is not listed. The Capital District shows the
    // flag of Caracas (2022), which it uses; the Federal Dependencies have no official flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_C.md and VenezuelaFlagCredits.json.
    static let venezuela = Country(
        id: "VE",
        name: "Venezuela",
        localName: "Venezuela",
        divisionLabel: "States",
        groups: [
            venezuelanGroup("states", name: "States", localName: "Estados", divisions: [
                ("Z", "Amazonas", nil),
                ("B", "Anzoátegui", nil),
                ("C", "Apure", nil),
                ("D", "Aragua", nil),
                ("E", "Barinas", nil),
                ("F", "Bolívar", nil),
                ("G", "Carabobo", nil),
                ("H", "Cojedes", nil),
                ("Y", "Delta Amacuro", nil),
                ("I", "Falcón", nil),
                ("J", "Guárico", nil),
                ("X", "La Guaira", nil),
                ("K", "Lara", nil),
                ("L", "Mérida", nil),
                ("M", "Miranda", nil),
                ("N", "Monagas", nil),
                ("O", "Nueva Esparta", nil),
                ("P", "Portuguesa", nil),
                ("R", "Sucre", nil),
                ("S", "Táchira", nil),
                ("T", "Trujillo", nil),
                ("U", "Yaracuy", nil),
                ("V", "Zulia", nil),
            ]),
            venezuelanGroup("capital-district", name: "Capital District", localName: "Distrito Capital", divisions: [
                ("A", "Capital District", "Distrito Capital"),
            ]),
            venezuelanGroup("federal-dependencies", name: "Federal Dependencies", localName: "Dependencias Federales", divisions: [
                ("W", "Federal Dependencies", "Dependencias Federales"),
            ]),
        ]
    )

    /// Places shown with the national flag, and why.
    private static let venezuelanFlagNotes: [String: String] = [
        "W": "The national flag is shown; the Federal Dependencies have no official flag.",
    ]

    private static func venezuelanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "VE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = venezuelanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "VE-\(place.code)",
                    countryID: "VE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "VE-\(group)",
                    flagAssetName: flagNote == nil ? "ve_flag_\(place.code.lowercased())" : "world_flag_ve",
                    flagNote: flagNote
                )
            }
        )
    }
}
