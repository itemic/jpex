import Foundation

extension CountryCatalog {
    // Tanzania's 31 regions: 26 on the mainland and five in Zanzibar. IDs follow ISO 3166-2:TZ.
    // The regions have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let tanzania = Country(
        id: "TZ",
        name: "Tanzania",
        localName: "Tanzania",
        divisionLabel: "Regions",
        groups: [
            tanzanianGroup("mainland", name: "Mainland", localName: "Tanzania Bara", divisions: [
                ("01", "Arusha", nil),
                ("02", "Dar es Salaam", nil),
                ("03", "Dodoma", nil),
                ("27", "Geita", nil),
                ("04", "Iringa", nil),
                ("05", "Kagera", nil),
                ("28", "Katavi", nil),
                ("08", "Kigoma", nil),
                ("09", "Kilimanjaro", nil),
                ("12", "Lindi", nil),
                ("26", "Manyara", nil),
                ("13", "Mara", nil),
                ("14", "Mbeya", nil),
                ("16", "Morogoro", nil),
                ("17", "Mtwara", nil),
                ("18", "Mwanza", nil),
                ("29", "Njombe", nil),
                ("19", "Pwani", nil),
                ("20", "Rukwa", nil),
                ("21", "Ruvuma", nil),
                ("22", "Shinyanga", nil),
                ("30", "Simiyu", nil),
                ("23", "Singida", nil),
                ("31", "Songwe", nil),
                ("24", "Tabora", nil),
                ("25", "Tanga", nil),
            ]),
            tanzanianGroup("zanzibar", name: "Zanzibar", localName: nil, divisions: [
                ("06", "Pemba North", "Kaskazini Pemba"),
                ("10", "Pemba South", "Kusini Pemba"),
                ("07", "Unguja North", "Kaskazini Unguja"),
                ("11", "Unguja South", "Kusini Unguja"),
                ("15", "Urban West", "Mjini Magharibi"),
            ]),
        ]
    )

    private static func tanzanianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "TZ-\(place.code)",
                    countryID: "TZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TZ-\(group)",
                    flagAssetName: "world_flag_tz",
                    flagNote: "Tanzania's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
