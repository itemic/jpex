import Foundation

extension CountryCatalog {
    // Bhutan's 20 districts (dzongkhags). IDs follow ISO 3166-2:BT.
    // The districts have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let bhutan = Country(
        id: "BT",
        name: "Bhutan",
        localName: "འབྲུག་ཡུལ་",
        divisionLabel: "Districts",
        groups: [
            bhutaneseGroup("districts", name: "Districts", localName: "རྫོང་ཁག", divisions: [
                ("33", "Bumthang", "བུམ་ཐང"),
                ("12", "Chhukha", "ཆུ་ཁ"),
                ("22", "Dagana", "དར་དཀར་ནང"),
                ("GA", "Gasa", "མགར་ས"),
                ("13", "Haa", "ཧཱ"),
                ("44", "Lhuentse", "ལྷུན་རྩེ"),
                ("42", "Mongar", "མོང་སྒར"),
                ("11", "Paro", "སྤ་རོ"),
                ("43", "Pemagatshel", "པད་མ་དགའ་ཚལ"),
                ("23", "Punakha", "སྤུ་ན་ཁ"),
                ("45", "Samdrup Jongkhar", "བསམ་གྲུབ་ལྗོངས་མཁར"),
                ("14", "Samtse", "བསམ་རྩེ"),
                ("31", "Sarpang", "གསར་སྤང"),
                ("15", "Thimphu", "ཐིམ་ཕུ"),
                ("41", "Trashigang", "བཀྲ་ཤིས་སྒང"),
                ("TY", "Trashiyangtse", "བཀྲ་ཤིས་གཡང་རྩེ"),
                ("32", "Trongsa", "ཀྲོང་གསར"),
                ("21", "Tsirang", "རྩི་རང"),
                ("24", "Wangdue Phodrang", "དབང་འདུས་ཕོ་བྲང"),
                ("34", "Zhemgang", "གཞམས་སྒང"),
            ]),
        ]
    )

    private static func bhutaneseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BT-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BT-\(place.code)",
                    countryID: "BT",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BT-\(group)",
                    flagAssetName: "world_flag_bt",
                    flagNote: "Bhutan's districts have no official flags; the national flag is shown."
                )
            }
        )
    }
}
