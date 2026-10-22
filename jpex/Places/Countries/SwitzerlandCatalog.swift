import Foundation

extension CountryCatalog {
    /// Cantons follow the constitutional order, with stable ISO 3166-2:CH identifiers.
    static let switzerland = Country(
        id: "CH",
        name: "Switzerland",
        localName: "Switzerland",
        divisionLabel: "Cantons",
        groups: [
            DivisionGroup(
                id: "CH-cantons",
                name: "Cantons",
                divisions: [
                    swissCanton("ZH", name: "Zurich", localName: "Zürich"),
                    swissCanton("BE", name: "Bern", localName: "Bern"),
                    swissCanton("LU", name: "Lucerne", localName: "Luzern"),
                    swissCanton("UR", name: "Uri", localName: "Uri"),
                    swissCanton("SZ", name: "Schwyz", localName: "Schwyz"),
                    swissCanton("OW", name: "Obwalden", localName: "Obwalden"),
                    swissCanton("NW", name: "Nidwalden", localName: "Nidwalden"),
                    swissCanton("GL", name: "Glarus", localName: "Glarus"),
                    swissCanton("ZG", name: "Zug", localName: "Zug"),
                    swissCanton("FR", name: "Fribourg", localName: "Fribourg"),
                    swissCanton("SO", name: "Solothurn", localName: "Solothurn"),
                    swissCanton("BS", name: "Basel-Stadt", localName: "Basel-Stadt"),
                    swissCanton("BL", name: "Basel-Landschaft", localName: "Basel-Landschaft"),
                    swissCanton("SH", name: "Schaffhausen", localName: "Schaffhausen"),
                    swissCanton("AR", name: "Appenzell Ausserrhoden", localName: "Appenzell Ausserrhoden"),
                    swissCanton("AI", name: "Appenzell Innerrhoden", localName: "Appenzell Innerrhoden"),
                    swissCanton("SG", name: "St. Gallen", localName: "St. Gallen"),
                    swissCanton("GR", name: "Graubünden", localName: "Graubünden"),
                    swissCanton("AG", name: "Aargau", localName: "Aargau"),
                    swissCanton("TG", name: "Thurgau", localName: "Thurgau"),
                    swissCanton("TI", name: "Ticino", localName: "Ticino"),
                    swissCanton("VD", name: "Vaud", localName: "Vaud"),
                    swissCanton("VS", name: "Valais", localName: "Valais"),
                    swissCanton("NE", name: "Neuchâtel", localName: "Neuchâtel"),
                    swissCanton("GE", name: "Geneva", localName: "Genève"),
                    swissCanton("JU", name: "Jura", localName: "Jura")
                ]
            )
        ]
    )

    private static func swissCanton(
        _ code: String,
        name: String,
        localName: String
    ) -> AdministrativeDivision {
        AdministrativeDivision(
            id: "CH-\(code)",
            countryID: "CH",
            name: name,
            localName: localName,
            abbreviation: code,
            groupID: "CH-cantons",
            flagAssetName: "ch_flag_\(code.lowercased())"
        )
    }
}
