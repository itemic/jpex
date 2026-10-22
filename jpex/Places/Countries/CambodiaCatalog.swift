import Foundation

extension CountryCatalog {
    // Cambodia's capital, Phnom Penh, and its 24 provinces, including Tbong Khmum (split from Kampong Cham in 2013).
    // IDs follow ISO 3166-2:KH. None has an official flag, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let cambodia = Country(
        id: "KH",
        name: "Cambodia",
        localName: "កម្ពុជា",
        divisionLabel: "Provinces",
        groups: [
            cambodianGroup("capital", name: "Capital", localName: "រាជធានី", divisions: [
                ("12", "Phnom Penh", "ភ្នំពេញ"),
            ]),
            cambodianGroup("provinces", name: "Provinces", localName: "ខេត្ត", divisions: [
                ("1", "Banteay Meanchey", "បន្ទាយមានជ័យ"),
                ("2", "Battambang", "បាត់ដំបង"),
                ("3", "Kampong Cham", "កំពង់ចាម"),
                ("4", "Kampong Chhnang", "កំពង់ឆ្នាំង"),
                ("5", "Kampong Speu", "កំពង់ស្ពឺ"),
                ("6", "Kampong Thom", "កំពង់ធំ"),
                ("7", "Kampot", "កំពត"),
                ("8", "Kandal", "កណ្ដាល"),
                ("23", "Kep", "កែប"),
                ("9", "Koh Kong", "កោះកុង"),
                ("10", "Kratié", "ក្រចេះ"),
                ("11", "Mondulkiri", "មណ្ឌលគិរី"),
                ("22", "Oddar Meanchey", "ឧត្ដរមានជ័យ"),
                ("24", "Pailin", "ប៉ៃលិន"),
                ("18", "Preah Sihanouk", "ព្រះសីហនុ"),
                ("13", "Preah Vihear", "ព្រះវិហារ"),
                ("14", "Prey Veng", "ព្រៃវែង"),
                ("15", "Pursat", "ពោធិ៍សាត់"),
                ("16", "Ratanakiri", "រតនគិរី"),
                ("17", "Siem Reap", "សៀមរាប"),
                ("19", "Stung Treng", "ស្ទឹងត្រែង"),
                ("20", "Svay Rieng", "ស្វាយរៀង"),
                ("21", "Takéo", "តាកែវ"),
                ("25", "Tbong Khmum", "ត្បូងឃ្មុំ"),
            ]),
        ]
    )

    private static func cambodianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "KH-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "KH-\(place.code)",
                    countryID: "KH",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "KH-\(group)",
                    flagAssetName: "world_flag_kh",
                    flagNote: "Cambodia's provinces and capital have no official flags; the national flag is shown."
                )
            }
        )
    }
}
