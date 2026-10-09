import Foundation

extension CountryCatalog {
    // The Dominican Republic's 31 provinces, grouped by macro-region (Cibao, Southeast, Southwest), and the National
    // District. IDs follow ISO 3166-2:DO; its ten development regions (DO-33 to DO-42) are not listed as places.
    // The provinces have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let dominicanRepublic = Country(
        id: "DO",
        name: "Dominican Republic",
        localName: "República Dominicana",
        divisionLabel: "Provinces",
        groups: [
            dominicanGroup("cibao", name: "Cibao", localName: nil, divisions: [
                ("05", "Dajabón", nil),
                ("06", "Duarte", nil),
                ("09", "Espaillat", nil),
                ("19", "Hermanas Mirabal", nil),
                ("13", "La Vega", nil),
                ("14", "María Trinidad Sánchez", nil),
                ("28", "Monseñor Nouel", nil),
                ("15", "Monte Cristi", nil),
                ("18", "Puerto Plata", nil),
                ("20", "Samaná", nil),
                ("24", "Sánchez Ramírez", nil),
                ("25", "Santiago", nil),
                ("26", "Santiago Rodríguez", nil),
                ("27", "Valverde", nil),
            ]),
            dominicanGroup("southeast", name: "Southeast", localName: "Sureste", divisions: [
                ("08", "El Seibo", nil),
                ("30", "Hato Mayor", nil),
                ("11", "La Altagracia", nil),
                ("12", "La Romana", nil),
                ("29", "Monte Plata", nil),
                ("23", "San Pedro de Macorís", nil),
                ("32", "Santo Domingo", nil),
            ]),
            dominicanGroup("southwest", name: "Southwest", localName: "Suroeste", divisions: [
                ("02", "Azua", nil),
                ("03", "Baoruco", nil),
                ("04", "Barahona", nil),
                ("07", "Elías Piña", nil),
                ("10", "Independencia", nil),
                ("16", "Pedernales", nil),
                ("17", "Peravia", nil),
                ("21", "San Cristóbal", nil),
                ("31", "San José de Ocoa", nil),
                ("22", "San Juan", nil),
            ]),
            dominicanGroup("national-district", name: "National District", localName: "Distrito Nacional", divisions: [
                ("01", "National District", "Distrito Nacional"),
            ]),
        ]
    )

    private static func dominicanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "DO-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "DO-\(place.code)",
                    countryID: "DO",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "DO-\(group)",
                    flagAssetName: "world_flag_do",
                    flagNote: "Dominican provinces and the National District have no official flags; the national flag is shown."
                )
            }
        )
    }
}
