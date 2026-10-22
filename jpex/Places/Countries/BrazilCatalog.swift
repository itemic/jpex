import Foundation

extension CountryCatalog {
    // Brazil's 26 states and the Federal District, grouped by IBGE region. IDs follow ISO 3166-2:BR.
    // Flag sources and licences: MORE_FLAG_SOURCES.md and BrazilFlagCredits.json.
    static let brazil = Country(
        id: "BR",
        name: "Brazil",
        localName: "Brasil",
        divisionLabel: "States",
        groups: [
            brazilianRegion("north", name: "North", localName: "Norte", divisions: [
                ("AC", "Acre", nil),
                ("AP", "Amapá", nil),
                ("AM", "Amazonas", nil),
                ("PA", "Pará", nil),
                ("RO", "Rondônia", nil),
                ("RR", "Roraima", nil),
                ("TO", "Tocantins", nil),
            ]),
            brazilianRegion("northeast", name: "Northeast", localName: "Nordeste", divisions: [
                ("AL", "Alagoas", nil),
                ("BA", "Bahia", nil),
                ("CE", "Ceará", nil),
                ("MA", "Maranhão", nil),
                ("PB", "Paraíba", nil),
                ("PE", "Pernambuco", nil),
                ("PI", "Piauí", nil),
                ("RN", "Rio Grande do Norte", nil),
                ("SE", "Sergipe", nil),
            ]),
            brazilianRegion("central-west", name: "Central-West", localName: "Centro-Oeste", divisions: [
                ("DF", "Federal District", "Distrito Federal"),
                ("GO", "Goiás", nil),
                ("MT", "Mato Grosso", nil),
                ("MS", "Mato Grosso do Sul", nil),
            ]),
            brazilianRegion("southeast", name: "Southeast", localName: "Sudeste", divisions: [
                ("ES", "Espírito Santo", nil),
                ("MG", "Minas Gerais", nil),
                ("RJ", "Rio de Janeiro", nil),
                ("SP", "São Paulo", nil),
            ]),
            brazilianRegion("south", name: "South", localName: "Sul", divisions: [
                ("PR", "Paraná", nil),
                ("RS", "Rio Grande do Sul", nil),
                ("SC", "Santa Catarina", nil),
            ]),
        ]
    )

    private static func brazilianRegion(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String, localName: String?)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "BR-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "BR-\(place.code)",
                    countryID: "BR",
                    name: place.name,
                    localName: place.localName,
                    abbreviation: place.code,
                    groupID: "BR-\(group)",
                    flagAssetName: "br_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
