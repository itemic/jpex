import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(CountingPreferences.self) private var counting
    @Query private var saveModels: [SaveModel]
    @AppStorage("selectedCountry") private var selectedCountryID = "JP"
    @AppStorage("localLanguage") private var localLanguage = false
    @State private var preferredColumn: NavigationSplitViewColumn = .detail
    @State private var saveError: String?
    @State private var undoState = UndoState()
    @State private var haptic: StatusHaptic?
    /// The region the person just finished, so its header can celebrate.
    @State private var regionCelebration: RegionCelebration?
    @State private var showingSettings = false
    /// The lists opened from one another on the way to this one, such as the World before Japan,
    /// newest last, for going back.
    @State private var trail: [String] = []
    /// How the list now shown was arrived at, so its map can fly over from the one before.
    @State private var arrival: CollectionArrival?
    /// The list's width, for telling a swipe in from its trailing edge in right-to-left languages.
    @State private var containerWidth: CGFloat = 0
    @State private var game: MapGame?
    /// The width of the page before the fold while iPhone Duo is held partly folded like a book.
    @State private var leadingPageWidth: CGFloat?
    /// Where the list starts on screen, and how far a side bar of controls insets it there.
    @State private var detailEdge = DetailEdge()

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

    /// Every list that can be chosen: each country's, and each group of countries', such as the EU.
    private var countries: [Country] {
        CountryCatalog.countries(applying: counting.rules) + WorldGroup.collections
    }

    /// The sidebar's sections, with groups of countries just after the World.
    private var sidebarSections: [CollectionSection] {
        var sections = CountryCatalog.sections(applying: counting.rules)
        sections.insert(CollectionSection(title: CollectionSection.worldGroupsTitle, countries: WorldGroup.collections), at: min(1, sections.count))
        return sections
    }

    private var country: Country {
        countries.first { $0.id == selectedCountryID } ?? CountryCatalog.japan
    }

    var body: some View {
        let ladder = saveModels.first?.ladder ?? .standard
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            CountrySidebarView(
                sections: sidebarSections,
                selectedCountryID: rootSelection,
                saveModel: saveModels.first,
                rules: counting.rules
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
                } else {
                    ProgressView()
                }
            }
        }
        .onGeometryChange(for: CGFloat?.self, of: Self.leadingPageWidth(in:)) { leadingPageWidth = $0 }
        .tint(.primary)
        .sensoryFeedback(trigger: haptic) { _, event in event?.feedback }
        .sheet(isPresented: $showingSettings) { SettingsView(saveModel: saveModels.first) }
        .fullScreenCover(item: $game) { game in
            GameScreen(game: game) {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { self.game = nil }
            }
            .presentationBackground(.clear)
        }
        .task {
            prepareStore()
            raiseCountriesToTheirPlacesOnce()
            applyPlaceReorganisations()
        }
        .onChange(of: saveModels.count) {
            raiseCountriesToTheirPlacesOnce()
            applyPlaceReorganisations()
        }
        .onChange(of: selectedCountryID) {
            preferredColumn = .detail
        }
        .onChange(of: ladder) { old, new in
            // Undo can't bring back a level that has been deleted.
            if old.levels.contains(where: { new.level(id: $0.id) == nil }) {
                undoManager?.removeAllActions()
                refreshUndoState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidCloseUndoGroup)) { _ in refreshUndoState() }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidUndoChange)) { _ in refreshUndoState() }
        .onReceive(NotificationCenter.default.publisher(for: .NSUndoManagerDidRedoChange)) { _ in refreshUndoState() }
        .onReceive(NotificationCenter.default.publisher(for: .placesDidReset)) { _ in
            undoManager?.removeAllActions()
            ToastCenter.shared.dismiss()
            refreshUndoState()
        }
        .alert("Couldn’t save status", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
        .environment(\.visitLadder, ladder)
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
            onOpenCollection: { id, fliesMap in open(id, fliesMap: fliesMap) }
        )
        .environment(\.regionCelebration, regionCelebration)
        // In a country, the way back leads to the World, or to the list it was opened from, rather
        // than to the sidebar: by the button or a swipe in from the leading edge.
        .navigationBarBackButtonHidden(previousCollection != nil)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let isLeftToRight = layoutDirection == .leftToRight
                    let fromEdge = isLeftToRight ? value.startLocation.x < 24 : value.startLocation.x > containerWidth - 24
                    let across = isLeftToRight ? value.translation.width : -value.translation.width
                    guard fromEdge, across > 70, abs(value.translation.height) < across * 0.6 else { return }
                    goBack()
                },
            isEnabled: previousCollection != nil && detailStartsAtScreenEdge)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
        .onGeometryChange(for: DetailEdge.self) { proxy in
            DetailEdge(minX: proxy.frame(in: .global).minX, inset: proxy.safeAreaInsets.leading)
        } action: { detailEdge = $0 }
        .toolbar {
            if let previous = previousCollection {
                ToolbarItem(placement: .topBarLeading) {
                    Button(previous.listTitle, systemImage: "chevron.backward", action: goBack)
                        .keyboardShortcut("[", modifiers: .command)
                        .accessibilityLabel("Back to \(previous.listTitle)")
                }
            }
            if TravelMap.named(collection.id) != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Quiz", systemImage: "gamecontroller") { openGame(collection) }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                undoButton
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            // Lists are chosen from the sidebar, so only Settings sits here.
            ToolbarItem(placement: .primaryAction) {
                Button("Settings", systemImage: "gearshape") { showingSettings = true }
            }
        }
    }

    /// The list to go back to: the one this was opened from, or for a country chosen directly, the
    /// World it's part of.
    private var previousCollection: Country? {
        if let id = trail.last {
            return countries.first { $0.id == id }
        }
        guard selectedCountryID != CountryCatalog.world.id else { return nil }
        return countries.first { $0.id == CountryCatalog.world.id }
    }

    /// The list chosen from the sidebar, which starts afresh from there, its map
    /// flying over from the one shown before.
    private var rootSelection: Binding<String> {
        Binding(
            get: { selectedCountryID },
            set: { id in
                guard id != selectedCountryID else { return }
                trail = []
                arrival = CollectionArrival(fromID: selectedCountryID, toID: id)
                selectedCountryID = id
            })
    }

    /// Shows another list where this one was, such as Japan's prefectures opened from the World,
    /// and keeps the way back. Its map flies in from this one's, unless the map has already flown
    /// there full screen.
    private func open(_ id: String, fliesMap: Bool) {
        guard id != selectedCountryID, countries.contains(where: { $0.id == id }) else { return }
        trail.append(selectedCountryID)
        arrival = CollectionArrival(fromID: fliesMap ? selectedCountryID : nil, toID: id)
        selectedCountryID = id
    }

    /// Back to the list this one was opened from, or from a country to the World, its map flying
    /// back out, with the place just left brought into view.
    private func goBack() {
        guard let previous = previousCollection else { return }
        if !trail.isEmpty { trail.removeLast() }
        let left = selectedCountryID
        let row = previous.divisions.first { CountryCatalog.collection(for: $0)?.id == left }
        arrival = CollectionArrival(fromID: left, toID: previous.id, revealedPlaceID: row?.id)
        selectedCountryID = previous.id
    }

    /// The quiz pops a collection's map up as a board to quiz yourself on, running its own animation.
    private func openGame(_ collection: Country) {
        guard let quiz = MapGame.make(for: collection, rules: counting.rules) else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { game = quiz }
    }

    /// Always in the same place, so the toolbar never shifts. Tap to undo; touch and hold to redo.
    private var undoButton: some View {
        Menu {
            if let name = undoState.redoName {
                Button(name.isEmpty ? "Redo" : "Redo \(name)", systemImage: "arrow.uturn.forward") {
                    undoManager?.redo()
                }
            }
        } label: {
            Label(undoState.undoName.map { $0.isEmpty ? "Undo" : "Undo \($0)" } ?? "Undo", systemImage: "arrow.uturn.backward")
                .symbolEffect(.bounce, value: undoState.registrations)
        } primaryAction: {
            undoManager?.undo()
        }
        .labelStyle(.iconOnly)
        .disabled(undoState.undoName == nil && undoState.redoName == nil)
    }

    /// Sets a place's level. The countries it belongs to rise to at least that level, with a toast
    /// saying so, and one undo puts every one of them back.
    private func update(
        _ status: VisitLevel, for division: AdministrativeDivision, in collection: Country, model: SaveModel
    ) {
        let before = model.snapshot()
        let previous = before.status(for: division)
        guard previous.id != status.id else { return }
        let raised = before.countriesRaised(by: status, at: division, rules: counting.rules)
        let targets = ([division] + raised.map(\.place)).map { (place: $0, level: status) }
        let name = "\(division.name) → \(status.name)"
        guard setLevels(targets, model: model, context: modelContext, undoManager: undoManager, actionName: name) else { return }
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
            regionCelebration = RegionCelebration(regionID: id)
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
    private func setLevels(
        _ targets: [(place: AdministrativeDivision, level: VisitLevel)], model: SaveModel,
        context: ModelContext, undoManager: UndoManager?, actionName: String
    ) -> Bool {
        let before = model.snapshot()
        let inverse = targets.map { (place: $0.place, level: before.status(for: $0.place)) }
        let previousData = model.statusesData
        let previousJapan = model.visitStatus
        do {
            for target in targets { try model.setStatus(target.level, for: target.place) }
            try context.save()
        } catch {
            model.statusesData = previousData
            model.visitStatus = previousJapan
            saveError = error.localizedDescription
            return false
        }
        undoManager?.registerUndo(withTarget: model) { model in
            guard setLevels(inverse, model: model, context: context, undoManager: undoManager, actionName: actionName) else { return }
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

    private func refreshUndoState() {
        var state = undoState
        state.undoName = undoManager?.canUndo == true ? undoManager?.undoActionName : nil
        state.redoName = undoManager?.canRedo == true ? undoManager?.redoActionName : nil
        if state.undoName != nil, state.undoName != undoState.undoName { state.registrations += 1 }
        undoState = state
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
