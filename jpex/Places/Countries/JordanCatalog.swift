import Foundation

extension CountryCatalog {
    // Jordan's 12 governorates, grouped by the three regions (aqalim) used for planning: North, Central and South.
    // IDs follow ISO 3166-2:JO. The governorates have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let jordan = Country(
        id: "JO",
        name: "Jordan",
        localName: "الأردن",
        divisionLabel: "Governorates",
        groups: [
            jordanianGroup("north", name: "North", localName: "إقليم الشمال", divisions: [
                ("AJ", "Ajloun", "عجلون"),
                ("IR", "Irbid", "إربد"),
                ("JA", "Jerash", "جرش"),
                ("MA", "Mafraq", "المفرق"),
            ]),
            jordanianGroup("central", name: "Central", localName: "إقليم الوسط", divisions: [
                ("AM", "Amman", "العاصمة"),
                ("BA", "Balqa", "البلقاء"),
                ("MD", "Madaba", "مادبا"),
                ("AZ", "Zarqa", "الزرقاء"),
            ]),
            jordanianGroup("south", name: "South", localName: "إقليم الجنوب", divisions: [
                ("AQ", "Aqaba", "العقبة"),
                ("KA", "Karak", "الكرك"),
                ("MN", "Ma'an", "معان"),
                ("AT", "Tafilah", "الطفيلة"),
            ]),
        ]
    )

    private static func jordanianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "JO-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "JO-\(place.code)",
                    countryID: "JO",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "JO-\(group)",
                    flagAssetName: "world_flag_jo",
                    flagNote: "Jordan's governorates have no official flags; the national flag is shown."
                )
            }
        )
    }
}
