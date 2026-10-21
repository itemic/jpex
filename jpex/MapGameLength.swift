import Foundation

/// How many places a round of Game Mode asks about.
enum MapGameLength: String, CaseIterable, Identifiable {
    /// Ten places, or all of them when there are fewer.
    case ten
    /// Every place in play, each once.
    case every
    /// As many as the person chooses, or all of them when there are fewer.
    case custom

    var id: Self { self }

    /// The number of questions, given how many places are in play and how many the person chose.
    func count(from available: Int, custom: Int) -> Int {
        switch self {
        case .ten: min(10, available)
        case .every: available
        case .custom: min(max(custom, 1), available)
        }
    }
}
