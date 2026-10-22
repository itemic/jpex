import Foundation

extension CountryCatalog {
    // Zambia's ten provinces, Muchinga (2011) included. IDs follow ISO 3166-2:ZM.
    // The provinces have no official flags, so each shows the national flag. See MORE_FLAG_SOURCES_D.md.
    static let zambia = Country(
        id: "ZM",
        name: "Zambia",
        localName: "Zambia",
        divisionLabel: "Provinces",
        groups: [
            zambianGroup("provinces", name: "Provinces", localName: nil, divisions: [
                ("02", "Central", nil),
                ("08", "Copperbelt", nil),
                ("03", "Eastern", nil),
                ("04", "Luapula", nil),
                ("09", "Lusaka", nil),
                ("10", "Muchinga", nil),
                ("06", "North-Western", nil),
                ("05", "Northern", nil),
                ("07", "Southern", nil),
                ("01", "Western", nil),
            ]),
        ]
    )

    private static func zambianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "ZM-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "ZM-\(place.code)",
                    countryID: "ZM",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "ZM-\(group)",
                    flagAssetName: "world_flag_zm",
                    flagNote: "Zambia's provinces have no official flags; the national flag is shown."
                )
            }
        )
    }
}
