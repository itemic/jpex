import Foundation

extension CountryCatalog {
    // Estonia's 15 counties (maakonnad); municipalities are not listed. IDs follow ISO 3166-2:EE.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and EstoniaFlagCredits.json.
    static let estonia = Country(
        id: "EE",
        name: "Estonia",
        localName: "Eesti",
        divisionLabel: "Counties",
        groups: [
            estonianGroup("counties", name: "Counties", localName: "Maakonnad", divisions: [
                ("37", "Harju", "Harjumaa"),
                ("39", "Hiiu", "Hiiumaa"),
                ("45", "Ida-Viru", "Ida-Virumaa"),
                ("52", "Järva", "Järvamaa"),
                ("50", "Jõgeva", "Jõgevamaa"),
                ("56", "Lääne", "Läänemaa"),
                ("60", "Lääne-Viru", "Lääne-Virumaa"),
                ("68", "Pärnu", "Pärnumaa"),
                ("64", "Põlva", "Põlvamaa"),
                ("71", "Rapla", "Raplamaa"),
                ("74", "Saare", "Saaremaa"),
                ("79", "Tartu", "Tartumaa"),
                ("81", "Valga", "Valgamaa"),
                ("84", "Viljandi", "Viljandimaa"),
                ("87", "Võru", "Võrumaa"),
            ]),
        ]
    )

    private static func estonianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "EE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "EE-\(place.code)",
                    countryID: "EE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "EE-\(group)",
                    flagAssetName: "ee_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
