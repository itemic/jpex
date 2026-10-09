import Foundation

extension CountryCatalog {
    // El Salvador's 14 departments. IDs follow ISO 3166-2:SV; the 2024 municipal reform did not change the departments.
    // Morazán and Usulután, whose current flags have no accurate artwork, show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_C.md and ElSalvadorFlagCredits.json.
    static let elSalvador = Country(
        id: "SV",
        name: "El Salvador",
        localName: "El Salvador",
        divisionLabel: "Departments",
        groups: [
            salvadoranGroup("departments", name: "Departments", localName: "Departamentos", divisions: [
                ("AH", "Ahuachapán"),
                ("CA", "Cabañas"),
                ("CH", "Chalatenango"),
                ("CU", "Cuscatlán"),
                ("LI", "La Libertad"),
                ("PA", "La Paz"),
                ("UN", "La Unión"),
                ("MO", "Morazán"),
                ("SM", "San Miguel"),
                ("SS", "San Salvador"),
                ("SV", "San Vicente"),
                ("SA", "Santa Ana"),
                ("SO", "Sonsonate"),
                ("US", "Usulután"),
            ]),
        ]
    )

    /// Departments shown with the national flag: no accurate artwork of the current flag.
    private static let salvadoranFlagNotes: [String: String] = [
        "MO": "The national flag is shown; no accurate artwork of Morazán Department's current flag is available.",
        "US": "The national flag is shown; no accurate artwork of Usulután Department's flag is available.",
    ]

    private static func salvadoranGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "SV-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = salvadoranFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "SV-\(place.code)",
                    countryID: "SV",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "SV-\(group)",
                    flagAssetName: flagNote == nil ? "sv_flag_\(place.code.lowercased())" : "world_flag_sv",
                    flagNote: flagNote
                )
            }
        )
    }
}
