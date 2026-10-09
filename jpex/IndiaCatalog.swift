import Foundation

extension CountryCatalog {
    // India's 28 states and eight union territories. IDs follow ISO 3166-2:IN.
    // States and union territories have no official flags, so every entry shows the national flag.
    // See MORE_FLAG_SOURCES.md.
    static let india = Country(
        id: "IN",
        name: "India",
        localName: "भारत",
        divisionLabel: "States & territories",
        groups: [
            indianGroup("states", name: "States", localName: nil, divisions: [
                ("AP", "Andhra Pradesh"),
                ("AR", "Arunachal Pradesh"),
                ("AS", "Assam"),
                ("BR", "Bihar"),
                ("CG", "Chhattisgarh"),
                ("GA", "Goa"),
                ("GJ", "Gujarat"),
                ("HR", "Haryana"),
                ("HP", "Himachal Pradesh"),
                ("JH", "Jharkhand"),
                ("KA", "Karnataka"),
                ("KL", "Kerala"),
                ("MP", "Madhya Pradesh"),
                ("MH", "Maharashtra"),
                ("MN", "Manipur"),
                ("ML", "Meghalaya"),
                ("MZ", "Mizoram"),
                ("NL", "Nagaland"),
                ("OD", "Odisha"),
                ("PB", "Punjab"),
                ("RJ", "Rajasthan"),
                ("SK", "Sikkim"),
                ("TN", "Tamil Nadu"),
                ("TS", "Telangana"),
                ("TR", "Tripura"),
                ("UP", "Uttar Pradesh"),
                ("UK", "Uttarakhand"),
                ("WB", "West Bengal"),
            ]),
            indianGroup("territories", name: "Union territories", localName: nil, divisions: [
                ("AN", "Andaman and Nicobar Islands"),
                ("CH", "Chandigarh"),
                ("DH", "Dadra and Nagar Haveli and Daman and Diu"),
                ("DL", "Delhi"),
                ("JK", "Jammu and Kashmir"),
                ("LA", "Ladakh"),
                ("LD", "Lakshadweep"),
                ("PY", "Puducherry"),
            ]),
        ]
    )

    private static func indianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "IN-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "IN-\(place.code)",
                    countryID: "IN",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "IN-\(group)",
                    flagAssetName: "world_flag_in",
                    flagNote: "India's states and union territories have no official flags; the national flag is shown."
                )
            }
        )
    }
}
