import SwiftUI

/// Learn: every place in play as a row of glass cards to swipe through, one for each place, with
/// the cards either side peeking in. Each card holds its place's name and region, its own flag where
/// it has one, its capitals where they're known, and its codes, each labelled. A slim header above the row counts through the places, and
/// opens a list of them all to jump to, with arrows that step along. Beneath the row, a scrubber
/// runs through every place, marked out by region: drag along it to race through them. The arrow
/// keys and VoiceOver step too, and tapping a card either side or a place on the map scrolls the
/// row to it. Whenever the row comes to rest on a card, the map lights up its place.
struct GameLearnCard: View {
    var game: MapGame
    var localLanguage: Bool
    /// Whether the row has room of its own, as on the near side of iPhone Duo's fold.
    var isRoomy: Bool
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
    /// What the place in the middle has of its own to learn, such as Prefectures for Japan, offered
    /// beside the count as a way into it.
    var subcollectionLabel: String?
    var onOpenSubcollection: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// The card in the middle of the row, kept in step with the place shown.
    @State private var centredID: String?
    @State private var rowWidth: CGFloat = 0
    /// The tallest card so far, so every card in the row stands as tall.
    @State private var cardHeight: CGFloat = 0
    /// Whether the scrubber is being dragged, so the row keeps up without gliding.
    @State private var isScrubbing = false
    @AccessibilityFocusState private var focusedID: String?

    /// How far into the row the cards either side reach, gap included.
    private static let peek: CGFloat = 26
    private static let spacing: CGFloat = 10
    private static let widestCard: CGFloat = 440
    /// The header, the row's room for shadows and the scrubber, around the cards.
    private static let chrome: CGFloat = 130

    init(
        game: MapGame, localLanguage: Bool, isRoomy: Bool, maxHeight: CGFloat? = nil, onStep: @escaping (Int) -> Void,
        onShow: @escaping (AdministrativeDivision) -> Void, onScrub: @escaping (Int, Bool) -> Void,
        subcollectionLabel: String? = nil, onOpenSubcollection: @escaping () -> Void = {}
    ) {
        self.game = game
        self.localLanguage = localLanguage
        self.isRoomy = isRoomy
        self.maxHeight = maxHeight
        self.onStep = onStep
        self.onShow = onShow
        self.onScrub = onScrub
        self.subcollectionLabel = subcollectionLabel
        self.onOpenSubcollection = onOpenSubcollection
        _centredID = State(initialValue: game.learnPlace?.id)
    }

    private var cardWidth: CGFloat {
        min(max(rowWidth - 2 * Self.peek, 0), Self.widestCard)
    }

    /// The room either side of the card in the middle, which lines the header and scrubber up with it.
    private var sideMargin: CGFloat {
        max((rowWidth - cardWidth) / 2, 0)
    }

    /// Whether places are told apart by region: on a map of several, when all of them are in play.
    private var showsRegions: Bool {
        game.scopeID == nil && !game.scopes.isEmpty
    }

    /// The places in runs by region, in the row's order, for the scrubber's marks and the list.
    private var sections: [LearnSection] {
        var sections: [LearnSection] = []
        for (index, place) in game.learnPlaces.enumerated() {
            if let last = sections.last, last.groupID == place.groupID {
                sections[sections.count - 1].count += 1
            } else {
                let name = game.collection.groups.first { $0.id == place.groupID }?.displayName(localLanguage: localLanguage)
                sections.append(LearnSection(groupID: place.groupID, name: name ?? "", start: index, count: 1))
            }
        }
        return showsRegions && sections.count > 1 ? sections : [LearnSection(groupID: "", name: "", start: 0, count: game.learnPlaces.count)]
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, sideMargin)
            if rowWidth > 0 {
                row
                LearnScrubber(
                    count: game.learnPlaces.count, index: game.learnIndex, sections: sections,
                    name: { game.learnPlaces.indices.contains($0) ? game.learnPlaces[$0].displayName(localLanguage: localLanguage) : "" },
                    isScrubbing: $isScrubbing, onScrub: onScrub)
                    .zIndex(1)
                    .padding(.horizontal, sideMargin)
                    .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: isRoomy ? .infinity : nil)
        .fontDesign(.rounded)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
            guard abs(width - rowWidth) > 0.5 else { return }
            rowWidth = width
            cardHeight = 0
        }
        .onChange(of: game.learnIndex) { follow() }
        .onChange(of: dynamicTypeSize) { cardHeight = 0 }
        .onChange(of: maxHeight) { cardHeight = 0 }
    }

    /// How far through the places, which opens the list of them all to jump to; beside it, where the
    /// place has places of its own, such as Japan its prefectures, a way into learning those; and the
    /// arrows. Where it's narrow, the region's name goes first, then the way in shortens.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            headerRow(showsRegion: true, isLinkShort: false)
            headerRow(showsRegion: false, isLinkShort: false)
            headerRow(showsRegion: false, isLinkShort: true)
        }
        .animation(.snappy, value: game.learnIndex)
        .animation(.bouncy(duration: 0.4), value: subcollectionLabel)
    }

    private func headerRow(showsRegion: Bool, isLinkShort: Bool) -> some View {
        HStack(spacing: 8) {
            Menu {
                jumpList
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(MapGame.learnColor)
                    // The region the place is in, where places are told apart by region.
                    if showsRegion, self.showsRegions,
                       let section = sections.first(where: { ($0.start..<($0.start + $0.count)).contains(game.learnIndex) }) {
                        Text(section.name)
                            .foregroundStyle(MapGame.learnColor)
                            .contentTransition(.interpolate)
                    }
                    HStack(spacing: 0) {
                        Text("\(game.learnIndex + 1)")
                            .typeStyle(.count)
                            .contentTransition(.numericText(value: Double(game.learnIndex)))
                        Text(" / \(game.learnPlaces.count)")
                            .typeStyle(.countTotal)
                    }
                    .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline.weight(.regular))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .fixedSize()
                .glassPanel(in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Place \(game.learnIndex + 1) of \(game.learnPlaces.count)")
            .layoutPriority(1)
            .accessibilityHint("Opens a list of every place to jump to.")
            if let subcollectionLabel {
                subcollectionLink(subcollectionLabel, isShort: isLinkShort)
                    .transition(.scale(scale: 0.6, anchor: .leading).combined(with: .opacity))
            }
            Spacer(minLength: 0)
            stepButton("Previous", systemImage: "chevron.left", by: -1, key: .leftArrow)
                .disabled(game.learnIndex == 0)
            stepButton("Next", systemImage: "chevron.right", by: 1, key: .rightArrow)
                .disabled(game.learnIndex + 1 >= game.learnPlaces.count)
        }
    }

    /// The way into a place's own places, such as "Prefectures ›", shortened where it's narrow to
    /// its first word, such as "States ›" for "States & territories".
    private func subcollectionLink(_ label: String, isShort: Bool) -> some View {
        let shown = isShort ? (label.components(separatedBy: " & ").first ?? label) : label
        let place = game.learnPlace.map { $0.displayName(localLanguage: localLanguage) } ?? ""
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
            .frame(minHeight: 34)
            .fixedSize()
            .glassPanel(in: Capsule(), tint: MapGame.learnColor, interactive: true)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Learn \(place)’s \(label.lowercased())")
        .accessibilityHint("Opens Learn for them.")
    }

    /// Every place to jump to: in a submenu for each region where places are told apart by
    /// region, so the grouping is plain, the region shown open with a tick; otherwise one list.
    @ViewBuilder
    private var jumpList: some View {
        let jump = Binding(get: { game.learnIndex }, set: { onScrub($0, true) })
        if sections.count > 1 {
            ForEach(sections) { section in
                let range = section.start..<(section.start + section.count)
                Menu {
                    Picker(section.name, selection: jump) {
                        ForEach(range, id: \.self) { index in
                            Text(game.learnPlaces[index].displayName(localLanguage: localLanguage)).tag(index)
                        }
                    }
                } label: {
                    Label {
                        Text(section.name)
                        Text(section.count == 1 ? "1 place" : "\(section.count) places")
                    } icon: {
                        Image(systemName: range.contains(game.learnIndex) ? "checkmark" : "")
                    }
                }
            }
        } else {
            Picker("Jump to", selection: jump) {
                ForEach(game.learnPlaces.indices, id: \.self) { index in
                    Text(game.learnPlaces[index].displayName(localLanguage: localLanguage)).tag(index)
                }
            }
        }
    }

    private func stepButton(_ title: String, systemImage: String, by offset: Int, key: KeyEquivalent) -> some View {
        Button {
            onStep(offset)
        } label: {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.semibold))
                .frame(width: 40, height: 34)
        }
        .buttonStyle(CandyButtonStyle(color: MapGame.learnColor, pattern: .candyStripes))
        .keyboardShortcut(key, modifiers: [])
    }

    /// The cards, each its own pane of glass, paging into place one after another. The ones
    /// either side lean back a little and fade, or with Reduce Motion only fade.
    private var row: some View {
        let shrinks = !reduceMotion
        return ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Self.spacing) {
                ForEach(game.learnPlaces) { place in
                    card(for: place)
                        .frame(width: cardWidth)
                        .scrollTransition(.interactive.threshold(.visible(0.9)), axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(shrinks ? 1 - 0.05 * abs(phase.value) : 1)
                                .opacity(1 - 0.45 * abs(phase.value))
                        }
                }
            }
            // Room for the glass's edge above and its shadow below, which the row would otherwise cut off.
            .padding(.top, 10)
            .padding(.bottom, 24)
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, sideMargin, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByFew))
        .scrollPosition(id: $centredID, anchor: .center)
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        // The scrubber sits a little into the shadows' room.
        .padding(.bottom, -10)
        .onScrollPhaseChange { _, phase in
            if phase == .idle { settle() }
        }
    }

    private func card(for place: AdministrativeDivision) -> some View {
        let isCentred = place.id == game.learnPlace?.id
        let tallest = maxHeight.map { max($0 - Self.chrome, 160) }
        return LearnPlaceCard(
            place: place, localLanguage: localLanguage, flag: game.hasOwnFlag(place) ? place.flagAssetName : nil,
            capitals: game.capitals[place.id] ?? [], codes: game.codes(of: place),
            width: cardWidth, height: cardHeight, maxHeight: tallest
        ) { height in
            // Never past the room there is; a card taller than that scrolls within itself.
            let height = min(height, tallest ?? height)
            if height > cardHeight + 0.5 { cardHeight = height }
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
        guard let index = game.learnPlaces.firstIndex(of: place) else { return }
        if index == game.learnIndex {
            onShow(place)
        } else {
            onStep(index - game.learnIndex)
        }
    }

    /// Once a swipe comes to rest on another card, its place is the one shown.
    private func settle() {
        guard !isScrubbing, let centredID, centredID != game.learnPlace?.id,
              let place = game.learnPlaces.first(where: { $0.id == centredID }) else { return }
        onShow(place)
    }

    /// The arrows, the arrow keys, VoiceOver, the scrubber, the list and taps on the map move the
    /// place shown; the row scrolls along to its card, at once while scrubbing, and VoiceOver
    /// moves with it.
    private func follow() {
        guard let place = game.learnPlace else { return }
        if focusedID != nil, focusedID != place.id { focusedID = place.id }
        guard centredID != place.id else { return }
        withAnimation(reduceMotion || isScrubbing ? nil : .smooth(duration: 0.45)) { centredID = place.id }
    }
}

/// A run of places in one region, in Learn's order.
private struct LearnSection: Identifiable, Equatable {
    var groupID: String
    var name: String
    var start: Int
    var count: Int
    var id: Int { start }
}

/// A track running through every place in Learn, its regions marked out along it, with a candy
/// knob at the place shown. Drag along it, or touch anywhere on it, to race through the places,
/// with a tick of feedback for each one. For VoiceOver it's adjustable, a region at a time where
/// there are regions, or a tenth of the way otherwise.
private struct LearnScrubber: View {
    var count: Int
    var index: Int
    var sections: [LearnSection]
    var name: (Int) -> String
    @Binding var isScrubbing: Bool
    var onScrub: (Int, Bool) -> Void
    @State private var width: CGFloat = 0
    /// Where the finger is along the track while it drags, which the knob follows exactly; let go,
    /// the knob springs onto the place.
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
            Circle()
                .fill(.white)
                .padding(-2.5)
                .overlay { CandyGloss(color: MapGame.learnColor, pattern: .candyStripes).clipShape(Circle()) }
                .frame(width: Self.knob, height: Self.knob)
                .shadow(color: MapGame.learnColor.opacity(0.4), radius: isScrubbing ? 8 : 4, y: 2)
                .scaleEffect(isScrubbing ? 1.25 : 1)
                .offset(x: knobX - Self.knob / 2)
                .animation(dragX == nil ? .snappy : nil, value: knobX)
                .animation(.bouncy(duration: 0.3), value: isScrubbing)
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
                    .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
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
                    withAnimation(.snappy) { dragX = nil }
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

    /// Where the bubble's leading edge goes: centred over the knob, kept within the track's ends,
    /// or centred on the track if it's wider still.
    private var calloutX: CGFloat {
        guard calloutSize.width < width else { return (width - calloutSize.width) / 2 }
        return min(max(knobX - calloutSize.width / 2, 0), width - calloutSize.width)
    }

    /// The bubble over the knob while scrubbing: the region, unless the place shares its name, and the place.
    private var callout: some View {
        let section = sections.first { ($0.start..<($0.start + $0.count)).contains(index) }
        return HStack(spacing: 6) {
            if let section, !section.name.isEmpty, section.name != name(index) {
                Text(section.name)
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

/// One place in Learn's row, in a glass card of its own, read top to bottom: its name, light and
/// large, with its flag at a modest size beside it, or where it has none of its own, the code it
/// goes by instead, such as Beijing's 京, and beneath the name its formal or local name on
/// one line, the whole of it a tap away, and a small tag for the region it's in. Then a line for its
/// capital, or chips for several, each with its part in governing; then its codes, each labelled
/// with a small coloured symbol and its kind's name in a tidy two-column grid. Every part flows after
/// the last, so nothing sits on top of anything else. The card sizes itself to all of that and tells
/// the row, so the row can stand every card as tall as the tallest; Learn grows tall enough to hold
/// it, and only at the largest text sizes, with no room left, does a card scroll within its glass.
private struct LearnPlaceCard: View {
    var place: AdministrativeDivision
    var localLanguage: Bool
    /// The place's own flag, or nil where it only has its country's, or shares one.
    var flag: String?
    var capitals: [CapitalCity]
    var codes: [(kind: MapGame.CodeKind, code: String)]
    /// The card's width.
    var width: CGFloat
    /// The row's height, so every card stands as tall as the tallest.
    var height: CGFloat
    /// The most height there is for a card, where it's limited.
    var maxHeight: CGFloat?
    var onMeasure: (CGFloat) -> Void
    /// The card's height with everything showing.
    @State private var shownHeight: CGFloat = 0
    @ScaledMetric(relativeTo: .title) private var flagHeight = 34

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        let shown = content
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { height in
                if abs(height - shownHeight) > 0.5 { shownHeight = height }
            }
        Group {
            if let maxHeight, shownHeight > maxHeight + 0.5 {
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
        .onChange(of: shownHeight) { if shownHeight > 0 { onMeasure(shownHeight) } }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if !capitals.isEmpty {
                CapitalLine(capitals: capitals, color: MapGame.learnColor)
                    // Its chips run on to the card's edges when they scroll.
                    .padding(.horizontal, -16)
            }
            // The code standing in for the flag isn't listed again.
            let listed = codes.filter { $0.kind != emblem?.kind }
            if !listed.isEmpty {
                CodeGrid(codes: listed)
            }
        }
        .padding(16)
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

    /// The name, its other name and region beneath, and the flag beside them, or the code standing
    /// in for it.
    private var header: some View {
        let name = place.displayName(localLanguage: localLanguage)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .typeStyle(.placeName, language: place.language(of: name))
                    .fontDesign(.default)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    // A long formal name keeps gliding to its end and back, never cut short.
                    ScrollingText {
                        Text(subtitle)
                            .typeStyle(.compactPlaceSubtitle, language: place.language(of: subtitle))
                            .fontDesign(.default)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let flag {
                // The flag as it is, its own shape uncut and unframed, lifted by a soft shadow.
                Image(flag)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .frame(maxWidth: flagHeight * 1.9, maxHeight: flagHeight)
                    .padding(.top, 6)
                    .accessibilityHidden(true)
            } else if let emblem {
                // Drawn as a question shows it, at about the flag's height, never squeezed by a long name.
                CodeBadge(code: emblem.code, kind: emblem.kind, size: 24)
                    .fixedSize()
                    .padding(.top, 6)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(emblem.kind.learnName) \(CodeBadge.spoken(emblem.code))")
            }
        }
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

/// A place's codes in a tidy grid, two to a row, each a small coloured symbol, its kind's short
/// name, and the code. A code that runs long, such as Brazil's several aircraft prefixes, takes a
/// row of its own. VoiceOver hears every kind's name and the code letter by letter.
private struct CodeGrid: View {
    var codes: [(kind: MapGame.CodeKind, code: String)]

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 6, verticalSpacing: 7) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { index, entry in
                        cells(for: entry, isLast: index == row.count - 1, spansRow: row.count == 1)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spoken(codes))
    }

    /// The codes in rows of two, a long one on a row of its own.
    private var rows: [[(kind: MapGame.CodeKind, code: String)]] {
        var rows: [[(kind: MapGame.CodeKind, code: String)]] = []
        var pending: (kind: MapGame.CodeKind, code: String)?
        for entry in codes {
            if entry.code.count > 6 {
                rows.append([entry])
            } else if let first = pending {
                rows.append([first, entry])
                pending = nil
            } else {
                pending = entry
            }
        }
        if let pending { rows.append([pending]) }
        return rows
    }

    @ViewBuilder
    private func cells(for entry: (kind: MapGame.CodeKind, code: String), isLast: Bool, spansRow: Bool) -> some View {
        Image(systemName: entry.kind.symbolName)
            .font(.caption.weight(.medium))
            .foregroundStyle(entry.kind.tint)
            .gridColumnAlignment(.center)
        Text(entry.kind.learnName)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
        Text(entry.kind.listed(entry.code))
            .font(.subheadline)
            .monospacedDigit()
            .typesettingLanguage(Locale.Language(identifier: "zh-Hans"), isEnabled: entry.kind == .shortName)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.trailing, isLast ? 0 : 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gridCellColumns(spansRow ? 4 : 1)
    }

    /// Every code for VoiceOver, such as "Codes: ISO D Z, web dot d z".
    static func spoken(_ codes: [(kind: MapGame.CodeKind, code: String)]) -> String {
        "Codes: " + codes.map { "\($0.kind.spokenName) \(CodeBadge.spoken($0.code))" }.joined(separator: ", ")
    }
}

private extension MapGame.CodeKind {
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

/// A place's capitals, each a chip in Learn's colour: its name, and beneath, what it is, "Capital"
/// where there's one, or its part, such as "Official capital" or "Seat of govt during the war",
/// where there are several. Chips that don't fit side by side scroll sideways, edge to edge.
private struct CapitalLine: View {
    var capitals: [CapitalCity]
    var color: Color

    var body: some View {
        let chips = HStack(spacing: 8) {
            ForEach(capitals, id: \.self) { capital in
                chip(for: capital)
            }
        }
        .padding(.horizontal, 16)
        // Side by side where they fit; otherwise a row that scrolls, so a lone capital never
        // catches the swipe that turns the cards.
        ViewThatFits(in: .horizontal) {
            chips
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView(.horizontal) { chips }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private func chip(for capital: CapitalCity) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(capital.name)
                .typeStyle(.compactPlaceName)
                .fontDesign(.default)
                .lineLimit(1)
                .fixedSize()
            Text(capitals.count == 1 ? "Capital" : capital.role.map(Self.caption(for:)) ?? "Capital")
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// For VoiceOver, such as "Capitals: Khartoum, official; Port Sudan, seat of government during the war".
    private var spoken: String {
        if capitals.count == 1, let capital = capitals.first { return "Capital: \(capital.name)" }
        return "Capitals: " + capitals.map { capital in capital.role.map { "\(capital.name), \($0)" } ?? capital.name }
            .joined(separator: "; ")
    }

    /// A part in governing as a chip says it: a single word as that kind of capital, "Official
    /// capital"; anything longer as written, shortened, "Seat of govt during the war".
    static func caption(for role: String) -> String {
        let short = role
            .replacingOccurrences(of: "government", with: "govt")
            .replacingOccurrences(of: " and ", with: " & ")
        let phrase = short.contains(" ") || short.contains(",") || short.contains(";") ? short : short + " capital"
        return phrase.prefix(1).uppercased() + phrase.dropFirst()
    }
}
