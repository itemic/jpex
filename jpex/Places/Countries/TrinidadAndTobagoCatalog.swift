import Foundation

extension CountryCatalog {
    // Trinidad and Tobago's fourteen municipal corporations and Tobago, the ISO 3166-2:TT list, grouped as
    // the Municipal Corporations Act groups them. None has free artwork of its flag, so each shows the
    // national flag; see MORE_FLAG_SOURCES_D.md.
    static let trinidadAndTobago = Country(
        id: "TT",
        name: "Trinidad and Tobago",
        localName: "Trinidad and Tobago",
        divisionLabel: "Municipalities & Tobago",
        groups: [
            trinidadianGroup("cities", name: "Cities", localName: nil, divisions: [
                ("POS", "Port of Spain", nil),
                ("SFO", "San Fernando", nil),
            ]),
            trinidadianGroup("boroughs", name: "Boroughs", localName: nil, divisions: [
                ("ARI", "Arima", nil),
                ("CHA", "Chaguanas", nil),
                ("DMN", "Diego Martin", nil),
                ("PTF", "Point Fortin", nil),
                ("SIP", "Siparia", nil),
            ]),
            trinidadianGroup("regions", name: "Regional corporations", localName: nil, divisions: [
                ("CTT", "Couva–Tabaquite–Talparo", nil),
                ("MRC", "Mayaro–Rio Claro", nil),
                ("PED", "Penal–Debe", nil),
                ("PRT", "Princes Town", nil),
                ("SJL", "San Juan–Laventille", nil),
                ("SGE", "Sangre Grande", nil),
                ("TUP", "Tunapuna–Piarco", nil),
            ]),
            trinidadianGroup("tobago", name: "Tobago", localName: nil, divisions: [
                ("TOB", "Tobago", nil),
            ]),
        ]
    )

    /// Every place shows the national flag, for the reason given.
    private static let trinidadianFlagNotes: [String: String] = [
        "POS": "The national flag is shown; no freely licensed artwork of Port of Spain's flag is available.",
        "SFO": "The national flag is shown; no freely licensed artwork of San Fernando's flag is available.",
        "ARI": "The national flag is shown; no freely licensed artwork of Arima's flag is available.",
        "CHA": "The national flag is shown; no freely licensed artwork of Chaguanas's flag is available.",
        "DMN": "The national flag is shown; no freely licensed artwork of Diego Martin's flag is available.",
        "PTF": "The national flag is shown; no freely licensed artwork of Point Fortin's flag is available.",
        "SIP": "The national flag is shown; no freely licensed artwork of Siparia's flag is available.",
        "CTT": "The national flag is shown; no freely licensed artwork of Couva–Tabaquite–Talparo's flag is available.",
        "MRC": "The national flag is shown; no freely licensed artwork of Mayaro–Rio Claro's flag is available.",
        "PED": "The national flag is shown; no freely licensed artwork of Penal–Debe's flag is available.",
        "PRT": "The national flag is shown; no freely licensed artwork of Princes Town's flag is available.",
        "SJL": "The national flag is shown; no freely licensed artwork of San Juan–Laventille's flag is available.",
        "SGE": "The national flag is shown; no freely licensed artwork of Sangre Grande's flag is available.",
        "TUP": "The national flag is shown; no freely licensed artwork of Tunapuna–Piarco's flag is available.",
        "TOB": "The national flag is shown; no freely licensed artwork of the Tobago House of Assembly's flag is available.",
    ]

    private static func trinidadianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "TT-\(place.code)",
                    countryID: "TT",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TT-\(group)",
                    flagAssetName: "world_flag_tt",
                    flagNote: trinidadianFlagNotes[place.code]
                )
            }
        )
    }
}
