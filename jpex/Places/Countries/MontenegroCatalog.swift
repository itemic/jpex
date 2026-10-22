import Foundation

extension CountryCatalog {
    // Montenegro's 25 municipalities, including Tuzi (2018) and Zeta (2022). IDs follow ISO 3166-2:ME.
    // Local names are in Montenegrin Cyrillic. Flag sources and licences: MORE_FLAG_SOURCES_A.md and MontenegroFlagCredits.json.
    static let montenegro = Country(
        id: "ME",
        name: "Montenegro",
        localName: "Црна Гора",
        divisionLabel: "Municipalities",
        groups: [
            montenegrinGroup("municipalities", name: "Municipalities", localName: "Општине", divisions: [
                ("01", "Andrijevica", "Андријевица"),
                ("02", "Bar", "Бар"),
                ("03", "Berane", "Беране"),
                ("04", "Bijelo Polje", "Бијело Поље"),
                ("05", "Budva", "Будва"),
                ("06", "Cetinje", "Цетиње"),
                ("07", "Danilovgrad", "Даниловград"),
                ("22", "Gusinje", "Гусиње"),
                ("08", "Herceg Novi", "Херцег Нови"),
                ("09", "Kolašin", "Колашин"),
                ("10", "Kotor", "Котор"),
                ("11", "Mojkovac", "Мојковац"),
                ("12", "Nikšić", "Никшић"),
                ("23", "Petnjica", "Петњица"),
                ("13", "Plav", "Плав"),
                ("14", "Pljevlja", "Пљевља"),
                ("15", "Plužine", "Плужине"),
                ("16", "Podgorica", "Подгорица"),
                ("17", "Rožaje", "Рожаје"),
                ("18", "Šavnik", "Шавник"),
                ("19", "Tivat", "Тиват"),
                ("24", "Tuzi", "Тузи"),
                ("20", "Ulcinj", "Улцињ"),
                ("21", "Žabljak", "Жабљак"),
                ("25", "Zeta", "Зета"),
            ]),
        ]
    )

    /// Municipalities without flag artwork show the national flag.
    private static let montenegrinFlagNotes: [String: String] = [
        "25": "The national flag is shown; no artwork of a flag for Zeta, a municipality since 2022, is available.",
    ]

    private static func montenegrinGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "ME-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = montenegrinFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "ME-\(place.code)",
                    countryID: "ME",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "ME-\(group)",
                    flagAssetName: flagNote == nil ? "me_flag_\(place.code.lowercased())" : "world_flag_me",
                    flagNote: flagNote
                )
            }
        )
    }
}
