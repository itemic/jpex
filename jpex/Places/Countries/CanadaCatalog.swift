import Foundation

extension CountryCatalog {
    // Canada’s ten provinces and three territories; stable ISO 3166-2 codes.
    // Source: https://www.canada.ca/en/intergovernmental-affairs/services/provinces-territories.html
    static let canada = Country(
        id: "CA",
        name: "Canada",
        localName: "Canada",
        divisionLabel: "Provinces & territories",
        groups: [
            DivisionGroup(
                id: "CA-provinces",
                name: "Provinces",
                divisions: [
                    canadianDivision("AB", name: "Alberta", group: "provinces"),
                    canadianDivision("BC", name: "British Columbia", localName: "Colombie-Britannique", group: "provinces"),
                    canadianDivision("MB", name: "Manitoba", group: "provinces"),
                    canadianDivision("NB", name: "New Brunswick", localName: "Nouveau-Brunswick", group: "provinces"),
                    canadianDivision("NL", name: "Newfoundland and Labrador", localName: "Terre-Neuve-et-Labrador", group: "provinces"),
                    canadianDivision("NS", name: "Nova Scotia", localName: "Nouvelle-Écosse", group: "provinces"),
                    canadianDivision("ON", name: "Ontario", group: "provinces"),
                    canadianDivision("PE", name: "Prince Edward Island", localName: "Île-du-Prince-Édouard", group: "provinces"),
                    canadianDivision("QC", name: "Quebec", localName: "Québec", group: "provinces"),
                    canadianDivision("SK", name: "Saskatchewan", group: "provinces")
                ]
            ),
            DivisionGroup(
                id: "CA-territories",
                name: "Territories",
                divisions: [
                    canadianDivision("NT", name: "Northwest Territories", localName: "Territoires du Nord-Ouest", group: "territories"),
                    canadianDivision("NU", name: "Nunavut", group: "territories"),
                    canadianDivision("YT", name: "Yukon", group: "territories")
                ]
            )
        ]
    )

    private static func canadianDivision(_ code: String, name: String, localName: String? = nil, group: String) -> AdministrativeDivision {
        AdministrativeDivision(
            id: "CA-\(code)",
            countryID: "CA",
            name: name,
            localName: localName,
            abbreviation: code,
            groupID: "CA-\(group)",
            flagAssetName: "ca_flag_\(code.lowercased())"
        )
    }
}
