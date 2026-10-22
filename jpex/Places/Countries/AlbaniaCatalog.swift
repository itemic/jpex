import Foundation

extension CountryCatalog {
    // Albania's twelve counties (qarqe). IDs follow ISO 3166-2:AL.
    // Counties without a documented flag in use show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and AlbaniaFlagCredits.json.
    static let albania = Country(
        id: "AL",
        name: "Albania",
        localName: "Shqipëria",
        divisionLabel: "Counties",
        groups: [
            albanianGroup("counties", name: "Counties", localName: "Qarqet", divisions: [
                ("01", "Berat", "Qarku i Beratit"),
                ("09", "Dibër", "Qarku i Dibrës"),
                ("02", "Durrës", "Qarku i Durrësit"),
                ("03", "Elbasan", "Qarku i Elbasanit"),
                ("04", "Fier", "Qarku i Fierit"),
                ("05", "Gjirokastër", "Qarku i Gjirokastrës"),
                ("06", "Korçë", "Qarku i Korçës"),
                ("07", "Kukës", "Qarku i Kukësit"),
                ("08", "Lezhë", "Qarku i Lezhës"),
                ("10", "Shkodër", "Qarku i Shkodrës"),
                ("11", "Tirana", "Qarku i Tiranës"),
                ("12", "Vlorë", "Qarku i Vlorës"),
            ]),
        ]
    )

    /// Counties without a documented flag in use show the national flag.
    private static let albanianFlagNotes: [String: String] = [
        "09": "The national flag is shown; Dibër County has no documented flag in use.",
        "04": "The national flag is shown; Fier County has no documented flag in use.",
        "08": "The national flag is shown; Lezhë County has no documented flag in use.",
        "10": "The national flag is shown; Shkodër County has no documented flag in use.",
    ]

    private static func albanianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "AL-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = albanianFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "AL-\(place.code)",
                    countryID: "AL",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "AL-\(group)",
                    flagAssetName: flagNote == nil ? "al_flag_\(place.code.lowercased())" : "world_flag_al",
                    flagNote: flagNote
                )
            }
        )
    }
}
