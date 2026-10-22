import Foundation

extension CountryCatalog {
    // Ireland's 26 counties, grouped by province (Ulster lists the three counties in the state).
    // IDs follow ISO 3166-2:IE; Dublin, Cork, Galway and the other counties with several councils are one place each.
    // Counties have no official flags. Flags in each county's GAA colours are shown with a note; Kildare's
    // colours are plain white, so it shows the national flag.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and IrelandFlagCredits.json.
    static let ireland = Country(
        id: "IE",
        name: "Ireland",
        localName: "Éire",
        divisionLabel: "Counties",
        groups: [
            irishProvince("connacht", name: "Connacht", localName: "Connachta", divisions: [
                ("G", "Galway", "Gaillimh"),
                ("LM", "Leitrim", "Liatroim"),
                ("MO", "Mayo", "Maigh Eo"),
                ("RN", "Roscommon", "Ros Comáin"),
                ("SO", "Sligo", "Sligeach"),
            ]),
            irishProvince("leinster", name: "Leinster", localName: "Laighin", divisions: [
                ("CW", "Carlow", "Ceatharlach"),
                ("D", "Dublin", "Baile Átha Cliath"),
                ("KE", "Kildare", "Cill Dara"),
                ("KK", "Kilkenny", "Cill Chainnigh"),
                ("LS", "Laois", nil),
                ("LD", "Longford", "An Longfort"),
                ("LH", "Louth", "Lú"),
                ("MH", "Meath", "An Mhí"),
                ("OY", "Offaly", "Uíbh Fhailí"),
                ("WH", "Westmeath", "An Iarmhí"),
                ("WX", "Wexford", "Loch Garman"),
                ("WW", "Wicklow", "Cill Mhantáin"),
            ]),
            irishProvince("munster", name: "Munster", localName: "An Mhumhain", divisions: [
                ("CE", "Clare", "An Clár"),
                ("CO", "Cork", "Corcaigh"),
                ("KY", "Kerry", "Ciarraí"),
                ("LK", "Limerick", "Luimneach"),
                ("TA", "Tipperary", "Tiobraid Árann"),
                ("WD", "Waterford", "Port Láirge"),
            ]),
            irishProvince("ulster", name: "Ulster", localName: "Ulaidh", divisions: [
                ("CN", "Cavan", "An Cabhán"),
                ("DL", "Donegal", "Dún na nGall"),
                ("MN", "Monaghan", "Muineachán"),
            ]),
        ]
    )

    /// Kildare's county colours are plain white, which does not read as a flag, so the national flag
    /// is shown instead.
    private static let irishCountiesWithoutColourFlags: Set<String> = ["KE"]

    private static func irishProvince(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "IE-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let hasColourFlag = !irishCountiesWithoutColourFlags.contains(place.code)
                return AdministrativeDivision(
                    id: "IE-\(place.code)",
                    countryID: "IE",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "IE-\(group)",
                    flagAssetName: hasColourFlag ? "ie_flag_\(place.code.lowercased())" : "world_flag_ie",
                    flagNote: hasColourFlag
                        ? "Unofficial flag in the county's GAA colours."
                        : "The national flag is shown; \(place.name) has no official flag."
                )
            }
        )
    }
}
