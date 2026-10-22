import Foundation

extension CountryCatalog {
    // Türkiye's 81 provinces, grouped into the seven geographical regions. IDs follow ISO 3166-2:TR.
    // Provinces have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_2.md.
    static let turkey = Country(
        id: "TR",
        name: "Türkiye",
        localName: "Türkiye",
        divisionLabel: "Provinces",
        groups: [
            turkishRegion("marmara", name: "Marmara", localName: nil, divisions: [
                ("10", "Balıkesir", nil),
                ("11", "Bilecik", nil),
                ("16", "Bursa", nil),
                ("17", "Çanakkale", nil),
                ("22", "Edirne", nil),
                ("34", "Istanbul", "İstanbul"),
                ("39", "Kırklareli", nil),
                ("41", "Kocaeli", nil),
                ("54", "Sakarya", nil),
                ("59", "Tekirdağ", nil),
                ("77", "Yalova", nil),
            ]),
            turkishRegion("aegean", name: "Aegean", localName: "Ege", divisions: [
                ("03", "Afyonkarahisar", nil),
                ("09", "Aydın", nil),
                ("20", "Denizli", nil),
                ("35", "Izmir", "İzmir"),
                ("43", "Kütahya", nil),
                ("45", "Manisa", nil),
                ("48", "Muğla", nil),
                ("64", "Uşak", nil),
            ]),
            turkishRegion("mediterranean", name: "Mediterranean", localName: "Akdeniz", divisions: [
                ("01", "Adana", nil),
                ("07", "Antalya", nil),
                ("15", "Burdur", nil),
                ("31", "Hatay", nil),
                ("32", "Isparta", nil),
                ("46", "Kahramanmaraş", nil),
                ("33", "Mersin", nil),
                ("80", "Osmaniye", nil),
            ]),
            turkishRegion("central-anatolia", name: "Central Anatolia", localName: "İç Anadolu", divisions: [
                ("68", "Aksaray", nil),
                ("06", "Ankara", nil),
                ("18", "Çankırı", nil),
                ("26", "Eskişehir", nil),
                ("70", "Karaman", nil),
                ("38", "Kayseri", nil),
                ("71", "Kırıkkale", nil),
                ("40", "Kırşehir", nil),
                ("42", "Konya", nil),
                ("50", "Nevşehir", nil),
                ("51", "Niğde", nil),
                ("58", "Sivas", nil),
                ("66", "Yozgat", nil),
            ]),
            turkishRegion("black-sea", name: "Black Sea", localName: "Karadeniz", divisions: [
                ("05", "Amasya", nil),
                ("08", "Artvin", nil),
                ("74", "Bartın", nil),
                ("69", "Bayburt", nil),
                ("14", "Bolu", nil),
                ("19", "Çorum", nil),
                ("81", "Düzce", nil),
                ("28", "Giresun", nil),
                ("29", "Gümüşhane", nil),
                ("78", "Karabük", nil),
                ("37", "Kastamonu", nil),
                ("52", "Ordu", nil),
                ("53", "Rize", nil),
                ("55", "Samsun", nil),
                ("57", "Sinop", nil),
                ("60", "Tokat", nil),
                ("61", "Trabzon", nil),
                ("67", "Zonguldak", nil),
            ]),
            turkishRegion("eastern-anatolia", name: "Eastern Anatolia", localName: "Doğu Anadolu", divisions: [
                ("04", "Ağrı", nil),
                ("75", "Ardahan", nil),
                ("12", "Bingöl", nil),
                ("13", "Bitlis", nil),
                ("23", "Elazığ", nil),
                ("24", "Erzincan", nil),
                ("25", "Erzurum", nil),
                ("30", "Hakkâri", nil),
                ("76", "Iğdır", nil),
                ("36", "Kars", nil),
                ("44", "Malatya", nil),
                ("49", "Muş", nil),
                ("62", "Tunceli", nil),
                ("65", "Van", nil),
            ]),
            turkishRegion("southeastern-anatolia", name: "Southeastern Anatolia", localName: "Güneydoğu Anadolu", divisions: [
                ("02", "Adıyaman", nil),
                ("72", "Batman", nil),
                ("21", "Diyarbakır", nil),
                ("27", "Gaziantep", nil),
                ("79", "Kilis", nil),
                ("47", "Mardin", nil),
                ("63", "Şanlıurfa", nil),
                ("56", "Siirt", nil),
                ("73", "Şırnak", nil),
            ]),
        ]
    )

    private static func turkishRegion(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "TR-\(place.code)",
                    countryID: "TR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TR-\(group)",
                    flagAssetName: "world_flag_tr",
                    flagNote: "Turkey's provinces have no official flags; the national flag is shown."
                )
            }
        )
    }
}
