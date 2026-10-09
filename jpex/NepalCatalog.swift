import Foundation

extension CountryCatalog {
    // Nepal's seven provinces with their current names, in their official order (formerly Provinces 1 to 7).
    // IDs follow ISO 3166-2:NP. The provinces have adopted emblems but no flags, so every entry shows the
    // national flag with a note. See MORE_FLAG_SOURCES_3.md.
    static let nepal = Country(
        id: "NP",
        name: "Nepal",
        localName: "नेपाल",
        divisionLabel: "Provinces",
        groups: [
            nepaliGroup("provinces", name: "Provinces", localName: "प्रदेश", divisions: [
                ("P1", "Koshi", "कोशी"),
                ("P2", "Madhesh", "मधेश"),
                ("P3", "Bagmati", "बागमती"),
                ("P4", "Gandaki", "गण्डकी"),
                ("P5", "Lumbini", "लुम्बिनी"),
                ("P6", "Karnali", "कर्णाली"),
                ("P7", "Sudurpashchim", "सुदूरपश्चिम"),
            ]),
        ]
    )

    private static func nepaliGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "NP-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "NP-\(place.code)",
                    countryID: "NP",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "NP-\(group)",
                    flagAssetName: "world_flag_np",
                    flagNote: "The national flag is shown; \(place.name) Province has no official flag."
                )
            }
        )
    }
}
