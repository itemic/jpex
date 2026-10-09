import SwiftUI

/// A list's map at rest, with the journey from the list before played over it as the list takes
/// that one's place. The journey runs from the moment the list was chosen, so a map that comes
/// into view partway through joins it there, and one that comes into view later simply rests.
/// Once the journey lands, the map at rest, drawn exactly where the journey ends, takes over.
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
                            morph: frame.leg?.local, morphProgress: frame.morphProgress, detailIsLeaving: frame.isLeaving)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .transition(.opacity)
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
