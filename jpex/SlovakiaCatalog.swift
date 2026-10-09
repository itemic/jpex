import Foundation

extension CountryCatalog {
    // Slovakia's eight self-governing regions (kraje). IDs follow ISO 3166-2:SK.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and SlovakiaFlagCredits.json.
    static let slovakia = Country(
        id: "SK",
        name: "Slovakia",
        localName: "Slovensko",
        divisionLabel: "Regions",
        groups: [
            slovakGroup("regions", name: "Regions", localName: "Kraje", divisions: [
                ("BC", "Banská Bystrica", "Banskobystrický kraj"),
                ("BL", "Bratislava", "Bratislavský kraj"),
                ("KI", "Košice", "Košický kraj"),
                ("NI", "Nitra", "Nitriansky kraj"),
                ("PV", "Prešov", "Prešovský kraj"),
                ("TC", "Trenčín", "Trenčiansky kraj"),
                ("TA", "Trnava", "Trnavský kraj"),
                ("ZI", "Žilina", "Žilinský kraj"),
            ]),
        ]
    )

    private static func slovakGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "SK-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "SK-\(place.code)",
                    countryID: "SK",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "SK-\(group)",
                    flagAssetName: "sk_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
