import Foundation

/// A group of countries the person makes for themselves, such as Trips with Mum or a bucket list.
/// It's listed with the World Groups and works as they do: a list of its own, drawn from Countries
/// and sharing its statuses, on the World map zoomed to its members, with a quiz of its own.
/// Members are kept by their permanent IDs, so they follow renames, and a member stays in the
/// group whatever counts as a country.
struct CustomWorldGroup: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
    /// The symbol on its badge, or empty for none.
    var symbolName: String
    /// Its colour: its badge's, unless it has a flag, and its cards' and buttons'.
    var tint: LevelColor
    /// Members by their IDs in Countries, such as WORLD-FR, or CN-HK for a place it shares.
    var memberIDs: Set<String> = []
    /// Its badge drawn as a flag of the person's design, such as a tricolour, in place of a plain
    /// tile in its colour. Nil for the plain tile.
    var flag: GroupFlag? = nil

    /// Lists of the person's groups have IDs of their own, apart from every country's and the
    /// World Groups'.
    private static let idPrefix = "MYGROUP-"

    var collectionID: String { Self.idPrefix + id.uuidString }

    /// The ID of the group whose list has this ID, if it is one.
    static func groupID(fromCollectionID collectionID: String) -> UUID? {
        guard collectionID.hasPrefix(idPrefix) else { return nil }
        return UUID(uuidString: String(collectionID.dropFirst(idPrefix.count)))
    }

    /// The group as a list: its members under their continents, each continent A to Z, where the
    /// counting rules put them.
    func collection(applying rules: CountingRules) -> Country {
        collection(from: CountryCatalog.groupablePlaces(applying: rules))
    }

    /// The group as a list, from places already gathered, so several groups can share them.
    func collection(from places: [AdministrativeDivision]) -> Country {
        let groups = CountryCatalog.continents(of: places.filter { memberIDs.contains($0.id) })
        return Country(id: collectionID, name: name, localName: name, divisionLabel: "Countries", groups: groups)
    }
}

extension CountryCatalog {
    /// Every place a group of countries can hold, under the continent the counting rules put it
    /// in: the countries as the rules count them, then the places they leave out, such as a
    /// territory switched off, or the United Kingdom's nations while it counts as one, so a member
    /// keeps its place whatever counts as a country.
    static func groupablePlaces(applying rules: CountingRules) -> [AdministrativeDivision] {
        var otherUnitedKingdom = rules
        otherUnitedKingdom.splitsUnitedKingdom.toggle()
        var seen: Set<String> = []
        return (world(applying: rules).divisions + world.divisions + world(applying: otherUnitedKingdom).divisions)
            .filter { seen.insert($0.id).inserted }
    }

    /// Places under their continents, in the World's order, each continent A to Z.
    static func continents(of places: [AdministrativeDivision]) -> [DivisionGroup] {
        let byContinent = Dictionary(grouping: places, by: \.groupID)
        return world.groups.compactMap { continent in
            guard let members = byContinent[continent.id] else { return nil }
            var group = continent
            group.divisions = members.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return group
        }
    }
}
