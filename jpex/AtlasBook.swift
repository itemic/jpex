import SwiftUI

/// The Atlas as a book, on iPhone Duo held open like one: the map on the left-hand page, and on the
/// right a page for each place, its flag, names, capitals, codes and what the Atlas knows, one
/// sheet sliding over to the next. The two pages meet at the fold without a seam, the map running
/// up to it and the page's paper on from it. Partly folded, another layer takes the right-hand
/// page as an index of its key's places (see `AtlasBookIndex`).
enum AtlasBook {
    /// The two pages of an open book: the fold running down this space, from top to bottom, whether
    /// the device is partly folded or lying open flat. Nil where there's no such fold, as on any
    /// other device, iPhone Duo closed, or open and turned on its side, where the fold runs across.
    static func spread(in proxy: GeometryProxy) -> FoldRegions? {
        guard #available(iOS 27.1, *),
              let fold = proxy.reservedRegions(kind: .division, options: .includeInactive).first
        else { return nil }
        let size = proxy.size
        let frame = fold.frame
        // Running down the space, from top to bottom: taller than it's wide, and most of the height.
        guard frame.height > frame.width, frame.height > size.height * 0.5 else { return nil }
        // Partly folded, the pages keep clear of the crease; lying flat, they meet at the spine.
        let margins = fold.isActive ? fold.margins : EdgeInsets()
        let leading = frame.minX - margins.leading
        let trailing = frame.maxX + margins.trailing
        let far = CGRect(x: 0, y: 0, width: max(leading, 0), height: size.height)
        let near = CGRect(x: trailing, y: 0, width: max(size.width - trailing, 0), height: size.height)
        // Each page needs room to be a page.
        guard far.width > 240, near.width > 240 else { return nil }
        return FoldRegions(far: far, near: near, isAcross: false)
    }

    /// The paper the pages are printed on: the soft gray of the map's sea, so the spread reads as
    /// one book, the map on the left page and the place on the right.
    static let paper = Color.pageBackground

    /// How far the map runs on under the right-hand page, where the page's paper fades in over it.
    static let overlap: CGFloat = 56

    /// Where the two pages meet: the middle of the fold.
    static func spine(of spread: FoldRegions) -> CGFloat {
        (spread.far.maxX + spread.near.minX) / 2
    }
}

/// The right-hand page of the Atlas book: a few controls along its head, as the row of cards has,
/// "Atlas" to choose another layer, how far through the places with the list to jump from, the
/// place's level and a way out, and beneath them the pages themselves, one for each place, turned
/// with a swipe or a tap at their edge.
struct AtlasBookPages: View {
    var deck: LearnDeck
    var localLanguage: Bool
    /// The place on show's level, set from its badge.
    var status: Binding<VisitLevel>?
    /// What the Atlas knows about a place, after its codes.
    var facts: (AdministrativeDivision) -> [MapFact]
    /// Turned to another page, by a swipe or a tap at a page's edge, or by the arrow keys.
    var onStep: (Int) -> Void
    /// Jumped to a place picked from the list.
    var onJump: (Int) -> Void
    var onShowLayers: () -> Void
    var onClose: () -> Void
    /// How far the page's paper reaches past its contents towards the spine, under the crease of
    /// a partly folded device, so the paper meets the map with no gap between.
    var spineInset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .subheadline) private var buttonSize: CGFloat = 34

    var body: some View {
        VStack(spacing: 0) {
            head
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
            AtlasBookPager(
                count: deck.count, index: deck.index, reduceMotion: reduceMotion,
                page: { index in
                    AtlasBookPage(
                        deck: deck, place: deck.places[index], number: index + 1, localLanguage: localLanguage,
                        facts: facts(deck.places[index]))
                },
                onTurn: { index in onStep(index - deck.index) })
                .accessibilityElement(children: .contain)
                .accessibilityAction(named: "Next page") { onStep(1) }
                .accessibilityAction(named: "Previous page") { onStep(-1) }
        }
        .padding(.leading, spineInset)
        .background {
            AtlasBookPaper()
        }
        .background { keyboardSteps }
        .fontDesign(.rounded)
    }

    /// Along the head of the page: "Atlas", which opens the map's layers, how far through the
    /// places, which opens the list of them all, then the place's level and the cross.
    private var head: some View {
        HStack(spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    title(showsName: true)
                    jumpMenu
                }
                HStack(spacing: 8) {
                    title(showsName: false)
                    jumpMenu
                }
            }
            Spacer(minLength: 0)
            if let status, let place = deck.current {
                ZStack { levelBadge(status, for: place) }
            }
            closeButton
        }
    }

    /// "Atlas" and its book in a capsule of glass, which opens the map's layers to choose another.
    private func title(showsName: Bool) -> some View {
        Button(action: onShowLayers) {
            HStack(spacing: 7) {
                Image(systemName: "book.fill")
                    .foregroundStyle(MapGame.learnColor)
                if showsName {
                    Text("Atlas")
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
            .frame(minHeight: buttonSize)
            .fixedSize()
            .glassPanel(in: Capsule(), interactive: true)
            .contentShape(Capsule())
        }
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .accessibilityLabel("Atlas")
        .accessibilityHint("Shows the layers, to choose another.")
        .accessibilityAddTraits(.isHeader)
    }

    /// How far through the places, which opens the list of them all to jump to.
    private var jumpMenu: some View {
        Menu {
            jumpList
        } label: {
            HStack(spacing: 7) {
                HStack(spacing: 0) {
                    Text("\(deck.index + 1)")
                        .typeStyle(.count)
                        .contentTransition(.numericText(value: Double(deck.index)))
                    Text(" / \(deck.count)")
                        .typeStyle(.countTotal)
                }
                .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .lineLimit(1)
            .padding(.horizontal, 13)
            .frame(minHeight: buttonSize)
            .fixedSize()
            .glassPanel(in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(Motion.moving(Motion.count, reduceMotion: reduceMotion), value: deck.index)
        .accessibilityLabel("\(deck.index + 1) of \(deck.count)")
        .accessibilityHint("Opens a list of every place to jump to.")
    }

    /// Every place, by region where places are told apart by region, to jump to.
    @ViewBuilder
    private var jumpList: some View {
        let jump = Binding(get: { deck.index }, set: { onJump($0) })
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

    /// The place's level as a round badge, as on the row of cards, a badge of its own for each
    /// place, so turning the page never reads as a level-up.
    private func levelBadge(_ status: Binding<VisitLevel>, for place: AdministrativeDivision) -> some View {
        AtlasLevelBadge(level: status, placeName: place.displayName(localLanguage: localLanguage), size: buttonSize)
            .id(place.id)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.85)))
    }

    /// Puts the Atlas away.
    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: buttonSize, height: buttonSize)
                .glassPanel(in: Circle(), interactive: true)
                .contentShape(Circle())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel("Close Atlas")
    }

    /// The arrow keys turn the pages, as they step through the row of cards.
    private var keyboardSteps: some View {
        ZStack {
            Button("Previous place") { onStep(-1) }
                .keyboardShortcut(.leftArrow, modifiers: [])
            Button("Next place") { onStep(1) }
                .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }
}
