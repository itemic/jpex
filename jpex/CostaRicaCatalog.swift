import Foundation

extension CountryCatalog {
    // Costa Rica's seven provinces in official order. IDs follow ISO 3166-2:CR.
    // San José, Alajuela and Cartago have no provincial flag and show the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_C.md and CostaRicaFlagCredits.json.
    static let costaRica = Country(
        id: "CR",
        name: "Costa Rica",
        localName: "Costa Rica",
        divisionLabel: "Provinces",
        groups: [
            costaRicanGroup("provinces", name: "Provinces", localName: "Provincias", divisions: [
                ("SJ", "San José"),
                ("A", "Alajuela"),
                ("C", "Cartago"),
                ("H", "Heredia"),
                ("G", "Guanacaste"),
                ("P", "Puntarenas"),
                ("L", "Limón"),
            ]),
        ]
    )

    /// Provinces shown with the national flag: no provincial flag has been adopted.
    private static let costaRicanFlagNotes: [String: String] = [
        "SJ": "The national flag is shown; San José Province has no official flag.",
        "A": "The national flag is shown; Alajuela Province has no official flag.",
        "C": "The national flag is shown; Cartago Province has no official flag.",
    ]

    private static func costaRicanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "CR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = costaRicanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "CR-\(place.code)",
                    countryID: "CR",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "CR-\(group)",
                    flagAssetName: flagNote == nil ? "cr_flag_\(place.code.lowercased())" : "world_flag_cr",
                    flagNote: flagNote
                )
            }
        )
    }
}
