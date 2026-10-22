import Foundation

extension CountryCatalog {
    // Constituent countries; permanent IDs follow ISO 3166-2:GB.
    // Source and the Northern Ireland flag choice are documented in UK_FLAG_SOURCES.md.
    static let unitedKingdom = Country(
        id: "GB",
        name: "United Kingdom",
        localName: "United Kingdom",
        divisionLabel: "Countries",
        groups: [
            DivisionGroup(
                id: "GB-countries",
                name: "Countries",
                divisions: [
                    britishCountry("ENG", name: "England", flag: "gb_flag_eng"),
                    britishCountry("SCT", name: "Scotland", flag: "gb_flag_sct"),
                    britishCountry("WLS", name: "Wales", flag: "gb_flag_wls"),
                    britishCountry("NIR", name: "Northern Ireland", flag: "world_flag_gb",
                                   note: "The Union Flag is shown; Northern Ireland has no separate official flag.")
                ]
            )
        ]
    )

    private static func britishCountry(
        _ code: String,
        name: String,
        flag: String,
        note: String? = nil
    ) -> AdministrativeDivision {
        AdministrativeDivision(
            id: "GB-\(code)",
            countryID: "GB",
            name: name,
            abbreviation: code,
            groupID: "GB-countries",
            flagAssetName: flag,
            flagNote: note
        )
    }
}
