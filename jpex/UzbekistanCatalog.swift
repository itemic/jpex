import Foundation

extension CountryCatalog {
    // Uzbekistan's twelve regions (viloyatlar), the Republic of Karakalpakstan and the capital, Tashkent.
    // IDs follow ISO 3166-2:UZ. Places without an official flag show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and UzbekistanFlagCredits.json.
    static let uzbekistan = Country(
        id: "UZ",
        name: "Uzbekistan",
        localName: "Oʻzbekiston",
        divisionLabel: "Regions",
        groups: [
            uzbekGroup("regions", name: "Regions", localName: "Viloyatlar", divisions: [
                ("AN", "Andijan", "Andijon viloyati"),
                ("BU", "Bukhara", "Buxoro viloyati"),
                ("FA", "Fergana", "Fargʻona viloyati"),
                ("JI", "Jizzakh", "Jizzax viloyati"),
                ("NG", "Namangan", "Namangan viloyati"),
                ("NW", "Navoiy", "Navoiy viloyati"),
                ("QA", "Qashqadaryo", "Qashqadaryo viloyati"),
                ("SA", "Samarqand", "Samarqand viloyati"),
                ("SI", "Sirdaryo", "Sirdaryo viloyati"),
                ("SU", "Surxondaryo", "Surxondaryo viloyati"),
                ("TO", "Tashkent Region", "Toshkent viloyati"),
                ("XO", "Xorazm", "Xorazm viloyati"),
            ]),
            uzbekGroup("republic", name: "Republic", localName: "Respublika", divisions: [
                ("QR", "Karakalpakstan", "Qoraqalpogʻiston Respublikasi"),
            ]),
            uzbekGroup("capital", name: "Capital", localName: "Poytaxt", divisions: [
                ("TK", "Tashkent", "Toshkent"),
            ]),
        ]
    )

    /// Places with their own flag artwork. The regions have no official flags.
    private static let uzbekPlacesWithFlags: Set<String> = ["QR"]

    private static let uzbekSpecialFlagNotes: [String: String] = [
        "TK": "The national flag is shown; Tashkent has no official flag.",
    ]

    private static func uzbekFlagNote(_ code: String, name: String) -> String? {
        if uzbekPlacesWithFlags.contains(code) { return nil }
        if let note = uzbekSpecialFlagNotes[code] { return note }
        let place = name.hasSuffix(" Region") ? name : "\(name) Region"
        return "The national flag is shown; \(place) has no official flag."
    }

    private static func uzbekGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "UZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = uzbekFlagNote(place.code, name: place.name)
                return AdministrativeDivision(
                    id: "UZ-\(place.code)",
                    countryID: "UZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "UZ-\(group)",
                    flagAssetName: flagNote == nil ? "uz_flag_\(place.code.lowercased())" : "world_flag_uz",
                    flagNote: flagNote
                )
            }
        )
    }
}
