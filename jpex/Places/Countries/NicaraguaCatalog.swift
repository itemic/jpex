import Foundation

extension CountryCatalog {
    // Nicaragua's fifteen departments and its two autonomous regions on the Caribbean coast. IDs follow
    // ISO 3166-2:NI. Local names are Spanish. Flag sources and licences: MORE_FLAG_SOURCES_D.md and
    // NicaraguaFlagCredits.json.
    static let nicaragua = Country(
        id: "NI",
        name: "Nicaragua",
        localName: "Nicaragua",
        divisionLabel: "Departments & regions",
        groups: [
            nicaraguanGroup("departments", name: "Departments", localName: "Departamentos", divisions: [
                ("BO", "Boaco", nil),
                ("CA", "Carazo", nil),
                ("CI", "Chinandega", nil),
                ("CO", "Chontales", nil),
                ("ES", "Estelí", nil),
                ("GR", "Granada", nil),
                ("JI", "Jinotega", nil),
                ("LE", "León", nil),
                ("MD", "Madriz", nil),
                ("MN", "Managua", nil),
                ("MS", "Masaya", nil),
                ("MT", "Matagalpa", nil),
                ("NS", "Nueva Segovia", nil),
                ("SJ", "Río San Juan", nil),
                ("RI", "Rivas", nil),
            ]),
            nicaraguanGroup("regions", name: "Autonomous regions", localName: "Regiones autónomas", divisions: [
                ("AN", "North Caribbean Coast", "Costa Caribe Norte"),
                ("AS", "South Caribbean Coast", "Costa Caribe Sur"),
            ]),
        ]
    )

    /// Places without a flag of their own here show the national flag.
    private static let nicaraguanFlagNotes: [String: String] = [
        "BO": "The national flag is shown; Boaco Department has no official flag.",
        "CA": "The national flag is shown; Carazo Department has no official flag.",
        "CI": "The national flag is shown; Chinandega Department has no official flag.",
        "CO": "The national flag is shown; Chontales Department has no official flag.",
        "ES": "The national flag is shown; Estelí Department has no official flag.",
        "GR": "The national flag is shown; Granada Department has no official flag.",
        "JI": "The national flag is shown; Jinotega Department has no official flag.",
        "LE": "The national flag is shown; León Department has no official flag.",
        "MD": "The national flag is shown; Madriz Department has no official flag.",
        "MN": "The national flag is shown; Managua Department has no official flag.",
        "MS": "The national flag is shown; Masaya Department has no official flag.",
        "MT": "The national flag is shown; Matagalpa Department has no official flag.",
        "NS": "The national flag is shown; Nueva Segovia Department has no official flag.",
        "SJ": "The national flag is shown; Río San Juan Department has no official flag.",
        "RI": "The national flag is shown; Rivas Department has no official flag.",
    ]

    private static func nicaraguanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "NI-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = nicaraguanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "NI-\(place.code)",
                    countryID: "NI",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "NI-\(group)",
                    flagAssetName: flagNote == nil ? "ni_flag_\(place.code.lowercased())" : "world_flag_ni",
                    flagNote: flagNote
                )
            }
        )
    }
}
