import Foundation

extension CountryCatalog {
    // Bosnia and Herzegovina: the ten cantons of the Federation, Republika Srpska and Brčko District.
    // Canton IDs are the codes BA-01 to BA-10, which ISO 3166-2:BA used for the cantons until 2015 (the current
    // ISO list has only the two entities and Brčko District); BA-SRP and BA-BRC are current ISO codes.
    // Flag sources and licences: MORE_FLAG_SOURCES_A.md and BosniaFlagCredits.json.
    static let bosniaAndHerzegovina = Country(
        id: "BA",
        name: "Bosnia and Herzegovina",
        localName: "Bosna i Hercegovina",
        divisionLabel: "Cantons & entities",
        groups: [
            bosnianGroup("federation", name: "Federation of Bosnia and Herzegovina", localName: "Federacija Bosne i Hercegovine", divisions: [
                ("01", "Una-Sana Canton", "Unsko-sanski kanton"),
                ("02", "Posavina Canton", "Posavski kanton"),
                ("03", "Tuzla Canton", "Tuzlanski kanton"),
                ("04", "Zenica-Doboj Canton", "Zeničko-dobojski kanton"),
                ("05", "Bosnian Podrinje Canton", "Bosansko-podrinjski kanton Goražde"),
                ("06", "Central Bosnia Canton", "Srednjobosanski kanton"),
                ("07", "Herzegovina-Neretva Canton", "Hercegovačko-neretvanski kanton"),
                ("08", "West Herzegovina Canton", "Zapadnohercegovački kanton"),
                ("09", "Sarajevo Canton", "Kanton Sarajevo"),
                ("10", "Canton 10", "Kanton 10"),
            ]),
            bosnianGroup("republika-srpska", name: "Republika Srpska", localName: "Република Српска", divisions: [
                ("SRP", "Republika Srpska", "Република Српска"),
            ]),
            bosnianGroup("brcko", name: "Brčko District", localName: "Brčko distrikt", divisions: [
                ("BRC", "Brčko District", "Brčko distrikt"),
            ]),
        ]
    )

    /// Places shown with the national flag. Brčko District uses the national flag by statute.
    private static let bosnianFlagNotes: [String: String] = [
        "10": "The national flag is shown; Canton 10's flag was ruled unconstitutional in 1998 and has not been replaced.",
        "BRC": "The national flag is shown; Brčko District has no flag of its own and uses the national flag.",
    ]

    private static func bosnianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BA-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place -> AdministrativeDivision in
                let flagNote = bosnianFlagNotes[place.code]
                return AdministrativeDivision(
                    id: "BA-\(place.code)",
                    countryID: "BA",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BA-\(group)",
                    flagAssetName: flagNote == nil ? "ba_flag_\(place.code.lowercased())" : "world_flag_ba",
                    flagNote: flagNote
                )
            }
        )
    }
}
