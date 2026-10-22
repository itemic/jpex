import Foundation

extension CountryCatalog {
    // Guyana's ten regions. IDs follow ISO 3166-2:GY. None has an official flag, so each shows the
    // national flag; see MORE_FLAG_SOURCES_D.md.
    static let guyana = Country(
        id: "GY",
        name: "Guyana",
        localName: "Guyana",
        divisionLabel: "Regions",
        groups: [
            guyaneseGroup("regions", name: "Regions", localName: nil, divisions: [
                ("BA", "Barima-Waini", nil),
                ("CU", "Cuyuni-Mazaruni", nil),
                ("DE", "Demerara-Mahaica", nil),
                ("EB", "East Berbice-Corentyne", nil),
                ("ES", "Essequibo Islands-West Demerara", nil),
                ("MA", "Mahaica-Berbice", nil),
                ("PM", "Pomeroon-Supenaam", nil),
                ("PT", "Potaro-Siparuni", nil),
                ("UD", "Upper Demerara-Berbice", nil),
                ("UT", "Upper Takutu-Upper Essequibo", nil),
            ]),
        ]
    )

    private static func guyaneseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "GY-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "GY-\(place.code)",
                    countryID: "GY",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "GY-\(group)",
                    flagAssetName: "world_flag_gy",
                    flagNote: "Guyana's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
