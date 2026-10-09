import Foundation

extension CountryCatalog {
    // South Africa's nine provinces. IDs follow ISO 3166-2:ZA.
    // Provinces have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_2.md.
    static let southAfrica = Country(
        id: "ZA",
        name: "South Africa",
        localName: "South Africa",
        divisionLabel: "Provinces",
        groups: [
            southAfricanGroup("provinces", name: "Provinces", localName: nil, divisions: [
                ("EC", "Eastern Cape"),
                ("FS", "Free State"),
                ("GP", "Gauteng"),
                ("KZN", "KwaZulu-Natal"),
                ("LP", "Limpopo"),
                ("MP", "Mpumalanga"),
                ("NW", "North West"),
                ("NC", "Northern Cape"),
                ("WC", "Western Cape"),
            ]),
        ]
    )

    private static func southAfricanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "ZA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "ZA-\(place.code)",
                    countryID: "ZA",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "ZA-\(group)",
                    flagAssetName: "world_flag_za",
                    flagNote: "South Africa's provinces have no official flags; the national flag is shown."
                )
            }
        )
    }
}
