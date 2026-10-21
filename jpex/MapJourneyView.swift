import SwiftUI

/// A list's map at rest, with the journey from the list before played over it as the list takes
/// that one's place. The journey runs from the moment the list was chosen, so a map that comes
/// into view partway through joins it there, and one that comes into view later simply rests.
/// Once the journey lands, the map at rest, drawn exactly where the journey ends, takes over.
///
/// The map at rest never fades itself: it is hidden while the journey flies and shown again the
/// moment it lands, beneath the journey, which then fades away over it. So a map that stays in
/// place while its list changes, such as the one beside the list on iPad or a partly folded
/// iPhone Duo, never flashes the destination before the flight, and never dims as it lands.
struct MapJourneyView<Resting: View>: View {
    var journey: MapJourney?
    var minimumStatus: VisitLevel
    var insets = EdgeInsets()
    @ViewBuilder var resting: Resting
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The arrival whose journey has landed.
    @State private var landedID: UUID?

    var body: some View {
        ZStack {
            resting
                .opacity(isFlying ? 0 : 1)
                // Never faded along with whatever else is changing, such as the list around it.
                .animation(nil, value: isFlying)
            if isFlying, let journey {
                TimelineView(.animation) { timeline in
                    GeometryReader { proxy in
                        let frame = journey.frame(
                            at: timeline.date.timeIntervalSince(journey.arrival.date), size: proxy.size, insets: insets)
                        TravelMapCanvas(
                            map: frame.turningLongitude.map(journey.world(turnedTo:)) ?? journey.world,
                            statuses: journey.worldStatuses, minimumStatus: minimumStatus,
                            zoom: frame.camera.zoom, pan: frame.camera.pan, insets: insets, focus: journey.worldFocus,
                            revealsOnAppear: false, selection: frame.selection,
                            detail: frame.leg?.detail, detailProgress: frame.detailProgress,
                            morph: frame.leg?.local, morphProgress: frame.morphProgress, detailIsLeaving: frame.isLeaving,
                            detailWash: journey.detailWash)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                // Takes off at once, from exactly where the map at rest was, and fades away over
                // the map at rest as it lands.
                .transition(.asymmetric(insertion: .identity, removal: .opacity))
            }
        }
        .task(id: journey?.arrival.id) {
            guard let journey else { return }
            let remaining = journey.duration - Date.now.timeIntervalSince(journey.arrival.date)
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { landedID = journey.arrival.id }
        }
    }

    private var isFlying: Bool {
        guard let journey, landedID != journey.arrival.id, !reduceMotion else { return false }
        return Date.now.timeIntervalSince(journey.arrival.date) < journey.duration
    }
}
