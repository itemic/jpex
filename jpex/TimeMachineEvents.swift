import SwiftUI

/// What changed: in history, a card for each change since the era before, the one in the middle
/// glowing on the map, a tap flying the map there; in deep time, the great moments, a tap
/// travelling to each. A row along the bottom, or a column at the side on wide screens.
struct TimeMachineEvents: View {
    var model: TimeMachineModel
    var isColumn: Bool
    @State private var deepEventID: String?
    @ScaledMetric(relativeTo: .footnote) private var cardHeight: CGFloat = 88

    var body: some View {
        Group {
            if isColumn {
                ScrollView {
                    LazyVStack(spacing: 12) { cards }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) { cards }
                        .scrollTargetLayout()
                }
                .scrollPosition(id: scrolledID, anchor: .center)
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .frame(height: cardHeight + 14)
            }
        }
        .scrollIndicators(.hidden)
        .allowsHitTesting(!model.isTravelling)
        .animation(.smooth(duration: 0.35), value: model.currentEra?.id)
        .animation(.smooth(duration: 0.5), value: model.presentedMode)
        .onChange(of: nearestDeepEvent?.id) { _, id in
            withAnimation(.smooth) { deepEventID = id }
        }
    }

    @ViewBuilder private var cards: some View {
        if model.presentedMode == .deepTime, let deepTime = model.atlas?.deepTime {
            ForEach(deepTime.events) { event in
                Button {
                    model.fly(toMa: event.ma)
                } label: {
                    DeepTimeEventCard(event: event, isFocused: event.id == nearestDeepEvent?.id)
                        .frame(width: isColumn ? nil : 230)
                        .frame(minHeight: cardHeight)
                }
                .buttonStyle(.plain)
            }
            .transition(.opacity)
        } else if let era = model.currentEra, let atlas = model.atlas {
            ForEach(era.events) { event in
                Button {
                    focus(on: event, atlas: atlas)
                } label: {
                    HistoryEventCard(event: event, atlas: atlas, isFocused: event.id == model.focusedEventID)
                        .frame(width: isColumn ? nil : 230)
                        .frame(minHeight: cardHeight)
                }
                .buttonStyle(.plain)
            }
            .id(era.id)
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 16)), removal: .opacity))
        }
    }

    /// The row's centred card: in history, the event in focus; in deep time, the nearest moment.
    private var scrolledID: Binding<String?> {
        if model.presentedMode == .deepTime {
            return $deepEventID
        }
        return Binding(get: { model.focusedEventID }, set: { model.focusedEventID = $0 })
    }

    /// Flies the map to an event's places, or back out if it's already there.
    private func focus(on event: HistoricalEvent, atlas: TimeMachineAtlas) {
        if model.focusedEventID == event.id, model.camera.scale > 1.05 {
            withAnimation(.smooth(duration: 0.6)) { model.camera = .whole }
            return
        }
        withAnimation(.smooth) { model.focusedEventID = event.id }
        model.frame(units: atlas.unitIndices(for: event.unitIDs), in: model.mapSize)
    }

    /// The moment of deep time closest to the scrubber.
    private var nearestDeepEvent: DeepTime.Event? {
        guard model.presentedMode == .deepTime, let events = model.atlas?.deepTime?.events else { return nil }
        return events.min { abs($0.ma - model.ma) < abs($1.ma - model.ma) }
    }
}
