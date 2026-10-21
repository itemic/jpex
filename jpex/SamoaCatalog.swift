import Foundation

extension CountryCatalog {
    // Samoa's eleven districts. IDs follow ISO 3166-2:WS. None has an official flag, so each shows the
    // national flag; see MORE_FLAG_SOURCES_D.md.
    static let samoa = Country(
        id: "WS",
        name: "Samoa",
        localName: "Sāmoa",
        divisionLabel: "Districts",
        groups: [
            samoanGroup("districts", name: "Districts", localName: "Itūmālō", divisions: [
                ("AA", "Aʻana", nil),
                ("AL", "Aiga-i-le-Tai", nil),
                ("AT", "Atua", nil),
                ("FA", "Faʻasaleleaga", nil),
                ("GE", "Gagaʻemauga", nil),
                ("GI", "Gagaʻifomauga", nil),
                ("PA", "Palauli", nil),
                ("SA", "Satupaʻitea", nil),
                ("TU", "Tuamasaga", nil),
                ("VF", "Vaʻa-o-Fonoti", nil),
                ("VS", "Vaisigano", nil),
            ]),
        ]
    )

    private static func samoanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "WS-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "WS-\(place.code)",
                    countryID: "WS",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "WS-\(group)",
                    flagAssetName: "world_flag_ws",
                    flagNote: "Samoa's districts have no official flags; the national flag is shown."
                )
            }
        )
    }
}
