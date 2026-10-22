import Foundation

extension CountryCatalog {
    // Mongolia's 21 provinces (aimags) and the capital, Ulaanbaatar. IDs follow ISO 3166-2:MN.
    // Flag sources and licences: MORE_FLAG_SOURCES_3.md and MongoliaFlagCredits.json.
    static let mongolia = Country(
        id: "MN",
        name: "Mongolia",
        localName: "Монгол Улс",
        divisionLabel: "Provinces",
        groups: [
            mongolianGroup("provinces", name: "Provinces", localName: "Аймгууд", divisions: [
                ("073", "Arkhangai", "Архангай"),
                ("071", "Bayan-Ölgii", "Баян-Өлгий"),
                ("069", "Bayankhongor", "Баянхонгор"),
                ("067", "Bulgan", "Булган"),
                ("037", "Darkhan-Uul", "Дархан-Уул"),
                ("061", "Dornod", "Дорнод"),
                ("063", "Dornogovi", "Дорноговь"),
                ("059", "Dundgovi", "Дундговь"),
                ("065", "Govi-Altai", "Говь-Алтай"),
                ("064", "Govisümber", "Говьсүмбэр"),
                ("039", "Khentii", "Хэнтий"),
                ("043", "Khovd", "Ховд"),
                ("041", "Khövsgöl", "Хөвсгөл"),
                ("053", "Ömnögovi", "Өмнөговь"),
                ("035", "Orkhon", "Орхон"),
                ("055", "Övörkhangai", "Өвөрхангай"),
                ("049", "Selenge", "Сэлэнгэ"),
                ("051", "Sükhbaatar", "Сүхбаатар"),
                ("047", "Töv", "Төв"),
                ("046", "Uvs", "Увс"),
                ("057", "Zavkhan", "Завхан"),
            ]),
            mongolianGroup("capital", name: "Capital", localName: "Нийслэл", divisions: [
                ("1", "Ulaanbaatar", "Улаанбаатар"),
            ]),
        ]
    )

    private static func mongolianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "MN-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "MN-\(place.code)",
                    countryID: "MN",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "MN-\(group)",
                    flagAssetName: "mn_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
