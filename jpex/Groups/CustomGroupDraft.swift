import Foundation

/// A group of countries being made or changed in its editor: its name, its look and its members.
struct CustomGroupDraft: Identifiable, Equatable {
    /// The group being changed, or the ID a new one will have.
    var id: UUID
    var name: String
    /// The symbol on its badge, or empty for none.
    var symbolName: String
    var tint: LevelColor
    var memberIDs: Set<String>
    /// Its badge as a flag, or nil for a plain tile in its colour.
    var flag: GroupFlag?
    /// Whether it's a group not saved yet, such as a copy of another.
    var isNew: Bool

    /// The symbol a new group starts with.
    static let newSymbolName = "star.fill"

    /// A new group, with nothing in it yet.
    init(tint: LevelColor) {
        id = UUID()
        name = ""
        symbolName = Self.newSymbolName
        self.tint = tint
        memberIDs = []
        flag = nil
        isNew = true
    }

    /// One of the person's groups, to change.
    init(editing group: CustomWorldGroup) {
        id = group.id
        name = group.name
        symbolName = group.symbolName
        tint = group.tint
        memberIDs = group.memberIDs
        flag = group.flag
        isNew = false
    }

    /// The flag being designed: the group's own, or a plain one in its colour to start from.
    /// Setting it takes the group's colour from the flag's, where it has one, so its cards and
    /// buttons match, and its symbol from the flag's first, for a plain tile.
    var design: GroupFlag {
        get { (flag ?? GroupFlag(plain: tint)).resolvingSymbols(fallback: symbolName) }
        set {
            flag = newValue
            if let accent = newValue.accent { tint = accent }
            symbolName = newValue.symbols?.first?.name ?? ""
        }
    }

    /// A new group starting as a copy of one of the person's own, to change from there.
    init(copying group: CustomWorldGroup) {
        self.init(editing: group)
        id = UUID()
        name = "\(group.name) Copy"
        isNew = true
    }

    /// A new group starting from one of the World's, such as the EU, with its members and look, to
    /// add to or take from.
    init(copying group: WorldGroup) {
        id = UUID()
        name = "\(group.name) Copy"
        symbolName = group.symbolName
        tint = group.copyTint
        memberIDs = Set(group.collection.divisions.map(\.id))
        flag = nil
        isNew = true
    }

    /// The name as it's saved, without spaces around it.
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether it can be saved: it needs a name, and at least one country.
    var canSave: Bool {
        !trimmedName.isEmpty && !memberIDs.isEmpty
    }

    func contains(_ place: AdministrativeDivision) -> Bool {
        memberIDs.contains(place.id)
    }

    /// Whether there are places here and every one of them is in.
    func containsAll(_ places: [AdministrativeDivision]) -> Bool {
        !places.isEmpty && places.allSatisfy(contains)
    }

    mutating func toggle(_ place: AdministrativeDivision) {
        if memberIDs.remove(place.id) == nil {
            memberIDs.insert(place.id)
        }
    }

    /// Puts every one of these places in, or where they're all in already, takes them all out.
    /// Returns the places that went in or came out, in the order given.
    @discardableResult
    mutating func toggleAll(_ places: [AdministrativeDivision]) -> [AdministrativeDivision] {
        if containsAll(places) {
            for place in places { memberIDs.remove(place.id) }
            return places
        }
        let added = places.filter { !contains($0) }
        for place in added { memberIDs.insert(place.id) }
        return added
    }

    /// The group as it's saved.
    var group: CustomWorldGroup {
        CustomWorldGroup(
            id: id, name: trimmedName, symbolName: symbolName, tint: tint, memberIDs: memberIDs, flag: flag)
    }
}
