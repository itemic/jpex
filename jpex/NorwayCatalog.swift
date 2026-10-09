import Foundation

extension CountryCatalog {
    // Norway's 15 counties in force since 1 January 2024. IDs follow ISO 3166-2:NO.
    // Østfold, Akershus, Buskerud, Vestfold, Telemark, Troms and Finnmark were re-established in 2024
    // and fly their pre-2020 county flags again.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and NorwayFlagCredits.json.
    static let norway = Country(
        id: "NO",
        name: "Norway",
        localName: "Norge",
        divisionLabel: "Counties",
        groups: [
            norwegianGroup("counties", name: "Counties", localName: "Fylker", divisions: [
                ("42", "Agder"),
                ("32", "Akershus"),
                ("33", "Buskerud"),
                ("56", "Finnmark"),
                ("34", "Innlandet"),
                ("15", "Møre og Romsdal"),
                ("18", "Nordland"),
                ("03", "Oslo"),
                ("31", "Østfold"),
                ("11", "Rogaland"),
                ("40", "Telemark"),
                ("55", "Troms"),
                ("50", "Trøndelag"),
                ("39", "Vestfold"),
                ("46", "Vestland"),
            ]),
        ]
    )

    private static func norwegianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "NO-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "NO-\(place.code)",
                    countryID: "NO",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "NO-\(group)",
                    flagAssetName: "no_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
