import Foundation

extension CountryCatalog {
    // Ghana's 16 regions (since the 2018 reorganisation). IDs follow ISO 3166-2:GH as updated in 2019.
    // The regions have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let ghana = Country(
        id: "GH",
        name: "Ghana",
        localName: "Ghana",
        divisionLabel: "Regions",
        groups: [
            ghanaianGroup("regions", name: "Regions", localName: nil, divisions: [
                ("AF", "Ahafo"),
                ("AH", "Ashanti"),
                ("BO", "Bono"),
                ("BE", "Bono East"),
                ("CP", "Central"),
                ("EP", "Eastern"),
                ("AA", "Greater Accra"),
                ("NE", "North East"),
                ("NP", "Northern"),
                ("OT", "Oti"),
                ("SV", "Savannah"),
                ("UE", "Upper East"),
                ("UW", "Upper West"),
                ("TV", "Volta"),
                ("WP", "Western"),
                ("WN", "Western North"),
            ]),
        ]
    )

    private static func ghanaianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "GH-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "GH-\(place.code)",
                    countryID: "GH",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "GH-\(group)",
                    flagAssetName: "world_flag_gh",
                    flagNote: "Ghana's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
