import SwiftUI

/// Learn: every place in a deck as a row of glass cards to swipe through, one for each place, with
/// the cards either side peeking in. Each card holds its place's name and region, its own flag where
/// it has one, its capitals where they're known, and its codes, each labelled. A slim header above
/// the row counts through the places, and opens a list of them all to jump to, with round glass
/// arrows that step along. Beneath the row, a scrubber runs through every place, marked out by
/// region: drag along it to race through them. The arrow keys and VoiceOver step too, and tapping
/// a card either side or a place on the map scrolls the row to it. Whenever the row comes to rest
/// on a card, the map lights up its place. It's calm glass throughout, the quiz's candy left to
/// the quizzes, and it works from a `LearnDeck` alone, so any map can show it.
struct GameLearnCard: View {
    var deck: LearnDeck
    var localLanguage: Bool
    /// Whether the row has room of its own, as on the near side of iPhone Duo's fold.
    var isRoomy: Bool
    /// Whether the cards take their most condensed form, where room is short, as in a column beside
    /// the map in landscape: smaller type and a tighter grid, so more of a place shows at once.
    var isCondensed = false
    /// Steps on or back through the places: by the arrows, the arrow keys, VoiceOver, or a tap on
    /// a card either side.
    var onStep: (Int) -> Void
    /// Shows a place: the one the row came to rest on after a swipe, or the card in the middle, tapped.
    var onShow: (AdministrativeDivision) -> Void
    /// Jumps to a place by its position: as the scrubber is dragged, and once more, finished, as
    /// it's let go or a place is picked from the list.
    var onScrub: (Int, Bool) -> Void
    /// The most height there is for the whole of Learn, header and scrubber included, where it's
    /// limited, as in a column beside the map. Taller cards scroll within their glass.
    var maxHeight: CGFloat?
    /// Set where Learn sits over the foot of a narrow screen: how far past the screen's safe area
    /// its glass runs on, off the bottom edge, so the cards read as a sheet that scrolls rather
    /// than boxes cut short. The scrubber then sits under the header instead of beneath the cards.
    var bottomBleed: CGFloat?
    /// What the place in the middle has of its own to learn, such as Prefectures for Japan, offered
    /// beside the count as a way into it.
    var subcollectionLabel: String?
    var onOpenSubcollection: () -> Void
    /// What each card adds after its codes, such as a country's side of the road and plugs: by
    /// default all the Atlas knows, and from a map showing one of its layers, that layer's fact first.
    var facts: (AdministrativeDivision) -> [MapFact]
    /// Opens the map's layers, to leave the Atlas for another layer: the header's "Atlas" title,
    /// as every layer's key names its layer.
    var onShowLayers: () -> Void = {}
    /// Puts the Atlas away altogether, from the small glass cross at the header's end.
    var onClose: () -> Void = {}
    /// The person's level for the place in the middle, shown as its pill in the header to climb
    /// with a tap, or set from every level with a touch and hold. Without it, no pill.
    var status: Binding<VisitLevel>? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The card in the middle of the row, kept in step with the place shown.
    @State private var centredID: String?
    @State private var rowWidth: CGFloat = 0
    /// Each card's own height as last measured, by place, so every card in the row stands as tall
    /// as the tallest, and a card measured taller mid-change, as while the device turns, doesn't
    /// hold the row tall once it measures shorter.
    @State private var cardHeights: [String: CGFloat] = [:]
    /// Whether the scrubber is being dragged, so the row keeps up without gliding.
    @State private var isScrubbing = false
    /// The position a swipe is coming to rest on, worked out as the finger lifts and shown on the
    /// map at once, so the row's own glide into place isn't scrolled over again as it follows.
    @State private var predictedIndex: Int?
    @AccessibilityFocusState private var focusedID: String?
    @ScaledMetric(relativeTo: .subheadline) private var stepperSize: CGFloat = usualStepperSize
    /// The header's round buttons at the usual text size, which `chrome` allows for.
    private static let usualStepperSize: CGFloat = 34

    /// How far into the row the cards either side reach, gap included: in a narrow column, as
    /// beside the map on iPhone Duo closed and on its side, only a sliver, so the card in the
    /// middle keeps the room and its neighbours don't crowd the bar beside them.
    private var peek: CGFloat {
        rowWidth < 440 ? 16 : 26
    }
    private static let spacing: CGFloat = 10
    private static let widestCard: CGFloat = 440
    private static let widestShortCard: CGFloat = 720
    /// The header, the row's room for shadows and the scrubber, around the cards.
    private static let chrome: CGFloat = 130
    /// The same where room is short, the row's room for shadows 10 points less.
    private static let compactChrome: CGFloat = 120
    /// The header, the scrubber beneath it and the room between, above cards that run off the
    /// screen's foot.
    private static let bleedingChrome: CGFloat = 92
    /// The room the scrubber takes, which condensed cards have instead.
    private static let scrubberRoom: CGFloat = 34
    /// Below this much height for the whole of Learn, the cards and the room around them tighten,
    /// so the header and a whole card still fit, as on iPhone in landscape.
    private static let compactBelow: CGFloat = 440

    init(
        deck: LearnDeck, localLanguage: Bool, isRoomy: Bool, isCondensed: Bool = false, maxHeight: CGFloat? = nil,
        bottomBleed: CGFloat? = nil,
        onStep: @escaping (Int) -> Void,
        onShow: @escaping (AdministrativeDivision) -> Void, onScrub: @escaping (Int, Bool) -> Void,
        subcollectionLabel: String? = nil, facts: @escaping (AdministrativeDivision) -> [MapFact] = MapColouring.facts(about:),
        onOpenSubcollection: @escaping () -> Void = {},
        onShowLayers: @escaping () -> Void = {}, onClose: @escaping () -> Void = {},
        status: Binding<VisitLevel>? = nil
    ) {
        self.deck = deck
        self.localLanguage = localLanguage
        self.isRoomy = isRoomy
        self.isCondensed = isCondensed
        self.maxHeight = maxHeight
        self.bottomBleed = bottomBleed
        self.onStep = onStep
        self.onShow = onShow
        self.onScrub = onScrub
        self.subcollectionLabel = subcollectionLabel
        self.facts = facts
        self.onOpenSubcollection = onOpenSubcollection
        self.onShowLayers = onShowLayers
        self.onClose = onClose
        self.status = status
        _centredID = State(initialValue: deck.current?.id)
    }

    /// The height every card in the row stands at: that of the tallest of the card in the middle
    /// and the ones either side, so the row holds still through a swipe, then settles to the
    /// cards around the new one, rather than staying as tall as the tallest seen.
    private var cardHeight: CGFloat {
        guard deck.places.indices.contains(deck.index) else { return cardHeights.values.max() ?? 0 }
        let nearby = max(deck.index - 1, 0)...min(deck.index + 1, deck.places.count - 1)
        return nearby.compactMap { cardHeights[deck.places[$0].id] }.max() ?? cardHeights.values.max() ?? 0
    }

    /// The card in the middle's width: at most 440 points, or where room is short but wide, as
    /// beside iPhone Duo's fold, up to 720, so its codes can sit more to a row and the card stays
    /// short enough to show whole.
    private var cardWidth: CGFloat {
        min(max(rowWidth - 2 * peek, 0), isCompact ? Self.widestShortCard : Self.widestCard)
    }

    /// Whether room is short, so the cards take their compact form and the row tightens around them.
    private var isCompact: Bool {
        (maxHeight ?? .infinity) < Self.compactBelow || isCondensed
    }

    /// The room either side of the card in the middle, which lines the header and scrubber up with it.
    private var sideMargin: CGFloat {
        max((rowWidth - cardWidth) / 2, 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if rowWidth > 0 {
                if isCondensed {
                    // Condensed, the scrubber folds away, the count's list, a swipe and the
                    // arrows still moving through the places, so the card has the room.
                    row
                        .padding(.top, 4)
                } else if bottomBleed != nil {
                    // The cards run off the screen's foot, so the scrubber comes up under the header.
                    scrubber
                        .padding(.top, 8)
                    row
                } else {
                    row
                    scrubber
                        .padding(.bottom, 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        // Cards that run off the screen's foot rest on it, the sheet sliding off the edge, rather
        // than floating in the middle of the room.
        .frame(maxHeight: isRoomy ? .infinity : nil, alignment: bottomBleed != nil ? .bottom : .center)
        .background { keyboardSteps }
        .fontDesign(.rounded)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
            guard abs(width - rowWidth) > 0.5 else { return }
            rowWidth = width
            cardHeights = [:]
        }
        .onChange(of: deck.index) { old, _ in follow(from: old) }
        .onChange(of: dynamicTypeSize) { cardHeights = [:] }
        // Cards are measured afresh whenever the room, the text size or the places change.
        .onChange(of: maxHeight) { cardHeights = [:] }
        .onChange(of: ObjectIdentifier(deck)) { cardHeights = [:] }
        .onChange(of: deck.collection.id) { cardHeights = [:] }
    }

    private var scrubber: some View {
        LearnScrubber(
            count: deck.count, index: deck.index, sections: deck.sections,
            sectionNames: deck.sections.map { $0.name(localLanguage: localLanguage) },
            name: { deck.places.indices.contains($0) ? deck.places[$0].displayName(localLanguage: localLanguage) : "" },
            isScrubbing: $isScrubbing, onScrub: onScrub)
            .zIndex(1)
            .padding(.horizontal, sideMargin)
    }

    /// The header: "Atlas", which opens the map's layers, as every layer's key names its layer;
    /// how far through the places, which opens the list of them all to jump to; beside it, where the
    /// place has places of its own, such as Japan its prefectures, a way into learning those; then
    /// the person's level for the place, the arrows and a small cross that puts the Atlas away.
    /// Where it's narrow, the region's name goes first, then the way in shortens, then the arrows
    /// and the way in go; the title, the count, the level and the cross always stay, so there's
    /// always a plain way back to the layers and out.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            headerRow(showsRegion: true, isLinkShort: false)
            headerRow(showsRegion: false, isLinkShort: false)
            headerRow(showsRegion: false, isLinkShort: true)
            // In a narrow column, such as beside the map on iPhone Duo closed and on its side, the
            // arrows go, the cards still swiping, the scrubber still running through them and the
            // arrow keys still stepping; narrower still, the way into a place's own places too;
            // and narrower again, the title keeps only its book.
            headerRow(showsRegion: false, isLinkShort: true, showsSteppers: false)
            headerRow(showsRegion: false, isLinkShort: true, showsSteppers: false, showsLink: false)
            headerRow(
                showsRegion: false, isLinkShort: true, showsSteppers: false, showsLink: false, showsTitleName: false)
            // Narrowest of all, as in Split View's slimmest column or with the largest text, the
            // header reaches out over the cards peeking in either side, so the title, the count,
            // the level and the cross still fit rather than running off the edge.
            headerRow(
                showsRegion: false, isLinkShort: true, showsSteppers: false, showsLink: false, showsTitleName: false,
                margin: min(sideMargin, 8))
            // And at the very largest text, the count keeps only the place's number, the total
            // still read out by VoiceOver.
            headerRow(
                showsRegion: false, isLinkShort: true, showsSteppers: false, showsLink: false, showsTitleName: false,
                showsTotal: false, margin: min(sideMargin, 8))
        }
        .animation(Motion.moving(.snappy, reduceMotion: reduceMotion), value: deck.index)
        .animation(Motion.moving(.bouncy(duration: 0.4), reduceMotion: reduceMotion), value: subcollectionLabel)
    }

    private func headerRow(
        showsRegion: Bool, isLinkShort: Bool, showsSteppers: Bool = true, showsLink: Bool = true,
        showsTitleName: Bool = true, showsTotal: Bool = true, margin: CGFloat? = nil
    ) -> some View {
        HStack(spacing: 8) {
            title(showsName: showsTitleName)
            jumpMenu(showsRegion: showsRegion, showsTotal: showsTotal)
            if showsLink, let subcollectionLabel {
                subcollectionLink(subcollectionLabel, isShort: isLinkShort)
                    .transition(.arrive(reduceMotion: reduceMotion, anchor: .leading))
            }
            Spacer(minLength: 0)
            levelPill
            if showsSteppers {
                stepButton("Previous", systemImage: "chevron.left", by: -1, isEnabled: !deck.isAtStart)
                stepButton("Next", systemImage: "chevron.right", by: 1, isEnabled: !deck.isAtEnd)
            }
            closeButton
        }
        // Lined up with the card in the middle, unless told otherwise.
        .padding(.horizontal, margin ?? sideMargin)
    }

    /// "Atlas" and its book in a capsule of glass, which opens the map's layers to choose another,
    /// a small chevron saying so, as each layer's key does with its own name.
    private func title(showsName: Bool) -> some View {
        Button(action: onShowLayers) {
            HStack(spacing: 7) {
                Image(systemName: "book.fill")
                    .foregroundStyle(MapGame.learnColor)
                if showsName {
                    ScrollingName(text: "Atlas")
                        .fixedSize()
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .padding(.horizontal, 13)
            .frame(minHeight: stepperSize)
            .fixedSize()
            .glassPanel(in: Capsule(), interactive: true)
            .contentShape(Capsule())
        }
        // A pill as wide as its name, so it gives only a little under the finger, as a key's
        // title does; the round buttons beside it give their full squish.
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .layoutPriority(2)
        .accessibilityLabel("Atlas")
        .accessibilityHint("Shows the layers, to choose another.")
        .accessibilityAddTraits(.isHeader)
    }

    /// How far through the places, with the region where places are told apart by region, which
    /// opens the list of them all to jump to, a surprise first.
    private func jumpMenu(showsRegion: Bool, showsTotal: Bool = true) -> some View {
        Menu {
            if deck.count > 1 {
                Button("Surprise me", systemImage: "dice", action: surprise)
                Divider()
            }
            jumpList
        } label: {
            HStack(spacing: 7) {
                // The region the place is in, where places are told apart by region.
                if showsRegion, deck.showsRegions, let section = deck.currentSection {
                    Text(section.name(localLanguage: localLanguage))
                        .foregroundStyle(MapGame.learnColor)
                        .contentTransition(.interpolate)
                }
                HStack(spacing: 0) {
                    Text("\(deck.index + 1)")
                        .typeStyle(.count)
                        .contentTransition(.numericText(value: Double(deck.index)))
                    if showsTotal {
                        Text(" / \(deck.count)")
                            .typeStyle(.countTotal)
                    }
                }
                .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .font(.subheadline.weight(.regular))
            .lineLimit(1)
            .padding(.horizontal, 13)
            .frame(minHeight: stepperSize)
            .fixedSize()
            .glassPanel(in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .layoutPriority(1)
        // Read straight after the title, so VoiceOver says "Atlas", then "3 of 195".
        .accessibilityLabel("\(deck.index + 1) of \(deck.count)")
        .accessibilityValue(showsRegion && deck.showsRegions ? deck.currentSection?.name(localLanguage: localLanguage) ?? "" : "")
        .accessibilityHint("Opens a list of every place to jump to.")
    }

    /// Jumps to any place but the one shown, by the same way as a pick from the list, so the row
    /// scrolls, the globe turns and the map glides there, and the card lands as a search's pick
    /// does: it pops, rings itself in light and lights its name, or with Reduce Motion only lights.
    private func surprise() {
        guard deck.count > 1 else { return }
        var position = Int.random(in: 0..<(deck.count - 1))
        if position >= deck.index { position += 1 }
        pickPlace(at: position)
    }

    /// Goes to a place picked from the list, or by a surprise, and lands its card there.
    private func pickPlace(at position: Int) {
        guard deck.places.indices.contains(position) else { return }
        onScrub(position, true)
        deck.land(on: LearnSearch.Result(place: deck.places[position], index: position, match: .name))
    }

    /// The person's level for the place in the middle, as a round badge the size of the header's
    /// other round buttons: its level's symbol, white on the level's glossy colour, or on calm glass
    /// before it has one. A tap climbs a level, and touching and holding lists every level to
    /// choose from: the colour washes to the new level's and the symbol swaps for its own as it
    /// bounces, or with Reduce Motion only cross-fades. Swiping to another place, the badge
    /// cross-fades to that place's level rather than climbing, so a level-up only ever celebrates
    /// a level the person set.
    @ViewBuilder
    private var levelPill: some View {
        if let status, let place = deck.current {
            // A slot of its own, so one place's level and the next's cross-fade where they stand,
            // rather than the two standing side by side while they trade places.
            ZStack { levelBadge(status, for: place) }
                .layoutPriority(2)
        }
    }

    /// The badge for one place's level, which `levelPill` holds: a badge of its own for each place,
    /// so moving between places never reads as a level-up.
    private func levelBadge(_ status: Binding<VisitLevel>, for place: AdministrativeDivision) -> some View {
        AtlasLevelBadge(level: status, placeName: place.displayName(localLanguage: localLanguage), size: stepperSize)
            .id(place.id)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.85)))
    }

    /// Puts the Atlas away: a small cross in a calm round pane of glass, as the map's own round
    /// buttons are.
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: stepperSize, height: stepperSize)
                .glassPanel(in: Circle(), interactive: true)
                .contentShape(Circle())
        }
        .buttonStyle(PillButtonStyle())
        .layoutPriority(2)
        .accessibilityLabel("Close Atlas")
    }

    /// The arrow keys, which step through the places whichever header shows, even one too narrow
    /// for its arrows: two titled buttons with no size of their own, so they're listed among the
    /// keyboard's shortcuts. VoiceOver steps with each card's own actions instead.
    private var keyboardSteps: some View {
        ZStack {
            Button("Previous place") { onStep(-1) }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(deck.isAtStart)
            Button("Next place") { onStep(1) }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(deck.isAtEnd)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    /// The way into a place's own places, such as "Prefectures ›", shortened where it's narrow to
    /// its first word, such as "States ›" for "States & territories".
    private func subcollectionLink(_ label: String, isShort: Bool) -> some View {
        let shown = isShort ? (label.components(separatedBy: " & ").first ?? label) : label
        let place = deck.current.map { $0.displayName(localLanguage: localLanguage) } ?? ""
        return Button(action: onOpenSubcollection) {
            HStack(spacing: 4) {
                Text(shown)
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(MapGame.learnColor)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(minHeight: stepperSize)
            .fixedSize()
            .glassPanel(in: Capsule(), tint: MapGame.learnColor, interactive: true)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place)’s \(label.lowercased())")
        .accessibilityHint("Opens their cards in the Atlas.")
    }

    /// Every place to jump to: in a submenu for each region where places are told apart by
    /// region, so the grouping is plain, the region shown open with a tick; otherwise one list.
    /// The card picked lands as a search's pick does.
    @ViewBuilder
    private var jumpList: some View {
        let jump = Binding(get: { deck.index }, set: { pickPlace(at: $0) })
        if deck.showsRegions {
            ForEach(deck.sections) { section in
                let name = section.name(localLanguage: localLanguage)
                Menu {
                    Picker(name, selection: jump) {
                        ForEach(section.range, id: \.self) { index in
                            Text(deck.places[index].displayName(localLanguage: localLanguage)).tag(index)
                        }
                    }
                } label: {
                    Label {
                        Text(name)
                        Text(section.count == 1 ? "1 place" : "\(section.count) places")
                    } icon: {
                        if section.range.contains(deck.index) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } else {
            Picker("Jump to", selection: jump) {
                ForEach(deck.places.indices, id: \.self) { index in
                    Text(deck.places[index].displayName(localLanguage: localLanguage)).tag(index)
                }
            }
        }
    }

    /// An arrow in a round pane of glass, as the map's own round buttons are, that gives under
    /// the finger; faint at either end, where there's nowhere further to go.
    private func stepButton(
        _ title: String, systemImage: String, by offset: Int, isEnabled: Bool
    ) -> some View {
        Button {
            onStep(offset)
        } label: {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isEnabled ? AnyShapeStyle(MapGame.learnColor) : AnyShapeStyle(.tertiary))
                .frame(width: stepperSize, height: stepperSize)
                .glassPanel(in: Circle(), interactive: isEnabled)
                .contentShape(Circle())
        }
        .buttonStyle(PillButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .animation(.smooth(duration: 0.2), value: isEnabled)
    }

    /// The cards, each its own pane of glass, paging into place one after another. The ones
    /// either side lean back a little and fade, or with Reduce Motion only fade.
    private var row: some View {
        let shrinks = !reduceMotion
        return ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: Self.spacing) {
                    ForEach(deck.places) { place in
                        card(for: place)
                            .frame(width: cardWidth)
                            // Every card at the row's height, so one further along, already made
                            // but out of sight, never makes the row taller than the cards in view.
                            .frame(height: cardHeight > 0 ? cardHeight : nil, alignment: .top)
                            .scrollTransition(.interactive.threshold(.visible(0.9)), axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(shrinks ? 1 - 0.05 * abs(phase.value) : 1)
                                    .opacity(1 - 0.45 * abs(phase.value))
                            }
                    }
                }
                // Room for the glass's edge above and its shadow below, which the row would otherwise
                // cut off; a little less where room is short, and none below cards that run off
                // the screen's foot.
                .padding(.top, isCompact ? 6 : 10)
                .padding(.bottom, bottomBleed != nil ? 0 : isCompact ? 18 : 24)
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, sideMargin, for: .scrollContent)
            .scrollTargetBehavior(LandingScrollTarget(
                step: cardWidth + Self.spacing, cardWidth: cardWidth, rowWidth: rowWidth, count: deck.count,
                onLanding: land))
            .scrollPosition(id: $centredID, anchor: .center)
            .scrollIndicators(.hidden)
            .fixedSize(horizontal: false, vertical: true)
            .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: cardHeight)
            // The scrubber sits a little into the shadows' room.
            .padding(.bottom, bottomBleed != nil ? 0 : -10)
            .onScrollPhaseChange { _, phase in
                if phase == .idle { settle() }
            }
            // The cards widen or narrow, and the room either side of them changes, as when iPhone
            // Duo folds; the row keeps the card in the middle in the middle, rather than where the
            // old layout left it.
            .onChange(of: [cardWidth, sideMargin]) {
                recentre(proxy, animated: false)
            }
            // Again once the room has settled, as iPhone Duo's panels glide into place as it folds.
            .task(id: [cardWidth, sideMargin]) {
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled, !isScrubbing, let id = deck.current?.id else { return }
                // The row's position let go of and taken up again, so the scroll view goes back to
                // the card even where it believes it's already there.
                centredID = nil
                try? await Task.sleep(for: .milliseconds(20))
                guard !Task.isCancelled, deck.current?.id == id else { return }
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) { centredID = id }
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    /// Brings the card for the place shown back to the middle, after the row has changed size. The
    /// scroll view keeps its offset in points, which at the new width can sit on another card
    /// altogether, and may already have reported that card as the one in the middle; so the card in
    /// the middle is set again as well as scrolled to, in a transaction of its own.
    private func recentre(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let id = deck.current?.id else { return }
        var transaction = Transaction(animation: animated && !reduceMotion ? .smooth(duration: 0.3) : nil)
        transaction.disablesAnimations = !animated || reduceMotion
        withTransaction(transaction) {
            if centredID != id { centredID = id }
            proxy.scrollTo(id, anchor: .center)
        }
    }

    private func card(for place: AdministrativeDivision) -> some View {
        let isCentred = place.id == deck.current?.id
        // The header's round buttons grow with the text size, and the header with them, so the
        // cards give it the room it takes beyond its usual height.
        let headerGrowth = max(stepperSize - Self.usualStepperSize, 0)
        let chrome = (bottomBleed != nil ? Self.bleedingChrome : isCompact ? Self.compactChrome : Self.chrome)
            - (isCondensed ? Self.scrubberRoom : 0)
            + headerGrowth
        let tallest = maxHeight.map { max($0 - chrome, 160) }
        let landing = deck.landing?.placeID == place.id ? deck.landing : nil
        return LearnPlaceCard(
            place: place, localLanguage: localLanguage, flag: deck.flag(of: place),
            capitals: deck.capitals(of: place), codes: deck.codes(of: place), facts: facts(place),
            landing: landing, width: cardWidth, height: cardHeight, maxHeight: tallest, isCompact: isCompact,
            isCondensed: isCondensed, bottomBleed: bottomBleed
        ) { height in
            // Never past the room there is; a card taller than that scrolls within itself. A sheet
            // running off the screen's foot is always its full height, so the row never cuts it
            // short above the edge.
            let height = bottomBleed != nil ? (tallest ?? height) : min(height, tallest ?? height)
            if abs(height - (cardHeights[place.id] ?? 0)) > 0.5 { cardHeights[place.id] = height }
        }
        .onTapGesture { tap(place) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isCentred ? .isSelected : [])
        .accessibilityAction(named: "Next") { onStep(1) }
        .accessibilityAction(named: "Previous") { onStep(-1) }
        .accessibilityFocused($focusedID, equals: place.id)
    }

    /// A tap on a card either side brings it to the middle; on the one in the middle, shows its place again.
    private func tap(_ place: AdministrativeDivision) {
        guard let position = deck.position(of: place) else { return }
        if position == deck.index {
            onShow(place)
        } else {
            onStep(position - deck.index)
        }
    }

    /// Once a swipe comes to rest on another card, its place is the one shown, unless it was
    /// already shown as the finger lifted.
    private func settle() {
        predictedIndex = nil
        guard !isScrubbing, let centredID, centredID != deck.current?.id,
              let place = deck.places.first(where: { $0.id == centredID }) else { return }
        onShow(place)
    }

    /// As the finger lifts from a swipe, the card it'll come to rest on is shown on the map at once,
    /// so the map glides there as the cards settle, rather than waiting for them to stop.
    private func land(at position: Int) {
        guard !isScrubbing, position != deck.index, deck.places.indices.contains(position) else { return }
        predictedIndex = position
        onShow(deck.places[position])
    }

    /// The arrows, the arrow keys, VoiceOver, the scrubber, the list and taps on the map move the
    /// place shown, from `old`; the row scrolls along to its card, and VoiceOver moves with it.
    /// A step or two glides there; anything farther, as from the list, the search or a place
    /// tapped across the map, is simply there, rather than racing past dozens of cards, the map's
    /// flight showing the way and a search's landing lighting the card. While scrubbing, and with
    /// Reduce Motion, it's always simply there.
    private func follow(from old: Int) {
        guard let place = deck.current else { return }
        if focusedID != nil, focusedID != place.id { focusedID = place.id }
        // A swipe already on its way to this card glides there by itself.
        guard centredID != place.id, predictedIndex != deck.index else { return }
        let glides = !reduceMotion && !isScrubbing && abs(deck.index - old) <= Self.farthestGlide
        withAnimation(glides ? .smooth(duration: 0.45) : nil) { centredID = place.id }
    }

    /// The most cards the row glides across to follow the place shown; farther, it's simply there.
    private static let farthestGlide = 2
}

/// The row's paging, card by card as `viewAligned` pages, which also works out, as soon as a swipe
/// is let go, which card it will come to rest on, so the map needn't wait for the cards to stop.
private struct LandingScrollTarget: ScrollTargetBehavior {
    /// From one card's middle to the next.
    var step: CGFloat
    var cardWidth: CGFloat
    var rowWidth: CGFloat
    var count: Int
    var onLanding: (Int) -> Void

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        ViewAlignedScrollTargetBehavior(limitBehavior: .alwaysByFew).updateTarget(&target, context: context)
        // Only a swipe let go while moving: the scroll view also asks as its size changes, as when
        // the device turns or iPhone Duo folds, when the widths here may be a layout behind and
        // could name the wrong card. A swipe let go at rest is little way from its card, and the
        // row coming to rest shows it soon enough.
        guard context.velocity.dx != 0 else { return }
        let rowWidth = context.containerSize.width > 0 ? context.containerSize.width : rowWidth
        guard step > 0, count > 0, rowWidth > 0 else { return }
        // The target lines a card's middle up with the row's. Depending on whether the scroll
        // view counts its offset from the room before the first card or from the first card
        // itself, that middle sits at `rowWidth / 2` or `cardWidth / 2` along from the card's
        // own place in the row; whichever lands on a whole card is the one in use.
        let fromRow = (target.rect.midX - rowWidth / 2) / step
        let fromCard = (target.rect.midX - cardWidth / 2) / step
        let rowMiss = abs(fromRow - fromRow.rounded()) * step
        let cardMiss = abs(fromCard - fromCard.rounded()) * step
        guard min(rowMiss, cardMiss) < 2 else { return }
        let position = Int((cardMiss <= rowMiss ? fromCard : fromRow).rounded())
        guard (0..<count).contains(position) else { return }
        // Told once the scroll view has finished working out where it's going.
        DispatchQueue.main.async { onLanding(position) }
    }
}

/// A track running through every place in Learn, its regions marked out along it, with a round
/// white knob, ringed in Learn's colour, at the place shown. Drag along it, or touch anywhere on
/// it, to race through the places, with a tick of feedback for each one. For VoiceOver it's
/// adjustable, a region at a time where there are regions, or a tenth of the way otherwise.
private struct LearnScrubber: View {
    var count: Int
    var index: Int
    var sections: [LearnDeck.Section]
    /// Each run's region, by name, in the same order.
    var sectionNames: [String]
    var name: (Int) -> String
    @Binding var isScrubbing: Bool
    var onScrub: (Int, Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width: CGFloat = 0
    /// Where the finger is along the track while it drags, which the knob follows exactly; let go,
    /// the knob springs onto the place, or with Reduce Motion eases there in a moment.
    @State private var dragX: CGFloat?
    /// The bubble's size, to centre it over the knob and stand it clear above the track.
    @State private var calloutSize: CGSize = .zero

    private static let knob: CGFloat = 22
    private static let height: CGFloat = 30
    /// How far above the track the bubble floats, clear of a finger on the knob.
    private static let bubbleLift: CGFloat = 34

    /// Where the knob is: under the finger while it drags, otherwise at the place shown.
    private var knobX: CGFloat {
        let inset = Self.knob / 2 + 4
        guard let dragX else { return position(of: index) }
        return min(max(dragX, inset), max(width - inset, inset))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(MapGame.learnColor.opacity(0.08))
            if sections.count > 1 {
                marks
            }
            knob
        }
        .frame(height: Self.height)
        .glassPanel(in: Capsule())
        .overlay(alignment: .topLeading) {
            // While scrubbing, the region and place under the knob, in a bubble floating well above
            // it, clear of the finger, with a point down to the knob.
            if isScrubbing {
                callout
                    .fixedSize()
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { calloutSize = $0 }
                    .offset(x: calloutX, y: -(calloutSize.height + Self.bubbleLift))
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        // A fine line up from the knob to the bubble, so it's plain which place the bubble names.
        .overlay(alignment: .topLeading) {
            if isScrubbing {
                Capsule()
                    .fill(MapGame.learnColor.opacity(0.45))
                    .frame(width: 2, height: Self.bubbleLift - 6)
                    .offset(x: knobX - 1, y: -(Self.bubbleLift - 2))
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        // The bubble and its line rise in as a finger takes the scrubber and go as it lets go, a
        // control answering the touch where it is; the knob keeps its own curves, nearer to it.
        .animation(MapMotion.control(reduceMotion: reduceMotion), value: isScrubbing)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isScrubbing = true
                    dragX = value.location.x
                    let target = self.index(at: value.location.x)
                    if target != index { onScrub(target, false) }
                }
                .onEnded { value in
                    isScrubbing = false
                    withAnimation(Motion.moving(.snappy, reduceMotion: reduceMotion)) { dragX = nil }
                    onScrub(self.index(at: value.location.x), true)
                })
        .accessibilityElement()
        .accessibilityLabel("Places")
        .accessibilityValue("\(name(index)), \(index + 1) of \(count)")
        .accessibilityHint(sections.count > 1 ? "Swipe up or down to move a region at a time." : "Swipe up or down to move a tenth of the way.")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onScrub(jump(by: 1), true)
            case .decrement: onScrub(jump(by: -1), true)
            @unknown default: break
            }
        }
    }

    /// The knob: a plain white bead with a ring of Learn's colour and a soft neutral shadow, which
    /// grows a little under the finger, or with Reduce Motion only deepens its ring.
    private var knob: some View {
        Circle()
            .fill(.white)
            .overlay {
                Circle()
                    .strokeBorder(MapGame.learnColor, lineWidth: isScrubbing ? 3.5 : 2.5)
            }
            .frame(width: Self.knob, height: Self.knob)
            .shadow(color: .black.opacity(isScrubbing ? 0.22 : 0.15), radius: isScrubbing ? 6 : 3, y: 1.5)
            .scaleEffect(isScrubbing && !reduceMotion ? 1.18 : 1)
            .offset(x: knobX - Self.knob / 2)
            .animation(dragX == nil ? Motion.moving(.snappy, reduceMotion: reduceMotion) : nil, value: knobX)
            .animation(.smooth(duration: 0.25), value: isScrubbing)
    }

    /// Where the bubble's leading edge goes: centred over the knob, kept within the track's ends,
    /// or centred on the track if it's wider still.
    private var calloutX: CGFloat {
        guard calloutSize.width < width else { return (width - calloutSize.width) / 2 }
        return min(max(knobX - calloutSize.width / 2, 0), width - calloutSize.width)
    }

    /// The bubble over the knob while scrubbing: the region, unless the place shares its name, and the place.
    private var callout: some View {
        let region = sections.firstIndex { $0.range.contains(index) }.map { sectionNames.indices.contains($0) ? sectionNames[$0] : "" }
        return HStack(spacing: 6) {
            if let region, !region.isEmpty, region != name(index) {
                Text(region)
                    .typeStyle(.smallEyebrow)
                    .foregroundStyle(MapGame.learnColor)
            }
            Text(name(index))
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassPanel(in: Capsule(), tint: MapGame.learnColor)
    }

    /// A fine upright line where each region gives way to the next. Regions aren't named along
    /// the track, which has no room for many; the bubble and the header name the knob's.
    private var marks: some View {
        ZStack(alignment: .leading) {
            ForEach(sections.dropFirst()) { section in
                let x = (position(of: section.start - 1) + position(of: section.start)) / 2
                Capsule()
                    .fill(MapGame.learnColor.opacity(0.3))
                    .frame(width: 1.5, height: Self.height * 0.45)
                    .offset(x: x - 0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Where a place sits along the track, keeping the knob inside it at either end.
    private func position(of index: Int) -> CGFloat {
        let inset = Self.knob / 2 + 4
        guard count > 1 else { return width / 2 }
        return inset + (width - inset * 2) * CGFloat(index) / CGFloat(count - 1)
    }

    /// The place nearest a point along the track.
    private func index(at x: CGFloat) -> Int {
        let inset = Self.knob / 2 + 4
        guard count > 1, width > inset * 2 else { return 0 }
        let fraction = (x - inset) / (width - inset * 2)
        return min(max(Int((fraction * CGFloat(count - 1)).rounded()), 0), count - 1)
    }

    /// For VoiceOver: on to the start of the next region, or back to the start of this one or the
    /// last; without regions, a tenth of the way.
    private func jump(by direction: Int) -> Int {
        guard sections.count > 1 else {
            return min(max(index + direction * max(count / 10, 1), 0), count - 1)
        }
        if direction > 0 {
            return sections.first { $0.start > index }?.start ?? count - 1
        }
        return sections.last { $0.start < index }?.start ?? 0
    }
}


/// One place in Learn's row, in a glass card of its own, read top to bottom. Across the top runs
/// its flag at a modest size on the leading edge, or where it has none of its own the code it goes
/// by instead, such as Beijing's 京; then its name, light and large, with its formal or local name
/// beneath on one line; and on the trailing edge its capital, or chips for several, each with its
/// part in governing. Where the capitals can't sit there beside the name, they take a row of their
/// own beneath it. Then come its codes, each labelled with a small coloured symbol and its kind's
/// name in a tidy grid, and for a country, flowing straight on in the same grid, what the Atlas
/// knows about it: the side of the road, its plugs, its voltage and its coasts. Every part flows
/// after the last, so nothing sits on top of anything else. The card sizes itself to all of that
/// and tells the row, so the row can stand every card as tall as the tallest; Learn grows tall
/// enough to hold it, and only at the largest text sizes, with no room left, does a card scroll
/// within its glass. The Atlas shows the same card for a country tapped on its map.
struct LearnPlaceCard: View {
    var place: AdministrativeDivision
    var localLanguage: Bool
    /// The place's own flag, or nil where it only has its country's, or shares one.
    var flag: String?
    var capitals: [CapitalCity]
    var codes: [(kind: MapGame.CodeKind, code: String)]
    /// What the Atlas knows about it, such as its plugs: a country's, and nothing for other places.
    var facts: [MapFact] = []
    /// Set as the place is picked from Learn's search, its list of every place or a surprise: the
    /// card pops as it lands in the middle, and rings itself in light, with what it was found by lit
    /// up, such as its +81, or its name, for a moment.
    var landing: LearnSearch.Landing? = nil
    /// The card's width.
    var width: CGFloat
    /// The row's height, so every card stands as tall as the tallest.
    var height: CGFloat
    /// The most height there is for a card, where it's limited.
    var maxHeight: CGFloat?
    /// Whether room is short, so the name is set smaller and the card sits tighter around it all.
    var isCompact: Bool = false
    /// The most condensed form, where room is short and wide: a smaller flag and a tighter grid.
    var isCondensed: Bool = false
    /// Set where the card runs off the screen's foot: it stands all the height there is, its
    /// contents scrolling within it, with this much more room beneath them to scroll up past the
    /// edge into view.
    var bottomBleed: CGFloat? = nil
    var onMeasure: (CGFloat) -> Void
    /// The card's height with everything showing.
    @State private var shownHeight: CGFloat = 0
    /// While it pops as it lands from the search.
    @State private var isPopped = false
    /// While it, and what it was found by, are lit up after landing from the search.
    @State private var isSpotlit = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The flag's height, about that of the name's first line, so it sits beside it.
    @ScaledMetric(relativeTo: .title) private var flagHeight: CGFloat = 34
    /// How far below the top of the name's first line the flag, or the code standing in for it, and
    /// any capitals beside the name begin: about where the name's capital letters do, so all three
    /// line up along the top.
    @ScaledMetric(relativeTo: .title) private var badgeDrop: CGFloat = 6

    /// The widest a flag is shown for its height; a longer one, such as Qatar's, sits a little
    /// lower instead.
    private static let longestFlag: CGFloat = 1.9

    var body: some View {
        // A sheet running off the screen's foot has square corners there, the screen's own
        // rounded corners rounding it, so it reads as one sheet sliding on under the edge.
        let foot: CGFloat = bottomBleed != nil ? 0 : 26
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 26, bottomLeadingRadius: foot, bottomTrailingRadius: foot, topTrailingRadius: 26,
            style: .continuous)
        let shown = content
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                if abs(height - shownHeight) > 0.5 { shownHeight = height }
            }
        Group {
            if let maxHeight, let bottomBleed {
                // A sheet of glass running off the screen's foot, its contents scrolling within it.
                ScrollView(.vertical) {
                    shown
                        .padding(.bottom, bottomBleed)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicatorsFlash(onAppear: true)
                .frame(width: width, height: maxHeight)
            } else if let maxHeight, shownHeight > maxHeight + 0.5 {
                // A last resort, at the largest text sizes, for a card taller than all the room there is.
                ScrollView(.vertical) { shown }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicatorsFlash(onAppear: true)
                    .frame(width: width, height: maxHeight)
            } else {
                shown
                    .frame(width: width, alignment: .topLeading)
                    .frame(minHeight: height, alignment: .topLeading)
            }
        }
        .clipShape(shape)
        .glassPanel(in: shape)
        .contentShape(shape)
        // Rung faintly in Learn's colour after landing from the search, a gentle bloom past its edge.
        .overlay {
            ZStack {
                shape.stroke(MapGame.learnColor.opacity(0.22), lineWidth: 4).blur(radius: 8)
                shape.strokeBorder(MapGame.learnColor.opacity(0.45), lineWidth: 1)
            }
            .opacity(isSpotlit ? 1 : 0)
            .allowsHitTesting(false)
        }
        .scaleEffect(isPopped ? 1.035 : 1)
        .onChange(of: shownHeight) { if shownHeight > 0 { onMeasure(shownHeight) } }
        // Measured afresh when the row forgets its tallest, as when the room changes, even where
        // this card's own height hasn't, so the row doesn't fall back to cards of uneven heights.
        .onChange(of: height) { if height == 0, shownHeight > 0 { onMeasure(shownHeight) } }
        // As the card is made, too, as when the row first reaches it on its way.
        .task(id: landing?.id) { await land() }
    }

    /// Pops the card once the row has brought it round, lights it and what it was found by, then
    /// lets the light fade. With Reduce Motion, it only lights. Anything else landing starts afresh.
    private func land() async {
        guard landing != nil else {
            if isPopped || isSpotlit {
                withAnimation(.smooth(duration: 0.4)) {
                    isPopped = false
                    isSpotlit = false
                }
            }
            return
        }
        // A moment for the row to bring the card into the middle.
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        withAnimation(.bouncy(duration: 0.35, extraBounce: 0.15)) {
            isPopped = !reduceMotion
            isSpotlit = true
        }
        try? await Task.sleep(for: .milliseconds(220))
        guard !Task.isCancelled else { return }
        withAnimation(.bouncy(duration: 0.5)) { isPopped = false }
        try? await Task.sleep(for: .seconds(1.8))
        guard !Task.isCancelled else { return }
        withAnimation(.smooth(duration: 0.9)) { isSpotlit = false }
    }

    /// What the card was found by, lit while it's spotlit.
    private var spotlitMatch: LearnSearch.Match? {
        isSpotlit ? landing?.match : nil
    }

    /// The kind of code the card was found by, lit while it's spotlit.
    private var spotlitKind: MapGame.CodeKind? {
        if case .code(let kind, _) = spotlitMatch { return kind }
        return nil
    }

    /// Learn's colour for whatever of the header the card was found by, while it's spotlit.
    private func headerStyle(isMatch: Bool, otherwise style: some ShapeStyle) -> AnyShapeStyle {
        isMatch ? AnyShapeStyle(MapGame.learnColor) : AnyShapeStyle(style)
    }

    /// The card's own padding.
    private var inset: CGFloat {
        isCondensed ? 10 : isCompact ? 12 : 16
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: isCondensed ? 7 : isCompact ? 10 : 14) {
            header
            // The code standing in for the flag isn't listed again. What the Atlas knows, such as
            // the plugs, flows straight on after the codes, in the same grid with no gap between,
            // taking up any room the last row of codes leaves. A wide card holds three or four to
            // a row.
            // The capitals lead, as one more detail, on a line of their own across the card.
            let details = codes.filter { $0.kind != emblem?.kind }.map(CodeGrid.Entry.init(code:))
            let isCapitalLit = if case .capital = spotlitMatch { true } else { false }
            let leading = capitals.isEmpty ? [] : [CodeGrid.Entry(capitals: capitals, isLit: isCapitalLit)]
            if !leading.isEmpty || !details.isEmpty || !facts.isEmpty {
                CodeGrid(
                    leading: leading, entries: details, trailing: facts.map(CodeGrid.Entry.init(fact:)),
                    spotlit: spotlitKind, maxGroups: max(2, min(4, Int(width / (isCondensed ? 150 : 190)))),
                    isCondensed: isCondensed)
            }
        }
        .padding(inset)
        .frame(width: width, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Where the place has no flag of its own, the code it goes by, which stands in the flag's
    /// place: a Chinese province's short name, such as 京 for Beijing, or a French department's
    /// number, such as 93 for Seine-Saint-Denis. Nil where it has a flag, or no such code.
    private var emblem: (kind: MapGame.CodeKind, code: String)? {
        guard flag == nil else { return nil }
        for kind in MapGame.CodeKind.emblems {
            if let entry = codes.first(where: { $0.kind == kind }) { return entry }
        }
        return nil
    }

    /// Across the top: the flag on the leading edge, or the code standing in for it, then the name
    /// with its other name beneath, each on one line. VoiceOver reads it all as one.
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            badge
            names
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenHeader)
        .accessibilityAddTraits(.isHeader)
    }

    /// The name, light and large, and beneath it its other name, each on one line, gliding to
    /// show the rest where it's too long for its room, never wrapping, shrunk or cut short.
    private var names: some View {
        let name = place.displayName(localLanguage: localLanguage)
        return VStack(alignment: .leading, spacing: 2) {
            ScrollingText {
                Text(name)
                    .typeStyle(isCompact ? .compactPlaceName : .placeName, language: place.language(of: name))
                    .fontDesign(.default)
                    .foregroundStyle(headerStyle(isMatch: spotlitMatch == .name, otherwise: .primary))
            }
            // Condensed, the other name folds away; VoiceOver still reads it.
            if let subtitle, !isCondensed {
                ScrollingText {
                    Text(subtitle)
                        .typeStyle(.compactPlaceSubtitle, language: place.language(of: subtitle))
                        .fontDesign(.default)
                        .foregroundStyle(headerStyle(isMatch: spotlitMatch == .otherName(subtitle), otherwise: .secondary))
                }
            }
        }
    }

    /// On the header's leading edge, the flag as it is, its own shape uncut and unframed, lifted by
    /// a soft shadow; or where the place has none of its own, the code standing in for it, drawn as
    /// a question shows it, at about the flag's height. Either keeps its own width, never squeezed
    /// by a long name.
    @ViewBuilder
    private var badge: some View {
        if let flag {
            let size = flagSize(of: flag)
            Image(flag)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .padding(.top, badgeDrop)
        } else if let emblem {
            CodeBadge(code: emblem.code, kind: emblem.kind, size: 24)
                .fixedSize()
                // Found by it, it swells and glows a moment.
                .scaleEffect(spotlitKind == emblem.kind && !reduceMotion ? 1.15 : 1)
                .shadow(color: MapGame.learnColor.opacity(spotlitKind == emblem.kind ? 0.6 : 0), radius: 8)
                .padding(.top, badgeDrop)
        }
    }

    /// The flag's size beside the name: `flagHeight` tall in its own proportions, so it hugs its
    /// own width and the name follows straight on, unless that would make it wider than
    /// `longestFlag` times its height, when it keeps that width and stands a little shorter.
    private func flagSize(of flag: String) -> CGSize {
        guard let artwork = UIImage(named: flag)?.size, artwork.width > 0, artwork.height > 0 else {
            return CGSize(width: flagHeight * 1.5, height: flagHeight)
        }
        let aspect = artwork.width / artwork.height
        let height = isCondensed ? flagHeight * 0.8 : flagHeight
        let width = min(height * aspect, height * Self.longestFlag)
        return CGSize(width: width, height: width / aspect)
    }

    /// What VoiceOver reads for the header, in the same order however it's laid out: the name, its
    /// other name, the code standing in for the flag, such as "Short name 京", and the capitals.
    private var spokenHeader: String {
        var parts = [place.displayName(localLanguage: localLanguage)]
        if let subtitle { parts.append(subtitle) }
        if let emblem { parts.append("\(emblem.kind.learnName) \(CodeBadge.spoken(emblem.code))") }
        return parts.joined(separator: ", ")
    }

    /// The place's other name, where it says something its name doesn't.
    private var subtitle: String? {
        guard let subtitle = place.subtitle(localLanguage: localLanguage) else { return nil }
        func folded(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        }
        return folded(subtitle) == folded(place.displayName(localLanguage: localLanguage)) ? nil : subtitle
    }
}

/// A place's codes in a tidy grid, each a small coloured symbol, its kind's short name, and the
/// code, and for a country, flowing straight on after them in the same rows and columns, what the
/// Atlas knows, such as its plugs. They sit as many to a row as fit whole within the card, up to
/// `maxGroups`: two on a phone's card, three or four where the card is wide, as beside iPhone
/// Duo's fold. A code that runs long, such as Brazil's several aircraft prefixes, takes the room
/// of two, or three. VoiceOver hears every kind's name and the code letter by letter.
struct CodeGrid: View {
    /// One line of the grid: a code, or something the Atlas knows.
    struct Entry {
        var symbolName: String
        var tint: Color
        var label: String
        var value: String
        var spoken: String
        /// Set in Chinese type, as China's short names are.
        var isChinese = false
        /// The kind of code it is; nil for what the Atlas knows.
        var kind: MapGame.CodeKind?
        /// The value with parts set apart, as each capital's part in governing, in grey.
        var styledValue: AttributedString?
        /// Lit up, as the capitals are when a place was just found by one in Learn's search.
        var isLit = false

        init(code entry: (kind: MapGame.CodeKind, code: String)) {
            kind = entry.kind
            symbolName = entry.kind.symbolName
            tint = entry.kind.tint
            label = entry.kind.learnName
            value = entry.kind.listed(entry.code)
            spoken = "\(entry.kind.spokenName) \(CodeBadge.spoken(entry.code))"
            isChinese = entry.kind == .shortName
        }

        /// The capitals, as one entry: "Capital" and its name, or where there are several, "Capitals"
        /// and each name with its part in governing beside it, "Pretoria (executive), Cape Town
        /// (legislative)".
        init(capitals: [CapitalCity], isLit: Bool) {
            symbolName = "building.columns"
            tint = MapGame.learnColor
            label = capitals.count == 1 ? "Capital" : "Capitals"
            value = capitals.map(\.name).joined(separator: ", ")
            var styled = AttributedString()
            for (index, capital) in capitals.enumerated() {
                if index > 0 { styled += AttributedString(", ") }
                styled += AttributedString(capital.name)
                if capitals.count > 1, let role = capital.role {
                    var part = AttributedString(" (\(role.replacingOccurrences(of: "government", with: "govt")))")
                    part.foregroundColor = .secondary
                    styled += part
                }
            }
            styledValue = styled
            spoken = capitals.count == 1
                ? "Capital: \(capitals[0].name)"
                : "Capitals: " + capitals.map { capital in capital.role.map { "\(capital.name), \($0)" } ?? capital.name }
                    .joined(separator: "; ")
            self.isLit = isLit
        }

        init(fact: MapFact) {
            symbolName = fact.symbolName
            tint = fact.tint
            label = fact.label
            value = fact.value
            spoken = fact.spoken
        }

        /// How many of a row's places it takes: one, or for a value that runs long, two or three.
        var span: Int {
            value.count > 14 ? 3 : value.count > 6 ? 2 : 1
        }
    }

    /// What leads, each on a line of its own across the grid, such as a country's capitals.
    var leading: [Entry] = []
    var entries: [Entry]
    /// What follows the entries as a run of its own, such as what the Atlas knows after a country's
    /// codes: straight on, in the same rows and columns with nothing set between them, taking up
    /// any room the last row of entries leaves, but never drawn up in among them.
    var trailing: [Entry] = []
    /// The kind of code a place was just found by in Learn's search, lit up in its own colour.
    var spotlit: MapGame.CodeKind? = nil
    /// The most entries a row holds, where they fit whole beside each other.
    var maxGroups: Int = 2
    /// Smaller type and tighter rows, where room is short.
    var isCondensed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Every entry's symbol, label and value, set out by `CodeGridLayout`: as many to a row as fit
    /// within the card with every code and its label whole beside each other, fewer otherwise,
    /// down to one to a row on a narrow card or at large text sizes, so a value never runs under
    /// the label beside it, past the card's edge, or has to glide where it needn't.
    var body: some View {
        let all = leading + entries + trailing
        let spans = leading.map { _ in CodeGridLayout.wholeRow } + (entries + trailing).map(\.span)
        CodeGridLayout(
            spans: spans, wholeRows: leading.count, trailingFrom: leading.count + entries.count, maxGroups: maxGroups,
            isCondensed: isCondensed
        ) {
            ForEach(all.indices, id: \.self) { index in
                cells(for: all[index])
            }
        }
        .accessibilityElement(children: .ignore)
        // Every entry, such as "Capital: Algiers, Codes: ISO D Z, web dot d z".
        .accessibilityLabel(spoken)
    }

    private var spoken: String {
        let codes = (entries + trailing).map(\.spoken)
        return (leading.map(\.spoken) + (codes.isEmpty ? [] : ["Codes: " + codes.joined(separator: ", ")]))
            .joined(separator: ", ")
    }

    /// An entry's symbol, label and value, the three views the layout sets out for it. The value
    /// keeps its own width wherever the layout has room for it whole; offered less, as one to a row
    /// on a narrow card or a line of its own, it stays on one line and glides to its end and back,
    /// or with Reduce Motion dissolves there, never wrapped, shrunk or cut short.
    @ViewBuilder
    private func cells(for entry: Entry) -> some View {
        // The code found by, in a wash of its own colour, its symbol breathing, or with Reduce
        // Motion only lit.
        let isSpotlit = (entry.kind != nil && entry.kind == spotlit) || entry.isLit
        Image(systemName: entry.symbolName)
            .font(isCondensed ? .caption2.weight(.medium) : .caption.weight(.medium))
            .foregroundStyle(entry.tint)
            .symbolEffect(.breathe, isActive: isSpotlit && !reduceMotion)
        Text(entry.label)
            .font(isCondensed ? .caption2 : .caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
        ScrollingText {
            value(of: entry, isSpotlit: isSpotlit)
        }
        // The wash sits inside the cell, which is clipped, so a gliding value never draws into
        // its neighbour; the cell then reaches back out by the wash's margin, so the value lines
        // up with its column as before.
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background {
            Capsule()
                .fill(entry.tint.opacity(isSpotlit ? 0.18 : 0))
        }
        .clipped()
        .padding(.horizontal, -7)
        .padding(.vertical, -3)
    }

    private func value(of entry: Entry, isSpotlit: Bool) -> some View {
        Text(entry.styledValue ?? AttributedString(entry.value))
            .font(isCondensed ? .footnote : .subheadline)
            .monospacedDigit()
            .typesettingLanguage(Locale.Language(identifier: "zh-Hans"), isEnabled: entry.isChinese)
            .foregroundStyle(isSpotlit ? AnyShapeStyle(entry.tint) : AnyShapeStyle(.primary))
    }
}

/// Sets out a `CodeGrid`, three views to an entry, its symbol, label and value: in rows of as many
/// groups as fit within the width it's offered with every value whole, from `maxGroups` down, or
/// failing that one entry to a row, each value then offered all the rest of its row. Several to a
/// row, each group keeps columns of its own, its symbols centred and its labels and values lined
/// up, and whatever room is left over is shared out between the gaps from one group to the next,
/// so the entries spread across the card and the last group ends at its edge. A long value reaches
/// on across the groups after its own, and the gaps open wide enough to hold it; where that would
/// carry the row past the card's edge, the rows give way to fewer groups instead. It does by hand
/// what a `Grid` would, because a `Grid`'s long cells, spanning its stretching gaps, could carry it
/// wider than it was offered, as Brazil's airport prefixes did, while it still reckoned it fitted.
/// Every row's views sit on their first baseline.
private struct CodeGridLayout: Layout {
    /// How many of a row's places each entry takes, in order.
    var spans: [Int]
    /// How many entries lead, each on a whole row of its own, its value offered all the rest of the
    /// row to glide in, never widening the grid's gaps.
    var wholeRows: Int = 0
    /// Where the entries that follow as a run of their own begin, such as what the Atlas knows.
    var trailingFrom: Int
    /// The most groups a row holds.
    var maxGroups: Int
    /// Tighter rows and gaps, where room is short.
    var isCondensed = false

    /// The span of an entry with a whole row to itself.
    static let wholeRow = 99
    /// The room between a symbol and its label, and between a label and its value.
    private static let spacing: CGFloat = 6
    private static let rowSpacing: CGFloat = 7
    private var spacing: CGFloat { isCondensed ? 5 : Self.spacing }
    private var rowSpacing: CGFloat { isCondensed ? 4 : Self.rowSpacing }
    /// The least room between one group and the next.
    private static let leastGap: CGFloat = 10

    /// An entry in its row, by its place in the order, and how many of the row's places it takes.
    struct Placement {
        var index: Int
        var span: Int
    }

    /// Where each view goes, and the width it's offered there, nil for its own.
    private struct Plan {
        var size: CGSize
        var origins: [CGPoint]
        var widths: [CGFloat?]
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        plan(width: proposal.width, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let plan = plan(width: bounds.width, subviews: subviews)
        for (index, subview) in zip(plan.origins.indices, subviews) {
            subview.place(
                at: CGPoint(x: bounds.minX + plan.origins[index].x, y: bounds.minY + plan.origins[index].y),
                anchor: .topLeading, proposal: ProposedViewSize(width: plan.widths[index], height: nil))
        }
    }

    /// The most groups to a row that fit within `width`, or one to a row; with no width to keep
    /// within, as many as there can be.
    private func plan(width: CGFloat?, subviews: Subviews) -> Plan {
        let width = width.flatMap { $0.isFinite ? $0 : nil }
        let count = min(spans.count, subviews.count / 3)
        let ideal = subviews.map { $0.dimensions(in: .unspecified) }
        for groups in stride(from: maxGroups, through: 2, by: -1) {
            if let plan = plan(groups: groups, width: width, count: count, ideal: ideal) { return plan }
        }
        return single(width: width, count: count, subviews: subviews, ideal: ideal)
    }

    /// `groups` to a row, every view at its own size, or nil where they can't all fit within `width`.
    /// Each place in the row has columns of its own as wide as the widest symbol, label and value
    /// of the entries starting there, a long value aside, which reaches on over the places after.
    private func plan(groups: Int, width: CGFloat?, count: Int, ideal: [ViewDimensions]) -> Plan? {
        let rows = Self.rows(of: Array(spans.prefix(count)), trailingFrom: trailingFrom, groups: groups)
        var symbols = [CGFloat](repeating: 0, count: groups)
        var labels = symbols
        var values = symbols
        var isUsed = [Bool](repeating: false, count: groups)
        for row in rows {
            var slot = 0
            for placed in row {
                symbols[slot] = max(symbols[slot], ideal[3 * placed.index].width)
                labels[slot] = max(labels[slot], ideal[3 * placed.index + 1].width)
                if placed.span == 1 { values[slot] = max(values[slot], ideal[3 * placed.index + 2].width) }
                isUsed[slot] = true
                slot += placed.span
            }
        }
        let spacing = self.spacing
        let slotWidths = (0..<groups).map { isUsed[$0] ? symbols[$0] + labels[$0] + values[$0] + 2 * spacing : 0 }
        // The gaps open as wide as the longest value reaching across them needs.
        var gap = isCondensed ? Self.leastGap - 2 : Self.leastGap
        for row in rows {
            var slot = 0
            for placed in row {
                if placed.span > 1, placed.index >= wholeRows {
                    let reach = values[slot] + slotWidths[(slot + 1)..<(slot + placed.span)].reduce(0, +)
                    gap = max(gap, (ideal[3 * placed.index + 2].width - reach) / CGFloat(placed.span - 1))
                }
                slot += placed.span
            }
        }
        let fixed = slotWidths.reduce(0, +)
        let least = fixed + CGFloat(groups - 1) * gap
        if let width, least > width + 0.5 { return nil }
        let total = width ?? least
        let spread = max((total - fixed) / CGFloat(groups - 1), gap)
        var slotXs: [CGFloat] = []
        var x: CGFloat = 0
        for slot in 0..<groups {
            slotXs.append(x)
            x += slotWidths[slot] + spread
        }
        var origins = [CGPoint](repeating: .zero, count: ideal.count)
        var widths = [CGFloat?](repeating: nil, count: ideal.count)
        var y: CGFloat = 0
        for (number, row) in rows.enumerated() {
            if number > 0 { y += rowSpacing }
            let cells = row.flatMap { placed in (0..<3).map { ideal[3 * placed.index + $0] } }
            let ascent = cells.map { $0[.firstTextBaseline] }.max() ?? 0
            let descent = cells.map { $0.height - $0[.firstTextBaseline] }.max() ?? 0
            var slot = 0
            for placed in row {
                let first = 3 * placed.index
                let x = slotXs[slot]
                origins[first] = CGPoint(
                    x: x + (symbols[slot] - ideal[first].width) / 2, y: y + ascent - ideal[first][.firstTextBaseline])
                origins[first + 1] = CGPoint(
                    x: x + symbols[slot] + spacing, y: y + ascent - ideal[first + 1][.firstTextBaseline])
                origins[first + 2] = CGPoint(
                    x: x + symbols[slot] + labels[slot] + 2 * spacing, y: y + ascent - ideal[first + 2][.firstTextBaseline])
                if placed.index < wholeRows {
                    widths[first + 2] = max(total - symbols[slot] - labels[slot] - 2 * spacing, 0)
                }
                slot += placed.span
            }
            y += ascent + descent
        }
        return Plan(size: CGSize(width: total, height: y), origins: origins, widths: widths)
    }

    /// One entry to a row, in a column of symbols and one of labels, each value offered all the
    /// rest of its row, to glide or wrap in where it's longer.
    private func single(width: CGFloat?, count: Int, subviews: Subviews, ideal: [ViewDimensions]) -> Plan {
        let spacing = self.spacing
        let symbolWidth = (0..<count).map { ideal[3 * $0].width }.max() ?? 0
        let labelWidth = (0..<count).map { ideal[3 * $0 + 1].width }.max() ?? 0
        let valueX = symbolWidth + labelWidth + 2 * spacing
        let valueWidth = width.map { max($0 - valueX, 0) }
        var origins = [CGPoint](repeating: .zero, count: ideal.count)
        var widths = [CGFloat?](repeating: nil, count: ideal.count)
        var widest: CGFloat = 0
        var y: CGFloat = 0
        for index in 0..<count {
            if index > 0 { y += rowSpacing }
            let first = 3 * index
            let value = subviews[first + 2].dimensions(in: ProposedViewSize(width: valueWidth, height: nil))
            widest = max(widest, value.width)
            let cells = [ideal[first], ideal[first + 1], value]
            let ascent = cells.map { $0[.firstTextBaseline] }.max() ?? 0
            let descent = cells.map { $0.height - $0[.firstTextBaseline] }.max() ?? 0
            origins[first] = CGPoint(
                x: (symbolWidth - ideal[first].width) / 2, y: y + ascent - ideal[first][.firstTextBaseline])
            origins[first + 1] = CGPoint(x: symbolWidth + spacing, y: y + ascent - ideal[first + 1][.firstTextBaseline])
            origins[first + 2] = CGPoint(x: valueX, y: y + ascent - value[.firstTextBaseline])
            widths[first + 2] = valueWidth
            y += ascent + descent
        }
        return Plan(size: CGSize(width: width ?? valueX + widest, height: y), origins: origins, widths: widths)
    }

    /// The entries in rows of `groups` places, each taking one place, or a long one two or three.
    /// Each row starts with the next entry in order, then fills the room it leaves with the longest
    /// later entry of the same run that fits, the earliest of those first, so short and long ones
    /// share rows, as Drives with Voltage and Plugs with Coasts, rather than a long one standing
    /// alone. Once the codes are all placed, what the Atlas knows takes up whatever room the last
    /// of their rows leaves and carries straight on, so it flows on after them in the same grid
    /// but is never drawn up in among them.
    static func rows(of spans: [Int], trailingFrom: Int, groups: Int) -> [[Placement]] {
        var remaining = spans.indices.map { Placement(index: $0, span: spans[$0]) }
        var rows: [[Placement]] = []
        while !remaining.isEmpty {
            var first = remaining.removeFirst()
            first.span = min(first.span, groups)
            var row = [first]
            var room = groups - first.span
            while room > 0, let next = remaining.first {
                // Only from the run the next entry belongs to: the codes, until they're all placed.
                let isTrailing = next.index >= trailingFrom
                let fitting = remaining.indices.filter {
                    remaining[$0].span <= room && (remaining[$0].index >= trailingFrom) == isTrailing
                }
                guard let longest = fitting.map({ remaining[$0].span }).max(),
                      let index = fitting.first(where: { remaining[$0].span == longest })
                else { break }
                row.append(remaining.remove(at: index))
                room -= longest
            }
            rows.append(row)
        }
        return rows
    }
}

extension MapGame.CodeKind {
    /// The kinds that can stand in for a place's flag, the most telling first: China's short
    /// names, Polish and Czech plate letters, and French and Japanese numbers.
    static let emblems: [MapGame.CodeKind] = [.shortName, .plate, .number]

    /// Its name beside its code in Learn, short enough to sit in a column.
    var learnName: String {
        switch self {
        case .iso: "ISO"
        case .domain: "Web"
        case .phone: "Phone"
        case .car: "Car"
        case .olympic: "Olympic"
        case .fifa: "FIFA"
        case .plate: "Plate"
        case .shortName: "Short name"
        case .aircraft: "Aircraft"
        case .airport: "Airport"
        case .currency: "Currency"
        case .number: "Number"
        case .postcode: "Postcode"
        case .timeZone: "Time"
        }
    }

    /// A code as Learn lists it: as it is, or a postcode's first digit with dots for the rest, "2···".
    func listed(_ code: String) -> String {
        self == .postcode ? code + "···" : code
    }

    /// Its symbol's colour in Learn's codes: a small palette, deep enough to read on light glass
    /// and lifted to read on dark.
    var tint: Color {
        switch self {
        case .iso: LevelColor.indigo.color
        case .domain: LevelColor.blue.color
        case .phone: .adaptive(light: (0.12, 0.62, 0.30), dark: (0.30, 0.82, 0.45))
        case .car: .adaptive(light: (0.90, 0.45, 0.05), dark: (1.0, 0.62, 0.25))
        case .olympic: .adaptive(light: (0.78, 0.56, 0.04), dark: (1.0, 0.80, 0.28))
        // The grass's yellower green, apart from the phone's.
        case .fifa: .adaptive(light: (0.38, 0.6, 0.04), dark: (0.64, 0.85, 0.3))
        case .plate, .shortName: .adaptive(light: (0.05, 0.27, 0.72), dark: (0.42, 0.62, 1.0))
        case .aircraft: .adaptive(light: (0.0, 0.55, 0.66), dark: (0.35, 0.82, 0.92))
        case .airport: .adaptive(light: (0.84, 0.19, 0.48), dark: (1.0, 0.48, 0.70))
        case .currency: .adaptive(light: (0.58, 0.24, 0.72), dark: (0.80, 0.58, 0.98))
        case .number: .adaptive(light: (0.55, 0.25, 0.70), dark: (0.78, 0.55, 0.95))
        case .postcode: .adaptive(light: (0.84, 0.13, 0.17), dark: (1.0, 0.42, 0.42))
        case .timeZone: .adaptive(light: (0.20, 0.30, 0.65), dark: (0.52, 0.64, 1.0))
        }
    }
}

private extension Color {
    /// A colour that takes one shade in light mode and another in dark.
    static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        })
    }
}

/// The person's level for a place in the Atlas, as a round badge the size of the round buttons
/// beside it: the level's symbol, white on the level's glossy colour. Before the place has a level,
/// a dashed ring with a plus in it, an empty place waiting to be filled, so it reads as "not yet,
/// tap to add" rather than as a blank circle. A tap climbs a level, and touching and holding lists
/// every level to choose from.
struct AtlasLevelBadge: View {
    @Binding var level: VisitLevel
    /// The place's name, for VoiceOver.
    var placeName: String
    var size: CGFloat
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let isNever = level == .never
        Button {
            if let higher = ladder.higher(than: level) { level = higher }
        } label: {
            Image(systemName: isNever ? "plus" : level.symbolName)
                .font(.system(size: size * (isNever ? 0.4 : 0.42), weight: .bold))
                .foregroundStyle(isNever ? AnyShapeStyle(MapGame.learnColor) : AnyShapeStyle(.white))
                .shadow(color: .black.opacity(isNever ? 0 : 0.25), radius: 0.5, y: 0.5)
                .contentTransition(reduceMotion ? .opacity : .symbolEffect(.replace))
                .symbolEffect(.bounce, value: reduceMotion ? 0 : ladder.rank(of: level))
                .frame(width: size, height: size)
                .background {
                    if isNever {
                        Color.clear
                            .glassPanel(in: Circle(), interactive: true)
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        MapGame.learnColor.opacity(0.55),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                                    .padding(2)
                            }
                    } else {
                        BadgeGloss(color: level.color).clipShape(.circle)
                    }
                }
                // The new level's colour washes in as its symbol swaps.
                .animation(.snappy, value: level)
                .contentShape(.circle)
        }
        .buttonStyle(PillButtonStyle())
        .contentShape(.contextMenuPreview, Circle())
        .contextMenu {
            Picker("Visit status", selection: $level) {
                ForEach(ladder.allLevels) { level in
                    Label(level.name, systemImage: level.symbolName).tag(level)
                }
            }
            .pickerStyle(.inline)
        }
        .sensoryFeedback(.selection, trigger: level)
        .accessibilityLabel("Level for \(placeName)")
        .accessibilityValue(level.name)
        .accessibilityHint(
            isNever
                ? "Marks it \(ladder.higher(than: level)?.name.lowercased() ?? "visited"). Touch and hold to choose any level."
                : "Raises the level. Touch and hold to choose any level.")
    }
}
