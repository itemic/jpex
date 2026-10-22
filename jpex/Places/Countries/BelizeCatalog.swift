import Foundation

extension CountryCatalog {
    // Belize's six districts. IDs follow ISO 3166-2:BZ. None has an official flag, so each shows the
    // national flag; see MORE_FLAG_SOURCES_D.md.
    static let belize = Country(
        id: "BZ",
        name: "Belize",
        localName: "Belize",
        divisionLabel: "Districts",
        groups: [
            belizeanGroup("districts", name: "Districts", localName: nil, divisions: [
                ("BZ", "Belize District", nil),
                ("CY", "Cayo", nil),
                ("CZL", "Corozal", nil),
                ("OW", "Orange Walk", nil),
                ("SC", "Stann Creek", nil),
                ("TOL", "Toledo", nil),
            ]),
        ]
    )

    private static func belizeanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BZ-\(place.code)",
                    countryID: "BZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BZ-\(group)",
                    flagAssetName: "world_flag_bz",
                    flagNote: "Belize's districts have no official flags; the national flag is shown."
                )
            }
        )
    }
}
