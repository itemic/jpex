import Foundation

extension CountryCatalog {
    // Malta's 68 local councils, grouped by island (54 on Malta, 14 on Gozo). IDs follow ISO 3166-2:MT.
    // Councils whose flag has no accurate, freely licensed artwork show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and MaltaFlagCredits.json.
    static let malta = Country(
        id: "MT",
        name: "Malta",
        localName: "Malta",
        divisionLabel: "Local councils",
        groups: [
            malteseGroup("malta", name: "Malta", localName: nil, divisions: [
                ("01", "Attard", "Ħ'Attard"),
                ("02", "Balzan", "Ħal Balzan"),
                ("03", "Birgu", "Il-Birgu"),
                ("04", "Birkirkara", nil),
                ("05", "Birżebbuġa", nil),
                ("06", "Cospicua", "Bormla"),
                ("07", "Dingli", "Ħad-Dingli"),
                ("08", "Fgura", "Il-Fgura"),
                ("09", "Floriana", "Il-Furjana"),
                ("11", "Gudja", "Il-Gudja"),
                ("12", "Gżira", "Il-Gżira"),
                ("15", "Għargħur", "Ħal Għargħur"),
                ("17", "Għaxaq", "Ħal Għaxaq"),
                ("18", "Ħamrun", "Il-Ħamrun"),
                ("19", "Iklin", "L-Iklin"),
                ("21", "Kalkara", "Il-Kalkara"),
                ("23", "Kirkop", "Ħal Kirkop"),
                ("24", "Lija", "Ħal Lija"),
                ("25", "Luqa", "Ħal Luqa"),
                ("26", "Marsa", "Il-Marsa"),
                ("27", "Marsaskala", nil),
                ("28", "Marsaxlokk", nil),
                ("29", "Mdina", "L-Imdina"),
                ("30", "Mellieħa", "Il-Mellieħa"),
                ("31", "Mġarr", "L-Imġarr"),
                ("32", "Mosta", "Il-Mosta"),
                ("33", "Mqabba", "L-Imqabba"),
                ("34", "Msida", "L-Imsida"),
                ("35", "Mtarfa", "L-Imtarfa"),
                ("38", "Naxxar", "In-Naxxar"),
                ("39", "Paola", "Raħal Ġdid"),
                ("40", "Pembroke", nil),
                ("41", "Pietà", "Tal-Pietà"),
                ("43", "Qormi", "Ħal Qormi"),
                ("44", "Qrendi", "Il-Qrendi"),
                ("46", "Rabat", "Ir-Rabat"),
                ("47", "Safi", "Ħal Safi"),
                ("49", "San Ġwann", nil),
                ("53", "Santa Luċija", nil),
                ("54", "Santa Venera", nil),
                ("20", "Senglea", "L-Isla"),
                ("55", "Siġġiewi", "Is-Siġġiewi"),
                ("56", "Sliema", "Tas-Sliema"),
                ("48", "St. Julian's", "San Ġiljan"),
                ("51", "St. Paul's Bay", "San Pawl il-Baħar"),
                ("57", "Swieqi", "Is-Swieqi"),
                ("58", "Ta' Xbiex", nil),
                ("59", "Tarxien", "Ħal Tarxien"),
                ("60", "Valletta", "Il-Belt Valletta"),
                ("63", "Xgħajra", "Ix-Xgħajra"),
                ("64", "Żabbar", "Ħaż-Żabbar"),
                ("66", "Żebbuġ", "Ħaż-Żebbuġ"),
                ("67", "Żejtun", "Iż-Żejtun"),
                ("68", "Żurrieq", "Iż-Żurrieq"),
            ]),
            malteseGroup("gozo", name: "Gozo", localName: "Għawdex", divisions: [
                ("10", "Fontana", "Il-Fontana"),
                ("13", "Għajnsielem", nil),
                ("14", "Għarb", "L-Għarb"),
                ("16", "Għasri", "L-Għasri"),
                ("22", "Kerċem", "Ta' Kerċem"),
                ("36", "Munxar", "Il-Munxar"),
                ("37", "Nadur", "In-Nadur"),
                ("42", "Qala", "Il-Qala"),
                ("50", "San Lawrenz", nil),
                ("52", "Sannat", "Ta' Sannat"),
                ("45", "Victoria", "Ir-Rabat"),
                ("61", "Xagħra", "Ix-Xagħra"),
                ("62", "Xewkija", "Ix-Xewkija"),
                ("65", "Żebbuġ (Gozo)", "Iż-Żebbuġ"),
            ]),
        ]
    )

    /// Councils whose flag has no accurate, freely licensed artwork show the national flag.
    private static let malteseFlagNotes: [String: String] = [
        "21": "The national flag is shown; no accurate artwork of Kalkara's current flag (2009) is available.",
        "28": "The national flag is shown; no accurate artwork of Marsaxlokk's flag is available.",
        "39": "The national flag is shown; no freely licensed artwork of Paola's flag is available.",
        "64": "The national flag is shown; no accurate artwork of Żabbar's flag is available.",
    ]

    private static func malteseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "MT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = malteseFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "MT-\(place.code)",
                    countryID: "MT",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "MT-\(group)",
                    flagAssetName: flagNote == nil ? "mt_flag_\(place.code.lowercased())" : "world_flag_mt",
                    flagNote: flagNote
                )
            }
        )
    }
}
