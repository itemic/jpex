import Foundation

/// The person's levels, lowest first, such as Passed through to Lived.
/// Never been sits below them all and isn't part of the list.
struct VisitLadder: Codable, Equatable, Sendable {
    var levels: [VisitLevel]

    /// Room for fine distinctions while every level still fits comfortably on screen.
    static let maximumCount = 10

    /// The original five levels. Their IDs are the keys places were saved with before levels could change.
    static let standard = VisitLadder(levels: [
        VisitLevel(id: "passed", name: "Passed", tint: .lightBlue, symbolName: "arrow.right"),
        VisitLevel(id: "alighted", name: "Alighted", tint: .green, symbolName: "figure.walk"),
        VisitLevel(id: "visited", name: "Visited", tint: .yellow, symbolName: "mappin"),
        VisitLevel(id: "stayed", name: "Stayed", tint: .orange, symbolName: "moon"),
        VisitLevel(id: "lived", name: "Lived", tint: .red, symbolName: "house.fill"),
    ])

    /// Never been, then every level, lowest first.
    var allLevels: [VisitLevel] {
        [.never] + levels
    }

    /// At least one level, none beyond the limit, every ID unique and every level named.
    var isValid: Bool {
        let ids = Set(levels.map(\.id))
        return !levels.isEmpty && levels.count <= Self.maximumCount && ids.count == levels.count
            && !ids.contains(VisitLevel.never.id)
            && levels.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// The level with this ID, including never been.
    func level(id: String) -> VisitLevel? {
        id == VisitLevel.never.id ? .never : levels.first { $0.id == id }
    }

    /// 0 for never been, then 1 for the lowest level and up.
    /// A level missing from the ladder ranks with never been.
    func rank(of level: VisitLevel) -> Int {
        levels.firstIndex { $0.id == level.id }.map { $0 + 1 } ?? 0
    }

    /// The texture a level wears: the one chosen for it, or else one from its place on the ladder.
    /// Never been has none.
    func patternStyle(of level: VisitLevel) -> LevelPatternStyle? {
        let rank = rank(of: level)
        guard rank > 0 else { return nil }
        return levels[rank - 1].pattern ?? LevelPatternStyle(rank: rank)
    }

    /// One step up, wrapping from the highest level back to never been.
    func next(after level: VisitLevel) -> VisitLevel {
        let all = allLevels
        return all[(rank(of: level) + 1) % all.count]
    }

    /// One step up, without wrapping around.
    func higher(than level: VisitLevel) -> VisitLevel? {
        let rank = rank(of: level)
        return rank < levels.count ? levels[rank] : nil
    }

    /// One step down, without wrapping around.
    func lower(than level: VisitLevel) -> VisitLevel? {
        let rank = rank(of: level)
        return rank > 0 ? allLevels[rank - 1] : nil
    }

    /// This level and every level above it.
    func levels(from minimum: VisitLevel) -> ArraySlice<VisitLevel> {
        levels[max(rank(of: minimum) - 1, 0)...]
    }

    /// Where places go when their level is removed: down to the closest level below it
    /// that remains, or to never been. Keyed by the removed level's ID.
    func replacements(becoming new: VisitLadder) -> [String: VisitLevel] {
        var replacements: [String: VisitLevel] = [:]
        for (index, level) in levels.enumerated() where new.level(id: level.id) == nil {
            let remainingBelow = levels[..<index].reversed().lazy.compactMap { new.level(id: $0.id) }
            replacements[level.id] = remainingBelow.first ?? .never
        }
        return replacements
    }
}
