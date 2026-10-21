import SwiftUI

/// What's drawn over World maps, which always wear the person's own levels: the Equator and
/// tropics, and the antipodes, as toggles in a list's eye menu. The full map offers the same as
/// cards in its layer chooser. Night and day are World Time's, in the time zones.
struct WorldLayerControls: View {
    @AppStorage(WorldLayers.latitudesKey) private var showsLatitudes = false
    @AppStorage(WorldLayers.antipodesKey) private var showsAntipodes = false

    var body: some View {
        Toggle("Equator & tropics", systemImage: "circle.and.line.horizontal", isOn: $showsLatitudes)
        Toggle("Antipodes", systemImage: Antipodes.symbolName, isOn: $showsAntipodes)
    }
}
