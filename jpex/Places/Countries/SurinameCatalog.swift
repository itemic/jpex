import Foundation

extension CountryCatalog {
    // Suriname's ten districts. IDs follow ISO 3166-2:SR. None has an official flag, so each shows the
    // national flag; see MORE_FLAG_SOURCES_D.md.
    static let suriname = Country(
        id: "SR",
        name: "Suriname",
        localName: "Suriname",
        divisionLabel: "Districts",
        groups: [
            surinameseGroup("districts", name: "Districts", localName: "Distrikten", divisions: [
                ("BR", "Brokopondo", nil),
                ("CM", "Commewijne", nil),
                ("CR", "Coronie", nil),
                ("MA", "Marowijne", nil),
                ("NI", "Nickerie", nil),
                ("PR", "Para", nil),
                ("PM", "Paramaribo", nil),
                ("SA", "Saramacca", nil),
                ("SI", "Sipaliwini", nil),
                ("WA", "Wanica", nil),
            ]),
        ]
    )

    private static func surinameseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "SR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "SR-\(place.code)",
                    countryID: "SR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "SR-\(group)",
                    flagAssetName: "world_flag_sr",
                    flagNote: "Suriname's districts have no official flags; the national flag is shown."
                )
            }
        )
    }
}
