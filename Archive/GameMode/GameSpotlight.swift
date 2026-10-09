import SwiftUI

/// A place lit up on Game Mode's board, and how.
struct GameSpotlight: Equatable {
    enum Style {
        /// The place in question: striped like candy, with a glow that breathes.
        case question
        /// An answer being pointed out: a glow in the colour it went, and rings when it's small.
        case answer
        /// A place lighting up and fading once in the lobby, as a taste of the game.
        case twinkle
    }

    /// How long a twinkle takes to light up and fade.
    static let twinkleDuration: TimeInterval = 1.4

    var regionIDs: [String]
    var style: Style
    var color: Color
    /// When a twinkle began. Places in question and answers stay lit.
    var start: Date?
}
