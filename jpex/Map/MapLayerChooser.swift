import SwiftUI

/// What the full map shows, chosen in the map's own panel rather than from a menu: a card for each
/// layer under Show, as the quiz lists its answers, the person's travels first, then the Atlas's
/// cards, and on the World the time zones and the facts a traveller wants to know before going,
/// each with its symbol in its own colour; beneath them on the World, under Overlays, the lines
/// and shapes that can be drawn over any of them, the Equator and tropics, and the antipodes, which
/// switch on and off where they are; and last, under Map, whether places carry their names, and on
/// the World the projection it's drawn in. Choosing a layer
/// lights its card and bounces its symbol for a beat, then puts the chooser away again, and the
/// countries sweep across into their new colours; an overlay, a projection or the names change in
/// place, so several can be tried in turn. The cards rise in one after another as it opens.
struct MapLayerChooser: View {
    /// The layer the map shows now, lit among the cards.
    var current: MapLayer
    /// The layers to offer: the World's every one, or another map's travels and Atlas.
    var layers: [MapLayer] = MapLayer.all
    /// True when the chooser has a region of its own beside the map, as on iPhone Duo's near side.
    var isSeparate: Bool
    /// The most room the cards may take before they scroll.
    var maxGridHeight: CGFloat
    /// Whether to offer the Map section, with place names.
    var showsMapSection: Bool = false
    /// Whether the map is the World's, which alone has overlays and projections.
    var isWorld: Bool = true
    /// Called a short beat after a layer's card is tapped, once it has lit up.
    var onChoose: (MapLayer) -> Void
    var onClose: () -> Void
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(WorldLayers.latitudesKey) private var showsLatitudes = false
    @AppStorage(WorldLayers.antipodesKey) private var showsAntipodes = false
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage("mapShowsLabels") private var showsLabels = true
    /// The layer just tapped, lit while the beat before it's chosen plays; further taps wait.
    @State private var choosing: MapLayer?
    /// The beat before the tapped layer is handed on, let go if the chooser closes first.
    @State private var pendingChoice: Task<Void, Never>?
    /// How tall the cards stand, roughly two columns' worth to begin with so the glass opens
    /// close to its size before they're measured.
    @State private var gridHeight: CGFloat = 300
    /// How much larger the person's text is than standard, for the cards to grow with it.
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1
    /// Whether the cards have risen in, set just after the chooser appears.
    @State private var hasRisen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150 * textScale), spacing: 8)], spacing: 8) {
                    Section {
                        ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                            layerCard(layer)
                                .modifier(CardRise(index: index, hasRisen: hasRisen))
                        }
                    } header: {
                        CardGridHeader(title: "Show")
                    }
                    if isWorld {
                        Section {
                            ForEach(Array(overlays.enumerated()), id: \.element.title) { index, overlay in
                                overlayCard(overlay)
                                    .modifier(CardRise(index: layers.count + index, hasRisen: hasRisen))
                            }
                        } header: {
                            CardGridHeader(title: "Overlays", detail: overlaysDetail)
                        }
                    }
                    if showsMapSection {
                        let before = layers.count + (isWorld ? overlays.count : 0)
                        Section {
                            if isWorld {
                                projectionMenu
                                    .modifier(CardRise(index: before, hasRisen: hasRisen))
                            }
                            labelsCard
                                .modifier(CardRise(index: before + 1, hasRisen: hasRisen))
                        } header: {
                            CardGridHeader(title: "Map")
                        }
                    }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { gridHeight = $0 }
            }
            .cardGridScrolling()
            .padding(.horizontal, 16)
            // Sized to its cards, so the panel's glass hugs them, until it runs out of room and scrolls.
            .frame(height: isSeparate ? nil : min(gridHeight + 16, maxGridHeight))
            .frame(maxHeight: isSeparate ? .infinity : nil)
        }
        // As much room beneath the last card as above the first, so the grid sits evenly in its glass.
        .padding(.vertical, 14)
        .fontDesign(.rounded)
        .task {
            // Risen on the next frame, so each card visibly comes up into its place.
            try? await Task.sleep(for: .milliseconds(16))
            hasRisen = true
        }
        // Closed during the beat, as by its Close button, the tapped layer is let go.
        .onDisappear {
            pendingChoice?.cancel()
            choosing = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Layers")
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Layers")
                .typeStyle(.eyebrow)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Button("Close", systemImage: "xmark", action: onClose)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.fill.tertiary, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .buttonStyle(PillButtonStyle())
                .accessibilityLabel("Close layers")
        }
        .padding(.trailing, -8)
    }

    private func layerCard(_ layer: MapLayer) -> some View {
        let isCurrent = layer == current
        return PlaceChoiceCard(
            name: layer.name, symbolName: layer.symbolName, tint: tint(of: layer),
            isSelected: (choosing ?? current) == layer,
            spokenDetail: layer == .timeZones ? "Opens World Time" : layer == .atlas ? "A card for each place" : nil,
            pressedScale: PillButtonStyle.cardScale
        ) {
            choose(layer)
        }
        .accessibilityHint(isCurrent ? "" : "Shows it on the map.")
    }

    /// Lights the tapped layer's card, its symbol bouncing, and hands the layer on a beat later,
    /// so the choice is seen to land before the panel changes; at once with Reduce Motion. Taps
    /// during the beat are let go.
    private func choose(_ layer: MapLayer) {
        guard choosing == nil else { return }
        guard !reduceMotion else {
            onChoose(layer)
            return
        }
        choosing = layer
        pendingChoice = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.18))
            guard !Task.isCancelled else { return }
            onChoose(layer)
            choosing = nil
        }
    }

    /// The projection the World is drawn in, as one card that opens a menu of them all, rather than
    /// a card for each of the many there are. Choosing one reshapes the map behind the chooser,
    /// which stays open so another can be tried.
    private var projectionMenu: some View {
        Menu {
            Picker("Projection", selection: $projection) {
                ForEach(MapProjection.allCases) { option in
                    Text(option.name).tag(option)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.tint)
                    .frame(width: 30, height: 22)
                    .accessibilityHidden(true)
                ScrollingText {
                    Text(projection.name)
                        .font(.callout.weight(.light))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .accessibilityLabel("Projection")
        .accessibilityValue(projection.name)
    }

    /// Whether places carry their names on the map, switched in place like the overlays.
    private var labelsCard: some View {
        PlaceChoiceCard(
            name: "Place names", symbolName: "character.textbox", tint: .accentColor, isSelected: showsLabels,
            spokenDetail: showsLabels ? "On" : "Off", pressedScale: PillButtonStyle.cardScale
        ) {
            // With Reduce Motion, a short fade rather than a cut; the map fades the names in or out
            // where they are, on its own clock.
            withAnimation(reduceMotion ? MapMotion.fade : .smooth) { showsLabels.toggle() }
        }
        .accessibilityAddTraits(.isToggle)
    }

    private func overlayCard(_ overlay: Overlay) -> some View {
        PlaceChoiceCard(
            name: overlay.title, symbolName: overlay.symbolName, tint: overlay.tint, isSelected: overlay.isOn.wrappedValue,
            spokenDetail: overlay.isOn.wrappedValue ? "On" : "Off", pressedScale: PillButtonStyle.cardScale
        ) {
            // With Reduce Motion, a short fade rather than a cut; the map fades the overlay in or
            // out where it is, rather than drawing it across the World.
            withAnimation(reduceMotion ? MapMotion.fade : .smooth) { overlay.isOn.wrappedValue.toggle() }
        }
        .accessibilityAddTraits(.isToggle)
    }

    /// A layer's own colour; the person's travels wear the colour of their highest level.
    private func tint(of layer: MapLayer) -> Color {
        layer.tint ?? ladder.levels.last?.color ?? .accentColor
    }

    /// What can be drawn over the map, whichever layer it shows.
    private var overlays: [Overlay] {
        [
            Overlay(
                title: "Equator & tropics", symbolName: "circle.and.line.horizontal",
                tint: Color(light: (0.75, 0.25, 0.30), dark: (1.0, 0.5, 0.52)), isOn: $showsLatitudes),
            // The same violet as the antipodes' fact in a country's callout.
            Overlay(
                title: "Antipodes", symbolName: Antipodes.symbolName,
                tint: Color(light: (0.36, 0.30, 0.80), dark: (0.62, 0.58, 1.0)), isOn: $showsAntipodes),
        ]
    }

    /// How many overlays are on, beside their heading; nothing when none are.
    private var overlaysDetail: String? {
        let count = [showsLatitudes, showsAntipodes].filter { $0 }.count
        return count == 0 ? nil : "\(count) on"
    }

    /// One of the overlays: its card's name and symbol, and the setting it switches.
    private struct Overlay {
        var title: String
        var symbolName: String
        var tint: Color
        var isOn: Binding<Bool>
    }
}

/// A card rising into its place as the chooser opens, each a moment after the one before, so they
/// come up across the grid in a wave. With Reduce Motion they're simply there.
private struct CardRise: ViewModifier {
    var index: Int
    var hasRisen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isDown = !hasRisen && !reduceMotion
        content
            .opacity(isDown ? 0 : 1)
            .scaleEffect(isDown ? 0.9 : 1, anchor: .bottom)
            .offset(y: isDown ? 14 : 0)
            .animation(.bouncy(duration: 0.45, extraBounce: 0.1).delay(Double(index) * 0.03), value: hasRisen)
    }
}
