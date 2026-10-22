import Foundation

extension CountryCatalog {
    // Kuwait's six governorates. IDs follow ISO 3166-2:KW.
    // The governorates have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let kuwait = Country(
        id: "KW",
        name: "Kuwait",
        localName: "الكويت",
        divisionLabel: "Governorates",
        groups: [
            kuwaitiGroup("governorates", name: "Governorates", localName: "المحافظات", divisions: [
                ("AH", "Al Ahmadi", "الأحمدي"),
                ("JA", "Al Jahra", "الجهراء"),
                ("KU", "Capital Governorate", "محافظة العاصمة"),
                ("FA", "Farwaniya", "الفروانية"),
                ("HA", "Hawalli", "حولي"),
                ("MU", "Mubarak Al-Kabeer", "مبارك الكبير"),
            ]),
        ]
    )

    private static func kuwaitiGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "KW-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "KW-\(place.code)",
                    countryID: "KW",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "KW-\(group)",
                    flagAssetName: "world_flag_kw",
                    flagNote: "Kuwait's governorates have no official flags; the national flag is shown."
                )
            }
        )
    }
}
