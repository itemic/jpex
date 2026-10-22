import Foundation

extension CountryCatalog {
    // Mexico's 31 states and Mexico City. IDs follow ISO 3166-2:MX.
    // Fourteen states have flags set by state law. The others, and Mexico City, customarily fly the
    // coat of arms on white; those flags are shown with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and MexicoFlagCredits.json.
    static let mexico = Country(
        id: "MX",
        name: "Mexico",
        localName: "México",
        divisionLabel: "States",
        groups: [
            mexicanGroup("states", name: "States", localName: "Estados", divisions: [
                ("AGU", "Aguascalientes", nil),
                ("BCN", "Baja California", nil),
                ("BCS", "Baja California Sur", nil),
                ("CAM", "Campeche", nil),
                ("CHP", "Chiapas", nil),
                ("CHH", "Chihuahua", nil),
                ("COA", "Coahuila", nil),
                ("COL", "Colima", nil),
                ("DUR", "Durango", nil),
                ("GUA", "Guanajuato", nil),
                ("GRO", "Guerrero", nil),
                ("HID", "Hidalgo", nil),
                ("JAL", "Jalisco", nil),
                ("MIC", "Michoacán", nil),
                ("MOR", "Morelos", nil),
                ("NAY", "Nayarit", nil),
                ("NLE", "Nuevo León", nil),
                ("OAX", "Oaxaca", nil),
                ("PUE", "Puebla", nil),
                ("QUE", "Querétaro", nil),
                ("ROO", "Quintana Roo", nil),
                ("SLP", "San Luis Potosí", nil),
                ("SIN", "Sinaloa", nil),
                ("SON", "Sonora", nil),
                ("MEX", "State of Mexico", "Estado de México"),
                ("TAB", "Tabasco", nil),
                ("TAM", "Tamaulipas", nil),
                ("TLA", "Tlaxcala", nil),
                ("VER", "Veracruz", nil),
                ("YUC", "Yucatán", nil),
                ("ZAC", "Zacatecas", nil),
            ]),
            mexicanGroup("capital", name: "Mexico City", localName: "Ciudad de México", divisions: [
                ("CMX", "Mexico City", "Ciudad de México"),
            ]),
        ]
    )

    /// States whose flag is set by state law. The other states and Mexico City customarily fly
    /// their coat of arms on white; those flags are shown with a note.
    private static let mexicanEntitiesWithOfficialFlags: Set<String> = [
        "BCS", "COA", "COL", "DUR", "GRO", "GUA", "JAL", "OAX", "QUE", "ROO", "TAB", "TAM", "TLA", "YUC",
    ]

    private static func mexicanFlagNote(_ code: String) -> String? {
        if mexicanEntitiesWithOfficialFlags.contains(code) { return nil }
        return code == "CMX"
            ? "Unofficial flag with the city's coat of arms."
            : "Unofficial flag with the state's coat of arms."
    }

    private static func mexicanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "MX-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "MX-\(place.code)",
                    countryID: "MX",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "MX-\(group)",
                    flagAssetName: "mx_flag_\(place.code.lowercased())",
                    flagNote: mexicanFlagNote(place.code)
                )
            }
        )
    }
}
