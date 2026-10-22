import Foundation

extension CountryCatalog {
    // Taiwan's 22 cities and counties: six special municipalities, three provincial cities and 13 counties.
    // IDs follow ISO 3166-2:TW. Flag sources and licences: MORE_FLAG_SOURCES.md and TaiwanFlagCredits.json.
    static let taiwan = Country(
        id: "TW",
        name: "Taiwan",
        localName: "臺灣",
        divisionLabel: "Cities & counties",
        groups: [
            taiwaneseGroup("municipalities", name: "Special municipalities", localName: "直轄市", divisions: [
                ("TPE", "Taipei", "臺北市"),
                ("NWT", "New Taipei", "新北市"),
                ("TAO", "Taoyuan", "桃園市"),
                ("TXG", "Taichung", "臺中市"),
                ("TNN", "Tainan", "臺南市"),
                ("KHH", "Kaohsiung", "高雄市"),
            ]),
            taiwaneseGroup("cities", name: "Provincial cities", localName: "市", divisions: [
                ("KEE", "Keelung", "基隆市"),
                ("HSZ", "Hsinchu City", "新竹市"),
                ("CYI", "Chiayi City", "嘉義市"),
            ]),
            taiwaneseGroup("counties", name: "Counties", localName: "縣", divisions: [
                ("HSQ", "Hsinchu County", "新竹縣"),
                ("MIA", "Miaoli", "苗栗縣"),
                ("CHA", "Changhua", "彰化縣"),
                ("NAN", "Nantou", "南投縣"),
                ("YUN", "Yunlin", "雲林縣"),
                ("CYQ", "Chiayi County", "嘉義縣"),
                ("PIF", "Pingtung", "屏東縣"),
                ("ILA", "Yilan", "宜蘭縣"),
                ("HUA", "Hualien", "花蓮縣"),
                ("TTT", "Taitung", "臺東縣"),
                ("PEN", "Penghu", "澎湖縣"),
                ("KIN", "Kinmen", "金門縣"),
                ("LIE", "Lienchiang", "連江縣"),
            ]),
        ]
    )

    private static func taiwaneseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "TW-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "TW-\(place.code)",
                    countryID: "TW",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "TW-\(group)",
                    flagAssetName: "tw_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
