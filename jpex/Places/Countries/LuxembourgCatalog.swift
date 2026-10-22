import Foundation

extension CountryCatalog {
    // Luxembourg's twelve cantons. IDs follow ISO 3166-2:LU. Local names are Luxembourgish.
    // The cantons have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_A.md.
    static let luxembourg = Country(
        id: "LU",
        name: "Luxembourg",
        localName: "Lëtzebuerg",
        divisionLabel: "Cantons",
        groups: [
            luxembourgishGroup("cantons", name: "Cantons", localName: "Kantonen", divisions: [
                ("CA", "Capellen", nil),
                ("CL", "Clervaux", "Klierf"),
                ("DI", "Diekirch", "Dikrech"),
                ("EC", "Echternach", "Iechternach"),
                ("ES", "Esch-sur-Alzette", "Esch-Uelzecht"),
                ("GR", "Grevenmacher", "Gréiwemaacher"),
                ("LU", "Luxembourg", "Lëtzebuerg"),
                ("ME", "Mersch", "Miersch"),
                ("RD", "Redange", "Réiden"),
                ("RM", "Remich", "Réimech"),
                ("VD", "Vianden", "Veianen"),
                ("WI", "Wiltz", "Wolz"),
            ]),
        ]
    )

    private static func luxembourgishGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "LU-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "LU-\(place.code)",
                    countryID: "LU",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "LU-\(group)",
                    flagAssetName: "world_flag_lu",
                    flagNote: "Luxembourg's cantons have no official flags; the national flag is shown."
                )
            }
        )
    }
}
