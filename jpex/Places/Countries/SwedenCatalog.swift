import Foundation

extension CountryCatalog {
    // Sweden's 21 counties, grouped by the three lands (Götaland, Svealand, Norrland). IDs follow ISO 3166-2:SE.
    // Counties have no adopted flags; each shows a banner of its official county arms, the form in which
    // Swedish arms are flown as flags.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and SwedenFlagCredits.json.
    static let sweden = Country(
        id: "SE",
        name: "Sweden",
        localName: "Sverige",
        divisionLabel: "Counties",
        groups: [
            swedishLand("gotaland", name: "Götaland", localName: nil, divisions: [
                ("K", "Blekinge", "Blekinge län"),
                ("I", "Gotland", "Gotlands län"),
                ("N", "Halland", "Hallands län"),
                ("F", "Jönköping", "Jönköpings län"),
                ("H", "Kalmar", "Kalmar län"),
                ("G", "Kronoberg", "Kronobergs län"),
                ("E", "Östergötland", "Östergötlands län"),
                ("M", "Skåne", "Skåne län"),
                ("O", "Västra Götaland", "Västra Götalands län"),
            ]),
            swedishLand("svealand", name: "Svealand", localName: nil, divisions: [
                ("W", "Dalarna", "Dalarnas län"),
                ("T", "Örebro", "Örebro län"),
                ("D", "Södermanland", "Södermanlands län"),
                ("AB", "Stockholm", "Stockholms län"),
                ("C", "Uppsala", "Uppsala län"),
                ("S", "Värmland", "Värmlands län"),
                ("U", "Västmanland", "Västmanlands län"),
            ]),
            swedishLand("norrland", name: "Norrland", localName: nil, divisions: [
                ("X", "Gävleborg", "Gävleborgs län"),
                ("Z", "Jämtland", "Jämtlands län"),
                ("BD", "Norrbotten", "Norrbottens län"),
                ("AC", "Västerbotten", "Västerbottens län"),
                ("Y", "Västernorrland", "Västernorrlands län"),
            ]),
        ]
    )

    private static func swedishLand(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "SE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "SE-\(place.code)",
                    countryID: "SE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "SE-\(group)",
                    flagAssetName: "se_flag_\(place.code.lowercased())",
                    flagNote: "Banner of the county's coat of arms."
                )
            }
        )
    }
}
