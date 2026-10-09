import Foundation

extension CountryCatalog {
    // Kenya's 47 counties, grouped by the former provinces they belonged to before 2013. IDs follow ISO 3166-2:KE,
    // whose numbers are alphabetical rather than the constitutional county numbers.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and KenyaFlagCredits.json.
    static let kenya = Country(
        id: "KE",
        name: "Kenya",
        localName: "Kenya",
        divisionLabel: "Counties",
        groups: [
            kenyanGroup("coast", name: "Coast", localName: nil, divisions: [
                ("14", "Kilifi"),
                ("19", "Kwale"),
                ("21", "Lamu"),
                ("28", "Mombasa"),
                ("39", "Taita-Taveta"),
                ("40", "Tana River"),
            ]),
            kenyanGroup("north-eastern", name: "North Eastern", localName: nil, divisions: [
                ("07", "Garissa"),
                ("24", "Mandera"),
                ("46", "Wajir"),
            ]),
            kenyanGroup("eastern", name: "Eastern", localName: nil, divisions: [
                ("06", "Embu"),
                ("09", "Isiolo"),
                ("18", "Kitui"),
                ("22", "Machakos"),
                ("23", "Makueni"),
                ("25", "Marsabit"),
                ("26", "Meru"),
                ("41", "Tharaka-Nithi"),
            ]),
            kenyanGroup("central", name: "Central", localName: nil, divisions: [
                ("13", "Kiambu"),
                ("15", "Kirinyaga"),
                ("29", "Murang'a"),
                ("35", "Nyandarua"),
                ("36", "Nyeri"),
            ]),
            kenyanGroup("rift-valley", name: "Rift Valley", localName: nil, divisions: [
                ("01", "Baringo"),
                ("02", "Bomet"),
                ("05", "Elgeyo-Marakwet"),
                ("10", "Kajiado"),
                ("12", "Kericho"),
                ("20", "Laikipia"),
                ("31", "Nakuru"),
                ("32", "Nandi"),
                ("33", "Narok"),
                ("37", "Samburu"),
                ("42", "Trans-Nzoia"),
                ("43", "Turkana"),
                ("44", "Uasin Gishu"),
                ("47", "West Pokot"),
            ]),
            kenyanGroup("western", name: "Western", localName: nil, divisions: [
                ("03", "Bungoma"),
                ("04", "Busia"),
                ("11", "Kakamega"),
                ("45", "Vihiga"),
            ]),
            kenyanGroup("nyanza", name: "Nyanza", localName: nil, divisions: [
                ("08", "Homa Bay"),
                ("16", "Kisii"),
                ("17", "Kisumu"),
                ("27", "Migori"),
                ("34", "Nyamira"),
                ("38", "Siaya"),
            ]),
            kenyanGroup("nairobi", name: "Nairobi", localName: nil, divisions: [
                ("30", "Nairobi"),
            ]),
        ]
    )

    private static func kenyanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "KE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "KE-\(place.code)",
                    countryID: "KE",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "KE-\(group)",
                    flagAssetName: "ke_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
