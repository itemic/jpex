import Foundation

extension CountryCatalog {
    // Ukraine's 24 oblasts, the cities with special status Kyiv and Sevastopol, and the Autonomous Republic of
    // Crimea. IDs follow ISO 3166-2:UA. Flag sources and licences: MORE_FLAG_SOURCES_3.md and UkraineFlagCredits.json.
    static let ukraine = Country(
        id: "UA",
        name: "Ukraine",
        localName: "Україна",
        divisionLabel: "Oblasts",
        groups: [
            ukrainianGroup("oblasts", name: "Oblasts", localName: "Області", divisions: [
                ("71", "Cherkasy", "Черкаська область"),
                ("74", "Chernihiv", "Чернігівська область"),
                ("77", "Chernivtsi", "Чернівецька область"),
                ("12", "Dnipropetrovsk", "Дніпропетровська область"),
                ("14", "Donetsk", "Донецька область"),
                ("26", "Ivano-Frankivsk", "Івано-Франківська область"),
                ("63", "Kharkiv", "Харківська область"),
                ("65", "Kherson", "Херсонська область"),
                ("68", "Khmelnytskyi", "Хмельницька область"),
                ("35", "Kirovohrad", "Кіровоградська область"),
                ("32", "Kyiv Oblast", "Київська область"),
                ("09", "Luhansk", "Луганська область"),
                ("46", "Lviv", "Львівська область"),
                ("48", "Mykolaiv", "Миколаївська область"),
                ("51", "Odesa", "Одеська область"),
                ("53", "Poltava", "Полтавська область"),
                ("56", "Rivne", "Рівненська область"),
                ("59", "Sumy", "Сумська область"),
                ("61", "Ternopil", "Тернопільська область"),
                ("05", "Vinnytsia", "Вінницька область"),
                ("07", "Volyn", "Волинська область"),
                ("21", "Zakarpattia", "Закарпатська область"),
                ("23", "Zaporizhzhia", "Запорізька область"),
                ("18", "Zhytomyr", "Житомирська область"),
            ]),
            ukrainianGroup("cities", name: "Cities", localName: "Міста", divisions: [
                ("30", "Kyiv", "Київ"),
                ("40", "Sevastopol", "Севастополь"),
            ]),
            ukrainianGroup("autonomous-republic", name: "Autonomous Republic", localName: "Автономна Республіка", divisions: [
                ("43", "Crimea", "Автономна Республіка Крим"),
            ]),
        ]
    )

    private static func ukrainianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "UA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "UA-\(place.code)",
                    countryID: "UA",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "UA-\(group)",
                    flagAssetName: "ua_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
