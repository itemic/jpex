import Foundation

extension CountryCatalog {
    // Senegal's 14 regions. IDs follow ISO 3166-2:SN.
    // The regions have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let senegal = Country(
        id: "SN",
        name: "Senegal",
        localName: "Sénégal",
        divisionLabel: "Regions",
        groups: [
            senegaleseGroup("regions", name: "Regions", localName: "Régions", divisions: [
                ("DK", "Dakar"),
                ("DB", "Diourbel"),
                ("FK", "Fatick"),
                ("KA", "Kaffrine"),
                ("KL", "Kaolack"),
                ("KE", "Kédougou"),
                ("KD", "Kolda"),
                ("LG", "Louga"),
                ("MT", "Matam"),
                ("SL", "Saint-Louis"),
                ("SE", "Sédhiou"),
                ("TC", "Tambacounda"),
                ("TH", "Thiès"),
                ("ZG", "Ziguinchor"),
            ]),
        ]
    )

    private static func senegaleseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "SN-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "SN-\(place.code)",
                    countryID: "SN",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "SN-\(group)",
                    flagAssetName: "world_flag_sn",
                    flagNote: "Senegal's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
