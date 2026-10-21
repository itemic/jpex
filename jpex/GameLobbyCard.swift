import SwiftUI

/// Where the quiz starts, in two levels. On the first: the set of places, which can be swapped for
/// any other with a map; beneath it, the region to play, such as Europe, or on the World a group
/// of countries, such as the EU; a candy tile for each way to quiz yourself; and below them Learn,
/// a calm full-width card rather than candy, which leaves the quiz for the full map to browse every
/// place there instead. A tap on a tile opens its second level over the first, which sinks back, small and
/// faint, as if a step further away: how the tile plays, set out large, and Start, pinned to the
/// foot. Back brings the first level forward again.
struct GameLobbyCard<CollectionPicker: View>: View {
    @Bindable var game: MapGame
    var localLanguage: Bool
    /// Whether the card has room to spare, as beside the map on a wide screen, so its tiles can stand taller.
    var isRoomy = false
    /// Whether the card has little height to fill whatever the size class, as on the near side of
    /// iPhone Duo's fold when it's set down like a laptop, so it keeps short as it does on its side.
    var isShortOfHeight = false
    /// The most height the card can have, where it's limited, so a tile's second level can keep
    /// its Start in view.
    var maxHeight: CGFloat? = nil
    /// The places lighting up on the board behind, for a tile's second level to show by, such as
    /// their codes.
    var glowing: [AdministrativeDivision] = []
    /// Whether there's a full map to learn the places on, so Learn is offered at all: not for a
    /// set of places without a map, where the tile would only close the quiz.
    var canLearn = true
    /// The tile whose second level is open; nil on the first. The quiz holds it, so Escape steps
    /// back out of a tile before it closes the quiz.
    @Binding var openTile: MapGameMode?
    var onPlay: (MapGameMode) -> Void
    /// Leaves the quiz for Learn on the collection's full map.
    var onLearn: () -> Void
    /// Chooses another set of places, such as the World or Australia.
    @ViewBuilder var collectionPicker: () -> CollectionPicker
    @Environment(CustomWorldGroups.self) private var customGroups
    /// The groups of countries hidden from the sidebar in Settings, left out of the region menu too.
    @AppStorage(HiddenWorldGroups.storageKey) private var hiddenGroups = HiddenWorldGroups()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Short, as on iPhone on its side or iPhone Duo's outer display standing in a tent, where the
    /// title bar already names the places and chooses others, so the card leaves its name to it.
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    /// Counts each step between the levels, for a tick.
    @State private var steps = 0
    /// The first level's height, and how tall the open second level would like to be.
    @State private var firstLevelHeight: CGFloat = 0
    @State private var setupHeight: CGFloat = 0
    /// Every tile's height, Learn's included.
    @ScaledMetric(relativeTo: .headline) private var tileHeight = 54

    var body: some View {
        let isShort = isShortOfHeight || verticalSizeClass == .compact
        let isOpen = openTile != nil
        // Open, the card is as tall as either level, within the room there is, so the second
        // level's choices scroll there if they must and its Start stays at the foot.
        let openHeight = min(max(firstLevelHeight, setupHeight), maxHeight ?? .infinity)
        ZStack(alignment: .top) {
            firstLevel(isShort: isShort)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    if !isOpen, abs(height - firstLevelHeight) >= 0.5 { firstLevelHeight = height }
                }
                // Sunk back behind the second level: smaller, fainter and softer, a step away.
                .scaleEffect(isOpen && !reduceMotion ? 0.88 : 1)
                .opacity(isOpen ? 0.1 : 1)
                .blur(radius: isOpen && !reduceMotion ? 2 : 0)
                .allowsHitTesting(!isOpen)
                .accessibilityHidden(isOpen)
            if let openTile {
                GameModeSetup(
                    game: game, tile: openTile, localLanguage: localLanguage, isShort: isShort, glowing: glowing, onBack: back,
                    onStart: { mode in onPlay(mode) },
                    onIdealHeight: { height in
                        // Its height is only known once it's laid out, a moment after it opens, so
                        // the card grows to it on the opening's own curve rather than jumping there.
                        guard abs(height - setupHeight) >= 0.5 else { return }
                        withAnimation(openingCurve) { setupHeight = height }
                    })
                .frame(height: openHeight > 0 ? openHeight : nil)
                .id(openTile)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .scale(scale: 1.08).combined(with: .opacity),
                    removal: .scale(scale: 1.05).combined(with: .opacity)))
                .zIndex(1)
                // Escape on a keyboard steps back to the tiles, as VoiceOver's escape does.
                Button("Back", action: back)
                    .keyboardShortcut(.cancelAction)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: isOpen && openHeight > 0 ? openHeight : nil, alignment: .top)
        .fontDesign(.rounded)
        .sensoryFeedback(.selection, trigger: steps)
        .animation(openingCurve, value: openTile)
        // Other places, chosen from the title bar, start from the first level.
        .onChange(of: game.collection.id) { openTile = nil }
    }

    private func firstLevel(isShort: Bool) -> some View {
        VStack(alignment: .leading, spacing: isShort ? 10 : 14) {
            if !isShort {
                header
            }
            if GameOption.region.isOffered(in: game) {
                regionMenu
            }
            VStack(spacing: 8) {
                tiles
                if canLearn {
                    learnTile
                }
            }
        }
        .padding(isShort ? 14 : 18)
    }

    /// How a tile's second level opens over the first and closes again, and the card grows or
    /// shrinks to it: smoothly, or with Reduce Motion, a short fade.
    private var openingCurve: Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: 0.42)
    }

    /// Opens a tile's second level.
    private func open(_ tile: MapGameMode) {
        openTile = tile
        steps += 1
    }

    /// Back to the first level.
    private func back() {
        guard openTile != nil else { return }
        openTile = nil
        steps += 1
    }

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
                ScrollingText {
                    Text("\(game.places.count) \(game.collection.divisionLabel.lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        // A group with a flag of its own, such as the EU, shows it as a country would.
        if let flag = game.collection.flagAssetName {
            Image(flag)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 32)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        } else if let emblem = customGroups.emblem(for: game.collection) {
            // A group's symbol on its tile, or on a flag the person designed for it.
            WorldGroupBadge(emblem: emblem, symbolScale: 0.47)
                .frame(width: 48, height: 32)
                .clipShape(.rect(cornerRadius: 5))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        } else {
            Image(systemName: MapCenter.current.globeSymbolName)
                .font(.system(size: 34))
                .foregroundStyle(MapGameMode.nameIt.color.gradient)
        }
    }

    /// The region to play: everywhere, or one of the map's own regions, such as Kantō or Europe,
    /// and on the World, beneath them, a group of countries, such as the EU or one the person made,
    /// in a menu of its own. The pill shows a group by its short name, such as EU.
    private var regionMenu: some View {
        let option = GameOption.region
        // Groups hidden from the sidebar in Settings stay out of here too, unless one's in play.
        let groups = game.groupScopes.filter { !hiddenGroups.isHidden($0.id) || $0.id == game.scopeID }
        let regionNames = game.scopes.map { $0.displayName(localLanguage: localLanguage) }
        let groupNames = groups.map { $0.worldGroup?.shortName ?? $0.name }
        return Menu {
            Picker(option.title, selection: $game.scopeID) {
                Label("Everywhere", systemImage: "globe").tag(String?.none)
                ForEach(game.scopes) { group in
                    Text(group.displayName(localLanguage: localLanguage)).tag(String?.some(group.id))
                }
            }
            if !groups.isEmpty {
                Menu {
                    Picker(CollectionSection.worldGroupsTitle, selection: $game.scopeID) {
                        ForEach(groups) { group in
                            Label(group.name, systemImage: customGroups.emblem(for: group)?.symbolName ?? Self.groupsSymbol)
                                .tag(String?.some(group.id))
                        }
                    }
                } label: {
                    Text(CollectionSection.worldGroupsTitle)
                    if let chosen = game.scopedGroup {
                        Text(chosen.name)
                    }
                    Image(systemName: Self.groupsSymbol)
                }
            }
        } label: {
            OptionPill(
                symbolName: game.scopedGroup.flatMap { customGroups.emblem(for: $0)?.symbolName } ?? option.symbolName,
                value: game.scopeName(localLanguage: localLanguage) ?? "Everywhere",
                values: ["Everywhere"] + regionNames + groupNames)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityValue(game.scopedGroup?.name ?? game.scope?.name ?? "Everywhere")
        .sensoryFeedback(.selection, trigger: game.scopeID)
    }

    /// The symbol for groups of countries, beside them in the region menu.
    private static var groupsSymbol: String { "person.3.fill" }

    /// A candy tile for each way to quiz yourself, two to a row, or one at the largest text sizes,
    /// an odd one out at the foot spanning the row. Flag and Capital each have one tile for both
    /// their ways round.
    private var tiles: some View {
        let tiles = MapGameMode.tiles.filter { tile in tile.directions.contains(where: game.isAvailable) }
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        let rows = stride(from: 0, to: tiles.count, by: count).map { Array(tiles[$0..<min($0 + count, tiles.count)]) }
        return VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row) { tile in
                        ModeTile(mode: tile, hint: hint(for: tile), isRoomy: isRoomy) {
                            open(tile)
                        }
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// What a tile plays, for VoiceOver's hint, such as "Type the name of the prefecture that lights up".
    private func hint(for tile: MapGameMode) -> String {
        let ways = tile.directions.filter(game.isAvailable)
        let summaries = ways.map { $0.summary(placeNoun: game.collection.placeNoun, method: game.answerMethod(for: $0)) }
        return summaries.joined(separator: ", or ")
    }

    /// The Atlas, the grid's last row: as tall as the tiles and as wide as the row, glassy candy
    /// like them, in the Atlas's own indigo and dotted rather than striped, as somewhere to browse
    /// rather than a game, with an arrow out to the full map, where it opens.
    private var learnTile: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let color = MapGame.learnColor
        return Button(action: onLearn) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .accessibilityHidden(true)
                ScrollingText {
                    Text("Atlas")
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.forward")
                    .font(.subheadline.weight(.bold))
                    .accessibilityHidden(true)
            }
            .font(.headline.weight(.medium))
            .foregroundStyle(CandyGloss.lettering(on: color))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: tileHeight + (isRoomy ? 16 : 0))
            // Candy over a little tinted glass, which shows through it and lights its edge, as
            // the quiz's tiles are.
            .background { CandyGloss(color: color, pattern: .dots).opacity(0.82) }
            .clipShape(shape)
            .glassPanel(in: shape, tint: color)
            .overlay { GlassEdge(shape: shape) }
            .contentShape(shape)
            .shadow(color: color.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel("Atlas")
        .accessibilityHint("\(learnSummary), on the full map.")
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

/// Every option for the quiz, and where it's set: the region as a small menu on the lobby's first
/// level; how many questions, the time limits, the answer type and Auto-fill on a tile's second
/// level, with a mode's own kinds, such as Map's borders or Code's kinds of code; or in the toolbar. Each knows which modes it changes and
/// whether it's offered for these places, so a new option is a case here and its control where it's set.
enum GameOption: String, CaseIterable, Identifiable {
    case region, length, roundTime, questionTime, answerStyle, autoFill, borders, codeKind, outlineRotated, autoZoom

    var id: Self { self }

    /// Where an option is set.
    enum Placement: Equatable {
        /// As a small menu on the lobby's first level, for every mode.
        case inline
        /// On a tile's second level, for the modes it changes.
        case setup
        /// As a mode's own kinds, on its tile's second level.
        case subMode
        /// In the toolbar, as Auto Zoom is, to change mid-round.
        case toolbar
    }

    var placement: Placement {
        switch self {
        case .region: .inline
        case .length, .roundTime, .questionTime, .answerStyle, .autoFill: .setup
        case .borders, .codeKind, .outlineRotated: .subMode
        case .autoZoom: .toolbar
        }
    }

    /// Its name, as its section on a second level is headed and for VoiceOver.
    var title: String {
        switch self {
        case .region: "Region"
        case .length: "Questions"
        case .roundTime: "Game time limit"
        case .questionTime: "Question time limit"
        case .answerStyle: "Answer type"
        case .autoFill: "Auto-fill"
        case .borders: "Borders"
        case .codeKind: "Codes"
        case .outlineRotated: "Shapes"
        case .autoZoom: "Auto zoom"
        }
    }

    var symbolName: String {
        switch self {
        case .region: "mappin.and.ellipse"
        case .length: "list.number"
        case .roundTime: "timer"
        case .questionTime: "stopwatch"
        case .answerStyle: "character.cursor.ibeam"
        case .autoFill: "text.badge.plus"
        case .borders: "squareshape.split.2x2"
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
        case .region, .roundTime: available
        case .questionTime: available.filter { $0 != .listAll }
        case .length: available.filter { game.choosesRoundSize(for: $0) }
        case .answerStyle: available.filter { !$0.answerStyles.isEmpty }
        case .autoFill: available.filter { game.offersAutoFill(for: $0) }
        case .borders: available.filter(\.hidesBorders)
        case .codeKind: game.codeKinds.count > 1 ? available.filter { $0 == .code } : []
        case .outlineRotated: available.filter { $0 == .outline }
        case .autoZoom: available.filter { $0 != .findIt && $0 != .flags && $0 != .listAll }
        }
    }

    /// Whether it's offered for these places: a region only where there's more than one, or on
    /// the World, groups of countries to choose from, and how many only where there are more than ten.
    @MainActor
    func isOffered(in game: MapGame) -> Bool {
        switch self {
        case .region: !game.scopes.isEmpty || !game.groupScopes.isEmpty
        case .length: game.placesInScope.count > 10
        case .roundTime: true
        case .questionTime, .autoFill, .borders, .codeKind, .answerStyle, .outlineRotated, .autoZoom: !modes(in: game).isEmpty
        }
    }
}

/// A small menu's face in the lobby: a symbol, the value, and a chevron, on a capsule of glass. It's as
/// wide as its widest value, laid out unseen beneath the one shown, so changing it never resizes
/// the pill; the new value simply crossfades in.
private struct OptionPill: View {
    var symbolName: String
    var value: String
    /// Every value it can show, for its width.
    var values: [String]
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
                    .contentTransition(.interpolate)
            }
            .font(.footnote.weight(.medium))
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

/// A mode's candy tile, which keeps its size and its name whatever happens. It gives under the
/// finger as the Atlas tile beneath does, and tapped, it opens its second level.
private struct ModeTile: View {
    var mode: MapGameMode
    var hint: String
    var isRoomy: Bool
    var onTap: () -> Void
    @ScaledMetric(relativeTo: .headline) private var height = 54

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        let tall = height + (isRoomy ? 16 : 0)
        Button(action: onTap) {
            HStack(spacing: 7) {
                Image(systemName: mode.symbolName)
                ScrollingName(text: mode.name)
                Spacer(minLength: 0)
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
            .contentShape(shape)
            .shadow(color: mode.color.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mode.name)
        .accessibilityHint(hint)
    }
}

/// The light catching a glass tile's edge: brightest along the top, fading round the sides.
struct GlassEdge<S: InsettableShape>: View {
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
