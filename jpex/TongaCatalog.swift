import Foundation

extension CountryCatalog {
    // Tonga's five island divisions. IDs follow ISO 3166-2:TO. None has an official flag, so each shows the
    // national flag; see MORE_FLAG_SOURCES_D.md.
    static let tonga = Country(
        id: "TO",
        name: "Tonga",
        localName: "Tonga",
        divisionLabel: "Divisions",
        groups: [
            tonganGroup("divisions", name: "Divisions", localName: nil, divisions: [
                ("01", "ʻEua", nil),
                ("02", "Haʻapai", nil),
                ("03", "Niua Islands", "Ongo Niua"),
                ("04", "Tongatapu", nil),
                ("05", "Vavaʻu", nil),
            ]),
        ]
    )

    private static func tonganGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TO-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "TO-\(place.code)",
                    countryID: "TO",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TO-\(group)",
                    flagAssetName: "world_flag_to",
                    flagNote: "Tonga's divisions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
