import Foundation

extension CountryCatalog {
    // Iran's 31 provinces, grouped by the five regions set up by the Ministry of the Interior in 2014, each labelled
    // with the city that hosts its secretariat. IDs follow ISO 3166-2:IR as renumbered in November 2020.
    // The provinces have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let iran = Country(
        id: "IR",
        name: "Iran",
        localName: "ایران",
        divisionLabel: "Provinces",
        groups: [
            iranianGroup("region-1", name: "Region 1 (Tehran)", localName: "منطقه ۱", divisions: [
                ("30", "Alborz", "البرز"),
                ("27", "Golestan", "گلستان"),
                ("02", "Mazandaran", "مازندران"),
                ("26", "Qazvin", "قزوین"),
                ("25", "Qom", "قم"),
                ("20", "Semnan", "سمنان"),
                ("23", "Tehran", "تهران"),
            ]),
            iranianGroup("region-2", name: "Region 2 (Isfahan)", localName: "منطقه ۲", divisions: [
                ("18", "Bushehr", "بوشهر"),
                ("14", "Chaharmahal and Bakhtiari", "چهارمحال و بختیاری"),
                ("07", "Fars", "فارس"),
                ("22", "Hormozgan", "هرمزگان"),
                ("10", "Isfahan", "اصفهان"),
                ("17", "Kohgiluyeh and Boyer-Ahmad", "کهگیلویه و بویراحمد"),
            ]),
            iranianGroup("region-3", name: "Region 3 (Tabriz)", localName: "منطقه ۳", divisions: [
                ("24", "Ardabil", "اردبیل"),
                ("03", "East Azerbaijan", "آذربایجان شرقی"),
                ("01", "Gilan", "گیلان"),
                ("12", "Kurdistan", "کردستان"),
                ("04", "West Azerbaijan", "آذربایجان غربی"),
                ("19", "Zanjan", "زنجان"),
            ]),
            iranianGroup("region-4", name: "Region 4 (Kermanshah)", localName: "منطقه ۴", divisions: [
                ("13", "Hamadan", "همدان"),
                ("16", "Ilam", "ایلام"),
                ("05", "Kermanshah", "کرمانشاه"),
                ("06", "Khuzestan", "خوزستان"),
                ("15", "Lorestan", "لرستان"),
                ("00", "Markazi", "مرکزی"),
            ]),
            iranianGroup("region-5", name: "Region 5 (Mashhad)", localName: "منطقه ۵", divisions: [
                ("08", "Kerman", "کرمان"),
                ("28", "North Khorasan", "خراسان شمالی"),
                ("09", "Razavi Khorasan", "خراسان رضوی"),
                ("11", "Sistan and Baluchestan", "سیستان و بلوچستان"),
                ("29", "South Khorasan", "خراسان جنوبی"),
                ("21", "Yazd", "یزد"),
            ]),
        ]
    )

    private static func iranianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "IR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "IR-\(place.code)",
                    countryID: "IR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "IR-\(group)",
                    flagAssetName: "world_flag_ir",
                    flagNote: "Iran's provinces have no official flags; the national flag is shown."
                )
            }
        )
    }
}
