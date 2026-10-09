import Foundation

extension CountryCatalog {
    // Honduras's 18 departments. IDs follow ISO 3166-2:HN.
    // The departments have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let honduras = Country(
        id: "HN",
        name: "Honduras",
        localName: "Honduras",
        divisionLabel: "Departments",
        groups: [
            honduranGroup("departments", name: "Departments", localName: "Departamentos", divisions: [
                ("AT", "Atlántida", nil),
                ("IB", "Bay Islands", "Islas de la Bahía"),
                ("CH", "Choluteca", nil),
                ("CL", "Colón", nil),
                ("CM", "Comayagua", nil),
                ("CP", "Copán", nil),
                ("CR", "Cortés", nil),
                ("EP", "El Paraíso", nil),
                ("FM", "Francisco Morazán", nil),
                ("GD", "Gracias a Dios", nil),
                ("IN", "Intibucá", nil),
                ("LP", "La Paz", nil),
                ("LE", "Lempira", nil),
                ("OC", "Ocotepeque", nil),
                ("OL", "Olancho", nil),
                ("SB", "Santa Bárbara", nil),
                ("VA", "Valle", nil),
                ("YO", "Yoro", nil),
            ]),
        ]
    )

    private static func honduranGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "HN-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "HN-\(place.code)",
                    countryID: "HN",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "HN-\(group)",
                    flagAssetName: "world_flag_hn",
                    flagNote: "The departments of Honduras have no official flags; the national flag is shown."
                )
            }
        )
    }
}
