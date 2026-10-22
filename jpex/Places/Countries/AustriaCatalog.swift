import Foundation

extension CountryCatalog {
    // Austria's nine federal states. IDs follow ISO 3166-2:AT.
    // Each state shows its civil state flag (Landesflagge), not the service flag with arms, so
    // Upper Austria and Tyrol share white-red and Salzburg, Vienna and Vorarlberg share red-white.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and AustriaFlagCredits.json.
    static let austria = Country(
        id: "AT",
        name: "Austria",
        localName: "Österreich",
        divisionLabel: "States",
        groups: [
            austrianGroup("states", name: "States", localName: "Bundesländer", divisions: [
                ("1", "Burgenland", nil),
                ("2", "Carinthia", "Kärnten"),
                ("3", "Lower Austria", "Niederösterreich"),
                ("5", "Salzburg", nil),
                ("6", "Styria", "Steiermark"),
                ("7", "Tyrol", "Tirol"),
                ("4", "Upper Austria", "Oberösterreich"),
                ("9", "Vienna", "Wien"),
                ("8", "Vorarlberg", nil),
            ]),
        ]
    )

    private static func austrianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "AT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "AT-\(place.code)",
                    countryID: "AT",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "AT-\(group)",
                    flagAssetName: "at_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
