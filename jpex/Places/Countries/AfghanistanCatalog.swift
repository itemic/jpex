import Foundation

extension CountryCatalog {
    // Afghanistan's 34 provinces. IDs follow ISO 3166-2:AF. Local names are Pashto.
    // The provinces have no official flags, so each shows the national flag. See MORE_FLAG_SOURCES_D.md.
    static let afghanistan = Country(
        id: "AF",
        name: "Afghanistan",
        localName: "افغانستان",
        divisionLabel: "Provinces",
        groups: [
            afghanGroup("provinces", name: "Provinces", localName: "ولایتونه", divisions: [
                ("BDS", "Badakhshan", "بدخشان"),
                ("BDG", "Badghis", "بادغیس"),
                ("BGL", "Baghlan", "بغلان"),
                ("BAL", "Balkh", "بلخ"),
                ("BAM", "Bamyan", "بامیان"),
                ("DAY", "Daikundi", "دایکنډي"),
                ("FRA", "Farah", "فراه"),
                ("FYB", "Faryab", "فاریاب"),
                ("GHA", "Ghazni", "غزني"),
                ("GHO", "Ghor", "غور"),
                ("HEL", "Helmand", "هلمند"),
                ("HER", "Herat", "هرات"),
                ("JOW", "Juzjan", "جوزجان"),
                ("KAB", "Kabul", "کابل"),
                ("KAN", "Kandahar", "کندهار"),
                ("KAP", "Kapisa", "کاپیسا"),
                ("KHO", "Khost", "خوست"),
                ("KNR", "Kunar", "کونړ"),
                ("KDZ", "Kunduz", "کندز"),
                ("LAG", "Laghman", "لغمان"),
                ("LOG", "Logar", "لوګر"),
                ("WAR", "Maidan Wardak", "میدان وردګ"),
                ("NAN", "Nangarhar", "ننګرهار"),
                ("NIM", "Nimruz", "نیمروز"),
                ("NUR", "Nuristan", "نورستان"),
                ("PIA", "Paktia", "پکتیا"),
                ("PKA", "Paktika", "پکتیکا"),
                ("PAN", "Panjshir", "پنجشېر"),
                ("PAR", "Parwan", "پروان"),
                ("SAM", "Samangan", "سمنګان"),
                ("SAR", "Sar-e-Pol", "سرپل"),
                ("TAK", "Takhar", "تخار"),
                ("URU", "Uruzgan", "روزګان"),
                ("ZAB", "Zabul", "زابل"),
            ]),
        ]
    )

    private static func afghanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "AF-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "AF-\(place.code)",
                    countryID: "AF",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "AF-\(group)",
                    flagAssetName: "world_flag_af",
                    flagNote: "Afghanistan's provinces have no official flags; the national flag is shown."
                )
            }
        )
    }
}
