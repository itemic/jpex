import Foundation

extension CountryCatalog {
    // Bulgaria's 28 provinces (oblasti), including Sofia City. IDs follow ISO 3166-2:BG.
    // The provinces have no official flags (the flags of their capital cities belong to the municipalities),
    // so every entry shows the national flag with a note. See MORE_FLAG_SOURCES_3.md.
    static let bulgaria = Country(
        id: "BG",
        name: "Bulgaria",
        localName: "България",
        divisionLabel: "Provinces",
        groups: [
            bulgarianGroup("provinces", name: "Provinces", localName: "Области", divisions: [
                ("01", "Blagoevgrad", "Благоевград"),
                ("02", "Burgas", "Бургас"),
                ("08", "Dobrich", "Добрич"),
                ("07", "Gabrovo", "Габрово"),
                ("26", "Haskovo", "Хасково"),
                ("09", "Kardzhali", "Кърджали"),
                ("10", "Kyustendil", "Кюстендил"),
                ("11", "Lovech", "Ловеч"),
                ("12", "Montana", "Монтана"),
                ("13", "Pazardzhik", "Пазарджик"),
                ("14", "Pernik", "Перник"),
                ("15", "Pleven", "Плевен"),
                ("16", "Plovdiv", "Пловдив"),
                ("17", "Razgrad", "Разград"),
                ("18", "Ruse", "Русе"),
                ("27", "Shumen", "Шумен"),
                ("19", "Silistra", "Силистра"),
                ("20", "Sliven", "Сливен"),
                ("21", "Smolyan", "Смолян"),
                ("22", "Sofia City", "София-град"),
                ("23", "Sofia Province", "Софийска област"),
                ("24", "Stara Zagora", "Стара Загора"),
                ("25", "Targovishte", "Търговище"),
                ("03", "Varna", "Варна"),
                ("04", "Veliko Tarnovo", "Велико Търново"),
                ("05", "Vidin", "Видин"),
                ("06", "Vratsa", "Враца"),
                ("28", "Yambol", "Ямбол"),
            ]),
        ]
    )

    /// The provinces have no official flags. "Sofia Province" already carries the type word.
    private static func bulgarianFlagNote(_ name: String) -> String {
        let province = name.hasSuffix(" Province") ? name : "\(name) Province"
        return "The national flag is shown; \(province) has no official flag."
    }

    private static func bulgarianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BG-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BG-\(place.code)",
                    countryID: "BG",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BG-\(group)",
                    flagAssetName: "world_flag_bg",
                    flagNote: bulgarianFlagNote(place.name)
                )
            }
        )
    }
}
