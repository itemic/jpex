import SwiftUI

/// The map quiz: a collection's map pops up as a board to quiz yourself on. Identify lights up a
/// place to name, typed or picked; Flag shows a flag to name; Find names a place for you to tap;
/// and Capital asks for a place's capital. With Auto Zoom on, the camera flies close enough to each
/// place to see even the smallest; with it off, the whole board stays in view and places only light
/// up. Only a country's main body lights up, never its far-flung territories. Answers colour the
/// board as you go, and a wrong one just says so. The lobby's Learn tile leaves the quiz for the
/// collection's full map, to browse every place there instead. The map fills the screen and can
/// be dragged past its edges; the World wraps around as you drag it sideways. Flag sets each flag
/// large and waving over the names instead of the map. On iPhone Duo the map carries on under both
/// sides of the fold, the camera keeping to the far side, and the card sits on the near side, above
/// the keyboard when it's up. Before the camera settles on a country the World's edge would cut in
/// two, such as Russia or Fiji, the World turns beneath it so the country sits whole, and turns
/// back home when the whole board comes back into view. Groups of countries, such as the EU, play on the World map with the
/// countries outside them veiled, and add Member?, asking whether a country lit up is in or out.
struct GameScreen: View {
    var onClose: () -> Void
    /// Leaves the quiz for Learn on a collection's full map, once the quiz has closed; false where
    /// there turns out to be no list to learn in, so the quiz comes back rather than vanishing.
    var onLearn: (LearnDeck.Request) -> Bool
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether decoration may move by itself, as the lobby's twinkles do: not in Low Power Mode,
    /// with Reduce Motion, nor while the app isn't in front.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    @AppStorage("localLanguage") private var localLanguage = false
    /// Whether the camera flies to each place in turn, or keeps the whole board in view.
    @AppStorage(MapGame.autoZoomKey) private var autoZoom = true
    /// The quiz under way, replaced when another set of places is chosen.
    @State private var game: MapGame
    @State private var navigator: MapNavigator
    @State private var isExpanded = false
    /// The lobby tile whose second level is open, so Escape steps back out of it before leaving.
    @State private var openTile: MapGameMode?
    /// Whether leaving a round partly played is waiting for the person to confirm it.
    @State private var isConfirmingEnd = false
    @State private var isClosing = false
    @State private var panelFrame: CGRect = .zero
    @State private var flash: GameFlash?
    /// Places twinkling in the lobby, each lighting up and fading in turn.
    @State private var twinkles: [GameSpotlight] = []
    /// Whether the lobby's twinkling has come to rest, after a while with nothing done.
    @State private var twinklesRest = false
    /// Counts the times the person moves the map while the twinkling rests, to start it again.
    @State private var lobbyNudges = 0
    /// A place from the results being looked at again.
    @State private var reviewID: String?
    /// In Find, the place tapped on the map, waiting to be confirmed.
    @State private var selection: AdministrativeDivision?
    /// In Find with the borders hidden, where the place waiting to be confirmed was tapped, in map
    /// units: a dot marks the spot, as Dot marks its place, since lighting up the place's outline
    /// would give the borders away.
    @State private var selectionDot: CGPoint?
    /// When the dot marking the place tapped in Find, with the borders hidden, last dropped in, so
    /// it lands rather than appearing; let go once it's landed, so the board rests again.
    @State private var markerStart: Date?
    /// When the glow around a place last lit up: a place chosen in Find, an answer given, or one
    /// looked at again from the results, so the glow comes up and sends a ring out rather than
    /// appearing; let go once it's come up, so the board rests again.
    @State private var glowStart: Date?
    /// When the place in question lights up: as the camera lands on it, or at once where the board
    /// stays put, so its candy comes up and sends a ring out rather than appearing; let go once
    /// it's come up, so the board rests again.
    @State private var questionLitAt: Date?
    /// In Find, the last place tapped and when, so a second tap straight after answers with it.
    @State private var lastTap: MapTap?
    /// Counts camera flights, so a flight in two legs can tell when another has taken over.
    @State private var flights = 0
    /// When the camera's flight under way lands, the World's turn before it included, so the
    /// board isn't reframed under it partway.
    @State private var flightEnds = Date.distantPast
    /// Whether the board is fitted to the places in play and hasn't been moved since, so it can be
    /// fitted again as the room for it changes.
    @State private var isBoardFitted = false
    @State private var haptic: GameHaptic?
    @State private var pendingReframe: Task<Void, Never>?
    /// In Outline, the box the shape is set in, in global coordinates, for it to fly from.
    @State private var outlineBox: CGRect = .zero
    /// In Outline, the shape flying into its place on the board once it's answered.
    @State private var outlineFlight: OutlineFlight?
    /// The World partway through turning, drawn lighter so it can redraw at every frame.
    @State private var turningMap: TravelMap?
    /// The longitude at the World's middle partway through turning, or nil while it's at rest.
    @State private var turningLongitude: Double?
    @State private var worldTurn: Task<Void, Never>?
    /// While iPhone Duo is partly folded, its two sides, measured as if the keyboard weren't up, so
    /// typing never flips the layout; the card on the near side keeps above the keyboard instead.
    @State private var fold: FoldRegions?

    init(game: MapGame, onClose: @escaping () -> Void, onLearn: @escaping (LearnDeck.Request) -> Bool = { _ in false }) {
        self.onClose = onClose
        self.onLearn = onLearn
        _game = State(initialValue: game)
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
                    arrangement(
                        size: proxy.size, origin: proxy.frame(in: .global).origin,
                        fold: fold.map { keptAboveKeyboard($0, height: proxy.size.height) },
                        bottomInset: proxy.safeAreaInsets.bottom)
                }
            }
            .background {
                // The fold, measured under the keyboard too, in the same space as the layout above.
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: FoldRegions(in: proxy), initial: true) { _, regions in fold = regions }
                }
                .ignoresSafeArea(.keyboard)
                .accessibilityHidden(true)
            }
            .containerBackground(.clear, for: .navigation)
            .navigationTitle(game.collection.name)
            .navigationBarTitleDisplayMode(.inline)
            // Other places are chosen between rounds, not partway through one, which would lose it.
            .toolbarTitleMenu {
                if game.phase == .lobby || game.phase == .finished { collectionPicker }
            }
            // The bar is always there, so the room it takes never changes under the board as the
            // quiz opens; only its buttons fade in.
            .toolbar { toolbar }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .confirmationDialog("End this round?", isPresented: $isConfirmingEnd, titleVisibility: .visible) {
                Button("End round", role: .destructive, action: backToLobby)
                Button("Keep playing", role: .cancel) {}
            }
        }
        .overlay {
            flightLayer
        }
        .task { await open() }
        .onChange(of: game.scopeID) { frameScope() }
        .onChange(of: game.placeSetID) { frameScope() }
        .onChange(of: panelFrame.minY) { reframeOnceTheCardSettles() }
        .onChange(of: panelFrame.minX) { reframeOnceTheCardSettles() }
        .onChange(of: autoZoom) { followAutoZoom() }
        .task(id: TwinkleRun(
            isOn: game.phase == .lobby && isExpanded && allowsAmbientMotion, collectionID: game.collection.id,
            scopeID: game.scopeID, nudges: lobbyNudges)
        ) { await twinkleWhileWaiting() }
        .task(id: game.deadline) { await countDown() }
        .task(id: game.questionDeadline) { await countDownQuestion() }
        .task(id: markerStart) {
            // Once Find's dot has landed and its ring has faded, the board can rest again.
            guard markerStart != nil else { return }
            try? await Task.sleep(for: .seconds(GameSpotlight.markerDrop + GameSpotlight.markerRing + 0.1))
            guard !Task.isCancelled else { return }
            markerStart = nil
        }
        .task(id: glowStart) {
            // Likewise once a glow has come up and its ring has faded.
            guard glowStart != nil else { return }
            try? await Task.sleep(for: .seconds(GameSpotlight.markerDrop + GameSpotlight.markerRing + 0.1))
            guard !Task.isCancelled else { return }
            glowStart = nil
        }
        .task(id: questionLitAt) {
            // And once the place in question has come up, which waits for the camera to land, and
            // its ring has faded.
            guard let questionLitAt else { return }
            let wait = max(questionLitAt.timeIntervalSinceNow, 0)
            try? await Task.sleep(for: .seconds(wait + GameSpotlight.markerDrop + GameSpotlight.markerRing + 0.1))
            guard !Task.isCancelled else { return }
            self.questionLitAt = nil
        }
        .sensoryFeedback(trigger: haptic) { _, event in event?.feedback }
        .accessibilityAction(.escape, back)
    }

    /// The sides of the fold within the room the keyboard leaves: the near side ends where the
    /// keyboard begins, keeping enough height for the card even if that means reaching over the fold.
    private func keptAboveKeyboard(_ fold: FoldRegions, height: CGFloat) -> FoldRegions {
        guard fold.near.maxY > height + 0.5 else { return fold }
        var kept = fold
        let bottom = max(height, 0)
        let top = min(fold.near.minY, max(bottom - 150, 0))
        kept.near = CGRect(x: fold.near.minX, y: top, width: fold.near.width, height: max(bottom - top, 0))
        kept.far.size.height = min(fold.far.height, max(bottom - fold.far.minY, 0))
        return kept
    }

    /// The board with the card floating over its foot, or beside it on a wide screen; while
    /// iPhone Duo is partly folded, the board on the far side of the fold and the card filling the near side.
    @ViewBuilder
    private func arrangement(size: CGSize, origin: CGPoint, fold: FoldRegions?, bottomInset: CGFloat) -> some View {
        if isFlagRound, let place = game.current {
            flagArrangement(for: place, size: size, fold: fold, bottomInset: bottomInset)
                .transition(.opacity)
        } else if game.mode == .outline, game.phase == .asking, let place = game.current {
            outlineArrangement(for: place, size: size, fold: fold, bottomInset: bottomInset)
                .transition(.opacity)
        } else {
            mapArrangement(size: size, origin: origin, fold: fold, bottomInset: bottomInset)
                .transition(.opacity)
        }
    }

    private var isFlagRound: Bool {
        game.mode == .flags && (game.phase == .asking || game.phase == .answered)
    }

    /// Find's round, which keeps the camera where you put it, Auto Zoom or not.
    private var isFindingRound: Bool {
        game.mode == .findIt && (game.phase == .asking || game.phase == .answered)
    }

    /// The map always fills the screen, so on iPhone Duo its sea carries on under the near side
    /// beneath the card; only the camera keeps to the far side.
    private func mapArrangement(size: CGSize, origin: CGPoint, fold: FoldRegions?, bottomInset: CGFloat) -> some View {
        let bounds = CGRect(origin: .zero, size: size)
        let panelRect = fold?.near ?? bounds
        let isBeside = fold == nil && isWide(size)
        return ZStack(alignment: .topLeading) {
            stage(panelFrame: fold == nil ? panelFrame : .zero, farSide: fold?.far.offsetBy(dx: origin.x, dy: origin.y))
                .id(game.collection.id)
                .transition(.opacity)
                .frame(width: bounds.width, height: bounds.height)
            panel(
                isSeparate: fold != nil, isBeside: isBeside, isTall: size.height >= 600, height: panelRect.height,
                columnWidth: columnWidth(for: size), safeBottom: bottomInset)
                .frame(width: panelRect.width, height: panelRect.height, alignment: isBeside ? .bottomTrailing : .bottom)
                .position(x: panelRect.midX, y: panelRect.midY)
        }
        .animation(.smooth(duration: 0.5), value: fold)
    }

    /// Whether the card stands beside the map or a hero rather than below it: on a wide screen, as
    /// on iPad or iPhone Duo unfolded and turned on its side, and on any short, wide one, such as
    /// iPhone on its side or Duo's outer display standing in a tent, where a card below would leave
    /// no room for the board.
    private func isWide(_ size: CGSize) -> Bool {
        size.width > size.height && (size.width >= 600 || size.height < 500)
    }

    /// The column a card takes beside the board: a comfortable width, but never more than about
    /// half a narrow screen, so the board keeps its share.
    private func columnWidth(for size: CGSize) -> CGFloat {
        min(max(size.width * 0.5, 300), 420)
    }

    /// Where a hero, such as Flag's flag or Outline's shape, and the card go: the hero above the
    /// card, or on a wide screen to its leading side with the card in a column beside it; on iPhone
    /// Duo partly folded, the hero on the far side of the fold and the card on the near side.
    private func heroLayout(size: CGSize, fold: FoldRegions?) -> (hero: CGRect, card: CGRect) {
        if let fold, !fold.far.isEmpty { return (fold.far, fold.near) }
        if isWide(size) {
            let column = min(max(size.width * 0.42, 300), 460)
            return (
                CGRect(x: 0, y: 0, width: size.width - column, height: size.height),
                CGRect(x: size.width - column, y: 0, width: column, height: size.height))
        }
        let split = size.height * 0.42
        return (
            CGRect(x: 0, y: 0, width: size.width, height: split),
            CGRect(x: 0, y: split, width: size.width, height: size.height - split))
    }

    /// The card's room beside or below a hero, run on to the foot of the screen where it reaches
    /// the bottom, so a list scrolls all the way down under the home indicator.
    private func heroCardRect(_ rect: CGRect, size: CGSize, bottomInset: CGFloat) -> CGRect {
        guard rect.maxY >= size.height - 0.5 else { return rect }
        var rect = rect
        rect.size.height += bottomInset
        return rect
    }

    /// Flags in place of the map: the flag large and waving above the names, over a wash of its
    /// own colours filling the whole screen, or on iPhone Duo, on the far side of the fold with the
    /// names on the near side.
    private func flagArrangement(
        for place: AdministrativeDivision, size: CGSize, fold: FoldRegions?, bottomInset: CGFloat
    ) -> some View {
        let (flagRect, cardRect) = heroLayout(size: size, fold: fold)
        let namesRect = heroCardRect(cardRect, size: size, bottomInset: bottomInset)
        let reachesFoot = namesRect.height > cardRect.height
        return ZStack(alignment: .topLeading) {
            // Edge to edge, under the bars and the home indicator: blown up past the screen's
            // edges first, so the blur never fades out before them.
            Color.clear
                .overlay {
                    Image(place.flagAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(1.3)
                        .blur(radius: 60)
                        .opacity(0.22)
                }
                .clipped()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .id(place.id)
                .transition(.opacity)
            FlagHero(place: place, isRight: game.outcomes[place.id]?.isRightFirstTime == true)
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .frame(width: flagRect.width, height: flagRect.height)
                .position(x: flagRect.midX, y: flagRect.midY)
                .id(place.id)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .scale(scale: 0.7).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
            questionBesideHero(bottomInset: reachesFoot ? bottomInset : 0, height: namesRect.height)
                .frame(maxWidth: 600)
                .frame(width: namesRect.width, height: namesRect.height, alignment: .top)
                .position(x: namesRect.midX, y: namesRect.midY)
        }
        .opacity(isExpanded ? 1 : 0)
        .animation(roundChange, value: place.id)
    }

    /// Outline in place of the map: the shape alone, large on a plain grey ground above the card,
    /// or on iPhone Duo, on the far side of the fold with the card on the near side.
    private func outlineArrangement(
        for place: AdministrativeDivision, size: CGSize, fold: FoldRegions?, bottomInset: CGFloat
    ) -> some View {
        let (shapeRect, heroCard) = heroLayout(size: size, fold: fold)
        let cardRect = heroCardRect(heroCard, size: size, bottomInset: bottomInset)
        let reachesFoot = cardRect.height > heroCard.height
        return ZStack(alignment: .topLeading) {
            Color(uiColor: .systemGray6)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            if let outline = game.outline(of: place) {
                OutlineHero(
                    path: outline, color: game.mode.color, rotation: game.rotations[place.id] ?? 0,
                    accessibilityLabel: outlineLabel(for: place))
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { outlineBox = $0 }
                    .padding(.horizontal, 36)
                    .padding(.vertical, 28)
                    .frame(width: shapeRect.width, height: shapeRect.height)
                    .position(x: shapeRect.midX, y: shapeRect.midY)
                    .id(place.id)
                    // Each shape grows into place; with Reduce Motion it only fades in.
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .opacity))
            }
            questionBesideHero(bottomInset: reachesFoot ? bottomInset : 0, height: cardRect.height)
                .frame(maxWidth: 600)
                .frame(width: cardRect.width, height: cardRect.height, alignment: .top)
                .position(x: cardRect.midX, y: cardRect.midY)
        }
        .opacity(isExpanded ? 1 : 0)
        .animation(roundChange, value: place.id)
    }

    /// The question card beside or below a hero. A list of names fills its room and scrolls itself;
    /// anything else keeps to its own height, and scrolls only where the room runs short, as on a
    /// short screen such as iPhone Duo's outer display on its side.
    @ViewBuilder
    private func questionBesideHero(bottomInset: CGFloat, height: CGFloat) -> some View {
        let card = GameQuestionCard(
            game: game, localLanguage: localLanguage, isRoomy: true, selection: nil, onAnswer: answer,
            onTyped: answer(typed:), onDecoy: answer(decoy:), onReveal: reveal, onNext: next, onSkip: skip,
            bottomInset: bottomInset)
        if game.answerMethod == .list {
            card
        } else {
            FittedScroll(maxHeight: height) { card }
        }
    }

    /// What VoiceOver hears for an outline, which it can't see: such as "Outline of a country in Africa".
    private func outlineLabel(for place: AdministrativeDivision) -> String {
        let noun = game.collection.placeNoun
        guard game.scopeID == nil, !game.scopes.isEmpty,
              let group = game.collection.groups.first(where: { $0.id == place.groupID })
        else { return "Outline of a \(noun)" }
        return "Outline of a \(noun) in \(group.name)"
    }

    /// The outline flying into its place on the board, over everything.
    @ViewBuilder
    private var flightLayer: some View {
        if let outlineFlight {
            GeometryReader { proxy in
                let origin = proxy.frame(in: .global).origin
                OutlineShape(unit: outlineFlight.path, stretch: outlineFlight.stretch)
                    .fill(outlineFlight.color.gradient)
                    .overlay {
                        OutlineShape(unit: outlineFlight.path, stretch: outlineFlight.stretch)
                            .stroke(.white, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    }
                    .frame(width: outlineFlight.frame.width, height: outlineFlight.frame.height)
                    .rotationEffect(.degrees(outlineFlight.rotation))
                    .position(x: outlineFlight.frame.midX - origin.x, y: outlineFlight.frame.midY - origin.y)
                    .opacity(outlineFlight.opacity)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func stage(panelFrame: CGRect, farSide: CGRect?) -> some View {
        let tried = triedRegionIDs
        return GameMapStage(
            navigator: navigator, map: turningMap ?? game.map, statuses: game.statuses, labels: labels,
            veiled: game.veiledRegionIDs, veilID: "\(game.scopeID ?? "everywhere")-\(game.placeSetID ?? "all")-\(game.isMembershipRound)",
            // With the borders hidden, rings around the smallest places would give them away.
            ringed: isFindingRound && game.showsBorders ? game.openRegionIDs.subtracting(tried) : [], tried: tried,
            plain: plainRegionIDs,
            // Lights keep to places as they rest, so they wait while the World turns beneath them.
            spotlights: turningMap == nil ? spotlights : [], flash: turningMap == nil ? flash : nil, wrapPeriod: wrapPeriod,
            isExpanded: isExpanded, tapsAnswer: isFindingRound, panelFrame: panelFrame,
            farSide: farSide,
            accessibilityLabel: mapLabel, accessibilityValue: mapValue, accessibilityHint: mapHint, onTap: tap(at:),
            onMove: movedByHand)
    }

    /// The card over the board, in one glass panel, standing off the screen's foot by the app's
    /// shared rule: a little above the home indicator, or a margin's width where there's none.
    private func panel(
        isSeparate: Bool, isBeside: Bool, isTall: Bool, height: CGFloat, columnWidth: CGFloat, safeBottom: CGFloat
    ) -> some View {
        let isAnswering = game.phase == .asking || game.phase == .answered
        // Beside the map, a list of names or pictures to pick from takes the column's full height.
        let fillsColumn = isBeside && isAnswering && game.answerMethod == .list
        // A list of names or pictures scrolls itself; every other card keeps to its own height, and
        // scrolls within the glass only where the screen is too short for it, rather than running
        // off the top.
        let fitsItself = isAnswering && game.answerMethod == .list
        // The gap beneath the glass, by the app's shared rule, and the room left above it, less a
        // little at the top, for a card that keeps to its own height.
        let foot: CGFloat = safeBottom > 0 ? 10 : 16
        let room = max(height - foot - 6, 0)
        let swap = AnyTransition.slotSwap(reduceMotion: reduceMotion)
        return ZStack(alignment: .bottom) {
            // One glass throughout. As a round of a list begins or ends, only what's in it trades
            // places, the card that scrolls itself and the one that keeps to its own height, in one
            // slot pinned to the foot, and the glass reshapes around them rather than giving way to
            // another.
            ZStack(alignment: .bottom) {
                if fitsItself {
                    card(isRoomy: isSeparate || fillsColumn, isWide: isBeside && isTall)
                        .transition(swap)
                } else {
                    FittedScroll(maxHeight: room) {
                        // Short of height, as on the near side of iPhone Duo's fold when it's set
                        // down like a laptop, the lobby leaves its name to the title bar so every
                        // tile fits without scrolling.
                        card(isRoomy: false, isWide: isBeside && isTall, isShort: height < 520, maxHeight: room)
                    }
                    .transition(swap)
                }
            }
            .frame(maxWidth: isBeside ? columnWidth : 600)
            // Whatever comes and goes inside stays inside the glass.
            .clipShape(.rect(cornerRadius: 28))
            .glassPanel(in: .rect(cornerRadius: 28))
            .padding(.horizontal, 10)
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { panelFrame = $0 }
        .padding(.bottom, foot)
        .padding(.top, isSeparate || fillsColumn ? 6 : 0)
        .frame(maxHeight: isSeparate || fillsColumn ? .infinity : nil, alignment: .bottom)
        .opacity(isExpanded ? 1 : 0)
        // It rises into place as the quiz opens and sinks as it closes; with Reduce Motion it only fades.
        .offset(y: isExpanded || isSeparate || reduceMotion ? 0 : 80)
    }

    /// The card for where the quiz is: the lobby, a question, or the results. The one going and the
    /// one coming share one slot, pinned to the glass's foot, so as they trade places the glass
    /// takes the taller of the two rather than both stacked, and never swells and snaps back.
    private func card(isRoomy: Bool, isWide: Bool, isShort: Bool = false, maxHeight: CGFloat? = nil) -> some View {
        let swap = AnyTransition.slotSwap(reduceMotion: reduceMotion)
        return ZStack(alignment: .bottom) {
            switch game.phase {
            case .lobby:
                GameLobbyCard(
                    game: game, localLanguage: localLanguage, isRoomy: isWide, isShortOfHeight: isShort, maxHeight: maxHeight,
                    glowing: twinkles.compactMap { $0.regionIDs.first.flatMap(game.place(id:)) }, canLearn: learnRequest != nil,
                    openTile: $openTile, onPlay: start, onLearn: learn
                ) { collectionPicker }
                    .transition(swap)
            case .asking, .answered:
                if game.mode == .listAll {
                    GameListAllCard(game: game, localLanguage: localLanguage, onTyped: name(listAll:), onGiveUp: giveUp)
                        .transition(swap)
                } else {
                    GameQuestionCard(
                        game: game, localLanguage: localLanguage, isRoomy: isRoomy, selection: selection, onAnswer: answer,
                        onTyped: answer(typed:), onDecoy: answer(decoy:), onReveal: reveal, onNext: next, onSkip: skip,
                        onMembership: answer(isMember:), listFoot: 8)
                        .transition(swap)
                }
            case .finished:
                GameResultsCard(
                    game: game, localLanguage: localLanguage, reviewID: reviewID, onLookAgain: review,
                    onReview: reviewMisses, onNewGame: { start(game.mode) }, onBack: backToLobby)
                    .transition(swap)
            }
        }
    }

    /// Every set of places there's a map to quiz on, groups of countries in their own section.
    /// Choosing one starts afresh with its map.
    /// In a submenu for each section, such as World Groups or Asia, named with the places chosen
    /// in it, so the long list keeps its grouping; the World first, on its own.
    @ViewBuilder
    private var collectionPicker: some View {
        // Choosing another set of places starts afresh.
        let selection = Binding(get: { game.collection.id }, set: { id in switchCollection(to: id) })
        ForEach(MapGame.sections(applying: counting.rules)) { section in
            if let title = section.title {
                Menu {
                    Picker(title, selection: selection) {
                        ForEach(section.countries) { collection in
                            Text(collection.distinctName).tag(collection.id)
                        }
                    }
                } label: {
                    Text(title)
                    if let chosen = section.countries.first(where: { $0.id == game.collection.id }) {
                        Text(chosen.distinctName)
                    }
                }
            } else {
                Picker("Places", selection: selection) {
                    ForEach(section.countries) { collection in
                        Text(collection.distinctName).tag(collection.id)
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Group {
                if game.phase == .lobby {
                    // With a tile's second level open, Escape steps back to the tiles instead.
                    Button("Close", systemImage: "xmark", action: close)
                        .keyboardShortcut(openTile == nil ? .cancelAction : nil)
                } else {
                    Button("Quizzes", systemImage: "chevron.backward", action: back)
                        .accessibilityLabel("Back to quizzes")
                        .keyboardShortcut(.cancelAction)
                }
            }
            .opacity(isExpanded ? 1 : 0)
        }
        // Only where there's a board to fly over: not in the lobby, nor in Flag, which has none.
        if game.phase != .lobby, !isFlagRound {
            // Zoom out and in by hand, a step at a time, around the middle of the map.
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Zoom out", systemImage: "minus") { zoom(by: 1 / 1.8) }
                    .disabled(!canZoomByHand || navigator.camera.zoom <= 1.01)
                    .opacity(isExpanded ? 1 : 0)
                Button("Zoom in", systemImage: "plus") { zoom(by: 1.8) }
                    .disabled(!canZoomByHand || navigator.camera.zoom >= navigator.maximumZoom - 0.01)
                    .opacity(isExpanded ? 1 : 0)
                // Back out to the whole board in one go, as the full map's Show all does.
                Button("Show all", systemImage: "arrow.down.right.and.arrow.up.left", action: showAll)
                    .disabled(!canZoomByHand || navigator.camera.zoom <= 1.01)
                    .opacity(isExpanded ? 1 : 0)
            }
            // A pinch does the same, so where room runs short, as in iPhone Duo's side bar on its
            // short outer display, these go into the overflow menu before Auto Zoom, the one place
            // to turn it on or off mid-round.
            .overflowsFirst()
            ToolbarItem(placement: .primaryAction) {
                Toggle("Auto zoom", systemImage: "location.viewfinder", isOn: $autoZoom)
                    .toggleStyle(.button)
                    .disabled(!autoZoomApplies)
                    .opacity(isExpanded ? 1 : 0)
                    .accessibilityHint("When on, the map flies in to each place. When off, the whole map stays in view.")
            }
            .overflowsLast()
        }
    }

    /// Whether the board is there to zoom: not while Outline's shape stands in for it.
    private var canZoomByHand: Bool {
        isExpanded && !(game.phase == .asking && game.mode == .outline)
    }

    /// Zooms the map by a step around its middle, as a pinch would, which leaves it no longer fitted.
    private func zoom(by factor: CGFloat) {
        movedByHand()
        navigator.zoom(by: factor, animation: reduceMotion ? nil : .smooth(duration: 0.35))
        haptic = GameHaptic(feedback: .selection)
    }

    /// Back out to the whole board, by hand as a step of zoom is, so Auto Zoom doesn't fly straight
    /// back in; at once with Reduce Motion.
    private func showAll() {
        movedByHand()
        navigator.showAll(animation: reduceMotion ? nil : .smooth(duration: 0.45))
        haptic = GameHaptic(feedback: .selection)
    }

    /// Whether Auto Zoom has anything to do just now. Find keeps the camera where you put it, and
    /// Outline and Code have nothing on the board to fly to until they're answered.
    private var autoZoomApplies: Bool {
        if isFindingRound || game.mode == .listAll { return false }
        if game.phase == .asking, [.outline, .code, .whoseCapital, .pickOutline].contains(game.mode) { return false }
        return true
    }

    // MARK: The board

    /// The places lit up on the board: twinkles in the lobby, otherwise the one spotlight.
    private var spotlights: [GameSpotlight] {
        game.phase == .lobby ? twinkles : spotlight.map { [$0] } ?? []
    }

    /// The place lit up on the board: the place in question in Identify and Capital, the answer
    /// once it's given, and a place looked at again from the results.
    private var spotlight: GameSpotlight? {
        switch game.phase {
        case .lobby:
            return nil
        case .asking:
            if game.mode == .findIt, let selection {
                // With the borders hidden, only a dot where it was tapped: the place's outline lit
                // up would show where its borders run before it's answered.
                guard game.showsBorders else {
                    return selectionDot.map {
                        GameSpotlight(regionIDs: [], style: .marker, color: game.mode.color, marker: $0, start: markerStart)
                    }
                }
                return lit(selection.id, style: .answer, color: game.mode.color, litAt: glowStart)
            }
            if game.mode == .dot, let place = game.current, let point = game.dotPoint(of: place) {
                return GameSpotlight(regionIDs: [], style: .marker, color: game.mode.color, marker: point)
            }
            guard lightsQuestion, let place = game.current else { return nil }
            return lit(place.id, style: .question, color: game.mode.color, litAt: questionLitAt)
        case .answered:
            guard let place = game.current, let outcome = game.outcomes[place.id] else { return nil }
            return lit(
                place.id, style: .answer, color: MapGame.level(for: outcome).color, cities: capitalCities(of: place),
                litAt: glowStart)
        case .finished:
            // A place looked at again, with its capitals marked where they're the answer.
            guard let reviewID, let outcome = game.outcomes[reviewID] else { return nil }
            let cities = game.place(id: reviewID).map(capitalCities(of:)) ?? []
            return lit(reviewID, style: .answer, color: MapGame.level(for: outcome).color, cities: cities, litAt: glowStart)
        }
    }

    /// Whether the place in question is lit up on the board while it's asked about, striped like
    /// candy: in Identify, Capital, Member?, Flag's and Code's Find, and Everything.
    private var lightsQuestion: Bool {
        [.nameIt, .capitals, .member, .pickFlag, .pickCode, .everything].contains(game.mode)
    }

    /// A place lit up: its own outline only, keeping to its main body, so a country's far-flung
    /// territories and overseas departments stay dark. `litAt` is when its light came on, the place
    /// in question's or an answer's glow, for it to come up rather than appear.
    private func lit(
        _ placeID: String, style: GameSpotlight.Style, color: Color, cities: [GameSpotlight.City] = [], litAt: Date? = nil
    ) -> GameSpotlight {
        GameSpotlight(
            regionIDs: game.mainRegions(of: placeID), style: style, color: color, cities: cities,
            mainBody: game.mainBody(of: placeID), litAt: litAt)
    }

    /// A place's capitals to mark on the map, where it's known where they are: in Capital either
    /// way round once it's answered.
    private func capitalCities(of place: AdministrativeDivision) -> [GameSpotlight.City] {
        guard game.mode == .capitals || game.mode == .whoseCapital else { return [] }
        return (game.capitals[place.id] ?? []).compactMap { capital in
            game.mapPoint(of: capital).map { GameSpotlight.City(name: capital.name, point: $0) }
        }
    }

    /// In Dot, the regions not answered yet, drawn as plain land; each one's borders
    /// and colour bloom in as it's answered.
    private var plainRegionIDs: Set<String> {
        let isPlain = game.mode == .dot || game.mode == .findIt && !game.showsBorders
        guard isPlain, game.phase == .asking || game.phase == .answered else { return [] }
        return Set(game.regionPlaces.filter { game.outcomes[$0.value.id] == nil }.keys)
    }

    /// In Find, the regions of the places already tried for this question, faded on the board
    /// until it's answered.
    private var triedRegionIDs: Set<String> {
        guard game.mode == .findIt, game.phase == .asking else { return [] }
        return Set(game.wrongGuesses.flatMap { game.placeRegions[$0.id] ?? [] })
    }

    /// Each place's name, once it's been answered, so the board fills in as you learn it.
    private var labels: [String: MapLabel] {
        var labels: [String: MapLabel] = [:]
        for (id, outcome) in game.outcomes {
            guard game.hasOwnRegion(id), let place = game.place(id: id) else { continue }
            let name = place.displayName(localLanguage: localLanguage)
            labels[id] = MapLabel(
                text: name, language: place.language(of: name), rank: MapGame.ladder.rank(of: MapGame.level(for: outcome)))
        }
        return labels
    }

    private var mapLabel: String {
        let map = "Map of \(game.collection.name)"
        guard game.phase == .asking, let place = game.current else { return map }
        switch game.mode {
        case .nameIt:
            guard let group = game.collection.groups.first(where: { $0.id == place.groupID }) else {
                return "\(map), with one \(game.collection.placeNoun) lit up"
            }
            return "\(map). The \(game.collection.placeNoun) lit up is in \(group.name)."
        case .findIt:
            return "\(map). Find \(place.name)."
        case .capitals, .member, .pickFlag, .pickCode:
            return "\(map). \(place.name) is lit up."
        case .dot:
            guard let group = game.collection.groups.first(where: { $0.id == place.groupID }), !game.scopes.isEmpty else {
                return "\(map), with one \(game.collection.placeNoun) marked with a dot"
            }
            return "\(map). The \(game.collection.placeNoun) marked with a dot is in \(group.name)."
        case .everything:
            guard let country = game.countryName(of: place) else { return "\(map), with one place lit up" }
            return "\(map). The place lit up is in \(country)."
        case .flags, .outline, .code, .whoseCapital, .listAll, .pickOutline:
            return map
        }
    }

    /// In Find, the places already tried for this question.
    private var mapValue: String {
        guard game.mode == .findIt, game.phase == .asking, !game.wrongGuesses.isEmpty else { return "" }
        let names = game.wrongGuesses.map { $0.displayName(localLanguage: localLanguage) }
        return "Already tried \(names.formatted(.list(type: .and)))"
    }

    private var mapHint: String {
        switch (game.phase, game.mode) {
        case (.asking, .findIt):
            game.showsBorders
                ? "Tap a place to choose it, then confirm, or double-tap it to answer straight away. Pinch to zoom."
                : "Tap a place to mark it with a dot, then confirm, or tap it again to answer. Pinch to zoom."
        case (.asking, .nameIt): game.answerMethod == .typing ? "Type its name below the map." : "Choose its name below the map."
        case (.asking, .flags): "Choose its name below the map."
        case (.asking, .pickFlag): "Choose its flag below the map."
        case (.asking, .pickOutline): "Choose its outline below the map."
        case (.asking, .pickCode): game.answerMethod == .typing ? "Type its code below the map." : "Choose its code below the map."
        case (.asking, .outline), (.asking, .code), (.asking, .dot), (.asking, .whoseCapital), (.asking, .everything):
            game.answerMethod == .typing ? "Type its name below the map." : "Choose its name below the map."
        case (.asking, .capitals): game.answerMethod == .typing ? "Type its capital below the map." : "Choose its capital below the map."
        case (.asking, .member): "Answer in or out below the map."
        case (.asking, .listAll): "Type the names below the map. Each one fills in as it’s named. Pinch to zoom."
        default: "Pinch to zoom."
        }
    }

    // MARK: Playing

    /// Swaps in a quiz on another collection, keeping how you like to play, and frames its map.
    private func switchCollection(to id: String) {
        guard id != game.collection.id,
              let collection = MapGame.collections(applying: counting.rules).first(where: { $0.id == id }),
              let quiz = MapGame.make(for: collection, rules: counting.rules)
        else { return }
        clearRound()
        twinkles = []
        worldTurn?.cancel()
        turningMap = nil
        turningLongitude = nil
        let layout = navigator.layout
        let next = MapNavigator(collection: quiz.collection, map: quiz.map)
        next.updateLayout(layout)
        withAnimation(.smooth(duration: 0.45)) {
            game = quiz
            navigator = next
        }
        frameScope(animated: false)
        haptic = GameHaptic(feedback: .selection)
    }

    private func start(_ mode: MapGameMode) {
        clearRound()
        withAnimation(roundChange) {
            game.mode = mode
            game.start()
        }
        roundBegan()
    }

    /// From the results, a round of only the places worth another look, in the same mode.
    private func reviewMisses() {
        clearRound()
        withAnimation(roundChange) { game.startReview() }
        roundBegan()
    }

    /// A round has begun: a thump, and the camera to its first place, or the whole board.
    private func roundBegan() {
        let mode = game.mode
        haptic = GameHaptic(feedback: .impact(weight: .medium))
        // Find starts with the whole board in view, in the room the question card leaves it, rather
        // than wherever the lobby left the camera; from then on the map only moves when you move it.
        guard mode != .findIt else {
            game.holdQuestionClock(for: frameScope())
            return
        }
        // The first question's clock waits for the camera to arrive, and the question itself, so
        // neither eats into it. List All keeps the whole board in view, to watch it fill in.
        let flight = followsQuestion ? frameQuestion() : frameScope()
        lightQuestion(after: flight)
        game.holdQuestionClock(for: max(flight, questionEntrance))
    }

    /// Lights up the place in question as the camera lands on it, or at once where the camera stays
    /// put, so it comes up with its ring on a board that's come to rest, as its clock starts. A
    /// flight has all but come to rest a quarter of a second before its end, so the light starts
    /// then, and is up as the camera settles rather than a beat after.
    private func lightQuestion(after flight: TimeInterval) {
        questionLitAt = lightsQuestion && game.phase == .asking ? .now.addingTimeInterval(max(flight - 0.25, 0)) : nil
    }

    /// How long a question takes to arrive, for its clock to wait on: Flag's flag and Outline's
    /// shape growing in over half a second, four to pick from dealt one after another in about
    /// 0.7, anything else at once; nothing to wait on with Reduce Motion, where they only fade.
    private var questionEntrance: TimeInterval {
        guard !reduceMotion else { return 0 }
        let hero: TimeInterval = game.mode == .flags || game.mode == .outline ? 0.5 : 0
        let dealt: TimeInterval = game.answerMethod == .four ? 0.68 : 0
        return max(hero, dealt)
    }

    /// Brings the camera to the question just come up, as Auto Zoom has it, and holds its clock
    /// until both the camera and the question have arrived. Find leaves the camera where you put it.
    private func frameNewQuestion() {
        var flight: TimeInterval = 0
        if followsQuestion {
            flight = frameQuestion()
        } else if game.mode != .findIt, !isBoardFitted {
            // Nothing on the board to fly to yet, as in Code: the camera pulls back out from the
            // last answer rather than lingering on it.
            flight = frameScope()
        }
        lightQuestion(after: flight)
        game.holdQuestionClock(for: max(flight, questionEntrance))
    }

    /// Where the lobby's Atlas tile leads: the collection's full map, at the first place in the
    /// region or set the quiz was set to, or else at its first. A group of countries, such as the EU
    /// or one of the person's own, stays itself: its own list and its own map, the World zoomed to
    /// its members, with a deck of just its members, starting at its first country in play. Nil
    /// where there's no map to learn on, so the lobby leaves the Atlas out rather than only closing.
    private var learnRequest: LearnDeck.Request? {
        let collection = game.collection
        let inPlay = Set(game.placesInPlay.map(\.id))
        let isNarrowed = game.scopeID != nil || game.placeSetID != nil
        let start = isNarrowed ? collection.divisions.first { inPlay.contains($0.id) }?.id : nil
        if collection.isGroupOfCountries {
            let first = start ?? collection.divisions.first(where: { inPlay.contains($0.id) })?.id ?? collection.divisions.first?.id
            guard let first, TravelMap.named(collection.id) != nil else { return nil }
            return LearnDeck.Request(collectionID: collection.id, placeID: first)
        }
        guard TravelMap.named(collection.id) != nil else { return nil }
        return LearnDeck.Request(collectionID: collection.id, placeID: start)
    }

    /// Learn, from the lobby's tile: the quiz closes, and the collection's full map opens in Learn,
    /// at the first place in the region or set the quiz was set to, or else at its first.
    private func learn() {
        guard !isClosing, let request = learnRequest else { return }
        haptic = GameHaptic(feedback: .impact(weight: .medium))
        isClosing = true
        withAnimation(closingAnimation) {
            isExpanded = false
        } completion: {
            guard !onLearn(request) else { return }
            isClosing = false
            // Back again where there's nothing to learn on, it pops up as it first opened.
            withAnimation(openingAnimation) { isExpanded = true }
        }
    }

    /// Lets go of anything left over from the last round: a pending move on, a mistake still
    /// showing, a place chosen on the map.
    private func clearRound() {
        outlineFlight = nil
        reviewID = nil
        flash = nil
        selection = nil
        selectionDot = nil
        markerStart = nil
        glowStart = nil
        questionLitAt = nil
        lastTap = nil
    }

    /// Answers, the card springing along, and where that settles the question, lights the answer's
    /// glow on the board from this moment, so it comes up rather than appearing.
    private func settling<Result>(_ answer: () -> Result) -> Result {
        let wasAsking = game.phase == .asking
        let result = withAnimation(settle) { answer() }
        if wasAsking, game.phase == .answered { glowStart = .now }
        return result
    }

    /// Lets go of the mistake's name over the map, fading it out rather than dropping it.
    private func clearFlash() {
        guard flash != nil else { return }
        withAnimation(.smooth(duration: 0.2)) { flash = nil }
    }

    /// Answers with a name chosen, or a place tapped in Find. Correct stays on the answer until
    /// Next is pressed; wrong says so, and shows where the wrong place is.
    private func answer(_ place: AdministrativeDivision) {
        guard let current = game.current else { return }
        let result = settling { game.answer(place) }
        let guess = place.displayName(localLanguage: localLanguage)
        selection = nil
        switch result {
        case .right:
            haptic = GameHaptic(feedback: .success)
            announce("Correct! \(spokenAnswerName(of: current)).")
            if [.outline, .code, .dot, .whoseCapital, .pickOutline].contains(game.mode) { showAnswer() }
        case .wrong, .again:
            haptic = GameHaptic(feedback: result == .wrong ? .error : .impact(weight: .light))
            showMistake(place)
            if game.mode == .capitals, let capital = game.capitalName(of: place) {
                announce("Not \(capital). That’s the capital of \(guess).")
            } else {
                announce(game.mode == .findIt ? "That’s \(guess)." : "Not \(guess).")
            }
        case .ignored:
            break
        }
    }

    /// A tap on the board, in Find, chooses a place to confirm, so a slip of the finger doesn't
    /// count, and tapping it again lets it go; a second tap straight after the first answers with
    /// it. With the borders hidden, the place chosen is only marked with a dot where it was tapped,
    /// in Dot's own style, as its outline would show where the borders run: a second tap on the
    /// dot, or anywhere else in the same place, answers with it, and a tap on another place moves
    /// the dot there. A place already tried stays faded, and a tap on it only brings a soft bump
    /// and, for VoiceOver, a reminder.
    private func tap(at location: CGPoint) {
        guard turningMap == nil, game.mode == .findIt, game.phase == .asking else { return }
        let spot = wrapped(location)
        let geometry = navigator.geometry
        // On the dot, or a fingertip from it, the tap means the place the dot marks, whichever
        // side of a hidden border it lands.
        if !game.showsBorders, let selection, let selectionDot {
            let dot = geometry.toScreen(selectionDot)
            if hypot(spot.x - dot.x, spot.y - dot.y) <= MapTap.dotReach {
                answer(selection)
                return
            }
        }
        guard let region = game.map.place(at: spot, geometry: geometry, among: game.scopedRegionIDs),
              let place = game.regionPlaces[region.id]
        else { return }
        guard !game.wrongGuesses.contains(place) else {
            haptic = GameHaptic(feedback: .impact(flexibility: .soft, intensity: 0.5))
            announce("Already tried \(place.displayName(localLanguage: localLanguage)).")
            return
        }
        guard game.showsBorders else {
            if place == selection {
                answer(place)
            } else {
                withAnimation(settle) {
                    selection = place
                    selectionDot = geometry.toMap(spot)
                }
                // The dot drops in where the finger was, swelling a touch and settling with a ring.
                markerStart = .now
                haptic = GameHaptic(feedback: .selection)
            }
            return
        }
        let thisTap = MapTap(placeID: place.id, date: .now)
        defer { lastTap = thisTap }
        if let lastTap, lastTap.placeID == place.id,
           thisTap.date.timeIntervalSince(lastTap.date) < MapTap.doubleTapInterval {
            answer(place)
            return
        }
        withAnimation(settle) { selection = selection == place ? nil : place }
        // The place chosen glows up and sends a ring out, as the dot lands where borders are hidden.
        if selection != nil { glowStart = .now }
        haptic = GameHaptic(feedback: .selection)
    }

    /// A point on any copy of the wrapping World, moved onto the copy the map's places are on.
    private func wrapped(_ location: CGPoint) -> CGPoint {
        guard let wrapPeriod, let edge = game.map.outline?.boundingRect.minX else { return location }
        let geometry = navigator.geometry
        var point = geometry.toMap(location)
        point.x = edge + (point.x - edge).truncatingRemainder(dividingBy: wrapPeriod)
        if point.x < edge { point.x += wrapPeriod }
        return geometry.toScreen(point)
    }

    /// The World's width, for wrapping it around as it's dragged sideways. Only a rectangular
    /// World meets itself at its edges.
    private var wrapPeriod: CGFloat? {
        guard game.collection.isOnWorldMap, !game.map.isSphere,
              let outline = game.map.outline?.boundingRect, outline.width > outline.height
        else { return nil }
        return outline.width
    }

    /// Answers with a typed name, or in Capital, a typed capital. Typed out in full as another place
    /// in play, it shows where that place is, as a wrong pick does.
    private func answer(typed: String) {
        guard let place = game.current else { return }
        let result = settling { game.answer(typed: typed) }
        switch result {
        case .right:
            haptic = GameHaptic(feedback: .success)
            let answer = spokenAnswerName(of: place)
            if let correction = game.correction {
                announce("Correct! \(answer). It’s spelt \(correction).")
            } else {
                announce("Correct! \(answer).")
            }
            if [.outline, .code, .dot, .whoseCapital].contains(game.mode) { showAnswer() }
        case .other(let other), .again(let other):
            if case .other = result {
                haptic = GameHaptic(feedback: .error)
            } else {
                haptic = GameHaptic(feedback: .impact(weight: .light))
            }
            showMistake(other)
            let name = other.displayName(localLanguage: localLanguage)
            announce(game.mode == .capitals ? "That’s the capital of \(name)." : "Not \(name).")
        case .decoy(let city):
            haptic = GameHaptic(feedback: .error)
            announce("\(city) is in \(place.displayName(localLanguage: localLanguage)), but it isn’t the capital.")
        case .wrong:
            haptic = GameHaptic(feedback: .error)
            announce("Incorrect.")
        case .ignored:
            break
        }
    }

    /// In Member?, answers in or out. Either way the question's settled, and the country lights up
    /// in the colour it went.
    private func answer(isMember guess: Bool) {
        guard let place = game.current else { return }
        let result = settling { game.answer(isMember: guess) }
        let name = place.displayName(localLanguage: localLanguage)
        let group = game.groupNameInSentence ?? game.collection.name
        let fact = game.isMember(place) ? "\(name) is in \(group)." : "\(name) isn’t in \(group)."
        switch result {
        case .right:
            haptic = GameHaptic(feedback: .success)
            announce("Correct! \(fact)")
        case .wrong:
            haptic = GameHaptic(feedback: .error)
            announce("Incorrect. \(fact)")
        case .again, .ignored:
            break
        }
    }

    /// In Capital, picks a well-known city in the place that isn't its capital: wrong, gently.
    private func answer(decoy city: String) {
        guard let place = game.current else { return }
        let result = withAnimation(settle) { game.answer(decoy: city) }
        guard result == .wrong else { return }
        haptic = GameHaptic(feedback: .error)
        announce("\(city) is in \(place.displayName(localLanguage: localLanguage)), but it isn’t the capital.")
    }

    /// Every one of a place's capitals, such as "Pretoria, Cape Town and Bloemfontein".
    private func capitalNames(of place: AdministrativeDivision) -> String {
        (game.capitals[place.id] ?? []).map(\.name).formatted(.list(type: .and))
    }

    /// The answer as VoiceOver says it's right: the place's name, or its capitals, or its code.
    private func spokenAnswerName(of place: AdministrativeDivision) -> String {
        switch game.mode {
        case .capitals: capitalNames(of: place)
        case .pickCode: game.code(of: place).map(CodeBadge.spoken) ?? place.displayName(localLanguage: localLanguage)
        default: place.displayName(localLanguage: localLanguage)
        }
    }

    private func reveal() {
        guard let place = game.current else { return }
        settling { game.reveal() }
        haptic = GameHaptic(feedback: .impact(weight: .light))
        announce(spokenAnswer(for: place))
        showAnswer()
    }

    /// The answer as VoiceOver tells it when it's shown: the place, or in Member?, whether it's in.
    private func spokenAnswer(for place: AdministrativeDivision) -> String {
        let name = place.displayName(localLanguage: localLanguage)
        guard game.mode == .member else { return "It’s \(name)." }
        let group = game.groupNameInSentence ?? game.collection.name
        return game.isMember(place) ? "\(name) is in \(group)." : "\(name) isn’t in \(group)."
    }

    /// Names a place in List All from what's typed, the moment it's spelt out in full: it fills in
    /// on the map with a soft tap, and naming the last one ends the round.
    private func name(listAll typed: String) -> AdministrativeDivision? {
        guard let place = withAnimation(settle, { game.answer(listAll: typed) }) else { return nil }
        let name = place.displayName(localLanguage: localLanguage)
        if game.phase == .finished {
            haptic = finishedHaptic
            announce("\(name). That’s all \(game.questions.count)!")
        } else {
            haptic = GameHaptic(feedback: .impact(flexibility: .soft, intensity: 0.7))
            announce("\(name). \(game.named.count) of \(game.questions.count).")
        }
        return place
    }

    /// Gives up on List All: the places not named are shown, and the round's over.
    private func giveUp() {
        withAnimation(roundChange) { game.giveUp() }
        haptic = finishedHaptic
        frameScope()
        announce("\(game.rightCount) of \(game.questions.count) named.")
    }

    /// Leaves this question for later: whatever was in hand is let go, and the next one comes up,
    /// the camera flying to it as Next would.
    private func skip() {
        guard game.canSkip else { return }
        clearFlash()
        selection = nil
        lastTap = nil
        withAnimation(.swap(reduceMotion: reduceMotion)) { game.skip() }
        haptic = GameHaptic(feedback: .impact(flexibility: .soft, intensity: 0.6))
        announce("Skipped. It comes back at the end.")
        frameNewQuestion()
    }

    private func next() {
        clearFlash()
        selection = nil
        lastTap = nil
        // A shape still landing from the last question stays with it.
        outlineFlight = nil
        // One question gives way to the next in its slot; the last gives way to the results as
        // giving up or running out of time does.
        let into: Animation = game.isLastQuestion ? roundChange : .swap(reduceMotion: reduceMotion)
        withAnimation(into) { game.advance() }
        switch game.phase {
        case .asking:
            frameNewQuestion()
        case .finished:
            frameScope()
            haptic = finishedHaptic
            announce("Round over: \(game.rightCount) of \(game.questions.count) right first time.")
        case .lobby, .answered:
            break
        }
    }

    private func backToLobby() {
        clearRound()
        withAnimation(roundChange) { game.returnToLobby() }
        frameScope()
    }

    /// Escape goes back a step: out of a tile to the quizzes, out of a round to the quizzes, asking
    /// first where some of it has been played, or out of the quiz.
    private func back() {
        if game.phase == .lobby {
            if openTile != nil { openTile = nil } else { close() }
        } else if hasProgress {
            isConfirmingEnd = true
        } else {
            backToLobby()
        }
    }

    /// Whether a round under way has been partly played, so leaving it would lose something.
    private var hasProgress: Bool {
        (game.phase == .asking || game.phase == .answered) && (game.index > 0 || !game.named.isEmpty)
    }

    /// Lights up a place from the results again, flying to it with Auto Zoom on.
    private func review(_ place: AdministrativeDivision) {
        withAnimation(settle) { reviewID = place.id }
        glowStart = .now
        haptic = GameHaptic(feedback: .selection)
        if autoZoom { whole(place.id) { fly(to: $0, margin: 2.2) } }
    }

    // MARK: The camera

    /// The place the camera keeps framed while Auto Zoom is on: the place in question in Identify,
    /// Capital and Dot, and the answer once it's given in Outline and Code too.
    private var followedPlace: AdministrativeDivision? {
        guard autoZoom else { return nil }
        switch game.phase {
        case .asking: return [.nameIt, .capitals, .dot, .member, .pickFlag, .pickCode, .everything].contains(game.mode) ? game.current : nil
        case .answered:
            let followed: [MapGameMode] = [
                .nameIt, .capitals, .dot, .outline, .code, .member, .pickFlag, .whoseCapital, .everything, .pickOutline, .pickCode,
            ]
            return followed.contains(game.mode) ? game.current : nil
        case .lobby, .finished: return nil
        }
    }

    /// How much room to leave around the place framed: in Dot, a generous area around the dot,
    /// so its surroundings help; otherwise close enough to see the smallest place.
    private var cameraMargin: CGFloat {
        game.mode == .dot && game.phase == .asking ? 3.5 : 2.2
    }

    /// With Auto Zoom on, Identify, Capital, Dot, Member?, Flag's Find and Everything fly to each place in turn. Returns
    /// about how long the camera takes to get there, the World's turn included.
    @discardableResult
    private func frameQuestion() -> TimeInterval {
        guard followsQuestion, let place = game.current else { return 0 }
        let turning = turnDuration(to: game.wholeLongitude(for: place.id) ?? game.centerLongitude)
        let flying = game.frames[place.id].map(flightDuration(to:)) ?? 0
        whole(place.id) { fly(to: $0, margin: cameraMargin) }
        return turning + flying
    }

    /// Whether the camera flies to each question's place: with Auto Zoom on, where the place is lit
    /// up or marked on the board while it's asked about.
    private var followsQuestion: Bool {
        autoZoom && [.nameIt, .capitals, .dot, .member, .pickFlag, .pickCode, .everything].contains(game.mode)
    }

    /// How long the World takes to turn to a new middle, as `turnWorld` turns it.
    private func turnDuration(to longitude: Double) -> TimeInterval {
        let degrees = MapJourney.turn(from: turningLongitude ?? game.centerLongitude, to: longitude)
        return reduceMotion || degrees == 0 ? 0 : 0.35 + abs(degrees) / 180 * 0.55
    }

    /// How long `fly(to:margin:)` takes from where the camera is now: straight there, or out and back in.
    private func flightDuration(to frame: CGRect) -> TimeInterval {
        guard !reduceMotion else { return 0 }
        let geometry = navigator.geometry
        let area = geometry.fitArea
        let corner = geometry.toMap(CGPoint(x: area.minX, y: area.minY))
        let opposite = geometry.toMap(CGPoint(x: area.maxX, y: area.maxY))
        let inView = CGRect(
            x: min(corner.x, opposite.x), y: min(corner.y, opposite.y),
            width: abs(opposite.x - corner.x), height: abs(opposite.y - corner.y))
        return navigator.camera.zoom > 1.01 && !inView.intersects(frame) ? 1.2 : 0.9
    }

    /// The card changes height as a question comes and goes, which changes the room left for the
    /// map. Once it settles, and any flight under way has landed, so a flight in two legs is never
    /// cut off partway, the place being followed is framed again in the room there now is, or a
    /// board fitted to the screen is fitted again, unless it's been moved by hand since, Find's
    /// included, as its round starts.
    private func reframeOnceTheCardSettles() {
        pendingReframe?.cancel()
        pendingReframe = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            // A flight may be followed by another as it lands, so wait until none is under way.
            while !Task.isCancelled, flightEnds.timeIntervalSinceNow > 0 {
                try? await Task.sleep(for: .seconds(flightEnds.timeIntervalSinceNow + 0.02))
            }
            guard !Task.isCancelled else { return }
            if let place = followedPlace, outlineFlight == nil {
                // A reframe is a flight of its own: any leg of an earlier one still to come stands down.
                flights += 1
                isBoardFitted = false
                whole(place.id) { navigator.frame($0, margin: cameraMargin, animation: reduceMotion ? nil : .smooth(duration: 0.5)) }
            } else if isBoardFitted {
                frameScope()
            }
        }
    }

    /// Turning Auto Zoom on flies to the place in view; turning it off fits the board back on the
    /// screen, where places only light up. Find keeps the camera where you put it either way.
    private func followAutoZoom() {
        haptic = GameHaptic(feedback: .selection)
        guard !isFindingRound, !isFlagRound else { return }
        switch game.phase {
        case .asking, .answered:
            if !autoZoom {
                if followsPlaces { frameScope() }
            } else if let place = followedPlace {
                whole(place.id) { fly(to: $0, margin: cameraMargin) }
            }
        case .finished:
            if !autoZoom {
                frameScope()
            } else if let reviewID {
                whole(reviewID) { fly(to: $0, margin: 2.2) }
            }
        case .lobby:
            break
        }
    }

    /// Shows the places in play as large as they'll go: the chosen group, or the map filling the
    /// screen, with the World turned back home first if it was turned.
    @discardableResult
    private func frameScope(animated: Bool = true) -> TimeInterval {
        defer {
            flights += 1
            isBoardFitted = true
        }
        let duration = animated ? turnDuration(to: game.homeLongitude) + (reduceMotion ? 0 : 0.8) : 0
        flightEnds = .now.addingTimeInterval(duration)
        turnWorld(to: game.homeLongitude, instantly: !animated) {
            let animation: Animation? = animated && !reduceMotion ? .smooth(duration: 0.8) : nil
            if let frame = game.scopeFrame {
                navigator.frame(frame, margin: 0.04, animation: animation)
            } else {
                withAnimation(animation) { navigator.camera = navigator.fillingCamera }
            }
        }
        return duration
    }

    /// Hands over a place's frame once it sits whole: straight away where it already does, or once
    /// the World has turned so the map's edge no longer cuts it in two. Places after it that sit
    /// whole too leave the World where it is.
    private func whole(_ placeID: String, instantly: Bool = false, then focus: @escaping (CGRect) -> Void) {
        let target = game.wholeLongitude(for: placeID) ?? game.centerLongitude
        // The turn is part of the journey: nothing reframes the board until it's done.
        if !instantly { flightEnds = max(flightEnds, .now.addingTimeInterval(turnDuration(to: target))) }
        turnWorld(to: target, instantly: instantly) {
            if let frame = game.frames[placeID] { focus(frame) }
        }
    }

    /// Turns the World beneath the camera to a new middle, as the list's map does before diving
    /// into a country: smoothly, redrawn light at every step, then settled in full detail, after
    /// which `then` runs. With Reduce Motion, or `instantly`, it simply settles there.
    private func turnWorld(to longitude: Double, instantly: Bool = false, then: @escaping () -> Void) {
        let from = turningLongitude ?? game.centerLongitude
        let degrees = MapJourney.turn(from: from, to: longitude)
        guard degrees != 0 || turningLongitude != nil else {
            then()
            return
        }
        worldTurn?.cancel()
        worldTurn = Task { @MainActor in
            if !reduceMotion, !instantly, degrees != 0 {
                let duration = 0.35 + abs(degrees) / 180 * 0.55
                let start = Date.now
                while !Task.isCancelled {
                    let progress = min(Date.now.timeIntervalSince(start) / duration, 1)
                    let eased = progress * progress * (3 - 2 * progress)
                    let step = MapJourney.normalized(from + degrees * eased)
                    turningLongitude = step
                    turningMap = Geography.world?.turningMap(.mercator, centerLongitude: step)
                    if progress >= 1 { break }
                    try? await Task.sleep(for: .milliseconds(16))
                }
                // Another turn has taken over, from wherever this one reached.
                guard !Task.isCancelled else { return }
            }
            game.settleTurn(at: longitude)
            turningMap = nil
            turningLongitude = nil
            then()
        }
    }

    /// The camera was moved by hand, so the board is no longer fitted for it. In the lobby, a
    /// twinkling that's come to rest starts again.
    private func movedByHand() {
        if isBoardFitted { isBoardFitted = false }
        if twinklesRest, game.phase == .lobby {
            twinklesRest = false
            lobbyNudges += 1
        }
    }

    /// Whether this round's camera follows places, as every mode but Find and Flag does.
    private var followsPlaces: Bool {
        game.mode != .findIt && game.mode != .flags && game.mode != .listAll
    }

    /// Brings the answer into view with Auto Zoom on. Outline's shape flies into its place; Find
    /// only slides the map across, keeping the zoom you chose.
    private func showAnswer() {
        guard let place = game.current, game.frames[place.id] != nil else { return }
        if game.mode == .outline {
            // The board is out of sight behind the shape, so the World can simply be turned already.
            whole(place.id, instantly: true) { _ in landOutline(place) }
            return
        }
        guard game.mode == .findIt else {
            // At the margin the board keeps the place followed in, so a reframe as the card
            // settles doesn't nudge the zoom again straight after.
            if autoZoom { whole(place.id) { fly(to: $0, margin: cameraMargin) } }
            return
        }
        whole(place.id) { frame in
            flights += 1
            isBoardFitted = false
            flightEnds = .now.addingTimeInterval(reduceMotion ? 0 : 0.7)
            let center = CGPoint(x: frame.midX, y: frame.midY)
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.7)) {
                navigator.camera = navigator.geometry.camera(centering: center, zoom: navigator.camera.zoom)
            }
        }
    }

    /// Outline's moment: the shape, turned upright if it came at an angle, flies and shrinks into
    /// its real place on the board as the map fades in around it, taking the colour the answer
    /// went, then gives way to the board. With Reduce Motion the map simply fades in, framed.
    private func landOutline(_ place: AdministrativeDivision) {
        let frameBoard = {
            if autoZoom, let frame = game.frames[place.id] {
                flights += 1
                isBoardFitted = false
                navigator.frame(frame, margin: 2.2, animation: nil)
            } else {
                frameScope(animated: false)
            }
        }
        guard !reduceMotion, let path = game.outline(of: place), !outlineBox.isEmpty else {
            frameBoard()
            return
        }
        let flight = OutlineFlight(
            placeID: place.id, path: path, frame: outlineBox, rotation: game.rotations[place.id] ?? 0, color: game.mode.color)
        outlineFlight = flight
        Task { @MainActor in
            // A moment for the board to come back and learn its size, then the camera is set
            // before the map shows, and the shape heads for where the place now is.
            try? await Task.sleep(for: .milliseconds(60))
            guard outlineFlight?.id == flight.id else { return }
            frameBoard()
            guard let core = game.frames[place.id] else {
                outlineFlight = nil
                return
            }
            let target = core.applying(navigator.geometry.transform)
            let landed = game.outcomes[place.id].map { MapGame.level(for: $0).color } ?? game.mode.color
            withAnimation(.smooth(duration: 0.9)) {
                outlineFlight?.frame = target
                outlineFlight?.rotation = 0
                outlineFlight?.stretch = 1
                outlineFlight?.color = landed
            } completion: {
                withAnimation(.easeOut(duration: 0.4)) {
                    outlineFlight?.opacity = 0
                } completion: {
                    if outlineFlight?.id == flight.id { outlineFlight = nil }
                }
            }
        }
    }

    /// Flies the camera to part of the board: straight there when it's in view, otherwise pulling
    /// back first to take in both ends of the journey, then coming down on the place.
    private func fly(to frame: CGRect, margin: CGFloat) {
        flights += 1
        isBoardFitted = false
        flightEnds = .now.addingTimeInterval(flightDuration(to: frame))
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

    /// Flashes a place answered by mistake red, with its name beside it; in Capitals, with the
    /// capital that was picked, such as "Nairobi, Kenya".
    private func showMistake(_ place: AdministrativeDivision) {
        let regionIDs = game.mainRegions(of: place.id)
        guard let region = regionIDs.first.flatMap({ game.map.region(id: $0) }) else { return }
        let name = place.displayName(localLanguage: localLanguage)
        let capital = game.mode == .capitals ? game.capitalName(of: place) : nil
        let mistake = GameFlash(
            regionIDs: regionIDs, name: capital.map { "\($0), \(name)" } ?? name,
            language: capital == nil ? place.language(of: name) : nil, flagAssetName: place.flagAssetName,
            anchor: region.center)
        withAnimation(.bouncy(duration: 0.35)) { flash = mistake }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(GameFlash.duration))
            guard flash?.id == mistake.id else { return }
            withAnimation(.smooth(duration: 0.3)) { flash = nil }
        }
    }

    /// In the lobby, places in view light up in candy colours, as a taste of the quiz, each with its
    /// name floating beside it: one after another, and on a big map several at once, staggered and
    /// spread well apart. After half a minute they come to rest, until the map's moved or other
    /// places or a region are chosen; in Low Power Mode, with Reduce Motion, or with the app in
    /// the background, they don't twinkle at all.
    private func twinkleWhileWaiting() async {
        twinkles = []
        twinklesRest = false
        guard game.phase == .lobby, isExpanded, allowsAmbientMotion else { return }
        let colors = MapGameMode.allCases.map(\.color).shuffled()
        var count = 0
        try? await Task.sleep(for: .seconds(0.6))
        let restsAt = Date.now.addingTimeInterval(Self.twinklingTime)
        while !Task.isCancelled, Date.now < restsAt {
            let now = Date.now
            twinkles.removeAll { ($0.start ?? now).addingTimeInterval(GameSpotlight.twinkleDuration) <= now }
            let geometry = navigator.geometry
            // Places in the clear part of the view, so neither the place nor its name hides under the card.
            let clear = geometry.fitArea
            let inView = game.placesInPlay.compactMap { place -> (place: AdministrativeDivision, center: CGPoint)? in
                guard let frame = game.frames[place.id]?.applying(geometry.transform),
                      max(frame.width, frame.height) >= 12 else { return nil }
                let center = CGPoint(x: frame.midX, y: frame.midY)
                return clear.contains(center) ? (place, center) : nil
            }
            // More at once the more there is to see: up to seven on the World.
            let most = min(max(inView.count / 8, 1), 7)
            let lit = twinkles.compactMap { twinkle in
                twinkle.caption.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY).applying(geometry.transform) }
            }
            let apart = max(min(clear.width, clear.height) * 0.22, 70)
            let candidates = inView.filter { candidate in
                !twinkles.contains { $0.regionIDs.contains(candidate.place.id) }
                    && lit.allSatisfy { hypot($0.x - candidate.center.x, $0.y - candidate.center.y) >= apart }
            }
            if twinkles.count < most, let pick = candidates.randomElement() {
                let place = pick.place
                let name = place.displayName(localLanguage: localLanguage)
                let caption = GameSpotlight.Caption(
                    name: name, language: place.language(of: name),
                    flagAssetName: game.hasOwnFlag(place) ? place.flagAssetName : nil, frame: game.frames[place.id] ?? .zero)
                twinkles.append(GameSpotlight(
                    regionIDs: game.mainRegions(of: place.id), style: .twinkle, color: colors[count % colors.count],
                    mainBody: game.mainBody(of: place.id), caption: caption, start: .now))
                count += 1
            }
            // Staggered, so they come and go one after another rather than all together.
            try? await Task.sleep(for: .seconds(most > 1 ? GameSpotlight.twinkleDuration / Double(most) + 0.15 : GameSpotlight.twinkleDuration + 0.25))
        }
        // At rest: the last ones fade out, then the board has nothing left to draw them for.
        try? await Task.sleep(for: .seconds(GameSpotlight.twinkleDuration))
        guard !Task.isCancelled else { return }
        twinkles = []
        twinklesRest = true
    }

    /// How long the lobby twinkles before it comes to rest.
    private static let twinklingTime: TimeInterval = 30

    /// Waits a moment for the board to learn its size, fills the screen with the map, then pops it up.
    private func open() async {
        try? await Task.sleep(for: .milliseconds(30))
        frameScope(animated: false)
        withAnimation(openingAnimation) {
            isExpanded = true
        }
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(closingAnimation) {
            isExpanded = false
        } completion: {
            onClose()
        }
    }

    /// How the quiz moves on from one part to the next, the lobby, a round and its results, the
    /// glass reshaping around each: a candy bounce, or with Reduce Motion, a short fade, so nothing
    /// overshoots.
    private var roundChange: Animation {
        Motion.moving(.bouncy(duration: 0.5), reduceMotion: reduceMotion)
    }

    /// How an answer, a place chosen or one looked at again settles in, the card springing along:
    /// a snappy spring, or with Reduce Motion, a short fade.
    private var settle: Animation {
        Motion.moving(.snappy, reduceMotion: reduceMotion)
    }

    /// How the quiz pops up, as it opens and as it comes back from a Learn with nowhere to go: a
    /// lively spring, or with Reduce Motion, a short fade.
    private var openingAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.25) : .bouncy(duration: 0.6, extraBounce: 0.12)
    }

    /// How it drops away as it closes, or leaves for Learn: smoothly, or with Reduce Motion, a short fade.
    private var closingAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.25) : .smooth(duration: 0.4)
    }

    /// Counts down a round against the clock: VoiceOver hears a minute, thirty seconds and ten
    /// seconds left, the last ten tick softly, and at nought the round ends with the places not
    /// yet answered shown. Leaving the round stops it.
    private func countDown() async {
        guard let deadline = game.deadline else { return }
        while !Task.isCancelled {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else {
                runOutOfTime()
                return
            }
            let seconds = Int(remaining.rounded(.up))
            switch seconds {
            case 60: announce("One minute left.")
            case 30: announce("Thirty seconds left.")
            case 10: announce("Ten seconds left.")
            default: break
            }
            if seconds <= 10 {
                haptic = GameHaptic(feedback: .impact(flexibility: .soft, intensity: 0.45))
            }
            // Wake on the next whole second.
            let fraction = remaining - remaining.rounded(.down)
            try? await Task.sleep(for: .seconds(fraction > 0.02 ? fraction : 1))
        }
    }

    /// Counts down a question against the clock: its last three seconds tick softly, VoiceOver
    /// hears five seconds left, once, where there was longer than that to begin with, and at nought
    /// the answer is shown, waiting on Next. An answer, or leaving the round, stops it.
    private func countDownQuestion() async {
        guard let deadline = game.questionDeadline else { return }
        let total = deadline.timeIntervalSinceNow
        while !Task.isCancelled {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else {
                questionTimeRanOut()
                return
            }
            let seconds = Int(remaining.rounded(.up))
            if seconds == 5, total > 5.5 { announce("Five seconds left.") }
            if seconds <= 3 {
                haptic = GameHaptic(feedback: .impact(flexibility: .soft, intensity: 0.4))
            }
            let fraction = remaining - remaining.rounded(.down)
            try? await Task.sleep(for: .seconds(fraction > 0.02 ? fraction : 1))
        }
    }

    /// This question's time is up: the answer's shown, as Reveal shows it, and Next waits.
    private func questionTimeRanOut() {
        guard game.phase == .asking, let place = game.current else { return }
        selection = nil
        clearFlash()
        settling { game.runOutOfQuestionTime() }
        haptic = GameHaptic(feedback: .warning)
        announce("Time’s up. \(spokenAnswer(for: place))")
        showAnswer()
    }

    /// Time's up: the round ends, the places not answered shown, and the board comes back into view.
    private func runOutOfTime() {
        guard game.phase == .asking || game.phase == .answered else { return }
        selection = nil
        clearFlash()
        withAnimation(roundChange) { game.runOutOfTime() }
        haptic = finishedHaptic
        frameScope()
        announce("Time’s up. \(game.rightCount) of \(game.questions.count) \(game.mode == .listAll ? "named" : "right first time").")
    }

    private func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }

    /// The round's end, felt: a heavy thump, firmer the more answers were right first time.
    private var finishedHaptic: GameHaptic {
        let score = game.questions.isEmpty ? 0 : Double(game.rightCount) / Double(game.questions.count)
        return GameHaptic(feedback: .impact(weight: .heavy, intensity: 0.45 + 0.55 * score))
    }
}

/// Outline's shape on its way from the question into its place on the board.
private struct OutlineFlight: Identifiable {
    var id = UUID()
    var placeID: String
    var path: Path
    /// Where it is, in global coordinates.
    var frame: CGRect
    /// Its turn, in degrees, from the angle it came at back to upright.
    var rotation: Double
    var color: Color
    /// From 0, the shape true to its proportions, to 1, stretched to the place's box on the board.
    var stretch: CGFloat = 0
    var opacity: Double = 1
}

/// A place's outline, kept within a unit square, drawn in any rect: fitted there whole, true to its
/// proportions, or as `stretch` runs to 1, stretched to fill it, as the board's projection draws it.
struct OutlineShape: Shape {
    var unit: Path
    var stretch: CGFloat = 0

    var animatableData: CGFloat {
        get { stretch }
        set { stretch = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let fitted = CGAffineTransform(a: side, b: 0, c: 0, d: side, tx: rect.midX - side / 2, ty: rect.midY - side / 2)
        let bounds = unit.boundingRect
        guard stretch > 0, bounds.width > 0, bounds.height > 0 else { return unit.applying(fitted) }
        let scaleX = rect.width / bounds.width
        let scaleY = rect.height / bounds.height
        let filled = CGAffineTransform(
            a: scaleX, b: 0, c: 0, d: scaleY, tx: rect.minX - bounds.minX * scaleX, ty: rect.minY - bounds.minY * scaleY)
        func mix(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * stretch }
        return unit.applying(CGAffineTransform(
            a: mix(fitted.a, filled.a), b: 0, c: 0, d: mix(fitted.d, filled.d),
            tx: mix(fitted.tx, filled.tx), ty: mix(fitted.ty, filled.ty)))
    }
}

/// Outline's question: a place's shape alone, filled in a soft candy tone with a crisp white edge
/// and a soft shadow, turned at an angle when Rotated is on.
private struct OutlineHero: View {
    var path: Path
    var color: Color
    var rotation: Double
    var accessibilityLabel: String

    var body: some View {
        ZStack {
            OutlineShape(unit: path)
                .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .top, endPoint: .bottom))
            OutlineShape(unit: path)
                .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))
        }
        .rotationEffect(.degrees(rotation))
        .shadow(color: color.opacity(0.35), radius: 18, y: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
    }
}

private struct GameHaptic: Equatable {
    var id = UUID()
    var feedback: SensoryFeedback
}

/// A tap on a place in Find, kept to tell a double tap from two single ones; and with the borders
/// hidden, how close to the dot a tap must come to be a second tap on it.
private struct MapTap {
    var placeID: String
    var date: Date

    /// How soon a second tap on the same place must follow the first to answer with it.
    static let doubleTapInterval: TimeInterval = 0.35
    /// With the borders hidden, how near the dot a second tap must land, in points, to answer with
    /// the place it marks: about a fingertip's breadth either side of it.
    static let dotReach: CGFloat = 30
}

/// A flag set large in Flags, still, in its true shape with nothing around it, that gives a little
/// pop once you've named it.
private struct FlagHero: View {
    var place: AdministrativeDivision
    var isRight: Bool

    var body: some View {
        Image(place.flagAssetName)
            .resizable()
            .scaledToFit()
            .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
            .pop(on: isRight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("A flag")
    }
}

/// Content at its own height while it fits, scrolling within the room there is when it doesn't,
/// as on a short screen such as iPhone on its side or iPhone Duo's outer display standing in a
/// tent, so a card never runs off the top of the screen.
private struct FittedScroll<Content: View>: View {
    var maxHeight: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        // A scroll view's own height is its content's; capped, it hugs short content and scrolls tall.
        ScrollView {
            content
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: maxHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// What the lobby's twinkling runs for: whether it may, and the places, region and nudges that
/// start it afresh.
private struct TwinkleRun: Hashable {
    var isOn: Bool
    var collectionID: String
    var scopeID: String?
    var nudges: Int
}
