import Foundation

/// Catalog content is separate from a person's travel record. Adding a country
/// requires catalog entries and flag assets, without changing the saved schema.
struct Country: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var localName: String
    var divisionLabel: String
    var groups: [DivisionGroup]
    /// For a country listed at more than one level, the ID of its first level's list on every
    /// further level's, such as France's regions on its departments. The first level is the one
    /// the sidebar shows and the World opens. Nil on every other list.
    var firstLevelID: String? = nil
    /// For a list of one place's own subdivisions, such as Tasmania's local government areas, the
    /// place they divide. The list opens from that place, as a country's opens from the World, and
    /// shares the place's ID. Nil on every other list.
    var parentPlace: AdministrativeDivision? = nil
    /// For a group of countries, how many of its members are hidden from the World, and so left
    /// out of its list (see `hiding(_:)`).
    var hiddenCount = 0

    var divisions: [AdministrativeDivision] {
        groups.flatMap(\.divisions)
    }

    var supportsLocalNames: Bool {
        divisions.contains { $0.localName != nil }
    }

    /// The ID of the country's own list: this one's, or for a further level, its first level's.
    /// For a country, its ISO code, such as FR for France's departments as well as its regions,
    /// or AU for Tasmania's local government areas.
    var countryListID: String {
        firstLevelID ?? parentPlace?.countryID ?? id
    }

    /// The national flag for this collection, or for a place's own subdivisions, that place's flag,
    /// or for a group of countries with a flag of its own, such as the EU, that one. The World and
    /// other groups have none.
    var flagAssetName: String? {
        if let parentPlace { return parentPlace.flagAssetName }
        if isGroupOfCountries { return worldGroup?.flagAssetName }
        return id == "WORLD" ? nil : "world_flag_\(countryListID.lowercased())"
    }

    /// What its list is called: the kind of places it lists, such as Prefectures, or the World's
    /// or a group's own name, such as European Union, or the place whose subdivisions it lists,
    /// such as Tasmania. A country listed at more than one level, or with lists of its places'
    /// own subdivisions, goes by its own name, such as France or Australia, and the list chooses
    /// the level beneath its map.
    var listTitle: String {
        if id == "WORLD" || isGroupOfCountries || parentPlace != nil { return name }
        let hasLevels = CountryCatalog.levels(of: self).count > 1 || !CountryCatalog.subdivisionLists(of: self).isEmpty
        return hasLevels ? name : divisionLabel
    }

    /// A name that tells the list apart from every other, as in the quiz's choice of maps: its own
    /// name, with the kind of places it lists where its country is listed at more than one level,
    /// such as "France (Departments)".
    var distinctName: String {
        CountryCatalog.levels(of: self).count > 1 ? "\(name) (\(divisionLabel))" : name
    }

    /// The group of countries this lists, such as the EU, rather than a country's own places.
    var worldGroup: WorldGroup? {
        WorldGroup(collectionID: id)
    }

    /// The ID of the group of countries the person made that this lists, if it's one of theirs.
    var customGroupID: UUID? {
        CustomWorldGroup.groupID(fromCollectionID: id)
    }

    /// Whether it lists a group of countries, one the World knows, such as the EU, or one the
    /// person made, rather than a country's own places.
    var isGroupOfCountries: Bool {
        worldGroup != nil || customGroupID != nil
    }

    /// The list without the countries hidden from the World, by ISO code, counting how many it
    /// left out, as a group of countries shows them.
    func hiding(_ codes: Set<String>) -> Country {
        guard !codes.isEmpty else { return self }
        var list = self
        var hidden = 0
        list.groups = groups.compactMap { group in
            var group = group
            let before = group.divisions.count
            group.divisions.removeAll { codes.contains($0.abbreviation) }
            hidden += before - group.divisions.count
            return group.divisions.isEmpty ? nil : group
        }
        list.hiddenCount = hidden
        return list
    }
}
