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
        /// A dot marking a place, with nothing else of it lit: the place in question in Dot, and in
        /// Find with the borders hidden, where the place waiting to be confirmed was tapped.
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
    /// When a twinkle began, or when a marker's dot dropped in, for it to land and send a ring out.
    /// Places in question and answers stay lit.
    var start: Date?
    /// When the light came on: an answer's glow, such as a place chosen in Find or an answer just
    /// given, or the place in question's candy, as the camera lands on it. Until then the place
    /// stays dark; from then it comes up over a marker's drop and sends one ring out as it lands,
    /// as the dot does, rather than appearing; nil once it's up, and it simply stays lit.
    var litAt: Date?

    /// How long a marker's dot takes to drop in and land: a quick swell past its size and a settle.
    static let markerDrop: TimeInterval = 0.35
    /// How long the ring a marker sends out on landing takes to spread and fade.
    static let markerRing: TimeInterval = 0.6

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
