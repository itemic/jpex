import Foundation

/// How many places a round of Game Mode asks about.
enum MapGameLength: String, CaseIterable, Identifiable {
    /// Ten places, or all of them when there are fewer.
    case ten
    /// Every place in play, each once.
    case every

    var id: Self { self }

    /// The number of questions, given how many places are in play.
    func count(from available: Int) -> Int {
        switch self {
        case .ten: min(10, available)
        case .every: available
        }
    }
}
