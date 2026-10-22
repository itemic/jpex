import Foundation

extension CountryCatalog {
    // Paraguay's 17 departments, grouped by natural region, and the capital, Asunción, in official order.
    // IDs follow ISO 3166-2:PY (Boquerón is PY-19, although it is now the 16th department).
    // Departments whose flag could not be verified show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_C.md and ParaguayFlagCredits.json.
    static let paraguay = Country(
        id: "PY",
        name: "Paraguay",
        localName: "Paraguay",
        divisionLabel: "Departments",
        groups: [
            paraguayanGroup("eastern", name: "Eastern Region", localName: "Región Oriental", divisions: [
                ("1", "Concepción"),
                ("2", "San Pedro"),
                ("3", "Cordillera"),
                ("4", "Guairá"),
                ("5", "Caaguazú"),
                ("6", "Caazapá"),
                ("7", "Itapúa"),
                ("8", "Misiones"),
                ("9", "Paraguarí"),
                ("10", "Alto Paraná"),
                ("11", "Central"),
                ("12", "Ñeembucú"),
                ("13", "Amambay"),
                ("14", "Canindeyú"),
            ]),
            paraguayanGroup("western", name: "Western Region", localName: "Región Occidental", divisions: [
                ("15", "Presidente Hayes"),
                ("19", "Boquerón"),
                ("16", "Alto Paraguay"),
            ]),
            paraguayanGroup("capital", name: "Capital", localName: nil, divisions: [
                ("ASU", "Asunción"),
            ]),
        ]
    )

    /// Departments shown with the national flag, and why (no verified flag, or conflicting designs).
    private static let paraguayanFlagNotes: [String: String] = [
        "2": "The national flag is shown; no official flag of San Pedro Department could be verified.",
        "6": "The national flag is shown; no official flag of Caazapá Department could be verified.",
        "10": "The national flag is shown; Alto Paraná Department's current flag could not be verified.",
        "14": "The national flag is shown; no official flag of Canindeyú Department could be verified.",
        "15": "The national flag is shown; Presidente Hayes Department's current flag could not be verified.",
        "16": "The national flag is shown; Alto Paraguay Department's current flag could not be verified.",
    ]

    private static func paraguayanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PY-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = paraguayanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "PY-\(place.code)",
                    countryID: "PY",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "PY-\(group)",
                    flagAssetName: flagNote == nil ? "py_flag_\(place.code.lowercased())" : "world_flag_py",
                    flagNote: flagNote
                )
            }
        )
    }
}
