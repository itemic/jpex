import Foundation

extension CountryCatalog {
    // Indonesia's 38 provinces, including Jakarta, Yogyakarta and the four Papua provinces created in 2022,
    // grouped by the ISO 3166-2:ID geographical units. IDs follow ISO 3166-2:ID.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and IndonesiaFlagCredits.json.
    static let indonesia = Country(
        id: "ID",
        name: "Indonesia",
        localName: "Indonesia",
        divisionLabel: "Provinces",
        groups: [
            indonesianRegion("sumatra", name: "Sumatra", localName: "Sumatera", divisions: [
                ("AC", "Aceh", nil),
                ("BB", "Bangka Belitung Islands", "Kepulauan Bangka Belitung"),
                ("BE", "Bengkulu", nil),
                ("JA", "Jambi", nil),
                ("LA", "Lampung", nil),
                ("SU", "North Sumatra", "Sumatera Utara"),
                ("RI", "Riau", nil),
                ("KR", "Riau Islands", "Kepulauan Riau"),
                ("SS", "South Sumatra", "Sumatera Selatan"),
                ("SB", "West Sumatra", "Sumatera Barat"),
            ]),
            indonesianRegion("java", name: "Java", localName: "Jawa", divisions: [
                ("BT", "Banten", nil),
                ("JT", "Central Java", "Jawa Tengah"),
                ("JI", "East Java", "Jawa Timur"),
                ("JK", "Jakarta", nil),
                ("JB", "West Java", "Jawa Barat"),
                ("YO", "Yogyakarta", "Daerah Istimewa Yogyakarta"),
            ]),
            indonesianRegion("lesser-sunda", name: "Lesser Sunda Islands", localName: "Nusa Tenggara", divisions: [
                ("BA", "Bali", nil),
                ("NT", "East Nusa Tenggara", "Nusa Tenggara Timur"),
                ("NB", "West Nusa Tenggara", "Nusa Tenggara Barat"),
            ]),
            indonesianRegion("kalimantan", name: "Kalimantan", localName: nil, divisions: [
                ("KT", "Central Kalimantan", "Kalimantan Tengah"),
                ("KI", "East Kalimantan", "Kalimantan Timur"),
                ("KU", "North Kalimantan", "Kalimantan Utara"),
                ("KS", "South Kalimantan", "Kalimantan Selatan"),
                ("KB", "West Kalimantan", "Kalimantan Barat"),
            ]),
            indonesianRegion("sulawesi", name: "Sulawesi", localName: nil, divisions: [
                ("ST", "Central Sulawesi", "Sulawesi Tengah"),
                ("GO", "Gorontalo", nil),
                ("SA", "North Sulawesi", "Sulawesi Utara"),
                ("SN", "South Sulawesi", "Sulawesi Selatan"),
                ("SG", "Southeast Sulawesi", "Sulawesi Tenggara"),
                ("SR", "West Sulawesi", "Sulawesi Barat"),
            ]),
            indonesianRegion("maluku", name: "Maluku Islands", localName: "Maluku", divisions: [
                ("MA", "Maluku", nil),
                ("MU", "North Maluku", "Maluku Utara"),
            ]),
            indonesianRegion("papua", name: "Papua", localName: nil, divisions: [
                ("PT", "Central Papua", "Papua Tengah"),
                ("PE", "Highland Papua", "Papua Pegunungan"),
                ("PA", "Papua", nil),
                ("PS", "South Papua", "Papua Selatan"),
                ("PD", "Southwest Papua", "Papua Barat Daya"),
                ("PB", "West Papua", "Papua Barat"),
            ]),
        ]
    )

    private static func indonesianRegion(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "ID-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "ID-\(place.code)",
                    countryID: "ID",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "ID-\(group)",
                    flagAssetName: "id_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
