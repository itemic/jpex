import Foundation

extension CountryCatalog {
    // Peru's 24 departments, the Constitutional Province of Callao and Lima Province, which is governed by
    // the Metropolitan Municipality of Lima rather than a regional government. IDs follow ISO 3166-2:PE.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and PeruFlagCredits.json.
    static let peru = Country(
        id: "PE",
        name: "Peru",
        localName: "Perú",
        divisionLabel: "Regions",
        groups: [
            peruvianGroup("regions", name: "Regions", localName: "Regiones", divisions: [
                ("AMA", "Amazonas", nil),
                ("ANC", "Áncash", nil),
                ("APU", "Apurímac", nil),
                ("ARE", "Arequipa", nil),
                ("AYA", "Ayacucho", nil),
                ("CAJ", "Cajamarca", nil),
                ("CAL", "Callao", nil),
                ("CUS", "Cusco", nil),
                ("HUV", "Huancavelica", nil),
                ("HUC", "Huánuco", nil),
                ("ICA", "Ica", nil),
                ("JUN", "Junín", nil),
                ("LAL", "La Libertad", nil),
                ("LAM", "Lambayeque", nil),
                ("LMA", "Lima Province", "Provincia de Lima"),
                ("LIM", "Lima Region", "Región Lima"),
                ("LOR", "Loreto", nil),
                ("MDD", "Madre de Dios", nil),
                ("MOQ", "Moquegua", nil),
                ("PAS", "Pasco", nil),
                ("PIU", "Piura", nil),
                ("PUN", "Puno", nil),
                ("SAM", "San Martín", nil),
                ("TAC", "Tacna", nil),
                ("TUM", "Tumbes", nil),
                ("UCA", "Ucayali", nil),
            ]),
        ]
    )

    private static func peruvianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "PE-\(place.code)",
                    countryID: "PE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "PE-\(group)",
                    flagAssetName: "pe_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
