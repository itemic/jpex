import Foundation

extension CountryCatalog {
    // Kyrgyzstan's seven regions (oblustar) and the cities of Bishkek and Osh. IDs follow ISO 3166-2:KG.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and KyrgyzstanFlagCredits.json.
    static let kyrgyzstan = Country(
        id: "KG",
        name: "Kyrgyzstan",
        localName: "Кыргызстан",
        divisionLabel: "Regions",
        groups: [
            kyrgyzGroup("regions", name: "Regions", localName: "Облустар", divisions: [
                ("B", "Batken", "Баткен облусу"),
                ("C", "Chüy", "Чүй облусу"),
                ("Y", "Issyk-Kul", "Ысык-Көл облусу"),
                ("J", "Jalal-Abad", "Жалал-Абад облусу"),
                ("N", "Naryn", "Нарын облусу"),
                ("O", "Osh Region", "Ош облусу"),
                ("T", "Talas", "Талас облусу"),
            ]),
            kyrgyzGroup("cities", name: "Cities", localName: "Шаарлар", divisions: [
                ("GB", "Bishkek", "Бишкек"),
                ("GO", "Osh", "Ош"),
            ]),
        ]
    )

    /// Regions without an official flag show the national flag.
    private static let kyrgyzFlagNotes: [String: String] = [
        "O": "The national flag is shown; Osh Region has no official flag.",
    ]

    private static func kyrgyzGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "KG-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = kyrgyzFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "KG-\(place.code)",
                    countryID: "KG",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "KG-\(group)",
                    flagAssetName: flagNote == nil ? "kg_flag_\(place.code.lowercased())" : "world_flag_kg",
                    flagNote: flagNote
                )
            }
        )
    }
}
