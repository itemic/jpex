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
    /// When the list was chosen, which is when its map sets off.
    var date = Date.now

    /// Whether the arrival may still be playing out. A view coming into sight after that, such as a
    /// map card scrolled back to, shows the list as it is rather than replaying how it arrived.
    var isUnderWay: Bool {
        Date.now.timeIntervalSince(date) < 5
    }
}
