import Foundation

extension CountryCatalog {
    // Tunisia's 24 governorates, grouped by economic region. IDs follow ISO 3166-2:TN.
    // The governorates have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let tunisia = Country(
        id: "TN",
        name: "Tunisia",
        localName: "تونس",
        divisionLabel: "Governorates",
        groups: [
            tunisianGroup("greater-tunis", name: "Greater Tunis", localName: "تونس الكبرى", divisions: [
                ("11", "Tunis", "تونس"),
                ("12", "Ariana", "أريانة"),
                ("13", "Ben Arous", "بن عروس"),
                ("14", "Manouba", "منوبة"),
            ]),
            tunisianGroup("north-east", name: "North East", localName: "الشمال الشرقي", divisions: [
                ("21", "Nabeul", "نابل"),
                ("22", "Zaghouan", "زغوان"),
                ("23", "Bizerte", "بنزرت"),
            ]),
            tunisianGroup("north-west", name: "North West", localName: "الشمال الغربي", divisions: [
                ("31", "Béja", "باجة"),
                ("32", "Jendouba", "جندوبة"),
                ("33", "Kef", "الكاف"),
                ("34", "Siliana", "سليانة"),
            ]),
            tunisianGroup("centre-east", name: "Centre East", localName: "الوسط الشرقي", divisions: [
                ("51", "Sousse", "سوسة"),
                ("52", "Monastir", "المنستير"),
                ("53", "Mahdia", "المهدية"),
                ("61", "Sfax", "صفاقس"),
            ]),
            tunisianGroup("centre-west", name: "Centre West", localName: "الوسط الغربي", divisions: [
                ("41", "Kairouan", "القيروان"),
                ("42", "Kasserine", "القصرين"),
                ("43", "Sidi Bouzid", "سيدي بوزيد"),
            ]),
            tunisianGroup("south-east", name: "South East", localName: "الجنوب الشرقي", divisions: [
                ("81", "Gabès", "قابس"),
                ("82", "Medenine", "مدنين"),
                ("83", "Tataouine", "تطاوين"),
            ]),
            tunisianGroup("south-west", name: "South West", localName: "الجنوب الغربي", divisions: [
                ("71", "Gafsa", "قفصة"),
                ("72", "Tozeur", "توزر"),
                ("73", "Kebili", "قبلي"),
            ]),
        ]
    )

    private static func tunisianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TN-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "TN-\(place.code)",
                    countryID: "TN",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TN-\(group)",
                    flagAssetName: "world_flag_tn",
                    flagNote: "Tunisia's governorates have no official flags; the national flag is shown."
                )
            }
        )
    }
}
