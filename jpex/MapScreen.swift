import SwiftUI

/// A collection's map, opened from the map card at the top of its list. The map grows out of the
/// card and settles full screen, and shrinks back into it when closed, pulled down or pinched in.
/// Pinch, drag and double-tap to explore; tap a place for its callout, and from a country with a
/// map of its own, fly into it. On iPhone Duo the panel takes its own side of the fold.
struct MapScreen: View {
    var saveModel: SaveModel
    /// The card's frame in global coordinates, so the map can grow out of it and shrink back.
    /// Nil when the card is out of view; the map then fades in and out instead.
    var sourceFrame: CGRect?
    var onStatusChange: (VisitLevel, AdministrativeDivision, Country) -> Void
    /// Shows a collection's list in place of the map.
    var onOpenCollection: (String) -> Void
    /// Called once the map stands in for its card, so the card can step aside.
    var onPresent: () -> Void
    /// Called once the map is back in its card.
    var onClose: () -> Void
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("localLanguage") private var localLanguage = false
    @AppStorage("mapShowsNames") private var showsNames = false
    @AppStorage("mapShowsLabels") private var showsLabels = true
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var savedCenter = MapCenter.standard
    @AppStorage(DayNight.storageKey) private var showsDayNight = false
    @State private var navigator: MapNavigator
    @State private var isExpanded = false
    @State private var isClosing = false
    @State private var isLeaving = false
    @State private var highlight: VisitLevel?
    @State private var panelFrame: CGRect = .zero
    /// The panel's height while closed. The map only keeps clear of this much, so opening the
    /// names over it doesn't push the map around; the map can be moved out from under them anyway.
    @State private var closedPanelHeight: CGFloat = 0
    @State private var stageFrame: CGRect = .zero
    @State private var regionOwners: [String: String] = [:]

    init(
        collection: Country, map: TravelMap, saveModel: SaveModel, sourceFrame: CGRect?,
        onStatusChange: @escaping (VisitLevel, AdministrativeDivision, Country) -> Void,
        onOpenCollection: @escaping (String) -> Void,
        onPresent: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.saveModel = saveModel
        self.sourceFrame = sourceFrame
        self.onStatusChange = onStatusChange
        self.onOpenCollection = onOpenCollection
        self.onPresent = onPresent
        self.onClose = onClose
        _navigator = State(initialValue: MapNavigator(collection: collection, map: map))
    }

    var body: some View {
        let collection = navigator.current.collection
        let snapshot = saveModel.snapshot()
        let content = MapContent(stop: navigator.current, snapshot: snapshot, rules: counting.rules, regionOwners: regionOwners)
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    MapBackdrop(navigator: navigator, isExpanded: isExpanded)
                    arrangement(content: content, snapshot: snapshot, size: proxy.size, fold: FoldRegions(in: proxy))
                }
            }
            .containerBackground(.clear, for: .navigation)
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarVisibility(isExpanded ? .visible : .hidden, for: .navigationBar)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        }
        // A place rising a level sends its ripple of light across the whole screen, not just the map.
        .environment(\.spreadsRipplesAcrossScreen, true)
        .environment(\.showsDayNight, showsDayNight)
        .opacity(isLeaving ? 0 : 1)
        // Grown on the next frame, once the map has been drawn over the card, so it visibly grows from it.
        .task {
            try? await Task.sleep(for: .milliseconds(16))
            expand()
        }
        // Left alone, the globe drifts slowly east while the map is open.
        .task(id: isExpanded) {
            guard isExpanded else { return }
            await navigator.driftWhileIdle(reduceMotion: reduceMotion)
        }
        .onChange(of: counting.rules, initial: true) {
            regionOwners = CountryCatalog.mapRegionOwners(applying: counting.rules)
        }
        // Turning the World by hand settles on a centre, which every World map then uses.
        .onChange(of: navigator.center) { _, center in savedCenter = center }
        .sensoryFeedback(.alignment, trigger: navigator.center)
        .onChange(of: projection) { old, new in
            navigator.reproject(from: old, to: new, reduceMotion: reduceMotion)
        }
        .task(id: navigator.selection?.place.id) {
            // While a country's callout is open, get its subdivisions ready so flying in starts at once.
            guard navigator.current.collection.id == CountryCatalog.world.id,
                  let place = navigator.selection?.place, let collection = subcollection(of: place)
            else { return }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            if let subdivisions = Geography.subdivisions(of: collection.id) {
                _ = navigator.globeLongitude.map { subdivisions.map(projection, centerLongitude: $0) }
                    ?? subdivisions.map(projection, center: navigator.center)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: navigator.stops.count)
        .accessibilityAction(.escape) {
            if navigator.selection != nil {
                navigator.selection = nil
            } else if navigator.previous != nil {
                navigator.flyBack(reduceMotion: reduceMotion)
            } else {
                close()
            }
        }
    }

    /// The map with its panel floating over its foot, or, while iPhone Duo is partly folded, the
    /// map on the far side of the fold and the panel, opened up, on the near side.
    private func arrangement(content: MapContent, snapshot: TravelSnapshot, size: CGSize, fold: FoldRegions?) -> some View {
        let isFolded = fold != nil
        let bounds = CGRect(origin: .zero, size: size)
        let stageRect = fold?.far ?? bounds
        let panelRect = fold?.near ?? bounds
        let collection = navigator.current.collection
        let stage = MapStage(
            navigator: navigator, statuses: content.statuses, places: content.places,
            detailStatuses: content.detailStatuses, detailPlaces: content.detailPlaces,
            minimumStatus: counting.rules.minimumLevel(in: ladder), highlight: highlight,
            labels: showsLabels ? labels(for: content) : [:],
            isExpanded: isExpanded, revealsOnAppear: sourceFrame == nil, sourceFrame: sourceFrame,
            panelFrame: isFolded || panelFrame.isEmpty ? .zero : CGRect(
                x: panelFrame.minX, y: panelFrame.maxY - (closedPanelHeight > 0 ? closedPanelHeight : 72),
                width: panelFrame.width, height: closedPanelHeight > 0 ? closedPanelHeight : 72),
            onFrameChange: { stageFrame = $0 }, onClose: close,
            onLongPress: { flyIn(at: $0, places: content.places) }
        ) { selection, placement in
            MapCallout(
                division: selection.place,
                groupName: collection.groups.first { $0.id == selection.place.groupID }?
                    .displayName(localLanguage: localLanguage),
                status: snapshot.status(for: selection.place),
                collection: subcollection(of: selection.place).map {
                    CollectionSummary(collection: $0, snapshot: snapshot, rules: counting.rules)
                },
                localLanguage: localLanguage,
                pointerX: placement.pointerX, pointsDown: placement.pointsDown, hasPointer: placement.hasPointer,
                onStatusChange: { onStatusChange($0, selection.place, collection) },
                onOpenCollection: { open(selection) }
            )
        }
        let panel = MapPanel(
            collection: collection, statuses: content.listedStatuses, counted: content.counted, tally: content.tally,
            highlight: $highlight, showsNames: $showsNames, isSeparate: isFolded,
            maxNamesHeight: max(140, stageFrame.height * 0.32), localLanguage: localLanguage
        ) { place in
            navigator.focus(on: place, animation: reduceMotion ? nil : .smooth(duration: 0.7))
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            panelFrame = frame
            if !showsNames { closedPanelHeight = frame.height }
        }
        .opacity(isExpanded ? 1 : 0)
        .offset(y: isExpanded || isFolded ? 0 : 80)
        return ZStack(alignment: .topLeading) {
            stage
                .frame(width: stageRect.width, height: stageRect.height)
                .position(x: stageRect.midX, y: stageRect.midY)
            panel
                .frame(width: panelRect.width, height: panelRect.height, alignment: .bottom)
                .position(x: panelRect.midX, y: panelRect.midY)
        }
        .animation(.smooth(duration: 0.5), value: fold)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if let previous = navigator.previous {
                Button(previous.collection.name, systemImage: "chevron.backward") {
                    navigator.flyBack(reduceMotion: reduceMotion)
                }
            } else {
                Button("Close", systemImage: "xmark", action: close)
            }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Toggle("Place names", systemImage: "character.textbox", isOn: $showsLabels.animation(.smooth))
                .toggleStyle(.button)
            ShowAllButton(navigator: navigator)
            if navigator.current.collection.id == CountryCatalog.world.id, Geography.world != nil {
                Menu("Projection", systemImage: "globe") {
                    Picker("Projection", selection: $projection) {
                        ForEach(MapProjection.allCases) { projection in
                            Text(projection.name).tag(projection)
                        }
                    }
                }
            }
            if navigator.previous != nil {
                Button("List", systemImage: "list.bullet") { leave(toList: navigator.current.collection.id) }
            }
        }
    }

    /// Each place's name for the map, in the language the list shows first. Places that only take
    /// another's colour, such as territories that don't count as countries, keep their own outline unnamed.
    private func labels(for content: MapContent) -> [String: MapLabel] {
        var labels: [String: MapLabel] = [:]
        for (places, statuses) in [(content.places, content.statuses), (content.detailPlaces, content.detailStatuses)] {
            for (regionID, place) in places where place.id == regionID {
                let name = place.displayName(localLanguage: localLanguage)
                labels[regionID] = MapLabel(
                    text: name, language: place.language(of: name), rank: ladder.rank(of: statuses[regionID] ?? .never))
            }
        }
        return labels
    }

    // MARK: Actions

    /// The collection listing a place's own subdivisions, shaped by the counting rules.
    private func subcollection(of place: AdministrativeDivision) -> Country? {
        guard let id = CountryCatalog.collection(for: place)?.id else { return nil }
        return CountryCatalog.countries(applying: counting.rules).first { $0.id == id }
    }

    /// Flies into a place's subdivisions on the same map, or into a map of its own, or shows its
    /// list when it has no map.
    /// Touch and hold a country with subdivisions of its own to fly straight into it.
    private func flyIn(at location: CGPoint, places: [String: AdministrativeDivision]) {
        guard navigator.current.detail == nil, !navigator.isFlying,
              let region = navigator.current.map.place(at: location, geometry: navigator.geometry, among: Set(places.keys)),
              let place = places[region.id], subcollection(of: place) != nil
        else { return }
        open(MapSelection(place: place, regionID: region.id))
    }

    private func open(_ selection: MapSelection) {
        guard let collection = subcollection(of: selection.place) else { return }
        if navigator.current.collection.id == CountryCatalog.world.id,
           let subdivisions = Geography.subdivisions(of: collection.id) {
            navigator.fly(
                into: collection,
                // A hand-turned globe cuts the subdivisions around the same longitude as the World.
                subdivisions: navigator.globeLongitude.map { subdivisions.map(projection, centerLongitude: $0) }
                    ?? subdivisions.map(projection, center: navigator.center),
                local: TravelMap.named(collection.id), from: selection.regionID, reduceMotion: reduceMotion)
        } else if let map = TravelMap.named(collection.id) {
            navigator.fly(into: collection, map: map, from: selection.regionID, reduceMotion: reduceMotion)
        } else {
            leave(toList: collection.id)
        }
    }

    private func expand() {
        onPresent()
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .smooth(duration: 0.55, extraBounce: 0.06)) {
            isExpanded = true
        }
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        // A globe that drifted turns back to its centre as it shrinks into the card, which shows it.
        navigator.turnHome(reduceMotion: reduceMotion)
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .smooth(duration: 0.5)) {
            isExpanded = false
            navigator.returnToStart()
        } completion: {
            onClose()
        }
    }

    private func leave(toList id: String) {
        withAnimation(.easeOut(duration: 0.2)) {
            isLeaving = true
        } completion: {
            onOpenCollection(id)
        }
    }
}

/// What the current map shows: each region's level, and the place each region stands for.
private struct MapContent {
    /// The map's own places: the World's countries, or a country's subdivisions on its own map.
    var statuses: [String: VisitLevel] = [:]
    var places: [String: AdministrativeDivision] = [:]
    /// A country's subdivisions drawn over the World, once the camera has flown into it.
    var detailStatuses: [String: VisitLevel] = [:]
    var detailPlaces: [String: AdministrativeDivision] = [:]
    var counted: Int
    var tally: [String: Int]

    init(stop: MapStop, snapshot: TravelSnapshot, rules: CountingRules, regionOwners: [String: String]) {
        let base = stop.base ?? stop.collection
        // On the World, places that don't count as countries take the colour of their country.
        (statuses, places) = Self.regions(
            of: base, snapshot: snapshot, regionOwners: base.id == CountryCatalog.world.id ? regionOwners : [:])
        if stop.detail != nil {
            (detailStatuses, detailPlaces) = Self.regions(of: stop.collection, snapshot: snapshot, regionOwners: [:])
        }
        counted = snapshot.count(in: stop.collection.divisions, counting: rules)
        tally = snapshot.tally(of: stop.collection.divisions)
    }

    /// The levels of the places the panel lists: the subdivisions, once flown into a country.
    var listedStatuses: [String: VisitLevel] {
        detailPlaces.isEmpty ? statuses : detailStatuses
    }

    private static func regions(
        of collection: Country, snapshot: TravelSnapshot, regionOwners: [String: String]
    ) -> ([String: VisitLevel], [String: AdministrativeDivision]) {
        var statuses: [String: VisitLevel] = [:]
        var places: [String: AdministrativeDivision] = [:]
        for place in collection.divisions {
            statuses[place.id] = snapshot.status(for: place)
            places[place.id] = place
        }
        for (regionID, ownerID) in regionOwners where places[regionID] == nil {
            guard let owner = places[ownerID] else { continue }
            statuses[regionID] = statuses[ownerID]
            places[regionID] = owner
        }
        // A place left out of the count that belongs to no country, such as Western Sahara or
        // Antarctica, can still be tapped and given a level of its own.
        if collection.id == CountryCatalog.world.id {
            for place in CountryCatalog.world.divisions where places[place.id] == nil {
                statuses[place.id] = snapshot.status(for: place)
                places[place.id] = place
            }
        }
        return (statuses, places)
    }
}

/// The map itself: its layers crossing over as the camera flies between maps, the gestures that
/// move the camera, and the callout for the selected place. Only this view follows the camera.
private struct MapStage<Callout: View>: View {
    var navigator: MapNavigator
    var statuses: [String: VisitLevel]
    var places: [String: AdministrativeDivision]
    var detailStatuses: [String: VisitLevel]
    var detailPlaces: [String: AdministrativeDivision]
    var minimumStatus: VisitLevel
    var highlight: VisitLevel?
    /// Place names to set on the map, by region.
    var labels: [String: MapLabel]
    var isExpanded: Bool
    var revealsOnAppear: Bool
    var sourceFrame: CGRect?
    /// The panel's frame when it floats over the map, so the map keeps clear of it.
    var panelFrame: CGRect
    var onFrameChange: (CGRect) -> Void
    var onClose: () -> Void
    /// Touch and hold on the map, at a point in the map's own space.
    var onLongPress: (CGPoint) -> Void
    @ViewBuilder var callout: (MapSelection, CalloutPlacement) -> Callout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gesture: StageGesture?
    /// How far a pinch has taken the map below the whole view, towards letting it go: 1 and over
    /// lets go when the fingers lift.
    @State private var pinchOut: Double?
    @State private var calloutHeight: CGFloat = 240
    @State private var selectionCount = 0
    @State private var longPressHandled = false
    @State private var longPresses = 0

    /// Fires as soon as the hold is recognised, not when the finger lifts.
    private var longPress: some Gesture {
        LongPressGesture(minimumDuration: 0.45)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                // A finger landing on the map stops the globe drifting, as a hand would.
                if case .first(true) = value { navigator.touch() }
                guard case .second(true, let drag?) = value, !longPressHandled else { return }
                longPressHandled = true
                longPresses += 1
                onLongPress(drag.startLocation)
            }
            .onEnded { _ in longPressHandled = false }
    }

    var body: some View {
        GeometryReader { outer in
            let safe = outer.safeAreaInsets
            GeometryReader { proxy in
                let global = proxy.frame(in: .global)
                let bounds = CGRect(origin: .zero, size: proxy.size)
                let insets = clearInsets(safe: safe, global: global)
                let camera = navigator.camera
                let geometry = MapGeometry(
                    focus: navigator.current.focus, size: proxy.size, zoom: camera.zoom, pan: camera.pan, insets: insets)
                let fitArea = geometry.fitArea
                let growth = growth(bounds: bounds, global: global, insets: insets)
                ZStack(alignment: .topLeading) {
                    layers(camera: camera, insets: insets, anchor: UnitPoint(
                        x: fitArea.midX / max(bounds.width, 1), y: fitArea.midY / max(bounds.height, 1)))
                        .frame(width: bounds.width, height: bounds.height)
                        .contentShape(Rectangle())
                        .gesture(panAndZoom(origin: global.origin, center: CGPoint(x: fitArea.midX, y: fitArea.midY)))
                        .onTapGesture(count: 2) { location in
                            navigator.touch()
                            navigator.toggleZoom(at: location, animation: reduceMotion ? nil : .smooth(duration: 0.5))
                        }
                        .onTapGesture { location in
                            navigator.touch()
                            // A tap on a copy of a tiled World finds the place on the middle copy.
                            let location = geometry.toScreen(navigator.current.map.untiled(geometry.toMap(location)))
                            withAnimation(.bouncy(duration: 0.4, extraBounce: 0.04)) {
                                if navigator.select(
                                    at: location, places: places, detailPlaces: detailPlaces, reduceMotion: reduceMotion
                                ) { selectionCount += 1 }
                            }
                        }
                        .simultaneousGesture(longPress)
                        .allowsHitTesting(isExpanded && !navigator.isFlying && navigator.reprojection == nil)
                        .scaleEffect(pullScale)
                        .offset(navigator.pullOffset)
                        // The map is drawn once at full size and carried from where the card's map
                        // sits, so nothing is redrawn while it grows out of the card or shrinks back.
                        .scaleEffect(growth.scale, anchor: .topLeading)
                        .offset(growth.offset)
                        .position(x: bounds.midX, y: bounds.midY)
                        // The sea fills the whole map, so while it's carried from the card it stays
                        // inside the card's rounded edges, opening out to the screen's as it grows.
                        .mask {
                            let clip = isExpanded ? bounds : sourceFrame?.offsetBy(dx: -global.minX, dy: -global.minY) ?? bounds
                            RoundedRectangle(cornerRadius: isExpanded ? 0 : 18, style: .continuous)
                                .frame(width: clip.width, height: clip.height)
                                .position(x: clip.midX, y: clip.midY)
                        }
                        .opacity(isExpanded || sourceFrame != nil ? 1 : 0)
                        .accessibilityElement()
                        .accessibilityLabel("Map of \(navigator.current.collection.name)")
                        .accessibilityHint("Places with a level are listed under the map.")
                    LinearGradient(
                        colors: [Color.pageBackground.opacity(0.8), .clear],
                        startPoint: .top, endPoint: .bottom)
                        .frame(height: safe.top + 20)
                        .opacity(isExpanded ? 1 : 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    if isExpanded, let pinchOut {
                        LetGoHint(
                            title: navigator.previous?.collection.name ?? "Close",
                            systemImage: navigator.previous == nil ? "xmark" : "chevron.backward",
                            progress: pinchOut)
                            .position(x: fitArea.midX, y: fitArea.minY + 34)
                            .transition(.opacity)
                    }
                    calloutLayer(geometry: geometry)
                }
                .animation(.smooth(duration: 0.25), value: pinchOut == nil)
                .sensoryFeedback(.impact(weight: .medium), trigger: (pinchOut ?? 0) >= 1) { _, isArmed in isArmed }
                .onChange(of: MapLayout(size: proxy.size, insets: insets), initial: true) { _, layout in
                    navigator.updateLayout(layout)
                }
                .onChange(of: global, initial: true) { _, frame in onFrameChange(frame) }
            }
            .ignoresSafeArea()
        }
        .sensoryFeedback(.selection, trigger: selectionCount)
        .sensoryFeedback(.impact(weight: .medium), trigger: longPresses)
    }

    /// The current map, with the map before it while the two cross over.
    private func layers(camera: MapCamera, insets: EdgeInsets, anchor: UnitPoint) -> some View {
        ZStack {
            // A country flown into from the World shares the World's layer, so its subdivisions
            // arrive on the same map instead of crossing to another.
            ForEach([navigator.current], id: \.layerID) { stop in
                let isReshaping = navigator.reprojection != nil && stop.id == CountryCatalog.world.id
                TimelineView(.animation(paused: !isReshaping)) { timeline in
                    let shown = shownMap(for: stop, at: timeline.date)
                    TravelMapCanvas(
                        map: shown.map, statuses: statuses, minimumStatus: minimumStatus,
                        zoom: camera.zoom, pan: camera.pan, insets: insets, focus: shown.focus,
                        revealsOnAppear: revealsOnAppear && !navigator.hasFlown,
                        highlight: highlight, selection: navigator.selection?.regionID,
                        detail: stop.detail.map {
                            MapDetail(map: $0, statuses: detailStatuses, ownerRegionIDs: owners(of: stop, detail: $0))
                        },
                        detailProgress: navigator.detailProgress,
                        morph: stop.detail == nil ? nil : stop.local,
                        morphProgress: navigator.morphProgress,
                        detailIsLeaving: navigator.isDrainingSubdivisions,
                        labels: isExpanded ? labels : [:]
                    )
                }
                .transition(layerTransition(anchor: anchor))
            }
        }
        .animation(.smooth(duration: 0.45), value: insets)
    }

    /// The World's regions a country's subdivisions cover: the country itself, and places such as
    /// Hong Kong that appear in both lists. Taiwan is one of China's only while it isn't counted
    /// as a country of its own.
    private func owners(of stop: MapStop, detail: TravelMap) -> Set<String> {
        var owners = Set(detail.regions.map(\.id).filter { detailStatuses[$0] != nil })
        if let country = CountryCatalog.world.divisions.first(where: { $0.abbreviation == stop.collection.id }) {
            owners.insert(country.id)
        }
        return owners
    }

    /// A stop's map, or the World map partway between projections while it reshapes.
    private func shownMap(for stop: MapStop, at date: Date) -> (map: TravelMap, focus: CGRect) {
        guard let change = navigator.reprojection, stop.id == CountryCatalog.world.id,
              let geography = Geography.world
        else { return (stop.map, stop.focus) }
        let map = geography.map(
            from: change.from, to: change.to, progress: change.progress(at: date), center: navigator.center)
        return (map, map.focusRect(including: []))
    }

    /// Flying in, the new map comes up from below while the old one rushes past and fades;
    /// flying back, the reverse.
    private func layerTransition(anchor: UnitPoint) -> AnyTransition {
        let nearer = AnyTransition(MapLayerTransition(scale: 1.18, anchor: anchor))
        let farther = AnyTransition(MapLayerTransition(scale: 0.88, anchor: anchor))
        return navigator.direction == .inward
            ? .asymmetric(insertion: farther, removal: nearer)
            : .asymmetric(insertion: nearer, removal: farther)
    }

    @ViewBuilder
    private func calloutLayer(geometry: MapGeometry) -> some View {
        ZStack(alignment: .topLeading) {
            if isExpanded, let selection = navigator.selection {
                let anchor = selection.regionID
                    .flatMap { (navigator.current.detail ?? navigator.current.map).region(id: $0) }
                    .map { geometry.toScreen($0.center) }
                let placement = CalloutPlacement(anchor: anchor, height: calloutHeight, area: geometry.fitArea)
                callout(selection, placement)
                    .frame(width: placement.width)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { calloutHeight = $0 }
                    .position(placement.center)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.3, anchor: placement.unitAnchor).combined(with: .opacity),
                            removal: .scale(scale: 0.85, anchor: placement.unitAnchor).combined(with: .opacity)))
                    // Tapping another place glides the same card over to it; only flipping between
                    // above and below the place swaps it for a fresh one.
                    .id(placement.pointsDown)
            }
        }
    }

    /// How the full-size map is carried while it isn't open: scaled and moved so its map lies exactly
    /// over the card's, or, with no card in view, a little smaller around the middle.
    private func growth(bounds: CGRect, global: CGRect, insets: EdgeInsets) -> (scale: CGFloat, offset: CGSize) {
        guard !isExpanded else { return (1, .zero) }
        guard let sourceFrame else {
            return (0.92, CGSize(width: bounds.width * 0.04, height: bounds.height * 0.04))
        }
        let card = sourceFrame.offsetBy(dx: -global.minX, dy: -global.minY)
        let focus = navigator.current.focus
        let open = focus.applying(MapGeometry(focus: focus, size: bounds.size, zoom: 1, pan: .zero, insets: insets).transform)
        let inCard = focus.applying(MapGeometry(focus: focus, size: card.size, zoom: 1, pan: .zero).transform)
            .offsetBy(dx: card.minX, dy: card.minY)
        guard open.width > 0, inCard.width > 0 else { return (1, .zero) }
        let scale = inCard.width / open.width
        return (scale, CGSize(width: inCard.minX - open.minX * scale, height: inCard.minY - open.minY * scale))
    }

    /// Room kept clear for bars, the screen's edges, and a panel floating over the map.
    private func clearInsets(safe: EdgeInsets, global: CGRect) -> EdgeInsets {
        var bottom = safe.bottom
        if !panelFrame.isEmpty, panelFrame.intersects(global), panelFrame.minY > global.minY {
            bottom = max(bottom, global.maxY - panelFrame.minY + 8)
        }
        return EdgeInsets(top: safe.top + 8, leading: safe.leading + 8, bottom: bottom, trailing: safe.trailing + 8)
    }

    private var pullScale: CGFloat {
        1 - min(max(navigator.pullOffset.height, 0) / 1400, 0.3)
    }

    /// Pinch and drag to move the camera. At the whole-map view, pulling down puts the map away,
    /// and so does pinching it smaller than the screen.
    private func panAndZoom(origin: CGPoint, center: CGPoint) -> some Gesture {
        MagnifyGesture()
            .simultaneously(with: DragGesture(minimumDistance: 6, coordinateSpace: .global))
            .onChanged { value in
                let translation = value.second?.translation ?? .zero
                if gesture == nil {
                    let pullsDown = value.first == nil && navigator.camera.zoom <= 1.01
                        && translation.height > abs(translation.width)
                    // Seen whole, the World turns under a sideways drag instead of sliding.
                    let turns = value.first == nil && navigator.canTurnGlobe && abs(translation.width) >= abs(translation.height)
                    gesture = pullsDown ? .pull : turns ? .turn : .camera
                }
                if gesture == .pull {
                    navigator.pullOffset = translation
                } else if gesture == .turn {
                    navigator.turnGlobe(by: translation.width)
                } else {
                    let dragStart = value.second.map { CGPoint(x: $0.startLocation.x - origin.x, y: $0.startLocation.y - origin.y) }
                    // Past the map's edges or zoom limits, it gives like a rubber band.
                    navigator.moveCamera(
                        magnification: value.first?.magnification ?? 1,
                        anchor: value.first?.startLocation ?? dragStart ?? center,
                        translation: translation, resists: true)
                    // Pinched smaller than the whole map, a hint shows what letting go will do.
                    let zoom = navigator.camera.zoom
                    pinchOut = value.first != nil && zoom < 0.99
                        ? Double((1 - zoom) / (1 - MapNavigator.letGoZoom)) : nil
                }
            }
            .onEnded { value in
                defer {
                    gesture = nil
                    pinchOut = nil
                }
                if gesture == .turn {
                    navigator.endTurningGlobe(velocity: value.second?.velocity.width ?? 0, reduceMotion: reduceMotion)
                    return
                }
                if gesture == .pull {
                    let predicted = value.second?.predictedEndTranslation.height ?? 0
                    if navigator.pullOffset.height > 110 || predicted > 340 {
                        onClose()
                    } else {
                        withAnimation(.smooth(duration: 0.35)) { navigator.pullOffset = .zero }
                    }
                    return
                }
                if navigator.camera.zoom < MapNavigator.letGoZoom {
                    navigator.cancelGesture()
                    // Pinched out past the whole map, a country flown into goes back out to the map
                    // it came from, carrying on the way the fingers went; otherwise the map closes.
                    if navigator.previous != nil {
                        navigator.flyBack(reduceMotion: reduceMotion)
                    } else {
                        onClose()
                    }
                    return
                }
                // Pulled past its limits, the map springs back; otherwise it carries any fling.
                let springsBack = navigator.isPastLimits
                let fling = value.second.map {
                    CGSize(
                        width: ($0.predictedEndTranslation.width - $0.translation.width) * 0.6,
                        height: ($0.predictedEndTranslation.height - $0.translation.height) * 0.6)
                } ?? .zero
                navigator.settleCamera(
                    fling: springsBack ? .zero : fling,
                    animation: reduceMotion ? nil : springsBack ? .bouncy(duration: 0.5) : .smooth(duration: 0.6))
            }
    }
}

private enum StageGesture {
    case camera, pull, turn
}

/// What letting go of a pinch will do, shown while the map is pinched smaller than the whole view:
/// back out to the map it was flown into from, or closed. It grows as the pinch goes on, and once
/// far enough it fills in, ready.
private struct LetGoHint: View {
    var title: String
    var systemImage: String
    var progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let isArmed = progress >= 1
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isArmed ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
            .background {
                if isArmed {
                    Capsule().fill(.primary)
                } else {
                    Color.clear.glassPanel(in: Capsule())
                }
            }
            .scaleEffect(reduceMotion ? 1 : isArmed ? 1.06 : 0.85 + 0.15 * min(progress, 1))
            .opacity(min(progress * 1.6, 1))
            .animation(.bouncy(duration: 0.35), value: isArmed)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Where the callout sits: above the place when there is room, otherwise below it, kept inside
/// the clear part of the map with its point aimed at the place.
struct CalloutPlacement {
    var center: CGPoint
    var width: CGFloat
    var pointerX: CGFloat
    var pointsDown: Bool
    var hasPointer: Bool
    var unitAnchor: UnitPoint

    init(anchor: CGPoint?, height: CGFloat, area: CGRect) {
        width = min(340, max(area.width - 24, 200))
        guard let anchor, area.insetBy(dx: -30, dy: -30).contains(anchor) else {
            // With the place out of view, the card rests at the top of the map.
            center = CGPoint(x: area.midX, y: area.minY + 12 + height / 2)
            pointerX = width / 2
            pointsDown = true
            hasPointer = false
            unitAnchor = .top
            return
        }
        let fitsAbove = anchor.y - 2 - height >= area.minY
        let fitsBelow = anchor.y + 2 + height <= area.maxY
        pointsDown = fitsAbove || !fitsBelow
        hasPointer = fitsAbove || fitsBelow
        let x = min(max(anchor.x, area.minX + 4 + width / 2), area.maxX - 4 - width / 2)
        let y = if fitsAbove {
            anchor.y - 2 - height / 2
        } else if fitsBelow {
            anchor.y + 2 + height / 2
        } else {
            min(max(anchor.y, area.minY + height / 2), area.maxY - height / 2)
        }
        center = CGPoint(x: x, y: y)
        pointerX = anchor.x - (x - width / 2)
        unitAnchor = UnitPoint(x: pointerX / width, y: pointsDown ? 1 : 0)
    }
}

/// A map layer coming or going as the camera flies between maps.
private struct MapLayerTransition: Transition {
    var scale: CGFloat
    var anchor: UnitPoint

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : scale, anchor: anchor)
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity ? 0 : 8)
    }
}

/// The screen behind the map, fading in as the map grows and out as it is pulled away.
private struct MapBackdrop: View {
    var navigator: MapNavigator
    var isExpanded: Bool

    var body: some View {
        let pull = min(max(navigator.pullOffset.height, 0) / 500, 0.8)
        Color.pageBackground
            .opacity(isExpanded ? 1 - pull : 0)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// Pulls back to the whole map. Only this button follows the camera, so the toolbar doesn't redraw as it moves.
private struct ShowAllButton: View {
    var navigator: MapNavigator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button("Show all", systemImage: "arrow.down.right.and.arrow.up.left") {
            navigator.showAll(animation: reduceMotion ? nil : .smooth(duration: 0.5))
        }
        .disabled(navigator.camera.zoom <= 1.01)
    }
}
