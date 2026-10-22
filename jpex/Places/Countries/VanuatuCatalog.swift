import Foundation

extension CountryCatalog {
    // Vanuatu's six provinces. IDs follow ISO 3166-2:VU. Local names are the French forms where they differ.
    // Flag sources and licences: MORE_FLAG_SOURCES_D.md and VanuatuFlagCredits.json.
    static let vanuatu = Country(
        id: "VU",
        name: "Vanuatu",
        localName: "Vanuatu",
        divisionLabel: "Provinces",
        groups: [
            vanuatuanGroup("provinces", name: "Provinces", localName: nil, divisions: [
                ("MAP", "Malampa", nil),
                ("PAM", "Penama", "Pénama"),
                ("SAM", "Sanma", nil),
                ("SEE", "Shefa", "Shéfa"),
                ("TAE", "Tafea", "Taféa"),
                ("TOB", "Torba", nil),
            ]),
        ]
    )

    /// Places without a flag of their own here show the national flag.
    private static let vanuatuanFlagNotes: [String: String] = [
        "PAM": "The national flag is shown; no accurate artwork of Penama's flag is available.",
        "SAM": "The national flag is shown; artwork for Sanma's current flag (2013) is not available.",
        "TOB": "The national flag is shown; no accurate artwork of Torba's flag is available.",
    ]

    private static func vanuatuanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "VU-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = vanuatuanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "VU-\(place.code)",
                    countryID: "VU",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "VU-\(group)",
                    flagAssetName: flagNote == nil ? "vu_flag_\(place.code.lowercased())" : "world_flag_vu",
                    flagNote: flagNote
                )
            }
        )
    }
}
