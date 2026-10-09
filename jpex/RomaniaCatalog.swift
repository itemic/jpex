import Foundation

extension CountryCatalog {
    // Romania's 41 counties and Bucharest, grouped by historical region. IDs follow ISO 3166-2:RO.
    // Counties that span two regions are listed under the one usually given for them: Arad and Satu Mare
    // under Crișana, Mehedinți under Wallachia, Sălaj under Transylvania, Suceava and Vrancea under Moldavia.
    // A county flag is official only once the Government has approved it (Law 141/2015). Counties without one,
    // and those whose approved flag has no accurate artwork yet, show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and RomaniaFlagCredits.json.
    static let romania = Country(
        id: "RO",
        name: "Romania",
        localName: "România",
        divisionLabel: "Counties",
        groups: [
            romanianRegion("transylvania", name: "Transylvania", localName: "Transilvania", divisions: [
                ("AB", "Alba", nil),
                ("BN", "Bistrița-Năsăud", nil),
                ("BV", "Brașov", nil),
                ("CJ", "Cluj", nil),
                ("CV", "Covasna", nil),
                ("HR", "Harghita", nil),
                ("HD", "Hunedoara", nil),
                ("MS", "Mureș", nil),
                ("SJ", "Sălaj", nil),
                ("SB", "Sibiu", nil),
            ]),
            romanianRegion("wallachia", name: "Wallachia", localName: "Țara Românească", divisions: [
                ("AG", "Argeș", nil),
                ("BR", "Brăila", nil),
                ("BZ", "Buzău", nil),
                ("CL", "Călărași", nil),
                ("DB", "Dâmbovița", nil),
                ("DJ", "Dolj", nil),
                ("GR", "Giurgiu", nil),
                ("GJ", "Gorj", nil),
                ("IL", "Ialomița", nil),
                ("IF", "Ilfov", nil),
                ("MH", "Mehedinți", nil),
                ("OT", "Olt", nil),
                ("PH", "Prahova", nil),
                ("TR", "Teleorman", nil),
                ("VL", "Vâlcea", nil),
            ]),
            romanianRegion("moldavia", name: "Moldavia", localName: "Moldova", divisions: [
                ("BC", "Bacău", nil),
                ("BT", "Botoșani", nil),
                ("GL", "Galați", nil),
                ("IS", "Iași", nil),
                ("NT", "Neamț", nil),
                ("SV", "Suceava", nil),
                ("VS", "Vaslui", nil),
                ("VN", "Vrancea", nil),
            ]),
            romanianRegion("dobruja", name: "Dobruja", localName: "Dobrogea", divisions: [
                ("CT", "Constanța", nil),
                ("TL", "Tulcea", nil),
            ]),
            romanianRegion("banat", name: "Banat", localName: nil, divisions: [
                ("CS", "Caraș-Severin", nil),
                ("TM", "Timiș", nil),
            ]),
            romanianRegion("crisana", name: "Crișana", localName: nil, divisions: [
                ("AR", "Arad", nil),
                ("BH", "Bihor", nil),
                ("SM", "Satu Mare", nil),
            ]),
            romanianRegion("maramures", name: "Maramureș", localName: nil, divisions: [
                ("MM", "Maramureș", nil),
            ]),
            romanianRegion("bucharest", name: "Bucharest", localName: "București", divisions: [
                ("B", "Bucharest", "București"),
            ]),
        ]
    )

    /// Counties whose flag has been approved by Government decision under Law 141/2015 and is shown.
    private static let romanianCountiesWithFlagArtwork: Set<String> = [
        "CV", "IF", "MS",
    ]

    /// Counties with an approved flag for which no accurate artwork is available; the national flag is shown.
    private static let romanianFlagArtworkNotes: [String: String] = [
        "BV": "The national flag is shown; artwork for Brașov County's flag, approved in 2026, is not available yet.",
        "BZ": "The national flag is shown; no accurate artwork of Buzău County's official flag is available.",
        "PH": "The national flag is shown; no accurate artwork of Prahova County's official flag is available.",
        "TM": "The national flag is shown; no accurate artwork of Timiș County's official flag is available.",
    ]

    private static func romanianFlagNote(_ code: String, name: String) -> String? {
        if romanianCountiesWithFlagArtwork.contains(code) { return nil }
        if let note = romanianFlagArtworkNotes[code] { return note }
        return code == "B"
            ? "The national flag is shown; Bucharest has no official flag."
            : "The national flag is shown; \(name) County has no official flag."
    }

    private static func romanianRegion(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "RO-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = romanianFlagNote(place.code, name: place.name)
                return AdministrativeDivision(
                    id: "RO-\(place.code)",
                    countryID: "RO",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "RO-\(group)",
                    flagAssetName: flagNote == nil ? "ro_flag_\(place.code.lowercased())" : "world_flag_ro",
                    flagNote: flagNote
                )
            }
        )
    }
}
