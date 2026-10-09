import Foundation

extension CountryCatalog {
    // Iceland's eight regions (landshlutar), in their official order. IDs follow ISO 3166-2:IS.
    // The regions have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_3.md.
    static let iceland = Country(
        id: "IS",
        name: "Iceland",
        localName: "Ísland",
        divisionLabel: "Regions",
        groups: [
            icelandicGroup("regions", name: "Regions", localName: "Landshlutar", divisions: [
                ("1", "Capital Region", "Höfuðborgarsvæðið"),
                ("2", "Southern Peninsula", "Suðurnes"),
                ("3", "Western Region", "Vesturland"),
                ("4", "Westfjords", "Vestfirðir"),
                ("5", "Northwestern Region", "Norðurland vestra"),
                ("6", "Northeastern Region", "Norðurland eystra"),
                ("7", "Eastern Region", "Austurland"),
                ("8", "Southern Region", "Suðurland"),
            ]),
        ]
    )

    private static func icelandicGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "IS-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "IS-\(place.code)",
                    countryID: "IS",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "IS-\(group)",
                    flagAssetName: "world_flag_is",
                    flagNote: "Iceland's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
