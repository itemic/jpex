import Foundation

extension CountryCatalog {
    // Serbia's 24 administrative districts outside Kosovo and the City of Belgrade, grouped by statistical region.
    // The five districts that ISO 3166-2:RS lists for Kosovo (RS-25 to RS-29) are not included: the app lists Kosovo
    // as a place of its own. IDs follow ISO 3166-2:RS. Districts are state administrative areas without symbols, so
    // they show the national flag with a note. Flag sources and licences: MORE_FLAG_SOURCES_A.md and SerbiaFlagCredits.json.
    static let serbia = Country(
        id: "RS",
        name: "Serbia",
        localName: "Србија",
        divisionLabel: "Districts",
        groups: [
            serbianGroup("belgrade", name: "Belgrade", localName: "Београд", divisions: [
                ("00", "Belgrade", "Београд"),
            ]),
            serbianGroup("vojvodina", name: "Vojvodina", localName: "Војводина", divisions: [
                ("01", "North Bačka", "Севернобачки округ"),
                ("02", "Central Banat", "Средњобанатски округ"),
                ("03", "North Banat", "Севернобанатски округ"),
                ("04", "South Banat", "Јужнобанатски округ"),
                ("05", "West Bačka", "Западнобачки округ"),
                ("06", "South Bačka", "Јужнобачки округ"),
                ("07", "Srem", "Сремски округ"),
            ]),
            serbianGroup("sumadija-western", name: "Šumadija and Western Serbia", localName: "Шумадија и Западна Србија", divisions: [
                ("08", "Mačva", "Мачвански округ"),
                ("09", "Kolubara", "Колубарски округ"),
                ("12", "Šumadija", "Шумадијски округ"),
                ("13", "Pomoravlje", "Поморавски округ"),
                ("16", "Zlatibor", "Златиборски округ"),
                ("17", "Moravica", "Моравички округ"),
                ("18", "Raška", "Рашки округ"),
                ("19", "Rasina", "Расински округ"),
            ]),
            serbianGroup("southern-eastern", name: "Southern and Eastern Serbia", localName: "Јужна и Источна Србија", divisions: [
                ("10", "Podunavlje", "Подунавски округ"),
                ("11", "Braničevo", "Браничевски округ"),
                ("14", "Bor", "Борски округ"),
                ("15", "Zaječar", "Зајечарски округ"),
                ("20", "Nišava", "Нишавски округ"),
                ("21", "Toplica", "Топлички округ"),
                ("22", "Pirot", "Пиротски округ"),
                ("23", "Jablanica", "Јабланички округ"),
                ("24", "Pčinja", "Пчињски округ"),
            ]),
        ]
    )

    /// Places with their own flag artwork. Districts are state administrative areas without symbols of their own.
    private static let serbianPlacesWithFlags: Set<String> = ["00"]

    private static func serbianFlagNote(_ code: String, name: String) -> String? {
        if serbianPlacesWithFlags.contains(code) { return nil }
        let place = name.hasSuffix(" District") ? name : "\(name) District"
        return "The national flag is shown; \(place) has no official flag."
    }

    private static func serbianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "RS-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = serbianFlagNote(place.code, name: place.name)
                return AdministrativeDivision(
                    id: "RS-\(place.code)",
                    countryID: "RS",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "RS-\(group)",
                    flagAssetName: flagNote == nil ? "rs_flag_\(place.code.lowercased())" : "world_flag_rs",
                    flagNote: flagNote
                )
            }
        )
    }
}
