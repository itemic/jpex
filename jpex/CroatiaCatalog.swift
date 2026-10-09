import Foundation

extension CountryCatalog {
    // Croatia's 20 counties and the City of Zagreb, which has county status. IDs follow ISO 3166-2:HR.
    // Flag sources and licences: MORE_FLAG_SOURCES_2.md and CroatiaFlagCredits.json.
    static let croatia = Country(
        id: "HR",
        name: "Croatia",
        localName: "Hrvatska",
        divisionLabel: "Counties",
        groups: [
            croatianGroup("counties", name: "Counties", localName: "Županije", divisions: [
                ("07", "Bjelovar-Bilogora", "Bjelovarsko-bilogorska županija"),
                ("12", "Brod-Posavina", "Brodsko-posavska županija"),
                ("21", "City of Zagreb", "Grad Zagreb"),
                ("19", "Dubrovnik-Neretva", "Dubrovačko-neretvanska županija"),
                ("18", "Istria", "Istarska županija"),
                ("04", "Karlovac", "Karlovačka županija"),
                ("06", "Koprivnica-Križevci", "Koprivničko-križevačka županija"),
                ("02", "Krapina-Zagorje", "Krapinsko-zagorska županija"),
                ("09", "Lika-Senj", "Ličko-senjska županija"),
                ("20", "Međimurje", "Međimurska županija"),
                ("14", "Osijek-Baranja", "Osječko-baranjska županija"),
                ("11", "Požega-Slavonia", "Požeško-slavonska županija"),
                ("08", "Primorje-Gorski Kotar", "Primorsko-goranska županija"),
                ("15", "Šibenik-Knin", "Šibensko-kninska županija"),
                ("03", "Sisak-Moslavina", "Sisačko-moslavačka županija"),
                ("17", "Split-Dalmatia", "Splitsko-dalmatinska županija"),
                ("05", "Varaždin", "Varaždinska županija"),
                ("10", "Virovitica-Podravina", "Virovitičko-podravska županija"),
                ("16", "Vukovar-Syrmia", "Vukovarsko-srijemska županija"),
                ("13", "Zadar", "Zadarska županija"),
                ("01", "Zagreb County", "Zagrebačka županija"),
            ]),
        ]
    )

    private static func croatianGroup(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "HR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "HR-\(place.code)",
                    countryID: "HR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "HR-\(group)",
                    flagAssetName: "hr_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
