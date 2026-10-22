import Foundation

extension CountryCatalog {
    // Algeria's 69 provinces (wilayas), grouped by planning region. DZ-01...DZ-58 follow ISO 3166-2:DZ; the 11 wilayas
    // created by Law 26-06 of 4 April 2026 (numbers and names: Presidential Decree 26-206 of 25 May 2026) are not in ISO
    // yet and use their official numbers, DZ-59...DZ-69. Each sits in its parent wilaya's planning region.
    // The wilayas have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let algeria = Country(
        id: "DZ",
        name: "Algeria",
        localName: "الجزائر",
        divisionLabel: "Provinces",
        groups: [
            algerianGroup("north-central", name: "North Central", localName: "الشمال الأوسط", divisions: [
                ("02", "Chlef", "الشلف"),
                ("06", "Béjaïa", "بجاية"),
                ("09", "Blida", "البليدة"),
                ("10", "Bouïra", "البويرة"),
                ("15", "Tizi Ouzou", "تيزي وزو"),
                ("16", "Algiers", "الجزائر"),
                ("26", "Médéa", "المدية"),
                ("35", "Boumerdès", "بومرداس"),
                ("42", "Tipaza", "تيبازة"),
                ("44", "Aïn Defla", "عين الدفلى"),
                ("67", "Ksar El Boukhari", "قصر البخاري"),
            ]),
            algerianGroup("north-east", name: "North East", localName: "الشمال الشرقي", divisions: [
                ("18", "Jijel", "جيجل"),
                ("21", "Skikda", "سكيكدة"),
                ("23", "Annaba", "عنابة"),
                ("24", "Guelma", "قالمة"),
                ("25", "Constantine", "قسنطينة"),
                ("36", "El Tarf", "الطارف"),
                ("41", "Souk Ahras", "سوق أهراس"),
                ("43", "Mila", "ميلة"),
            ]),
            algerianGroup("north-west", name: "North West", localName: "الشمال الغربي", divisions: [
                ("13", "Tlemcen", "تلمسان"),
                ("22", "Sidi Bel Abbès", "سيدي بلعباس"),
                ("27", "Mostaganem", "مستغانم"),
                ("29", "Mascara", "معسكر"),
                ("31", "Oran", "وهران"),
                ("46", "Aïn Témouchent", "عين تموشنت"),
                ("48", "Relizane", "غليزان"),
                ("63", "El Aricha", "العريشة"),
            ]),
            algerianGroup("highlands", name: "Highlands", localName: "الهضاب العليا", divisions: [
                ("03", "Laghouat", "الأغواط"),
                ("04", "Oum El Bouaghi", "أم البواقي"),
                ("05", "Batna", "باتنة"),
                ("12", "Tébessa", "تبسة"),
                ("14", "Tiaret", "تيارت"),
                ("17", "Djelfa", "الجلفة"),
                ("19", "Sétif", "سطيف"),
                ("20", "Saïda", "سعيدة"),
                ("28", "M'Sila", "المسيلة"),
                ("32", "El Bayadh", "البيض"),
                ("34", "Bordj Bou Arréridj", "برج بوعريريج"),
                ("38", "Tissemsilt", "تيسمسيلت"),
                ("40", "Khenchela", "خنشلة"),
                ("45", "Naâma", "النعامة"),
                ("59", "Aflou", "أفلو"),
                ("60", "Barika", "بريكة"),
                ("62", "Bir El Ater", "بئر العاتر"),
                ("64", "Ksar Chellala", "قصر الشلالة"),
                ("65", "Aïn Ouessara", "عين وسارة"),
                ("66", "Messaad", "مسعد"),
                ("68", "Bou Saâda", "بوسعادة"),
                ("69", "El Abiodh Sidi Cheikh", "الأبيض سيدي الشيخ"),
            ]),
            algerianGroup("south", name: "South", localName: "الجنوب", divisions: [
                ("01", "Adrar", "أدرار"),
                ("07", "Biskra", "بسكرة"),
                ("08", "Béchar", "بشار"),
                ("11", "Tamanrasset", "تمنراست"),
                ("30", "Ouargla", "ورقلة"),
                ("33", "Illizi", "إليزي"),
                ("37", "Tindouf", "تندوف"),
                ("39", "El Oued", "الوادي"),
                ("47", "Ghardaïa", "غرداية"),
                ("49", "Timimoun", "تيميمون"),
                ("50", "Bordj Badji Mokhtar", "برج باجي مختار"),
                ("51", "Ouled Djellal", "أولاد جلال"),
                ("52", "Béni Abbès", "بني عباس"),
                ("53", "In Salah", "عين صالح"),
                ("54", "In Guezzam", "عين قزام"),
                ("55", "Touggourt", "تقرت"),
                ("56", "Djanet", "جانت"),
                ("57", "El M'Ghair", "المغير"),
                ("58", "El Meniaa", "المنيعة"),
                ("61", "El Kantara", "القنطرة"),
            ]),
        ]
    )

    private static func algerianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "DZ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "DZ-\(place.code)",
                    countryID: "DZ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "DZ-\(group)",
                    flagAssetName: "world_flag_dz",
                    flagNote: "Algeria's provinces have no official flags; the national flag is shown."
                )
            }
        )
    }
}
