import Foundation

extension CountryCatalog {
    // Argentina's 23 provinces and the Autonomous City of Buenos Aires, grouped by region.
    // IDs follow ISO 3166-2:AR. Flag sources and licences: MORE_FLAG_SOURCES.md and ArgentinaFlagCredits.json.
    static let argentina = Country(
        id: "AR",
        name: "Argentina",
        localName: "Argentina",
        divisionLabel: "Provinces",
        groups: [
            argentineRegion("northwest", name: "Northwest", localName: "Noroeste", divisions: [
                ("Y", "Jujuy", nil),
                ("A", "Salta", nil),
                ("T", "Tucumán", nil),
                ("K", "Catamarca", nil),
                ("F", "La Rioja", nil),
                ("G", "Santiago del Estero", nil),
            ]),
            argentineRegion("northeast", name: "Northeast", localName: "Noreste", divisions: [
                ("P", "Formosa", nil),
                ("H", "Chaco", nil),
                ("N", "Misiones", nil),
                ("W", "Corrientes", nil),
            ]),
            argentineRegion("cuyo", name: "Cuyo", localName: nil, divisions: [
                ("M", "Mendoza", nil),
                ("J", "San Juan", nil),
                ("D", "San Luis", nil),
            ]),
            argentineRegion("pampas", name: "Pampas", localName: "Pampeana", divisions: [
                ("B", "Buenos Aires", nil),
                ("C", "Buenos Aires City", "Ciudad Autónoma de Buenos Aires"),
                ("X", "Córdoba", nil),
                ("E", "Entre Ríos", nil),
                ("L", "La Pampa", nil),
                ("S", "Santa Fe", nil),
            ]),
            argentineRegion("patagonia", name: "Patagonia", localName: nil, divisions: [
                ("Q", "Neuquén", nil),
                ("R", "Río Negro", nil),
                ("U", "Chubut", nil),
                ("Z", "Santa Cruz", nil),
                ("V", "Tierra del Fuego", nil),
            ]),
        ]
    )

    private static func argentineRegion(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "AR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "AR-\(place.code)",
                    countryID: "AR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "AR-\(group)",
                    flagAssetName: "ar_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
