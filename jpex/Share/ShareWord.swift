import SwiftUI

/// A place as the typographic designs set it: its name in the list's language, its level, how high
/// that level stands among the person's levels, and its flag, for setting the name in its colours.
struct ShareWord: Identifiable, Sendable {
    var id: String
    var name: String
    var level: VisitLevel
    /// From 0 for the lowest level to 1 for the highest; 0 for somewhere not yet been to.
    var height: Double
    /// The place's flag's asset name.
    var flag: String
    /// The place's own colour when the places are coloured smartly.
    var smart: Color?

    var isVisited: Bool { level.id != VisitLevel.never.id }
}
