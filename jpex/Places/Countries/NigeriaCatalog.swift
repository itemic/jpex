import Foundation

extension CountryCatalog {
    // Nigeria's 36 states and the Federal Capital Territory, grouped by geopolitical zone. IDs follow ISO 3166-2:NG.
    // Most states have no official flag, or no accurate artwork of it, and show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_C.md and NigeriaFlagCredits.json.
    static let nigeria = Country(
        id: "NG",
        name: "Nigeria",
        localName: "Nigeria",
        divisionLabel: "States",
        groups: [
            nigerianGroup("north-central", name: "North Central", localName: nil, divisions: [
                ("BE", "Benue"),
                ("FC", "Federal Capital Territory"),
                ("KO", "Kogi"),
                ("KW", "Kwara"),
                ("NA", "Nasarawa"),
                ("NI", "Niger"),
                ("PL", "Plateau"),
            ]),
            nigerianGroup("north-east", name: "North East", localName: nil, divisions: [
                ("AD", "Adamawa"),
                ("BA", "Bauchi"),
                ("BO", "Borno"),
                ("GO", "Gombe"),
                ("TA", "Taraba"),
                ("YO", "Yobe"),
            ]),
            nigerianGroup("north-west", name: "North West", localName: nil, divisions: [
                ("JI", "Jigawa"),
                ("KD", "Kaduna"),
                ("KN", "Kano"),
                ("KT", "Katsina"),
                ("KE", "Kebbi"),
                ("SO", "Sokoto"),
                ("ZA", "Zamfara"),
            ]),
            nigerianGroup("south-east", name: "South East", localName: nil, divisions: [
                ("AB", "Abia"),
                ("AN", "Anambra"),
                ("EB", "Ebonyi"),
                ("EN", "Enugu"),
                ("IM", "Imo"),
            ]),
            nigerianGroup("south-south", name: "South South", localName: nil, divisions: [
                ("AK", "Akwa Ibom"),
                ("BY", "Bayelsa"),
                ("CR", "Cross River"),
                ("DE", "Delta"),
                ("ED", "Edo"),
                ("RI", "Rivers"),
            ]),
            nigerianGroup("south-west", name: "South West", localName: nil, divisions: [
                ("EK", "Ekiti"),
                ("LA", "Lagos"),
                ("OG", "Ogun"),
                ("ON", "Ondo"),
                ("OS", "Osun"),
                ("OY", "Oyo"),
            ]),
        ]
    )

    /// States shown with the national flag, and why.
    private static let nigerianFlagNotes: [String: String] = [
        "BE": "The national flag is shown; Benue State has no official flag.",
        "FC": "The national flag is shown; the Federal Capital Territory has no official flag.",
        "KO": "The national flag is shown; Kogi State has no official flag.",
        "KW": "The national flag is shown; Kwara State has no official flag.",
        "NA": "The national flag is shown; no artwork of Nasarawa State's flag is available.",
        "NI": "The national flag is shown; Niger State has no official flag.",
        "PL": "The national flag is shown; Plateau State has no official flag.",
        "AD": "The national flag is shown; Adamawa State has no official flag.",
        "BA": "The national flag is shown; Bauchi State has no official flag.",
        "BO": "The national flag is shown; Borno State has no official flag.",
        "GO": "The national flag is shown; Gombe State has no official flag.",
        "TA": "The national flag is shown; Taraba State has no official flag.",
        "YO": "The national flag is shown; Yobe State has no official flag.",
        "JI": "The national flag is shown; Jigawa State has no official flag.",
        "KD": "The national flag is shown; Kaduna State has no official flag.",
        "KN": "The national flag is shown; Kano State has no official flag.",
        "KT": "The national flag is shown; Katsina State has no official flag.",
        "KE": "The national flag is shown; Kebbi State has no official flag.",
        "SO": "The national flag is shown; Sokoto State has no official flag.",
        "ZA": "The national flag is shown; Zamfara State has no official flag.",
        "AB": "The national flag is shown; no accurate artwork of Abia State's current flag is available.",
        "AN": "The national flag is shown; no accurate artwork of Anambra State's current flag is available.",
        "EB": "The national flag is shown; Ebonyi State has no official flag.",
        "EN": "The national flag is shown; Enugu State has no official flag.",
        "IM": "The national flag is shown; Imo State has no official flag.",
        "CR": "The national flag is shown; no accurate artwork of Cross River State's flag is available.",
        "DE": "The national flag is shown; no accurate artwork of Delta State's current flag is available.",
        "ED": "The national flag is shown; Edo State has no official flag.",
        "RI": "The national flag is shown; Rivers State has no official flag.",
        "EK": "The national flag is shown; Ekiti State has no official flag.",
        "OG": "The national flag is shown; no usable artwork of Ogun State's flag is available.",
        "ON": "The national flag is shown; Ondo State has no official flag.",
        "OS": "The national flag is shown; Osun State repealed its flag law in 2023.",
        "OY": "The national flag is shown; no accurate artwork of Oyo State's flag is available.",
    ]

    private static func nigerianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "NG-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = nigerianFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "NG-\(place.code)",
                    countryID: "NG",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "NG-\(group)",
                    flagAssetName: flagNote == nil ? "ng_flag_\(place.code.lowercased())" : "world_flag_ng",
                    flagNote: flagNote
                )
            }
        )
    }
}
