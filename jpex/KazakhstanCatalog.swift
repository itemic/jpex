import Foundation

extension CountryCatalog {
    // Kazakhstan's 17 regions (including Abai, Jetisu and Ulytau, created in 2022) and the cities of Astana, Almaty
    // and Shymkent. IDs follow ISO 3166-2:KZ as revised in 2022. Places without an official flag show the national
    // flag with a note. Flag sources and licences: MORE_FLAG_SOURCES_A.md and KazakhstanFlagCredits.json.
    static let kazakhstan = Country(
        id: "KZ",
        name: "Kazakhstan",
        localName: "Қазақстан",
        divisionLabel: "Regions",
        groups: [
            kazakhGroup("regions", name: "Regions", localName: "Облыстар", divisions: [
                ("10", "Abai", "Абай облысы"),
                ("11", "Akmola", "Ақмола облысы"),
                ("15", "Aktobe", "Ақтөбе облысы"),
                ("19", "Almaty Region", "Алматы облысы"),
                ("23", "Atyrau", "Атырау облысы"),
                ("63", "East Kazakhstan", "Шығыс Қазақстан облысы"),
                ("31", "Jambyl", "Жамбыл облысы"),
                ("33", "Jetisu", "Жетісу облысы"),
                ("35", "Karaganda", "Қарағанды облысы"),
                ("39", "Kostanay", "Қостанай облысы"),
                ("43", "Kyzylorda", "Қызылорда облысы"),
                ("47", "Mangystau", "Маңғыстау облысы"),
                ("59", "North Kazakhstan", "Солтүстік Қазақстан облысы"),
                ("55", "Pavlodar", "Павлодар облысы"),
                ("61", "Turkistan", "Түркістан облысы"),
                ("62", "Ulytau", "Ұлытау облысы"),
                ("27", "West Kazakhstan", "Батыс Қазақстан облысы"),
            ]),
            kazakhGroup("cities", name: "Cities", localName: "Қалалар", divisions: [
                ("71", "Astana", "Астана"),
                ("75", "Almaty", "Алматы"),
                ("79", "Shymkent", "Шымкент"),
            ]),
        ]
    )

    /// Places with their own flag artwork. The regions have no official flags (their approved "regional symbols" are emblems).
    private static let kazakhPlacesWithFlags: Set<String> = ["71", "75"]

    private static let kazakhSpecialFlagNotes: [String: String] = [
        "79": "The national flag is shown; Shymkent has no official flag.",
    ]

    private static func kazakhFlagNote(_ code: String, name: String) -> String? {
        if kazakhPlacesWithFlags.contains(code) { return nil }
        if let note = kazakhSpecialFlagNotes[code] { return note }
        let place = name.hasSuffix(" Region") ? name : "\(name) Region"
        return "The national flag is shown; \(place) has no official flag."
    }

    private static func kazakhGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "KZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = kazakhFlagNote(place.code, name: place.name)
                return AdministrativeDivision(
                    id: "KZ-\(place.code)",
                    countryID: "KZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "KZ-\(group)",
                    flagAssetName: flagNote == nil ? "kz_flag_\(place.code.lowercased())" : "world_flag_kz",
                    flagNote: flagNote
                )
            }
        )
    }
}
