import Foundation

extension CountryCatalog {
    // Oman's 11 governorates. IDs follow ISO 3166-2:OM.
    // The governorates have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let oman = Country(
        id: "OM",
        name: "Oman",
        localName: "عُمان",
        divisionLabel: "Governorates",
        groups: [
            omaniGroup("governorates", name: "Governorates", localName: "المحافظات", divisions: [
                ("DA", "Ad Dakhiliyah", "الداخلية"),
                ("ZA", "Ad Dhahirah", "الظاهرة"),
                ("BS", "Al Batinah North", "شمال الباطنة"),
                ("BJ", "Al Batinah South", "جنوب الباطنة"),
                ("BU", "Al Buraimi", "البريمي"),
                ("WU", "Al Wusta", "الوسطى"),
                ("SS", "Ash Sharqiyah North", "شمال الشرقية"),
                ("SJ", "Ash Sharqiyah South", "جنوب الشرقية"),
                ("ZU", "Dhofar", "ظفار"),
                ("MU", "Musandam", "مسندم"),
                ("MA", "Muscat", "مسقط"),
            ]),
        ]
    )

    private static func omaniGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "OM-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "OM-\(place.code)",
                    countryID: "OM",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "OM-\(group)",
                    flagAssetName: "world_flag_om",
                    flagNote: "Oman's governorates have no official flags; the national flag is shown."
                )
            }
        )
    }
}
