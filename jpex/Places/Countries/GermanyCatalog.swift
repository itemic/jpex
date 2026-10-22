import Foundation

extension CountryCatalog {
    /// State identifiers follow ISO 3166-2:DE. Keep them stable across catalog edits.
    /// Names and abbreviations: Destatis' federal-state directory.
    static let germany = Country(
        id: "DE",
        name: "Germany",
        localName: "Deutschland",
        divisionLabel: "States",
        groups: [
            DivisionGroup(
                id: "DE-states",
                name: "States",
                localName: "Bundesländer",
                divisions: [
                    germanState("BW", name: "Baden-Württemberg", localName: "Baden-Württemberg"),
                    germanState("BY", name: "Bavaria", localName: "Bayern"),
                    germanState("BE", name: "Berlin", localName: "Berlin"),
                    germanState("BB", name: "Brandenburg", localName: "Brandenburg"),
                    germanState("HB", name: "Bremen", localName: "Bremen"),
                    germanState("HH", name: "Hamburg", localName: "Hamburg"),
                    germanState("HE", name: "Hesse", localName: "Hessen"),
                    germanState("NI", name: "Lower Saxony", localName: "Niedersachsen"),
                    germanState("MV", name: "Mecklenburg-Western Pomerania", localName: "Mecklenburg-Vorpommern"),
                    germanState("NW", name: "North Rhine-Westphalia", localName: "Nordrhein-Westfalen"),
                    germanState("RP", name: "Rhineland-Palatinate", localName: "Rheinland-Pfalz"),
                    germanState("SL", name: "Saarland", localName: "Saarland"),
                    germanState("SN", name: "Saxony", localName: "Sachsen"),
                    germanState("ST", name: "Saxony-Anhalt", localName: "Sachsen-Anhalt"),
                    germanState("SH", name: "Schleswig-Holstein", localName: "Schleswig-Holstein"),
                    germanState("TH", name: "Thuringia", localName: "Thüringen")
                ]
            )
        ]
    )

    private static func germanState(
        _ code: String,
        name: String,
        localName: String
    ) -> AdministrativeDivision {
        AdministrativeDivision(
            id: "DE-\(code)",
            countryID: "DE",
            name: name,
            localName: localName,
            abbreviation: code,
            groupID: "DE-states",
            flagAssetName: "de_flag_\(code.lowercased())"
        )
    }
}
