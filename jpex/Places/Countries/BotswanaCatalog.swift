import Foundation

extension CountryCatalog {
    // Botswana's ten districts and six cities and towns, the ISO 3166-2:BW list; the district councils
    // formed in 2022–23 aren't listed. Each place shows the national flag; see MORE_FLAG_SOURCES_D.md.
    static let botswana = Country(
        id: "BW",
        name: "Botswana",
        localName: "Botswana",
        divisionLabel: "Districts",
        groups: [
            botswananGroup("districts", name: "Districts", localName: nil, divisions: [
                ("CE", "Central", nil),
                ("CH", "Chobe", nil),
                ("GH", "Ghanzi", nil),
                ("KG", "Kgalagadi", nil),
                ("KL", "Kgatleng", nil),
                ("KW", "Kweneng", nil),
                ("NE", "North-East", nil),
                ("NW", "North-West", nil),
                ("SE", "South-East", nil),
                ("SO", "Southern", nil),
            ]),
            botswananGroup("cities", name: "Cities & towns", localName: nil, divisions: [
                ("FR", "Francistown", nil),
                ("GA", "Gaborone", nil),
                ("JW", "Jwaneng", nil),
                ("LO", "Lobatse", nil),
                ("SP", "Selebi-Phikwe", nil),
                ("ST", "Sowa Town", nil),
            ]),
        ]
    )

    /// Every place shows the national flag, for the reason given.
    private static let botswananFlagNotes: [String: String] = [
        "CE": "The national flag is shown; Central District has no documented flag in use.",
        "CH": "The national flag is shown; Chobe District has no documented flag in use.",
        "GH": "The national flag is shown; no artwork of the Ghanzi District Council's flag is available.",
        "KG": "The national flag is shown; Kgalagadi District has no documented flag in use.",
        "KL": "The national flag is shown; no artwork of the Kgatleng District Council's flag is available.",
        "KW": "The national flag is shown; Kweneng District has no documented flag in use.",
        "NE": "The national flag is shown; North-East District has no documented flag in use.",
        "NW": "The national flag is shown; North-West District has no documented flag in use.",
        "SE": "The national flag is shown; South-East District has no documented flag in use.",
        "SO": "The national flag is shown; Southern District has no documented flag in use.",
        "FR": "The national flag is shown; no freely licensed artwork of Francistown's flag is available.",
        "GA": "The national flag is shown; no freely licensed artwork of Gaborone's flag is available.",
        "JW": "The national flag is shown; no freely licensed artwork of Jwaneng's flag is available.",
        "LO": "The national flag is shown; no freely licensed artwork of Lobatse's flag is available.",
        "SP": "The national flag is shown; no freely licensed artwork of Selebi-Phikwe's flag is available.",
        "ST": "The national flag is shown; Sowa Town has no documented flag in use.",
    ]

    private static func botswananGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BW-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BW-\(place.code)",
                    countryID: "BW",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BW-\(group)",
                    flagAssetName: "world_flag_bw",
                    flagNote: botswananFlagNotes[place.code]
                )
            }
        )
    }
}
