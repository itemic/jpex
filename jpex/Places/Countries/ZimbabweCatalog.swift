import Foundation

extension CountryCatalog {
    // Zimbabwe's eight provinces and the metropolitan provinces of Bulawayo and Harare. IDs follow
    // ISO 3166-2:ZW. None has an official flag, so each shows the national flag. See MORE_FLAG_SOURCES_D.md.
    static let zimbabwe = Country(
        id: "ZW",
        name: "Zimbabwe",
        localName: "Zimbabwe",
        divisionLabel: "Provinces",
        groups: [
            zimbabweanGroup("provinces", name: "Provinces", localName: nil, divisions: [
                ("MA", "Manicaland", nil),
                ("MC", "Mashonaland Central", nil),
                ("ME", "Mashonaland East", nil),
                ("MW", "Mashonaland West", nil),
                ("MV", "Masvingo", nil),
                ("MN", "Matabeleland North", nil),
                ("MS", "Matabeleland South", nil),
                ("MI", "Midlands", nil),
            ]),
            zimbabweanGroup("metropolitan", name: "Metropolitan provinces", localName: nil, divisions: [
                ("BU", "Bulawayo", nil),
                ("HA", "Harare", nil),
            ]),
        ]
    )

    /// Every place shows the national flag, for the reason given.
    private static let zimbabweanFlagNotes: [String: String] = [
        "MA": "The national flag is shown; Manicaland Province has no official flag.",
        "MC": "The national flag is shown; Mashonaland Central Province has no official flag.",
        "ME": "The national flag is shown; Mashonaland East Province has no official flag.",
        "MW": "The national flag is shown; Mashonaland West Province has no official flag.",
        "MV": "The national flag is shown; Masvingo Province has no official flag.",
        "MN": "The national flag is shown; Matabeleland North Province has no official flag.",
        "MS": "The national flag is shown; Matabeleland South Province has no official flag.",
        "MI": "The national flag is shown; Midlands Province has no official flag.",
        "BU": "The national flag is shown; Bulawayo Metropolitan Province has no official flag.",
        "HA": "The national flag is shown; Harare Metropolitan Province has no official flag.",
    ]

    private static func zimbabweanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "ZW-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "ZW-\(place.code)",
                    countryID: "ZW",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "ZW-\(group)",
                    flagAssetName: "world_flag_zw",
                    flagNote: zimbabweanFlagNotes[place.code]
                )
            }
        )
    }
}
