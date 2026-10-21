import Foundation

extension CountryCatalog {
    // Moldova's 32 districts, three municipalities and two autonomous territorial units, Gagauzia and
    // Transnistria, listed de jure as Bender is. IDs follow ISO 3166-2:MD. Flag sources and licences:
    // MORE_FLAG_SOURCES_D.md and MoldovaFlagCredits.json.
    static let moldova = Country(
        id: "MD",
        name: "Moldova",
        localName: "Moldova",
        divisionLabel: "Districts",
        groups: [
            moldovanGroup("districts", name: "Districts", localName: "Raioane", divisions: [
                ("AN", "Anenii Noi", nil),
                ("BS", "Basarabeasca", nil),
                ("BR", "Briceni", nil),
                ("CA", "Cahul", nil),
                ("CL", "Călărași", nil),
                ("CT", "Cantemir", nil),
                ("CS", "Căușeni", nil),
                ("CM", "Cimișlia", nil),
                ("CR", "Criuleni", nil),
                ("DO", "Dondușeni", nil),
                ("DR", "Drochia", nil),
                ("DU", "Dubăsari", nil),
                ("ED", "Edineț", nil),
                ("FA", "Fălești", nil),
                ("FL", "Florești", nil),
                ("GL", "Glodeni", nil),
                ("HI", "Hîncești", nil),
                ("IA", "Ialoveni", nil),
                ("LE", "Leova", nil),
                ("NI", "Nisporeni", nil),
                ("OC", "Ocnița", nil),
                ("OR", "Orhei", nil),
                ("RE", "Rezina", nil),
                ("RI", "Rîșcani", nil),
                ("SI", "Sîngerei", nil),
                ("SD", "Șoldănești", nil),
                ("SO", "Soroca", nil),
                ("SV", "Ștefan Vodă", nil),
                ("ST", "Strășeni", nil),
                ("TA", "Taraclia", nil),
                ("TE", "Telenești", nil),
                ("UN", "Ungheni", nil),
            ]),
            moldovanGroup("municipalities", name: "Municipalities", localName: "Municipii", divisions: [
                ("BA", "Bălți", nil),
                ("BD", "Bender", nil),
                ("CU", "Chișinău", nil),
            ]),
            moldovanGroup("autonomous-territorial-units", name: "Autonomous territorial units", localName: "Unități teritoriale autonome", divisions: [
                ("GA", "Gagauzia", "Găgăuzia"),
                ("SN", "Transnistria", "Stînga Nistrului"),
            ]),
        ]
    )

    /// Places without a flag of their own here show the national flag.
    private static let moldovanFlagNotes: [String: String] = [
        "BR": "The national flag is shown; no artwork of Briceni District's flag (adopted in 2026) is available.",
        "BD": "The national flag is shown; Bender's flag (2003) was adopted under the Transnistrian administration, which Moldova does not recognise.",
        "SN": "The national flag is shown; Transnistria has no official flag as a territorial unit of Moldova.",
    ]

    private static func moldovanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "MD-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = moldovanFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "MD-\(place.code)",
                    countryID: "MD",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "MD-\(group)",
                    flagAssetName: flagNote == nil ? "md_flag_\(place.code.lowercased())" : "world_flag_md",
                    flagNote: flagNote
                )
            }
        )
    }
}
