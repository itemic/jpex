import Foundation

/// How a list came to be shown in place of another: the list before it, for its map to fly over
/// from, and a place to bring into view, such as the country just come back from.
struct CollectionArrival: Equatable {
    var id = UUID()
    /// The collection shown before, for the map to fly from. Nil when the map is already there,
    /// as after flying in full screen.
    var fromID: String?
    /// The collection now shown.
    var toID: String
    /// A place in the new list to bring into view and light up for a moment.
    var revealedPlaceID: String? = nil
    /// A place on the list before whose own places the new list opens on, such as Île-de-France
    /// for France's departments, for the map to dive into.
    var fromPlaceID: String? = nil
    /// When the list was chosen, which is when its map sets off.
    var date = Date.now
    /// Which way the list came: further in, back out, or across to another level of the same place.
    var kind = Kind.into

    /// Which way a list came to take another's place, which the new list's rise into view follows:
    /// further in rises up from below, back out settles down from above, and across to another
    /// level of the same country simply fades through, the page staying where it is.
    enum Kind: Equatable {
        /// Further in, such as Japan's prefectures from the World, or a list chosen afresh.
        case into
        /// Back out, such as the World from Japan, or a country's list from one of its places'.
        case back
        /// Across to another level of the same place, such as France's departments from its regions.
        case level

        /// How far below its place the new list starts as it fades in; above, for a negative rise.
        var rise: CGFloat {
            switch self {
            case .into: 14
            case .back: -10
            case .level: 0
            }
        }
    }

    /// Whether the arrival may still be playing out. A view coming into sight after that, such as a
    /// map card scrolled back to, shows the list as it is rather than replaying how it arrived.
    var isUnderWay: Bool {
        Date.now.timeIntervalSince(date) < 5
    }
}

/// A place to bring into view in the list already open, such as one found by a search, even when
/// it's the same place as last time.
struct RevealedPlace: Equatable {
    var id: String
    var token = UUID()
}
