#if os(visionOS)
import SwiftData
import SwiftUI

/// A list's map out of its window, hanging in the room on its own: no glass and no sea behind it,
/// only the land, each place in the colour of its level, with the list's name and count beneath.
/// It keeps up as places change level in the list.
struct FloatingMapView: View {
    var listID: String
    @Environment(CountingPreferences.self) private var counting
    @Environment(CustomWorldGroups.self) private var customGroups
    @Query private var saveModels: [SaveModel]
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard

    var body: some View {
        if let list, let map = TravelMap.named(list.id, projection: projection, center: center) {
            let snapshot = SaveModel.kept(of: saveModels)?.snapshot()
            let ladder = snapshot?.ladder ?? .standard
            let statuses = Dictionary(uniqueKeysWithValues: list.divisions.map { ($0.id, snapshot?.status(for: $0) ?? .never) })
            let counted = snapshot?.count(in: list.divisions, counting: counting.rules) ?? 0
            let focus = map.focusRect(including: statuses.keys)
            let aspect = focus.width / max(focus.height, 1)
            TravelMapCanvas(
                map: map, statuses: statuses, minimumStatus: counting.rules.minimumLevel(in: ladder),
                focus: focus, drawsBackdrop: false, tiles: false)
                .aspectRatio(aspect, contentMode: .fit)
                // The window opens the map's own shape, with no empty window round it to stand in
                // front of others and fade them.
                .frame(
                    minWidth: 320, idealWidth: Self.longestSide * min(aspect, 1), maxWidth: .infinity,
                    minHeight: 320, idealHeight: Self.longestSide / max(aspect, 1), maxHeight: .infinity)
                .environment(\.visitLadder, ladder)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Map of \(list.listTitle)")
                .accessibilityValue("\(counted) of \(list.divisions.count)")
                .ornament(attachmentAnchor: .scene(.bottom)) {
                    SpatialMapLabel(title: list.listTitle, counted: counted, total: list.divisions.count)
                }
        } else {
            // Such as a group of the person's own deleted since its map was floated.
            ContentUnavailableView("No map", systemImage: "map")
                .padding()
                .glassBackgroundEffect()
        }
    }

    /// How long the map's longer side is when it first floats out, in points.
    private static let longestSide: CGFloat = 900

    /// The list, found as the lists' window finds it: a country's own, or a group of countries'.
    private var list: Country? {
        let rules = counting.rules
        if let country = CountryCatalog.countries(applying: rules).first(where: { $0.id == listID }) {
            return country
        }
        return (customGroups.collections(applying: rules) + WorldGroup.collections)
            .first { $0.id == listID }?
            .hiding(rules.hiddenStates)
    }
}
#endif
