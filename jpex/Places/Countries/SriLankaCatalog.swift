import Foundation

extension CountryCatalog {
    // Sri Lanka's nine provinces. IDs follow ISO 3166-2:LK; districts are not included.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and SriLankaFlagCredits.json.
    static let sriLanka = Country(
        id: "LK",
        name: "Sri Lanka",
        localName: "ශ්‍රී ලංකාව",
        divisionLabel: "Provinces",
        groups: [
            sriLankanGroup("provinces", name: "Provinces", localName: "පළාත්", divisions: [
                ("2", "Central Province", "මධ්‍යම පළාත"),
                ("5", "Eastern Province", "නැගෙනහිර පළාත"),
                ("7", "North Central Province", "උතුරු මැද පළාත"),
                ("6", "North Western Province", "වයඹ පළාත"),
                ("4", "Northern Province", "උතුරු පළාත"),
                ("9", "Sabaragamuwa Province", "සබරගමුව පළාත"),
                ("3", "Southern Province", "දකුණු පළාත"),
                ("8", "Uva Province", "ඌව පළාත"),
                ("1", "Western Province", "බස්නාහිර පළාත"),
            ]),
        ]
    )

    private static func sriLankanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "LK-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "LK-\(place.code)",
                    countryID: "LK",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "LK-\(group)",
                    flagAssetName: "lk_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
