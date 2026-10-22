import Foundation

extension CountryCatalog {
    // Malaysia's 13 states and three federal territories. IDs follow ISO 3166-2:MY.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and MalaysiaFlagCredits.json.
    static let malaysia = Country(
        id: "MY",
        name: "Malaysia",
        localName: "Malaysia",
        divisionLabel: "States & territories",
        groups: [
            malaysianGroup("states", name: "States", localName: "Negeri", divisions: [
                ("01", "Johor", nil),
                ("02", "Kedah", nil),
                ("03", "Kelantan", nil),
                ("04", "Malacca", "Melaka"),
                ("05", "Negeri Sembilan", nil),
                ("06", "Pahang", nil),
                ("07", "Penang", "Pulau Pinang"),
                ("08", "Perak", nil),
                ("09", "Perlis", nil),
                ("12", "Sabah", nil),
                ("13", "Sarawak", nil),
                ("10", "Selangor", nil),
                ("11", "Terengganu", nil),
            ]),
            malaysianGroup("territories", name: "Federal territories", localName: "Wilayah Persekutuan", divisions: [
                ("14", "Kuala Lumpur", nil),
                ("15", "Labuan", nil),
                ("16", "Putrajaya", nil),
            ]),
        ]
    )

    private static func malaysianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "MY-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "MY-\(place.code)",
                    countryID: "MY",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "MY-\(group)",
                    flagAssetName: "my_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
