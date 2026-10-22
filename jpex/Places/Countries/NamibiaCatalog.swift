import Foundation

extension CountryCatalog {
    // Namibia's 14 regions, including Kavango East and Kavango West (2013). IDs follow ISO 3166-2:NA.
    // No region has a flag with available artwork; every entry shows the national flag with a note. See MORE_FLAG_SOURCES_C.md.
    static let namibia = Country(
        id: "NA",
        name: "Namibia",
        localName: "Namibia",
        divisionLabel: "Regions",
        groups: [
            namibianGroup("regions", name: "Regions", localName: nil, divisions: [
                ("ER", "Erongo"),
                ("HA", "Hardap"),
                ("KA", "ǁKharas"),
                ("KE", "Kavango East"),
                ("KW", "Kavango West"),
                ("KH", "Khomas"),
                ("KU", "Kunene"),
                ("OW", "Ohangwena"),
                ("OH", "Omaheke"),
                ("OS", "Omusati"),
                ("ON", "Oshana"),
                ("OT", "Oshikoto"),
                ("OD", "Otjozondjupa"),
                ("CA", "Zambezi"),
            ]),
        ]
    )

    /// Every region shows the national flag. Four regional councils fly flags that have no freely licensed artwork.
    private static let namibianFlagNotes: [String: String] = [
        "ER": "The national flag is shown; no artwork of the Erongo Regional Council's flag is available.",
        "HA": "The national flag is shown; Hardap Region has no official flag.",
        "KA": "The national flag is shown; no artwork of the ǁKharas Regional Council's flag is available.",
        "KE": "The national flag is shown; Kavango East Region has no official flag.",
        "KW": "The national flag is shown; Kavango West Region has no official flag.",
        "KH": "The national flag is shown; no artwork of the Khomas Regional Council's flag is available.",
        "KU": "The national flag is shown; no artwork of the Kunene Regional Council's flag is available.",
        "OW": "The national flag is shown; Ohangwena Region has no official flag.",
        "OH": "The national flag is shown; Omaheke Region has no official flag.",
        "OS": "The national flag is shown; Omusati Region has no official flag.",
        "ON": "The national flag is shown; Oshana Region has no official flag.",
        "OT": "The national flag is shown; Oshikoto Region has no official flag.",
        "OD": "The national flag is shown; Otjozondjupa Region has no official flag.",
        "CA": "The national flag is shown; Zambezi Region has no official flag.",
    ]

    private static func namibianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "NA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "NA-\(place.code)",
                    countryID: "NA",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "NA-\(group)",
                    flagAssetName: "world_flag_na",
                    flagNote: namibianFlagNotes[place.code]
                )
            }
        )
    }
}
