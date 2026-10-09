import Foundation

extension CountryCatalog {
    // Bahrain's four governorates (the Central Governorate was abolished in 2014). IDs follow ISO 3166-2:BH,
    // which has no BH-16. The governorates have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let bahrain = Country(
        id: "BH",
        name: "Bahrain",
        localName: "البحرين",
        divisionLabel: "Governorates",
        groups: [
            bahrainiGroup("governorates", name: "Governorates", localName: "المحافظات", divisions: [
                ("13", "Capital Governorate", "محافظة العاصمة"),
                ("15", "Muharraq", "المحرق"),
                ("17", "Northern Governorate", "المحافظة الشمالية"),
                ("14", "Southern Governorate", "المحافظة الجنوبية"),
            ]),
        ]
    )

    private static func bahrainiGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BH-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BH-\(place.code)",
                    countryID: "BH",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BH-\(group)",
                    flagAssetName: "world_flag_bh",
                    flagNote: "Bahrain's governorates have no official flags; the national flag is shown."
                )
            }
        )
    }
}
