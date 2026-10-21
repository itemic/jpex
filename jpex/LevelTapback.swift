import SwiftUI

/// A quick level picker that floats beside a place, like a Messages tapback: the place's flag
/// beside its name and its current level, then a row of glossy badges, one per level, with the
/// current one ringed. Tap a badge to set it, or slide along them and let go, each one named as the
/// finger passes: the ring hops across to it and the picker puts itself away. The badges always sit
/// in one row, coming smaller where the picker is narrow rather than scrolling. Tap anywhere else
/// to put it away sooner. A place with subdivisions of its own also gets a way into them. Rather
/// than dimming everything around it, it glows faintly in its level's colour, brighter than the
/// page where the display has HDR headroom.
/// On a map it points at its place, with the kind of place it is in small capitals above its name.
struct LevelTapback: View {
    var status: VisitLevel
    var place: AdministrativeDivision
    var localLanguage: Bool
    /// The place's own subdivisions, such as Japan's prefectures, at every level they're listed at,
    /// such as France's regions and its departments.
    var collections: [CollectionSummary] = []
    /// A line in small capitals above the name, such as "State".
    var eyebrow: String? = nil
    /// Where it points at its place, as on a map. Nil floats it free, as beside a list row.
    var pointer: CalloutPointer? = nil
    /// The most room it may take, point and all: what's beneath the badges scrolls past it.
    var maxHeight: CGFloat? = nil
    /// Whether a higher level chosen here floats its badge up out of the picker, over everything
    /// around it, as a pill's does when tapped. Beside a list row the row's own pill sits under the
    /// picker, so the badge rises from here instead; on a map, the place itself lifts off.
    var floatsChosenBadge = false
    /// What the World map's layers say about the place, such as its plugs, under the badges.
    var facts: [MapFact] = []
    var onSelect: (VisitLevel) -> Void
    /// Opens one of `collections`, by ID.
    var onOpenCollection: (String) -> Void
    /// Where it's offered, as on the full map outside the Atlas, opens the place's card there.
    var onOpenAtlas: (() -> Void)? = nil
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.breaksOutOntoScreen) private var breaksOutOntoScreen
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .body) private var badgeSize = 42
    /// How tall the flag is, about the height of the name beside it.
    @ScaledMetric(relativeTo: .title3) private var flagHeight = 30
    @State private var hasAppeared = false
    /// How wide the row of badges came out, which the way into the place's subdivisions matches.
    @State private var badgesWidth: CGFloat = 0
    @State private var badgesHeight: CGFloat = 0
    /// How big what's beneath the badges comes out, scrolling or not.
    @State private var extrasSize: CGSize = .zero
    /// How tall the header came out, so the room kept for it fits any names at any text size.
    @State private var headerHeight: CGFloat?
    /// Counts taps on each level's badge, by level, so only the badge tapped pops.
    @State private var picks: [String: Int] = [:]
    /// Where each level's badge is on screen, for a chosen one to float up from.
    @State private var badgeFrames = BadgeFrames()
    /// The badge under a finger sliding along them, by index.
    @State private var hovered: Int?
    /// Set while a finger slides along the badges, so the badge it began on doesn't also choose.
    @State private var isScrubbing = false

    /// The least room worth pointing at a place from: enough for its name and every level.
    static let minimumHeight: CGFloat = 150

    /// How the picker comes in, the same beside a row and on a map.
    static let opening = Animation.bouncy(duration: 0.4, extraBounce: 0.08)
    /// How it goes away.
    static let closing = Animation.smooth(duration: 0.25)
    /// How long it stays once a level is chosen: long enough for the ring to land on the new badge
    /// and the level beside the flag to change, then it puts itself away.
    static let settleDelay = Duration.seconds(0.6)

    /// Grows out of its point, or the corner nearest its place, and shrinks back a little as it
    /// fades. With Reduce Motion it simply fades.
    static func transition(from anchor: UnitPoint, reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .scale(scale: 0.3, anchor: anchor).combined(with: .opacity),
            removal: .scale(scale: 0.85, anchor: anchor).combined(with: .opacity))
    }

    /// How far the header keeps in from the picker's top and sides, and the badges from its foot.
    private static let edge: CGFloat = 16

    /// Whether there is anything beneath the badges.
    private var hasExtras: Bool { !collections.isEmpty || onOpenAtlas != nil || !facts.isEmpty }

    /// How tall the header is taken to be until it has been measured.
    private var guessedHeaderHeight: CGFloat { eyebrow == nil ? 46 : 62 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Room for the header, which is overlaid so long names can't widen the picker.
            Color.clear
                .frame(width: 0, height: headerHeight ?? guessedHeaderHeight)
                .padding([.horizontal, .top], Self.edge)
            // The badges hug their width, and where the picker is narrow, as on iPhone Duo closed or at
            // large text sizes, they come smaller so every level still fits in one row, never
            // scrolling sideways, so a finger can always slide along them all.
            ViewThatFits(in: .horizontal) {
                ForEach(badgeSizes, id: \.self) { size in
                    badges(size: size)
                }
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: {
                badgesWidth = $0.width
                badgesHeight = $0.height
            }
            extras
        }
        .overlay(alignment: .top) {
            header
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                .padding([.horizontal, .top], Self.edge)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(pointer?.pointsDown == true ? .bottom : .top, pointer == nil ? 0 : CalloutShape.pointerHeight)
        // Tinted only lightly, so the glass stays glass.
        .glassPanel(in: shape, tint: status == .never ? nil : status.color.opacity(0.55), interactive: true)
        .background {
            // A halo behind the glass, which the glass takes up as if lit from within. Before the
            // place has a level it's a soft white wash; with one, the colour gathers at the edges and
            // only breathes into the glass, so it's a tint over it rather than a slab of colour.
            ZStack {
                if status == .never {
                    shape
                        .fill(glow)
                        .padding(-3)
                        .blur(radius: 16)
                        .opacity(0.55)
                } else {
                    shape
                        .stroke(glow, lineWidth: 10)
                        .padding(-3)
                        .blur(radius: 14)
                        .opacity(0.5)
                    shape
                        .fill(glow)
                        .opacity(0.06)
                }
            }
            .accessibilityHidden(true)
        }
        .overlay {
            shape
                .stroke(glow.opacity(status == .never ? 0.9 : 0.55), lineWidth: 1)
                .padding(0.5)
                .allowsHitTesting(false)
        }
        .animation(.smooth(duration: 0.5), value: status)
        .onAppear { hasAppeared = true }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Level for \(place.name)")
    }

    /// The ways into the place's subdivisions and what the map's layers say about it, beneath the
    /// badges. Where the picker would run taller than `maxHeight`, these scroll, so the place's
    /// name and its levels always stay in view.
    @ViewBuilder
    private var extras: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            // A row for each way into its subdivisions, such as France's regions, then its departments.
            if !collections.isEmpty || onOpenAtlas != nil {
                VStack(spacing: 6) {
                    ForEach(collections) { collection in
                        collectionRow(collection)
                    }
                    if let onOpenAtlas {
                        atlasRow(onOpenAtlas)
                    }
                }
                .padding([.horizontal, .bottom], Self.rowInset)
            }
            if !facts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(facts) { fact in
                        MapFactRow(fact: fact)
                    }
                }
                .padding(.horizontal, Self.edge)
                .padding(.bottom, Self.edge)
                // As wide as the badges, so a long fact glides rather than widening the picker.
                .frame(maxWidth: badgesWidth > 0 ? badgesWidth : nil, alignment: .leading)
            }
        }
        // The badges' own ring gap leaves some room already.
        .padding(.top, hasExtras ? 10 : 0)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { extrasSize = $0 }
        if let room = extrasRoom, extrasSize.height > room + 0.5 {
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(width: extrasSize.width, height: room)
            // What runs on fades out at the foot rather than being sliced off.
            .mask {
                LinearGradient(
                    stops: [.init(color: .black, location: 0.8), .init(color: .black.opacity(0), location: 1)],
                    startPoint: .top, endPoint: .bottom)
            }
        } else {
            content
        }
    }

    /// How far a way into the subdivisions keeps in from the picker's sides and foot.
    private static let rowInset: CGFloat = 12

    /// How tall the extras may be within `maxHeight`, after the point, the header and the badges.
    private var extrasRoom: CGFloat? {
        guard let maxHeight else { return nil }
        let pointerHeight = pointer == nil ? 0 : CalloutShape.pointerHeight
        let header = (headerHeight ?? guessedHeaderHeight) + Self.edge
        return max(maxHeight - pointerHeight - header - badgesHeight, 0)
    }

    /// A rounded panel, with a point towards its place when it has one.
    private var shape: AnyShape {
        let radius = badgeSize / 2 + 12
        guard let pointer else { return AnyShape(.rect(cornerRadius: radius, style: .continuous)) }
        return AnyShape(CalloutShape(pointerX: pointer.x, pointsDown: pointer.pointsDown, cornerRadius: radius))
    }

    /// The picker's glow: its level's colour, or white before the place has one.
    private var glow: Color {
        (status == .never ? Color.white : status.color).glowing(by: 1.5)
    }

    /// How the name is set: a stronger weight than a row's light one, which looks thin beside a flag.
    private static let nameStyle = TypeStyle(size: 20, textStyle: .title3, weight: .semibold, spacing: -0.3)

    /// The flag, in colour once the place has a level, beside the place's name, its name in the
    /// other language, and the level it's at, centred on them. Names too long for the picker scroll
    /// to show their ends rather than cutting off.
    private var header: some View {
        HStack(spacing: 12) {
            flag
            VStack(alignment: .leading, spacing: 1) {
                if let eyebrow {
                    ScrollingText {
                        Text(eyebrow)
                            .typeStyle(.smallEyebrow)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 1)
                }
                let name = place.displayName(localLanguage: localLanguage)
                ScrollingText {
                    Text(name)
                        .typeStyle(Self.nameStyle, language: place.language(of: name))
                }
                // Only the name in the other language: the formal name is too long for so small a card.
                if let subtitle = place.alternateName(localLanguage: localLanguage) {
                    ScrollingText {
                        Text(subtitle)
                            .placeName(place.language(of: subtitle))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                levelLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The level the place is at, beneath its name, in the level's colour, or quietly grey before it
    /// has one. While a finger slides along the badges it gives way to the name floating over them.
    private var levelLine: some View {
        ScrollingText {
            Text(status.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(status == .never ? AnyShapeStyle(.secondary) : AnyShapeStyle(levelTextColor))
                .contentTransition(.opacity)
        }
        .opacity(hovered == nil ? 1 : 0)
    }

    /// The level's colour as text: brighter than the badge in the dark, a little deeper in the light,
    /// where its own colour would wash out against the glass.
    private var levelTextColor: Color {
        colorScheme == .dark ? status.color.glowing(by: 1) : status.color.mix(with: .black, by: 0.18)
    }

    /// The flag at its own shape, about as tall as the name beside it, in colour once the place has
    /// a level and grey before.
    private var flag: some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        return Image(place.flagAssetName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: flagHeight * 1.8, maxHeight: flagHeight)
            .clipShape(shape)
            .grayscale(status == .never ? 1 : 0)
            .overlay { shape.strokeBorder(.primary.opacity(0.12), lineWidth: 1 / displayScale) }
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            .animation(.smooth(duration: 0.8), value: status)
            .accessibilityHidden(true)
    }

    /// A way into the place's subdivisions at one level: their kind and how many count on one line,
    /// with a bar of their levels beneath across the row's whole width, so the name has the room
    /// to be read whole rather than squeezed beside the count and bar.
    private func collectionRow(_ collection: CollectionSummary) -> some View {
        Button { onOpenCollection(collection.id) } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    ScrollingText {
                        Text(collection.label)
                            .font(.subheadline.weight(.semibold))
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 4)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(collection.counted, format: .number)
                            .typeStyle(.count)
                        Text("/ \(collection.total.formatted())")
                            .typeStyle(.countTotal)
                            .foregroundStyle(.secondary)
                    }
                    .fixedSize()
                    Image(systemName: "chevron.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                StatusTallyBar(
                    tally: collection.tally, total: collection.total, minimumStatus: collection.minimumStatus,
                    showsStripes: false)
                    .frame(height: 4)
            }
            // Spans the picker: the badges' width, less the row's margins and padding.
            .frame(width: badgesWidth > 52 ? badgesWidth - 2 * Self.rowInset - 28 : nil)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.primary.opacity(0.06), in: .rect(cornerRadius: 16, style: .continuous))
            .contentShape(.rect(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PillButtonStyle(pressedScale: 0.96))
        .accessibilityLabel("\(collection.label), \(collection.counted) of \(collection.total)")
    }

    /// The way into the place's card in the Atlas, across the picker's whole width like the ways
    /// into its subdivisions, in the Atlas's indigo.
    private func atlasRow(_ open: @escaping () -> Void) -> some View {
        Button(action: open) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MapGame.learnColor)
                    .accessibilityHidden(true)
                ScrollingText {
                    Text("Open in Atlas")
                        .font(.subheadline.weight(.semibold))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(width: badgesWidth > 52 ? badgesWidth - 2 * Self.rowInset - 28 : nil)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(MapGame.learnColor.opacity(0.1), in: .rect(cornerRadius: 16, style: .continuous))
            .contentShape(.rect(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PillButtonStyle(pressedScale: 0.96))
        .accessibilityHint("Shows its card, with its flag, capitals and codes.")
    }

    /// A badge for every level. Where they all fit, a finger can slide along them as along a
    /// Messages tapback: each one it passes lifts and is named, and letting go chooses it.
    private func badges(size: CGFloat) -> some View {
        let levels = ladder.allLevels
        return HStack(spacing: Self.badgeSpacing) {
            ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                badge(for: level, isHovered: hovered == index, size: size)
                    .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.3)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.15) : .bouncy(duration: 0.4, extraBounce: 0.2).delay(Double(index) * 0.03),
                        value: hasAppeared)
            }
        }
        .overlay(alignment: .topLeading) { ring(among: levels, size: size) }
        .overlay(alignment: .topLeading) { levelName(among: levels, size: size) }
        // The gaps between badges catch a sliding finger too.
        .contentShape(.rect)
        .simultaneousGesture(scrub(along: levels, size: size))
        .sensoryFeedback(.selection, trigger: hovered) { _, new in new != nil }
        // The ring's gap brings each badge in line with the header's edge; the room above is where
        // a name floats while a finger slides along them.
        .padding(.horizontal, Self.edge - Self.ringGap)
        .padding(.top, Self.edge - Self.ringGap)
        .padding(.bottom, hasExtras ? 0 : Self.edge - Self.ringGap)
    }

    private static let badgeSpacing: CGFloat = 6
    /// The room around each badge for the ring that marks the current level.
    private static let ringGap: CGFloat = 3

    /// From one badge's leading edge to the next's, for badges of a size.
    private func badgePitch(_ size: CGFloat) -> CGFloat { size + Self.ringGap * 2 + Self.badgeSpacing }

    /// The sizes the badges may take, largest first: their own, then smaller steps for a narrow
    /// picker, never below a comfortable target.
    private var badgeSizes: [CGFloat] {
        [badgeSize, badgeSize * 0.88, badgeSize * 0.78, max(badgeSize * 0.7, 30)]
    }

    private func pick(_ level: VisitLevel) {
        picks[level.id, default: 0] += 1
        floatBadge(of: level)
        onSelect(level)
    }

    /// Choosing a higher level, where `floatsChosenBadge` asks for it, sends that level's badge
    /// floating up out of the picker from the badge tapped, sparking at the top level, over
    /// everything around. Only while these views are the ones in front, and never with Reduce Motion.
    private func floatBadge(of level: VisitLevel) {
        guard floatsChosenBadge, breaksOutOntoScreen, !reduceMotion, ladder.rank(of: level) > ladder.rank(of: status),
              let rect = badgeFrames.rects[level.id], !rect.isNull, !rect.isEmpty
        else { return }
        ToastCenter.shared.float(LevelFloat(
            origin: CGPoint(x: rect.midX, y: rect.minY), color: level.color, symbolName: level.symbolName,
            isTop: ladder.higher(than: level) == nil))
    }

    /// The badge under a finger sliding along them, or none once it strays well above or below.
    private func scrub(along levels: [VisitLevel], size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                isScrubbing = true
                let index = Int(((value.location.x + Self.badgeSpacing / 2) / badgePitch(size)).rounded(.down))
                let isNear = value.location.y > -44 && value.location.y < size + 50
                let next = isNear ? min(max(index, 0), levels.count - 1) : nil
                if next != hovered {
                    withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .snappy(duration: 0.25, extraBounce: 0.2)) {
                        hovered = next
                    }
                }
            }
            .onEnded { _ in
                if let hovered, levels.indices.contains(hovered) { pick(levels[hovered]) }
                withAnimation(.snappy(duration: 0.25)) { hovered = nil }
                // The badge the slide began on lets go too; it mustn't choose its own level as well.
                Task {
                    try? await Task.sleep(for: .milliseconds(120))
                    isScrubbing = false
                }
            }
    }

    private func badge(for level: VisitLevel, isHovered: Bool, size badgeSize: CGFloat) -> some View {
        let isCurrent = level.id == status.id
        return Button {
            guard !isScrubbing else { return }
            pick(level)
        } label: {
            Image(systemName: level.symbolName)
                .font(.system(size: badgeSize * 0.4, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5)
                .symbolEffect(.bounce, value: reduceMotion ? 0 : picks[level.id, default: 0])
                .frame(width: badgeSize, height: badgeSize)
                .background { BadgeGloss(color: level.color) }
                .clipShape(.circle)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { badgeFrames.rects[level.id] = $0 }
                .pop(on: picks[level.id, default: 0])
                .shadow(color: level.color.opacity(isHovered ? 0.5 : 0), radius: 8, y: 4)
                .scaleEffect(isHovered && !reduceMotion ? 1.22 : 1, anchor: .bottom)
                .padding(Self.ringGap)
                .contentShape(.circle)
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel(level.name)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    /// One ring around the current level's badge. Choosing another level hops the ring across to
    /// the new badge, rather than one fading out and another in.
    @ViewBuilder
    private func ring(among levels: [VisitLevel], size badgeSize: CGFloat) -> some View {
        if let index = levels.firstIndex(where: { $0.id == status.id }) {
            let size = badgeSize + Self.ringGap * 2
            Circle()
                .strokeBorder(status.color.glowing(by: 1), lineWidth: 2.5)
                .frame(width: size, height: size)
                // Lands just after the badges, as if settling on the one already chosen.
                .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.6)
                .opacity(hasAppeared ? 1 : 0)
                .animation(
                    reduceMotion ? .easeOut(duration: 0.15) : .bouncy(duration: 0.4, extraBounce: 0.2).delay(0.12),
                    value: hasAppeared)
                .offset(x: CGFloat(index) * badgePitch(badgeSize))
                .animation(Motion.moving(Motion.hop, reduceMotion: reduceMotion), value: index)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// While a finger slides along the badges, the name of the one beneath it, raised over the lifted
    /// badge, since the finger hides it. At rest the level is named beside the flag instead.
    @ViewBuilder
    private func levelName(among levels: [VisitLevel], size badgeSize: CGFloat) -> some View {
        if let index = hovered, levels.indices.contains(index) {
            let level = levels[index]
            let size = badgeSize + Self.ringGap * 2
            // The first and last names line up with their badge's outer edge, so they stay inside.
            let alignment: HorizontalAlignment = index == 0 ? .leading : index == levels.count - 1 ? .trailing : .center
            Color.clear
                .frame(width: size, height: size)
                .overlay(alignment: Alignment(horizontal: alignment, vertical: .top)) {
                    Text(level.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(level.color.glowing(by: 1))
                        .lineLimit(1)
                        .fixedSize()
                        .offset(y: reduceMotion ? -18 : -18 - badgeSize * 0.22)
                        .id(level.id)
                        .transition(.opacity.combined(with: .offset(y: 4)))
                }
                .opacity(hasAppeared ? 1 : 0)
                .animation(reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.3).delay(0.15), value: hasAppeared)
                .offset(x: CGFloat(index) * badgePitch(badgeSize))
                .animation(reduceMotion ? .easeOut(duration: 0.2) : .snappy(duration: 0.3, extraBounce: 0.1), value: index)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// Where each of a tapback's badges is on screen, by level, kept aside from the view's state, since
/// it changes as the picker grows in or its badges scroll, and is only read when one is chosen.
private final class BadgeFrames {
    var rects: [String: CGRect] = [:]
}

/// Where a tapback points at its place: how far along its width, and whether it sits above the place.
struct CalloutPointer: Equatable {
    var x: CGFloat
    var pointsDown: Bool
}

/// The pills' glossy finish on a round badge.
struct BadgeGloss: View {
    var color: Color

    var body: some View {
        ZStack {
            color
            Color.white
                .mask(LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .center))
            color.brightness(-0.2)
                .mask(LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom))
        }
    }
}

/// Where the place a tapback belongs to sits, so the tapback can float beside it.
struct TapbackAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

extension Color {
    /// The colour made brighter by a number of exposure stops, past the white of the page where the
    /// display has HDR headroom. Earlier systems keep the colour as it is.
    func glowing(by stops: Double) -> Color {
        if #available(iOS 26.0, *) {
            return exposureAdjust(stops)
        }
        return self
    }
}
