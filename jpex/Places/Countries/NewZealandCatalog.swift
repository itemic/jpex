import Foundation

extension CountryCatalog {
    // New Zealand's 16 regions and the Chatham Islands Territory, grouped by island. IDs follow ISO 3166-2:NZ.
    // Local names are the regions' Māori names, and Rēkohu (Moriori) for the Chatham Islands.
    // Only Nelson has an official flag, adopted by Nelson City Council, the region's unitary authority; the
    // other places show the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and NewZealandFlagCredits.json.
    static let newZealand = Country(
        id: "NZ",
        name: "New Zealand",
        localName: "Aotearoa",
        divisionLabel: "Regions",
        groups: [
            newZealandGroup("north", name: "North Island", localName: "Te Ika-a-Māui", divisions: [
                ("AUK", "Auckland", "Tāmaki Makaurau"),
                ("BOP", "Bay of Plenty", "Te Moana-a-Toi"),
                ("GIS", "Gisborne", "Te Tairāwhiti"),
                ("HKB", "Hawke's Bay", "Te Matau-a-Māui"),
                ("MWT", "Manawatū-Whanganui", nil),
                ("NTL", "Northland", "Te Tai Tokerau"),
                ("TKI", "Taranaki", nil),
                ("WKO", "Waikato", nil),
                ("WGN", "Wellington", "Te Upoko o te Ika a Māui"),
            ]),
            newZealandGroup("south", name: "South Island", localName: "Te Waipounamu", divisions: [
                ("CAN", "Canterbury", "Waitaha"),
                ("MBH", "Marlborough", "Te Tauihu-o-te-waka"),
                ("NSN", "Nelson", "Whakatū"),
                ("OTA", "Otago", "Ōtākou"),
                ("STL", "Southland", "Murihiku"),
                ("TAS", "Tasman", "Te Tai o Aorere"),
                ("WTC", "West Coast", "Te Tai Poutini"),
            ]),
            newZealandGroup("chatham", name: "Chatham Islands", localName: "Rēkohu", divisions: [
                ("CIT", "Chatham Islands", "Rēkohu"),
            ]),
        ]
    )

    /// Notes for places shown with the national flag whose wording differs from the default.
    private static let newZealandFlagNotes: [String: String] = [
        "CIT": "The national flag is shown; the Chatham Islands have no official flag.",
    ]

    private static func newZealandGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "NZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let hasFlag = place.code == "NSN"
                let defaultNote = "The national flag is shown; \(place.name) has no official flag."
                return AdministrativeDivision(
                    id: "NZ-\(place.code)",
                    countryID: "NZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "NZ-\(group)",
                    flagAssetName: hasFlag ? "nz_flag_nsn" : "world_flag_nz",
                    flagNote: hasFlag
                        ? nil
                        : newZealandFlagNotes[place.code, default: defaultNote]
                )
            }
        )
    }
}
