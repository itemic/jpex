import Foundation

extension CountryCatalog {
    // Papua New Guinea's 20 provinces, the Autonomous Region of Bougainville and the National Capital District,
    // grouped by the four regions: Highlands, Islands (with Bougainville), Momase and Southern (with the capital).
    // IDs follow ISO 3166-2:PG. Flag sources and licences: MORE_FLAG_SOURCES_B.md and PapuaNewGuineaFlagCredits.json.
    static let papuaNewGuinea = Country(
        id: "PG",
        name: "Papua New Guinea",
        localName: "Papua Niugini",
        divisionLabel: "Provinces",
        groups: [
            papuaNewGuineanGroup("highlands", name: "Highlands", localName: nil, divisions: [
                ("CPK", "Chimbu", "Simbu"),
                ("EHG", "Eastern Highlands", "Isten Hailans"),
                ("EPW", "Enga", nil),
                ("HLA", "Hela", nil),
                ("JWK", "Jiwaka", nil),
                ("SHM", "Southern Highlands", "Sauten Hailans"),
                ("WHM", "Western Highlands", "Westen Hailans"),
            ]),
            papuaNewGuineanGroup("islands", name: "Islands", localName: nil, divisions: [
                ("NSB", "Bougainville", "Bogenvil"),
                ("EBR", "East New Britain", "Is Niu Briten"),
                ("MRL", "Manus", nil),
                ("NIK", "New Ireland", "Niu Ailan"),
                ("WBK", "West New Britain", "Wes Niu Briten"),
            ]),
            papuaNewGuineanGroup("momase", name: "Momase", localName: nil, divisions: [
                ("ESW", "East Sepik", "Is Sepik"),
                ("MPM", "Madang", nil),
                ("MPL", "Morobe", nil),
                ("SAN", "Sandaun", nil),
            ]),
            papuaNewGuineanGroup("southern", name: "Southern", localName: nil, divisions: [
                ("CPM", "Central Province", "Sentral"),
                ("GPK", "Gulf", nil),
                ("MBA", "Milne Bay", "Milen Be"),
                ("NCD", "National Capital District", "Pot Mosbi"),
                ("NPP", "Oro", nil),
                ("WPD", "Western Province", "Westen"),
            ]),
        ]
    )

    /// Hela replaced its 2012 flag in 2015; only the 2012 design has artwork, so the national flag is shown.
    private static let papuaNewGuineanFlagNotes: [String: String] = [
        "HLA": "The national flag is shown; artwork for Hela's current provincial flag (2015) is not available.",
    ]

    private static func papuaNewGuineanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PG-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = papuaNewGuineanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "PG-\(place.code)",
                    countryID: "PG",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "PG-\(group)",
                    flagAssetName: flagNote == nil ? "pg_flag_\(place.code.lowercased())" : "world_flag_pg",
                    flagNote: flagNote
                )
            }
        )
    }
}
