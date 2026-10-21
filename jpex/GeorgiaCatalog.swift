import Foundation

extension CountryCatalog {
    // Georgia's nine regions, the autonomous republics of Abkhazia and Adjara, and the capital, Tbilisi.
    // IDs follow ISO 3166-2:GE. Abkhazia is listed de jure; South Ossetia isn't a unit of its own. Local names
    // are Georgian. Flag sources and licences: MORE_FLAG_SOURCES_D.md and GeorgiaFlagCredits.json.
    static let georgia = Country(
        id: "GE",
        name: "Georgia",
        localName: "საქართველო",
        divisionLabel: "Regions",
        groups: [
            georgianGroup("regions", name: "Regions", localName: "მხარეები", divisions: [
                ("GU", "Guria", "გურია"),
                ("IM", "Imereti", "იმერეთი"),
                ("KA", "Kakheti", "კახეთი"),
                ("KK", "Kvemo Kartli", "ქვემო ქართლი"),
                ("MM", "Mtskheta-Mtianeti", "მცხეთა-მთიანეთი"),
                ("RL", "Racha-Lechkhumi and Kvemo Svaneti", "რაჭა-ლეჩხუმი და ქვემო სვანეთი"),
                ("SZ", "Samegrelo-Zemo Svaneti", "სამეგრელო-ზემო სვანეთი"),
                ("SJ", "Samtskhe–Javakheti", "სამცხე-ჯავახეთი"),
                ("SK", "Shida Kartli", "შიდა ქართლი"),
            ]),
            georgianGroup("autonomous-republics", name: "Autonomous republics", localName: "ავტონომიური რესპუბლიკები", divisions: [
                ("AB", "Abkhazia", "აფხაზეთი"),
                ("AJ", "Adjara", "აჭარა"),
            ]),
            georgianGroup("capital", name: "Capital", localName: "დედაქალაქი", divisions: [
                ("TB", "Tbilisi", "თბილისი"),
            ]),
        ]
    )

    /// Places without a flag of their own here show the national flag.
    private static let georgianFlagNotes: [String: String] = [
        "GU": "The national flag is shown; Guria has no official flag.",
        "IM": "The national flag is shown; Imereti has no official flag.",
        "KA": "The national flag is shown; Kakheti has no official flag.",
        "KK": "The national flag is shown; Kvemo Kartli has no official flag.",
        "MM": "The national flag is shown; Mtskheta-Mtianeti has no official flag.",
        "RL": "The national flag is shown; Racha-Lechkhumi and Kvemo Svaneti has no official flag.",
        "SZ": "The national flag is shown; Samegrelo-Zemo Svaneti has no official flag.",
        "SJ": "The national flag is shown; Samtskhe–Javakheti has no official flag.",
        "SK": "The national flag is shown; Shida Kartli has no official flag.",
        "AB": "The national flag is shown; the Autonomous Republic of Abkhazia has no official flag.",
    ]

    private static func georgianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "GE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = georgianFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "GE-\(place.code)",
                    countryID: "GE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "GE-\(group)",
                    flagAssetName: flagNote == nil ? "ge_flag_\(place.code.lowercased())" : "world_flag_ge",
                    flagNote: flagNote
                )
            }
        )
    }
}
