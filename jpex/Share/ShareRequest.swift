import Foundation

/// A nudge for a list to open its share screen on the places just been to, as from a toast's Share.
struct ShareRequest: Equatable {
    var collectionID: String
    var token = UUID()
}
