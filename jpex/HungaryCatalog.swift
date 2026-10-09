import Foundation

extension CountryCatalog {
    // Hungary's 19 counties and the capital, Budapest. IDs follow ISO 3166-2:HU; cities with county rights
    // lie within their counties and are not listed separately. County names are the same in Hungarian.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and HungaryFlagCredits.json.
    static let hungary = Country(
        id: "HU",
        name: "Hungary",
        localName: "Magyarország",
        divisionLabel: "Counties",
        groups: [
            hungarianGroup("counties", name: "Counties", localName: "Megyék", divisions: [
                ("BK", "Bács-Kiskun"),
                ("BA", "Baranya"),
                ("BE", "Békés"),
                ("BZ", "Borsod-Abaúj-Zemplén"),
                ("CS", "Csongrád-Csanád"),
                ("FE", "Fejér"),
                ("GS", "Győr-Moson-Sopron"),
                ("HB", "Hajdú-Bihar"),
                ("HE", "Heves"),
                ("JN", "Jász-Nagykun-Szolnok"),
                ("KE", "Komárom-Esztergom"),
                ("NO", "Nógrád"),
                ("PE", "Pest"),
                ("SO", "Somogy"),
                ("SZ", "Szabolcs-Szatmár-Bereg"),
                ("TO", "Tolna"),
                ("VA", "Vas"),
                ("VE", "Veszprém"),
                ("ZA", "Zala"),
            ]),
            hungarianGroup("capital", name: "Capital", localName: "Főváros", divisions: [
                ("BU", "Budapest"),
            ]),
        ]
    )

    private static func hungarianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "HU-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "HU-\(place.code)",
                    countryID: "HU",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "HU-\(group)",
                    flagAssetName: "hu_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
