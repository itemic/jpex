import Foundation

extension CountryCatalog {
    // Solomon Islands' nine provinces and Honiara, the Capital Territory. IDs follow ISO 3166-2:SB.
    // Flag sources and licences: MORE_FLAG_SOURCES_D.md and SolomonIslandsFlagCredits.json.
    static let solomonIslands = Country(
        id: "SB",
        name: "Solomon Islands",
        localName: "Solomon Islands",
        divisionLabel: "Provinces",
        groups: [
            solomonIslandsGroup("provinces", name: "Provinces", localName: nil, divisions: [
                ("CE", "Central Province", nil),
                ("CH", "Choiseul", nil),
                ("GU", "Guadalcanal", nil),
                ("IS", "Isabel", nil),
                ("MK", "Makira-Ulawa", nil),
                ("ML", "Malaita", nil),
                ("RB", "Rennell and Bellona", nil),
                ("TE", "Temotu", nil),
                ("WE", "Western Province", nil),
            ]),
            solomonIslandsGroup("capital", name: "Capital Territory", localName: nil, divisions: [
                ("CT", "Honiara", nil),
            ]),
        ]
    )

    /// Places without a flag of their own here show the national flag.
    private static let solomonIslandsFlagNotes: [String: String] = [
        "CE": "The national flag is shown; no accurate artwork of Central Province's flag is available.",
        "GU": "The national flag is shown; no accurate artwork of Guadalcanal Province's current flag is available.",
    ]

    private static func solomonIslandsGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "SB-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = solomonIslandsFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "SB-\(place.code)",
                    countryID: "SB",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "SB-\(group)",
                    flagAssetName: flagNote == nil ? "sb_flag_\(place.code.lowercased())" : "world_flag_sb",
                    flagNote: flagNote
                )
            }
        )
    }
}
