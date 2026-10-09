import Foundation

extension CountryCatalog {
    // Armenia's ten provinces (marzer) and the capital, Yerevan. IDs follow ISO 3166-2:AM.
    // The provinces have emblems but no flags, so they show the national flag with a note.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and ArmeniaFlagCredits.json.
    static let armenia = Country(
        id: "AM",
        name: "Armenia",
        localName: "Հայաստան",
        divisionLabel: "Provinces",
        groups: [
            armenianGroup("provinces", name: "Provinces", localName: "Մարզեր", divisions: [
                ("AG", "Aragatsotn", "Արագածոտն"),
                ("AR", "Ararat", "Արարատ"),
                ("AV", "Armavir", "Արմավիր"),
                ("GR", "Gegharkunik", "Գեղարքունիք"),
                ("KT", "Kotayk", "Կոտայք"),
                ("LO", "Lori", "Լոռի"),
                ("SH", "Shirak", "Շիրակ"),
                ("SU", "Syunik", "Սյունիք"),
                ("TV", "Tavush", "Տավուշ"),
                ("VD", "Vayots Dzor", "Վայոց ձոր"),
            ]),
            armenianGroup("capital", name: "Capital", localName: "Մայրաքաղաք", divisions: [
                ("ER", "Yerevan", "Երևան"),
            ]),
        ]
    )

    /// Places with their own flag artwork. The provinces have emblems but no flags.
    private static let armenianPlacesWithFlags: Set<String> = ["ER"]

    private static func armenianFlagNote(_ code: String, name: String) -> String? {
        if armenianPlacesWithFlags.contains(code) { return nil }
        let place = name.hasSuffix(" Province") ? name : "\(name) Province"
        return "The national flag is shown; \(place) has no official flag."
    }

    private static func armenianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "AM-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = armenianFlagNote(place.code, name: place.name)
                return AdministrativeDivision(
                    id: "AM-\(place.code)",
                    countryID: "AM",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "AM-\(group)",
                    flagAssetName: flagNote == nil ? "am_flag_\(place.code.lowercased())" : "world_flag_am",
                    flagNote: flagNote
                )
            }
        )
    }
}
