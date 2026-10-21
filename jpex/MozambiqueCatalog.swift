import Foundation

extension CountryCatalog {
    // Mozambique's ten provinces and its capital, Maputo City (MZ-MPM). IDs follow ISO 3166-2:MZ.
    // Local names are Portuguese. Each place shows the national flag; see MORE_FLAG_SOURCES_D.md.
    static let mozambique = Country(
        id: "MZ",
        name: "Mozambique",
        localName: "Moçambique",
        divisionLabel: "Provinces",
        groups: [
            mozambicanGroup("provinces", name: "Provinces", localName: "Províncias", divisions: [
                ("P", "Cabo Delgado", nil),
                ("G", "Gaza", nil),
                ("I", "Inhambane", nil),
                ("B", "Manica", nil),
                ("L", "Maputo Province", "Província de Maputo"),
                ("N", "Nampula", nil),
                ("A", "Niassa", nil),
                ("S", "Sofala", nil),
                ("T", "Tete", nil),
                ("Q", "Zambezia", "Zambézia"),
            ]),
            mozambicanGroup("capital", name: "Capital", localName: nil, divisions: [
                ("MPM", "Maputo", nil),
            ]),
        ]
    )

    /// Every place shows the national flag, for the reason given.
    private static let mozambicanFlagNotes: [String: String] = [
        "P": "Mozambique's provinces have no official flags; the national flag is shown.",
        "G": "Mozambique's provinces have no official flags; the national flag is shown.",
        "I": "Mozambique's provinces have no official flags; the national flag is shown.",
        "B": "Mozambique's provinces have no official flags; the national flag is shown.",
        "L": "Mozambique's provinces have no official flags; the national flag is shown.",
        "N": "Mozambique's provinces have no official flags; the national flag is shown.",
        "A": "Mozambique's provinces have no official flags; the national flag is shown.",
        "S": "Mozambique's provinces have no official flags; the national flag is shown.",
        "T": "Mozambique's provinces have no official flags; the national flag is shown.",
        "Q": "Mozambique's provinces have no official flags; the national flag is shown.",
        "MPM": "The national flag is shown; no freely licensed artwork of Maputo's flag is available.",
    ]

    private static func mozambicanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "MZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "MZ-\(place.code)",
                    countryID: "MZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "MZ-\(group)",
                    flagAssetName: "world_flag_mz",
                    flagNote: mozambicanFlagNotes[place.code]
                )
            }
        )
    }
}
