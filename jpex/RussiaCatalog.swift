import Foundation

extension CountryCatalog {
    // Russia's 83 federal subjects as listed in ISO 3166-2:RU: 21 republics, 9 krais, 46 oblasts, the federal cities
    // of Moscow and Saint Petersburg, 1 autonomous oblast and 4 autonomous okrugs, grouped by federal district.
    // IDs follow ISO 3166-2:RU. The app follows internationally recognised boundaries: Crimea and Sevastopol are
    // listed in the Ukraine collection (UA-43, UA-40), and the Ukrainian oblasts Russia claimed in 2022 are not included.
    // Flag sources and licences: RUSSIA_FLAG_SOURCES.md and RussiaFlagCredits.json.
    static let russia = Country(
        id: "RU",
        name: "Russia",
        localName: "Россия",
        divisionLabel: "Federal subjects",
        groups: [
            russianFederalDistrict("central", name: "Central", localName: "Центральный", divisions: [
                ("BEL", "Belgorod Oblast", "Белгородская область"),
                ("BRY", "Bryansk Oblast", "Брянская область"),
                ("IVA", "Ivanovo Oblast", "Ивановская область"),
                ("KLU", "Kaluga Oblast", "Калужская область"),
                ("KOS", "Kostroma Oblast", "Костромская область"),
                ("KRS", "Kursk Oblast", "Курская область"),
                ("LIP", "Lipetsk Oblast", "Липецкая область"),
                ("MOW", "Moscow", "Москва"),
                ("MOS", "Moscow Oblast", "Московская область"),
                ("ORL", "Oryol Oblast", "Орловская область"),
                ("RYA", "Ryazan Oblast", "Рязанская область"),
                ("SMO", "Smolensk Oblast", "Смоленская область"),
                ("TAM", "Tambov Oblast", "Тамбовская область"),
                ("TUL", "Tula Oblast", "Тульская область"),
                ("TVE", "Tver Oblast", "Тверская область"),
                ("VLA", "Vladimir Oblast", "Владимирская область"),
                ("VOR", "Voronezh Oblast", "Воронежская область"),
                ("YAR", "Yaroslavl Oblast", "Ярославская область"),
            ]),
            russianFederalDistrict("northwestern", name: "Northwestern", localName: "Северо-Западный", divisions: [
                ("ARK", "Arkhangelsk Oblast", "Архангельская область"),
                ("KGD", "Kaliningrad Oblast", "Калининградская область"),
                ("KR", "Karelia", "Республика Карелия"),
                ("KO", "Komi Republic", "Республика Коми"),
                ("LEN", "Leningrad Oblast", "Ленинградская область"),
                ("MUR", "Murmansk Oblast", "Мурманская область"),
                ("NEN", "Nenets Autonomous Okrug", "Ненецкий автономный округ"),
                ("NGR", "Novgorod Oblast", "Новгородская область"),
                ("PSK", "Pskov Oblast", "Псковская область"),
                ("SPE", "Saint Petersburg", "Санкт-Петербург"),
                ("VLG", "Vologda Oblast", "Вологодская область"),
            ]),
            russianFederalDistrict("southern", name: "Southern", localName: "Южный", divisions: [
                ("AD", "Adygea", "Республика Адыгея"),
                ("AST", "Astrakhan Oblast", "Астраханская область"),
                ("KL", "Kalmykia", "Республика Калмыкия"),
                ("KDA", "Krasnodar Krai", "Краснодарский край"),
                ("ROS", "Rostov Oblast", "Ростовская область"),
                ("VGG", "Volgograd Oblast", "Волгоградская область"),
            ]),
            russianFederalDistrict("north-caucasian", name: "North Caucasian", localName: "Северо-Кавказский", divisions: [
                ("CE", "Chechnya", "Чеченская Республика"),
                ("DA", "Dagestan", "Республика Дагестан"),
                ("IN", "Ingushetia", "Республика Ингушетия"),
                ("KB", "Kabardino-Balkaria", "Кабардино-Балкарская Республика"),
                ("KC", "Karachay-Cherkessia", "Карачаево-Черкесская Республика"),
                ("SE", "North Ossetia–Alania", "Республика Северная Осетия — Алания"),
                ("STA", "Stavropol Krai", "Ставропольский край"),
            ]),
            russianFederalDistrict("volga", name: "Volga", localName: "Приволжский", divisions: [
                ("BA", "Bashkortostan", "Республика Башкортостан"),
                ("CU", "Chuvashia", "Чувашская Республика — Чувашия"),
                ("KIR", "Kirov Oblast", "Кировская область"),
                ("ME", "Mari El", "Республика Марий Эл"),
                ("MO", "Mordovia", "Республика Мордовия"),
                ("NIZ", "Nizhny Novgorod Oblast", "Нижегородская область"),
                ("ORE", "Orenburg Oblast", "Оренбургская область"),
                ("PNZ", "Penza Oblast", "Пензенская область"),
                ("PER", "Perm Krai", "Пермский край"),
                ("SAM", "Samara Oblast", "Самарская область"),
                ("SAR", "Saratov Oblast", "Саратовская область"),
                ("TA", "Tatarstan", "Республика Татарстан"),
                ("UD", "Udmurtia", "Удмуртская Республика"),
                ("ULY", "Ulyanovsk Oblast", "Ульяновская область"),
            ]),
            russianFederalDistrict("ural", name: "Ural", localName: "Уральский", divisions: [
                ("CHE", "Chelyabinsk Oblast", "Челябинская область"),
                ("KHM", "Khanty-Mansi Autonomous Okrug", "Ханты-Мансийский автономный округ — Югра"),
                ("KGN", "Kurgan Oblast", "Курганская область"),
                ("SVE", "Sverdlovsk Oblast", "Свердловская область"),
                ("TYU", "Tyumen Oblast", "Тюменская область"),
                ("YAN", "Yamalo-Nenets Autonomous Okrug", "Ямало-Ненецкий автономный округ"),
            ]),
            russianFederalDistrict("siberian", name: "Siberian", localName: "Сибирский", divisions: [
                ("ALT", "Altai Krai", "Алтайский край"),
                ("AL", "Altai Republic", "Республика Алтай"),
                ("IRK", "Irkutsk Oblast", "Иркутская область"),
                ("KEM", "Kemerovo Oblast", "Кемеровская область — Кузбасс"),
                ("KK", "Khakassia", "Республика Хакасия"),
                ("KYA", "Krasnoyarsk Krai", "Красноярский край"),
                ("NVS", "Novosibirsk Oblast", "Новосибирская область"),
                ("OMS", "Omsk Oblast", "Омская область"),
                ("TOM", "Tomsk Oblast", "Томская область"),
                ("TY", "Tuva", "Республика Тыва"),
            ]),
            russianFederalDistrict("far-eastern", name: "Far Eastern", localName: "Дальневосточный", divisions: [
                ("AMU", "Amur Oblast", "Амурская область"),
                ("BU", "Buryatia", "Республика Бурятия"),
                ("CHU", "Chukotka Autonomous Okrug", "Чукотский автономный округ"),
                ("YEV", "Jewish Autonomous Oblast", "Еврейская автономная область"),
                ("KAM", "Kamchatka Krai", "Камчатский край"),
                ("KHA", "Khabarovsk Krai", "Хабаровский край"),
                ("MAG", "Magadan Oblast", "Магаданская область"),
                ("PRI", "Primorsky Krai", "Приморский край"),
                ("SA", "Sakha (Yakutia)", "Республика Саха (Якутия)"),
                ("SAK", "Sakhalin Oblast", "Сахалинская область"),
                ("ZAB", "Zabaykalsky Krai", "Забайкальский край"),
            ]),
        ]
    )

    private static func russianFederalDistrict(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "RU-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "RU-\(place.code)",
                    countryID: "RU",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "RU-\(group)",
                    flagAssetName: "ru_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
