import Foundation

/// The set of a list's places people usually mean by it, such as the United States' fifty states,
/// to quiz on in place of ten or all of them: the everyday whole, without far-flung territories.
struct PlaceSet: Identifiable, Hashable {
    var id: String
    /// What it's called, with how many places it holds, such as "50 states".
    var name: String
    var placeIDs: Set<String>

    /// The sets for some of a list's places, each only where it holds some of them but not all.
    static func sets(for collectionID: String, among places: [AdministrativeDivision]) -> [PlaceSet] {
        definitions.compactMap { definition in
            guard definition.collectionID == collectionID else { return nil }
            let ids = Set(places.filter(definition.includes).map(\.id))
            guard !ids.isEmpty, ids.count < places.count else { return nil }
            return PlaceSet(id: definition.id, name: definition.name(ids.count), placeIDs: ids)
        }
    }

    private struct Definition {
        var id: String
        var collectionID: String
        var name: (Int) -> String
        var includes: (AdministrativeDivision) -> Bool
    }

    private static let definitions: [Definition] = [
        Definition(id: "US-states", collectionID: "US", name: { "\($0) states" }) { $0.groupID == "US-states" },
        Definition(id: "US-states-dc", collectionID: "US", name: { "\($0 - 1) states + DC" }) {
            $0.groupID == "US-states" || $0.groupID == "US-federal"
        },
        // The six states and the two big mainland territories, without Jervis Bay or the islands offshore.
        Definition(id: "AU-states-territories", collectionID: "AU", name: { "\($0) states & territories" }) {
            $0.groupID == "AU-states" || $0.id == "AU-ACT" || $0.id == "AU-NT"
        },
        Definition(id: "WORLD-un", collectionID: CountryCatalog.world.id, name: { "\($0) UN members" }) {
            unitedNationsIDs.contains($0.id)
        },
    ]

    private static let unitedNationsIDs = Set(WorldGroup.unitedNations.collection.divisions.map(\.id))
}
