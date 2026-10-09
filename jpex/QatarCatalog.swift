import Foundation

extension CountryCatalog {
    // Qatar's eight municipalities, including Al Shahaniya (split from Al Rayyan in 2014). IDs follow ISO 3166-2:QA.
    // The municipalities have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let qatar = Country(
        id: "QA",
        name: "Qatar",
        localName: "قطر",
        divisionLabel: "Municipalities",
        groups: [
            qatariGroup("municipalities", name: "Municipalities", localName: "البلديات", divisions: [
                ("ZA", "Al Daayen", "الضعاين"),
                ("KH", "Al Khor and Al Thakhira", "الخور والذخيرة"),
                ("RA", "Al Rayyan", "الريان"),
                ("SH", "Al Shahaniya", "الشحانية"),
                ("MS", "Al Shamal", "الشمال"),
                ("WA", "Al Wakrah", "الوكرة"),
                ("DA", "Doha", "الدوحة"),
                ("US", "Umm Salal", "أم صلال"),
            ]),
        ]
    )

    private static func qatariGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "QA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "QA-\(place.code)",
                    countryID: "QA",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "QA-\(group)",
                    flagAssetName: "world_flag_qa",
                    flagNote: "Qatar's municipalities have no official flags; the national flag is shown."
                )
            }
        )
    }
}
