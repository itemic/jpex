import Foundation
import Observation

/// The groups of countries the person has made, kept in UserDefaults across launches. Shared, so
/// a map or a quiz found by a list's ID alone can find a group's members too.
@MainActor @Observable
final class CustomWorldGroups {
    static let shared = CustomWorldGroups()

    /// In the order they were made.
    private(set) var groups: [CustomWorldGroup] {
        didSet {
            if groups != oldValue, let data = try? JSONEncoder().encode(groups) {
                defaults.set(data, forKey: Self.storageKey)
            }
        }
    }

    /// The lists last built for the groups, and the rules they were built under, so the sidebar,
    /// drawn many times over, doesn't gather every place in the World each time.
    @ObservationIgnored private var cachedCollections: (rules: CountingRules, groups: [CustomWorldGroup], lists: [Country])?

    private let defaults: UserDefaults
    private static let storageKey = "customWorldGroups"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let data = defaults.data(forKey: Self.storageKey)
        if let data, let saved = try? JSONDecoder().decode([CustomWorldGroup].self, from: data) {
            groups = saved
        } else {
            // Groups that can't be read are put aside rather than written over by the next change.
            if let data { defaults.set(data, forKey: Self.storageKey + ".unreadable") }
            groups = []
        }
    }

    func group(id: UUID) -> CustomWorldGroup? {
        groups.first { $0.id == id }
    }

    /// The group whose list has this ID, if it's one of the person's.
    func group(collectionID: String) -> CustomWorldGroup? {
        CustomWorldGroup.groupID(fromCollectionID: collectionID).flatMap(group(id:))
    }

    /// Adds a new group, or saves the changes to one already made.
    func save(_ group: CustomWorldGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.append(group)
        }
    }

    func delete(_ id: UUID) {
        groups.removeAll { $0.id == id }
    }

    /// Deletes every group the person made.
    func deleteAll() {
        groups = []
    }

    /// Every group's list, A to Z by name, as the counting rules shape Countries.
    func collections(applying rules: CountingRules) -> [Country] {
        if let cached = cachedCollections, cached.rules == rules, cached.groups == groups { return cached.lists }
        let places = groups.isEmpty ? [] : CountryCatalog.groupablePlaces(applying: rules)
        let lists = groups
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { $0.collection(from: places) }
        cachedCollections = (rules, groups, lists)
        return lists
    }

    /// A colour for a new group: the first that none of the person's groups wears yet, so each
    /// new one stands apart, then round again.
    var suggestedTint: LevelColor {
        let worn = Set(groups.map(\.tint))
        return LevelColor.choices.first { !worn.contains($0) }
            ?? LevelColor.choices[groups.count % LevelColor.choices.count]
    }

    /// The editor's starting point for a group: empty for a new one, as it is for one to change,
    /// or with another group's members and look for a copy, such as the EU to add to.
    func draft(for target: GroupEditorTarget) -> CustomGroupDraft? {
        switch target {
        case .new:
            return CustomGroupDraft(tint: suggestedTint)
        case .edit(let id):
            return group(id: id).map(CustomGroupDraft.init(editing:))
        case .copy(let collectionID):
            if let worldGroup = WorldGroup(collectionID: collectionID) {
                return CustomGroupDraft(copying: worldGroup)
            }
            return group(collectionID: collectionID).map(CustomGroupDraft.init(copying:))
        }
    }
}
