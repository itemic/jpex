import SwiftUI

/// Game Mode: a collection's map pops up as a board to play on. Name It lights up a place for you
/// to name, flying the camera close enough to see even the smallest; Find It names a place for
/// you to tap, pinching to look closer. Answers colour the board as you go, a run of right answers
/// earns a bonus, and every round ends in stars. On iPhone Duo the board takes the far side of the
/// fold and the cards the near side.
struct GameScreen: View {
    var game: MapGame
    var onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("localLanguage") private var localLanguage = false
    @State private var navigator: MapNavigator
    @State private var isExpanded = false
    @State private var isClosing = false
    @State private var panelFrame: CGRect = .zero
    @State private var flash: GameFlash?
    @State private var twinkle: GameSpotlight?
    /// A place from the results being looked at again.
    @State private var reviewID: String?
    /// Where the player had the camera before a hint or a reveal moved it, to go back to for the next place.
    @State private var playerCamera: MapCamera?
    /// Counts camera flights, so a flight in two legs can tell when another has taken over.
    @State private var flights = 0
    @State private var burstLocation: CGPoint = .zero
    @State private var bursts = 0
    @State private var streakBanner: Int?
    @State private var streakBursts = 0
    @State private var haptic: GameHaptic?
    @State private var pendingAdvance: Task<Void, Never>?

    init(game: MapGame, onClose: @escaping () -> Void) {
        self.game = game
        self.onClose = onClose
        _navigator = State(initialValue: MapNavigator(collection: game.collection, map: game.map))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    Color(uiColor: .systemBackground)
                        .opacity(isExpanded ? 1 : 0)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                    arrangement(size: proxy.size, fold: FoldRegions(in: proxy))
                }
            }
            .containerBackground(.clear, for: .navigation)
            .navigationTitle(game.collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarVisibility(isExpanded ? .visible : .hidden, for: .navigationBar)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        }
        .onAppear(perform: expand)
        .onChange(of: game.scopeID) {
            frameScope()
            haptic = GameHaptic(feedback: .selection)
        }
        .onChange(of: game.streak) { old, new in celebrate(streak: new, from: old) }
        .task(id: game.phase == .lobby && isExpanded) { await twinkleWhileWaiting() }
        .sensoryFeedback(trigger: haptic) { _, event in event?.feedback }
        .accessibilityAction(.escape, back)
    }

    /// The board with the card floating over its foot, or beside it on a wide screen; while
    /// iPhone Duo is partly folded, the board on the far side of the fold and the card on the near side.
    private func arrangement(size: CGSize, fold: FoldRegions?) -> some View {
        let bounds = CGRect(origin: .zero, size: size)
        let stageRect = fold?.far ?? bounds
        let panelRect = fold?.near ?? bounds
        let isBeside = fold == nil && size.width > size.height && size.width >= 600
        return ZStack(alignment: .topLeading) {
            stage(panelFrame: fold == nil ? panelFrame : .zero)
                .frame(width: stageRect.width, height: stageRect.height)
                .position(x: stageRect.midX, y: stageRect.midY)
            panel(isSeparate: fold != nil, isBeside: isBeside)
                .frame(width: panelRect.width, height: panelRect.height, alignment: isBeside ? .bottomTrailing : .bottom)
                .position(x: panelRect.midX, y: panelRect.midY)
        }
        .animation(.smooth(duration: 0.5), value: fold)
    }

    private func stage(panelFrame: CGRect) -> some View {
        let isFinding = game.mode == .findIt && (game.phase == .asking || game.phase == .answered)
        return GameMapStage(
            navigator: navigator, statuses: game.statuses, labels: labels,
            veiled: game.veiledRegionIDs, veilID: game.scopeID ?? "everywhere",
            ringed: isFinding ? game.openRegionIDs : [],
            spotlight: spotlight, flash: flash, burstLocation: burstLocation, bursts: bursts,
            isExpanded: isExpanded, tapsAnswer: isFinding, panelFrame: panelFrame,
            accessibilityLabel: mapLabel, accessibilityHint: mapHint, onTap: tap(at:))
    }

    private func panel(isSeparate: Bool, isBeside: Bool) -> some View {
        VStack(spacing: 10) {
            if let streakBanner {
                StreakBanner(count: streakBanner)
                    .transition(.toast)
            }
            card
                .frame(maxWidth: isBeside ? 380 : 600)
                .glassPanel(in: .rect(cornerRadius: 30))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { panelFrame = $0 }
        }
        .overlay(alignment: .top) {
            // A run of right answers throws confetti from the top of the card.
            CelebrationBurst(trigger: streakBursts, colors: MapGame.confettiColors, pieceCount: 44)
                .frame(width: 360, height: 360)
                .offset(y: -180)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .frame(maxHeight: isSeparate ? .infinity : nil, alignment: .bottom)
        .opacity(isExpanded ? 1 : 0)
        .offset(y: isExpanded || isSeparate ? 0 : 80)
    }

    @ViewBuilder
    private var card: some View {
        switch game.phase {
        case .lobby:
            GameLobbyCard(game: game, localLanguage: localLanguage, onPlay: start)
                .transition(.blurReplace)
        case .asking, .answered:
            GameQuestionCard(
                game: game, localLanguage: localLanguage, onChoose: choose, onHint: hint, onReveal: reveal, onNext: next)
                .transition(.blurReplace)
        case .finished:
            GameResultsCard(
                game: game, localLanguage: localLanguage, reviewID: reviewID, onReview: review,
                onPlayAgain: { start(game.mode) }, onChangeGame: backToLobby)
                .transition(.blurReplace)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if game.phase == .lobby {
                Button("Close", systemImage: "xmark", action: close)
                    .keyboardShortcut(.cancelAction)
            } else {
                Button("Back to Games", systemImage: "chevron.backward", action: backToLobby)
                    .keyboardShortcut(.cancelAction)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            GameShowAllButton(navigator: navigator, hasScope: game.scopeID != nil) { frameScope() }
        }
    }

    // MARK: The board

    /// The place lit up on the board: twinkles in the lobby, the place in question in Name It, the
    /// answer once it's given, and a place looked at again from the results.
    private var spotlight: GameSpotlight? {
        switch game.phase {
        case .lobby:
            return twinkle
        case .asking:
            guard game.mode == .nameIt, let question = game.current else { return nil }
            return GameSpotlight(
                regionIDs: game.placeRegions[question.place.id] ?? [], style: .question, color: game.mode.color)
        case .answered:
            guard let question = game.current, let outcome = game.outcomes[question.place.id] else { return nil }
            return GameSpotlight(
                regionIDs: game.placeRegions[question.place.id] ?? [], style: .answer,
                color: MapGame.level(for: outcome).color)
        case .finished:
            guard let reviewID, let outcome = game.outcomes[reviewID] else { return nil }
            return GameSpotlight(
                regionIDs: game.placeRegions[reviewID] ?? [], style: .answer, color: MapGame.level(for: outcome).color)
        }
    }

    /// Each place's name, once it's been answered, so the board fills in as you learn it.
    private var labels: [String: MapLabel] {
        var labels: [String: MapLabel] = [:]
        for (id, outcome) in game.outcomes {
            guard game.placeRegions[id]?.contains(id) == true, let place = game.regionPlaces[id] else { continue }
            let name = place.displayName(localLanguage: localLanguage)
            labels[id] = MapLabel(
                text: name, language: place.language(of: name), rank: MapGame.ladder.rank(of: MapGame.level(for: outcome)))
        }
        return labels
    }

    private var mapLabel: String {
        let map = "Map of \(game.collection.name)"
        guard game.phase == .asking, let question = game.current else { return map }
        switch game.mode {
        case .nameIt:
            guard let group = game.collection.groups.first(where: { $0.id == question.place.groupID }) else {
                return "\(map), with one \(game.collection.placeNoun) lit up"
            }
            return "\(map). The \(game.collection.placeNoun) lit up is in \(group.name)."
        case .findIt:
            return "\(map). Find \(question.place.name)."
        }
    }

    private var mapHint: String {
        switch (game.phase, game.mode) {
        case (.asking, .findIt): "Tap a place to answer. Pinch to zoom."
        case (.asking, .nameIt): "Choose its name below the map."
        default: "Pinch to zoom."
        }
    }

    // MARK: Playing

    private func start(_ mode: MapGameMode) {
        pendingAdvance?.cancel()
        reviewID = nil
        flash = nil
        playerCamera = nil
        withAnimation(.bouncy(duration: 0.5)) {
            game.mode = mode
            game.start()
        }
        haptic = GameHaptic(feedback: .impact(weight: .medium))
        if mode == .nameIt {
            frameQuestion()
        } else {
            frameScope()
        }
    }

    private func choose(_ place: AdministrativeDivision) {
        guard let question = game.current else { return }
        withAnimation(.bouncy(duration: 0.4)) { game.choose(place) }
        guard game.phase == .answered else { return }
        let answer = question.place.displayName(localLanguage: localLanguage)
        if place.id == question.place.id {
            haptic = GameHaptic(feedback: .success)
            announce("Right! \(answer).")
            scheduleAdvance()
        } else {
            haptic = GameHaptic(feedback: .error)
            showMistake(place)
            announce("Not quite. It’s \(answer).")
        }
    }

    /// In Find It, answers with the place under a tap: confetti where it's right, and where it's
    /// wrong, that place's name, so even a miss shows where something is.
    private func tap(at location: CGPoint) {
        guard game.mode == .findIt, game.phase == .asking, let question = game.current,
              let region = game.map.place(at: location, geometry: navigator.geometry, among: game.scopedRegionIDs),
              let place = game.regionPlaces[region.id]
        else { return }
        let answer = question.place.displayName(localLanguage: localLanguage)
        let tapped = place.displayName(localLanguage: localLanguage)
        let guess = withAnimation(.bouncy(duration: 0.4)) { game.guess(place) }
        switch guess {
        case .right:
            burstLocation = location
            bursts += 1
            haptic = GameHaptic(feedback: .success)
            announce("Found it! \(answer).")
            scheduleAdvance()
        case .wrong, .again:
            showMistake(place)
            if guess == .wrong { haptic = GameHaptic(feedback: .error) }
            announce("That’s \(tapped).")
        case .missed:
            showMistake(place)
            haptic = GameHaptic(feedback: .error)
            announce("That’s \(tapped). Here’s \(answer).")
            showAnswer(after: 0.7)
        case .ignored:
            break
        }
    }

    private func hint() {
        guard game.canHint, let question = game.current else { return }
        withAnimation(.bouncy(duration: 0.45)) { game.useHint() }
        haptic = GameHaptic(feedback: .impact(weight: .light))
        guard game.mode == .findIt, let frame = game.frames[question.place.id] else { return }
        // The neighbourhood, with the place somewhere in it but not right at its heart.
        if playerCamera == nil { playerCamera = navigator.camera }
        let neighbourhood = frame
            .insetBy(dx: -frame.width * 2.5, dy: -frame.height * 2.5)
            .offsetBy(dx: frame.width * .random(in: -1.5...1.5), dy: frame.height * .random(in: -1.5...1.5))
        fly(to: neighbourhood, margin: 0)
    }

    private func reveal() {
        guard let question = game.current else { return }
        withAnimation(.bouncy(duration: 0.4)) { game.reveal() }
        haptic = GameHaptic(feedback: .impact(weight: .light))
        announce("Here’s \(question.place.displayName(localLanguage: localLanguage)).")
        showAnswer(after: 0)
    }

    private func next() {
        pendingAdvance?.cancel()
        flash = nil
        withAnimation(.bouncy(duration: 0.45)) { game.advance() }
        switch game.phase {
        case .asking:
            frameQuestion()
        case .finished:
            playerCamera = nil
            frameScope()
            announce("Round over: \(game.rightCount) of \(game.questions.count) right, \(game.score) points.")
        case .lobby, .answered:
            break
        }
    }

    private func backToLobby() {
        pendingAdvance?.cancel()
        reviewID = nil
        flash = nil
        playerCamera = nil
        withAnimation(.bouncy(duration: 0.5)) { game.returnToLobby() }
        frameScope()
    }

    /// Escape goes back a step: out of a round to the games, or out of Game Mode.
    private func back() {
        if game.phase == .lobby {
            close()
        } else {
            backToLobby()
        }
    }

    private func review(_ place: AdministrativeDivision) {
        withAnimation(.snappy) { reviewID = place.id }
        haptic = GameHaptic(feedback: .selection)
        if let frame = game.frames[place.id] { fly(to: frame, margin: 2.2) }
    }

    /// A right answer moves on by itself after a moment; a miss waits, so there's time to look.
    private func scheduleAdvance() {
        pendingAdvance?.cancel()
        let index = game.index
        pendingAdvance = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled, game.phase == .answered, game.index == index else { return }
            next()
        }
    }

    // MARK: The camera

    /// Name It flies to each place in turn, close enough to see the smallest. Find It goes back to
    /// wherever the player had the camera before a hint or a reveal moved it.
    private func frameQuestion() {
        switch game.mode {
        case .nameIt:
            guard let question = game.current, let frame = game.frames[question.place.id] else { return }
            fly(to: frame, margin: 2.2)
        case .findIt:
            guard let camera = playerCamera else { return }
            playerCamera = nil
            flights += 1
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.8)) { navigator.camera = camera }
        }
    }

    /// Shows every place in play: the round's group, or the whole map.
    private func frameScope() {
        flights += 1
        let animation: Animation? = reduceMotion ? nil : .smooth(duration: 0.8)
        if let frame = game.scopeFrame {
            navigator.frame(frame, margin: 0.04, animation: animation)
        } else {
            navigator.showAll(animation: animation)
        }
    }

    /// Glides to where the answer is, remembering where the player had the camera.
    private func showAnswer(after delay: Double) {
        guard let question = game.current, let frame = game.frames[question.place.id] else { return }
        if playerCamera == nil { playerCamera = navigator.camera }
        Task { @MainActor in
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard game.current?.id == question.id else { return }
            fly(to: frame, margin: 2.5)
        }
    }

    /// Flies the camera to part of the board: straight there when it's in view, otherwise pulling
    /// back first to take in both ends of the journey, then coming down on the place.
    private func fly(to frame: CGRect, margin: CGFloat) {
        flights += 1
        guard !reduceMotion else {
            navigator.frame(frame, margin: margin, animation: nil)
            return
        }
        let geometry = navigator.geometry
        let area = geometry.fitArea
        let corner = geometry.toMap(CGPoint(x: area.minX, y: area.minY))
        let opposite = geometry.toMap(CGPoint(x: area.maxX, y: area.maxY))
        let inView = CGRect(
            x: min(corner.x, opposite.x), y: min(corner.y, opposite.y),
            width: abs(opposite.x - corner.x), height: abs(opposite.y - corner.y))
        guard navigator.camera.zoom > 1.01, !inView.intersects(frame) else {
            navigator.frame(frame, margin: margin, animation: .smooth(duration: 0.9))
            return
        }
        let flight = flights
        navigator.frame(inView.union(frame), margin: 0.1, animation: .smooth(duration: 0.55))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.45))
            guard flights == flight else { return }
            navigator.frame(frame, margin: margin, animation: .smooth(duration: 0.75))
        }
    }

    // MARK: Feedback

    /// Flashes a place answered by mistake red, with its name beside it.
    private func showMistake(_ place: AdministrativeDivision) {
        let regionIDs = game.placeRegions[place.id] ?? []
        guard let region = regionIDs.first.flatMap({ game.map.region(id: $0) }) else { return }
        let name = place.displayName(localLanguage: localLanguage)
        let mistake = GameFlash(
            regionIDs: regionIDs, name: name, language: place.language(of: name), flagAssetName: place.flagAssetName,
            anchor: region.center)
        withAnimation(.bouncy(duration: 0.35)) { flash = mistake }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(GameFlash.duration))
            guard flash?.id == mistake.id else { return }
            withAnimation(.smooth(duration: 0.3)) { flash = nil }
        }
    }

    /// Runs of three, of five, and every five after earn a banner and a burst of confetti.
    private func celebrate(streak: Int, from previous: Int) {
        guard streak > previous, streak == 3 || (streak >= 5 && streak.isMultiple(of: 5)) else { return }
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.15)) { streakBanner = streak }
        streakBursts += 1
        announce("\(streak) in a row!")
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            guard streakBanner == streak else { return }
            withAnimation(.smooth(duration: 0.4)) { streakBanner = nil }
        }
    }

    /// In the lobby, places in view light up one at a time in candy colours, as a taste of the game.
    private func twinkleWhileWaiting() async {
        guard game.phase == .lobby, isExpanded, !reduceMotion else { return }
        let colors = MapGame.confettiColors.shuffled()
        var count = 0
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(count == 0 ? 0.6 : GameSpotlight.twinkleDuration + 0.25))
            let geometry = navigator.geometry
            let screen = CGRect(origin: .zero, size: geometry.size)
            let inView = game.scopedPlaces.filter { place in
                guard let frame = game.frames[place.id]?.applying(geometry.transform) else { return false }
                return screen.contains(CGPoint(x: frame.midX, y: frame.midY)) && max(frame.width, frame.height) >= 12
            }
            guard !Task.isCancelled, let place = inView.randomElement() else { continue }
            twinkle = GameSpotlight(
                regionIDs: game.placeRegions[place.id] ?? [], style: .twinkle, color: colors[count % colors.count], start: .now)
            count += 1
        }
    }

    private func expand() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .bouncy(duration: 0.6, extraBounce: 0.12)) {
            isExpanded = true
        }
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        pendingAdvance?.cancel()
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .smooth(duration: 0.4)) {
            isExpanded = false
        } completion: {
            onClose()
        }
    }

    private func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }
}

/// Pulls back to every place in play. Only this button follows the camera, so the toolbar doesn't
/// redraw as it moves.
private struct GameShowAllButton: View {
    var navigator: MapNavigator
    /// Whether the round plays only some of the places, which the button frames rather than the whole map.
    var hasScope: Bool
    var action: () -> Void

    var body: some View {
        Button("Show All", systemImage: "arrow.down.right.and.arrow.up.left", action: action)
            .disabled(!hasScope && navigator.camera.zoom <= 1.01)
    }
}

/// "5 in a row!", dropping in over the card for a run of right answers.
private struct StreakBanner: View {
    var count: Int

    var body: some View {
        Label("\(count) in a row!", systemImage: "flame.fill")
            .font(.headline.weight(.heavy))
            .fontDesign(.rounded)
            .foregroundStyle(CandyGloss.lettering(on: LevelColor.orange.color))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background { CandyGloss(color: LevelColor.orange.color, pattern: .candyStripes) }
            .clipShape(Capsule())
            .shadow(color: LevelColor.orange.color.opacity(0.4), radius: 10, y: 4)
            .symbolEffect(.bounce, value: count)
            .accessibilityHidden(true)
    }
}

private struct GameHaptic: Equatable {
    var id = UUID()
    var feedback: SensoryFeedback
}
