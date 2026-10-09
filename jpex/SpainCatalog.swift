import Foundation

extension CountryCatalog {
    /// Stable ISO 3166-2:ES identifiers keep visits independent of display order.
    static let spain = Country(
        id: "ES",
        name: "Spain",
        localName: "España",
        divisionLabel: "Communities & Cities",
        groups: [
            DivisionGroup(
                id: "ES-communities",
                name: "Autonomous Communities",
                localName: "Comunidades Autónomas",
                divisions: [
                    spanishDivision("AN", name: "Andalusia", localName: "Andalucía", groupID: "ES-communities"),
                    spanishDivision("AR", name: "Aragon", localName: "Aragón", groupID: "ES-communities"),
                    spanishDivision("AS", name: "Asturias", localName: "Asturias", groupID: "ES-communities"),
                    spanishDivision("IB", name: "Balearic Islands", localName: "Illes Balears", groupID: "ES-communities"),
                    spanishDivision("PV", name: "Basque Country", localName: "Euskadi", groupID: "ES-communities"),
                    spanishDivision("CN", name: "Canary Islands", localName: "Canarias", groupID: "ES-communities"),
                    spanishDivision("CB", name: "Cantabria", localName: "Cantabria", groupID: "ES-communities"),
                    spanishDivision("CL", name: "Castile and León", localName: "Castilla y León", groupID: "ES-communities"),
                    spanishDivision("CM", name: "Castile-La Mancha", localName: "Castilla-La Mancha", groupID: "ES-communities"),
                    spanishDivision("CT", name: "Catalonia", localName: "Catalunya", groupID: "ES-communities"),
                    spanishDivision("EX", name: "Extremadura", localName: "Extremadura", groupID: "ES-communities"),
                    spanishDivision("GA", name: "Galicia", localName: "Galicia", groupID: "ES-communities"),
                    spanishDivision("RI", name: "La Rioja", localName: "La Rioja", groupID: "ES-communities"),
                    spanishDivision("MD", name: "Community of Madrid", localName: "Comunidad de Madrid", groupID: "ES-communities"),
                    spanishDivision("MC", name: "Region of Murcia", localName: "Región de Murcia", groupID: "ES-communities"),
                    spanishDivision("NC", name: "Navarre", localName: "Navarra", groupID: "ES-communities"),
                    spanishDivision("VC", name: "Valencian Community", localName: "Comunitat Valenciana", groupID: "ES-communities")
                ]
            ),
            DivisionGroup(
                id: "ES-cities",
                name: "Autonomous Cities",
                localName: "Ciudades Autónomas",
                divisions: [
                    spanishDivision("CE", name: "Ceuta", localName: "Ceuta", groupID: "ES-cities"),
                    spanishDivision("ML", name: "Melilla", localName: "Melilla", groupID: "ES-cities")
                ]
            )
        ]
    )

    private static func spanishDivision(
        _ code: String,
        name: String,
        localName: String,
        groupID: String
    ) -> AdministrativeDivision {
        AdministrativeDivision(
            id: "ES-\(code)",
            countryID: "ES",
            name: name,
            localName: localName,
            abbreviation: code,
            groupID: groupID,
            flagAssetName: "es_flag_\(code.lowercased())"
        )
    }
}
