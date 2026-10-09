import SwiftUI

/// A place tapped or named by mistake, flashing red on Game Mode's board with its name beside it,
/// so every wrong answer still shows where something is.
struct GameFlash: Equatable, Identifiable {
    /// How long the flash takes to fade.
    static let duration: TimeInterval = 1.5

    var id = UUID()
    var regionIDs: [String]
    var name: String
    var language: Locale.Language?
    var flagAssetName: String
    /// Where to set the name, in map units, so it stays with the place as the camera moves.
    var anchor: CGPoint
    var start = Date.now
}
