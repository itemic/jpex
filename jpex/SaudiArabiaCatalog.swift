import Foundation

extension CountryCatalog {
    // Saudi Arabia's 13 regions (provinces). IDs follow ISO 3166-2:SA, which has no SA-13.
    // The regions have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_3.md.
    static let saudiArabia = Country(
        id: "SA",
        name: "Saudi Arabia",
        localName: "السعودية",
        divisionLabel: "Regions",
        groups: [
            saudiGroup("regions", name: "Regions", localName: "المناطق", divisions: [
                ("11", "Al-Baha", "الباحة"),
                ("12", "Al-Jouf", "الجوف"),
                ("05", "Al-Qassim", "القصيم"),
                ("14", "Asir", "عسير"),
                ("04", "Eastern Province", "المنطقة الشرقية"),
                ("06", "Hail", "حائل"),
                ("09", "Jazan", "جازان"),
                ("02", "Mecca", "مكة المكرمة"),
                ("03", "Medina", "المدينة المنورة"),
                ("10", "Najran", "نجران"),
                ("08", "Northern Borders", "الحدود الشمالية"),
                ("01", "Riyadh", "الرياض"),
                ("07", "Tabuk", "تبوك"),
            ]),
        ]
    )

    private static func saudiGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "SA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "SA-\(place.code)",
                    countryID: "SA",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "SA-\(group)",
                    flagAssetName: "world_flag_sa",
                    flagNote: "Saudi Arabia's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
