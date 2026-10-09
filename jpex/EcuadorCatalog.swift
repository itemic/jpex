import Foundation

extension CountryCatalog {
    // Ecuador's 24 provinces, grouped by natural region; Santo Domingo de los Tsáchilas is counted with the Coast.
    // IDs follow ISO 3166-2:EC. Flag sources and licences: MORE_FLAG_SOURCES_3.md and EcuadorFlagCredits.json.
    static let ecuador = Country(
        id: "EC",
        name: "Ecuador",
        localName: "Ecuador",
        divisionLabel: "Provinces",
        groups: [
            ecuadorianRegion("coast", name: "Coast", localName: "Costa", divisions: [
                ("O", "El Oro"),
                ("E", "Esmeraldas"),
                ("G", "Guayas"),
                ("R", "Los Ríos"),
                ("M", "Manabí"),
                ("SE", "Santa Elena"),
                ("SD", "Santo Domingo de los Tsáchilas"),
            ]),
            ecuadorianRegion("highlands", name: "Highlands", localName: "Sierra", divisions: [
                ("A", "Azuay"),
                ("B", "Bolívar"),
                ("F", "Cañar"),
                ("C", "Carchi"),
                ("H", "Chimborazo"),
                ("X", "Cotopaxi"),
                ("I", "Imbabura"),
                ("L", "Loja"),
                ("P", "Pichincha"),
                ("T", "Tungurahua"),
            ]),
            ecuadorianRegion("amazon", name: "Amazon", localName: "Amazonía", divisions: [
                ("S", "Morona Santiago"),
                ("N", "Napo"),
                ("D", "Orellana"),
                ("Y", "Pastaza"),
                ("U", "Sucumbíos"),
                ("Z", "Zamora Chinchipe"),
            ]),
            ecuadorianRegion("galapagos", name: "Galápagos", localName: nil, divisions: [
                ("W", "Galápagos"),
            ]),
        ]
    )

    private static func ecuadorianRegion(
        _ group: String,
        name: String,
        localName: String?,
        divisions: [(code: String, name: String)]
    ) -> DivisionGroup {
        DivisionGroup(
            id: "EC-\(group)",
            name: name,
            localName: localName,
            divisions: divisions.map { place in
                AdministrativeDivision(
                    id: "EC-\(place.code)",
                    countryID: "EC",
                    name: place.name,
                    abbreviation: place.code,
                    groupID: "EC-\(group)",
                    flagAssetName: "ec_flag_\(place.code.lowercased())"
                )
            }
        )
    }
}
