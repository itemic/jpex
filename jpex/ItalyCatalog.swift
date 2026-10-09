import Foundation

extension CountryCatalog {
    /// Stable ISO 3166-2:IT identifiers keep visits independent of display order.
    static let italy = Country(
        id: "IT",
        name: "Italy",
        localName: "Italia",
        divisionLabel: "Regions",
        groups: [
            DivisionGroup(
                id: "IT-regions",
                name: "Regions",
                localName: "Regioni",
                divisions: [
                    italianRegion("65", name: "Abruzzo", localName: "Abruzzo"),
                    italianRegion("23", name: "Aosta Valley", localName: "Valle d’Aosta"),
                    italianRegion("75", name: "Apulia", localName: "Puglia"),
                    italianRegion("77", name: "Basilicata", localName: "Basilicata"),
                    italianRegion("78", name: "Calabria", localName: "Calabria"),
                    italianRegion("72", name: "Campania", localName: "Campania"),
                    italianRegion("45", name: "Emilia-Romagna", localName: "Emilia-Romagna"),
                    italianRegion("36", name: "Friuli-Venezia Giulia", localName: "Friuli Venezia Giulia"),
                    italianRegion("62", name: "Lazio", localName: "Lazio"),
                    italianRegion("42", name: "Liguria", localName: "Liguria"),
                    italianRegion("25", name: "Lombardy", localName: "Lombardia"),
                    italianRegion("57", name: "Marche", localName: "Marche"),
                    italianRegion("67", name: "Molise", localName: "Molise"),
                    italianRegion("21", name: "Piedmont", localName: "Piemonte"),
                    italianRegion("88", name: "Sardinia", localName: "Sardegna"),
                    italianRegion("82", name: "Sicily", localName: "Sicilia"),
                    italianRegion("32", name: "Trentino-South Tyrol", localName: "Trentino-Alto Adige"),
                    italianRegion("52", name: "Tuscany", localName: "Toscana"),
                    italianRegion("55", name: "Umbria", localName: "Umbria"),
                    italianRegion("34", name: "Veneto", localName: "Veneto")
                ]
            )
        ]
    )

    private static func italianRegion(
        _ code: String,
        name: String,
        localName: String
    ) -> AdministrativeDivision {
        AdministrativeDivision(
            id: "IT-\(code)",
            countryID: "IT",
            name: name,
            localName: localName,
            abbreviation: code,
            groupID: "IT-regions",
            flagAssetName: "it_flag_\(code.lowercased())"
        )
    }
}
