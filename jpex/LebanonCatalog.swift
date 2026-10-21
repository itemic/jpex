import Foundation

extension CountryCatalog {
    // Lebanon's eight governorates. IDs follow ISO 3166-2:LB. Keserwan-Jbeil, created by law in 2017, has
    // never operated and isn't listed. Local names are Arabic. None has an official flag, so each shows the
    // national flag; see MORE_FLAG_SOURCES_D.md.
    static let lebanon = Country(
        id: "LB",
        name: "Lebanon",
        localName: "لبنان",
        divisionLabel: "Governorates",
        groups: [
            lebaneseGroup("governorates", name: "Governorates", localName: "المحافظات", divisions: [
                ("AK", "Akkar", "عكار"),
                ("BH", "Baalbek-Hermel", "بعلبك الهرمل"),
                ("BA", "Beirut", "بيروت"),
                ("BI", "Beqaa", "البقاع"),
                ("JL", "Mount Lebanon", "جبل لبنان"),
                ("NA", "Nabatieh", "النبطية"),
                ("AS", "North Governorate", "محافظة الشمال"),
                ("JA", "South Governorate", "محافظة الجنوب"),
            ]),
        ]
    )

    /// Every place shows the national flag, for the reason given.
    private static let lebaneseFlagNotes: [String: String] = [
        "AK": "Lebanon's governorates have no official flags; the national flag is shown.",
        "BH": "Lebanon's governorates have no official flags; the national flag is shown.",
        "BA": "The national flag is shown; no accurate artwork of the City of Beirut's flag is available.",
        "BI": "Lebanon's governorates have no official flags; the national flag is shown.",
        "JL": "Lebanon's governorates have no official flags; the national flag is shown.",
        "NA": "Lebanon's governorates have no official flags; the national flag is shown.",
        "AS": "Lebanon's governorates have no official flags; the national flag is shown.",
        "JA": "Lebanon's governorates have no official flags; the national flag is shown.",
    ]

    private static func lebaneseGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "LB-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "LB-\(place.code)",
                    countryID: "LB",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "LB-\(group)",
                    flagAssetName: "world_flag_lb",
                    flagNote: lebaneseFlagNotes[place.code]
                )
            }
        )
    }
}
