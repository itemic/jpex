import Foundation

extension CountryCatalog {
    // Chile's 16 regions, listed from north to south. IDs follow ISO 3166-2:CL.
    // Seven regions have officially adopted flags. The others fly only unofficial standards of the regional
    // government, so they show the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and ChileFlagCredits.json.
    static let chile = Country(
        id: "CL",
        name: "Chile",
        localName: "Chile",
        divisionLabel: "Regions",
        groups: [
            chileanGroup("regions", name: "Regions", localName: "Regiones", divisions: [
                ("AP", "Arica y Parinacota", nil),
                ("TA", "Tarapacá", nil),
                ("AN", "Antofagasta", nil),
                ("AT", "Atacama", nil),
                ("CO", "Coquimbo", nil),
                ("VS", "Valparaíso", nil),
                ("RM", "Santiago Metropolitan Region", "Región Metropolitana de Santiago"),
                ("LI", "O'Higgins", nil),
                ("ML", "Maule", nil),
                ("NB", "Ñuble", nil),
                ("BI", "Biobío", nil),
                ("AR", "Araucanía", "La Araucanía"),
                ("LR", "Los Ríos", nil),
                ("LL", "Los Lagos", nil),
                ("AI", "Aysén", nil),
                ("MA", "Magallanes", nil),
            ]),
        ]
    )

    /// Regions whose flag has been officially adopted. The others fly only unofficial standards of
    /// the regional government and show the national flag.
    private static let chileanRegionsWithOfficialFlags: Set<String> = ["AP", "AT", "CO", "LL", "LR", "MA", "VS"]

    private static func chileanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "CL-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let hasFlag = chileanRegionsWithOfficialFlags.contains(place.code)
                return AdministrativeDivision(
                    id: "CL-\(place.code)",
                    countryID: "CL",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "CL-\(group)",
                    flagAssetName: hasFlag ? "cl_flag_\(place.code.lowercased())" : "world_flag_cl",
                    flagNote: hasFlag ? nil : "The national flag is shown; \(place.name) has no official flag."
                )
            }
        )
    }
}
