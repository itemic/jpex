import Foundation

extension CountryCatalog {
    // Colombia's 32 departments and the Capital District of Bogotá. IDs follow ISO 3166-2:CO.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and ColombiaFlagCredits.json.
    static let colombia = Country(
        id: "CO",
        name: "Colombia",
        localName: "Colombia",
        divisionLabel: "Departments",
        groups: [
            colombianGroup("departments", name: "Departments", localName: "Departamentos", divisions: [
                ("AMA", "Amazonas", nil),
                ("ANT", "Antioquia", nil),
                ("ARA", "Arauca", nil),
                ("ATL", "Atlántico", nil),
                ("BOL", "Bolívar", nil),
                ("BOY", "Boyacá", nil),
                ("CAL", "Caldas", nil),
                ("CAQ", "Caquetá", nil),
                ("CAS", "Casanare", nil),
                ("CAU", "Cauca", nil),
                ("CES", "Cesar", nil),
                ("CHO", "Chocó", nil),
                ("COR", "Córdoba", nil),
                ("CUN", "Cundinamarca", nil),
                ("GUA", "Guainía", nil),
                ("GUV", "Guaviare", nil),
                ("HUI", "Huila", nil),
                ("LAG", "La Guajira", nil),
                ("MAG", "Magdalena", nil),
                ("MET", "Meta", nil),
                ("NAR", "Nariño", nil),
                ("NSA", "Norte de Santander", nil),
                ("PUT", "Putumayo", nil),
                ("QUI", "Quindío", nil),
                ("RIS", "Risaralda", nil),
                ("SAP", "San Andrés and Providencia", "San Andrés y Providencia"),
                ("SAN", "Santander", nil),
                ("SUC", "Sucre", nil),
                ("TOL", "Tolima", nil),
                ("VAC", "Valle del Cauca", nil),
                ("VAU", "Vaupés", nil),
                ("VID", "Vichada", nil),
            ]),
            colombianGroup("capital", name: "Capital District", localName: "Distrito Capital", divisions: [
                ("DC", "Bogotá", nil),
            ]),
        ]
    )

    private static func colombianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "CO-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "CO-\(place.code)",
                    countryID: "CO",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "CO-\(group)",
                    flagAssetName: "co_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
