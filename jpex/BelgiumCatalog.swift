import Foundation

extension CountryCatalog {
    // Belgium's ten provinces and the Brussels-Capital Region, grouped by region. IDs follow ISO 3166-2:BE.
    // Flemish provinces use Dutch local names; Walloon provinces and Brussels use French.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and BelgiumFlagCredits.json.
    static let belgium = Country(
        id: "BE",
        name: "Belgium",
        localName: "België",
        divisionLabel: "Provinces",
        groups: [
            belgianGroup("flanders", name: "Flanders", localName: "Vlaanderen", divisions: [
                ("VAN", "Antwerp", "Antwerpen"),
                ("VLI", "Limburg", nil),
                ("VOV", "East Flanders", "Oost-Vlaanderen"),
                ("VBR", "Flemish Brabant", "Vlaams-Brabant"),
                ("VWV", "West Flanders", "West-Vlaanderen"),
            ]),
            belgianGroup("wallonia", name: "Wallonia", localName: "Wallonie", divisions: [
                ("WBR", "Walloon Brabant", "Brabant wallon"),
                ("WHT", "Hainaut", nil),
                ("WLG", "Liège", nil),
                ("WLX", "Luxembourg", nil),
                ("WNA", "Namur", nil),
            ]),
            belgianGroup("brussels", name: "Brussels", localName: "Bruxelles", divisions: [
                ("BRU", "Brussels-Capital Region", "Région de Bruxelles-Capitale"),
            ]),
        ]
    )

    private static func belgianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BE-\(place.code)",
                    countryID: "BE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BE-\(group)",
                    flagAssetName: "be_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
