import Foundation

extension CountryCatalog {
    // Finland's 19 regions, including the autonomous Åland Islands (FI-01), which the Countries collection
    // shares. IDs follow ISO 3166-2:FI. Local names are Finnish, and Swedish for Åland.
    // Most regions fly a flag set by the regional council, usually a banner of the regional arms. Six
    // regions have only a regional pennant and show the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and FinlandFlagCredits.json.
    static let finland = Country(
        id: "FI",
        name: "Finland",
        localName: "Suomi",
        divisionLabel: "Regions",
        groups: [
            finnishGroup("regions", name: "Regions", localName: "Maakunnat", divisions: [
                ("01", "Åland Islands", "Åland"),
                ("08", "Central Finland", "Keski-Suomi"),
                ("07", "Central Ostrobothnia", "Keski-Pohjanmaa"),
                ("05", "Kainuu", nil),
                ("06", "Kanta-Häme", nil),
                ("09", "Kymenlaakso", nil),
                ("10", "Lapland", "Lappi"),
                ("13", "North Karelia", "Pohjois-Karjala"),
                ("14", "North Ostrobothnia", "Pohjois-Pohjanmaa"),
                ("15", "North Savo", "Pohjois-Savo"),
                ("12", "Ostrobothnia", "Pohjanmaa"),
                ("16", "Päijät-Häme", nil),
                ("11", "Pirkanmaa", nil),
                ("17", "Satakunta", nil),
                ("02", "South Karelia", "Etelä-Karjala"),
                ("03", "South Ostrobothnia", "Etelä-Pohjanmaa"),
                ("04", "South Savo", "Etelä-Savo"),
                ("19", "Southwest Finland", "Varsinais-Suomi"),
                ("18", "Uusimaa", nil),
            ]),
        ]
    )

    /// Regions whose flag is a banner of the regional coat of arms.
    private static let finnishBannersOfArms: Set<String> = ["03", "05", "06", "08", "11", "16", "17", "18"]

    /// Regions with a regional pennant but no flag; they show the national flag.
    private static let finnishRegionsWithoutFlags: Set<String> = ["02", "09", "10", "12", "14", "19"]

    private static func finnishFlagNote(_ code: String, name: String) -> String? {
        if finnishRegionsWithoutFlags.contains(code) {
            return "The national flag is shown; \(name) has no official flag."
        }
        return finnishBannersOfArms.contains(code) ? "Banner of the region's coat of arms." : nil
    }

    private static func finnishGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "FI-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "FI-\(place.code)",
                    countryID: "FI",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "FI-\(group)",
                    flagAssetName: finnishRegionsWithoutFlags.contains(place.code) ? "world_flag_fi" : "fi_flag_\(place.code)",
                    flagNote: finnishFlagNote(place.code, name: place.name)
                )
            }
        )
    }
}
