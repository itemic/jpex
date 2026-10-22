import Foundation

extension CountryCatalog {
    // Portugal's 18 mainland districts and the autonomous regions of the Azores and Madeira.
    // IDs follow ISO 3166-2:PT. Districts have no official flags and show the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and PortugalFlagCredits.json.
    static let portugal = Country(
        id: "PT",
        name: "Portugal",
        localName: "Portugal",
        divisionLabel: "Districts & regions",
        groups: [
            portugueseGroup("districts", name: "Districts", localName: "Distritos", divisions: [
                ("01", "Aveiro", nil),
                ("02", "Beja", nil),
                ("03", "Braga", nil),
                ("04", "Bragança", nil),
                ("05", "Castelo Branco", nil),
                ("06", "Coimbra", nil),
                ("07", "Évora", nil),
                ("08", "Faro", nil),
                ("09", "Guarda", nil),
                ("10", "Leiria", nil),
                ("11", "Lisbon", "Lisboa"),
                ("12", "Portalegre", nil),
                ("13", "Porto", nil),
                ("14", "Santarém", nil),
                ("15", "Setúbal", nil),
                ("16", "Viana do Castelo", nil),
                ("17", "Vila Real", nil),
                ("18", "Viseu", nil),
            ]),
            portugueseGroup("regions", name: "Autonomous regions", localName: "Regiões autónomas", divisions: [
                ("20", "Azores", "Açores"),
                ("30", "Madeira", nil),
            ]),
        ]
    )

    private static func portugueseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "PT-\(place.code)",
                    countryID: "PT",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "PT-\(group)",
                    flagAssetName: group == "districts" ? "world_flag_pt" : "pt_flag_\(place.code)",
                    flagNote: group == "districts"
                        ? "The national flag is shown; \(place.name) District has no official flag."
                        : nil
                )
            }
        )
    }
}
