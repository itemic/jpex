import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(CountingPreferences.self) private var counting
    @Environment(CustomWorldGroups.self) private var customGroups
    @Query private var saveModels: [SaveModel]
    /// The list open now. A first launch opens on the World.
    @AppStorage("selectedCountry") private var selectedCountryID = CountryCatalog.world.id
    /// The level each country listed at more than one level was last shown at, such as France's
    /// departments, one list ID per line, so it opens there again.
    @AppStorage("shownLevels") private var shownLevels = ""
    /// Whether the welcome has been seen through, so it shows only on a first launch.
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var showingWelcome = false
    /// Set when Replay Welcome screen is chosen in Settings, to show the welcome once Settings has gone.
    @State private var showsWelcomeAfterSettings = false
    /// Whether the welcome showing was asked for again, from Settings, rather than a first launch:
    /// then countries lit in it are practice, and it ends back in the list it was opened from.
    @State private var welcomeIsReplay = false
    @State private var listBeforeWelcome: String?
    /// The way back from the list the welcome was asked for from, for it to lead there again after.
    @State private var trailBeforeWelcome: [String] = []
    /// The person's own most-marked list, for the welcome to tour first, worked out as it opens.
    @State private var welcomeLeg: WelcomeLeg?
    /// Where the open list's map is on screen, for the welcome's World to land on.
    @State private var listMap = ListMapLocation()
    /// The catalog's lists under the rules last asked about, built once rather than at every pass.
    @State private var catalog = CatalogCache()
    @AppStorage("localLanguage") private var localLanguage = false
    @State private var preferredColumn: NavigationSplitViewColumn = .detail
    @State private var saveError: String?
    @State private var undoState = UndoState()
    @State private var haptic: StatusHaptic?
    /// The region the person just finished, so its header can celebrate.
    @State private var regionCelebration: RegionCelebration?
    /// A finished region's celebration, held until the place that finished it lands back on its map.
    @State private var heldCelebration: RegionCelebration?
    @State private var showingSettings = false
    /// The lists opened from one another on the way to this one, such as the World before Japan,
    /// newest last, for going back.
    @State private var trail: [String] = []
    /// How the list now shown was arrived at, so its map can fly over from the one before.
    @State private var arrival: CollectionArrival?
    /// The list's width, for telling a swipe in from its trailing edge in right-to-left languages.
    @State private var containerWidth: CGFloat = 0
    @State private var game: MapGame?
    /// Learn asked for from the quiz lobby, for the list of its collection to open its full map in.
    @State private var learnRequest: LearnDeck.Request?
    /// The width of the page before the fold while iPhone Duo is held partly folded like a book.
    @State private var leadingPageWidth: CGFloat?
    /// Where the list starts on screen, and how far a side bar of controls insets it there.
    @State private var detailEdge = DetailEdge()
    /// A place found by search in the list already open, to bring into view there.
    @State private var revealedPlace: RevealedPlace?
    /// A group of countries of the person's own being made or changed in its editor.
    @State private var groupDraft: CustomGroupDraft?
    /// One of the person's groups waiting for them to confirm it should go.
    @State private var groupPendingDeletion: CustomWorldGroup?

    /// How wide the sidebar should be for the column split to fall on an upright fold, such as
    /// iPhone Duo held like a book, so each page holds one column and the split view keeps its
    /// own margins either side of the crease. Nil while the screen is flat, folds across, or the
    /// fold leaves too little room on either side, such as a window beside another app.
    nonisolated private static func leadingPageWidth(in proxy: GeometryProxy) -> CGFloat? {
        guard #available(iOS 27.1, *), let fold = proxy.reservedRegions(kind: .division).first,
              fold.frame.height > fold.frame.width
        else { return nil }
        let before = fold.frame.minX - fold.margins.leading
        let after = proxy.size.width - fold.frame.maxX - fold.margins.trailing
        guard before > 260, after > 260 else { return nil }
        return fold.frame.midX
    }

    /// Whether the list's leading edge is the screen's own, where a swipe in from the edge can
    /// begin: not beside the sidebar, and not inset by a side bar of controls.
    private var detailStartsAtScreenEdge: Bool {
        detailEdge.inset < 1 && (layoutDirection == .rightToLeft || detailEdge.minX < 1)
    }

    /// Every list that can be chosen: each country's, and each group of countries', such as the EU
    /// or one the person made.
    private var countries: [Country] {
        catalog.countries(applying: counting.rules) + groupCollections
    }

    /// Every group of countries, the person's own first, then the World's.
    private var groupCollections: [Country] {
        // Countries hidden from the World are left out of its groups too.
        (customGroups.collections(applying: counting.rules) + WorldGroup.collections)
            .map { $0.hiding(counting.rules.hiddenStates) }
    }

    /// The sidebar's sections, with groups of countries just after the World.
    private var sidebarSections: [CollectionSection] {
        var sections = catalog.sections(applying: counting.rules)
        sections.insert(CollectionSection(title: CollectionSection.worldGroupsTitle, countries: groupCollections), at: min(1, sections.count))
        return sections
    }

    private var country: Country {
        countries.first { $0.id == selectedCountryID } ?? CountryCatalog.japan
    }

    var body: some View {
        // From the snapshot, decoded once for the saved data as it is, rather than at every pass.
        let ladder = saveModels.first?.snapshot().ladder ?? .standard
        // In parts, so each is quick to type-check.
        observing(presenting(splitView, ladder: ladder), ladder: ladder)
            .environment(\.visitLadder, ladder)
    }

    /// The places in the sidebar, and the list open beside them.
    private var splitView: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            CountrySidebarView(
                sections: sidebarSections,
                selectedCountryID: rootSelection,
                saveModel: saveModels.first,
                rules: counting.rules,
                onOpenPlace: { placeID, collectionID in openPlace(placeID, in: collectionID, keepsWayBack: false) },
                onEditGroup: editGroup,
                onDeleteGroup: { groupPendingDeletion = $0 },
                // The list opens with its full map in the Atlas, as the quiz lobby's Atlas tile does.
                onOpenAtlas: openAtlas(fromSidebar:)
            )
            .navigationTitle("Places")
            // Held like a book, the places fill the left page and the list the right one, each
            // clear of the fold, instead of the list straddling it.
            .navigationSplitViewColumnWidth(
                min: 260, ideal: leadingPageWidth ?? 290, max: max(leadingPageWidth ?? 330, 330))
        } detail: {
            // One list at a time, which changes in place: opening a country from the World flies its
            // map in and loads its sections where the World's were, rather than pushing a new page.
            NavigationStack {
                if let saveModel = saveModels.first {
                    collectionView(for: country, saveModel: saveModel)
                        // Places rising break out over the screen only while the list is what's in front.
                        .environment(\.breaksOutOntoScreen, !showingSettings && !showingWelcome && game == nil)
                        // The World card holds still at its centre beneath the welcome, for it to land on.
                        .environment(\.isBeneathWelcome, showingWelcome)
                } else {
                    ProgressView()
                }
            }
        }
        .onGeometryChange(for: CGFloat?.self, of: Self.leadingPageWidth(in:)) { leadingPageWidth = $0 }
    }

    /// What shows over the lists: the welcome, Settings, the quiz, a group being edited, and their alerts.
    private func presenting(_ content: some View, ladder: VisitLadder) -> some View {
        let presented = content
            // The welcome fills the screen over everything, the World flying in through space.
            .overlay {
                if showingWelcome, let saveModel = saveModels.first {
                    let snapshot = saveModel.snapshot()
                    WelcomeView(
                        worldStatuses: Dictionary(
                            CountryCatalog.world(applying: counting.rules).divisions.map { ($0.id, snapshot.status(for: $0)) }
                        ) { first, _ in first },
                        personalLeg: welcomeLeg,
                        landing: listMap,
                        onLanding: landOnWorld,
                        onFinish: finishWelcome(keeping:))
                    .transition(.opacity)
                } else if !hasSeenWelcome && saveError == nil {
                    // On a first launch, space is already there from the very first frame, so the
                    // welcome opens straight out of the dark rather than after a flash of the lists
                    // beneath it.
                    Color.black
                        .ignoresSafeArea()
                }
            }
            .statusBarHidden(showingWelcome || !hasSeenWelcome)
            .tint(.primary)
            .sensoryFeedback(trigger: haptic) { _, event in event?.feedback }
            .sheet(isPresented: $showingSettings) {
                if showsWelcomeAfterSettings {
                    showsWelcomeAfterSettings = false
                    showWelcome(isReplay: true)
                }
            } content: {
                SettingsView(saveModel: saveModels.first) { showsWelcomeAfterSettings = true }
            }
            .fullScreenCover(item: $game) { game in
                GameScreen(game: game) {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { self.game = nil }
                } onLearn: { request in
                    learn(request)
                }
                .presentationBackground(.clear)
            }
        return editingGroups(presented, ladder: ladder)
    }

    /// One of the person's own groups being made or changed, and one waiting for them to confirm
    /// it should go. Apart from the rest, so each part is quick to type-check.
    private func editingGroups(_ content: some View, ladder: VisitLadder) -> some View {
        let snapshot = saveModels.first?.snapshot() ?? TravelSnapshot(stored: [:], legacyJapan: [], ladder: ladder)
        let deletionTitle: String = "Delete “\(groupPendingDeletion?.name ?? "")”?"
        let isConfirmingDeletion = Binding(
            get: { groupPendingDeletion != nil }, set: { if !$0 { groupPendingDeletion = nil } })
        return content
            .sheet(item: $groupDraft) { draft in
                CustomGroupEditor(draft: draft, rules: counting.rules, snapshot: snapshot, onSave: saveGroup)
            }
            .confirmationDialog(deletionTitle, isPresented: isConfirmingDeletion, titleVisibility: .visible) {
                if let group = groupPendingDeletion {
                    Button("Delete group", role: .destructive) { deleteGroup(group) }
                }
            } message: {
                Text("Its countries keep their levels.")
            }
            // A group deleted anywhere else, such as in Settings, takes its list with it: the World
            // opens in its place, and the way back no longer leads to it.
            .onChange(of: customGroups.groups) {
                let ids = Set(customGroups.groups.map(\.collectionID))
                let isGone = { (id: String) in CustomWorldGroup.groupID(fromCollectionID: id) != nil && !ids.contains(id) }
                trail.removeAll(where: isGone)
                if isGone(selectedCountryID) {
                    trail = []
                    arrival = nil
                    selectedCountryID = CountryCatalog.world.id
                }
            }
    }

    /// What the lists keep up with: the store on launch, choices, undo and resets.
    private func observing(_ content: some View, ladder: VisitLadder) -> some View {
        content
            .background { CelebrationRelay(held: $heldCelebration, released: $regionCelebration) }
            .task {
                prepareStore()
                raiseCountriesToTheirPlacesOnce()
                raiseRegionsToTheirPlacesOnce()
                applyPlaceReorganisations()
                if !hasSeenWelcome, !saveModels.isEmpty || (try? modelContext.fetchCount(FetchDescriptor<SaveModel>())) ?? 0 > 0 {
                    showWelcome(isReplay: false)
                }
            }
            .onChange(of: saveModels.count) {
                raiseCountriesToTheirPlacesOnce()
                raiseRegionsToTheirPlacesOnce()
                applyPlaceReorganisations()
            }
            // The list is brought forward by whatever opens it, not by every change: a group deleted
            // from the sidebar leaves the sidebar showing.
            .onChange(of: selectedCountryID) {
                rememberLevel(of: country)
            }
            .onChange(of: ladder) { old, new in
                // Undo can't bring back a level that has been deleted.
                if old.levels.contains(where: { new.level(id: $0.id) == nil }) {
                    undoManager?.removeAllActions()
                    refreshUndoState()
                }
            }
            // Other undo managers, such as a search field's, post these too, but only a change of
            // this one's brings the Undo button out.
            .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidCloseUndoGroup)) { note in
                refreshUndoState(showsButton: note.object as? UndoManager === undoManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { note in
                refreshUndoState(showsButton: note.object as? UndoManager === undoManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { note in
                refreshUndoState(showsButton: note.object as? UndoManager === undoManager)
            }
            // The button tucks away a while after the last change, rather than sitting alone in the bar.
            .task(id: undoState.changes) {
                guard undoState.isButtonShown else { return }
                try? await Task.sleep(for: .seconds(UIAccessibility.isVoiceOverRunning ? 20 : 8))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth) { undoState.isButtonShown = false }
            }
            .onReceive(NotificationCenter.default.publisher(for: .placesDidReset)) { _ in
                undoManager?.removeAllActions()
                ToastCenter.shared.dismiss()
                refreshUndoState()
            }
            // With everything as it was on the first launch, the World is open again, with no way back
            // to lists that may have gone, such as the person's own groups.
            .onReceive(NotificationCenter.default.publisher(for: .everythingDidReset)) { _ in
                trail = []
                arrival = nil
                revealedPlace = nil
                preferredColumn = .detail
                selectedCountryID = CountryCatalog.world.id
            }
            .alert("Couldn’t save status", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
    }

    /// Shows the welcome, touring the person's own most-marked list first where they have one. Shown
    /// again from Settings, it remembers the list it was opened from, to return to.
    private func showWelcome(isReplay: Bool) {
        welcomeIsReplay = isReplay
        listBeforeWelcome = isReplay && selectedCountryID != CountryCatalog.world.id ? selectedCountryID : nil
        trailBeforeWelcome = listBeforeWelcome == nil ? [] : trail
        welcomeLeg = personalWelcomeLeg()
        // On a first launch it's there at once, over the dark already showing; replayed from
        // Settings, space fades in over the list it was asked for from.
        withAnimation(isReplay ? .smooth(duration: 0.6) : nil) { showingWelcome = true }
    }

    /// The welcome has landed on the World. On a first launch, the countries lit in it are kept;
    /// shown again, it flies on from the World into the list it was opened from.
    private func finishWelcome(keeping lit: [String: VisitLevel]) {
        hasSeenWelcome = true
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { showingWelcome = false }
        if !welcomeIsReplay {
            keepWelcomeMarks(lit)
        } else if let id = listBeforeWelcome {
            listBeforeWelcome = nil
            open(id, fliesMap: true)
            // Back where it was, the way back leads where it did, less any list gone meanwhile.
            trail = trailBeforeWelcome.filter { id in countries.contains { $0.id == id } }
            trailBeforeWelcome = []
        }
    }

    /// Countries lit up in the welcome on a first launch, each raised to the level it was given and
    /// never lowered, as one step that undo puts back, with a toast saying so.
    private func keepWelcomeMarks(_ lit: [String: VisitLevel]) {
        guard !lit.isEmpty, let model = saveModels.first else { return }
        let snapshot = model.snapshot()
        let ladder = snapshot.ladder
        let targets = CountryCatalog.world(applying: counting.rules).divisions.compactMap {
            place -> (place: AdministrativeDivision, level: VisitLevel)? in
            guard let level = lit[place.id], ladder.rank(of: level) > ladder.rank(of: snapshot.status(for: place)) else {
                return nil
            }
            return (place, level)
        }
        guard let highest = targets.max(by: { ladder.rank(of: $0.level) < ladder.rank(of: $1.level) }) else { return }
        let name = targets.count == 1 ? highest.place.name : "\(targets.count) countries"
        guard setLevels(targets, model: model, context: modelContext, undoManager: undoManager, actionName: name) else {
            return
        }
        let undoManager = undoManager
        ToastCenter.shared.show(LevelToast(
            placeName: name, flagAssetName: highest.place.flagAssetName, level: highest.level, ladder: model.ladder,
            onUndo: undoManager.map { manager in { manager.undo() } }))
    }

    /// The person's own list with the most places marked, for the welcome to tour first, its places
    /// climbing to their own levels: one with a map of its places and a capital to turn the globe to.
    private func personalWelcomeLeg() -> WelcomeLeg? {
        guard let snapshot = saveModels.first?.snapshot() else { return nil }
        let ranked = CountryCatalog.countries(applying: counting.rules)
            .filter { $0.id != CountryCatalog.world.id && $0.worldGroup == nil }
            .map { list in (list: list, marked: list.divisions.filter { snapshot.status(for: $0) != .never }) }
            .filter { !$0.marked.isEmpty }
            .sorted { $0.marked.count > $1.marked.count }
        for (list, marked) in ranked.prefix(5) {
            guard Geography.subdivisions(of: list.id) != nil,
                  let country = CountryCatalog.world.divisions.first(where: { $0.abbreviation == list.countryListID }),
                  let longitude = CapitalCities.capitals(of: country).first?.location.map({ Double($0.x) })
            else { continue }
            return WelcomeLeg(
                collectionID: list.id, worldPlaceID: country.id, longitude: longitude,
                places: marked.prefix(60).map { WelcomeLeg.Place(id: $0.id, levelID: snapshot.status(for: $0).id) })
        }
        return nil
    }

    /// Opens the World's list beneath the welcome as it leaves, at its top, so the World unrolling
    /// in space can land on its map.
    private func landOnWorld() {
        trail = []
        arrival = nil
        preferredColumn = .detail
        selectedCountryID = CountryCatalog.world.id
    }

    private func prepareStore() {
        guard saveModels.isEmpty else { return }
        do {
            // Fetch directly as well: the query may not yet have delivered its first update.
            guard try modelContext.fetchCount(FetchDescriptor<SaveModel>()) == 0 else { return }
            let model = SaveModel()
            modelContext.insert(model)
            do { try modelContext.save() }
            catch { modelContext.delete(model); throw error }
        } catch { saveError = error.localizedDescription }
    }

    private func collectionView(for collection: Country, saveModel: SaveModel) -> some View {
        CountryCollectionView(
            country: collection,
            saveModel: saveModel,
            localLanguage: $localLanguage,
            arrival: arrival,
            onStatusChange: { status, division, collection in update(status, for: division, in: collection, model: saveModel) },
            onOpenCollection: { id, fliesMap in open(id, fliesMap: fliesMap) },
            onSwitchLevel: { switchLevel(to: $0) },
            onOpenLevel: { open($0, fliesMap: true, isLevelChosen: true) },
            onShowInLevel: { switchLevel(to: $0, revealing: $1, divingInto: $2) },
            revealedPlace: revealedPlace,
            onOpenPlace: { placeID, collectionID in openPlace(placeID, in: collectionID, keepsWayBack: true) },
            mapLocation: listMap,
            learnRequest: learnRequest
        )
        .environment(\.regionCelebration, regionCelebration)
        // In a country, the way back leads to the World, or to the list it was opened from, rather
        // than to the sidebar: by the button or a swipe in from the leading edge.
        .navigationBarBackButtonHidden(previousCollection != nil)
        .modifier(BackSwipe(
            containerWidth: containerWidth, isEnabled: previousCollection != nil && detailStartsAtScreenEdge,
            onBack: goBack))
        // VoiceOver's scrub follows the same way back, and from the World, as the system's own Back
        // would, out to the places in the sidebar.
        // ⌘[ goes back a list, the back button being a menu, which takes no shortcut of its own.
        .background {
            Button("Back", action: goBack)
                .keyboardShortcut("[", modifiers: .command)
                .disabled(previousCollection == nil)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        }
        .accessibilityAction(.escape) {
            if previousCollection != nil { goBack() } else { preferredColumn = .sidebar }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .onGeometryChange(for: DetailEdge.self) { proxy in
            DetailEdge(minX: proxy.frame(in: .global).minX, inset: proxy.safeAreaInsets.leading)
        } action: { detailEdge = $0 }
        .toolbar {
            if let previous = previousCollection {
                // The way back, so it heads iPhone Duo's side bar as the system's own Back would.
                // A tap goes back one list; touch and hold for any list further back, or the places.
                ToolbarItem(placement: .cancellationAction) {
                    Menu {
                        ForEach(wayBack) { list in
                            Button(list.listTitle) { goBack(to: list.id) }
                        }
                        // On iPhone the places are otherwise only reached from the World.
                        if horizontalSizeClass == .compact {
                            Divider()
                            Button("Places", systemImage: "sidebar.leading") { preferredColumn = .sidebar }
                        }
                    } label: {
                        Label(previous.listTitle, systemImage: "chevron.backward")
                    } primaryAction: {
                        goBack()
                    }
                    .accessibilityLabel("Back to \(previous.listTitle)")
                }
            }
            if TravelMap.named(collection.id) != nil {
                ToolbarItem(placement: .primaryAction) {
                    // The one thing to play here, so it stands out from Settings beside it.
                    if #available(iOS 26.0, *) {
                        Button("Quiz", systemImage: "gamecontroller") { openGame(collection) }
                            .buttonStyle(.glassProminent)
                    } else {
                        Button("Quiz", systemImage: "gamecontroller") { openGame(collection) }
                    }
                }
                .overflowsLast()
            }
            // A group of the person's own is changed, copied or deleted from its list's overflow menu.
            if let group = customGroups.group(collectionID: collection.id) {
                ToolbarItemGroup(placement: .secondaryAction) {
                    Button("Edit group", systemImage: "pencil") { editGroup(.edit(group.id)) }
                    Button("Duplicate", systemImage: "plus.square.on.square") { editGroup(.copy(of: collection.id)) }
                    Button("Delete group", systemImage: "trash", role: .destructive) { groupPendingDeletion = group }
                }
            }
            // Down at the foot, well apart from the way back at the top, so the two arrows are
            // never taken for one another, and only for a while after a change, while a wrong tap
            // is still fresh. At the foot of iPhone Duo's side bar it would be the first to go into
            // the overflow menu, but it's how a wrong tap is put right, so it stays.
            if undoState.isButtonShown {
                // On iPhone the list's search field sits in this bar too, and would be pushed out of
                // it by the button, so it's named here to keep its place, with the button beside it.
                if #available(iOS 26.0, *) {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                }
                ToolbarItem(placement: .bottomBar) {
                    undoButton
                }
                .overflowsLast()
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            // Lists are chosen from the sidebar, so only Settings sits here.
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape") { showingSettings = true }
            }
            .overflowsFirst()
        }
    }

    /// The list to go back to: the one this was opened from; for a list of one place's own
    /// subdivisions found directly, such as Tasmania's, the country's list that place is in; or for
    /// a country chosen directly, the World it's part of.
    private var previousCollection: Country? {
        if let id = trail.last(where: { $0 != selectedCountryID }) {
            return countries.first { $0.id == id }
        }
        guard selectedCountryID != CountryCatalog.world.id else { return nil }
        if let parent = country.parentPlace, let list = countries.first(where: { list in
            list.id != CountryCatalog.world.id && list.divisions.contains { $0.id == parent.id }
        }) {
            return list
        }
        return countries.first { $0.id == CountryCatalog.world.id }
    }

    /// The list chosen from the sidebar, which starts afresh from there, its map
    /// flying over from the one shown before. A country listed at more than one level has one row,
    /// its first level's, which stays chosen at every level and opens at the one last shown. The
    /// country's row stays chosen too while one of its places' own lists is open, such as
    /// Australia's for Tasmania's.
    private var rootSelection: Binding<String> {
        Binding(
            get: { country.countryListID },
            set: { id in
                preferredColumn = .detail
                guard id != selectedCountryID, id != country.firstLevelID else { return }
                trail = []
                let shown = shownLevel(of: id)
                arrival = CollectionArrival(fromID: selectedCountryID, toID: shown)
                selectedCountryID = shown
            })
    }

    /// Shows another list where this one was, such as Japan's prefectures opened from the World,
    /// and keeps the way back. Its map flies in from this one's, unless the map has already flown
    /// there full screen. A country listed at more than one level opens at the one last shown,
    /// unless the level is chosen, as from a place's picker, or the full-screen map has flown into
    /// the very list it shows.
    private func open(_ id: String, fliesMap: Bool, isLevelChosen: Bool = false) {
        let id = fliesMap && !isLevelChosen ? shownLevel(of: id) : id
        guard id != selectedCountryID, countries.contains(where: { $0.id == id }) else { return }
        preferredColumn = .detail
        trail.append(selectedCountryID)
        arrival = CollectionArrival(fromID: fliesMap ? selectedCountryID : nil, toID: id)
        selectedCountryID = id
    }

    /// Shows the same country at another level in place of this one, such as France's departments
    /// instead of its regions, or another place's subdivisions, keeping the way back as it was.
    /// Up from a place's own subdivisions to its country's list, the map flies back out to the
    /// place, as going back does, and the way back no longer leads to where it already is.
    /// `revealing` brings a place or section of the new level into view, such as a region's
    /// departments, and the map dives into the place `divingInto` on the way, such as the region.
    private func switchLevel(to id: String, revealing revealedID: String? = nil, divingInto placeID: String? = nil) {
        guard id != selectedCountryID, countries.contains(where: { $0.id == id }) else { return }
        // The way back no longer leads to where it already is, as when a country's list was opened
        // at one level and is switched back to the one it was opened from.
        if trail.last == id { trail.removeLast() }
        if let parent = country.parentPlace, id == country.countryListID {
            arrival = CollectionArrival(fromID: selectedCountryID, toID: id, revealedPlaceID: parent.id, kind: .back)
        } else if country.parentPlace != nil, countries.first(where: { $0.id == id })?.parentPlace != nil {
            // Across to another place's subdivisions, such as the Northern Territory's from
            // Tasmania's, the map flies over the country from one to the other.
            arrival = CollectionArrival(fromID: selectedCountryID, toID: id, revealedPlaceID: revealedID, kind: .level)
        } else {
            arrival = CollectionArrival(
                fromID: placeID == nil ? nil : selectedCountryID, toID: id, revealedPlaceID: revealedID, fromPlaceID: placeID,
                kind: .level)
        }
        selectedCountryID = id
    }

    /// The list to open for a list's ID: for a country listed at more than one level, the level it
    /// was last shown at; otherwise the list itself.
    private func shownLevel(of id: String) -> String {
        guard let collection = countries.first(where: { $0.id == id }) else { return id }
        let shown = Set(shownLevels.split(separator: "\n").map(String.init))
        return CountryCatalog.levels(of: collection).first { shown.contains($0.id) }?.id ?? id
    }

    /// Notes the level a country listed at more than one level is shown at, for it to open there again.
    private func rememberLevel(of collection: Country) {
        let levels = Set(CountryCatalog.levels(of: collection).map(\.id))
        guard levels.count > 1 else { return }
        let others = shownLevels.split(separator: "\n").map(String.init).filter { !levels.contains($0) }
        shownLevels = (others + [collection.id]).joined(separator: "\n")
    }

    /// Opens the list a place found by search is in, with the place brought into view and lit for a
    /// moment. Found from a list, the way back leads to that list; from the sidebar, it starts afresh.
    private func openPlace(_ placeID: String, in collectionID: String, keepsWayBack: Bool) {
        preferredColumn = .detail
        guard collectionID != selectedCountryID else {
            revealedPlace = RevealedPlace(id: placeID)
            return
        }
        guard countries.contains(where: { $0.id == collectionID }) else { return }
        if keepsWayBack { trail.append(selectedCountryID) } else { trail = [] }
        arrival = CollectionArrival(fromID: selectedCountryID, toID: collectionID, revealedPlaceID: placeID)
        selectedCountryID = collectionID
    }

    /// Back to the list this one was opened from, or from a country to the World, its map flying
    /// back out, with the place just left brought into view.
    private func goBack() {
        // A way back to the list already open is no way back.
        while trail.last == selectedCountryID { trail.removeLast() }
        guard let previous = previousCollection else { return }
        if !trail.isEmpty { trail.removeLast() }
        let left = selectedCountryID
        // From any of a country's levels, such as France's departments, back to the country's row.
        let leftCountry = country.firstLevelID ?? left
        let row = previous.divisions.first { CountryCatalog.collection(for: $0)?.id == leftCountry }
        arrival = CollectionArrival(fromID: left, toID: previous.id, revealedPlaceID: row?.id, kind: .back)
        selectedCountryID = previous.id
    }

    /// Every list along the way back, nearest first and each once, ending at the World, for the
    /// back button's menu.
    private var wayBack: [Country] {
        var seen: Set<String> = [selectedCountryID]
        var ids = trail.reversed().filter { seen.insert($0).inserted }
        if ids.isEmpty, let previous = previousCollection, seen.insert(previous.id).inserted { ids.append(previous.id) }
        if seen.insert(CountryCatalog.world.id).inserted { ids.append(CountryCatalog.world.id) }
        return ids.compactMap { id in countries.first { $0.id == id } }
    }

    /// Straight back to a list further along the way back, its map flying back out to the place
    /// the way led on through, and the way back from there as it was.
    private func goBack(to id: String) {
        guard id != selectedCountryID, let destination = countries.first(where: { $0.id == id }) else { return }
        let index = trail.lastIndex(of: id)
        // The list the way led on to from there: the next along it, or this one.
        let next = index.flatMap { $0 + 1 < trail.count ? trail[$0 + 1] : nil } ?? selectedCountryID
        let nextCountry = countries.first { $0.id == next }?.firstLevelID ?? next
        let row = destination.divisions.first { CountryCatalog.collection(for: $0)?.id == nextCountry }
        if let index { trail.removeSubrange(index...) } else { trail = [] }
        arrival = CollectionArrival(fromID: selectedCountryID, toID: id, revealedPlaceID: row?.id, kind: .back)
        selectedCountryID = id
    }

    /// Opens the editor for a group of countries of the person's own: a new one, one of theirs, or a copy.
    private func editGroup(_ target: GroupEditorTarget) {
        groupDraft = customGroups.draft(for: target)
    }

    /// Saves a group from its editor. A new one opens straight away in its own list.
    private func saveGroup(_ group: CustomWorldGroup) {
        let isNew = customGroups.group(id: group.id) == nil
        customGroups.save(group)
        if isNew { rootSelection.wrappedValue = group.collectionID }
    }

    /// Deletes one of the person's groups. Where its list is open, the World takes its place, and
    /// the way back no longer leads to it.
    private func deleteGroup(_ group: CustomWorldGroup) {
        trail.removeAll { $0 == group.collectionID }
        if selectedCountryID == group.collectionID {
            trail = []
            arrival = nil
            selectedCountryID = CountryCatalog.world.id
        }
        customGroups.delete(group.id)
    }

    /// The quiz pops a collection's map up as a board to quiz yourself on, running its own animation.
    private func openGame(_ collection: Country) {
        guard let quiz = MapGame.make(for: collection, rules: counting.rules) else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { game = quiz }
    }

    /// Learn from the quiz lobby: the quiz goes, the list of its places takes the place of the one
    /// showing, keeping the way back to it, and the list's full map opens in Learn. Where there's
    /// no such list, the quiz stays open rather than closing onto nothing.
    @discardableResult
    private func learn(_ request: LearnDeck.Request) -> Bool {
        guard countries.contains(where: { $0.id == request.collectionID }) else { return false }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { game = nil }
        if request.collectionID != selectedCountryID {
            open(request.collectionID, fliesMap: false)
        }
        // The list comes forward even when it's the one already open, such as from the sidebar on
        // iPhone, for it to take the request up.
        preferredColumn = .detail
        learnRequest = request
        // Only a nudge: once the list has taken it up, it's let go, so it isn't taken up again.
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if learnRequest == request { learnRequest = nil }
        }
        return true
    }

    /// Open in Atlas from the sidebar: the list opens as choosing its row would, afresh and at the
    /// level last shown, or stays at the level it's at when it's the one open, with its full map in
    /// the Atlas.
    private func openAtlas(fromSidebar id: String) {
        rootSelection.wrappedValue = id
        _ = learn(LearnDeck.Request(collectionID: selectedCountryID))
    }

    /// Shown for a while after each change. Tap to undo; touch and hold to redo.
    private var undoButton: some View {
        Menu {
            if let name = undoState.redoName {
                Button(name.isEmpty ? "Redo" : "Redo \(name)", systemImage: "arrow.uturn.forward") {
                    undoManager?.redo()
                }
            }
        } label: {
            Label(undoState.undoName.map { $0.isEmpty ? "Undo" : "Undo \($0)" } ?? "Undo", systemImage: "arrow.uturn.backward")
                .symbolEffect(.bounce, value: reduceMotion ? 0 : undoState.registrations)
        } primaryAction: {
            undoManager?.undo()
        }
        // No label style of its own: the bar shows the symbol, and an overflow menu, such as on
        // iPhone Duo's side bar, the title with it.
        .disabled(undoState.undoName == nil && undoState.redoName == nil)
    }

    /// Sets a place's level. The places it lies within, its region and the countries it belongs to,
    /// rise to at least that level, with a toast saying so, and one undo puts every one of them back.
    private func update(
        _ status: VisitLevel, for division: AdministrativeDivision, in collection: Country, model: SaveModel
    ) {
        let before = model.snapshot()
        let previous = before.status(for: division)
        guard previous.id != status.id else { return }
        let raised = before.placesRaised(by: status, at: division, rules: counting.rules)
        let targets = ([division] + raised.map(\.place)).map { (place: $0, level: status) }
        let name = "\(division.name) → \(status.name)"
        guard setLevels(
            targets, model: model, context: modelContext, undoManager: undoManager, actionName: name,
            raised: Set(raised.map(\.place.id)))
        else { return }
        let after = model.snapshot()
        let milestone = self.milestone(changing: division, in: collection, before: before, after: after)
        haptic = StatusHaptic(feedback: feedback(from: previous, to: status, ladder: after.ladder, isMilestone: milestone != nil))
        switch milestone {
        case .list(let level):
            // Every place in the list has reached a level: "Japan VISITED", with confetti.
            ToastCenter.shared.show(LevelToast(
                placeName: collection.name, flagAssetName: collection.flagAssetName, level: level,
                kind: .completed, ladder: after.ladder))
            return
        case .region(let id):
            // The place lifts off the list's map first, and the region celebrates as it lands, so
            // the climax comes once rather than the confetti before it. With Reduce Motion nothing
            // lifts, so it celebrates at once.
            let celebration = RegionCelebration(regionID: id)
            if reduceMotion {
                regionCelebration = celebration
            } else {
                heldCelebration = celebration
            }
        case nil:
            break
        }
        if let country = raised.last?.place {
            let undoManager = undoManager
            ToastCenter.shared.show(LevelToast(
                placeName: country.name, flagAssetName: country.flagAssetName, level: status,
                ladder: after.ladder, onUndo: undoManager.map { manager in { manager.undo() } }))
        }
    }

    /// A list or region a change has just finished. A list is finished once every place in it
    /// counts, and again each time its lowest level rises, so it can say "Japan VISITED"; a region
    /// the first time every place in it counts.
    private func milestone(
        changing division: AdministrativeDivision, in collection: Country, before: TravelSnapshot, after: TravelSnapshot
    ) -> Milestone? {
        let rules = counting.rules
        func lowestRank(of places: [AdministrativeDivision], in snapshot: TravelSnapshot) -> Int {
            places.map { snapshot.ladder.rank(of: snapshot.status(for: $0)) }.min() ?? 0
        }
        func isFinished(_ places: [AdministrativeDivision], in snapshot: TravelSnapshot) -> Bool {
            !places.isEmpty && snapshot.count(in: places, counting: rules) == places.count
        }
        let places = collection.divisions
        if isFinished(places, in: after),
           !isFinished(places, in: before) || lowestRank(of: places, in: after) > lowestRank(of: places, in: before) {
            let ladder = after.ladder
            let rank = lowestRank(of: places, in: after)
            return ladder.allLevels.indices.contains(rank) ? .list(level: ladder.allLevels[rank]) : nil
        }
        if let region = collection.groups.first(where: { $0.id == division.groupID }),
           isFinished(region.divisions, in: after), !isFinished(region.divisions, in: before) {
            return .region(id: region.id)
        }
        return nil
    }

    /// Sets several places' levels as one step, and registers the step that puts them back, so
    /// undo and redo can each reverse the other. Restores everything if the save fails.
    @discardableResult
    /// `raised` are the places, such as countries, that rose by themselves with the one set by hand.
    private func setLevels(
        _ targets: [(place: AdministrativeDivision, level: VisitLevel)], model: SaveModel,
        context: ModelContext, undoManager: UndoManager?, actionName: String, raised: Set<String> = []
    ) -> Bool {
        let before = model.snapshot()
        let inverse = targets.map { (place: $0.place, level: before.status(for: $0.place)) }
        let previousData = model.statusesData
        let previousJapan = model.visitStatus
        let previousLog = model.changeLogData
        do {
            for target in targets { try model.setStatus(target.level, for: target.place) }
            // Undo and redo are changes too, so each is logged with its own date and the level it left.
            model.logChanges(targets, from: before, raised: raised)
            try context.save()
        } catch {
            model.statusesData = previousData
            model.visitStatus = previousJapan
            model.changeLogData = previousLog
            saveError = error.localizedDescription
            return false
        }
        undoManager?.registerUndo(withTarget: model) { model in
            guard setLevels(
                inverse, model: model, context: context, undoManager: undoManager, actionName: actionName, raised: raised)
            else { return }
            haptic = StatusHaptic(feedback: .impact(flexibility: .soft, intensity: 0.6))
            // Shows what was put back: "Benin VISITED → NEVER BEEN", the old pill struck through.
            if let place = inverse.first?.place, let undone = targets.first?.level, let restored = inverse.first?.level {
                ToastCenter.shared.show(LevelToast(
                    placeName: place.displayName(localLanguage: localLanguage), flagAssetName: place.flagAssetName,
                    level: restored, kind: .changed(from: undone), ladder: model.ladder))
            }
        }
        undoManager?.setActionName(actionName)
        return true
    }

    /// Catches the button up with the undo manager, bringing it out after a change of its own.
    private func refreshUndoState(showsButton: Bool = false) {
        var state = undoState
        state.undoName = undoManager?.canUndo == true ? undoManager?.undoActionName : nil
        state.redoName = undoManager?.canRedo == true ? undoManager?.redoActionName : nil
        if state.undoName != nil, state.undoName != undoState.undoName { state.registrations += 1 }
        let hasSteps = state.undoName != nil || state.redoName != nil
        if showsButton, hasSteps {
            state.isButtonShown = true
            state.changes += 1
        } else if !hasSteps {
            state.isButtonShown = false
        }
        withAnimation(.smooth) { undoState = state }
    }

    /// Saved records from before countries followed their places catch up once, quietly.
    /// Carries levels over to places that replaced others, such as Jeonnam-Gwangju, once each.
    private func applyPlaceReorganisations() {
        guard let model = saveModels.first else { return }
        let previousData = model.statusesData
        do {
            let applied = try model.applyPlaceReorganisations()
            guard !applied.isEmpty else { return }
            try modelContext.save()
            let key = SaveModel.appliedReorganisationsKey
            UserDefaults.standard.set((UserDefaults.standard.stringArray(forKey: key) ?? []) + applied, forKey: key)
        } catch {
            model.statusesData = previousData
        }
    }

    private func raiseCountriesToTheirPlacesOnce() {
        let key = "raisedCountriesToTheirPlaces"
        guard !UserDefaults.standard.bool(forKey: key), let model = saveModels.first else { return }
        let raises = model.snapshot().countriesBelowTheirPlaces(rules: counting.rules)
        let previousData = model.statusesData
        let previousJapan = model.visitStatus
        do {
            for (country, level) in raises { try model.setStatus(level, for: country) }
            if !raises.isEmpty { try modelContext.save() }
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            model.statusesData = previousData
            model.visitStatus = previousJapan
        }
    }

    /// Regions catch up once with what's already marked within them, such as France's regions with
    /// their departments, so no visit has to be marked twice. Each region is checked once, a region
    /// added later when it first appears, and from then on rises as its places do.
    private func raiseRegionsToTheirPlacesOnce() {
        let key = "regionsRaisedToTheirPlaces"
        guard let model = saveModels.first else { return }
        let checked = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        let due = CountryCatalog.regionIDs.subtracting(checked)
        guard !due.isEmpty else { return }
        let raises = model.snapshot().regionsBelowTheirPlaces(among: due)
        let previousData = model.statusesData
        let previousJapan = model.visitStatus
        do {
            for (region, level) in raises { try model.setStatus(level, for: region) }
            if !raises.isEmpty { try modelContext.save() }
            UserDefaults.standard.set(checked.union(due).sorted(), forKey: key)
        } catch {
            model.statusesData = previousData
            model.visitStatus = previousJapan
        }
    }

    /// Each step up taps a little harder the higher the level, the top level hardest; steps down
    /// are soft. Finishing a region or a list is a success.
    private func feedback(
        from previous: VisitLevel, to status: VisitLevel, ladder: VisitLadder, isMilestone: Bool
    ) -> SensoryFeedback {
        if isMilestone { return .success }
        let rank = ladder.rank(of: status)
        guard rank > ladder.rank(of: previous) else {
            return .impact(flexibility: .soft, intensity: rank == 0 ? 0.35 : 0.55)
        }
        let height = Double(rank) / Double(max(ladder.levels.count, 1))
        return .impact(weight: rank == ladder.levels.count ? .heavy : .medium, intensity: 0.35 + 0.65 * height)
    }
}

/// What undo and redo would do next, for the toolbar button.
private struct UndoState: Equatable {
    var undoName: String?
    var redoName: String?
    /// Counts new undoable steps, so the button can bounce as each one arrives.
    var registrations = 0
    /// Whether the button is out, as it is for a while after each change.
    var isButtonShown = false
    /// Counts changes, undos and redos, each starting the button's time out afresh.
    var changes = 0
}

/// A swipe in from the list's leading edge to go back, which the list follows as the finger moves:
/// it gives way a little towards the trailing side and dims, so the swipe is seen to take hold
/// before it's let go. Let go far enough across, the way back is taken; short of that, the list
/// springs back into place. With Reduce Motion the list only dims, holding still. A modifier of
/// its own, so only it is redrawn as the finger moves, not the list.
private struct BackSwipe: ViewModifier {
    /// The list's width, for telling a swipe in from its trailing edge in right-to-left languages.
    var containerWidth: CGFloat
    var isEnabled: Bool
    var onBack: () -> Void
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How far across the finger has come from the edge, while it's down.
    @GestureState(resetTransaction: Transaction(animation: .snappy)) private var pull: CGFloat = 0

    /// How far in from the edge a swipe must start.
    private static let edgeWidth: CGFloat = 24
    /// How far across a swipe must go to take the way back.
    private static let reach: CGFloat = 70

    func body(content: Content) -> some View {
        let direction: CGFloat = layoutDirection == .leftToRight ? 1 : -1
        content
            .offset(x: reduceMotion ? 0 : min(pull * 0.3, 48) * direction)
            .opacity(1 - min(pull, 160) / 640)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .updating($pull) { value, pull, _ in
                        guard let across = across(value) else { return }
                        pull = max(across, 0)
                    }
                    .onEnded { value in
                        guard let across = across(value), across > Self.reach,
                              abs(value.translation.height) < across * 0.6
                        else { return }
                        onBack()
                    },
                isEnabled: isEnabled)
    }

    /// How far a drag has come across from the list's leading edge, or nil when it didn't start there.
    private func across(_ value: DragGesture.Value) -> CGFloat? {
        let isLeftToRight = layoutDirection == .leftToRight
        let fromEdge = isLeftToRight
            ? value.startLocation.x < Self.edgeWidth : value.startLocation.x > containerWidth - Self.edgeWidth
        guard fromEdge else { return nil }
        return isLeftToRight ? value.translation.width : -value.translation.width
    }
}

/// Holds a finished region's celebration until the place that finished it lands back on its map,
/// as `ToastCenter`'s landing says, so the region's confetti bursts at the climax of the lift
/// rather than before it. A place that doesn't lift, as when the list's map is scrolled out of
/// sight or hidden, lets it go as soon as it's plain nothing has taken off: a place large on the
/// map lifts at once, and a small one once the camera has flown in close to it. Whatever happens,
/// it goes after `longestWait`. Apart from the rest, so only it is redrawn as places land.
private struct CelebrationRelay: View {
    @Binding var held: RegionCelebration?
    @Binding var released: RegionCelebration?

    /// When a place large on the map would have lifted off, and then a small one.
    private static let liftChecks = [0.1, 0.55]
    /// The longest a celebration waits for its landing: long enough for a small place's lift, which
    /// waits for the camera to fly in close before it leaves.
    private static let longestWait = 1.3

    var body: some View {
        Color.clear
            .onChange(of: ToastCenter.shared.landing) { release() }
            .task(id: held?.token) {
                guard let celebration = held else { return }
                var waited = 0.0
                for check in Self.liftChecks {
                    try? await Task.sleep(for: .seconds(check - waited))
                    waited = check
                    guard !Task.isCancelled else { return }
                    if let lifted = ToastCenter.shared.lastLiftDate, lifted >= celebration.date { break }
                    if check == Self.liftChecks.last {
                        release()
                        return
                    }
                }
                try? await Task.sleep(for: .seconds(Self.longestWait - waited))
                guard !Task.isCancelled else { return }
                release()
            }
            .accessibilityHidden(true)
    }

    private func release() {
        guard let held else { return }
        self.held = nil
        released = held
    }
}

/// Something a change of level finished: a whole list, at the level every place in it has
/// reached, or a region.
private enum Milestone {
    case list(level: VisitLevel)
    case region(id: String)
}

private struct StatusHaptic: Equatable {
    var id = UUID()
    var feedback: SensoryFeedback
}

/// Where the list starts on screen and how far its leading safe area reaches, for telling
/// whether a swipe in from its edge starts at the screen's edge.
private struct DetailEdge: Equatable {
    var minX: CGFloat = 0
    var inset: CGFloat = 0
}

/// The catalog's lists and sidebar sections under the rules last asked about, so a body that asks
/// for them several times builds them once. The catalog itself never changes while the app runs.
private final class CatalogCache {
    private var rules: CountingRules?
    private var countries: [Country] = []
    private var sections: [CollectionSection] = []

    func countries(applying rules: CountingRules) -> [Country] {
        refresh(for: rules)
        return countries
    }

    func sections(applying rules: CountingRules) -> [CollectionSection] {
        refresh(for: rules)
        return sections
    }

    private func refresh(for rules: CountingRules) {
        guard rules != self.rules else { return }
        self.rules = rules
        countries = CountryCatalog.countries(applying: rules)
        sections = CountryCatalog.sections(applying: rules)
    }
}
