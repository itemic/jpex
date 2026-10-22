import Foundation

extension CountryCatalog {
    // The 12 provinces of the Netherlands; the Caribbean special municipalities are not provinces.
    // IDs follow ISO 3166-2:NL. Flag sources and licences: MORE_FLAG_SOURCES.md and NetherlandsFlagCredits.json.
    static let netherlands = Country(
        id: "NL",
        name: "Netherlands",
        localName: "Nederland",
        divisionLabel: "Provinces",
        groups: [
            dutchGroup("provinces", name: "Provinces", localName: "Provincies", divisions: [
                ("DR", "Drenthe", nil),
                ("FL", "Flevoland", nil),
                ("FR", "Friesland", "Fryslân"),
                ("GE", "Gelderland", nil),
                ("GR", "Groningen", nil),
                ("LI", "Limburg", nil),
                ("NB", "North Brabant", "Noord-Brabant"),
                ("NH", "North Holland", "Noord-Holland"),
                ("OV", "Overijssel", nil),
                ("ZH", "South Holland", "Zuid-Holland"),
                ("UT", "Utrecht", nil),
                ("ZE", "Zeeland", nil),
            ]),
        ]
    )

    private static func dutchGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "NL-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "NL-\(place.code)",
                    countryID: "NL",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "NL-\(group)",
                    flagAssetName: "nl_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
