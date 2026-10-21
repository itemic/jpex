import Foundation

extension CountryCatalog {
    // Haiti's ten departments. IDs follow ISO 3166-2:HT. Local names are Haitian Creole. None has an
    // official flag, so each shows the national flag; see MORE_FLAG_SOURCES_D.md.
    static let haiti = Country(
        id: "HT",
        name: "Haiti",
        localName: "Ayiti",
        divisionLabel: "Departments",
        groups: [
            haitianGroup("departments", name: "Departments", localName: "Depatman", divisions: [
                ("AR", "Artibonite", "Latibonit"),
                ("CE", "Centre", "Sant"),
                ("GA", "Grand'Anse", "Grandans"),
                ("NI", "Nippes", "Nip"),
                ("ND", "Nord", "Nò"),
                ("NE", "Nord-Est", "Nòdès"),
                ("NO", "Nord-Ouest", "Nòdwès"),
                ("OU", "Ouest", "Lwès"),
                ("SD", "Sud", "Sid"),
                ("SE", "Sud-Est", "Sidès"),
            ]),
        ]
    )

    private static func haitianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "HT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "HT-\(place.code)",
                    countryID: "HT",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "HT-\(group)",
                    flagAssetName: "world_flag_ht",
                    flagNote: "Haiti's departments have no official flags; the national flag is shown."
                )
            }
        )
    }
}
