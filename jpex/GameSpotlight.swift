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
        /// A dot marking a place, in Dot, with nothing else of it lit.
        case marker
    }

    /// How long a twinkle takes to light up and fade, long enough to read the name beside it.
    static let twinkleDuration: TimeInterval = 2.2

    var regionIDs: [String]
    var style: Style
    var color: Color
    /// Cities to mark, such as a country's capitals.
    var cities: [City] = []
    /// The main body of the place, in map units, for the lights to keep to: far-flung islands drawn
    /// as part of it, such as a country's overseas departments, stay dark.
    var mainBody: CGRect?
    /// Where a marker's dot goes, in map units.
    var marker: CGPoint?
    /// The place's name, floating beside it while it twinkles.
    var caption: Caption?
    /// When a twinkle began. Places in question and answers stay lit.
    var start: Date?

    /// A city marked with a dot and its name.
    struct City: Equatable {
        var name: String
        /// Where it is, in map units.
        var point: CGPoint
    }

    /// A place's name to float beside it, with its flag where it has one of its own.
    struct Caption: Equatable {
        var name: String
        var language: Locale.Language?
        var flagAssetName: String?
        /// The main body of the place, in map units, for setting the name just above it.
        var frame: CGRect
    }
}
