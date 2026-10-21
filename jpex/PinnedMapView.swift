import SwiftUI

/// The collection's map, held on the far side of the fold while iPhone Duo sits partially folded,
/// or beside the list on any page wide enough, with the list on the near side. It answers taps as
/// the list's own map card does: tap a place to find it in the list, tap it again or tap the sea to
/// open the full map, which grows out of this one. The toolbar's Map button opens it straight away.
struct PinnedMapView: View {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    var minimumStatus: VisitLevel
    /// The place just found in the list, outlined on the map.
    var highlightedID: String?
    /// The flight over from the list before, when this list has just taken its place.
    var journey: MapJourney? = nil
    /// The list's count, once its total has scrolled away beneath the map, small in a corner.
    var badge: TravelTotalView? = nil
    var onSelect: (String) -> Void
    var onOpen: () -> Void
    var onFrameChange: (CGRect) -> Void
    @State private var selections = 0
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @State private var spinner = WorldSpinner()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let insets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

    /// A place tapped goes to the list to be found there; the sea opens the map, as on the list's
    /// own card. Only a place found ticks.
    private func tap(_ placeID: String?) {
        spinner.touch()
        guard let placeID else {
            onOpen()
            return
        }
        selections += 1
        onSelect(placeID)
    }

    var body: some View {
        MapJourneyView(journey: journey, minimumStatus: minimumStatus, insets: insets) {
            TimelineView(.animation(paused: !spinner.isTurning)) { timeline in
                // Taps are found on the map as it's drawn, turned and wherever its camera has
                // flown, so a tap always lands on the place under the finger.
                ZoomingMapCanvas(
                    map: spinner.turnedWorld(projection, at: timeline.date) ?? map, statuses: statuses,
                    minimumStatus: minimumStatus, insets: insets, selection: highlightedID, onTap: tap)
            }
        }
        // Its land fades away towards the pane's edges, into the page, as the list's map does.
        .mask { EdgeFade() }
        .showsWorldLayers()
        .turnsWorld(spinner, center: $center, isEnabled: TravelMap.showsWorld(places: statuses.keys))
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrameChange($0) }
        .accessibilityElement()
        .accessibilityLabel("Map")
        .accessibilityHint(MapCard.findingHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onOpen)
        // In whichever corner hides the least of the map, as on the list's own card. Taps pass through it.
        .overlay {
            GeometryReader { proxy in
                if let badge {
                    let corner = MapCard.clearestCorner(of: map, places: statuses.keys, in: proxy.size, insets: insets)
                    badge
                        .padding(12)
                        // Springs out of its corner, or with Reduce Motion, fades.
                        .transition(.arrive(reduceMotion: reduceMotion, anchor: corner.unitPoint))
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: corner)
                        .allowsHitTesting(false)
                }
            }
        }
        .animation(.snappy(duration: 0.3), value: badge == nil)
        .sensoryFeedback(.selection, trigger: selections)
    }
}
