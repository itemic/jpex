import Foundation

extension CountryCatalog {
    // Pakistan's four provinces, Islamabad Capital Territory, and the two territories it administers in
    // Kashmir, Azad Kashmir and Gilgit-Baltistan. IDs follow ISO 3166-2:PK; the former tribal areas have been
    // part of Khyber Pakhtunkhwa since 2018. Local names are Urdu. Flag sources and licences:
    // MORE_FLAG_SOURCES_D.md and PakistanFlagCredits.json.
    static let pakistan = Country(
        id: "PK",
        name: "Pakistan",
        localName: "پاکستان",
        divisionLabel: "Provinces & territories",
        groups: [
            pakistaniGroup("provinces", name: "Provinces", localName: "صوبے", divisions: [
                ("BA", "Balochistan", "بلوچستان"),
                ("KP", "Khyber Pakhtunkhwa", "خیبر پختونخوا"),
                ("PB", "Punjab", "پنجاب"),
                ("SD", "Sindh", "سندھ"),
            ]),
            pakistaniGroup("territories", name: "Territories", localName: "علاقے", divisions: [
                ("JK", "Azad Kashmir", "آزاد جموں و کشمیر"),
                ("GB", "Gilgit-Baltistan", "گلگت بلتستان"),
                ("IS", "Islamabad Capital Territory", "اسلام آباد وفاقی دارالحکومت علاقہ"),
            ]),
        ]
    )

    /// Places without a flag of their own here show the national flag.
    private static let pakistaniFlagNotes: [String: String] = [
        "BA": "The national flag is shown; no accurate artwork of Balochistan's current flag is available.",
        "KP": "The national flag is shown; no accurate artwork of Khyber Pakhtunkhwa's current flag is available.",
        "PB": "The national flag is shown; no accurate artwork of Punjab's current flag is available.",
        "SD": "The national flag is shown; Sindh's current flag could not be verified.",
        "GB": "The national flag is shown; no accurate artwork of Gilgit-Baltistan's current flag is available.",
        "IS": "The national flag is shown; Islamabad Capital Territory has no official flag.",
    ]

    private static func pakistaniGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "PK-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = pakistaniFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "PK-\(place.code)",
                    countryID: "PK",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "PK-\(group)",
                    flagAssetName: flagNote == nil ? "pk_flag_\(place.code.lowercased())" : "world_flag_pk",
                    flagNote: flagNote
                )
            }
        )
    }
}
