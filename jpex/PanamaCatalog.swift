import Foundation

extension CountryCatalog {
    // Panama's ten provinces in official order and the four indigenous comarcas with province rank (ISO 3166-2:PA).
    // The comarcas Guna de Madungandí and Guna de Wargandí are part of provinces and are not listed.
    // Flag sources and licences: MORE_FLAG_SOURCES_C.md and PanamaFlagCredits.json.
    static let panama = Country(
        id: "PA",
        name: "Panama",
        localName: "Panamá",
        divisionLabel: "Provinces & comarcas",
        groups: [
            panamanianGroup("provinces", name: "Provinces", localName: "Provincias", divisions: [
                ("1", "Bocas del Toro"),
                ("2", "Coclé"),
                ("3", "Colón"),
                ("4", "Chiriquí"),
                ("5", "Darién"),
                ("6", "Herrera"),
                ("7", "Los Santos"),
                ("8", "Panamá"),
                ("9", "Veraguas"),
                ("10", "Panamá Oeste"),
            ]),
            panamanianGroup("comarcas", name: "Indigenous comarcas", localName: "Comarcas indígenas", divisions: [
                ("EM", "Emberá-Wounaan"),
                ("KY", "Guna Yala"),
                ("NT", "Naso Tjër Di"),
                ("NB", "Ngäbe-Buglé"),
            ]),
        ]
    )

    /// Provinces and comarcas shown with the national flag, and why.
    private static let panamanianFlagNotes: [String: String] = [
        "1": "The national flag is shown; Bocas del Toro Province has no official flag.",
        "5": "The national flag is shown; Darién Province has no official flag.",
        "7": "The national flag is shown; Los Santos Province's flag is disputed and no accurate artwork of it is available.",
        "8": "The national flag is shown; Panamá Province has no official flag.",
        "EM": "The national flag is shown; the Emberá-Wounaan Comarca has no official flag.",
        "NB": "The national flag is shown; artwork for the Ngäbe-Buglé Comarca's current flag (2013) is not available.",
    ]

    private static func panamanianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = panamanianFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "PA-\(place.code)",
                    countryID: "PA",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "PA-\(group)",
                    flagAssetName: flagNote == nil ? "pa_flag_\(place.code.lowercased())" : "world_flag_pa",
                    flagNote: flagNote
                )
            }
        )
    }
}
