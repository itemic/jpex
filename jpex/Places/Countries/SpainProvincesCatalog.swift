import Foundation

extension CountryCatalog {
    // Spain's provinces, a list for each autonomous community with more than one, opened from the
    // community's row. The single-province communities (Asturias, the Balearic Islands, Cantabria,
    // Madrid, Murcia, Navarre and La Rioja) and Ceuta and Melilla have none. IDs follow ISO 3166-2:ES.
    // Local names are the official forms where they differ from English: Basque, Valencian and
    // Spanish. Maps: World Bank admin 2; see MAP_SOURCES_D.md.
    static let spanishProvinceLists: [Country] = [
        spanishProvinces("AN", flagOf: "Andalusia", [
            ("AL", "Almería", nil), ("CA", "Cádiz", nil), ("CO", "Córdoba", nil), ("GR", "Granada", nil),
            ("H", "Huelva", nil), ("J", "Jaén", nil), ("MA", "Málaga", nil), ("SE", "Seville", "Sevilla"),
        ]),
        spanishProvinces("AR", flagOf: "Aragon", [("HU", "Huesca", nil), ("TE", "Teruel", nil), ("Z", "Zaragoza", nil)]),
        spanishProvinces("PV", flagOf: "the Basque Country", [
            ("VI", "Álava", "Araba"), ("BI", "Biscay", "Bizkaia"), ("SS", "Gipuzkoa", nil),
        ]),
        spanishProvinces("CN", flagOf: "the Canary Islands", [
            ("GC", "Las Palmas", nil), ("TF", "Santa Cruz de Tenerife", nil),
        ]),
        spanishProvinces("CL", flagOf: "Castile and León", [
            ("AV", "Ávila", nil), ("BU", "Burgos", nil), ("LE", "León", nil), ("P", "Palencia", nil),
            ("SA", "Salamanca", nil), ("SG", "Segovia", nil), ("SO", "Soria", nil), ("VA", "Valladolid", nil),
            ("ZA", "Zamora", nil),
        ]),
        spanishProvinces("CM", flagOf: "Castile-La Mancha", [
            ("AB", "Albacete", nil), ("CR", "Ciudad Real", nil), ("CU", "Cuenca", nil), ("GU", "Guadalajara", nil),
            ("TO", "Toledo", nil),
        ]),
        spanishProvinces("CT", flagOf: "Catalonia", [
            ("B", "Barcelona", nil), ("GI", "Girona", nil), ("L", "Lleida", nil), ("T", "Tarragona", nil),
        ]),
        spanishProvinces("EX", flagOf: "Extremadura", [("BA", "Badajoz", nil), ("CC", "Cáceres", nil)]),
        spanishProvinces("GA", flagOf: "Galicia", [
            ("C", "A Coruña", nil), ("LU", "Lugo", nil), ("OR", "Ourense", nil), ("PO", "Pontevedra", nil),
        ]),
        spanishProvinces("VC", flagOf: "the Valencian Community", [
            ("A", "Alicante", "Alacant"), ("CS", "Castellón", "Castelló"), ("V", "Valencia", "València"),
        ]),
    ]

    private static func spanishProvinces(
        _ community: String, flagOf communityName: String, _ provinces: [(code: String, name: String, localName: String?)]
    ) -> Country {
        subdivisionList(
            of: "ES-\(community)", in: spain, label: "Provinces",
            groups: [(slug: "provinces", name: "Provinces", localName: "Provincias", places: provinces)],
            flagNote: "The flag of \(communityName) is shown; provincial flags aren't included.")
    }
}
