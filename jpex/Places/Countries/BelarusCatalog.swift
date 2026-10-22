import Foundation

extension CountryCatalog {
    // Belarus's six regions (voblasts) and the capital, Minsk. IDs follow ISO 3166-2:BY. Local names are Belarusian.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and BelarusFlagCredits.json.
    static let belarus = Country(
        id: "BY",
        name: "Belarus",
        localName: "Беларусь",
        divisionLabel: "Regions",
        groups: [
            belarusianGroup("regions", name: "Regions", localName: "Вобласці", divisions: [
                ("BR", "Brest", "Брэсцкая вобласць"),
                ("HO", "Gomel", "Гомельская вобласць"),
                ("HR", "Grodno", "Гродзенская вобласць"),
                ("MA", "Mogilev", "Магілёўская вобласць"),
                ("MI", "Minsk Region", "Мінская вобласць"),
                ("VI", "Vitebsk", "Віцебская вобласць"),
            ]),
            belarusianGroup("capital", name: "Capital", localName: "Сталіца", divisions: [
                ("HM", "Minsk", "Мінск"),
            ]),
        ]
    )

    private static func belarusianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BY-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BY-\(place.code)",
                    countryID: "BY",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BY-\(group)",
                    flagAssetName: "by_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
