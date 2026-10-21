import Foundation

extension CountryCatalog {
    // Myanmar's seven regions, seven states and Nay Pyi Taw Union Territory, as in the 2008 Constitution.
    // IDs follow ISO 3166-2:MM. Local names are Burmese. Flag sources and licences: MORE_FLAG_SOURCES_D.md
    // and MyanmarFlagCredits.json.
    static let myanmar = Country(
        id: "MM",
        name: "Myanmar",
        localName: "မြန်မာ",
        divisionLabel: "Regions & states",
        groups: [
            burmeseGroup("regions", name: "Regions", localName: "တိုင်းဒေသကြီးများ", divisions: [
                ("07", "Ayeyarwady", "ဧရာဝတီတိုင်းဒေသကြီး"),
                ("02", "Bago", "ပဲခူးတိုင်းဒေသကြီး"),
                ("03", "Magway", "မကွေးတိုင်းဒေသကြီး"),
                ("04", "Mandalay", "မန္တလေးတိုင်းဒေသကြီး"),
                ("01", "Sagaing", "စစ်ကိုင်းတိုင်းဒေသကြီး"),
                ("05", "Tanintharyi", "တနင်္သာရီတိုင်းဒေသကြီး"),
                ("06", "Yangon", "ရန်ကုန်တိုင်းဒေသကြီး"),
            ]),
            burmeseGroup("states", name: "States", localName: "ပြည်နယ်များ", divisions: [
                ("14", "Chin", "ချင်းပြည်နယ်"),
                ("11", "Kachin", "ကချင်ပြည်နယ်"),
                ("12", "Kayah", "ကယားပြည်နယ်"),
                ("13", "Kayin", "ကရင်ပြည်နယ်"),
                ("15", "Mon", "မွန်ပြည်နယ်"),
                ("16", "Rakhine", "ရခိုင်ပြည်နယ်"),
                ("17", "Shan", "ရှမ်းပြည်နယ်"),
            ]),
            burmeseGroup("union-territory", name: "Union territory", localName: "ပြည်ထောင်စုနယ်မြေ", divisions: [
                ("18", "Nay Pyi Taw", "နေပြည်တော် ပြည်ထောင်စုနယ်မြေ"),
            ]),
        ]
    )

    /// Places without a flag of their own here show the national flag.
    private static let burmeseFlagNotes: [String: String] = [
        "05": "The national flag is shown; no accurate artwork of Tanintharyi Region's flag is available.",
    ]

    private static func burmeseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "MM-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = burmeseFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "MM-\(place.code)",
                    countryID: "MM",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "MM-\(group)",
                    flagAssetName: flagNote == nil ? "mm_flag_\(place.code.lowercased())" : "world_flag_mm",
                    flagNote: flagNote
                )
            }
        )
    }
}
