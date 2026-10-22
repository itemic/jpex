import Foundation

extension CountryCatalog {
    // Cameroon's ten regions. IDs follow ISO 3166-2:CM. Local names are French, but for the
    // English-speaking Northwest and Southwest. The regions have no official flags, so each shows the
    // national flag. See MORE_FLAG_SOURCES_D.md.
    static let cameroon = Country(
        id: "CM",
        name: "Cameroon",
        localName: "Cameroun",
        divisionLabel: "Regions",
        groups: [
            cameroonianGroup("regions", name: "Regions", localName: "Régions", divisions: [
                ("AD", "Adamawa", "Adamaoua"),
                ("CE", "Centre", nil),
                ("ES", "East", "Est"),
                ("EN", "Far North", "Extrême-Nord"),
                ("LT", "Littoral", nil),
                ("NO", "North", "Nord"),
                ("NW", "Northwest", nil),
                ("SU", "South", "Sud"),
                ("SW", "Southwest", nil),
                ("OU", "West", "Ouest"),
            ]),
        ]
    )

    private static func cameroonianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "CM-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "CM-\(place.code)",
                    countryID: "CM",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "CM-\(group)",
                    flagAssetName: "world_flag_cm",
                    flagNote: "Cameroon's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
