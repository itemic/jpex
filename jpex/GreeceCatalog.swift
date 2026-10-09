import Foundation

extension CountryCatalog {
    // Greece's 13 regions and the autonomous monastic state of Mount Athos. IDs follow ISO 3166-2:GR.
    // None has an official flag, so every entry shows the national flag. See MORE_FLAG_SOURCES_2.md.
    static let greece = Country(
        id: "GR",
        name: "Greece",
        localName: "Ελλάδα",
        divisionLabel: "Regions",
        groups: [
            greekGroup("regions", name: "Regions", localName: "Περιφέρειες", divisions: [
                ("I", "Attica", "Αττική"),
                ("H", "Central Greece", "Στερεά Ελλάδα"),
                ("B", "Central Macedonia", "Κεντρική Μακεδονία"),
                ("M", "Crete", "Κρήτη"),
                ("A", "Eastern Macedonia and Thrace", "Ανατολική Μακεδονία και Θράκη"),
                ("D", "Epirus", "Ήπειρος"),
                ("F", "Ionian Islands", "Ιόνια Νησιά"),
                ("K", "North Aegean", "Βόρειο Αιγαίο"),
                ("J", "Peloponnese", "Πελοπόννησος"),
                ("L", "South Aegean", "Νότιο Αιγαίο"),
                ("E", "Thessaly", "Θεσσαλία"),
                ("G", "Western Greece", "Δυτική Ελλάδα"),
                ("C", "Western Macedonia", "Δυτική Μακεδονία"),
            ]),
            greekGroup("athos", name: "Mount Athos", localName: "Άγιον Όρος", divisions: [
                ("69", "Mount Athos", "Άγιον Όρος"),
            ]),
        ]
    )

    private static func greekGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "GR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "GR-\(place.code)",
                    countryID: "GR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "GR-\(group)",
                    flagAssetName: "world_flag_gr",
                    flagNote: group == "athos"
                        ? "The national flag is shown; Mount Athos has no official flag."
                        : "Greece's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
