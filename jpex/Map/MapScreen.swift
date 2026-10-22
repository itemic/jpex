import SwiftUI

/// A collection's map, opened from the map card at the top of its list. The map grows out of the
/// card and settles full screen, and shrinks back into it when closed, pulled down or pinched in.
/// Pinch, drag and double-tap to explore; tap a place for its callout, and from a country with a
/// map of its own, fly into it. On iPhone Duo the panel takes its own side of the fold.
///
/// The map is also the atlas. It always opens on the person's travels; its Layers button turns the
/// panel into a chooser of what the map shows: on any map, the travels or the Atlas's cards; and
/// on the World, the time zones, the World settling whole and curling up out of the map into World
/// Time and unrolling back into it after, or a fact about every country, such as the side of the
/// road, which the countries sweep across into while the panel becomes that fact's key. Tapping an
/// entry in a key brings its places forward and lists them, and picking one flies to it and opens
/// its callout, as tapping it on the map does, the fact leading its facts. Tapping the key's name
/// opens the chooser again, and the key can be put away, leaving the layer's colours on the map.
/// The panel's glass reshapes from one to the next. A key rests as a slim strip over the foot of
/// the map, so the World keeps all its width; on a wide screen the chooser floats in the top corner.
///
/// The Atlas is a row of cards to swipe through over the foot of the map, or beside it on a wide
/// screen, or on the near side of iPhone Duo's fold: a card for each place, its flag, capitals,
/// codes and facts. The map outlines the place on show and flies to it, and tapping a place on the
/// map brings the row round to it rather than opening a callout. Outside the Atlas, a place's
/// callout offers its card there. A place with places of its own to learn, such as Japan, offers a
/// way into them: the map flies into Japan and the Atlas carries on there, and flying back comes
/// back to Japan's card.
///
/// Its search finds any place by name, capital or code, on any map: in the Atlas the row comes
/// round to it, and otherwise the map flies there and opens its callout. Close always leaves the
/// map, and Escape steps back one thing at a time.
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
    /// Where the map opens straight into Learn, as from the quiz lobby's Learn tile; nil opens it
    /// on the person's travels.
    var learnStart: LearnDeck.Request?
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether the globe may drift by itself: not while the app isn't in front, in Low Power Mode
    /// or with Reduce Motion.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("localLanguage") private var localLanguage = false
    @AppStorage("mapShowsLabels") private var showsLabels = true
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var savedCenter = MapCenter.standard
    @AppStorage(WorldLayers.antipodesKey) private var showsAntipodes = false
    @AppStorage(WorldLayers.latitudesKey) private var showsLatitudes = false
    @State private var navigator: MapNavigator
    /// What the World's countries are coloured by. Every visit starts on the person's travels.
    @State private var colouring = MapColouring.travels
    /// A key of the fact shown brought forward, such as plug type G, by ID.
    @State private var keyHighlight: String?
    /// Whether the panel shows the layer chooser.
    @State private var isChoosingLayer = false
    /// Whether the key of the layer shown is put away, the layer's colours still on the map, and
    /// only a slim tab of its name left to bring the key back.
    @State private var isKeyHidden = false
    /// Whether World Time is open over the map, for the time zones.
    @State private var isShowingTimeZones = false
    /// Whether the map has stepped back for World Time: its panel and bars put away while the map
    /// settles and World Time curls up out of it, and until World Time has unrolled back into it.
    @State private var isOffToTimeZones = false
    /// Where the World lay on screen as World Time opened out of it, for World Time to curl up out
    /// of and unroll back into; nil when it grows and fades instead.
    @State private var timeZonesSource: TimeZonesSource?
    /// The layer picked from World Time's own chooser, shown once it has closed back into the map.
    @State private var layerFromTimeZones: MapLayer?
    /// The fact the map showed as World Time opened, such as plugs, which it comes back to when
    /// World Time closes with no other layer picked.
    @State private var layerBeforeTimeZones = MapColouring.travels
    /// The time zones were chosen while the map was flying or changing projection; World Time
    /// opens once it has settled.
    @State private var pendingTimeZones = false
    /// The fact the map showed as the Atlas opened, such as plugs, which the Atlas sets aside for
    /// the person's travels and which comes back when the Atlas is put away; nil when it opened
    /// over the travels, or once another fact has been chosen instead.
    @State private var layerBeforeAtlas: MapColouring?
    /// Whether the places of the key's entry brought forward are listed. A place picked from the
    /// list folds it away, the entry still lit, so the callout isn't hidden under it.
    @State private var isListing = false
    /// The size of the panel's glass, which follows whichever panel it holds.
    @State private var panelGlass: CGSize = .zero
    @State private var isExpanded = false
    /// Set once the map has finished growing out of its card, so the Atlas's first flight waits
    /// for it: the map grows, then flies.
    @State private var hasGrown = false
    /// The IDs of the places the Atlas has a card for on the map shown, as its row counts them
    /// under the person's rules, so a callout only offers the Atlas where there's a card to open.
    @State private var atlasPlaceIDs: Set<String> = []
    /// Whether the compass is up: from the moment the map turns away from north until it has come
    /// all the way back round, so the needle is seen swinging home before it goes.
    @State private var isCompassShown = false
    /// Counts each arrival back at north, for a click as the compass goes.
    @State private var northArrivals = 0
    /// Counts the chooser opening and closing, and the key being put away and brought back, for a tick.
    @State private var chooserTicks = 0
    /// The place picked from a key's list, by ID, until the map lets it go, so its selecting,
    /// which comes as the camera arrives, doesn't tick a second time: its card has ticked already.
    @State private var listPickID: String?
    @State private var isClosing = false
    @State private var isLeaving = false
    @State private var highlight: VisitLevel?
    @State private var panelFrame: CGRect = .zero
    /// The panel's height while closed. The map only keeps clear of this much, so opening the
    /// names over it doesn't push the map around; the map can be moved out from under them anyway.
    @State private var closedPanelHeight: CGFloat = 0
    @State private var stageFrame: CGRect = .zero
    @State private var regionOwners: [String: String] = [:]
    /// Learn's places and the one on show, while learning; nil otherwise.
    @State private var learnDeck: LearnDeck?
    /// The place each map was left at for another flown into from Learn, such as Japan for its
    /// prefectures, by collection ID, so Learn carries on from there coming back.
    @State private var learnReturns: [String: String] = [:]
    /// Learn's row of cards, where it is on screen, for the map to keep clear of.
    @State private var learnFrame: CGRect = .zero
    /// Whether the map has pulled out to show everything while Learn's scrubber is dragged.
    @State private var isScrubbingOut = false
    /// Counts each move through Learn's places, for a tick.
    @State private var learnTicks = 0
    @State private var isSearchingLearn = false
    /// The place picked from Learn's search, gone to once the search has closed, so the way there is seen.
    @State private var learnPick: LearnSearch.Result?
    /// Learn's search grows out of its button and shrinks back into it.
    @Namespace private var learnSearchZoom
    /// A key's title folds down into its tab as the key is put away, and lifts back up out of it.
    @Namespace private var keyTitle
    /// The places to search outside Learn, made as the search opens, so finding a place works the
    /// same everywhere: picked, the map flies to it and opens its callout.
    @State private var searchDeck: LearnDeck?
    /// The place picked from the search outside Learn, flown to once the search has closed.
    @State private var mapPick: AdministrativeDivision?
    /// Counts each nudge of the outline round the Atlas's place on show, which dims and traces
    /// itself round again, to say where the place is.
    @State private var learnPulses = 0
    /// Counts each tap on the map while learning that finds nothing to learn, for a soft knock.
    @State private var learnMisses = 0
    /// Where the map was opened to show, as from a place's own page: its callout, once the map has grown.
    var selectingPlaceID: String?
    /// The layer the map opens on, applied once it has grown, such as the time zones.
    var startingLayer: MapLayer?

    init(
        collection: Country, map: TravelMap, saveModel: SaveModel, sourceFrame: CGRect?,
        onStatusChange: @escaping (VisitLevel, AdministrativeDivision, Country) -> Void,
        onOpenCollection: @escaping (String) -> Void,
        onPresent: @escaping () -> Void,
        onClose: @escaping () -> Void,
        learning learnStart: LearnDeck.Request? = nil,
        selecting placeID: String? = nil,
        startingLayer: MapLayer? = nil
    ) {
        self.selectingPlaceID = placeID
        self.startingLayer = startingLayer
        self.saveModel = saveModel
        self.sourceFrame = sourceFrame
        self.onStatusChange = onStatusChange
        self.onOpenCollection = onOpenCollection
        self.onPresent = onPresent
        self.onClose = onClose
        self.learnStart = learnStart
        let navigator = MapNavigator(collection: collection, map: map)
        // The full map's World running on round fills the screen from top to foot, its copies
        // carrying on either side.
        navigator.fillsWithCopies = true
        _navigator = State(initialValue: navigator)
    }

    var body: some View {
        let snapshot = saveModel.snapshot()
        let content = MapContent(stop: navigator.current, snapshot: snapshot, rules: counting.rules, regionOwners: regionOwners)
        screen(content: content, snapshot: snapshot)
        // Grown on the next frame, once the map has been drawn over the card, so it visibly grows from it.
        // Opened into the Atlas, the row of cards is there from the start, and once the map has
        // grown, it flies to the first place, in one beat after the other (see `expand`). Opened
        // on a place, it flies there and opens its callout; opened on a layer, it shows it, the
        // time zones curling up out of the map. The Atlas can be opened on any map; the other
        // layers are the World's.
        .task {
            if let learnStart, learnDeck == nil {
                learnDeck = LearnDeck(
                    collection: navigator.current.collection, rules: counting.rules, startingAt: learnStart.placeID)
            }
            try? await Task.sleep(for: .milliseconds(16))
            expand()
            guard learnDeck == nil, selectingPlaceID != nil || startingLayer != nil else { return }
            try? await Task.sleep(for: .milliseconds(600))
            // Closed again before it got there, as by a quick pull down, it goes nowhere.
            guard !isClosing, !Task.isCancelled else { return }
            if let selectingPlaceID {
                select(placeID: selectingPlaceID, places: content.places)
            }
            if let startingLayer, showsWorld || startingLayer == .atlas { choose(startingLayer) }
        }
        .task(id: learnDeck?.landing?.id) {
            // Once its card has lit up and faded, so it doesn't light again when scrolled back to.
            guard let deck = learnDeck, deck.landing != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled { deck.clearLanding() }
        }
        // Flown into another map while learning, Learn carries on with its places, and back on a
        // map left for another, at the place it was left at.
        .onChange(of: navigator.current.collection.id) { _, id in
            refreshAtlasPlaceIDs()
            guard let deck = learnDeck, deck.collection.id != id else { return }
            let start = learnReturns.removeValue(forKey: id)
            guard let next = LearnDeck(collection: navigator.current.collection, rules: counting.rules, startingAt: start)
            else {
                stopLearning()
                return
            }
            withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { learnDeck = next }
        }
        // Once there, the map flies to the place on show, and World Time, chosen on the way,
        // opens once the map has come to rest.
        .onChange(of: navigator.isFlying) { _, isFlying in
            guard !isFlying else { return }
            if learnDeck != nil { frameLearnPlace() }
            showPendingTimeZones()
        }
        .onChange(of: navigator.reprojection == nil) { _, isSettled in
            if isSettled { showPendingTimeZones() }
        }
        // The Atlas's row first measured, or resized, as when turned on its side, the place on
        // show is framed again in the room the map now has: one straight glide once the row has
        // its room. While the map is still growing out of its card, the first measurement waits
        // for it, and the map flies once it has grown.
        .onChange(of: learnFrame.size) { old, new in
            guard learnDeck != nil, hasGrown, new != .zero,
                  abs(old.width - new.width) > 1 || abs(old.height - new.height) > 1
            else { return }
            // A beat later, once the map has taken in the room the row leaves it.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(40))
                frameLearnPlace()
            }
        }
        // Left alone, the globe drifts slowly east while the map is open, but only while ambient
        // motion may play, so it never turns for no one or at the battery's expense. Not while
        // World Time is up, so the World is still where it curled up from when it unrolls.
        .task(id: isExpanded && !isOffToTimeZones && allowsAmbientMotion) {
            guard isExpanded, !isOffToTimeZones, allowsAmbientMotion else { return }
            await navigator.driftWhileIdle(reduceMotion: reduceMotion)
        }
        .onChange(of: counting.rules, initial: true) {
            regionOwners = CountryCatalog.mapRegionOwners(applying: counting.rules)
            refreshAtlasPlaceIDs()
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
        // A place picked from a list ticks again once the map has moved on from it.
        .onChange(of: navigator.selection?.place.id) { _, id in
            if id != listPickID { listPickID = nil }
            // A place tapped on the map while a key's places are listed folds the list away, so
            // its callout opens in full view rather than under the list.
            if id != nil, isListing {
                withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isListing = false }
            }
        }
        .accessibilityAction(.escape, escape)
    }

    /// The map and its bars, with what the whole screen shares: the World's layers, World Time
    /// over it, and the ticks and clicks of moving about it.
    private func screen(content: MapContent, snapshot: TravelSnapshot) -> some View {
        let collection = navigator.current.collection
        return NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    MapBackdrop(navigator: navigator, isExpanded: isExpanded)
                    arrangement(
                        content: content, snapshot: snapshot, size: proxy.size, global: proxy.frame(in: .global),
                        safe: proxy.safeAreaInsets, fold: FoldRegions(in: proxy),
                        // Atlas book: the open book's two pages, partly folded or lying flat.
                        bookSpread: AtlasBook.spread(in: proxy))
                        // Folded, unfolded or turned, once everything has glided into its new place,
                        // the Atlas's place is framed again in the room the map has now.
                        .task(id: AtlasRoom(
                            size: proxy.size, fold: FoldRegions(in: proxy),
                            book: AtlasBook.spread(in: proxy))
                        ) {
                            guard learnDeck != nil, hasGrown else { return }
                            try? await Task.sleep(for: .milliseconds(650))
                            guard !Task.isCancelled else { return }
                            frameLearnPlace()
                        }
                    // Escape on a keyboard steps back one thing at a time, as VoiceOver's escape
                    // does; the Close button itself always leaves the map.
                    Button("Back", action: escape)
                        .keyboardShortcut(.cancelAction)
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                    // ⌘[ flies back out a map, the back button being a menu, which takes no shortcut.
                    Button("Back a map") { navigator.flyBack(reduceMotion: reduceMotion) }
                        .keyboardShortcut("[", modifiers: .command)
                        .disabled(navigator.previous == nil)
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                    // Zooming in and out from the keyboard, about the middle of the map, as on Maps.
                    // Titled, so a held Command key lists them among the map's shortcuts.
                    Button("Zoom in") { zoom(by: 1.8) }
                        .keyboardShortcut("=", modifiers: .command)
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                    Button("Zoom out") { zoom(by: 1 / 1.8) }
                        .keyboardShortcut("-", modifiers: .command)
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                }
            }
            .containerBackground(.clear, for: .navigation)
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarVisibility(isExpanded && !isOffToTimeZones ? .visible : .hidden, for: .navigationBar)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .sheet(isPresented: $isSearchingLearn, onDismiss: landFromSearch) {
                learnSearchSheet
            }
        }
        // A place rising a level breaks out of the map: it lifts off over the panel and callout, and
        // its ripple of light spreads across the whole screen.
        .environment(\.breaksOutOntoScreen, true)
        .environment(\.spreadsRipplesAcrossScreen, true)
        .environment(\.worldLayers, worldLayers)
        .fullScreenCover(isPresented: $isShowingTimeZones) {
            worldTime
                .presentationBackground(.clear)
        }
        // Flown into a country, the World's layers make way for its own places.
        .onChange(of: showsWorld) { _, showsWorld in
            if !showsWorld {
                isChoosingLayer = false
                // The time zones are the World's, so a wait for them ends on leaving it.
                pendingTimeZones = false
            }
        }
        .opacity(isLeaving ? 0 : 1)
        .modifier(ScreenFeedback(
            learnTicks: learnTicks, chooserTicks: chooserTicks, northArrivals: northArrivals, learnMisses: learnMisses))
        .onChange(of: isChoosingLayer) { chooserTicks += 1 }
        .onChange(of: isKeyHidden) { chooserTicks += 1 }
    }

    /// Steps back one thing at a time, for VoiceOver's escape and the Escape key: the search
    /// closes, then the chooser, then a key's entry brought forward lets go and its list folds
    /// away, then the Atlas is put away (out of a map flown into from it first), then the callout
    /// closes, then a map flown into flies back out, and last the map closes. Nothing happens
    /// while the map has stepped back for World Time.
    private func escape() {
        if isOffToTimeZones {
            return
        } else if isSearchingLearn {
            isSearchingLearn = false
        } else if isChoosingLayer {
            isChoosingLayer = false
        } else if (shownColouring != .travels && keyHighlight != nil) || highlight != nil {
            withAnimation(.atlasKey(reduceMotion: reduceMotion)) {
                keyHighlight = nil
                highlight = nil
                isListing = false
            }
        } else if learnDeck != nil {
            // Out of a map flown into from the Atlas, back to the one before; otherwise out of the Atlas.
            if navigator.previous != nil {
                navigator.flyBack(reduceMotion: reduceMotion)
            } else {
                stopLearning()
            }
        } else if navigator.selection != nil {
            withAnimation(LevelTapback.closing) { navigator.selection = nil }
        } else if navigator.previous != nil {
            navigator.flyBack(reduceMotion: reduceMotion)
        } else {
            close()
        }
    }

    /// The map with its panel floating over its foot, or, while iPhone Duo is partly folded, the
    /// map on the far side of the fold and the panel, opened up, on the near side. A layer's key
    /// rests over the foot, the World keeping above it, or on a short, wide screen, such as iPhone
    /// on its side, in a column down the trailing side, so the World keeps its height. On a wide
    /// screen the Atlas's row stands in a column down the trailing side, the map keeping to the
    /// rest, and the layer chooser floats in the column's top corner without moving the map.
    ///
    /// Opening the chooser in the Atlas leaves the Atlas just as it was: the row stays where it is,
    /// only softening away under the chooser, and the map keeps the room it had, so closing the
    /// chooser finds everything as it was left, the row still on the same card.
    private func arrangement(
        content: MapContent, snapshot: TravelSnapshot, size: CGSize, global: CGRect, safe: EdgeInsets,
        fold activeFold: FoldRegions?, bookSpread: FoldRegions? = nil
    ) -> some View {
        // Atlas book: held open like a book, partly folded or flat, the Atlas takes the right-hand
        // page as a book of places, beside the map on the left; partly folded, another layer
        // takes it as an index of its key's places. Sitting on a table, the fold runs across, and
        // there's no book.
        let spread = activeFold?.isAcross == true ? nil : bookSpread
        let isBook = learnDeck != nil && spread != nil
        let isIndexPose = learnDeck == nil && spread != nil && activeFold != nil
        let fold = isBook || isIndexPose ? spread : activeFold
        let isFolded = fold != nil
        let bounds = CGRect(origin: .zero, size: size)
        // Atlas book: the map and the page meet at the middle of the fold, with no gap between.
        let spine = isBook || isIndexPose ? fold.map(AtlasBook.spine(of:)) : nil
        // Sitting on a table, the map runs on past the fold into the top of the near side, fading
        // away there, so it slides on into the panel beneath rather than stopping at the crease.
        let tabletop = fold.flatMap { $0.isAcross ? $0 : nil }
        // In the book, the map runs on a little under the page, which fades in over it, so the
        // spread has no hard edge at the spine.
        let stageRect = spine.map { CGRect(x: 0, y: 0, width: min($0 + AtlasBook.overlap, size.width), height: size.height) }
            ?? tabletop.map { CGRect(x: 0, y: 0, width: size.width, height: min($0.near.minY + Self.tabletopReach, size.height)) }
            ?? fold?.far ?? bounds
        let panelRect = spine.map { CGRect(x: $0, y: 0, width: size.width - $0, height: size.height) }
            ?? fold?.near ?? bounds
        let collection = navigator.current.collection
        let mode = panelMode
        let side = Self.panelPlacement(for: mode, size: size, isFolded: isFolded)
        let learnSide = Self.panelPlacement(for: .learn, size: size, isFolded: isFolded)
        // The map makes way for the Atlas's row while it's open, and otherwise for the key, never
        // for the chooser, which floats over it, so opening the chooser never moves the map.
        // A key put away to its tab beside the map leaves the map the whole screen, the tab resting
        // in the corner of the foot over it.
        let isTabBeside = learnDeck == nil && showsKeyTab(isFolded: isFolded)
            && Self.panelPlacement(for: .key(shownColouring), size: size, isFolded: isFolded) == .trailing
        let mapSide: PanelSide = learnDeck != nil
            ? learnSide
            : isTabBeside ? .foot : Self.panelPlacement(for: .key(shownColouring), size: size, isFolded: isFolded)
        let columnWidth = Self.columnWidth(for: size)
        // The trailing column on the screen, glass and margin, worked out rather than measured so
        // the map makes way for it at once.
        let column = CGRect(
            x: global.maxX - columnWidth - Self.columnMargin, y: global.minY,
            width: columnWidth + Self.columnMargin, height: global.height)
        // Over the foot, the map keeps clear of a key's resting height only, or of the Atlas's row.
        // Until the one showing has been measured, the map keeps clear of where the key's strip
        // rests, or would, rather than filling the screen for a moment and then making way.
        let resting = closedPanelHeight > 0 ? closedPanelHeight : 72
        let keyFoot = panelFrame.isEmpty
            ? CGRect(
                x: global.minX, y: global.maxY - Self.footGap(safe) - resting, width: global.width, height: resting)
            : CGRect(x: panelFrame.minX, y: panelFrame.maxY - resting, width: panelFrame.width, height: resting)
        let footFrame = learnDeck != nil && !learnFrame.isEmpty ? learnFrame : keyFoot
        // On a wide screen the chooser floats in the top corner over the map, so the compass
        // steps aside, out from under it.
        let compassInset: CGFloat = isChoosingLayer && side == .trailing && mapSide != .trailing
            ? columnWidth + Self.columnMargin : 0
        let selectedParts = navigator.selection.map { selection in
            Set(regionIDs(of: selection.place)).union(selection.regionID.map { [$0] } ?? [])
        } ?? []
        let stage = MapStage(
            navigator: navigator, statuses: content.statuses, places: content.places,
            detailStatuses: content.detailStatuses, detailPlaces: content.detailPlaces,
            minimumStatus: counting.rules.minimumLevel(in: ladder), highlight: highlight,
            labels: labels(for: content), showsLabels: showsLabels,
            isExpanded: isExpanded, revealsOnAppear: sourceFrame == nil, sourceFrame: sourceFrame,
            // On a table, the map keeps its places above the fold, the part running on past it only
            // the fading edge of the page.
            panelFrame: tabletop.map {
                CGRect(x: global.minX, y: global.minY + $0.far.maxY, width: global.width, height: stageRect.height - $0.far.maxY)
            } ?? spine.map {
                // In the book, places keep to the left-hand page, the part under the page only its
                // fading edge.
                CGRect(x: global.minX + $0, y: global.minY, width: stageRect.width - $0, height: global.height)
            } ?? (isFolded || isTabBeside ? .zero : mapSide == .trailing ? column : footFrame),
            panelSide: spine != nil ? .trailing : mapSide,
            selectionParts: selectedParts,
            selectionTint: learnDeck == nil ? nil : MapGame.learnColor,
            // Each new place's outline draws itself round the place, as a pen would, whether its
            // callout has opened or the Atlas has come to it, on the map's own clock, so it never
            // cuts short the camera gliding there; scrubbed past, place after place, each is simply
            // there, rather than a string of half-drawn ones.
            tracesSelection: !isScrubbingOut,
            selectionPulses: learnPulses,
            mapLabel: mapLabel,
            hint: mapHint(for: mode, side: side, isFolded: isFolded),
            isCompassShown: $isCompassShown,
            compassInset: compassInset,
            untickedPlaceID: listPickID,
            onFrameChange: { stageFrame = $0 }, onClose: close,
            onLongPress: { flyIn(at: $0, places: content.places) },
            // Still in the Atlas while the chooser is open, so the place on show doesn't open a callout under it.
            onLearnTap: learnDeck == nil ? nil : { learnTap(at: $0, content: content) },
            spinsWithTwoFingers: learnDeck != nil,
            onShowLayers: isOffToTimeZones ? nil : { isChoosingLayer = true },
            onSearch: isOffToTimeZones ? nil : openSearch,
            onNorth: arriveNorth
        ) { selection, placement in
            MapCallout(
                division: selection.place,
                groupName: collection.groups.first { $0.id == selection.place.groupID }?
                    .displayName(localLanguage: localLanguage),
                status: snapshot.status(for: selection.place),
                // Every level its places are listed at, such as France's regions and its departments.
                collections: subcollection(of: selection.place).map(CountryCatalog.levels(of:))?.map {
                    CollectionSummary(collection: $0, snapshot: snapshot, rules: counting.rules)
                } ?? [],
                localLanguage: localLanguage,
                pointerX: placement.pointerX, pointsDown: placement.pointsDown, hasPointer: placement.hasPointer,
                maxHeight: placement.maxHeight,
                onStatusChange: { level in
                    onStatusChange(level, selection.place, collection)
                    putAwayCallout(for: selection.place.id)
                },
                onOpenCollection: { open(selection, level: $0) },
                facts: layerFacts(about: selection, places: content.places),
                // Outside the Atlas, a way into its card for the place, only where it has one.
                onOpenAtlas: learnDeck == nil && hasAtlasCard(for: selection.place) ? { choose(.atlas) } : nil
            )
        }
        let motion = MapMotion.panel(reduceMotion: reduceMotion)
        return ZStack(alignment: .topLeading) {
            stage
                // Left alone while it settles for World Time and until World Time has unrolled into it.
                .allowsHitTesting(!isOffToTimeZones)
                // On a table, the map fades into the page past the fold.
                .overlay(alignment: .bottom) {
                    if let tabletop {
                        LinearGradient(
                            colors: [Color.pageBackground.opacity(0), .pageBackground], startPoint: .top, endPoint: .bottom)
                            .frame(height: max(stageRect.height - tabletop.far.maxY, 0))
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: stageRect.width, height: stageRect.height)
                .position(x: stageRect.midX, y: stageRect.midY)
            ZStack {
                if let learnDeck, isBook {
                    // Atlas book: the right-hand page in place of the row of cards.
                    bookPages(learnDeck, spineInset: max((fold?.near.minX ?? 0) - (spine ?? 0), 0))
                        .opacity(isChoosingLayer ? 0 : 1)
                        .blur(radius: isChoosingLayer && !reduceMotion ? 8 : 0)
                        .allowsHitTesting(!isChoosingLayer)
                        .accessibilityHidden(isChoosingLayer)
                        .frame(width: panelRect.width, height: panelRect.height)
                        .transition(.opacity)
                } else if let learnDeck {
                    learnPanel(
                        learnDeck, side: learnSide, isFolded: isFolded, height: panelRect.height,
                        columnWidth: columnWidth, safe: safe)
                        // Under the chooser the row stays where it is, softening away rather than
                        // going, so it's just as it was when the chooser closes.
                        .opacity(isChoosingLayer ? 0 : 1)
                        .blur(radius: isChoosingLayer && !reduceMotion ? 8 : 0)
                        .allowsHitTesting(!isChoosingLayer)
                        .accessibilityHidden(isChoosingLayer)
                        .frame(
                            width: panelRect.width, height: panelRect.height,
                            alignment: learnSide == .foot ? .bottom : .trailing)
                        // Coming and going as one panel gives way to another on the glass.
                        .transition(PanelSwap(reduceMotion: reduceMotion, side: learnSide))
                }
                if isIndexPose, !isChoosingLayer, case .key(let shown) = panelMode {
                    // Atlas book: the layer's index on the right-hand page.
                    bookIndex(shown, content: content, spineInset: max((fold?.near.minX ?? 0) - (spine ?? 0), 0))
                        .frame(width: panelRect.width, height: panelRect.height)
                        .transition(.opacity)
                } else if learnDeck == nil || isChoosingLayer {
                    panelArea(
                        content: content, isFolded: isFolded, side: side, columnWidth: columnWidth,
                        columnHeight: panelRect.height, safe: safe)
                        // The chooser in the column's corner, or over the Atlas, leaves the map as
                        // it was, so it isn't where the map keeps clear of.
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                            if side == .foot, learnDeck == nil { panelFrame = frame }
                        }
                        // Put away for the Atlas, the glass starts afresh from the next panel's size.
                        .onDisappear { panelGlass = .zero }
                        .frame(
                            width: panelRect.width, height: panelRect.height,
                            alignment: side == .foot ? .bottom : isTabBeside && !isChoosingLayer ? .bottomTrailing : .topTrailing)
                        .transition(PanelSwap(reduceMotion: reduceMotion, side: side))
                }
            }
            .opacity(isExpanded && !isOffToTimeZones ? 1 : 0)
            .allowsHitTesting(!isOffToTimeZones)
            // Rising into place as the map grows out of its card; with Reduce Motion, fading in
            // where it rests.
            .offset(y: isExpanded || isFolded || reduceMotion ? 0 : 80)
            .frame(width: panelRect.width, height: panelRect.height)
            .position(x: panelRect.midX, y: panelRect.midY)
            // The panels change on the panel's own curve, and only they do: the map beneath keeps
            // to its own animations, so a camera setting off in the same moment, as when the Atlas
            // is chosen again and flies back to its place, glides on its own curve, or cuts with
            // Reduce Motion, rather than being carried along on the panel's.
            .animation(motion, value: learnDeck == nil)
            .animation(motion, value: isChoosingLayer)
            .animation(motion, value: side)
        }
        // Folding or unfolding iPhone Duo moves everything together.
        .animation(.smooth(duration: 0.5), value: fold)
    }

    /// Whether a panel stands beside the map rather than over its foot: on a wide screen, as on
    /// iPad or iPhone Duo unfolded and turned on its side, and on any short, wide one, such as
    /// iPhone on its side, where a panel over the foot would leave no room for the map.
    private static func isWide(_ size: CGSize) -> Bool {
        size.width > size.height && (size.width >= 600 || size.height < 500)
    }

    /// Whether a layer's key stands beside the map rather than over its foot: only on a short, wide
    /// screen, such as iPhone or iPhone Duo closed on its side, where even a slim strip over the
    /// foot would leave the World under half the width; everywhere else it's the strip.
    private static func keyStandsBeside(_ size: CGSize) -> Bool {
        size.width > size.height && size.height < 500
    }

    /// The column a panel takes beside the map: a comfortable width, but never more than about
    /// half a narrow screen, so the map keeps its share.
    private static func columnWidth(for size: CGSize) -> CGFloat {
        min(max(size.width * 0.5, 300), 420)
    }

    /// How far the map runs on past the fold into the near side, fading away, while iPhone Duo sits
    /// on a table.
    private static let tabletopReach: CGFloat = 72

    /// The room between the column and the screen's trailing edge, or iPhone Duo's bar.
    private static let columnMargin: CGFloat = 8

    /// How far a panel standing clear of the screen's foot sits above its safe area: a little over
    /// a home indicator, which already leaves room, and more over a bare edge.
    private static func footGap(_ safe: EdgeInsets) -> CGFloat {
        safe.bottom > 0 ? 10 : 16
    }

    /// Where a panel stands: the Atlas's row and the chooser in a column down the trailing side on
    /// a wide screen, and otherwise over the foot of the map. Every layer's key, the travels'
    /// included, is a slim strip resting over the foot, bottom-centred, so the World keeps all the
    /// width, except on a short, wide screen, where it takes the column so the World keeps its
    /// height. On iPhone Duo partly folded, every panel takes the near side of the fold.
    private static func panelPlacement(for mode: PanelMode, size: CGSize, isFolded: Bool) -> PanelSide {
        guard !isFolded else { return .foot }
        switch mode {
        case .learn, .layers: return isWide(size) ? .trailing : .foot
        case .key: return keyStandsBeside(size) ? .trailing : .foot
        }
    }

    /// What VoiceOver calls the map: its name, and in the Atlas or showing a fact, which.
    private var mapLabel: String {
        let name = navigator.current.collection.name
        if learnDeck != nil { return "Map of \(name), Atlas" }
        guard shownColouring != .travels else { return "Map of \(name)" }
        return "Map of \(name), showing \(shownColouring.name.lowercased())"
    }

    /// What VoiceOver says about the map: how to find a place, and where the panel it works with
    /// is, or in the Atlas, what tapping a place does.
    private func mapHint(for mode: PanelMode, side: PanelSide, isFolded: Bool) -> String {
        let search = "Use Search to find a place."
        if learnDeck != nil { return "Tap a place to bring its card round. \(search)" }
        let place = isFolded ? "across the fold" : side == .trailing ? "beside the map" : "at the foot of the map"
        switch mode {
        case .layers:
            return "\(search) The layers are open \(place)."
        case .key, .learn:
            // A key put away leaves its tab at the foot, in the corner beside the map where the
            // key stood in a column.
            return isKeyHidden && !isFolded
                ? "\(search) Show key is at the foot of the map." : "\(search) The key is \(place)."
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // Close always leaves the map; going back out of a map flown into is a named chevron, and
        // touched and held, it leaves from there too, without flying back out a map at a time.
        ToolbarItem(placement: .cancellationAction) {
            if let previous = navigator.previous {
                Menu {
                    Button("Open \(navigator.current.collection.name)’s list", systemImage: "list.bullet") {
                        leave(toList: navigator.current.collection.id)
                    }
                    Button("Close map", systemImage: "xmark", action: close)
                } label: {
                    Label(previous.collection.name, systemImage: "chevron.backward")
                } primaryAction: {
                    navigator.flyBack(reduceMotion: reduceMotion)
                }
                .accessibilityLabel("Back to \(previous.collection.name)")
            } else {
                Button("Close", systemImage: "xmark", action: close)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            ShowAllButton(navigator: navigator, onArrive: arriveNorth)
        }
        // What the map shows, to change while exploring it, on every map: the person's travels or
        // the Atlas's cards, and on the World the time zones and the facts too. The chooser opens
        // in the panel, as a card for each layer, rather than as a menu, with the map's own
        // settings, such as place names, beneath; the button takes the symbol of the layer shown,
        // so it's clear at a glance the map isn't on the travels.
        ToolbarItem(placement: .primaryAction) {
            Toggle(isOn: $isChoosingLayer) {
                Label(
                    "Layers",
                    systemImage: currentLayer == .colouring(.travels) ? "square.3.layers.3d" : currentLayer.symbolName)
                    .contentTransition(.symbolEffect(.replace))
            }
            .toggleStyle(.button)
            .keyboardShortcut("l", modifiers: .command)
            .accessibilityLabel("Layers")
            .accessibilityValue(currentLayer.name)
        }
        .overflowsLast()
        // Apart from Layers, beside Search, as a way somewhere else rather than something the map
        // shows: the list of the places on the map flown into.
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .primaryAction)
        }
        if navigator.previous != nil {
            ToolbarItem(placement: .primaryAction) {
                Button("Open list", systemImage: "list.bullet.rectangle") { leave(toList: navigator.current.collection.id) }
                    .accessibilityLabel("Open \(navigator.current.collection.name)’s list")
            }
            .overflowsLast()
        }
        // A way to find any place by its name, capital or codes, on any map: in Learn it brings
        // the row round to it; otherwise the map flies there and opens its callout.
        if #available(iOS 26.0, *) {
            searchItem
                .matchedTransitionSource(id: Self.learnSearchZoomID, in: learnSearchZoom)
                .overflowsLast()
        } else {
            searchItem
                .overflowsLast()
        }
    }

    private static let learnSearchZoomID = "learnSearch"

    private var searchItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Search", systemImage: "magnifyingglass", action: openSearch)
                .keyboardShortcut("f")
                .accessibilityHint("Finds a place by its name, capital or codes.")
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

    // MARK: Layers

    /// Whether the map shows a list of countries on the World, rather than a country's own places,
    /// so the World's layers apply.
    private var showsWorld: Bool {
        ListOrder.listsCountries(navigator.current.collection) && navigator.current.detail == nil
    }

    /// What the World's maps show: the person's travels, or on the World itself the fact chosen,
    /// with the lines and shapes chosen drawn over it.
    private var worldLayers: WorldLayers {
        let shown = shownColouring
        return WorldLayers(
            colouring: shown, showsLatitudes: showsLatitudes, showsAntipodes: showsAntipodes,
            highlight: shown == .travels ? nil : keyHighlight)
    }

    /// What the countries are coloured by on the map shown: the fact chosen on the World, and
    /// the person's travels on any other map, the fact kept for when the map is back on the World.
    private var shownColouring: MapColouring {
        showsWorld ? colouring : .travels
    }

    /// The layer showing, which the chooser lights and the Layers button wears: the Atlas while
    /// it's open, or otherwise what the map is coloured by.
    private var currentLayer: MapLayer { learnDeck != nil ? .atlas : .colouring(shownColouring) }

    /// What the layers say about a country tapped on the World: the fact the map shows first, such
    /// as the side of the road it drives on, then, with the antipodes showing, what lies on the far
    /// side of the Earth from it.
    private func layerFacts(about selection: MapSelection, places: [String: AdministrativeDivision]) -> [MapFact] {
        guard showsWorld else { return [] }
        var facts: [MapFact] = []
        let code = selection.regionID.flatMap(WorldLayers.code(ofRegion:)) ?? selection.place.abbreviation
        if colouring != .travels, let fact = colouring.fact(about: code) {
            facts.append(fact)
        }
        if showsAntipodes, let regionID = selection.regionID {
            facts.append(Antipodes.fact(aboutRegion: regionID) { id in
                (places[id] ?? CountryCatalog.world.divisions.first { $0.id == id })?.displayName(localLanguage: localLanguage)
            })
        }
        return facts
    }

    /// Shows a layer: a fact colours the countries, which sweep across into it, and its key takes
    /// the panel's place; the Atlas sets its cards over the person's travels, starting at the place
    /// whose callout is open, if one is; the time zones open World Time, once the map is still if
    /// it's flying or changing projection. Either way the chooser goes away, and a key put away
    /// comes back for the layer chosen.
    ///
    /// The person's travels chosen in the Atlas put the Atlas away, bringing back any fact the
    /// map showed before it, such as plugs; chosen off the World, they leave the World's fact as
    /// it is, so flying back out to the World finds it still showing. Chosen again while open,
    /// the Atlas only flies back to the place on show.
    private func choose(_ layer: MapLayer) {
        isChoosingLayer = false
        isKeyHidden = false
        switch layer {
        case .colouring(let chosen):
            pendingTimeZones = false
            if chosen == .travels {
                if learnDeck != nil {
                    // Your travels chosen outright shows the travels, not the fact set aside.
                    layerBeforeAtlas = nil
                    stopLearning()
                    return
                }
                guard showsWorld else { return }
            } else {
                // Another fact chosen outright takes the place of the one the Atlas set aside.
                layerBeforeAtlas = nil
                if learnDeck != nil { stopLearning() }
            }
            guard chosen != colouring else { return }
            // A level brought forward belongs to the travels, and a key to the fact it came from.
            highlight = nil
            keyHighlight = nil
            isListing = false
            colouring = chosen
        case .atlas:
            pendingTimeZones = false
            guard learnDeck == nil else {
                frameLearnPlace()
                return
            }
            // The Atlas is over the person's travels, its cards saying what the facts would; the
            // fact is set aside for when the Atlas is put away.
            if colouring != .travels {
                layerBeforeAtlas = colouring
                highlight = nil
                keyHighlight = nil
                isListing = false
                colouring = .travels
            }
            startLearning()
            // With nothing to browse here after all, the fact comes straight back.
            if learnDeck == nil, let before = layerBeforeAtlas {
                layerBeforeAtlas = nil
                colouring = before
            }
        case .timeZones:
            if navigator.isFlying || navigator.reprojection != nil {
                pendingTimeZones = true
            } else {
                showTimeZones()
            }
        }
    }

    /// Opens World Time, chosen while the map was moving, once it has come to rest.
    private func showPendingTimeZones() {
        guard pendingTimeZones, !navigator.isFlying, navigator.reprojection == nil else { return }
        pendingTimeZones = false
        showTimeZones()
    }

    /// Opens World Time for the time zones, out of the map itself. The panel and bars step aside
    /// while the World settles to how it opens, whole, facing north and with a turned globe back
    /// at its centre, and a fact shown sweeps back into the levels' colours at the same time;
    /// then World Time comes up over the map with no animation of its own, and the World curls up
    /// out of exactly what was on screen into the dial or the flat map, World Time covering the
    /// map the while so there's only ever the one World. With Reduce Motion, or from a map other
    /// than the World's, World Time fades in over the map instead.
    private func showTimeZones() {
        guard !isOffToTimeZones else { return }
        guard !navigator.isFlying, navigator.reprojection == nil else {
            pendingTimeZones = true
            return
        }
        pendingTimeZones = false
        let curls = !reduceMotion && navigator.previous == nil && navigator.current.detail == nil
            && navigator.current.collection.id == CountryCatalog.world.id
        let camera = navigator.camera
        let isSettled = camera.zoom <= 1.001 && camera.pan == .zero && camera.facesNorth
            && navigator.globeLongitude == nil
        // The time zones take the place of a fact shown, so the countries sweep back into their
        // levels' colours, which World Time curls up in. Closing World Time comes back to the fact.
        layerBeforeTimeZones = colouring
        let recolours = colouring != .travels
        // The colours take a moment to sweep across the World, on the map's own clock, so a curl
        // waits for the last of them rather than lifting off half-coloured.
        let sweepEnds = Date.now.addingTimeInterval(curls && recolours ? MapTiming.layerSweep + 0.02 : 0)
        let settles = curls && !isSettled
        if settles {
            navigator.touch()
            navigator.turnHome(reduceMotion: reduceMotion)
            navigator.normaliseRotation()
        }
        // The panel and bars fade, the camera settles and the colours change in one go, and World
        // Time comes up the moment that's done, rather than after a guess at how long it takes.
        // With nothing to animate, the completion comes at once.
        withAnimation(
            reduceMotion ? .easeInOut(duration: 0.2) : .smooth(duration: settles ? 0.5 : 0.3),
            completionCriteria: .logicallyComplete
        ) {
            isOffToTimeZones = true
            // A callout goes with the panel; Learn keeps its place outlined for when it's back.
            if learnDeck == nil { navigator.selection = nil }
            if recolours {
                highlight = nil
                keyHighlight = nil
                colouring = .travels
            }
            if settles { navigator.camera = MapCamera() }
        } completion: {
            presentTimeZones(curls: curls, after: sweepEnds)
        }
    }

    /// Brings World Time up over the settled map, once the colours have finished sweeping and a
    /// turned globe has come to rest on its centre.
    private func presentTimeZones(curls: Bool, after sweepEnds: Date) {
        Task { @MainActor in
            let remaining = sweepEnds.timeIntervalSinceNow
            if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            // A globe turning home rests on its centre a moment after it gets there.
            for _ in 0..<20 where navigator.globeLongitude != nil {
                try? await Task.sleep(for: .milliseconds(25))
            }
            guard isOffToTimeZones, !isShowingTimeZones else { return }
            // Where the World lies on screen, in the map's own frame on the screen.
            timeZonesSource = curls && !stageFrame.isEmpty ? TimeZonesSource(
                frame: stageFrame,
                transform: navigator.geometry.transform
                    .concatenating(CGAffineTransform(translationX: stageFrame.minX, y: stageFrame.minY))
            ) : nil
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { isShowingTimeZones = true }
        }
    }

    /// Back from World Time, unrolled into the map where it curled up from: World Time goes at
    /// once, leaving the map just as the World landed on it, which then shows any layer picked in
    /// World Time, or with none picked the fact it showed before, such as plugs, its countries
    /// sweeping across into it, as the panel and bars come back.
    private func returnFromTimeZones() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { isShowingTimeZones = false }
        timeZonesSource = nil
        let before = layerBeforeTimeZones
        layerBeforeTimeZones = .travels
        if let layer = layerFromTimeZones {
            layerFromTimeZones = nil
            choose(layer)
        } else if before != .travels {
            choose(.colouring(before))
        }
        withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) {
            isOffToTimeZones = false
        } completion: {
            // Back in the Atlas, the map, settled whole for World Time, flies back to the place
            // on show once the row is back.
            if learnDeck != nil { frameLearnPlace() }
        }
    }

    /// World Time over the full map, every country in its level's colour as the map paints it,
    /// territories that don't count as countries in their country's, so the World curls up just as
    /// it looked. Its Layers button offers the same chooser as the map's.
    private var worldTime: some View {
        let snapshot = saveModel.snapshot()
        var statuses = Dictionary(
            CountryCatalog.world(applying: counting.rules).divisions.map { ($0.id, snapshot.status(for: $0)) }
        ) { first, _ in first }
        for (regionID, ownerID) in regionOwners where statuses[regionID] == nil {
            if let owner = statuses[ownerID] { statuses[regionID] = owner }
        }
        for place in CountryCatalog.world.divisions where statuses[place.id] == nil {
            statuses[place.id] = snapshot.status(for: place)
        }
        return WorldTimeScreen(
            statuses: statuses,
            sourceFrame: timeZonesSource?.frame,
            sourceMapTransform: timeZonesSource?.transform,
            appColorScheme: colorScheme,
            onChooseLayer: { layerFromTimeZones = $0 },
            onClose: returnFromTimeZones)
    }

    /// A place picked from a fact's key or the search: the map flies to it and opens its callout,
    /// as tapping it would. A tiny island, such as American Samoa, is shown with the lands around
    /// it, as the Atlas shows it, rather than alone in an empty sea. A place drawn in parts, such
    /// as the United Kingdom's four countries, is found by its code and framed whole. Somewhere far
    /// off, the map pans over to it rather than jumping, so the way there is seen.
    private func pick(_ place: AdministrativeDivision, places: [String: AdministrativeDivision]) {
        let animation = MapMotion.camera(MapMotion.glide, reduceMotion: reduceMotion)
        let ids = regionIDs(of: place)
        let parts = ids.compactMap { navigator.current.map.region(id: $0) }
        guard !ids.contains(place.id), let region = parts.first else {
            navigator.focus(on: place, closest: Self.closestToPlace, animation: animation, panOver: true)
            return
        }
        // Framed whole, every part of it in view.
        let bounds = parts.dropFirst().reduce(region.coreBounds) { $0.union($1.coreBounds) }
        // The callout opens where the camera lands, on the last leg of a pan-over, as `focus` does.
        let chosen = MapSelection(place: places[region.id] ?? place, regionID: region.id)
        navigator.frame(bounds, margin: 1.4, animation: animation, panOver: true) {
            navigator.selection = chosen
        }
    }

    /// A place picked from a key's list: the list folds away, the entry still lit, and the map
    /// flies to the place and opens its callout, without a second tick, as the list's card has
    /// ticked already.
    private func pickFromList(_ place: AdministrativeDivision, places: [String: AdministrativeDivision]) {
        withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isListing = false }
        listPickID = place.id
        pick(place, places: places)
    }

    /// The place the map was opened to show, by ID, flown to with its callout open.
    private func select(placeID: String, places: [String: AdministrativeDivision]) {
        guard let place = places[placeID]
            ?? navigator.current.collection.divisions.first(where: { $0.id == placeID })
            ?? CountryCatalog.world.divisions.first(where: { $0.id == placeID })
        else { return }
        pick(place, places: places)
    }

    // MARK: Learn

    /// Starts the Atlas on the map's places, at the place whose callout is open, if it has a card,
    /// or otherwise at the nearest place that does, rather than at the first and far away. The
    /// place is outlined at once, and the map flies to it once the row has been measured, so it
    /// knows the room the row leaves it: one straight glide, rather than one that bends as the
    /// row arrives.
    private func startLearning() {
        let selected = navigator.selection?.place
        guard learnDeck == nil, let deck = LearnDeck(
            collection: navigator.current.collection, rules: counting.rules, startingAt: selected?.id)
        else { return }
        if let selected, !deck.contains(selected), let nearest = nearestAtlasPlace(to: selected, in: deck) {
            _ = deck.jump(to: nearest)
        }
        isChoosingLayer = false
        withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { learnDeck = deck }
        learnTicks += 1
        let outlined = navigator.selection?.place.id
        outlineLearnPlace()
        // Opened from a place's callout, the place is outlined already, so its outline dims and
        // traces round again in the Atlas's colour, to say the Atlas has opened on it.
        if outlined != nil, navigator.selection?.place.id == outlined { pulseLearnOutline() }
        // A row still measured from a moment ago, put away and opened again at once, won't be
        // measured afresh, so the map flies now.
        if hasGrown, !learnFrame.isEmpty {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(40))
                frameLearnPlace()
            }
        }
    }

    /// Outlines the place on show where it lies, without moving the map.
    private func outlineLearnPlace() {
        guard let place = learnDeck?.current else { return }
        let ids = regionIDs(of: place)
        navigator.selection = MapSelection(place: place, regionID: ids.contains(place.id) ? place.id : ids.first)
    }

    /// The place with a card in the Atlas lying nearest a place without one, such as Morocco for
    /// Western Sahara, by the middles of their outlines on the map shown.
    private func nearestAtlasPlace(to place: AdministrativeDivision, in deck: LearnDeck) -> AdministrativeDivision? {
        let map = navigator.current.detail ?? navigator.current.map
        guard let origin = (navigator.selection?.regionID ?? regionIDs(of: place).first).flatMap(map.region(id:))?.center
        else { return nil }
        var nearest: (place: AdministrativeDivision, distance: CGFloat)?
        for candidate in deck.places {
            guard let centre = regionIDs(of: candidate).first.flatMap(map.region(id:))?.center else { continue }
            let distance = hypot(centre.x - origin.x, centre.y - origin.y)
            if distance < nearest?.distance ?? .infinity { nearest = (candidate, distance) }
        }
        return nearest?.place
    }

    /// Whether the map's Atlas has a card for a place: only the places its row counts, so a place
    /// left out of the count, such as Western Sahara or Antarctica, offers no way into it.
    private func hasAtlasCard(for place: AdministrativeDivision) -> Bool {
        atlasPlaceIDs.contains(place.id)
    }

    /// Notes the places the Atlas has a card for on the map shown, counted as its row counts them
    /// (see `LearnDeck`): the collection under the person's rules, and for a country listed with
    /// places of the World, only its own.
    private func refreshAtlasPlaceIDs() {
        let collection = navigator.current.collection
        let counted = MapGame.collections(applying: counting.rules).first { $0.id == collection.id } ?? collection
        let ownID = counted.countryListID
        atlasPlaceIDs = Set(counted.divisions.filter { counted.isOnWorldMap || $0.countryID == ownID }.map(\.id))
    }

    /// Puts the Atlas away, and its outline on the map with it, bringing back the fact the map
    /// showed before the Atlas opened, if it set one aside.
    private func stopLearning() {
        isSearchingLearn = false
        learnReturns = [:]
        isScrubbingOut = false
        let before = layerBeforeAtlas
        layerBeforeAtlas = nil
        withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) {
            learnDeck = nil
            navigator.selection = nil
            if let before, before != colouring {
                highlight = nil
                keyHighlight = nil
                colouring = before
            }
        } completion: {
            // Only once the row has gone, so the map never fills the screen for a moment on the way
            // to making way for the key; opened again meanwhile, the row keeps its measure.
            if learnDeck == nil { learnFrame = .zero }
        }
    }

    /// The Atlas's row of cards: spanning its side of the screen so the cards either side can peek
    /// in, fading away at its ends. Beside the map it takes the whole column, the cards centred
    /// down it with room to breathe; on the near side of the fold it takes all the height there
    /// is; over the foot of the map it's kept short enough to leave the map in view. Where room is
    /// short and there's a home indicator beneath, its glass runs on past the screen's foot, the
    /// cards scrolling within it like a sheet; otherwise it stands as clear of the foot as any
    /// panel does.
    private func learnPanel(
        _ deck: LearnDeck, side: PanelSide, isFolded: Bool, height: CGFloat, columnWidth: CGFloat, safe: EdgeInsets
    ) -> some View {
        let subcollection = learnSubcollection
        let isBeside = side == .trailing
        // Room is short on a phone, on the near side of the fold, and down a column on a short
        // screen, such as iPhone on its side. On iPad, the cards stand whole with room beneath
        // them unless the window is short.
        let isShort = isFolded || (isBeside
            ? height < 520
            : horizontalSizeClass == .regular ? height < 700 : height < 900)
        let bleed: CGFloat? = isShort && safe.bottom > 0 ? safe.bottom : nil
        let room = isBeside || isFolded ? height - 12 : min(height * 0.46, 420)
        let place = deck.current
        return VStack(spacing: 8) {
            // A fresh row of cards for each map's places, flown into or back out of, the new row
            // taking the old one's place on the glass as one panel gives way to another, rather
            // than the two crossing over one above the other.
            ZStack(alignment: isBeside && bleed == nil ? .center : .bottom) {
                GameLearnCard(
                    deck: deck, localLanguage: localLanguage, isRoomy: isFolded || isBeside,
                    // In a short column beside the map, as in landscape, the cards take their
                    // condensed form.
                    isCondensed: isBeside && height < 520,
                    maxHeight: max(room, 220) + (bleed ?? 0), bottomBleed: bleed,
                    onStep: stepLearn, onShow: showLearn, onScrub: scrubLearn,
                    subcollectionLabel: subcollection?.divisionLabel, facts: learnFacts(about:),
                    onOpenSubcollection: openLearnSubcollection,
                    onShowLayers: { isChoosingLayer = true },
                    onClose: { stopLearning() },
                    // The place on show's level, set from its card as from its callout.
                    status: place.map { place in
                        Binding(
                            get: { saveModel.snapshot().status(for: place) },
                            set: { onStatusChange($0, place, navigator.current.collection) })
                    }
                )
                .transition(PanelSwap(reduceMotion: reduceMotion, side: side))
                .id(ObjectIdentifier(deck))
            }
            // The cards either side fade away at the row's ends, rather than being cut off there or
            // running on under the bar beside it on iPhone Duo.
            .mask {
                HStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 22)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 22)
                }
            }
        }
        .frame(width: isBeside ? columnWidth : nil)
        .frame(maxWidth: isBeside ? nil : .infinity)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { learnFrame = $0 }
        .padding(.trailing, isBeside ? Self.columnMargin : 0)
        // On past the screen's safe area to its very edge, or standing clear of it.
        .padding(.bottom, bleed.map { -$0 } ?? Self.footGap(safe))
        .frame(maxHeight: isFolded || isBeside ? .infinity : nil, alignment: isBeside && bleed == nil ? .center : .bottom)
    }

    /// Atlas book: the right-hand page, turning through the same places as the row of cards, and
    /// measured as the row is, so the map flies once it knows the room it has.
    private func bookPages(_ deck: LearnDeck, spineInset: CGFloat) -> some View {
        let place = deck.current
        return AtlasBookPages(
            deck: deck, localLanguage: localLanguage,
            status: place.map { place in
                Binding(
                    get: { saveModel.snapshot().status(for: place) },
                    set: { onStatusChange($0, place, navigator.current.collection) })
            },
            facts: learnFacts(about:),
            onStep: stepLearn,
            onJump: { scrubLearn(to: $0, isFinished: true) },
            onShowLayers: { isChoosingLayer = true },
            onClose: { stopLearning() },
            spineInset: spineInset)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { learnFrame = $0 }
    }

    /// Atlas book: the right-hand page for a layer other than the Atlas, its key along the head
    /// and every entry's places beneath, lighting and picking as the key does on its own.
    private func bookIndex(_ shown: MapColouring, content: MapContent, spineInset: CGFloat) -> some View {
        let travels = travelsKeyContent(content)
        return AtlasBookIndex(
            entries: shown == .travels ? travels.entries : AtlasKeyEntry.entries(for: shown),
            highlight: keyHighlightBinding.wrappedValue, localLanguage: localLanguage, spineInset: spineInset,
            onPick: { pickFromList($0, places: content.places) }
        ) {
            LayerKeyPanel(
                colouring: shown, highlight: keyHighlightBinding, style: .full, localLanguage: localLanguage,
                travels: travels, isListing: false, canHide: false, titleNamespace: keyTitle,
                onPick: { pickFromList($0, places: content.places) },
                onShowLayers: { isChoosingLayer = true })
        }
    }

    /// What a card says after its codes: all the Atlas knows about a country.
    private func learnFacts(about place: AdministrativeDivision) -> [MapFact] {
        MapColouring.facts(about: place)
    }

    /// What the place on show has of its own to learn on a map, such as Japan's prefectures, while
    /// the map can fly into them.
    private var learnSubcollection: Country? {
        guard let place = learnDeck?.current, navigator.current.detail == nil,
              LearnDeck.subcollection(of: place, rules: counting.rules) != nil
        else { return nil }
        return subcollection(of: place)
    }

    /// Flies into the place on show's own places, such as Japan's prefectures, where Learn carries on.
    private func openLearnSubcollection() {
        guard let place = learnDeck?.current, !navigator.isFlying else { return }
        open(MapSelection(place: place, regionID: regionIDs(of: place).first))
    }

    /// Steps through Learn, by the arrows, the arrow keys or VoiceOver, and flies to the place.
    private func stepLearn(_ offset: Int) {
        guard let deck = learnDeck,
              withAnimation(Motion.moving(.snappy, reduceMotion: reduceMotion), { deck.step(by: offset) })
        else { return }
        learnTicks += 1
        frameLearnPlace()
    }

    /// Shows a place in Learn, swiped to in the row of cards or tapped on the map, and flies there.
    private func showLearn(_ place: AdministrativeDivision) {
        guard let deck = learnDeck else { return }
        withAnimation(Motion.moving(.snappy, reduceMotion: reduceMotion)) { _ = deck.jump(to: place) }
        learnTicks += 1
        frameLearnPlace()
    }

    /// Scrubbing through Learn's places: the map pulls all the way out so each place can be seen
    /// outlined as it passes, with a tick at each new region, and once let go, the camera flies to
    /// where it stopped. A place picked from the list goes straight there.
    private func scrubLearn(to index: Int, isFinished: Bool) {
        guard let deck = learnDeck, deck.places.indices.contains(index) else { return }
        if !isFinished, !isScrubbingOut, !navigator.isFlying {
            isScrubbingOut = true
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.6)) {
                navigator.camera = MapCamera(rotation: navigator.camera.rotation)
            }
        }
        if index != deck.index {
            let crossesRegion = deck.current?.groupID != deck.places[index].groupID
            deck.jump(to: index)
            if crossesRegion || isFinished { learnTicks += 1 }
            if !isFinished, let place = deck.current {
                navigator.selection = MapSelection(place: place, regionID: regionIDs(of: place).first)
            }
        }
        if isFinished {
            isScrubbingOut = false
            frameLearnPlace()
        }
    }

    /// A tap on the map while learning brings the row round to the place tapped, rather than
    /// opening its callout.
    private func learnTap(at location: CGPoint, content: MapContent) {
        guard let deck = learnDeck, !navigator.isFlying else { return }
        let geometry = navigator.geometry
        let current = navigator.current
        let place: AdministrativeDivision?
        if let detail = current.detail {
            place = detail.place(at: location, geometry: geometry, among: Set(content.detailPlaces.keys))
                .flatMap { content.detailPlaces[$0.id] }
        } else {
            place = current.map.place(at: location, geometry: geometry, among: Set(content.places.keys))
                .flatMap { content.places[$0.id] }
        }
        guard let place, deck.contains(place) else {
            // A place in the World around a country flown into: out to the World, where the
            // Atlas carries on, as tapping there outside the Atlas would. Anything else, as the
            // sea or a place on the country's own map without a card, knocks softly and the
            // outline on show pulses, to say where the Atlas is.
            if place == nil, navigator.previous != nil, current.detail != nil,
               current.map.place(at: location, geometry: geometry, among: Set(content.places.keys)) != nil {
                navigator.flyBack(reduceMotion: reduceMotion)
            } else {
                learnMisses += 1
                pulseLearnOutline()
            }
            return
        }
        showLearn(place)
    }

    /// The outline round the place on show dims and draws back in, a moment's nudge to look at it.
    private func pulseLearnOutline() {
        guard learnDeck?.current != nil else { return }
        learnPulses += 1
    }

    /// The regions a place is drawn as: its own, or for one drawn in parts on the World, such as
    /// the United Kingdom's four countries, every part, found by its code.
    private func regionIDs(of place: AdministrativeDivision) -> [String] {
        let map = navigator.current.detail ?? navigator.current.map
        if map.region(id: place.id) != nil { return [place.id] }
        guard showsWorld else { return [] }
        return navigator.current.map.regions.filter { WorldLayers.code(ofRegion: $0.id) == place.abbreviation }.map(\.id)
    }

    /// Outlines the place on show and flies to it, framed whole, every part of it in view. A place
    /// already comfortably in view is only outlined, the camera staying still, so stepping from a
    /// large country to a small one nearby doesn't pull the map out and back in. Somewhere far
    /// off, the map pans over to it, pulling back a little on the way, rather than jumping. On the
    /// globe, a place round the side or the back is turned to first, the World pulling back to
    /// whole as it spins, and then flown to.
    private func frameLearnPlace(turningGlobe: Bool = true) {
        // Even while the camera is still on its way to the last place, so stepping on quickly
        // turns the glide towards the next place rather than leaving the map behind.
        guard let place = learnDeck?.current else { return }
        let animation = MapMotion.camera(MapMotion.glide, reduceMotion: reduceMotion)
        if turningGlobe, !isScrubbingOut,
           let longitude = Geography.world?.mainlandBounds(of: regionIDs(of: place).first ?? place.id)?.midX,
           let offset = navigator.turn(toFace: longitude), abs(offset) > 30 {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.6)) {
                navigator.camera = MapCamera(rotation: navigator.camera.rotation)
            }
            outlineLearnPlace()
            navigator.turnGlobe(toFace: longitude, reduceMotion: reduceMotion) {
                frameLearnPlace(turningGlobe: false)
            }
            return
        }
        let map = navigator.current.detail ?? navigator.current.map
        let ids = regionIDs(of: place)
        let parts = ids.compactMap { map.region(id: $0) }
        guard let first = parts.first else {
            navigator.selection = MapSelection(place: place, regionID: nil)
            return
        }
        let bounds = parts.dropFirst().reduce(first.coreBounds) { $0.union($1.coreBounds) }
        let selection = MapSelection(place: place, regionID: ids.contains(place.id) ? place.id : first.id)
        // The outline traces itself in on the map's own clock, alongside the camera's glide. The map
        // always moves on with the cards: where the place shows well at the zoom there is, as a
        // larger neighbour does from close in, it pans across to it without zooming; where it
        // would be a speck or wouldn't fit, or from the whole map, it's framed.
        if navigator.keepsZoom(showing: bounds) {
            navigator.selection = selection
            navigator.centre(on: bounds, animation: animation)
        } else if parts.count == 1, first.id == place.id {
            // A tiny island is shown with the lands around it, not alone in the sea.
            navigator.focus(on: place, closest: Self.closestToPlace, animation: animation, panOver: true)
        } else {
            navigator.selection = selection
            navigator.frame(bounds, margin: 1.4, animation: animation, panOver: true)
        }
    }

    /// The closest the map comes to a place it flies to, from the Atlas's cards, a key's list or
    /// the search, so a tiny island such as Tuvalu still has its neighbours around it.
    private static let closestToPlace: CGFloat = 5

    /// The search, zooming out of its button where the toolbar can be its source: Learn's own
    /// places while learning, or otherwise the map's, gathered as it opened.
    @ViewBuilder
    private var learnSearchSheet: some View {
        if let deck = learnDeck ?? searchDeck {
            let sheet = LearnSearchSheet(deck: deck, localLanguage: localLanguage) { result in
                if learnDeck != nil {
                    learnPick = result
                } else {
                    mapPick = result.place
                }
            }
            if #available(iOS 26.0, *) {
                sheet.navigationTransition(.zoom(sourceID: Self.learnSearchZoomID, in: learnSearchZoom))
            } else {
                sheet
            }
        }
    }

    /// Opens the search, gathering the map's places for it outside Learn.
    private func openSearch() {
        if learnDeck == nil {
            searchDeck = LearnDeck(collection: navigator.current.collection, rules: counting.rules)
            guard searchDeck != nil else { return }
        }
        isSearchingLearn = true
    }

    /// Once the search has closed, goes to the place picked, so the way there is seen. In Learn the
    /// row of cards and the map travel there, and its card lights up what it was found by;
    /// otherwise the map flies there and opens its callout. VoiceOver, left on the search button,
    /// hears where it's gone.
    private func landFromSearch() {
        searchDeck = nil
        if let place = mapPick {
            mapPick = nil
            let content = MapContent(
                stop: navigator.current, snapshot: saveModel.snapshot(), rules: counting.rules, regionOwners: regionOwners)
            pick(content.detailPlaces[place.id] ?? place, places: content.places)
            AccessibilityNotification.Announcement(place.displayName(localLanguage: localLanguage)).post()
            return
        }
        guard let pick = learnPick else { return }
        learnPick = nil
        showLearn(pick.place)
        learnDeck?.land(on: pick)
        AccessibilityNotification.Announcement(pick.place.displayName(localLanguage: localLanguage)).post()
    }

    // MARK: Panel

    /// Which panel sits with the map: the layer chooser, or the key of the layer shown, on every
    /// map, the person's travels a layer like any other, and off the World the only one.
    private var panelMode: PanelMode {
        if isChoosingLayer { return .layers }
        return .key(shownColouring)
    }

    /// What's brought forward on the map from the key of the layer shown: a level for the person's
    /// travels, by its ID, or an entry of a fact's key. Bringing an entry forward lists its places,
    /// and letting it go folds them away. An entry left lit after a place was picked from its list
    /// lists its places again when tapped, rather than letting go, so a second look is one tap.
    /// Listing an entry's places closes any callout, so the list never floats over it; whichever
    /// was asked for last shows, as a callout opening folds the list away.
    private var keyHighlightBinding: Binding<String?> {
        let isTravels = shownColouring == .travels
        return Binding(
            get: { isTravels ? highlight?.id : keyHighlight },
            set: { id in
                // Lit or let go in place, snappily: the glass takes the entry's colour in step
                // with the entry itself, while its list opens or folds on the panel's curve. A
                // callout closing goes on its own quick curve.
                withAnimation(.atlasKey(reduceMotion: reduceMotion)) {
                    let lit = isTravels ? highlight?.id : keyHighlight
                    if id == nil, lit != nil, !isListing {
                        isListing = true
                        closeCalloutForList()
                        return
                    }
                    if isTravels {
                        highlight = id.flatMap { id in ladder.levels.first { $0.id == id } }
                    } else {
                        keyHighlight = id
                    }
                    isListing = id != nil
                    if isListing { closeCalloutForList() }
                }
            })
    }

    /// Closes the callout, outside the Atlas, as a key's places are listed over the map.
    private func closeCalloutForList() {
        guard learnDeck == nil, navigator.selection != nil else { return }
        navigator.selection = nil
    }

    /// The person's travels as a layer's key, for the map shown: a level each, with its places,
    /// and how many count.
    private func travelsKeyContent(_ content: MapContent) -> LayerKeyPanel.Travels {
        LayerKeyPanel.Travels(
            entries: TravelsKey.entries(
                ladder: ladder, places: navigator.current.collection.divisions, statuses: content.listedStatuses,
                localLanguage: localLanguage),
            counted: content.counted, total: navigator.current.collection.divisions.count)
    }

    /// Whether the key is put away to its tab. Never on the near side of iPhone Duo's fold, where
    /// the key has its own side and nothing to make room for.
    private func showsKeyTab(isFolded: Bool) -> Bool {
        isKeyHidden && !isFolded
    }

    /// The panel on one sheet of glass, which reshapes as one panel gives way to the next: the
    /// chooser's cards closing into a key, a key folding down into its tab. Each panel's contents
    /// blur away as the next's come into focus, the glass and contents moving on the one curve,
    /// the panel's own (`MapMotion.panel(reduceMotion:)`).
    /// Over the foot of the map it's centred and no wider than reads well, a key's tab only as
    /// wide as its name; in the column beside the map, or on the near side of the fold, it fills
    /// its side.
    private func panelArea(
        content: MapContent, isFolded: Bool, side: PanelSide, columnWidth: CGFloat, columnHeight: CGFloat,
        safe: EdgeInsets
    ) -> some View {
        let mode = panelMode
        let gap = Self.footGap(safe)
        // On the near side of the fold a panel fills it; in the column, the chooser takes its
        // width but only the height its cards need.
        let fillsWidth = isFolded || side == .trailing
        let isTab: Bool
        if case .key = mode { isTab = showsKeyTab(isFolded: isFolded) } else { isTab = false }
        // A key on the near side of the fold takes only the height it needs, growing as an entry's
        // places are listed; the chooser fills it.
        let fills: Bool
        if case .key = mode { fills = false } else { fills = isFolded }
        let room = columnHeight - (side == .trailing ? 8 : 0) - gap
        return ZStack(alignment: side == .trailing ? .top : .bottom) {
            panelContent(mode, content: content, isFolded: isFolded, side: side, room: max(room, 200))
                .frame(
                    maxWidth: isTab ? nil : fillsWidth ? .infinity : 600, maxHeight: fills ? .infinity : nil,
                    alignment: .top)
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                    fitGlass(to: size, for: mode)
                }
                // A key put away and brought back swaps on the glass as one panel for another does.
                .id([AnyHashable(mode), AnyHashable(isTab)])
                .transition(PanelSwap(reduceMotion: reduceMotion, side: side))
        }
        // The glass behind, sized to the panel showing and reshaping to the next; behind rather
        // than beside it, so the glass's last size never holds the panel wider or taller than its
        // room. Solid to touch, so a tap between the panel's controls doesn't fall through to the map.
        .background(alignment: side == .trailing ? .top : .bottom) {
            Color.clear
                .contentShape(.rect(cornerRadius: 28))
                .glassPanel(in: .rect(cornerRadius: 28), tint: panelTint(for: mode))
                .frame(width: panelGlass.width, height: panelGlass.height)
                .accessibilityHidden(true)
        }
        // The chooser and a key read in the one typeface.
        .fontDesign(.rounded)
        .animation(MapMotion.panel(reduceMotion: reduceMotion), value: mode)
        // A tab in the column keeps to its trailing edge, under where the key stood.
        .frame(width: side == .trailing ? columnWidth : nil, alignment: isTab ? .trailing : .center)
        .padding(.leading, side == .trailing ? 0 : 12)
        .padding(.trailing, side == .trailing ? Self.columnMargin : 12)
        .padding(.top, side == .trailing ? 8 : 0)
        // Standing clear of the foot as every panel does.
        .padding(.bottom, gap)
        // In the column a key hangs from the top, and its tab rests in the corner of the foot.
        .frame(
            maxHeight: fills || side == .trailing ? .infinity : nil,
            alignment: side == .trailing && !isTab ? .top : .bottom)
    }

    /// What the panel holds: the chooser, or the key of the layer shown, or its tab once put away.
    /// `room` is the most height the panel may stand to on its side.
    @ViewBuilder
    private func panelContent(
        _ mode: PanelMode, content: MapContent, isFolded: Bool, side: PanelSide, room: CGFloat
    ) -> some View {
        let isColumn = side == .trailing
        switch mode {
        case .learn:
            // The Atlas's row stands on its own, never in the panel.
            EmptyView()
        case .layers:
            MapLayerChooser(
                current: currentLayer, layers: showsWorld ? MapLayer.all : MapLayer.everywhere,
                isSeparate: isFolded,
                // The chooser's header and the room around its grid take about 80 points.
                maxGridHeight: isColumn ? room - 80 : max(200, min(stageFrame.height * 0.5, room - 80)),
                showsMapSection: true, isWorld: showsWorld,
                onChoose: choose
            ) {
                isChoosingLayer = false
            }
        case .key(let shown) where showsKeyTab(isFolded: isFolded):
            KeyTab(colouring: shown, levelColor: ladder.levels.last?.color, namespace: keyTitle) {
                withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isKeyHidden = false }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                guard !isFolded, !isColumn, panelMode == .key(shown) else { return }
                closedPanelHeight = height + 8
            }
        case .key(let shown):
            // The whole key on its own side, beside the map or across the fold; a slim strip
            // over the foot.
            let isFull = isFolded || isColumn
            LayerKeyPanel(
                colouring: shown, highlight: keyHighlightBinding,
                style: isFull ? .full : .strip,
                localLanguage: localLanguage,
                travels: travelsKeyContent(content),
                isListing: isListing,
                // On its own side, the key and its places stand as tall as the side allows, so a
                // long list scrolls once, with the key, rather than in a scroller of its own. The
                // key's header and the room around it take about 84 points of that.
                maxListHeight: isFull ? max(room - 84, 140) : max(140, min(stageFrame.height * 0.3, room - 120)),
                // Across the fold the key has its own side, so there's nothing to put it away for.
                canHide: !isFolded,
                titleNamespace: keyTitle,
                onPick: { pickFromList($0, places: content.places) },
                onRestingHeightChange: { height in
                    // Only the strip itself; a list floating over it leaves the map where it is.
                    guard !isFull, panelMode == .key(shown) else { return }
                    closedPanelHeight = height + 8
                },
                onShowLayers: { isChoosingLayer = true },
                onHide: {
                    withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) {
                        keyHighlight = nil
                        highlight = nil
                        isListing = false
                        isKeyHidden = true
                    }
                }
            )
        }
    }

    /// The glass takes the colour of whatever is brought forward: a level, or a key of the fact shown.
    private func panelTint(for mode: PanelMode) -> Color? {
        switch mode {
        case .layers, .learn: nil
        case .key(.travels): highlight?.color
        case .key(let shown): keyHighlight.flatMap(shown.key(id:))?.color
        }
    }

    /// Reshapes the glass around the panel showing, on the same curve as the panel's contents and
    /// a key's list, so glass and contents move as one.
    private func fitGlass(to size: CGSize, for mode: PanelMode) {
        guard mode == panelMode else { return }
        if panelGlass == .zero {
            panelGlass = size
        } else if panelGlass != size {
            withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { panelGlass = size }
        }
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

    /// Lets the ring land on the level chosen, then puts the callout away, as the list's picker
    /// does, but a little sooner, so it has gone by the time the risen place lands back on the map
    /// rather than fading over it.
    private func putAwayCallout(for id: String) {
        Task {
            try? await Task.sleep(for: Self.calloutSettleDelay)
            guard navigator.selection?.place.id == id else { return }
            withAnimation(LevelTapback.closing) { navigator.selection = nil }
        }
    }

    /// How long the callout stays once a level is chosen on the map: long enough for the ring to
    /// land on the new badge, and shorter than the list's (`LevelTapback.settleDelay`), as here
    /// the place rising lifts off the map and lands again just after.
    private static let calloutSettleDelay = Duration.milliseconds(450)

    /// Flies into a place's subdivisions, at `level` where they're listed at more than one, such as
    /// France's departments, or otherwise at their first.
    private func open(_ selection: MapSelection, level: String? = nil) {
        guard let first = subcollection(of: selection.place) else { return }
        // Learn carries on in the map flown into, and coming back, at the place flown into.
        if learnDeck != nil { learnReturns[navigator.current.collection.id] = selection.place.id }
        let collection = level.flatMap { id in CountryCatalog.levels(of: first).first { $0.id == id } } ?? first
        if navigator.current.collection.id == CountryCatalog.world.id,
           let subdivisions = Geography.subdivisions(of: collection.id) {
            navigator.fly(
                into: collection,
                // A hand-turned globe cuts the subdivisions around the same longitude as the World.
                subdivisions: navigator.globeLongitude.map { subdivisions.map(projection, centerLongitude: $0) }
                    ?? subdivisions.map(projection, center: navigator.center),
                local: TravelMap.named(collection.id), from: selection.regionID, reduceMotion: reduceMotion)
        } else if let map = TravelMap.named(collection.id), let placed = map.placedOnParent,
                  navigator.current.collection.id == collection.countryListID {
            // A place's own subdivisions, such as Tasmania's, trace themselves in over the country's map.
            navigator.fly(into: collection, subdivisions: placed, local: map, from: selection.regionID, reduceMotion: reduceMotion)
        } else if let map = TravelMap.named(collection.id) {
            navigator.fly(into: collection, map: map, from: selection.regionID, reduceMotion: reduceMotion)
        } else {
            leave(toList: collection.id)
        }
    }

    /// Grows the map out of its card. Opened into the Atlas, the map only flies to the place on
    /// show once it has grown, so the two read as one beat after the other. With Reduce Motion it
    /// fades in where it will stand instead, and the card steps aside only once it's covered.
    private func expand() {
        if !reduceMotion { onPresent() }
        withAnimation(MapMotion.grow(reduceMotion: reduceMotion)) {
            isExpanded = true
        } completion: {
            if reduceMotion, !isClosing { onPresent() }
            hasGrown = true
            guard !isClosing, learnDeck != nil, !learnFrame.isEmpty else { return }
            frameLearnPlace()
        }
    }

    /// Zooms the map in or out a step about its middle, from the keyboard.
    private func zoom(by factor: CGFloat) {
        guard isExpanded, !isOffToTimeZones, !navigator.isFlying else { return }
        navigator.zoomStep(by: factor, animation: reduceMotion ? nil : .smooth(duration: 0.35))
    }

    /// The map back round to north: the compass, its needle home, goes with a click.
    private func arriveNorth() {
        guard isCompassShown, navigator.camera.facesNorth else { return }
        withAnimation(reduceMotion ? MapMotion.fade : .smooth(duration: 0.3)) { isCompassShown = false }
        northArrivals += 1
    }

    /// Shrinks the map back into its card, or with Reduce Motion fades it away where it stands.
    private func close() {
        guard !isClosing else { return }
        isClosing = true
        // With Reduce Motion nothing turns or glides back to where it started while it's seen;
        // the map is set back once it has faded away.
        guard !reduceMotion else {
            withAnimation(MapMotion.shrink(reduceMotion: true)) {
                isExpanded = false
            } completion: {
                navigator.returnToStart()
                onClose()
            }
            return
        }
        // A globe that drifted turns back to its centre as it shrinks into the card, which shows it,
        // and a turned map comes round to north the short way as it goes.
        navigator.turnHome(reduceMotion: reduceMotion)
        navigator.normaliseRotation()
        withAnimation(MapMotion.shrink(reduceMotion: reduceMotion)) {
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

/// Which callout card is showing: one for each place, and for which side of it the card sits.
private struct CalloutIdentity: Hashable {
    var placeID: String
    var pointsDown: Bool
}

/// Where the World lay on the full map as World Time opened out of it: the map's frame on the
/// screen, and the World's own units to the screen, so World Time curls up out of exactly that.
private struct TimeZonesSource {
    var frame: CGRect
    var transform: CGAffineTransform
}

/// The full map's haptics for moving through the Atlas and its layers: a tick for each move
/// through the Atlas, and as the chooser opens or closes and the key is put away or brought back,
/// as World Time's Layers button gives; a click as the compass, back at north, goes; and a soft
/// knock for a tap on nothing to learn, such as the sea.
private struct ScreenFeedback: ViewModifier {
    var learnTicks: Int
    var chooserTicks: Int
    var northArrivals: Int
    var learnMisses: Int

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.selection, trigger: learnTicks)
            .sensoryFeedback(.selection, trigger: chooserTicks)
            .sensoryFeedback(.alignment, trigger: northArrivals)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: learnMisses)
    }
}

/// Which panel sits with the full map.
private enum PanelMode: Hashable {
    /// The chooser of what the map shows.
    case layers
    /// A layer's key, such as the two roads for driving side, or a chip for each level of the
    /// person's travels, which every map has.
    case key(MapColouring)
    /// The Atlas's row of cards, which stands where the panel would.
    case learn
}

/// Where a panel stands on the full map, which the map keeps clear of.
private enum PanelSide: Hashable {
    /// Over the foot of the map, the map keeping above its resting height.
    case foot
    /// In a column down the trailing side of a wide screen, the map keeping to the leading side.
    case trailing
}

/// One panel giving way to the next on the same glass: its contents soften and sink a little as
/// they fade, and the next's sharpen as they rise into place. With Reduce Motion they only fade.
/// They sink towards the panel's foot over the foot of the map, and up towards its top in the
/// column, where the panel hangs from the top.
private struct PanelSwap: Transition {
    var reduceMotion: Bool
    var side: PanelSide

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: phase.isIdentity || reduceMotion ? 0 : 10)
            .scaleEffect(phase.isIdentity || reduceMotion ? 1 : 0.94, anchor: side == .trailing ? .top : .bottom)
    }
}

/// The key to what the World is coloured by, the person's travels or a fact: its symbol and name,
/// then the key made for it, a chip for each level of the travels, two roads for driving side,
/// every plug in use for plugs, the voltages, or the oceans. Tapping an entry brings its places
/// forward and lists them by name, such as every country at 110 V, and picking one finds it.
/// Tapping the layer's name opens the chooser, to change it, and a button at the end puts the key
/// away, leaving the layer's colours on the map.
///
/// Over the foot of the map it rests as a slim strip, its header on one line over a row of small
/// chips, and an entry's places float up over the map above it, on the same glass, so tapping an
/// entry never moves the map. On the near side of the fold it's the full key with the places
/// listed beneath it. The travels' header also counts the places that count.
private struct LayerKeyPanel: View {
    enum Style {
        /// The resting strip, an entry's places floating above it.
        case strip
        /// The whole key, listing an entry's places beneath it, filling its side.
        case full
    }

    /// The person's travels as a key: a level each, with its places, and how many count.
    struct Travels {
        var entries: [AtlasKeyEntry]
        var counted: Int
        var total: Int
    }

    var colouring: MapColouring
    @Binding var highlight: String?
    var style: Style
    var localLanguage: Bool
    var travels: Travels
    /// Whether the places of the entry brought forward are listed; picked from, the list folds
    /// away while the entry stays lit.
    var isListing = true
    /// The tallest an entry's places float above the strip before they scroll, or for the full
    /// key, the tallest the key and its places stand.
    var maxListHeight: CGFloat = 210
    /// Whether the key can be put away to a tab.
    var canHide = true
    /// Where the key's title is matched with its tab's, so putting the key away folds the title
    /// down into the tab.
    var titleNamespace: Namespace.ID? = nil
    var onPick: (AdministrativeDivision) -> Void
    /// The strip's own height, without any list floating over it, for the map to keep clear of.
    var onRestingHeightChange: (CGFloat) -> Void = { _ in }
    /// Opens the layer chooser, from the layer's name.
    var onShowLayers: () -> Void = {}
    /// Puts the key away, the layer's colours staying on the map.
    var onHide: () -> Void = {}
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Set as the key appears, which bounces its symbol, a little payoff for the pick.
    @State private var hasAppeared = false
    /// How tall the whole key stands, with any places it lists.
    @State private var fullHeight: CGFloat = 0

    private var entries: [AtlasKeyEntry] {
        colouring == .travels ? travels.entries : AtlasKeyEntry.entries(for: colouring)
    }

    var body: some View {
        let entries = entries
        Group {
            switch style {
            case .full:
                VStack(alignment: .leading, spacing: 12) {
                    header
                        .padding(.horizontal, 18)
                    ScrollView {
                        key(entries, isCompact: false, listsPlaces: isListing)
                            // An entry's places listed again after a pick open on the panel's
                            // curve, as they do when the entry is first lit.
                            .animation(MapMotion.panel(reduceMotion: reduceMotion), value: isListing)
                            .padding(.bottom, 4)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                                // Taken at once the first time, so the key opens at its size; after
                                // that it glides as places are listed or folded away, on the panel's
                                // curve, so the key and the glass round it move as one.
                                guard fullHeight > 0 else {
                                    fullHeight = height
                                    return
                                }
                                withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { fullHeight = height }
                            }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                    // As tall as the key and any places it lists, up to the room there is.
                    .frame(height: fullHeight > 0 ? min(fullHeight, maxListHeight) : nil)
                }
                .padding(.top, 14)
                .padding(.bottom, 12)
            case .strip:
                VStack(spacing: 0) {
                    if isListing, let entry = entries.first(where: { $0.id == highlight }) {
                        AtlasPlaceList(entry: entry, localLanguage: localLanguage, onPick: onPick, maxHeight: maxListHeight)
                            .padding(.top, 14)
                            .transition(.atlasPlaceList(reduceMotion: reduceMotion))
                    }
                    strip(entries)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { onRestingHeightChange($0) }
                }
                // The places float up and fold away on the panel's curve, with the glass round
                // them. Nearer the list, that wins as an entry is lit and listed at once; lighting
                // another entry while one is listed stays snappy, as lighting in place does.
                .animation(MapMotion.panel(reduceMotion: reduceMotion), value: isListing)
                .animation(.atlasKey(reduceMotion: reduceMotion), value: highlight)
            }
        }
        // The travels' count and total roll to their new values, and the header makes room for
        // them as they go, rather than the count jumping as its digits change.
        .animation(Motion.count, value: travels.counted)
        .animation(Motion.count, value: travels.total)
        .sensoryFeedback(.selection, trigger: highlight)
        .task {
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .milliseconds(200))
            hasAppeared = true
        }
    }

    /// The header folded onto one line over the key's chips.
    private func strip(_ entries: [AtlasKeyEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                title(font: .headline, symbolWidth: 24)
                Spacer(minLength: 8)
                count
                if canHide { hideButton }
            }
            .padding(.leading, 14)
            .padding(.trailing, 6)
            key(entries, isCompact: true, listsPlaces: false)
        }
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    /// The tallest a key's own list of places stands before it scrolls: in the full key, all the
    /// room the key has, so the list scrolls with the key rather than inside it.
    private var listMaxHeight: CGFloat {
        style == .full ? maxListHeight : 210
    }

    @ViewBuilder
    private func key(_ entries: [AtlasKeyEntry], isCompact: Bool, listsPlaces: Bool) -> some View {
        switch colouring {
        case .travels:
            TravelsKey(
                entries: entries, highlight: $highlight, localLanguage: localLanguage, onPick: onPick,
                listsPlaces: listsPlaces, listMaxHeight: listMaxHeight)
        case .plugs:
            PlugGallery(
                entries: entries, highlight: $highlight, localLanguage: localLanguage, onPick: onPick,
                isCompact: isCompact, listsPlaces: listsPlaces, listMaxHeight: listMaxHeight)
        case .voltage:
            VoltageKey(
                entries: entries, highlight: $highlight, localLanguage: localLanguage, onPick: onPick,
                isCompact: isCompact, listsPlaces: listsPlaces, listMaxHeight: listMaxHeight)
        case .coasts:
            CoastsKey(
                entries: entries, highlight: $highlight, localLanguage: localLanguage, onPick: onPick,
                isCompact: isCompact, listsPlaces: listsPlaces, listMaxHeight: listMaxHeight)
        default:
            DrivingSideKey(
                entries: entries, highlight: $highlight, localLanguage: localLanguage, onPick: onPick,
                isCompact: isCompact, listsPlaces: listsPlaces, listMaxHeight: listMaxHeight)
        }
    }

    /// The layer's symbol in its colour, the travels' in the top level's, bouncing once as the key
    /// appears.
    private var symbol: some View {
        Image(systemName: colouring.symbolName)
            .foregroundStyle(colouring.tint ?? ladder.levels.last?.color ?? .primary)
            .symbolEffect(.bounce, value: hasAppeared)
            .accessibilityHidden(true)
    }

    /// For the travels, how many places count of all there are, as the list's own count reads. Both
    /// roll to their new values: the count as a level is set, and the total as the map flies into a
    /// country, 195 rolling to 47.
    @ViewBuilder
    private var count: some View {
        if colouring == .travels {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(travels.counted, format: .number)
                    .typeStyle(.count)
                    .contentTransition(.numericText(value: Double(travels.counted)))
                Text("/ \(travels.total.formatted())")
                    .typeStyle(.countTotal)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(travels.total)))
            }
            .fixedSize()
            .feelsRipples()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(travels.counted) of \(travels.total) counted")
        }
    }

    /// The layer's symbol and its name, and the way to put the key away.
    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            title(font: .title3.weight(.semibold), symbolWidth: 30)
            Spacer(minLength: 8)
            count
            if canHide { hideButton }
        }
    }

    /// The layer's symbol and name, which open the chooser to change the layer, a small chevron
    /// saying so. Putting the key away folds them down into its tab.
    private func title(font: Font, symbolWidth: CGFloat) -> some View {
        Button(action: onShowLayers) {
            HStack(spacing: 8) {
                symbol
                    .frame(width: symbolWidth)
                ScrollingName(text: colouring.name)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .font(font)
            .modifier(KeyTitleMatch(namespace: titleNamespace))
            .contentShape(.rect)
        }
        // A pill as wide as the key's name, so it gives only a little under the finger.
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .foregroundStyle(.primary)
        .accessibilityLabel(colouring.name)
        .accessibilityHint("Shows the layers, to choose another.")
        .accessibilityAddTraits(.isHeader)
    }

    /// Puts the key away, leaving the layer's colours on the map.
    private var hideButton: some View {
        Button("Hide key", systemImage: "chevron.down", action: onHide)
            .labelStyle(.iconOnly)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 30, height: 30)
            .background(.fill.tertiary, in: Circle())
            .frame(width: 40, height: 40)
            .contentShape(Circle())
            .buttonStyle(PillButtonStyle())
            .accessibilityHint("Keeps the layer's colours on the map.")
    }
}

/// A layer's key put away: a slim tab of the layer's symbol and name at the foot of the map, its
/// colours still on the map, which brings the key back when tapped. The key's title folds down
/// into it as the key is put away, and lifts back up out of it as the key comes back.
private struct KeyTab: View {
    var colouring: MapColouring
    /// The person's top level's colour, which the travels' symbol wears.
    var levelColor: Color?
    /// Where the tab's symbol and name are matched with the key's title.
    var namespace: Namespace.ID? = nil
    var onShow: () -> Void

    var body: some View {
        Button(action: onShow) {
            // As wide as its name, up to a comfortable width, past which the name glides.
            WidthCap(maxWidth: 360) {
                HStack(spacing: 8) {
                    Image(systemName: colouring.symbolName)
                        .foregroundStyle(colouring.tint ?? levelColor ?? .primary)
                        .accessibilityHidden(true)
                    ScrollingName(text: colouring.name)
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .modifier(KeyTitleMatch(namespace: namespace))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .contentShape(.rect)
        }
        // A pill as wide as the key's name, so it gives only a little under the finger.
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .accessibilityLabel("Show key for \(colouring.name.lowercased())")
    }
}

/// The key's symbol and name, matched between its title and its tab, so putting the key away
/// folds the title down into the tab and bringing it back lifts it up into place, rather than
/// one simply fading as the other appears. Only their place on screen is matched, never their
/// size, so the name is never squeezed on the way. With Reduce Motion, or with nothing to match
/// with, each comes and goes with its panel.
private struct KeyTitleMatch: ViewModifier {
    var namespace: Namespace.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if let namespace, !reduceMotion {
            content.matchedGeometryEffect(id: "keyTitle", in: namespace, properties: .position)
        } else {
            content
        }
    }
}

/// Holds its content to its own width, but never wider than `maxWidth`: unlike a frame with a
/// most width, which widens to fill whatever it's offered up to that width, it hugs what it
/// holds, so a key's tab is only as wide as its name.
private struct WidthCap: Layout {
    var maxWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let width = min(proposal.width ?? maxWidth, maxWidth)
        return content.sizeThatFits(ProposedViewSize(width: width, height: proposal.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(
            at: bounds.origin, proposal: ProposedViewSize(width: bounds.width, height: bounds.height))
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
    /// Whether the names show: switched in the chooser, they fade in or out on the map's own
    /// clock, as they do as the map opens and closes.
    var showsLabels = true
    var isExpanded: Bool
    var revealsOnAppear: Bool
    var sourceFrame: CGRect?
    /// The panel's frame when it floats over the map or stands beside it, so the map keeps clear of it.
    var panelFrame: CGRect
    /// Where the panel stands, which says which side of it the map keeps to.
    var panelSide: PanelSide = .foot
    /// Room kept clear over the top of the map, under the bar, for a key pinned there.
    var topClearance: CGFloat = 0
    /// Every region of the selected place, outlined together, such as all four of the United
    /// Kingdom's countries for any one tapped.
    var selectionParts: Set<String> = []
    /// The outline's colour where it isn't the usual, as Learn's.
    var selectionTint: Color? = nil
    /// Whether a tinted outline traces itself in round each place newly picked.
    var tracesSelection = false
    /// Changes to pulse a tinted outline round again.
    var selectionPulses = 0
    /// What VoiceOver calls the map, such as "Map of World, showing plugs".
    var mapLabel: String
    /// What VoiceOver says about finding places on the map and where its panel is.
    var hint: String
    /// Whether the compass is up, from turning away from north until back round to it.
    @Binding var isCompassShown: Bool
    /// How far the compass steps in from the map's trailing edge, out from under a chooser
    /// floating in the top corner.
    var compassInset: CGFloat = 0
    /// A place whose choosing doesn't tick, as one picked from a list, which has ticked already.
    var untickedPlaceID: String? = nil
    var onFrameChange: (CGRect) -> Void
    var onClose: () -> Void
    /// Touch and hold on the map, at a point in the map's own space.
    var onLongPress: (CGPoint) -> Void
    /// While learning, a tap on the map, at a point in its own space, which moves Learn to the
    /// place there; no callout opens while it's set.
    var onLearnTap: ((CGPoint) -> Void)? = nil
    /// While learning, two fingers sliding sideways together spin the World round, as a finger
    /// does on a list's map, rather than sliding the map.
    var spinsWithTwoFingers = false
    /// Opens the layer chooser, for VoiceOver; nil where the map has no layers.
    var onShowLayers: (() -> Void)? = nil
    /// Opens the search, for VoiceOver.
    var onSearch: (() -> Void)? = nil
    /// Called as the map comes all the way back round to north, to put the compass away.
    var onNorth: () -> Void = {}
    @ViewBuilder var callout: (MapSelection, CalloutPlacement) -> Callout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gesture: StageGesture?
    /// How far the fingers had turned when turning the map took hold, past the dead zone, so the
    /// map starts turning from where it is rather than jumping. Nil until then.
    @State private var turnLatch: Angle?
    /// How far the map has turned in this gesture, kept for when one finger lifts and the turn ends
    /// while the drag carries on.
    @State private var gestureTurn = Angle.zero
    /// Where two fingers first came down, whichever of pinching and turning took hold first, so the
    /// map pivots about one point all gesture long rather than hopping when the other begins.
    @State private var twoFingerAnchor: CGPoint?
    /// How far two fingers had slid when they took to spinning the World, so it turns from there
    /// rather than jumping.
    @State private var spinOrigin: CGFloat = 0
    /// How far a pinch has taken the map below the whole view, towards letting it go: 1 and over
    /// lets go when the fingers lift.
    @State private var pinchOut: Double?
    @State private var calloutHeight: CGFloat = 240
    @State private var longPressHandled = false
    @State private var longPresses = 0
    /// Counts each time two fingers take hold of turning the map, for a tick.
    @State private var turnEngaged = 0

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
                let insets = clearInsets(safe: safe, global: global, focus: navigator.current.focus)
                let camera = navigator.camera
                let geometry = MapGeometry(
                    focus: navigator.fitted(navigator.current.focus, size: proxy.size, insets: insets), size: proxy.size,
                    zoom: camera.zoom, pan: camera.pan, insets: insets, rotation: camera.rotation)
                let fitArea = geometry.fitArea
                let growth = growth(bounds: bounds, global: global, insets: insets)
                ZStack(alignment: .topLeading) {
                    layers(camera: camera, size: proxy.size, insets: insets, anchor: UnitPoint(
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
                            if let onLearnTap {
                                onLearnTap(location)
                                return
                            }
                            withAnimation(LevelTapback.opening) {
                                _ = navigator.select(
                                    at: location, places: places, detailPlaces: detailPlaces, reduceMotion: reduceMotion)
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
                        // inside the card, with the card's soft edges, and grows out of the page with
                        // soft edges all the way, reaching the screen's own edges as it settles.
                        // With Reduce Motion it stands at its full size from the start, edges and
                        // all, and only fades in and out.
                        .mask {
                            GrowthMask(
                                progress: isExpanded || reduceMotion ? 1 : 0,
                                card: sourceFrame?.offsetBy(dx: -global.minX, dy: -global.minY) ?? bounds,
                                bounds: bounds)
                        }
                        .opacity(isExpanded || (sourceFrame != nil && !reduceMotion) ? 1 : 0)
                        .accessibilityElement()
                        .accessibilityLabel(mapLabel)
                        .accessibilityHint(hint)
                        // Turning is never needed: a turned map can always be brought back to north.
                        .accessibilityActions {
                            if !camera.facesNorth {
                                Button("Face north") { faceNorth() }
                            }
                            if let onShowLayers {
                                Button("Layers", action: onShowLayers)
                            }
                            if let onSearch {
                                Button("Search", action: onSearch)
                            }
                        }
                    LinearGradient(
                        colors: [Color.pageBackground.opacity(0.8), .clear],
                        startPoint: .top, endPoint: .bottom)
                        .frame(height: safe.top + 20)
                        .opacity(isExpanded ? 1 : 0)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    // The hint fades in and out on its own short curve, kept to it alone, so it
                    // never sets the pace of what the same lift of the fingers sets off: the map
                    // springing back, closing, or flying back out, each on its own curve, or with
                    // Reduce Motion, cutting. Pulling the map down shows the same hint, Close,
                    // filling in once letting go will close it.
                    ZStack {
                        if isExpanded, let pinchOut {
                            LetGoHint(
                                title: navigator.previous?.collection.name ?? "Close",
                                systemImage: navigator.previous == nil ? "xmark" : "chevron.backward",
                                progress: pinchOut)
                                .position(x: fitArea.midX, y: fitArea.minY + 34)
                                .transition(.opacity)
                        } else if isExpanded, gesture == .pull {
                            LetGoHint(
                                title: "Close", systemImage: "xmark",
                                progress: max(navigator.pullOffset.height, 0) / Self.pullToClose)
                                .position(x: fitArea.midX, y: fitArea.minY + 34)
                                .transition(.opacity)
                        }
                    }
                    .animation(
                        reduceMotion ? MapMotion.fade : .smooth(duration: 0.25), value: pinchOut == nil && gesture != .pull)
                    if onLearnTap == nil {
                        calloutLayer(geometry: geometry)
                            // Carried into new room with the map as a panel comes or goes, rather
                            // than jumping ahead of it.
                            .animation(MapMotion.room, value: insets)
                    }
                    // Turned away from north, a compass in the corner shows which way north lies,
                    // and brings the map back round to it when tapped. It stays while the needle
                    // swings home with the map, and goes once the map is facing north.
                    ZStack {
                        if isExpanded, isCompassShown {
                            MapCompass(rotation: camera.rotation, action: faceNorth)
                                .position(x: fitArea.maxX - compassInset - 26, y: fitArea.minY + 26)
                                .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                        }
                    }
                    .animation(MapMotion.room, value: insets)
                    .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: compassInset)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: (pinchOut ?? 0) >= 1) { _, isArmed in isArmed }
                // The same as a pull down passes the point where letting go closes the map.
                .sensoryFeedback(.impact(weight: .medium), trigger: navigator.pullOffset.height > Self.pullToClose) {
                    _, isArmed in isArmed
                }
                .onChange(of: MapLayout(size: proxy.size, insets: insets), initial: true) { _, layout in
                    navigator.updateLayout(layout)
                }
                .onChange(of: global, initial: true) { _, frame in onFrameChange(frame) }
            }
            .ignoresSafeArea()
        }
        // Choosing a place ticks, as choosing does on every map; impacts are kept for actions.
        // Learn gives its own tick as it moves the outline on.
        .sensoryFeedback(.selection, trigger: navigator.selection?.place.id) { _, new in
            new != nil && onLearnTap == nil && new != untickedPlaceID
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: longPresses)
        // A tick as two fingers take hold of turning the map; the click as it comes back to face
        // north comes with the compass going (see `onNorth`).
        .sensoryFeedback(.selection, trigger: turnEngaged)
        .onChange(of: navigator.camera.facesNorth) { _, facesNorth in
            guard facesNorth else {
                withAnimation(reduceMotion ? MapMotion.fade : .smooth(duration: 0.3)) { isCompassShown = true }
                return
            }
            // Brought round by a pinch's snap, or anything else that doesn't say when it's
            // there, the compass goes once the turn has had time to finish; at once with Reduce
            // Motion, as nothing turns.
            guard !reduceMotion else {
                onNorth()
                return
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(650))
                if navigator.camera.facesNorth { onNorth() }
            }
        }
    }

    /// The current map, with the map before it while the two cross over.
    private func layers(camera: MapCamera, size: CGSize, insets: EdgeInsets, anchor: UnitPoint) -> some View {
        ZStack {
            // A country flown into from the World shares the World's layer, so its subdivisions
            // arrive on the same map instead of crossing to another.
            ForEach([navigator.current], id: \.layerID) { stop in
                let isReshaping = navigator.reprojection != nil && stop.id == CountryCatalog.world.id
                TimelineView(.animation(paused: !isReshaping)) { timeline in
                    let shown = shownMap(for: stop, at: timeline.date, size: size, insets: insets)
                    TravelMapCanvas(
                        map: shown.map, statuses: statuses, minimumStatus: minimumStatus,
                        zoom: camera.zoom, pan: camera.pan, rotation: camera.rotation, insets: insets,
                        focus: shown.focus,
                        revealsOnAppear: revealsOnAppear && !navigator.hasFlown,
                        highlight: highlight, selection: navigator.selection?.regionID,
                        selectionParts: selectionParts, selectionTint: selectionTint,
                        tracesSelection: tracesSelection, selectionPulses: selectionPulses,
                        detail: stop.detail.map {
                            MapDetail(map: $0, statuses: detailStatuses, ownerRegionIDs: owners(of: stop, detail: $0))
                        },
                        detailProgress: navigator.detailProgress,
                        morph: stop.detail == nil ? nil : stop.local,
                        morphProgress: navigator.morphProgress,
                        detailIsLeaving: navigator.isDrainingSubdivisions,
                        labels: labels, showsLabels: isExpanded && showsLabels
                    )
                }
                .transition(layerTransition(anchor: anchor))
            }
        }
        .animation(MapMotion.room, value: insets)
    }

    /// The World's regions a country's subdivisions cover: the country itself, and places such as
    /// Hong Kong that appear in both lists. Taiwan is one of China's only while it isn't counted
    /// as a country of its own.
    private func owners(of stop: MapStop, detail: TravelMap) -> Set<String> {
        var owners = Set(detail.regions.map(\.id).filter { detailStatuses[$0] != nil })
        if let country = CountryCatalog.world.divisions.first(where: { $0.abbreviation == stop.collection.countryListID }) {
            owners.insert(country.id)
        }
        return owners
    }

    /// A stop's map and the part of it fitted to the screen, or the World map partway between
    /// projections while it reshapes. A World that runs on round fills the screen from top to
    /// foot rather than fitting whole, so while it reshapes, the share of its width fitted glides
    /// from the old projection's to the new one's: a rectangular World keeps its fill as it starts
    /// to reshape and grows into it as it lands, rather than jumping.
    private func shownMap(
        for stop: MapStop, at date: Date, size: CGSize, insets: EdgeInsets
    ) -> (map: TravelMap, focus: CGRect) {
        guard let change = navigator.reprojection, stop.id == CountryCatalog.world.id,
              let geography = Geography.world
        else { return (stop.map, navigator.fitted(stop.focus, size: size, insets: insets)) }
        let map = geography.map(
            from: change.from, to: change.to, progress: change.progress(at: date), center: navigator.center)
        let whole = map.focusRect(including: [])
        let width = whole.width * change.share(at: date)
        return (map, CGRect(x: whole.midX - width / 2, y: whole.minY, width: width, height: whole.height))
    }

    /// Flying in, the new map comes up from below while the old one rushes past and fades;
    /// flying back, the reverse. With Reduce Motion, the two maps simply cross-fade.
    private func layerTransition(anchor: UnitPoint) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
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
                let transition = LevelTapback.transition(from: placement.unitAnchor, reduceMotion: reduceMotion)
                callout(selection, placement)
                    .frame(width: placement.width)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                        // Placed at first by the last callout's height, it settles into place once
                        // it's been measured, rather than jumping.
                        withAnimation(MapMotion.control(reduceMotion: reduceMotion)) { calloutHeight = height }
                    }
                    .position(placement.center)
                    // It comes and goes on its own curves, whatever set it off: the camera flying to
                    // a place, a tap, the Atlas opening. It arrives with the tapback's bounce, and
                    // goes quickly, so one swapped for another never lingers beside it.
                    .transition(.asymmetric(
                        insertion: transition.animation(MapMotion.arrive(reduceMotion: reduceMotion)),
                        removal: transition.animation(MapMotion.leave(reduceMotion: reduceMotion))))
                    // Each place has a card of its own: another place's card grows out of its point
                    // as this one shrinks quickly away into its own, rather than one card gliding
                    // over while its rows, such as Canada's provinces and the way into the Atlas,
                    // fade through one another. Flipping between above and below swaps it too.
                    .id(CalloutIdentity(placeID: selection.place.id, pointsDown: placement.pointsDown))
            }
        }
    }

    /// How the full-size map is carried while it isn't open: scaled and moved so its map lies exactly
    /// over the card's, or, with no card in view, a little smaller around the middle. With Reduce
    /// Motion it's never carried, only faded in and out where it stands.
    private func growth(bounds: CGRect, global: CGRect, insets: EdgeInsets) -> (scale: CGFloat, offset: CGSize) {
        guard !isExpanded, !reduceMotion else { return (1, .zero) }
        guard let sourceFrame else {
            return (0.92, CGSize(width: bounds.width * 0.04, height: bounds.height * 0.04))
        }
        let card = sourceFrame.offsetBy(dx: -global.minX, dy: -global.minY)
        // The card shows the whole map; open, the part of it fitted to the screen, which may be
        // only the middle of a World running on round, so the same stretch of map is carried
        // from where it lies in the card.
        let whole = navigator.current.focus
        let focus = navigator.fitted(whole, size: bounds.size, insets: insets)
        let open = focus.applying(MapGeometry(focus: focus, size: bounds.size, zoom: 1, pan: .zero, insets: insets).transform)
        let inCard = focus.applying(MapGeometry(focus: whole, size: card.size, zoom: 1, pan: .zero).transform)
            .offsetBy(dx: card.minX, dy: card.minY)
        guard open.width > 0, inCard.width > 0 else { return (1, .zero) }
        let scale = inCard.width / open.width
        return (scale, CGSize(width: inCard.minX - open.minX * scale, height: inCard.minY - open.minY * scale))
    }

    /// Room kept clear for bars, the screen's edges, and a panel over the map, whether it floats
    /// over the map's foot or, as Learn's row on a wide screen, stands beside it: the map keeps to
    /// whichever side of it lets the map be drawn largest.
    private func clearInsets(safe: EdgeInsets, global: CGRect, focus: CGRect) -> EdgeInsets {
        let insets = EdgeInsets(
            top: safe.top + 8 + topClearance, leading: safe.leading + 8, bottom: safe.bottom, trailing: safe.trailing + 8)
        guard !panelFrame.isEmpty, panelFrame.intersects(global) else { return insets }
        var sides: [EdgeInsets] = []
        var beside = insets
        beside.trailing = max(insets.trailing, global.maxX - panelFrame.minX + 8)
        var above = insets
        above.bottom = max(insets.bottom, global.maxY - panelFrame.minY + 8)
        let startsPastLeading = panelFrame.minX > global.minX + 40
        switch panelSide {
        case .trailing:
            // In the column beside it, the map keeps to the leading side, never squeezed above.
            if startsPastLeading {
                sides.append(beside)
            } else if panelFrame.minY > global.minY {
                sides.append(above)
            }
        case .foot:
            if panelFrame.minY > global.minY { sides.append(above) }
            // Should a panel over the foot stand to the trailing side after all, up to the safe
            // area's edge, as beside iPhone Duo's bar, the map may take its leading side instead.
            if startsPastLeading, panelFrame.maxX >= global.maxX - safe.trailing - 40 {
                sides.append(beside)
            }
        }
        func scale(_ side: EdgeInsets) -> CGFloat {
            let width = global.width - side.leading - side.trailing
            let height = global.height - side.top - side.bottom
            guard width > 0, height > 0, focus.width > 0, focus.height > 0 else { return 0 }
            return min(width / focus.width, height / focus.height)
        }
        return sides.max { scale($0) < scale($1) } ?? insets
    }

    private var pullScale: CGFloat {
        1 - min(max(navigator.pullOffset.height, 0) / 1400, 0.3)
    }

    /// Brings a turned map back round to north, the compass going once it's there.
    private func faceNorth() {
        navigator.faceNorth(animation: reduceMotion ? nil : .smooth(duration: 0.5), completion: onNorth)
    }

    /// Pinch, turn and drag to move the camera. At the whole-map view, pulling down puts the map
    /// away, and so does pinching it smaller than the screen. Two fingers turn the map only once
    /// they've turned past a small dead zone, so a pinch doesn't turn it by accident.
    private func panAndZoom(origin: CGPoint, center: CGPoint) -> some Gesture {
        MagnifyGesture()
            .simultaneously(with: RotateGesture(minimumAngleDelta: .degrees(1)))
            .simultaneously(with: DragGesture(minimumDistance: 6, coordinateSpace: .global))
            .onChanged { value in
                let pinch = value.first?.first
                let twist = value.first?.second
                let drag = value.second
                let isTwoFingered = pinch != nil || twist != nil
                let translation = drag?.translation ?? .zero
                if gesture == nil {
                    let pullsDown = !isTwoFingered && navigator.camera.zoom <= 1.01
                        && translation.height > abs(translation.width)
                    // Seen whole, the World turns under a sideways drag instead of sliding.
                    let turns = !isTwoFingered && navigator.canTurnGlobe && abs(translation.width) >= abs(translation.height)
                    let spins = isTwoFingered && spinsWithTwoFingers && navigator.current.id == CountryCatalog.world.id
                        && navigator.current.detail == nil
                    gesture = spins ? .twoFingers : pullsDown ? .pull : turns ? .turn : .camera
                }
                // In the Atlas, two fingers hold the map still until they show what they mean:
                // spread or turned, they pinch and turn it as ever, and slid up or down they slide
                // it; slid sideways together first, they spin the World round, as a finger does on
                // a list's map, the map pulling back to the whole World as it starts to turn.
                if gesture == .twoFingers {
                    let spread = abs((pinch?.magnification ?? 1) - 1)
                    let turned = abs(twist?.rotation.degrees ?? 0)
                    // A finger lifted before deciding leaves a drag of the map.
                    if !isTwoFingered || spread > Self.spinSpread || turned > Self.turnDeadZone.degrees {
                        gesture = .camera
                    } else if hypot(translation.width, translation.height) > Self.spinStart {
                        if abs(translation.width) >= abs(translation.height) {
                            gesture = .spin
                            spinOrigin = translation.width
                            navigator.cancelGlide()
                            navigator.cancelGesture()
                            withAnimation(reduceMotion ? nil : .smooth(duration: 0.5)) { navigator.camera = MapCamera() }
                        } else {
                            gesture = .camera
                        }
                    } else {
                        return
                    }
                }
                if gesture == .spin {
                    navigator.turnGlobe(by: translation.width - spinOrigin)
                    return
                }
                if gesture == .pull {
                    navigator.pullOffset = translation
                } else if gesture == .turn {
                    navigator.turnGlobe(by: translation.width)
                } else {
                    let dragStart = drag.map { CGPoint(x: $0.startLocation.x - origin.x, y: $0.startLocation.y - origin.y) }
                    if twoFingerAnchor == nil { twoFingerAnchor = pinch?.startLocation ?? twist?.startLocation }
                    // Past the map's edges or zoom limits, it gives like a rubber band.
                    navigator.moveCamera(
                        magnification: pinch?.magnification ?? 1,
                        rotation: turn(by: twist?.rotation),
                        anchor: (isTwoFingered ? twoFingerAnchor : nil) ?? dragStart ?? center,
                        translation: translation, resists: true)
                    // Pinched smaller than the whole map, a hint shows what letting go will do.
                    let zoom = navigator.camera.zoom
                    pinchOut = pinch != nil && zoom < 0.99
                        ? Double((1 - zoom) / (1 - MapNavigator.letGoZoom)) : nil
                }
            }
            .onEnded { value in
                defer {
                    gesture = nil
                    pinchOut = nil
                    turnLatch = nil
                    gestureTurn = .zero
                    twoFingerAnchor = nil
                    spinOrigin = 0
                }
                // Held still without deciding, the map is where it was.
                if gesture == .twoFingers { return }
                let drag = value.second
                // Spun, the World carries on with the fingers' speed and settles on a centre.
                if gesture == .spin {
                    navigator.endTurningGlobe(velocity: drag?.velocity.width ?? 0, reduceMotion: reduceMotion)
                    return
                }
                if gesture == .turn {
                    navigator.endTurningGlobe(velocity: drag?.velocity.width ?? 0, reduceMotion: reduceMotion)
                    return
                }
                if gesture == .pull {
                    let predicted = drag?.predictedEndTranslation.height ?? 0
                    if navigator.pullOffset.height > Self.pullToClose || predicted > 340 {
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
                // Turned only a little, it settles facing north.
                let springsBack = navigator.isPastLimits
                let fling = drag.map {
                    CGSize(
                        width: ($0.predictedEndTranslation.width - $0.translation.width) * 0.6,
                        height: ($0.predictedEndTranslation.height - $0.translation.height) * 0.6)
                } ?? .zero
                navigator.settleCamera(
                    fling: springsBack ? .zero : fling,
                    animation: reduceMotion ? nil : springsBack ? .bouncy(duration: 0.5) : .smooth(duration: 0.6))
            }
    }

    /// How far the map turns for the fingers' turn so far: nothing within the dead zone, then
    /// everything past where turning took hold, so it starts from rest.
    private func turn(by fingers: Angle?) -> Angle {
        guard let fingers else { return gestureTurn }
        if turnLatch == nil, abs(fingers.degrees) >= Self.turnDeadZone.degrees {
            turnLatch = fingers.degrees < 0 ? -Self.turnDeadZone : Self.turnDeadZone
            turnEngaged += 1
        }
        guard let turnLatch else { return .zero }
        gestureTurn = fingers - turnLatch
        return gestureTurn
    }

    /// How far two fingers turn before the map turns with them.
    private static var turnDeadZone: Angle { .degrees(8) }

    /// In the Atlas, how far two fingers spread before they pinch rather than spin the World, and
    /// how far they slide together before they spin it.
    private static var spinSpread: CGFloat { 0.06 }
    private static var spinStart: CGFloat { 24 }

    /// How far the map is pulled down before letting go closes it.
    private static var pullToClose: CGFloat { 110 }
}

/// Which way north lies on a turned map: a glass circle in its corner whose needle points north,
/// and which brings the map back round to north when tapped, its needle bouncing as it does,
/// though not with Reduce Motion. World Time's map uses it too.
struct MapCompass: View {
    var rotation: Angle
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var taps = 0

    init(rotation: Angle, action: @escaping () -> Void) {
        self.rotation = rotation
        self.action = action
    }

    var body: some View {
        Button("Face north", systemImage: "location.north.line.fill") {
            taps += 1
            action()
        }
        .labelStyle(.iconOnly)
        .symbolEffect(.bounce, value: reduceMotion ? 0 : taps)
        .font(.body.weight(.semibold))
        .foregroundStyle(.red)
        .rotationEffect(rotation)
        .frame(width: 44, height: 44)
        .glassPanel(in: Circle(), interactive: true)
        .contentShape(Circle())
        .buttonStyle(PillButtonStyle())
        .accessibilityValue(turnDescription)
    }

    /// Which way north lies, such as "North is 30 degrees to the right", rather than a signed angle.
    private var turnDescription: String {
        let degrees = Int(MapCamera.normalised(rotation).degrees.rounded())
        return degrees >= 0
            ? "North is \(degrees) degrees to the right"
            : "North is \(-degrees) degrees to the left"
    }
}

private enum StageGesture {
    case camera, pull, turn
    /// In the Atlas, two fingers down and not yet spread, turned or moved far enough to say
    /// whether they pinch or spin the World.
    case twoFingers
    /// In the Atlas, two fingers sliding sideways together, spinning the World round.
    case spin
}

/// What letting go of a pinch will do, shown while the map is pinched smaller than the whole view:
/// back out to the map it was flown into from, or closed; and the same for a pull down, which
/// closes it. It grows as the pinch or pull goes on, and once far enough it fills in, ready, its
/// symbol giving a little bounce. World Time's map uses it too.
struct LetGoHint: View {
    var title: String
    var systemImage: String
    var progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts each time the hint fills in, ready, for its symbol to bounce.
    @State private var armings = 0

    init(title: String, systemImage: String, progress: Double) {
        self.title = title
        self.systemImage = systemImage
        self.progress = progress
    }

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
            .symbolEffect(.bounce, value: armings)
            .scaleEffect(reduceMotion ? 1 : isArmed ? 1.06 : 0.85 + 0.15 * min(progress, 1))
            .opacity(min(progress * 1.6, 1))
            .animation(.bouncy(duration: 0.35), value: isArmed)
            .onChange(of: isArmed) { _, isArmed in
                if isArmed, !reduceMotion { armings += 1 }
            }
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
    /// The most room the card may take; what's beneath its badges scrolls past it.
    var maxHeight: CGFloat

    init(anchor: CGPoint?, height: CGFloat, area: CGRect) {
        width = min(340, max(area.width - 8, 160))
        guard let anchor, area.insetBy(dx: -30, dy: -30).contains(anchor) else {
            // With the place out of view, the card rests at the top of the map.
            maxHeight = max(area.height - 24, LevelTapback.minimumHeight)
            center = CGPoint(x: area.midX, y: area.minY + 12 + min(height, maxHeight) / 2)
            pointerX = width / 2
            pointsDown = true
            hasPointer = false
            unitAnchor = .top
            return
        }
        // Above the place where it fits, otherwise below; too tall for either, it takes the roomier
        // side and scrolls what's beneath its badges, so it's never cut off by the map's edges.
        let spaceAbove = anchor.y - 2 - area.minY
        let spaceBelow = area.maxY - anchor.y - 2
        let above = height <= spaceAbove || (height > spaceBelow && spaceAbove >= spaceBelow)
        let space = above ? spaceAbove : spaceBelow
        hasPointer = space >= LevelTapback.minimumHeight
        pointsDown = above || !hasPointer
        let x = min(max(anchor.x, area.minX + 4 + width / 2), area.maxX - 4 - width / 2)
        let y: CGFloat
        if hasPointer {
            maxHeight = space
            let shown = min(height, space)
            y = above ? anchor.y - 2 - shown / 2 : anchor.y + 2 + shown / 2
        } else {
            // No room either side, as on a short screen: it rests over the place, as tall as the map allows.
            maxHeight = max(area.height, LevelTapback.minimumHeight)
            let shown = min(height, maxHeight)
            y = min(max(anchor.y, area.minY + shown / 2), area.maxY - shown / 2)
        }
        center = CGPoint(x: x, y: y)
        pointerX = anchor.x - (x - width / 2)
        unitAnchor = UnitPoint(x: pointerX / width, y: pointsDown ? 1 : 0)
    }
}

/// The full map's edges as it's carried out of its card and back. In the card they're the card's
/// own soft edges; on the way they stay soft, softest midway, so the map grows out of the page
/// rather than as a box laid over it; they reach the screen's edges only once it fills the screen.
private struct GrowthMask: View, Animatable {
    /// 0 in the card, 1 filling the screen.
    var progress: Double
    var card: CGRect
    var bounds: CGRect

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let t = CGFloat(min(max(progress, 0), 1))
        let rect = CGRect(
            x: card.minX + (bounds.minX - card.minX) * t, y: card.minY + (bounds.minY - card.minY) * t,
            width: card.width + (bounds.width - card.width) * t, height: card.height + (bounds.height - card.height) * t)
        let bloom = sin(.pi * t)
        EdgeFade(horizontal: 28 * (1 - t) + 110 * bloom, vertical: 18 * (1 - t) + 90 * bloom)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
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
/// The room the full map has: its size, and how iPhone Duo's fold divides it.
private struct AtlasRoom: Equatable {
    var size: CGSize
    var fold: FoldRegions?
    var book: FoldRegions?
}

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

/// Pulls back to the whole map, facing north. Only this button follows the camera, so the toolbar doesn't redraw as it moves.
/// Command-0 does the same, as on Maps.
private struct ShowAllButton: View {
    var navigator: MapNavigator
    /// Called once the map is back whole and facing north, to put the compass away.
    var onArrive: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button("Show all", systemImage: "arrow.down.right.and.arrow.up.left") {
            navigator.showAll(animation: reduceMotion ? nil : .smooth(duration: 0.5), completion: onArrive)
        }
        .keyboardShortcut("0", modifiers: .command)
        // Zoomed in or turned, there's a whole north-up map to come back to.
        .disabled(navigator.camera.zoom <= 1.01 && navigator.camera.facesNorth)
    }
}
