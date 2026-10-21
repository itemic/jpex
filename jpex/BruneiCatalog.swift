import Foundation

extension CountryCatalog {
    // Brunei's four districts. IDs follow ISO 3166-2:BN. Local names are Malay.
    // The districts have no flags, so each shows the national flag. See MORE_FLAG_SOURCES_D.md.
    static let brunei = Country(
        id: "BN",
        name: "Brunei Darussalam",
        localName: "Brunei Darussalam",
        divisionLabel: "Districts",
        groups: [
            bruneianGroup("districts", name: "Districts", localName: "Daerah", divisions: [
                ("BE", "Belait", nil),
                ("BM", "Brunei–Muara", "Brunei dan Muara"),
                ("TE", "Temburong", nil),
                ("TU", "Tutong", nil),
            ]),
        ]
    )

    private static func bruneianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BN-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BN-\(place.code)",
                    countryID: "BN",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BN-\(group)",
                    flagAssetName: "world_flag_bn",
                    flagNote: "Brunei's districts have no official flags; the national flag is shown."
                )
            }
        )
    }
}
