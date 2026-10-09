import Foundation

/// Catalog content is separate from a person's travel record. Adding a country
/// requires catalog entries and flag assets, without changing the saved schema.
struct Country: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var localName: String
    var divisionLabel: String
    var groups: [DivisionGroup]

    var divisions: [AdministrativeDivision] {
        groups.flatMap(\.divisions)
    }

    var supportsLocalNames: Bool {
        divisions.contains { $0.localName != nil }
    }

    /// The national flag for this collection; the World and groups of countries have none.
    var flagAssetName: String? {
        id == "WORLD" || worldGroup != nil ? nil : "world_flag_\(id.lowercased())"
    }

    /// What its list is called: the kind of places it lists, such as Prefectures, or the World's
    /// or a group's own name, such as European Union.
    var listTitle: String {
        id == "WORLD" || worldGroup != nil ? name : divisionLabel
    }

    /// The group of countries this lists, such as the EU, rather than a country's own places.
    var worldGroup: WorldGroup? {
        WorldGroup(collectionID: id)
    }
}
