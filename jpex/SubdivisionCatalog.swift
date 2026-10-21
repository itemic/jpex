import Foundation

extension CountryCatalog {
    /// Lists of one place's own subdivisions, a country's second level, such as Tasmania's local
    /// government areas. Each opens from its place's row, as a country's list opens from the World,
    /// and isn't listed in the sidebar.
    static let subdivisionLists: [Country] = australianLocalGovernmentLists + britishCouncilLists + spanishProvinceLists

    /// The lists of a country's places' own subdivisions, alphabetically by place, such as the
    /// Northern Territory's and Tasmania's for Australia, chosen beneath its map. For one of those
    /// lists, the same, itself among them. None for every other list.
    static func subdivisionLists(of collection: Country) -> [Country] {
        subdivisionListsByCountry[collection.countryListID] ?? []
    }

    /// What a country's places' own subdivisions are called together, beneath its map: the name
    /// their lists share, such as Provinces, or where each has its own, as the UK's council areas,
    /// principal areas and districts do, the name they go by together. Nil without any.
    static func subdivisionLabel(of collection: Country) -> String? {
        let lists = subdivisionLists(of: collection)
        guard let first = lists.first else { return nil }
        if lists.allSatisfy({ $0.divisionLabel == first.divisionLabel }) { return first.divisionLabel }
        return sharedSubdivisionLabels[collection.countryListID] ?? first.divisionLabel
    }

    private static let subdivisionListsByCountry: [String: [Country]] = Dictionary(grouping: subdivisionLists, by: \.countryListID)
        .mapValues { lists in lists.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } }

    /// For a country whose places' subdivisions go by different names, the one they share.
    private static let sharedSubdivisionLabels = ["GB": "Councils"]

    /// Shorter names for levels whose own crowd the row beside a phone's total, such as LGAs for
    /// local government areas.
    static let shortLevelLabels = ["Local government areas": "LGAs", "Communities & Cities": "Communities"]

    /// A list of one place's own subdivisions, such as Andalusia's provinces, sharing the place's ID.
    /// Its places keep their country's ID and lie within the place, which rises with them. Without
    /// flags of their own here, each shows the place's flag.
    static func subdivisionList(
        of parentID: String,
        in country: Country,
        label: String,
        groups: [(slug: String, name: String, localName: String?, places: [(code: String, name: String, localName: String?)])],
        flagNote: String
    ) -> Country {
        guard let parent = country.divisions.first(where: { $0.id == parentID }) else {
            preconditionFailure("\(country.name) has no place \(parentID)")
        }
        return Country(
            id: parent.id,
            name: parent.name,
            localName: parent.localName ?? parent.name,
            divisionLabel: label,
            groups: groups.map { group in
                let groupID = "\(parent.id)-\(group.slug)"
                return DivisionGroup(
                    id: groupID,
                    name: group.name,
                    localName: group.localName,
                    divisions: group.places.map { place in
                        AdministrativeDivision(
                            id: "\(country.id)-\(place.code)",
                            countryID: country.id,
                            name: place.name,
                            localName: place.localName,
                            abbreviation: place.code,
                            groupID: groupID,
                            flagAssetName: parent.flagAssetName,
                            flagNote: flagNote,
                            parentID: parent.id
                        )
                    }
                )
            },
            parentPlace: parent
        )
    }
}
