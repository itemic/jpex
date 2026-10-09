import Foundation

extension CountryCatalog {
    // Fiji's four divisions and the dependency of Rotuma. IDs follow ISO 3166-2:FJ; the 14 provinces are not listed.
    // None has an official flag, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let fiji = Country(
        id: "FJ",
        name: "Fiji",
        localName: "Viti",
        divisionLabel: "Divisions",
        groups: [
            fijianGroup("divisions", name: "Divisions", localName: nil, divisions: [
                ("C", "Central Division"),
                ("E", "Eastern Division"),
                ("N", "Northern Division"),
                ("W", "Western Division"),
                ("R", "Rotuma"),
            ]),
        ]
    )

    private static func fijianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "FJ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "FJ-\(place.code)",
                    countryID: "FJ",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "FJ-\(group)",
                    flagAssetName: "world_flag_fj",
                    flagNote: "Fiji's divisions and Rotuma have no official flags; the national flag is shown."
                )
            }
        )
    }
}
