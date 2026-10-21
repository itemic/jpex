import Foundation

extension CountryCatalog {
    // Tajikistan's regions, the districts under central government jurisdiction (TJ-RA), Gorno-Badakhshan
    // and the capital, Dushanbe. IDs follow ISO 3166-2:TJ. Local names are Tajik. None has an official flag,
    // so each shows the national flag; see MORE_FLAG_SOURCES_D.md.
    static let tajikistan = Country(
        id: "TJ",
        name: "Tajikistan",
        localName: "Тоҷикистон",
        divisionLabel: "Regions",
        groups: [
            tajikGroup("regions", name: "Regions", localName: "Вилоятҳо", divisions: [
                ("RA", "Districts under Central Government Jurisdiction", "Ноҳияҳои тобеи ҷумҳурӣ"),
                ("KT", "Khatlon", "Вилояти Хатлон"),
                ("SU", "Sughd", "Вилояти Суғд"),
            ]),
            tajikGroup("autonomous-region", name: "Autonomous region", localName: "Вилояти мухтор", divisions: [
                ("GB", "Gorno-Badakhshan", "Вилояти Мухтори Кӯҳистони Бадахшон"),
            ]),
            tajikGroup("capital", name: "Capital", localName: "Пойтахт", divisions: [
                ("DU", "Dushanbe", "Душанбе"),
            ]),
        ]
    )

    private static func tajikGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TJ-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "TJ-\(place.code)",
                    countryID: "TJ",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TJ-\(group)",
                    flagAssetName: "world_flag_tj",
                    flagNote: "Tajikistan's regions and capital have no official flags; the national flag is shown."
                )
            }
        )
    }
}
