import Foundation

extension CountryCatalog {
    // The Philippines' 82 provinces and Metro Manila, grouped by island group according to each
    // province's ISO 3166-2:PH region. IDs follow ISO 3166-2:PH; PH-00 is the National Capital Region.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and PhilippinesFlagCredits.json.
    static let philippines = Country(
        id: "PH",
        name: "Philippines",
        localName: "Pilipinas",
        divisionLabel: "Provinces",
        groups: [
            philippineIslandGroup("luzon", name: "Luzon", localName: nil, divisions: [
                ("ABR", "Abra"),
                ("ALB", "Albay"),
                ("APA", "Apayao"),
                ("AUR", "Aurora"),
                ("BAN", "Bataan"),
                ("BTN", "Batanes"),
                ("BTG", "Batangas"),
                ("BEN", "Benguet"),
                ("BUL", "Bulacan"),
                ("CAG", "Cagayan"),
                ("CAN", "Camarines Norte"),
                ("CAS", "Camarines Sur"),
                ("CAT", "Catanduanes"),
                ("CAV", "Cavite"),
                ("IFU", "Ifugao"),
                ("ILN", "Ilocos Norte"),
                ("ILS", "Ilocos Sur"),
                ("ISA", "Isabela"),
                ("KAL", "Kalinga"),
                ("LUN", "La Union"),
                ("LAG", "Laguna"),
                ("MAD", "Marinduque"),
                ("MAS", "Masbate"),
                ("00", "Metro Manila"),
                ("MOU", "Mountain Province"),
                ("NUE", "Nueva Ecija"),
                ("NUV", "Nueva Vizcaya"),
                ("MDC", "Occidental Mindoro"),
                ("MDR", "Oriental Mindoro"),
                ("PLW", "Palawan"),
                ("PAM", "Pampanga"),
                ("PAN", "Pangasinan"),
                ("QUE", "Quezon"),
                ("QUI", "Quirino"),
                ("RIZ", "Rizal"),
                ("ROM", "Romblon"),
                ("SOR", "Sorsogon"),
                ("TAR", "Tarlac"),
                ("ZMB", "Zambales"),
            ]),
            philippineIslandGroup("visayas", name: "Visayas", localName: nil, divisions: [
                ("AKL", "Aklan"),
                ("ANT", "Antique"),
                ("BIL", "Biliran"),
                ("BOH", "Bohol"),
                ("CAP", "Capiz"),
                ("CEB", "Cebu"),
                ("EAS", "Eastern Samar"),
                ("GUI", "Guimaras"),
                ("ILI", "Iloilo"),
                ("LEY", "Leyte"),
                ("NEC", "Negros Occidental"),
                ("NER", "Negros Oriental"),
                ("NSA", "Northern Samar"),
                ("WSA", "Samar"),
                ("SIG", "Siquijor"),
                ("SLE", "Southern Leyte"),
            ]),
            philippineIslandGroup("mindanao", name: "Mindanao", localName: nil, divisions: [
                ("AGN", "Agusan del Norte"),
                ("AGS", "Agusan del Sur"),
                ("BAS", "Basilan"),
                ("BUK", "Bukidnon"),
                ("CAM", "Camiguin"),
                ("NCO", "Cotabato"),
                ("COM", "Davao de Oro"),
                ("DAV", "Davao del Norte"),
                ("DAS", "Davao del Sur"),
                ("DVO", "Davao Occidental"),
                ("DAO", "Davao Oriental"),
                ("DIN", "Dinagat Islands"),
                ("LAN", "Lanao del Norte"),
                ("LAS", "Lanao del Sur"),
                ("MGN", "Maguindanao del Norte"),
                ("MGS", "Maguindanao del Sur"),
                ("MSC", "Misamis Occidental"),
                ("MSR", "Misamis Oriental"),
                ("SAR", "Sarangani"),
                ("SCO", "South Cotabato"),
                ("SUK", "Sultan Kudarat"),
                ("SLU", "Sulu"),
                ("SUN", "Surigao del Norte"),
                ("SUR", "Surigao del Sur"),
                ("TAW", "Tawi-Tawi"),
                ("ZAN", "Zamboanga del Norte"),
                ("ZAS", "Zamboanga del Sur"),
                ("ZSI", "Zamboanga Sibugay"),
            ]),
        ]
    )

    private static func philippineIslandGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PH-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "PH-\(place.code)",
                    countryID: "PH",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "PH-\(group)",
                    flagAssetName: place.code == "00" ? "world_flag_ph" : "ph_flag_\(place.code.lowercased())",
                    flagNote: place.code == "00" ? "The national flag is shown; Metro Manila has no official flag." : nil
                )
            }
        )
    }
}
