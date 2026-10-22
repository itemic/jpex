import Foundation

/// The groups of countries kept out of the sidebar, by their lists' IDs: the World's, such as the
/// EU, and the person's own. A hidden group is still there, with its list and its quiz; Show
/// Hidden at the end of World Groups brings it back into view.
struct HiddenWorldGroups: RawRepresentable, Equatable {
    var ids: Set<String> = []

    static let storageKey = "hiddenWorldGroups"

    /// The groups hidden until the person chooses otherwise: every one of the World's but a few
    /// of the best known. Groups of their own always start shown.
    init() {
        ids = Set(WorldGroup.allCases.filter { !Self.shownByDefault.contains($0) }.map(\.collectionID))
    }

    /// The World's groups the sidebar shows before anything is hidden or unhidden.
    static let shownByDefault: Set<WorldGroup> = [
        .unitedNations, .europeanUnion, .schengen, .asean, .gulfCooperation, .africanUnion,
    ]

    init(rawValue: String) {
        ids = Set(rawValue.split(separator: "\n").map(String.init))
    }

    /// One ID per line, as it's saved.
    var rawValue: String {
        ids.sorted().joined(separator: "\n")
    }

    /// The groups hidden as saved now, for code outside a view.
    static var current: HiddenWorldGroups {
        UserDefaults.standard.string(forKey: storageKey).map(HiddenWorldGroups.init(rawValue:)) ?? HiddenWorldGroups()
    }

    func isHidden(_ id: String) -> Bool {
        ids.contains(id)
    }

    mutating func setHidden(_ isHidden: Bool, for id: String) {
        if isHidden {
            ids.insert(id)
        } else {
            ids.remove(id)
        }
    }

    /// Lists split into those the sidebar shows and those it hides, each in the order given.
    func split(_ lists: [Country]) -> (shown: [Country], hidden: [Country]) {
        (lists.filter { !isHidden($0.id) }, lists.filter { isHidden($0.id) })
    }
}
