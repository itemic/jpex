import Foundation

extension CountryCatalog {
    // Guatemala's 22 departments in official order. IDs follow ISO 3166-2:GT.
    // Only flags confirmed by the departmental government (Gobernación) are shown; the others show the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_C.md and GuatemalaFlagCredits.json.
    static let guatemala = Country(
        id: "GT",
        name: "Guatemala",
        localName: "Guatemala",
        divisionLabel: "Departments",
        groups: [
            guatemalanGroup("departments", name: "Departments", localName: "Departamentos", divisions: [
                ("01", "Guatemala"),
                ("02", "El Progreso"),
                ("03", "Sacatepéquez"),
                ("04", "Chimaltenango"),
                ("05", "Escuintla"),
                ("06", "Santa Rosa"),
                ("07", "Sololá"),
                ("08", "Totonicapán"),
                ("09", "Quetzaltenango"),
                ("10", "Suchitepéquez"),
                ("11", "Retalhuleu"),
                ("12", "San Marcos"),
                ("13", "Huehuetenango"),
                ("14", "Quiché"),
                ("15", "Baja Verapaz"),
                ("16", "Alta Verapaz"),
                ("17", "Petén"),
                ("18", "Izabal"),
                ("19", "Zacapa"),
                ("20", "Chiquimula"),
                ("21", "Jalapa"),
                ("22", "Jutiapa"),
            ]),
        ]
    )

    /// Departments shown with the national flag: no flag adopted or used by the departmental government.
    private static let guatemalanFlagNotes: [String: String] = [
        "01": "The national flag is shown; Guatemala Department has no official flag.",
        "02": "The national flag is shown; El Progreso Department has no official flag.",
        "03": "The national flag is shown; Sacatepéquez Department has no official flag.",
        "05": "The national flag is shown; Escuintla Department has no official flag.",
        "06": "The national flag is shown; Santa Rosa Department has no official flag.",
        "07": "The national flag is shown; Sololá Department has no official flag.",
        "09": "The national flag is shown; Quetzaltenango Department has no official flag.",
        "10": "The national flag is shown; Suchitepéquez Department has no official flag.",
        "12": "The national flag is shown; San Marcos Department has no official flag.",
        "13": "The national flag is shown; Huehuetenango Department has no official flag.",
        "14": "The national flag is shown; Quiché Department has no official flag.",
        "15": "The national flag is shown; Baja Verapaz Department has no official flag.",
        "16": "The national flag is shown; Alta Verapaz Department has no official flag.",
        "17": "The national flag is shown; Petén Department has no official flag.",
        "18": "The national flag is shown; Izabal Department has no official flag.",
        "19": "The national flag is shown; Zacapa Department has no official flag.",
        "20": "The national flag is shown; Chiquimula Department has no official flag.",
        "21": "The national flag is shown; Jalapa Department has no official flag.",
    ]

    private static func guatemalanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "GT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = guatemalanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "GT-\(place.code)",
                    countryID: "GT",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "GT-\(group)",
                    flagAssetName: flagNote == nil ? "gt_flag_\(place.code.lowercased())" : "world_flag_gt",
                    flagNote: flagNote
                )
            }
        )
    }
}
