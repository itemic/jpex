import Foundation

extension CountryCatalog {
    // The seven emirates of the United Arab Emirates. IDs follow ISO 3166-2:AE.
    // Sharjah and Ras Al Khaimah share one flag, as do Dubai and Ajman. Fujairah has used the national flag
    // since 1975. Flag sources and licences: MORE_FLAG_SOURCES_2.md and UAEFlagCredits.json.
    static let unitedArabEmirates = Country(
        id: "AE",
        name: "United Arab Emirates",
        localName: "الإمارات",
        divisionLabel: "Emirates",
        groups: [
            emiratiGroup("emirates", name: "Emirates", localName: "الإمارات", divisions: [
                ("AZ", "Abu Dhabi", "أبو ظبي"),
                ("AJ", "Ajman", "عجمان"),
                ("DU", "Dubai", "دبي"),
                ("FU", "Fujairah", "الفجيرة"),
                ("RK", "Ras Al Khaimah", "رأس الخيمة"),
                ("SH", "Sharjah", "الشارقة"),
                ("UQ", "Umm Al Quwain", "أم القيوين"),
            ]),
        ]
    )

    private static func emiratiGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "AE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "AE-\(place.code)",
                    countryID: "AE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "AE-\(group)",
                    flagAssetName: place.code == "FU" ? "world_flag_ae" : "ae_flag_\(place.code.lowercased())",
                    flagNote: place.code == "FU"
                        ? "The national flag is shown; Fujairah has used it in place of an emirate flag since 1975."
                        : nil
                )
            }
        )
    }
}
