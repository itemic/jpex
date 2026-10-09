import SwiftUI

/// The map quiz: a collection's map pops up as a board to quiz yourself on. Identify lights up a
/// place to name, typed or picked; Flag shows a flag to name; Find names a place for you to tap;
/// and Capital asks for a place's capital. With Auto Zoom on, the camera flies close enough to each
/// place to see even the smallest; with it off, the whole board stays in view and places only light
/// up. Only a country's main body lights up, never its far-flung territories. Answers colour the
/// board as you go, and a wrong one just says so. Learn browses every place instead, as a row of
/// glass cards to swipe through, the map lighting up each in turn. The map fills the screen and can
/// be dragged past its edges; the World wraps around as you drag it sideways. Flag sets each flag
/// large and waving over the names instead of the map. On iPhone Duo the map carries on under both
/// sides of the fold, the camera keeping to the far side, and the card sits on the near side, above
/// the keyboard when it's up. Before the camera settles on a country the World's edge would cut in
/// two, such as Russia or Fiji, the World turns beneath it so the country sits whole, and turns
/// back home when the whole board comes back into view. Groups of countries, such as the EU, play on the World map with the
/// countries outside them veiled, and add Member?, asking whether a country lit up is in or out.
struct GameScreen: View {
    var onClose: () -> Void
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("localLanguage") private var localLanguage = false
    /// Whether the camera flies to each place in turn, or keeps the whole board in view.
    @AppStorage(MapGame.autoZoomKey) private var autoZoom = true
    /// The quiz under way, replaced when another set of places is chosen.
    @State private var game: MapGame
    @State private var navigator: MapNavigator
    @State private var isExpanded = false
    @State private var isClosing = false
    @State private var panelFrame: CGRect = .zero
    @State private var flash: GameFlash?
    /// Places twinkling in the lobby, each lighting up and fading in turn.
    @State private var twinkles: [GameSpotlight] = []
    /// A place from the results being looked at again.
    @State private var reviewID: String?
    /// In Find, the place tapped on the map, waiting to be confirmed.
    @State private var selection: AdministrativeDivision?
    /// In Find, the last place tapped and when, so a second tap straight after answers with it.
    @State private var lastTap: MapTap?
    /// Counts camera flights, so a flight in two legs can tell when another has taken over.
    @State private var flights = 0
    /// Whether the board is fitted to the places in play and hasn't been moved since, so it can be
    /// fitted again as the room for it changes.
    @State private var isBoardFitted = false
    @State private var haptic: GameHaptic?
    /// Whether the map has pulled out to the whole board while Learn's scrubber is dragged.
    @State private var isScrubbingOut = false
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
    /// The Learns opened into from another's, such as Japan's prefectures from the World's Japan,
    /// newest last, each with the place it was opened from, for going back to it.
    @State private var learnTrail: [LearnStop] = []

    init(game: MapGame, onClose: @escaping () -> Void) {
        self.onClose = onClose
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
            .toolbarTitleMenu { collectionPicker }
            // The bar is always there, so the room it takes never changes under the board as the
            // quiz opens; only its buttons fade in.
            .toolbar { toolbar }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        }
        .overlay { flightLayer }
        .task { await open() }
        .onChange(of: game.scopeID) { frameScope() }
        .onChange(of: game.placeSetID) { frameScope() }
        .onChange(of: panelFrame.minY) { reframeOnceTheCardSettles() }
        .onChange(of: panelFrame.minX) { reframeOnceTheCardSettles() }
        .onChange(of: autoZoom) { followAutoZoom() }
        .task(id: game.phase == .lobby && isExpanded) { await twinkleWhileWaiting() }
        .task(id: game.deadline) { await countDown() }
        .task(id: game.questionDeadline) { await countDownQuestion() }
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
            mapArrangement(size: size, origin: origin, fold: fold)
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
    private func mapArrangement(size: CGSize, origin: CGPoint, fold: FoldRegions?) -> some View {
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
                columnWidth: columnWidth(for: size))
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
        .animation(.bouncy(duration: 0.5), value: place.id)
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
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .opacity))
            }
            questionBesideHero(bottomInset: reachesFoot ? bottomInset : 0, height: cardRect.height)
                .frame(maxWidth: 600)
                .frame(width: cardRect.width, height: cardRect.height, alignment: .top)
                .position(x: cardRect.midX, y: cardRect.midY)
        }
        .opacity(isExpanded ? 1 : 0)
        .animation(.bouncy(duration: 0.5), value: place.id)
    }

    /// The question card beside or below a hero. A list of names fills its room and scrolls itself;
    /// anything else keeps to its own height, and scrolls only where the room runs short, as on a
    /// short screen such as iPhone Duo's outer display on its side.
    @ViewBuilder
    private func questionBesideHero(bottomInset: CGFloat, height: CGFloat) -> some View {
        let card = GameQuestionCard(
            game: game, localLanguage: localLanguage, isRoomy: true, selection: nil, onAnswer: answer,
            onTyped: answer(typed:), onDecoy: answer(decoy:), onReveal: reveal, onNext: next,
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
            ringed: isFindingRound ? game.openRegionIDs.subtracting(tried) : [], tried: tried, plain: plainRegionIDs,
            // Lights keep to places as they rest, so they wait while the World turns beneath them.
            spotlights: turningMap == nil ? spotlights : [], flash: turningMap == nil ? flash : nil, wrapPeriod: wrapPeriod,
            isExpanded: isExpanded, tapsAnswer: isFindingRound || game.phase == .learning, panelFrame: panelFrame,
            farSide: farSide,
            accessibilityLabel: mapLabel, accessibilityValue: mapValue, accessibilityHint: mapHint, onTap: tap(at:),
            onMove: movedByHand)
    }

    /// The card over the board. Learn brings its own row of glass cards, spanning its side of the
    /// screen so the cards either side can peek in; everything else sits in one glass panel.
    private func panel(
        isSeparate: Bool, isBeside: Bool, isTall: Bool, height: CGFloat, columnWidth: CGFloat
    ) -> some View {
        let isAnswering = game.phase == .asking || game.phase == .answered
        // Beside the map, a list of names to pick from takes the column's full height.
        let fillsColumn = isBeside && isAnswering && game.answerMethod == .list
        // A list of names scrolls itself; every other card keeps to its own height, and scrolls
        // within the glass only where the screen is too short for it, rather than running off the top.
        let fitsItself = isAnswering && game.answerMethod == .list
        return ZStack(alignment: .bottom) {
            if game.phase == .learning {
                // Learn keeps within the height there is: beside the map or on the near side of the
                // fold, all of it; over the foot of the map, enough to leave the map in view.
                let subcollection = game.learnPlace.flatMap(learnableSubcollection(of:))
                GameLearnCard(
                    game: game, localLanguage: localLanguage, isRoomy: isSeparate,
                    maxHeight: isBeside || isSeparate ? height - 12 : height * 0.78, onStep: step, onShow: show, onScrub: scrub,
                    subcollectionLabel: subcollection?.divisionLabel
                ) {
                    if let subcollection { learnSubdivisions(of: subcollection) }
                }
                    // A fresh row of cards for each set of places.
                    .id(game.collection.id)
                    .frame(maxWidth: isBeside ? columnWidth + 80 : .infinity)
                    // The cards either side fade away at the row's ends, rather than being cut off
                    // there or running on under the bar beside it on iPhone Duo.
                    .mask {
                        HStack(spacing: 0) {
                            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 22)
                            Color.black
                            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 22)
                        }
                    }
                    .transition(.blurReplace)
            } else {
                Group {
                    if fitsItself {
                        card(isRoomy: isSeparate || fillsColumn, isWide: isBeside && isTall)
                    } else {
                        FittedScroll(maxHeight: max(height - 12, 0)) {
                            card(isRoomy: false, isWide: isBeside && isTall)
                        }
                    }
                }
                .frame(maxWidth: isBeside ? columnWidth : 600)
                // Whatever comes and goes inside stays inside the glass.
                .clipShape(.rect(cornerRadius: 28))
                .glassPanel(in: .rect(cornerRadius: 28))
                .padding(.horizontal, 10)
                .transition(.blurReplace)
            }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { panelFrame = $0 }
        // Learn's row keeps room for its cards' shadows itself.
        .padding(.bottom, game.phase == .learning ? 0 : 6)
        .padding(.top, isSeparate || fillsColumn ? 6 : 0)
        .frame(maxHeight: isSeparate || fillsColumn ? .infinity : nil, alignment: .bottom)
        .opacity(isExpanded ? 1 : 0)
        .offset(y: isExpanded || isSeparate ? 0 : 80)
    }

    @ViewBuilder
    private func card(isRoomy: Bool, isWide: Bool) -> some View {
        switch game.phase {
        case .lobby:
            GameLobbyCard(
                game: game, localLanguage: localLanguage, isRoomy: isWide, onPlay: start, onLearn: startLearning
            ) { collectionPicker }
                .transition(.blurReplace)
        case .asking, .answered:
            GameQuestionCard(
                game: game, localLanguage: localLanguage, isRoomy: isRoomy, selection: selection, onAnswer: answer,
                onTyped: answer(typed:), onDecoy: answer(decoy:), onReveal: reveal, onNext: next,
                onMembership: answer(isMember:))
                .transition(.blurReplace)
        case .finished:
            GameResultsCard(
                game: game, localLanguage: localLanguage, reviewID: reviewID, onReview: review,
                onPlayAgain: { start(game.mode) }, onChangeGame: backToLobby)
                .transition(.blurReplace)
        case .learning:
            // Learn's cards are its own; see `panel`.
            EmptyView()
        }
    }

    /// Every set of places there's a map to quiz on, groups of countries in their own section.
    /// Choosing one starts afresh with its map.
    /// In a submenu for each section, such as World Groups or Asia, named with the places chosen
    /// in it, so the long list keeps its grouping; the World first, on its own.
    @ViewBuilder
    private var collectionPicker: some View {
        // Choosing another set of places starts afresh, leaving any way back behind.
        let selection = Binding(get: { game.collection.id }, set: { id in
            learnTrail = []
            switchCollection(to: id)
        })
        ForEach(MapGame.sections(applying: counting.rules)) { section in
            if let title = section.title {
                Menu {
                    Picker(title, selection: selection) {
                        ForEach(section.countries) { collection in
                            Text(collection.name).tag(collection.id)
                        }
                    }
                } label: {
                    Text(title)
                    if let chosen = section.countries.first(where: { $0.id == game.collection.id }) {
                        Text(chosen.name)
                    }
                }
            } else {
                Picker("Places", selection: selection) {
                    ForEach(section.countries) { collection in
                        Text(collection.name).tag(collection.id)
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
                    Button("Close", systemImage: "xmark", action: close)
                        .keyboardShortcut(.cancelAction)
                } else if game.phase == .learning, let stop = learnTrail.last {
                    // Out of a Learn opened from another's, back to that one, at the place it was opened from.
                    Button("Back to \(stop.name)", systemImage: "chevron.backward", action: learnBack)
                        .keyboardShortcut(.cancelAction)
                } else {
                    Button("Back to Quizzes", systemImage: "chevron.backward", action: backToLobby)
                        .keyboardShortcut(.cancelAction)
                }
            }
            .opacity(isExpanded ? 1 : 0)
        }
        // Only where there's a board to fly over: not in the lobby, nor in Flag, which has none.
        if game.phase != .lobby, !isFlagRound {
            // Zoom out and in by hand, a step at a time, around the middle of the map.
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Zoom Out", systemImage: "minus") { zoom(by: 1 / 1.8) }
                    .disabled(!canZoomByHand || navigator.camera.zoom <= 1.01)
                    .opacity(isExpanded ? 1 : 0)
                Button("Zoom In", systemImage: "plus") { zoom(by: 1.8) }
                    .disabled(!canZoomByHand || navigator.camera.zoom >= navigator.maximumZoom - 0.01)
                    .opacity(isExpanded ? 1 : 0)
            }
            ToolbarItem(placement: .primaryAction) {
                Toggle("Auto Zoom", systemImage: "location.viewfinder", isOn: $autoZoom)
                    .toggleStyle(.button)
                    .disabled(!autoZoomApplies)
                    .opacity(isExpanded ? 1 : 0)
                    .accessibilityHint("When on, the map flies in to each place. When off, the whole map stays in view.")
            }
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

    /// Whether Auto Zoom has anything to do just now. Find keeps the camera where you put it, and
    /// Outline and Code have nothing on the board to fly to until they're answered.
    private var autoZoomApplies: Bool {
        if isFindingRound { return false }
        if game.phase == .asking, game.mode == .outline || game.mode == .code { return false }
        return true
    }

    // MARK: The board

    /// The places lit up on the board: twinkles in the lobby, otherwise the one spotlight.
    private var spotlights: [GameSpotlight] {
        game.phase == .lobby ? twinkles : spotlight.map { [$0] } ?? []
    }

    /// The place lit up on the board: the place in question in Identify and Capital, the answer
    /// once it's given, a place looked at again from the results, and in Learn, the place being browsed.
    private var spotlight: GameSpotlight? {
        switch game.phase {
        case .lobby:
            return nil
        case .asking:
            if game.mode == .findIt, let selection {
                return lit(selection.id, style: .answer, color: game.mode.color)
            }
            if game.mode == .dot, let place = game.current, let point = game.dotPoint(of: place) {
                return GameSpotlight(regionIDs: [], style: .marker, color: game.mode.color, marker: point)
            }
            guard [.nameIt, .capitals, .member].contains(game.mode), let place = game.current else { return nil }
            return lit(place.id, style: .question, color: game.mode.color)
        case .answered:
            guard let place = game.current, let outcome = game.outcomes[place.id] else { return nil }
            return lit(place.id, style: .answer, color: MapGame.level(for: outcome).color, cities: capitalCities(of: place))
        case .finished:
            guard let reviewID, let outcome = game.outcomes[reviewID] else { return nil }
            return lit(reviewID, style: .answer, color: MapGame.level(for: outcome).color)
        case .learning:
            guard let place = game.learnPlace else { return nil }
            return lit(place.id, style: .answer, color: MapGame.learnColor, cities: capitalCities(of: place))
        }
    }

    /// A place lit up: its own outline only, keeping to its main body, so a country's far-flung
    /// territories and overseas departments stay dark.
    private func lit(
        _ placeID: String, style: GameSpotlight.Style, color: Color, cities: [GameSpotlight.City] = []
    ) -> GameSpotlight {
        GameSpotlight(
            regionIDs: game.mainRegions(of: placeID), style: style, color: color, cities: cities,
            mainBody: game.mainBody(of: placeID))
    }

    /// A place's capitals to mark on the map, where it's known where they are: in Capitals once
    /// it's answered, and in Learn.
    private func capitalCities(of place: AdministrativeDivision) -> [GameSpotlight.City] {
        guard game.mode == .capitals || game.phase == .learning else { return [] }
        return (game.capitals[place.id] ?? []).compactMap { capital in
            game.mapPoint(of: capital).map { GameSpotlight.City(name: capital.name, point: $0) }
        }
    }

    /// In Dot, the regions not answered yet, drawn as plain land; each one's borders
    /// and colour bloom in as it's answered.
    private var plainRegionIDs: Set<String> {
        guard game.mode == .dot, game.phase == .asking || game.phase == .answered else { return [] }
        return Set(game.regionPlaces.filter { game.outcomes[$0.value.id] == nil }.keys)
    }

    /// In Find, the regions of the places already tried for this question, faded on the board
    /// until it's answered.
    private var triedRegionIDs: Set<String> {
        guard game.mode == .findIt, game.phase == .asking else { return [] }
        return Set(game.wrongGuesses.flatMap { game.placeRegions[$0.id] ?? [] })
    }

    /// Each place's name, once it's been answered, so the board fills in as you learn it. Learn's
    /// card already names the place being browsed, so the board leaves it to the card.
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
        if let place = game.learnPlace {
            return "\(map), showing \(place.displayName(localLanguage: localLanguage))"
        }
        guard game.phase == .asking, let place = game.current else { return map }
        switch game.mode {
        case .nameIt:
            guard let group = game.collection.groups.first(where: { $0.id == place.groupID }) else {
                return "\(map), with one \(game.collection.placeNoun) lit up"
            }
            return "\(map). The \(game.collection.placeNoun) lit up is in \(group.name)."
        case .findIt:
            return "\(map). Find \(place.name)."
        case .capitals, .member:
            return "\(map). \(place.name) is lit up."
        case .dot:
            guard let group = game.collection.groups.first(where: { $0.id == place.groupID }), !game.scopes.isEmpty else {
                return "\(map), with one \(game.collection.placeNoun) marked with a dot"
            }
            return "\(map). The \(game.collection.placeNoun) marked with a dot is in \(group.name)."
        case .flags, .outline, .code:
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
        case (.asking, .findIt): "Tap a place to choose it, then confirm, or double-tap it to answer straight away. Pinch to zoom."
        case (.asking, .nameIt): game.answerMethod == .typing ? "Type its name below the map." : "Choose its name below the map."
        case (.asking, .flags): "Choose its name below the map."
        case (.asking, .outline), (.asking, .code), (.asking, .dot):
            game.answerMethod == .typing ? "Type its name below the map." : "Choose its name below the map."
        case (.asking, .capitals): game.answerMethod == .typing ? "Type its capital below the map." : "Choose its capital below the map."
        case (.asking, .member): "Answer in or out below the map."
        case (.learning, _): "Tap a place to learn about it. Pinch to zoom."
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
        withAnimation(.bouncy(duration: 0.5)) {
            game.mode = mode
            game.start()
        }
        haptic = GameHaptic(feedback: .impact(weight: .medium))
        // Find leaves the camera where it is: the map only moves when you move it.
        guard mode != .findIt else { return }
        // The first question's clock waits for the camera to arrive, so the flight doesn't eat into it.
        if autoZoom {
            game.holdQuestionClock(for: frameQuestion())
        } else {
            game.holdQuestionClock(for: frameScope())
        }
    }

    /// Learn: every place in play, one card at a time, the map lighting up each in turn.
    private func startLearning() {
        clearRound()
        withAnimation(.bouncy(duration: 0.5)) { game.startLearning() }
        haptic = GameHaptic(feedback: .impact(weight: .medium))
        if autoZoom {
            frameLearnPlace()
        } else {
            frameScope()
        }
    }

    /// What a place has of its own to learn, such as Japan's prefectures for Japan, where there's a
    /// map to learn them on.
    private func learnableSubcollection(of place: AdministrativeDivision) -> Country? {
        guard let collection = CountryCatalog.collection(for: place), TravelMap.named(collection.id) != nil else { return nil }
        return MapGame.collections(applying: counting.rules).first { $0.id == collection.id }
    }

    /// Opens Learn for a place's own places, such as Japan's prefectures from the World's Japan,
    /// keeping the way back to it.
    private func learnSubdivisions(of collection: Country) {
        guard let place = game.learnPlace else { return }
        let stop = LearnStop(collectionID: game.collection.id, placeID: place.id, name: game.collection.name)
        switchCollection(to: collection.id)
        guard game.collection.id == collection.id else { return }
        learnTrail.append(stop)
        startLearning()
    }

    /// Back to the Learn this one was opened from, at the place it was opened from.
    private func learnBack() {
        guard let stop = learnTrail.popLast() else { return }
        switchCollection(to: stop.collectionID)
        clearRound()
        withAnimation(.bouncy(duration: 0.5)) {
            game.startLearning()
            if let place = game.learnPlaces.first(where: { $0.id == stop.placeID }) { game.learn(place) }
        }
        haptic = GameHaptic(feedback: .impact(weight: .medium))
        if autoZoom {
            frameLearnPlace()
        } else {
            frameScope()
        }
    }

    /// Lets go of anything left over from the last round: a pending move on, a mistake still
    /// showing, a place chosen on the map.
    private func clearRound() {
        outlineFlight = nil
        reviewID = nil
        flash = nil
        selection = nil
        lastTap = nil
    }

    /// Answers with a name chosen, or a place tapped in Find. Correct stays on the answer until
    /// Next is pressed; wrong says so, and shows where the wrong place is.
    private func answer(_ place: AdministrativeDivision) {
        guard let current = game.current else { return }
        let result = withAnimation(.snappy) { game.answer(place) }
        let name = current.displayName(localLanguage: localLanguage)
        let guess = place.displayName(localLanguage: localLanguage)
        selection = nil
        switch result {
        case .right:
            haptic = GameHaptic(feedback: .success)
            announce(game.mode == .capitals ? "Correct! \(capitalNames(of: current))." : "Correct! \(name).")
            if [.outline, .code, .dot].contains(game.mode) { showAnswer() }
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

    /// A tap on the board. In Learn it shows the place tapped. In Find it chooses a place to
    /// confirm, so a slip of the finger doesn't count, and tapping it again lets it go; a second tap
    /// straight after the first answers with it. A place already tried stays faded, and a tap on it
    /// only brings a soft bump and, for VoiceOver, a reminder.
    private func tap(at location: CGPoint) {
        guard turningMap == nil, game.phase == .learning || (game.mode == .findIt && game.phase == .asking),
              let region = game.map.place(at: wrapped(location), geometry: navigator.geometry, among: game.scopedRegionIDs),
              let place = game.regionPlaces[region.id]
        else { return }
        if game.phase == .learning {
            guard game.learnPlaces.contains(place) else { return }
            show(place)
            return
        }
        guard !game.wrongGuesses.contains(place) else {
            haptic = GameHaptic(feedback: .impact(flexibility: .soft, intensity: 0.5))
            announce("Already tried \(place.displayName(localLanguage: localLanguage)).")
            return
        }
        let thisTap = MapTap(placeID: place.id, date: .now)
        defer { lastTap = thisTap }
        if let lastTap, lastTap.placeID == place.id,
           thisTap.date.timeIntervalSince(lastTap.date) < MapTap.doubleTapInterval {
            answer(place)
            return
        }
        withAnimation(.snappy) { selection = selection == place ? nil : place }
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
        let result = withAnimation(.snappy) { game.answer(typed: typed) }
        switch result {
        case .right:
            haptic = GameHaptic(feedback: .success)
            let answer = game.mode == .capitals ? capitalNames(of: place) : place.displayName(localLanguage: localLanguage)
            if let correction = game.correction {
                announce("Correct! \(answer). It’s spelt \(correction).")
            } else {
                announce("Correct! \(answer).")
            }
            if [.outline, .code, .dot].contains(game.mode) { showAnswer() }
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
            announce("Not quite.")
        case .ignored:
            break
        }
    }

    /// In Member?, answers in or out. Either way the question's settled, and the country lights up
    /// in the colour it went.
    private func answer(isMember guess: Bool) {
        guard let place = game.current else { return }
        let result = withAnimation(.snappy) { game.answer(isMember: guess) }
        let name = place.displayName(localLanguage: localLanguage)
        let group = game.collection.worldGroup?.nameInSentence ?? game.collection.name
        let fact = game.isMember(place) ? "\(name) is in \(group)." : "\(name) isn’t in \(group)."
        switch result {
        case .right:
            haptic = GameHaptic(feedback: .success)
            announce("Correct! \(fact)")
        case .wrong:
            haptic = GameHaptic(feedback: .error)
            announce("Not quite. \(fact)")
        case .again, .ignored:
            break
        }
    }

    /// In Capital, picks a well-known city in the place that isn't its capital: wrong, gently.
    private func answer(decoy city: String) {
        guard let place = game.current else { return }
        let result = withAnimation(.snappy) { game.answer(decoy: city) }
        guard result == .wrong else { return }
        haptic = GameHaptic(feedback: .error)
        announce("\(city) is in \(place.displayName(localLanguage: localLanguage)), but it isn’t the capital.")
    }

    /// Every one of a place's capitals, such as "Pretoria, Cape Town and Bloemfontein".
    private func capitalNames(of place: AdministrativeDivision) -> String {
        (game.capitals[place.id] ?? []).map(\.name).formatted(.list(type: .and))
    }

    /// Steps through Learn, by the arrows, the arrow keys or VoiceOver, and flies to the place.
    private func step(_ offset: Int) {
        let before = game.learnIndex
        withAnimation(.snappy) { game.step(by: offset) }
        guard game.learnIndex != before else { return }
        haptic = GameHaptic(feedback: .selection)
        frameLearnPlace()
    }

    /// Scrubbing through Learn's places: the map pulls all the way out so each place can be seen
    /// lighting up as it passes, with a tick at each new region, and once you let go, the camera
    /// flies to where you stopped. A place picked from the list goes straight there.
    private func scrub(to index: Int, isFinished: Bool) {
        guard game.learnPlaces.indices.contains(index) else { return }
        if !isFinished, !isScrubbingOut {
            isScrubbingOut = true
            frameScope()
        }
        if index != game.learnIndex {
            let crossesRegion = game.learnPlace?.groupID != game.learnPlaces[index].groupID
            game.learn(game.learnPlaces[index])
            if crossesRegion || isFinished { haptic = GameHaptic(feedback: .selection) }
        }
        if isFinished {
            isScrubbingOut = false
            frameLearnPlace()
        }
    }

    /// Shows a place in Learn, swiped to in the row of cards or tapped on the map, and flies there
    /// with Auto Zoom on.
    private func show(_ place: AdministrativeDivision) {
        withAnimation(.snappy) { game.learn(place) }
        haptic = GameHaptic(feedback: .selection)
        frameLearnPlace()
    }

    private func reveal() {
        guard let place = game.current else { return }
        withAnimation(.snappy) { game.reveal() }
        haptic = GameHaptic(feedback: .impact(weight: .light))
        announce(spokenAnswer(for: place))
        showAnswer()
    }

    /// The answer as VoiceOver tells it when it's shown: the place, or in Member?, whether it's in.
    private func spokenAnswer(for place: AdministrativeDivision) -> String {
        let name = place.displayName(localLanguage: localLanguage)
        guard game.mode == .member else { return "It’s \(name)." }
        let group = game.collection.worldGroup?.nameInSentence ?? game.collection.name
        return game.isMember(place) ? "\(name) is in \(group)." : "\(name) isn’t in \(group)."
    }

    private func next() {
        flash = nil
        selection = nil
        lastTap = nil
        // A shape still landing from the last question stays with it.
        outlineFlight = nil
        withAnimation(.snappy) { game.advance() }
        switch game.phase {
        case .asking:
            game.holdQuestionClock(for: frameQuestion())
        case .finished:
            frameScope()
            haptic = finishedHaptic
            announce("Round over: \(game.rightCount) of \(game.questions.count) right first time.")
        case .lobby, .answered, .learning:
            break
        }
    }

    private func backToLobby() {
        learnTrail = []
        clearRound()
        withAnimation(.bouncy(duration: 0.5)) { game.returnToLobby() }
        frameScope()
    }

    /// Escape goes back a step: out of a round to the quizzes, or out of the quiz.
    private func back() {
        if game.phase == .lobby {
            close()
        } else if game.phase == .learning, !learnTrail.isEmpty {
            learnBack()
        } else {
            backToLobby()
        }
    }

    /// Lights up a place from the results again, flying to it with Auto Zoom on.
    private func review(_ place: AdministrativeDivision) {
        withAnimation(.snappy) { reviewID = place.id }
        haptic = GameHaptic(feedback: .selection)
        if autoZoom { whole(place.id) { fly(to: $0, margin: 2.2) } }
    }

    // MARK: The camera

    /// The place the camera keeps framed while Auto Zoom is on: the place in question in Identify,
    /// Capital and Dot, the answer once it's given in Outline and Code too, and the place being
    /// browsed in Learn.
    private var followedPlace: AdministrativeDivision? {
        guard autoZoom else { return nil }
        switch game.phase {
        case .asking: return [.nameIt, .capitals, .dot, .member].contains(game.mode) ? game.current : nil
        case .answered: return [.nameIt, .capitals, .dot, .outline, .code, .member].contains(game.mode) ? game.current : nil
        case .learning: return game.learnPlace
        case .lobby, .finished: return nil
        }
    }

    /// How much room to leave around the place framed: in Dot, a generous area around the dot,
    /// so its surroundings help; otherwise close enough to see the smallest place.
    private var cameraMargin: CGFloat {
        game.mode == .dot && game.phase == .asking ? 3.5 : 2.2
    }

    /// With Auto Zoom on, Identify, Capital, Dot and Member? fly to each place in turn. Returns
    /// about how long the camera takes to get there, the World's turn included.
    @discardableResult
    private func frameQuestion() -> TimeInterval {
        guard autoZoom, [.nameIt, .capitals, .dot, .member].contains(game.mode), let place = game.current else { return 0 }
        let turning = turnDuration(to: game.wholeLongitude(for: place.id) ?? game.centerLongitude)
        let flying = game.frames[place.id].map(flightDuration(to:)) ?? 0
        whole(place.id) { fly(to: $0, margin: cameraMargin) }
        return turning + flying
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
    /// map. Once it settles, the place being followed is framed again in the room there now is, or
    /// a board fitted to the screen is fitted again, unless it's been moved by hand since.
    private func reframeOnceTheCardSettles() {
        pendingReframe?.cancel()
        pendingReframe = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            if let place = followedPlace, outlineFlight == nil {
                isBoardFitted = false
                whole(place.id) { navigator.frame($0, margin: cameraMargin, animation: reduceMotion ? nil : .smooth(duration: 0.5)) }
            } else if isBoardFitted, !isFindingRound {
                frameScope()
            }
        }
    }

    /// With Auto Zoom on, Learn flies to the place being browsed.
    private func frameLearnPlace() {
        guard autoZoom, let place = game.learnPlace else { return }
        whole(place.id) { fly(to: $0, margin: 2.2) }
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
        case .learning:
            if autoZoom { frameLearnPlace() } else { frameScope() }
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

    /// The camera was moved by hand, so the board is no longer fitted for it.
    private func movedByHand() {
        if isBoardFitted { isBoardFitted = false }
    }

    /// Whether this round's camera follows places, as every mode but Find and Flag does.
    private var followsPlaces: Bool {
        game.mode != .findIt && game.mode != .flags
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
            if autoZoom { whole(place.id) { fly(to: $0, margin: 2.5) } }
            return
        }
        whole(place.id) { frame in
            flights += 1
            isBoardFitted = false
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
    /// spread well apart. With Reduce Motion they only fade in and out.
    private func twinkleWhileWaiting() async {
        twinkles = []
        guard game.phase == .lobby, isExpanded else { return }
        let colors = MapGameMode.allCases.map(\.color).shuffled()
        var count = 0
        try? await Task.sleep(for: .seconds(0.6))
        while !Task.isCancelled {
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
            // More at once the more there is to see: up to four on the World.
            let most = min(max(inView.count / 14, 1), 4)
            let lit = twinkles.compactMap { twinkle in
                twinkle.caption.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY).applying(geometry.transform) }
            }
            let apart = max(min(clear.width, clear.height) * 0.3, 90)
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
    }

    /// Waits a moment for the board to learn its size, fills the screen with the map, then pops it up.
    private func open() async {
        try? await Task.sleep(for: .milliseconds(30))
        frameScope(animated: false)
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .bouncy(duration: 0.6, extraBounce: 0.12)) {
            isExpanded = true
        }
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .smooth(duration: 0.4)) {
            isExpanded = false
        } completion: {
            onClose()
        }
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
        flash = nil
        withAnimation(.snappy) { game.runOutOfQuestionTime() }
        haptic = GameHaptic(feedback: .warning)
        announce("Time’s up. \(spokenAnswer(for: place))")
        showAnswer()
    }

    /// Time's up: the round ends, the places not answered shown, and the board comes back into view.
    private func runOutOfTime() {
        guard game.phase == .asking || game.phase == .answered else { return }
        selection = nil
        flash = nil
        withAnimation(.bouncy(duration: 0.5)) { game.runOutOfTime() }
        haptic = finishedHaptic
        frameScope()
        announce("Time’s up. \(game.rightCount) of \(game.questions.count) right first time.")
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

/// A tap on a place in Find, kept to tell a double tap from two single ones.
private struct MapTap {
    var placeID: String
    var date: Date

    /// How soon a second tap on the same place must follow the first to answer with it.
    static let doubleTapInterval: TimeInterval = 0.35
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

/// A Learn left for another opened from it, such as the World's, left at Japan for its prefectures.
private struct LearnStop {
    var collectionID: String
    var placeID: String
    var name: String
}
