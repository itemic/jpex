import SwiftUI

/// Where the quiz starts: the set of places, which can be swapped for any other with a map, a
/// candy tile for each way to quiz yourself, and below them Learn, a full-width tile in its own
/// indigo, dotted rather than striped, for browsing every place instead. Under the name, a row of small menus chooses which places to play, how many, any
/// time limit, and how to answer. A tap on a tile starts it; a tile with kinds of its own, as Code
/// has its kinds of code and Outline its upright or turned shapes, lifts and fans them out above
/// itself as small candy buttons, over whatever's there, and a tap on one starts that kind. A
/// second tap on the tile, or a tap anywhere else, fans them back in.
struct GameLobbyCard<CollectionPicker: View>: View {
    @Bindable var game: MapGame
    var localLanguage: Bool
    /// Whether the card has room to spare, as beside the map on a wide screen, so its tiles can stand taller.
    var isRoomy = false
    var onPlay: (MapGameMode) -> Void
    var onLearn: () -> Void
    /// Chooses another set of places, such as the World or Australia.
    @ViewBuilder var collectionPicker: () -> CollectionPicker
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Short, as on iPhone on its side or iPhone Duo's outer display standing in a tent, where the
    /// title bar already names the places and chooses others, so the card leaves its name to it.
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    /// The tile whose kinds have fanned out above it, waiting for one to be chosen.
    @State private var expanded: MapGameMode?
    /// Counts each tap that opens or closes a tile's kinds, for a tick: starting a game from one of
    /// them has a thump of its own instead.
    @State private var fanTaps = 0
    /// The width the tiles span, for keeping a fan within the card.
    @State private var tilesWidth: CGFloat = 0
    /// Every tile's height, Learn's included.
    @ScaledMetric(relativeTo: .headline) private var tileHeight = 54

    var body: some View {
        let isShort = verticalSizeClass == .compact
        VStack(alignment: .leading, spacing: isShort ? 10 : 14) {
            if !isShort {
                header
            }
            placesRow
                .opacity(expanded == nil ? 1 : Self.fadedOpacity)
                // While a fan is out, a tap here only puts it away.
                .allowsHitTesting(expanded == nil)
            VStack(spacing: 8) {
                tiles
                learnTile
                    .opacity(expanded == nil ? 1 : Self.fadedOpacity)
                // While a fan is out, a tap here only puts it away.
                .allowsHitTesting(expanded == nil)
            }
        }
        .padding(isShort ? 14 : 18)
        .fontDesign(.rounded)
        // A tap outside a tile's kinds sends them back.
        .contentShape(Rectangle())
        .onTapGesture {
            guard expanded != nil else { return }
            expanded = nil
            fanTaps += 1
        }
        .sensoryFeedback(.selection, trigger: fanTaps)
        .animation(.smooth(duration: 0.3), value: expanded)
    }

    /// How far everything but an open tile and its kinds fades back, so the choice stands out.
    private static var fadedOpacity: Double { 0.25 }

    private var header: some View {
        HStack(spacing: 12) {
            badge
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Menu {
                    collectionPicker()
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        ScrollingText {
                            Text(game.collection.name)
                                .typeStyle(.placeName)
                                .fontDesign(.default)
                        }
                        Image(systemName: "chevron.down")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Places to quiz on")
                .accessibilityValue(game.collection.name)
                Text("\(game.places.count) \(game.collection.divisionLabel.lowercased())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        if let group = game.collection.worldGroup {
            Image(systemName: group.symbolName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(group.symbolColor)
                .frame(width: 48, height: 32)
                .background(group.color.gradient, in: .rect(cornerRadius: 5))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        } else if let flag = game.collection.flagAssetName {
            Image(flag)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 32)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        } else {
            Image(systemName: MapCenter.current.globeSymbolName)
                .font(.system(size: 34))
                .foregroundStyle(MapGameMode.nameIt.color.gradient)
        }
    }

    /// Which places to play, how many, any time limit and how to answer: small menus side by
    /// side, each the same height, showing its value. They never wrap; where they don't fit, the
    /// row scrolls.
    @ViewBuilder
    private var placesRow: some View {
        let options = GameOption.allCases.filter { $0.placement == .inline && $0.isOffered(in: game) }
        if !options.isEmpty {
            let row = HStack(spacing: 6) {
                ForEach(options) { option in
                    menu(for: option)
                }
            }
            .fixedSize()
            ViewThatFits(in: .horizontal) {
                row
                    .frame(maxWidth: .infinity, alignment: .leading)
                ScrollView(.horizontal) { row }
                    .scrollIndicators(.hidden)
                    .contentMargins(.trailing, 20, for: .scrollContent)
                    // A soft edge where the row runs on, so a pill reads as more to scroll to,
                    // not cut off by the card.
                    .mask {
                        HStack(spacing: 0) {
                            Color.black
                            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 28)
                        }
                        .padding(.vertical, -12)
                    }
            }
        }
    }

    @ViewBuilder
    private func menu(for option: GameOption) -> some View {
        switch option {
        case .region:
            Menu {
                Picker(option.title, selection: $game.scopeID) {
                    Label("Everywhere", systemImage: "globe").tag(String?.none)
                    ForEach(game.scopes) { group in
                        Text(group.displayName(localLanguage: localLanguage)).tag(String?.some(group.id))
                    }
                }
            } label: {
                OptionPill(
                    symbolName: option.symbolName,
                    value: game.scope?.displayName(localLanguage: localLanguage) ?? "Everywhere",
                    values: ["Everywhere"] + game.scopes.map { $0.displayName(localLanguage: localLanguage) })
            }
            .buttonStyle(.plain)
            .accessibilityLabel(option.title)
            .accessibilityValue(game.scope?.name ?? "Everywhere")
            .sensoryFeedback(.selection, trigger: game.scopeID)
        case .length:
            let available = game.placesInScope.count
            // Ten, then any sets of the places people usually mean, such as the fifty states, then all.
            let value = switch game.roundSize {
            case .ten: "10"
            case .set: game.placeSet?.name ?? "All \(available)"
            case .all: "All \(available)"
            }
            Menu {
                Picker(option.title, selection: $game.roundSize) {
                    Text("10 places").tag(MapGame.RoundSize.ten)
                    ForEach(game.placeSets) { set in
                        Text(set.name).tag(MapGame.RoundSize.set(set.id))
                    }
                    Text("All \(available)").tag(MapGame.RoundSize.all)
                }
            } label: {
                OptionPill(
                    symbolName: option.symbolName, value: value,
                    // Room for the most there could be, so choosing a region never resizes it.
                    values: ["10", "All \(game.places.count)"]
                        + PlaceSet.sets(for: game.collection.id, among: game.places).map(\.name),
                    isNumeric: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(option.title)
            .accessibilityValue(game.roundSize == .ten ? "10 places" : game.placeSet?.name ?? "All \(available) places")
            .sensoryFeedback(.selection, trigger: game.roundSize)
        case .timeLimit:
            Menu {
                Picker(option.title, selection: $game.timeLimit) {
                    Text(MapGame.TimeLimit.off.menuName).tag(MapGame.TimeLimit.off)
                    Section("Per game") {
                        ForEach(MapGame.TimeLimit.roundChoices) { limit in
                            Text(limit.menuName).tag(limit)
                        }
                    }
                    Section("Per question") {
                        ForEach(MapGame.TimeLimit.questionChoices) { limit in
                            Text(limit.menuName).tag(limit)
                        }
                    }
                }
            } label: {
                OptionPill(
                    symbolName: option.symbolName, value: game.timeLimit.name,
                    values: ([.off] + MapGame.TimeLimit.roundChoices + MapGame.TimeLimit.questionChoices).map(\.name))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(option.title)
            .accessibilityValue(game.timeLimit.spokenName)
            .sensoryFeedback(.selection, trigger: game.timeLimit)
        case .answerStyle:
            Menu {
                Picker(option.title, selection: $game.answerStyle) {
                    ForEach(MapGame.AnswerStyle.allCases) { style in
                        Label(style.name, systemImage: style.symbolName).tag(style)
                    }
                }
            } label: {
                OptionPill(
                    symbolName: game.answerStyle.symbolName, value: game.answerStyle.name,
                    values: MapGame.AnswerStyle.allCases.map(\.name))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(option.title)
            .accessibilityValue(game.answerStyle.spokenName)
            .accessibilityHint(game.isAvailable(.flags) ? "Flag is always chosen: multiple choice, or from the list when Type is chosen." : "")
            .sensoryFeedback(.selection, trigger: game.answerStyle)
        case .codeKind, .outlineRotated, .autoZoom:
            EmptyView()
        }
    }

    /// A candy tile for each way to quiz yourself, two to a row, or one at the largest text sizes,
    /// an odd one out at the foot spanning the row. A tile's kinds fan out over the tiles above it,
    /// so nothing moves and every tile keeps its size.
    private var tiles: some View {
        let modes = MapGameMode.allCases.filter { game.isAvailable($0) }
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        let rows = stride(from: 0, to: modes.count, by: count).map { Array(modes[$0..<min($0 + count, modes.count)]) }
        return VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(Array(row.enumerated()), id: \.element) { column, mode in
                        tile(mode, column: column, of: row.count)
                            .zIndex(expanded == mode ? 1 : 0)
                    }
                }
                // The open fan's row draws over the rest.
                .zIndex(row.contains { $0 == expanded } ? 1 : 0)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
            if GameLobbyGeometry.isWorthUpdating(from: tilesWidth, to: width) { tilesWidth = width }
        }
    }

    private func tile(_ mode: MapGameMode, column: Int, of columns: Int) -> some View {
        let kinds = subModes(of: mode)
        // Where the tile's middle sits across the tiles, for keeping its fan within the card.
        let tileWidth = (tilesWidth - 8 * CGFloat(columns - 1)) / CGFloat(columns)
        let middle = CGFloat(column) * (tileWidth + 8) + tileWidth / 2
        return ModeTile(
            mode: mode, hint: mode.summary(placeNoun: game.collection.placeNoun, method: game.answerMethod(for: mode)),
            hasKinds: !kinds.isEmpty, isExpanded: expanded == mode, isRoomy: isRoomy
        ) {
            withAnimation(.bouncy(duration: 0.4)) {
                if kinds.isEmpty {
                    expanded = nil
                } else {
                    expanded = expanded == mode ? nil : mode
                    fanTaps += 1
                }
            }
            if kinds.isEmpty { onPlay(mode) }
        } onPlayNow: {
            if let kind = kinds.first(where: \.isOn) ?? kinds.first {
                start(mode, as: kind)
            } else {
                expanded = nil
                onPlay(mode)
            }
        }
        .opacity(expanded == nil || expanded == mode ? 1 : Self.fadedOpacity)
        // Another tile, while a fan is out, only puts the fan away: the tap falls to the card.
        .allowsHitTesting(expanded == nil || expanded == mode)
        .overlay(alignment: .top) {
            if !kinds.isEmpty {
                KindFan(
                    mode: mode, kinds: kinds, isOpen: expanded == mode, tileMiddle: middle, room: tilesWidth
                ) { kind in
                    start(mode, as: kind)
                }
            }
        }
    }

    /// Starts a mode as one of its kinds, remembering it.
    private func start(_ mode: MapGameMode, as kind: Chip) {
        kind.select()
        expanded = nil
        onPlay(mode)
    }

    /// A mode's own kinds, as chips that start it that way, the one played last filled: Code's
    /// kinds of code, where these places have more than one, and Outline's upright or turned shapes.
    private func subModes(of mode: MapGameMode) -> [Chip] {
        guard let option = GameOption.allCases.first(where: { $0.placement == .subMode && $0.modes(in: game).contains(mode) })
        else { return [] }
        switch option {
        case .codeKind:
            return game.codeKinds.map { kind in
                Chip(id: kind.rawValue, label: kind.name, name: kind.summary, isOn: game.shownCodeKind == kind) {
                    game.codeKind = kind
                }
            }
        case .outlineRotated:
            return [
                Chip(id: "upright", label: "Upright", name: "Upright shapes", isOn: !game.outlineRotated) {
                    game.outlineRotated = false
                },
                Chip(id: "rotated", label: "Rotated", name: "Rotated shapes", isOn: game.outlineRotated) {
                    game.outlineRotated = true
                },
            ]
        case .region, .length, .timeLimit, .answerStyle, .autoZoom:
            return []
        }
    }

    /// Learn, the grid's last row: a candy tile as tall as the rest and as wide as the row, in its
    /// own calm indigo with dots rather than stripes, as somewhere to browse rather than a game.
    private var learnTile: some View {
        Button(action: onLearn) {
            HStack(spacing: 7) {
                Image(systemName: "book.fill")
                    .accessibilityHidden(true)
                Text("Learn & Practice")
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .opacity(0.8)
                    .accessibilityHidden(true)
            }
            .font(.headline.weight(.medium))
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: tileHeight + (isRoomy ? 16 : 0))
        }
        .buttonStyle(CandyButtonStyle(
            color: MapGame.learnColor, pattern: .dots, shape: RoundedRectangle(cornerRadius: 20, style: .continuous)))
        .overlay { GlassEdge(shape: RoundedRectangle(cornerRadius: 20, style: .continuous)) }
        .accessibilityHint(learnSummary)
    }

    /// What Learn holds for each place, such as "Where each prefecture is, its flag and its capital".
    private var learnSummary: String {
        var parts = ["Where each \(game.collection.placeNoun) is"]
        if !game.flagPlaces.isEmpty { parts.append("its flag") }
        if !game.capitals.isEmpty { parts.append("its capital") }
        return parts.formatted(.list(type: .and))
    }

}

// MARK: Options

/// Every option for the quiz, and where it's set: as the row of small menus in the lobby card, as
/// a mode's own kinds on its tile, or in the toolbar. Each knows which modes it changes and whether
/// it's offered for these places, so a new option is a case here and its control where it's set.
enum GameOption: String, CaseIterable, Identifiable {
    // In the order the lobby's row shows them.
    case region, length, timeLimit, answerStyle, codeKind, outlineRotated, autoZoom

    var id: Self { self }

    /// Where an option is set.
    enum Placement: Equatable {
        /// As a small menu in the lobby card's row, for every mode it changes.
        case inline
        /// As a mode's own kinds, chips on its tile that start it.
        case subMode
        /// In the toolbar, as Auto Zoom is, to change mid-round.
        case toolbar
    }

    var placement: Placement {
        switch self {
        case .region, .length, .timeLimit, .answerStyle: .inline
        case .codeKind, .outlineRotated: .subMode
        case .autoZoom: .toolbar
        }
    }

    /// Its name, for VoiceOver.
    var title: String {
        switch self {
        case .region: "Region"
        case .length: "How many"
        case .timeLimit: "Time limit"
        case .answerStyle: "Answer by"
        case .codeKind: "Code"
        case .outlineRotated: "Shapes"
        case .autoZoom: "Auto Zoom"
        }
    }

    var symbolName: String {
        switch self {
        case .region: "mappin.and.ellipse"
        case .length: "list.number"
        case .timeLimit: "timer"
        case .answerStyle: "character.cursor.ibeam"
        case .codeKind: "barcode"
        case .outlineRotated: "rotate.right"
        case .autoZoom: "plus.magnifyingglass"
        }
    }

    /// The modes it changes.
    @MainActor
    func modes(in game: MapGame) -> [MapGameMode] {
        let available = MapGameMode.allCases.filter { game.isAvailable($0) }
        return switch self {
        case .region, .length, .timeLimit: available
        case .answerStyle: available.filter(\.takesAnswerStyle)
        case .codeKind: game.codeKinds.count > 1 ? available.filter { $0 == .code } : []
        case .outlineRotated: available.filter { $0 == .outline }
        case .autoZoom: available.filter { $0 != .findIt && $0 != .flags }
        }
    }

    /// Whether it's offered for these places: a region only where there's more than one, and how
    /// many only where there are more than ten.
    @MainActor
    func isOffered(in game: MapGame) -> Bool {
        switch self {
        case .region: !game.scopes.isEmpty
        case .length: game.placesInScope.count > 10
        case .timeLimit: true
        case .codeKind, .answerStyle, .outlineRotated, .autoZoom: !modes(in: game).isEmpty
        }
    }
}

/// One of a mode's kinds on its tile, such as Car codes in Code, or Rotated in Outline.
private struct Chip: Identifiable {
    var id: String
    var label: String
    /// What it is, for VoiceOver.
    var name: String
    var isOn: Bool
    var select: () -> Void
}

/// A small menu's face in the lobby: a symbol, the value, and a chevron, on a capsule of glass. It's as
/// wide as its widest value, laid out unseen beneath the one shown, so changing it never resizes
/// the pill; the new value simply crossfades in.
private struct OptionPill: View {
    var symbolName: String
    var value: String
    /// Every value it can show, for its width.
    var values: [String]
    /// Whether the values are counts, which roll from one to the next.
    var isNumeric = false
    @ScaledMetric(relativeTo: .footnote) private var height = 30
    @ScaledMetric(relativeTo: .footnote) private var symbolWidth = 16

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbolName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: symbolWidth)
                .contentTransition(.symbolEffect(.replace))
            ZStack(alignment: .leading) {
                ForEach(Array(Set(values + [value])).sorted(), id: \.self) { candidate in
                    Text(candidate).hidden()
                }
                Text(value)
                    .contentTransition(isNumeric ? .numericText() : .interpolate)
            }
            .font(.footnote.weight(.medium))
            .monospacedDigit()
            .lineLimit(1)
            .fixedSize()
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 11)
        .frame(height: height)
        .glassPanel(in: Capsule(), interactive: true)
        .contentShape(Capsule())
        .animation(.snappy(duration: 0.25), value: value)
        .animation(.snappy(duration: 0.25), value: symbolName)
    }
}

/// A mode's candy tile, which keeps its size and its name whatever happens. Tapped, it starts the
/// mode, or where the mode has kinds of its own, it lifts with a soft glow and a fine white edge
/// while they're out beneath it, its chevron turning; tapped again, it settles back.
private struct ModeTile: View {
    var mode: MapGameMode
    var hint: String
    var hasKinds: Bool
    var isExpanded: Bool
    var isRoomy: Bool
    var onTap: () -> Void
    var onPlayNow: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .headline) private var height = 54

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let tall = height + (isRoomy ? 16 : 0)
        HStack(spacing: 7) {
            Image(systemName: mode.symbolName)
            Text(mode.name)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            if hasKinds {
                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.bold))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .opacity(0.8)
            }
        }
        .font(.headline.weight(.medium))
        .foregroundStyle(CandyGloss.lettering(on: mode.color))
        .padding(.horizontal, 12)
        .accessibilityHidden(true)
        .frame(maxWidth: .infinity)
        .frame(height: tall)
        // Candy over a little tinted glass, which shows through it and lights its edge.
        .background { CandyGloss(color: mode.color, pattern: .candyStripes).opacity(0.82) }
        .clipShape(shape)
        .glassPanel(in: shape, tint: mode.color)
        .overlay { GlassEdge(shape: shape) }
        .overlay { shape.strokeBorder(.white.opacity(isExpanded ? 0.85 : 0), lineWidth: 2) }
        .contentShape(shape)
        .shadow(color: mode.color.opacity(isExpanded ? 0.6 : 0.35), radius: isExpanded ? 14 : 8, y: isExpanded ? 6 : 4)
        .scaleEffect(isExpanded && !reduceMotion ? 1.03 : 1)
        .zIndex(isExpanded ? 1 : 0)
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mode.name)
        .accessibilityValue(hasKinds ? (isExpanded ? "Expanded" : "Collapsed") : "")
        .accessibilityHint(hasKinds ? (isExpanded ? "Hides its kinds." : "Shows its kinds. \(hint)") : hint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Play now", onPlayNow)
        .accessibilityAction(.escape) { if isExpanded { onTap() } }
    }
}

/// A mode's kinds, fanned out above its tile over whatever's there: small candy buttons in the
/// tile's colour, in one gentle arc, or two for six or seven, each tilted a little outward like
/// cards in a hand. They spring out from the tile's middle one after another, and fold back into it
/// in reverse; the fan keeps within the tiles' width. Each is a way to start, all filled alike.
/// With Reduce Motion they fade and scale in place.
private struct KindFan: View {
    var mode: MapGameMode
    var kinds: [Chip]
    var isOpen: Bool
    /// Where the tile's middle sits across the tiles.
    var tileMiddle: CGFloat
    /// The width the tiles span, which the fan keeps within.
    var room: CGFloat
    var onStart: (Chip) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var fanWidth: CGFloat = 0
    @State private var fanHeight: CGFloat = 0
    /// Each button's middle within the fan, by kind, for flying it from the tile.
    @State private var middles: [String: CGPoint] = [:]
    @ScaledMetric(relativeTo: .headline) private var tileHeight = 54

    private static let gap: CGFloat = 18
    private static let margin: CGFloat = 2

    /// The most buttons one arc holds: four where the card is wide enough, as on most iPhones; three
    /// on a narrower card or with larger text; two at the largest text sizes.
    private var perArc: Int {
        if dynamicTypeSize.isAccessibilitySize { return 2 }
        return room >= 340 && dynamicTypeSize <= .large ? 4 : 3
    }

    /// The arcs, nearest the tile last: as few as fit, shared out evenly, the outer ones fuller,
    /// such as Code's eight kinds of code in two arcs of four, or three arcs on a narrow phone.
    private var arcs: [[Chip]] {
        let count = (kinds.count + perArc - 1) / perArc
        guard count > 1 else { return [kinds] }
        var arcs: [[Chip]] = []
        var start = 0
        for index in 0..<count {
            let arcsLeft = count - index
            let size = (kinds.count - start + arcsLeft - 1) / arcsLeft
            arcs.append(Array(kinds[start..<(start + size)]))
            start += size
        }
        return arcs
    }

    /// How far the fan slides sideways to stay within the tiles.
    private var shift: CGFloat {
        guard fanWidth > 0, room > 0 else { return 0 }
        let half = fanWidth / 2 + Self.margin
        let centre = min(max(tileMiddle, half), max(room - half, half))
        return centre - tileMiddle
    }

    var body: some View {
        let arcs = arcs
        VStack(spacing: 8) {
            ForEach(Array(arcs.enumerated()), id: \.offset) { arcIndex, arc in
                HStack(spacing: 6) {
                    ForEach(Array(arc.enumerated()), id: \.element.id) { position, kind in
                        // The arcs nearer the tile fly out first.
                        let order = position + arcs[(arcIndex + 1)...].reduce(0) { $0 + $1.count }
                        button(kind, position: position, of: arc.count, order: order)
                    }
                }
            }
        }
        .coordinateSpace(.named(fanSpace))
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            if GameLobbyGeometry.isWorthUpdating(from: fanWidth, to: size.width) { fanWidth = size.width }
            if GameLobbyGeometry.isWorthUpdating(from: fanHeight, to: size.height) { fanHeight = size.height }
        }
        // Its foot a little above the tile's top: laid over the tile's top edge, then lifted by its
        // own height, which holds wherever the overlay is drawn.
        .offset(x: shift, y: -(fanHeight + Self.gap))
        .allowsHitTesting(isOpen)
        .accessibilityHidden(!isOpen)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(mode.name) kinds")
    }

    private var fanSpace: String { "fan-\(mode.rawValue)" }

    private func button(_ kind: Chip, position: Int, of count: Int, order: Int) -> some View {
        // From -1 at the arc's leading end to 1 at its trailing end.
        let spread = count > 1 ? CGFloat(position) / CGFloat(count - 1) * 2 - 1 : 0
        let middle = middles[kind.id] ?? .zero
        // The tile's middle, as seen from the button.
        let home = CGPoint(
            x: fanWidth / 2 - shift - middle.x,
            y: (middles.values.map(\.y).max() ?? 0) + 16 + Self.gap + tileHeight / 2 - middle.y)
        let flies = !reduceMotion
        return Button {
            onStart(kind)
        } label: {
            Text(kind.label)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
        }
        // Each one a way to start, not a setting, so all of them are filled alike.
        .buttonStyle(CandyButtonStyle(color: mode.color, pattern: .candyStripes))
        .onGeometryChange(for: CGPoint.self) { proxy in
            let frame = proxy.frame(in: .named(fanSpace))
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { middle in
            guard middle.x.isFinite, middle.y.isFinite else { return }
            if let old = middles[kind.id], !GameLobbyGeometry.isWorthUpdating(from: old.x, to: middle.x),
               !GameLobbyGeometry.isWorthUpdating(from: old.y, to: middle.y) { return }
            middles[kind.id] = middle
        }
        // An arc: the ends dip a little and lean outward.
        .rotationEffect(.degrees(isOpen ? Double(spread) * 7 : (flies ? Double(spread) * -25 : 0)))
        .offset(y: isOpen ? abs(spread) * abs(spread) * 7 : 0)
        .offset(x: isOpen || !flies ? 0 : home.x, y: isOpen || !flies ? 0 : home.y)
        .scaleEffect(isOpen ? 1 : (flies ? 0.2 : 0.85))
        .opacity(isOpen ? 1 : 0)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .bouncy(duration: isOpen ? 0.5 : 0.35, extraBounce: isOpen ? 0.25 : 0)
                    .delay(Double(isOpen ? order : max(kinds.count - 1 - order, 0)) * 0.035),
            value: isOpen)
        .accessibilityLabel(kind.name)
        .accessibilityHint("Starts \(mode.name).")
    }
}

/// Measurements the lobby keeps for laying out its tiles and fans. A change of a fraction of a
/// point, or no number at all, as while the lobby is still scaling in, doesn't count: storing it
/// would lay the lobby out again, measure again and store again, without end, and the game would
/// never open.
private enum GameLobbyGeometry {
    static func isWorthUpdating(from old: CGFloat, to new: CGFloat) -> Bool {
        new.isFinite && abs(new - old) >= 0.5
    }
}

/// The light catching a glass tile's edge: brightest along the top, fading round the sides.
private struct GlassEdge<S: InsettableShape>: View {
    var shape: S

    var body: some View {
        shape
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.75), .white.opacity(0.12), .white.opacity(0.3)],
                    startPoint: .top, endPoint: .bottom),
                lineWidth: 1)
            .allowsHitTesting(false)
    }
}
