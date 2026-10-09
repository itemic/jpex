import Foundation

extension CountryCatalog {
    // Uruguay's 19 departments. IDs follow ISO 3166-2:UY.
    // Montevideo and Tacuarembó have never adopted departmental flags and show the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and UruguayFlagCredits.json.
    static let uruguay = Country(
        id: "UY",
        name: "Uruguay",
        localName: "Uruguay",
        divisionLabel: "Departments",
        groups: [
            uruguayanGroup("departments", name: "Departments", localName: "Departamentos", divisions: [
                ("AR", "Artigas"),
                ("CA", "Canelones"),
                ("CL", "Cerro Largo"),
                ("CO", "Colonia"),
                ("DU", "Durazno"),
                ("FS", "Flores"),
                ("FD", "Florida"),
                ("LA", "Lavalleja"),
                ("MA", "Maldonado"),
                ("MO", "Montevideo"),
                ("PA", "Paysandú"),
                ("RN", "Río Negro"),
                ("RV", "Rivera"),
                ("RO", "Rocha"),
                ("SA", "Salto"),
                ("SJ", "San José"),
                ("SO", "Soriano"),
                ("TA", "Tacuarembó"),
                ("TT", "Treinta y Tres"),
            ]),
        ]
    )

    /// Departments that have never adopted a flag; the national flag is shown.
    private static let uruguayanFlagNotes: [String: String] = [
        "MO": "The national flag is shown; Montevideo Department has no official flag.",
        "TA": "The national flag is shown; Tacuarembó Department has no official flag.",
    ]

    private static func uruguayanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "UY-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = uruguayanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "UY-\(place.code)",
                    countryID: "UY",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "UY-\(group)",
                    flagAssetName: flagNote == nil ? "uy_flag_\(place.code.lowercased())" : "world_flag_uy",
                    flagNote: flagNote
                )
            }
        )
    }
}
