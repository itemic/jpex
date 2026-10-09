import SwiftUI

/// One step on the person's ladder of how well they know a place, such as Passed or Lived.
/// Places save only the ID, so renaming, recolouring or reordering a level keeps every place marked with it.
struct VisitLevel: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var tint: LevelColor
    var symbolName: String
    /// The texture the level wears over its colour, or nil to take one from its place on the ladder.
    var pattern: LevelPatternStyle? = nil

    var color: Color { tint.color }

    /// Somewhere not visited yet. It sits below every level and can't be renamed or removed.
    static let never = VisitLevel(id: "never", name: "Never been", tint: .gray, symbolName: "circle")
}
