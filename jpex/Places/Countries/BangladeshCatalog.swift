import Foundation

extension CountryCatalog {
    // Bangladesh's eight divisions (the 64 districts are not listed). IDs follow ISO 3166-2:BD (BD-A to BD-H).
    // The divisions have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_B.md.
    static let bangladesh = Country(
        id: "BD",
        name: "Bangladesh",
        localName: "বাংলাদেশ",
        divisionLabel: "Divisions",
        groups: [
            bangladeshiGroup("divisions", name: "Divisions", localName: "বিভাগ", divisions: [
                ("A", "Barishal", "বরিশাল"),
                ("B", "Chattogram", "চট্টগ্রাম"),
                ("C", "Dhaka", "ঢাকা"),
                ("D", "Khulna", "খুলনা"),
                ("H", "Mymensingh", "ময়মনসিংহ"),
                ("E", "Rajshahi", "রাজশাহী"),
                ("F", "Rangpur", "রংপুর"),
                ("G", "Sylhet", "সিলেট"),
            ]),
        ]
    )

    private static func bangladeshiGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BD-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BD-\(place.code)",
                    countryID: "BD",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BD-\(group)",
                    flagAssetName: "world_flag_bd",
                    flagNote: "Bangladesh's divisions have no official flags; the national flag is shown."
                )
            }
        )
    }
}
