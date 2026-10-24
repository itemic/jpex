#if os(visionOS)
import SwiftUI

/// The windows Apple Vision Pro opens beside the lists, so the map can leave its window and float in
/// the room: the World as a globe, and any list's map flat, with nothing behind it.
enum SpatialWindow: String {
    case globe
    case floatingMap

    /// Whether the globe has floated out by itself, as it does the first time the welcome's over.
    /// After that it comes back as the person left it, or from the World's Globe button.
    static let hasFloatedGlobeKey = "hasFloatedGlobe"

    /// What the globe's window presents: the World, always, so there's only ever one globe.
    static let globeValue = CountryCatalog.world.id
}

extension OpenWindowAction {
    /// Floats the World out as a globe, or brings the globe already out to the front.
    func openGlobe() {
        self(id: SpatialWindow.globe.rawValue, value: SpatialWindow.globeValue)
    }
}
#endif
