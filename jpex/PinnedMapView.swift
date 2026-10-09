import SwiftUI

/// The collection's map, held on the far side of the fold while iPhone Duo sits partially folded,
/// with the list on the near side. Tap a place to find it in the list; the corner button opens the
/// full map, which grows out of this one.
struct PinnedMapView: View {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    var minimumStatus: VisitLevel
    /// The place just found in the list, outlined on the map.
    var highlightedID: String?
    /// The flight over from the list before, when this list has just taken its place.
    var journey: MapJourney? = nil
    var onSelect: (String) -> Void
    var onOpen: () -> Void
    var onFrameChange: (CGRect) -> Void
    @State private var selections = 0
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @AppStorage(DayNight.storageKey) private var showsDayNight = false
    @State private var spinner = WorldSpinner()

    private let insets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

    var body: some View {
        GeometryReader { proxy in
            let geometry = MapGeometry(
                focus: map.focusRect(including: statuses.keys), size: proxy.size, zoom: 1, pan: .zero, insets: insets)
            MapJourneyView(journey: journey, minimumStatus: minimumStatus, insets: insets) {
                TimelineView(.animation(paused: !spinner.isTurning)) { timeline in
                    ZoomingMapCanvas(
                        map: spinner.turnedWorld(projection, at: timeline.date) ?? map, statuses: statuses,
                        minimumStatus: minimumStatus, insets: insets, selection: highlightedID)
                }
            }
                .environment(\.showsDayNight, showsDayNight)
                .turnsWorld(spinner, center: $center, isEnabled: TravelMap.showsWorld(places: statuses.keys))
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard let region = map.place(at: location, geometry: geometry, among: Set(statuses.keys)) else { return }
                    selections += 1
                    onSelect(region.id)
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrameChange($0) }
                .accessibilityElement()
                .accessibilityLabel("Map")
                .accessibilityHint("Tap a place to find it in the list.")
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: onOpen) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .glassPanel(in: Circle(), interactive: true)
                    .contentShape(Circle())
            }
            .buttonStyle(PillButtonStyle())
            .padding(12)
            .accessibilityLabel("Open map")
        }
        .sensoryFeedback(.selection, trigger: selections)
    }
}
