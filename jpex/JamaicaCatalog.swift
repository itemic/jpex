import Foundation

extension CountryCatalog {
    // Jamaica's 14 parishes, grouped by the three historic counties. IDs follow ISO 3166-2:JM.
    // The parishes have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let jamaica = Country(
        id: "JM",
        name: "Jamaica",
        localName: "Jamaica",
        divisionLabel: "Parishes",
        groups: [
            jamaicanGroup("cornwall", name: "Cornwall", localName: nil, divisions: [
                ("07", "Trelawny"),
                ("08", "Saint James"),
                ("09", "Hanover"),
                ("10", "Westmoreland"),
                ("11", "Saint Elizabeth"),
            ]),
            jamaicanGroup("middlesex", name: "Middlesex", localName: nil, divisions: [
                ("05", "Saint Mary"),
                ("06", "Saint Ann"),
                ("12", "Manchester"),
                ("13", "Clarendon"),
                ("14", "Saint Catherine"),
            ]),
            jamaicanGroup("surrey", name: "Surrey", localName: nil, divisions: [
                ("01", "Kingston"),
                ("02", "Saint Andrew"),
                ("03", "Saint Thomas"),
                ("04", "Portland"),
            ]),
        ]
    )

    private static func jamaicanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "JM-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "JM-\(place.code)",
                    countryID: "JM",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "JM-\(group)",
                    flagAssetName: "world_flag_jm",
                    flagNote: "Jamaica's parishes have no official flags; the national flag is shown."
                )
            }
        )
    }
}
