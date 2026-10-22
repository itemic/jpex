import SwiftUI

/// A tile's second level in the lobby: how it plays, set out large, and Start, pinned to the foot so
/// it's always there to press. At the top, a way back beside the tile's symbol in its colour, its
/// name, and a line on what you'll do. Between them, each choice is one line of toggles, the one
/// chosen lit in the tile's candy, scrolling sideways where they don't all fit: which way round to
/// identify, for a tile that goes both ways; Map's borders; a mode's own kinds, such as Code's
/// kinds of code, each shown as it's met in the world on a place lighting up behind, the codes
/// turning over unhurriedly one kind at a time, or Outline's upright or rotated shapes;
/// names in English or in the places' own language, such as Japanese; the answer type, Auto-fill
/// among them for typing with the nearest names offered; how many questions; and a time limit for
/// the game and one for each question. The choices scroll where there are more than fit. Every choice is kept
/// for next time.
struct GameModeSetup: View {
    @Bindable var game: MapGame
    var tile: MapGameMode
    var localLanguage: Bool
    var isShort: Bool
    var onBack: () -> Void
    var onStart: (MapGameMode) -> Void
    /// Says how tall it would like to be, with every choice in view, so the card can make room.
    var onIdealHeight: (CGFloat) -> Void = { _ in }
    /// The places lighting up on the board behind, whose flags, shapes and codes the toggles' pictures
    /// take in turn, each held a calm while rather than changing as every place comes and goes.
    var glowing: [AdministrativeDivision] = []
    /// Which way round it plays, for a tile that goes both ways.
    @State private var direction: MapGameMode
    @State private var headerHeight: CGFloat = 0
    @State private var choicesHeight: CGFloat = 0
    @State private var footHeight: CGFloat = 0
    /// Each kind of code's sample as it shows just now, held for a calm while rather than turning
    /// over with every place that lights up on the board behind; empty until they're first held.
    @State private var heldCodes: [MapGame.CodeKind: String] = [:]
    /// The place each way round's picture shows just now, Flag's and Outline's, held for a calm while
    /// like the codes rather than cutting to a new flag or shape at every twinkle behind.
    @State private var heldPlaces: [MapGameMode: AdministrativeDivision] = [:]
    /// Counts the turns the pictures take, one after another: Flag's or Outline's, or each kind of
    /// code's in turn.
    @State private var codeTurns = 0
    @AccessibilityFocusState private var isTitleFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether decoration may move by itself, as the codes turning over do: not in Low Power Mode,
    /// with Reduce Motion, nor while the app isn't in front.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    /// Whether places go by their own names, in their own language, rather than English: the
    /// app's own setting, here for the quiz's names too.
    @AppStorage("localLanguage") private var showsLocalNames = false
    @ScaledMetric(relativeTo: .headline) private var startHeight = 54
    @ScaledMetric(relativeTo: .headline) private var badgeSide = 44

    init(
        game: MapGame, tile: MapGameMode, localLanguage: Bool, isShort: Bool, glowing: [AdministrativeDivision] = [],
        onBack: @escaping () -> Void, onStart: @escaping (MapGameMode) -> Void,
        onIdealHeight: @escaping (CGFloat) -> Void = { _ in }
    ) {
        self.glowing = glowing
        self.game = game
        self.tile = tile
        self.localLanguage = localLanguage
        self.isShort = isShort
        self.onBack = onBack
        self.onStart = onStart
        self.onIdealHeight = onIdealHeight
        // The way round played last, where it's this tile's: Dot is Map's own, with the borders hidden.
        let ways = tile.directions.filter(game.isAvailable)
        let last = game.mode == .dot ? MapGameMode.nameIt : game.mode
        _direction = State(initialValue: ways.contains(last) ? last : ways.contains(tile) ? tile : ways.first ?? tile)
    }

    private var margin: CGFloat { isShort ? 14 : 18 }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding([.horizontal, .top], margin)
                .padding(.bottom, 12)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0; reportHeight() }
            ScrollView {
                choices
                    .padding(.horizontal, margin)
                    .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height } action: { _, height in
                choicesHeight = height
                reportHeight()
            }
            startButton
                .padding([.horizontal, .bottom], margin)
                .padding(.top, 10)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footHeight = $0; reportHeight() }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape, onBack)
        .sensoryFeedback(.selection, trigger: direction)
        .sensoryFeedback(.selection, trigger: game.answerStyle)
        .sensoryFeedback(.selection, trigger: game.roundSize)
        .sensoryFeedback(.selection, trigger: game.customCount)
        .sensoryFeedback(.selection, trigger: game.roundMinutes)
        .sensoryFeedback(.selection, trigger: game.questionSeconds)
        .sensoryFeedback(.selection, trigger: game.codeKind)
        .sensoryFeedback(.selection, trigger: game.outlineRotated)
        .sensoryFeedback(.selection, trigger: game.showsBorders)
        .sensoryFeedback(.selection, trigger: game.autoFill)
        .sensoryFeedback(.selection, trigger: showsLocalNames)
        // Lines coming and going, such as Auto-fill's with Type, glide in without a bounce.
        .animation(.smooth(duration: 0.25), value: startMode)
        .animation(.smooth(duration: 0.25), value: game.answerStyle)
        .animation(.smooth(duration: 0.25), value: game.roundSize)
        .onAppear { isTitleFocused = true }
        .task(id: allowsAmbientMotion) { await turnCodesOver() }
        // Each turn is taken here rather than in the task, so it draws on the places lighting up
        // on the board as they are now, not as they were when the task began.
        .onChange(of: codeTurns) { turnOverNextCode() }
        // Another set of places, such as Japan's in place of the World's, brings its own pictures.
        .onChange(of: game.collection.id) {
            heldCodes = [:]
            heldPlaces = [:]
            holdPictures()
        }
    }

    /// How tall it would be with every choice in view.
    private func reportHeight() {
        onIdealHeight(headerHeight + choicesHeight + footHeight)
    }

    // MARK: Pictures turning over

    /// How long each picture, a flag, a shape or a kind's code, shows before another takes its
    /// place: twice as long as a place stays lit on the board behind, so there's time to read the
    /// code, or take in the flag or the shape.
    private static let codeDwell = GameSpotlight.twinkleDuration * 2

    /// Something on the page whose picture turns over: a way round's toggle, as Flag's and
    /// Outline's are, or a kind of code, which Code's way round follows.
    private enum Turner: Hashable {
        case way(MapGameMode)
        case code(MapGame.CodeKind)
    }

    /// Everything on the page whose picture turns over, in the order their turns come round.
    private var turners: [Turner] {
        if tile == .code { return game.codeKinds.map(Turner.code) }
        return directions.filter { $0 == .pickFlag || $0 == .pickOutline }.map(Turner.way)
    }

    /// Whether a place has a picture for a way round: a flag of its own, or a shape to know it by.
    private func hasPicture(_ place: AdministrativeDivision, for way: MapGameMode) -> Bool {
        switch way {
        case .pickFlag: game.hasOwnFlag(place)
        case .pickOutline: game.outline(of: place) != nil
        default: false
        }
    }

    /// A place for a way round's picture: one lighting up on the board behind just now, other than
    /// `shown`, or once the board has come to rest, one of the places in play, spread across them
    /// by `turn` rather than neighbours in list order.
    private func pictureSample(for way: MapGameMode, other shown: AdministrativeDivision? = nil, turn: Int = 0) -> AdministrativeDivision? {
        if let place = glowing.first(where: { $0.id != shown?.id && hasPicture($0, for: way) }) { return place }
        // Looked through lazily from a point along the list, as a shape is costly to work out.
        let inPlay = game.placesInPlay
        guard !inPlay.isEmpty else { return shown }
        let start = (turn * 37) % inPlay.count
        for index in inPlay.indices {
            let place = inPlay[(start + index) % inPlay.count]
            if place.id != shown?.id, hasPicture(place, for: way) { return place }
        }
        return shown
    }

    /// The place a way round's picture shows: the one held for it, or before they're held, one
    /// lighting up on the board behind.
    private func shownPlace(for way: MapGameMode) -> AdministrativeDivision? {
        heldPlaces[way] ?? pictureSample(for: way)
    }

    /// A kind of code's sample as it shows just now: the one held for it, or before the codes are
    /// held, the code of one of the places lighting up on the board behind, a different place for
    /// each kind where there are enough.
    private func shownCode(of kind: MapGame.CodeKind) -> String? {
        heldCodes[kind] ?? game.sampleCode(of: kind, preferring: glowing, offset: game.codeKinds.firstIndex(of: kind) ?? 0)
    }

    /// Keeps the pictures, Flag's or Outline's toggle or Code's kinds, turning over at a calm, even
    /// pace, one at a time, so the page never changes all at once: each shows for a whole
    /// `codeDwell` before its next turn, the turns spread evenly across it. Only while decoration
    /// may move: with Reduce Motion, in Low Power Mode or with the app in the background, the first
    /// pictures hold still.
    private func turnCodesOver() async {
        holdPictures()
        let count = turners.count
        guard allowsAmbientMotion, count > 0 else { return }
        let step = Self.codeDwell / Double(count)
        // The first kind waits out a whole dwell before its turn; the rest follow a step apart.
        try? await Task.sleep(for: .seconds(Self.codeDwell - step))
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(step))
            guard !Task.isCancelled else { return }
            codeTurns += 1
        }
    }

    /// Holds what shows now, so it stays put rather than following each place that lights up behind.
    private func holdPictures() {
        if tile == .code {
            for kind in game.codeKinds where heldCodes[kind] == nil {
                heldCodes[kind] = shownCode(of: kind)
            }
        }
        for case .way(let way) in turners where heldPlaces[way] == nil {
            heldPlaces[way] = pictureSample(for: way)
        }
    }

    /// The next picture's turn: it takes the flag, shape or code of a place lighting up on the
    /// board behind just now, a different one from the one it shows, or once the board has come to
    /// rest, one of the places in play, and holds it.
    private func turnOverNextCode() {
        let turners = turners
        guard codeTurns > 0, !turners.isEmpty else { return }
        let index = (codeTurns - 1) % turners.count
        switch turners[index] {
        case .code(let kind):
            // A code other than the one showing, from the places lit just now where they have one,
            // or else from those in play, so a turn is never a turn back to the same code.
            let shown = heldCodes[kind]
            let lit = (0..<4).lazy.compactMap { game.sampleCode(of: kind, preferring: glowing, offset: index + $0 * turners.count) }
            let inPlay = (0..<4).lazy.compactMap { game.sampleCode(of: kind, offset: codeTurns + $0) }
            heldCodes[kind] = lit.first { $0 != shown } ?? inPlay.first { $0 != shown } ?? shown
        case .way(let way):
            heldPlaces[way] = pictureSample(for: way, other: heldPlaces[way], turn: codeTurns)
        }
    }

    /// A picture for a way round that identifies something of a place: one of its flags, its
    /// shapes or its codes, as the places lighting up on the board have them, each held a while.
    private func picture(for way: MapGameMode) -> SetupPicture? {
        switch way {
        case .pickFlag:
            return shownPlace(for: way).map { .flag($0.flagAssetName) }
        case .pickOutline:
            return shownPlace(for: way).flatMap { place in game.outline(of: place).map { .outline($0, tile.color, place.id) } }
        case .pickCode:
            // The same code as the kind chosen shows below, turning over with it.
            return shownCode(of: game.shownCodeKind).map { .code($0, game.shownCodeKind) }
        default:
            return nil
        }
    }

    /// The mode Start plays: the way round chosen, and for Map's place with the borders hidden, Dot.
    private var startMode: MapGameMode {
        direction == .nameIt && !game.showsBorders ? .dot : direction
    }

    /// A way to answer, as the answer type offers it: typed, typed with Auto-fill offering the
    /// nearest names as you go, four to pick from, or every one in play.
    private enum AnswerChoice: Hashable {
        case style(MapGame.AnswerStyle)
        case autoFill
    }

    /// The answer types the mode takes, Auto-fill just after Type where names are typed.
    private var answerChoices: [SetupChoice<AnswerChoice>] {
        startMode.answerStyles.flatMap { style -> [SetupChoice<AnswerChoice>] in
            let choice = SetupChoice(value: AnswerChoice.style(style), title: style.name, symbolName: style.symbolName, spokenName: style.spokenName)
            guard style == .type, startMode.offersAutoFill else { return [choice] }
            return [
                choice,
                SetupChoice(
                    value: .autoFill, title: GameOption.autoFill.title, symbolName: "keyboard.badge.ellipsis",
                    spokenName: "Type, with the 10 nearest names to pick from as you go"),
            ]
        }
    }

    /// The answer type the mode plays with just now.
    private var answerChoice: AnswerChoice? {
        guard let style = game.shownAnswerStyle(for: startMode) else { return nil }
        return style == .type && game.autoFill && startMode.offersAutoFill ? .autoFill : .style(style)
    }

    /// The ways round the tile plays, where these places have each.
    private var directions: [MapGameMode] {
        tile.directions.filter(game.isAvailable)
    }

    /// The way back, the tile's symbol on a square of its candy, its name, and what you'll do.
    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.backward")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .glassPanel(in: Circle(), interactive: true)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PillButtonStyle())
            .accessibilityLabel("Back")
            .accessibilityHint("Back to every quiz.")
            Image(systemName: tile.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CandyGloss.lettering(on: tile.color))
                .frame(width: badgeSide, height: badgeSide)
                .background {
                    CandyGloss(color: tile.color, pattern: .candyStripes)
                        .clipShape(.rect(cornerRadius: 12, style: .continuous))
                }
                .shadow(color: tile.color.opacity(0.35), radius: 6, y: 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(tile.name)
                    .typeStyle(.compactPlaceName)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                Text(startMode.summary(placeNoun: game.collection.placeNoun, method: game.answerMethod(for: startMode)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
        }
    }

    /// Every choice for the tile, a line each.
    @ViewBuilder
    private var choices: some View {
        VStack(alignment: .leading, spacing: isShort ? 12 : 16) {
            if directions.count > 1 {
                section(tile.directionsTitle) {
                    SetupToggles(
                        choices: directions.map { way in
                            SetupChoice(value: way, title: way.directionName, symbolName: way.directionSymbolName, picture: picture(for: way))
                        },
                        selection: direction, color: tile.color, stacksSymbols: true, edge: margin
                    ) { direction = $0 }
                }
            }
            if direction.hidesBorders {
                section(GameOption.borders.title) {
                    SetupToggles(
                        choices: [
                            SetupChoice(value: true, title: "Shown", symbolName: "squareshape.split.2x2", spokenName: "Borders shown"),
                            SetupChoice(value: false, title: "Hidden", symbolName: "squareshape", spokenName: "Borders hidden"),
                        ],
                        selection: game.showsBorders, color: tile.color, edge: margin
                    ) { game.showsBorders = $0 }
                }
            }
            kinds
            if game.collection.supportsLocalNames {
                section("Display language") {
                    SetupToggles(
                        choices: [
                            SetupChoice(value: false, title: "English", spokenName: "Names in English"),
                            SetupChoice(
                                value: true, title: game.collection.localNamesLanguage,
                                spokenName: "Names in \(game.collection.localNamesLanguage)"),
                        ],
                        selection: showsLocalNames, color: tile.color, edge: margin
                    ) { showsLocalNames = $0 }
                }
            }
            if answerChoices.count > 1 {
                section(GameOption.answerStyle.title) {
                    SetupToggles(
                        choices: answerChoices, selection: answerChoice, color: tile.color, stacksSymbols: true, edge: margin
                    ) { choice in
                        switch choice {
                        case .autoFill:
                            game.answerStyle = .type
                            game.autoFill = true
                        case .style(let style):
                            game.answerStyle = style
                            if style == .type { game.autoFill = false }
                        }
                    }
                }
            }
            if game.choosesRoundSize(for: startMode) {
                section(GameOption.length.title) { questionCounts }
            }
            section(GameOption.roundTime.title) {
                SetupToggles(
                    choices: [SetupChoice<Int?>(value: nil, title: "Off", spokenName: "No time limit for the game")]
                        + MapGame.roundMinuteChoices.map { SetupChoice(value: $0, title: "\($0) min", spokenName: "\($0) minutes") },
                    selection: game.roundMinutes, color: tile.color, edge: margin
                ) { game.roundMinutes = $0 }
            }
            // List All has no questions of its own to time.
            if startMode != .listAll {
                section(GameOption.questionTime.title) {
                    SetupToggles(
                        choices: [SetupChoice<Int?>(value: nil, title: "Off", spokenName: "No time limit for each question")]
                            + MapGame.questionSecondChoices.map { SetupChoice(value: $0, title: "\($0) sec", spokenName: "\($0) seconds") },
                        selection: game.questionSeconds, color: tile.color, edge: margin
                    ) { game.questionSeconds = $0 }
                }
            }
        }
    }

    /// A mode's own kinds: Code's kinds of code, where these places have more than one, each as
    /// it's met in the world above its name, and Outline's upright or rotated shapes.
    @ViewBuilder
    private var kinds: some View {
        // Shown whenever there are codes, even of one kind, as France has, so it's plain which.
        if startMode == .code || startMode == .pickCode, !game.codeKinds.isEmpty {
            section(GameOption.codeKind.title) {
                SetupRow(edge: margin) {
                    ForEach(game.codeKinds) { kind in
                        let isOn = game.shownCodeKind == kind
                        // A place lighting up on the board behind, a different one for each kind where
                        // it can be, held a while before the next takes its place.
                        let code = shownCode(of: kind) ?? ""
                        Button {
                            game.codeKind = kind
                        } label: {
                            VStack(spacing: 6) {
                                // As large as the tile holds: most codes at the largest, a long one
                                // smaller. The next dissolves in where the last one was, in one slot,
                                // as the toggles' pictures do, so the two never share the tile's height.
                                ZStack {
                                    ViewThatFits(in: .horizontal) {
                                        ForEach([30, 25, 20, 16] as [CGFloat], id: \.self) { size in
                                            CodeBadge(code: code, kind: kind, size: size, isCompact: true)
                                                .fixedSize()
                                        }
                                    }
                                    .id(code)
                                    .transition(CodeDissolve(blurs: !reduceMotion))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .animation(CodeDissolve.pace, value: code)
                                // Whole, scrolling where a long name outgrows the tile.
                                ScrollingText {
                                    Text(kind.name)
                                        .font(.caption.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 6)
                            .padding(.top, 8)
                            .padding(.bottom, 9)
                            .frame(width: 136, height: 98)
                        }
                        .buttonStyle(SetupToggleStyle(color: tile.color, isOn: isOn))
                        .accessibilityLabel(kind.summary)
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
            }
        } else if startMode == .outline || startMode == .pickOutline {
            section(GameOption.outlineRotated.title) {
                SetupToggles(
                    choices: [
                        SetupChoice(value: false, title: "Upright", symbolName: "arrow.up", spokenName: "Upright shapes"),
                        SetupChoice(value: true, title: "Rotated", symbolName: "rotate.right", spokenName: "Rotated shapes"),
                    ],
                    selection: game.outlineRotated, color: tile.color, edge: margin
                ) { game.outlineRotated = $0 }
            }
        }
    }

    /// How many questions: ten, any sets of the places people usually mean, such as the fifty
    /// states, all of them, or a number of your own, set beside it once it's chosen.
    private var questionCounts: some View {
        let available = game.placesInScope.count
        let isCustom = game.roundSize == .custom
        return SetupRow(edge: margin) {
            ForEach(
                [SetupChoice(value: MapGame.RoundSize.ten, title: "10", spokenName: "10 questions")]
                    + game.placeSets.map { SetupChoice(value: MapGame.RoundSize.set($0.id), title: $0.name) }
                    + [
                        SetupChoice(value: MapGame.RoundSize.all, title: "All \(available)", spokenName: "All \(available)"),
                        SetupChoice(value: MapGame.RoundSize.custom, title: "Custom", spokenName: "A number of your own"),
                    ]
            ) { choice in
                SetupToggleButton(choice: choice, isOn: game.roundSize == choice.value, color: tile.color, fillsWidth: false) {
                    game.roundSize = choice.value
                }
            }
            if isCustom {
                // It grows in beside Custom; with Reduce Motion, it only fades in.
                CountStepper(count: $game.customCount, range: 1...max(available, 1), color: tile.color)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.8).combined(with: .opacity))
            }
        }
    }

    /// Start, large and candy in the tile's colour, always at the foot; Return presses it from a
    /// hardware keyboard.
    private var startButton: some View {
        Button {
            onStart(startMode)
        } label: {
            Label("Start", systemImage: "play.fill")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: startHeight)
        }
        .buttonStyle(CandyButtonStyle(
            color: tile.color, pattern: .candyStripes, shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
        .overlay { GlassEdge(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)) }
        .keyboardShortcut(.defaultAction)
        .accessibilityHint(startMode.summary(placeNoun: game.collection.placeNoun, method: game.answerMethod(for: startMode)))
    }

    /// A choice's heading, with its line of toggles beneath.
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .typeStyle(.eyebrow)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }
}

/// One toggle in a second-level line: its value, its name, any symbol, and what VoiceOver hears
/// where the name alone doesn't say it.
private struct SetupChoice<Value: Hashable>: Identifiable {
    var value: Value
    var title: String
    var symbolName: String?
    var spokenName: String?
    /// A picture of what it means, in place of a symbol, such as a flag or a code as it's met in
    /// the world.
    var picture: SetupPicture?

    var id: Value { value }
}

/// A toggle's picture of what it means, in place of a symbol.
private enum SetupPicture {
    /// A code as it's met in the world, such as .jp in an address bar or a department's number.
    case code(String, MapGame.CodeKind)
    /// A flag.
    case flag(String)
    /// A place's shape, in the tile's colour, with the place's ID to tell one shape from the next.
    case outline(Path, Color, String)
}

/// Choices in one line as large toggles, sharing the line's width where they fit, and otherwise
/// keeping their own widths and scrolling sideways. A symbol sits beside its name, or above it
/// where `stacksSymbols` is set, so every toggle is as wide as the rest.
private struct SetupToggles<Value: Hashable>: View {
    var choices: [SetupChoice<Value>]
    var selection: Value?
    var color: Color
    var stacksSymbols = false
    /// How far the line can scroll past the card's margin, to the card's edge.
    var edge: CGFloat
    var select: (Value) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                buttons(fillsWidth: true)
            }
            SetupRow(edge: edge) {
                buttons(fillsWidth: false)
            }
        }
    }

    private func buttons(fillsWidth: Bool) -> some View {
        ForEach(choices) { choice in
            SetupToggleButton(
                choice: choice, isOn: choice.value == selection, color: color, fillsWidth: fillsWidth, stacksSymbol: stacksSymbols
            ) {
                select(choice.value)
            }
        }
    }
}

/// One toggle: candy in the tile's colour when chosen, otherwise a soft fill with its name in the
/// text's own colour.
private struct SetupToggleButton<Value: Hashable>: View {
    var choice: SetupChoice<Value>
    var isOn: Bool
    var color: Color
    var fillsWidth: Bool
    var stacksSymbol = false
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .subheadline) private var height = 44
    @ScaledMetric(relativeTo: .subheadline) private var stackedHeight = 84

    var body: some View {
        Button(action: action) {
            label
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                // Whole, never cut short: where the line can't hold every toggle whole, it scrolls.
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .frame(minWidth: stacksSymbol ? 96 : nil)
                .frame(height: stacksSymbol && (choice.symbolName != nil || choice.picture != nil) ? stackedHeight : height)
        }
        .buttonStyle(SetupToggleStyle(color: color, isOn: isOn))
        .accessibilityLabel(choice.spokenName ?? choice.title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    @ViewBuilder
    private var label: some View {
        if let picture = choice.picture {
            VStack(spacing: 5) {
                pictureView(picture)
                    .frame(height: 36)
                Text(choice.title)
            }
        } else if let symbol = choice.symbolName {
            if stacksSymbol {
                VStack(spacing: 5) {
                    Image(systemName: symbol)
                        .font(.title.weight(.semibold))
                        .frame(height: 36)
                    Text(choice.title)
                }
            } else {
                Label(choice.title, systemImage: symbol)
            }
        } else {
            Text(choice.title)
        }
    }

    @ViewBuilder
    private func pictureView(_ picture: SetupPicture) -> some View {
        switch picture {
        case .code(let code, let kind):
            // A new code, as its kind's turns over or another kind's chosen, dissolves in slowly
            // where the last one was.
            ZStack {
                ViewThatFits(in: .horizontal) {
                    ForEach([20, 16, 13] as [CGFloat], id: \.self) { size in
                        CodeBadge(code: code, kind: kind, size: size, isCompact: true)
                            .fixedSize()
                    }
                }
                .id(code)
                .transition(CodeDissolve(blurs: !reduceMotion))
            }
            .animation(CodeDissolve.pace, value: code)
        case .flag(let asset):
            // A new flag, as the toggle's picture turns over, dissolves in where the last one was,
            // as the codes do.
            ZStack {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 3))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .id(asset)
                    .transition(CodeDissolve(blurs: !reduceMotion))
            }
            .animation(CodeDissolve.pace, value: asset)
        case .outline(let path, let color, let placeID):
            ZStack {
                ZStack {
                    OutlineShape(unit: path)
                        .fill(color)
                    OutlineShape(unit: path)
                        .stroke(.white, style: StrokeStyle(lineWidth: 1, lineJoin: .round))
                }
                .id(placeID)
                .transition(CodeDissolve(blurs: !reduceMotion))
            }
            .frame(width: 40, height: 36)
            .animation(CodeDissolve.pace, value: placeID)
        }
    }
}

/// How a code in a toggle gives way to the next: a slow dissolve, the old one fading and softening
/// out of focus as the new one comes into focus where it was, with nothing growing, shrinking or
/// sliding, so a change reads as calm rather than busy. With Reduce Motion, it only fades.
private struct CodeDissolve: Transition {
    /// Whether it softens out of focus as it fades.
    var blurs = true

    /// Its pace: unhurried, easing in and out.
    static let pace = Animation.easeInOut(duration: 0.9)

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase.isIdentity ? 1 : 0)
            .blur(radius: blurs && !phase.isIdentity ? 4 : 0)
    }
}

/// A line of toggles that scrolls sideways, out to the card's edges, so nothing in it wraps; with
/// room around them for a lit toggle's glow, which the scroll view would otherwise cut off.
private struct SetupRow<Content: View>: View {
    var edge: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                content
            }
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, edge, for: .scrollContent)
        .padding(.horizontal, -edge)
        .padding(.vertical, -8)
    }
}

/// A toggle's look: lit candy in the tile's colour when it's chosen, with white lettering; otherwise
/// a soft fill with a fine edge, its name in the text's own colour, easy to read either way. A
/// press dims it, rather than squeezing it, which in a line that scrolls only shows once it's let go.
/// France's choice between its regions and its departments wears it too.
struct SetupToggleStyle: ButtonStyle {
    var color: Color
    var isOn: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        configuration.label
            .foregroundStyle(isOn ? AnyShapeStyle(CandyGloss.lettering(on: color)) : AnyShapeStyle(.primary))
            .background {
                if isOn {
                    CandyGloss(color: color, pattern: .candyStripes)
                        .clipShape(shape)
                } else {
                    shape.fill(.fill.tertiary)
                }
            }
            .overlay {
                shape.strokeBorder(isOn ? AnyShapeStyle(.white.opacity(0.35)) : AnyShapeStyle(.separator), lineWidth: isOn ? 1 : 0.5)
            }
            .contentShape(shape)
            .shadow(color: color.opacity(isOn ? 0.35 : 0), radius: 6, y: 3)
            // A press dims it a touch, and the choice cross-fades: nothing jumps or bounces.
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.18), value: isOn)
    }
}

/// A number of your own, with a step down and a step up either side: by one up to twenty, by five
/// up to a hundred, by ten beyond. VoiceOver adjusts it a step at a time.
private struct CountStepper: View {
    @Binding var count: Int
    var range: ClosedRange<Int>
    var color: Color
    @ScaledMetric(relativeTo: .subheadline) private var height = 44

    var body: some View {
        let shown = min(max(count, range.lowerBound), range.upperBound)
        HStack(spacing: 0) {
            Button("Fewer", systemImage: "minus") { count = max(shown - step(below: shown), range.lowerBound) }
                .disabled(shown <= range.lowerBound)
            Text("\(shown)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(shown)))
                .frame(minWidth: 36)
                .animation(.snappy, value: shown)
            Button("More", systemImage: "plus") { count = min(shown + step(above: shown), range.upperBound) }
                .disabled(shown >= range.upperBound)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .frame(height: height)
        // The same shape as the toggles beside it, edged in the tile's colour, as it's the choice.
        .background(.fill.tertiary, in: .rect(cornerRadius: 14, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(color.opacity(0.7), lineWidth: 1.5) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number of questions")
        .accessibilityValue("\(shown)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: count = min(shown + step(above: shown), range.upperBound)
            case .decrement: count = max(shown - step(below: shown), range.lowerBound)
            @unknown default: break
            }
        }
    }

    private func step(above count: Int) -> Int {
        count < 20 ? 1 : count < 100 ? 5 : 10
    }

    private func step(below count: Int) -> Int {
        count <= 20 ? 1 : count <= 100 ? 5 : 10
    }
}
