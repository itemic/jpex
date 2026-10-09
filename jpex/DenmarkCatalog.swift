import Foundation

extension CountryCatalog {
    // Denmark's regions. IDs follow ISO 3166-2:DK. The Capital Region (DK-84) and Zealand (DK-85) merge into
    // Region East Denmark on 1 January 2027; from that day the list shows it as DK-EAST, its maps come
    // from map_DK-2027.json, and levels set on the two carry over to it (see PlaceReorganisation).
    // Regions have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_2.md.
    static let denmark = Country(
        id: "DK",
        name: "Denmark",
        localName: "Danmark",
        divisionLabel: "Regions",
        groups: [
            danishGroup("regions", name: "Regions", localName: "Regioner", divisions: PlaceReorganisation.eastDenmark.isInEffect
                ? [
                    ("82", "Central Denmark", "Region Midtjylland"),
                    ("EAST", "East Denmark", "Region Østdanmark"),
                    ("81", "North Denmark", "Region Nordjylland"),
                    ("83", "Southern Denmark", "Region Syddanmark"),
                ]
                : [
                    ("84", "Capital Region", "Region Hovedstaden"),
                    ("82", "Central Denmark", "Region Midtjylland"),
                    ("81", "North Denmark", "Region Nordjylland"),
                    ("83", "Southern Denmark", "Region Syddanmark"),
                    ("85", "Zealand", "Region Sjælland"),
                ]),
        ]
    )

    private static func danishGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "DK-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "DK-\(place.code)",
                    countryID: "DK",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "DK-\(group)",
                    flagAssetName: "world_flag_dk",
                    flagNote: "Denmark's regions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
