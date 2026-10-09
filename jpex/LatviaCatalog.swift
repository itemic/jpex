import Foundation

extension CountryCatalog {
    // Latvia's seven state cities and 35 municipalities (novadi) as reorganised in 2021. IDs follow ISO 3166-2:LV.
    // Varakļāni Municipality (LV-102), merged into Madona Municipality on 1 July 2025, is not included.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and LatviaFlagCredits.json.
    static let latvia = Country(
        id: "LV",
        name: "Latvia",
        localName: "Latvija",
        divisionLabel: "Municipalities",
        groups: [
            latvianGroup("state-cities", name: "State cities", localName: "Valstspilsētas", divisions: [
                ("RIX", "Riga", "Rīga"),
                ("DGV", "Daugavpils", nil),
                ("JEL", "Jelgava", nil),
                ("JUR", "Jūrmala", nil),
                ("LPX", "Liepāja", nil),
                ("REZ", "Rēzekne", nil),
                ("VEN", "Ventspils", nil),
            ]),
            latvianGroup("municipalities", name: "Municipalities", localName: "Novadi", divisions: [
                ("011", "Ādaži", "Ādažu novads"),
                ("002", "Aizkraukle", "Aizkraukles novads"),
                ("007", "Alūksne", "Alūksnes novads"),
                ("111", "Augšdaugava", "Augšdaugavas novads"),
                ("015", "Balvi", "Balvu novads"),
                ("016", "Bauska", "Bauskas novads"),
                ("022", "Cēsis", "Cēsu novads"),
                ("026", "Dobele", "Dobeles novads"),
                ("033", "Gulbene", "Gulbenes novads"),
                ("041", "Jelgava Municipality", "Jelgavas novads"),
                ("042", "Jēkabpils", "Jēkabpils novads"),
                ("052", "Ķekava", "Ķekavas novads"),
                ("047", "Krāslava", "Krāslavas novads"),
                ("050", "Kuldīga", "Kuldīgas novads"),
                ("054", "Limbaži", "Limbažu novads"),
                ("056", "Līvāni", "Līvānu novads"),
                ("058", "Ludza", "Ludzas novads"),
                ("059", "Madona", "Madonas novads"),
                ("062", "Mārupe", "Mārupes novads"),
                ("067", "Ogre", "Ogres novads"),
                ("068", "Olaine", "Olaines novads"),
                ("073", "Preiļi", "Preiļu novads"),
                ("077", "Rēzekne Municipality", "Rēzeknes novads"),
                ("080", "Ropaži", "Ropažu novads"),
                ("087", "Salaspils", "Salaspils novads"),
                ("088", "Saldus", "Saldus novads"),
                ("089", "Saulkrasti", "Saulkrastu novads"),
                ("091", "Sigulda", "Siguldas novads"),
                ("094", "Smiltene", "Smiltenes novads"),
                ("112", "South Kurzeme", "Dienvidkurzemes novads"),
                ("097", "Talsi", "Talsu novads"),
                ("099", "Tukums", "Tukuma novads"),
                ("101", "Valka", "Valkas novads"),
                ("113", "Valmiera", "Valmieras novads"),
                ("106", "Ventspils Municipality", "Ventspils novads"),
            ]),
        ]
    )

    /// Municipalities without flag artwork show the national flag.
    private static let latvianFlagNotes: [String: String] = [
        "050": "The national flag is shown; no artwork of a Kuldīga Municipality flag is available.",
        "059": "The national flag is shown; no artwork of a Madona Municipality flag is available.",
    ]

    private static func latvianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "LV-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = latvianFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "LV-\(place.code)",
                    countryID: "LV",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "LV-\(group)",
                    flagAssetName: flagNote == nil ? "lv_flag_\(place.code.lowercased())" : "world_flag_lv",
                    flagNote: flagNote
                )
            }
        )
    }
}
