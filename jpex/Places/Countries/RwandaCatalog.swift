import Foundation

extension CountryCatalog {
    // Rwanda's four provinces and the City of Kigali. IDs follow ISO 3166-2:RW.
    // They have no official flags, so every entry shows the national flag. See MORE_FLAG_SOURCES_C.md.
    static let rwanda = Country(
        id: "RW",
        name: "Rwanda",
        localName: "Rwanda",
        divisionLabel: "Provinces",
        groups: [
            rwandanGroup("provinces", name: "Provinces", localName: "Intara", divisions: [
                ("01", "Kigali", "Umujyi wa Kigali"),
                ("02", "Eastern Province", "Intara y'Iburasirazuba"),
                ("03", "Northern Province", "Intara y'Amajyaruguru"),
                ("04", "Western Province", "Intara y'Iburengerazuba"),
                ("05", "Southern Province", "Intara y'Amajyepfo"),
            ]),
        ]
    )

    private static func rwandanGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "RW-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "RW-\(place.code)",
                    countryID: "RW",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "RW-\(group)",
                    flagAssetName: "world_flag_rw",
                    flagNote: "Rwanda's provinces and Kigali have no official flags; the national flag is shown."
                )
            }
        )
    }
}
