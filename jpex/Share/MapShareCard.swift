import SwiftUI

/// The picture of a list's map that the person shares, made like a trading card. The map fills it,
/// framed however they like, with the place's name and, as the card's big stat, how many of its
/// places they've been to; their levels as the app's glossy pills; and a pass along the foot saying
/// it was logged with the app, and when. It's laid out at a fixed size, the same at every text size
/// and on every screen, so the share screen's preview is exactly the picture that's sent.
struct MapShareCard: View {
    var content: MapShareContent
    /// How far the map's colours have swept in, and the count rolled up, from 0 to 1, as the share
    /// screen opens. The picture that's sent is drawn whole.
    var reveal: Double = 1
    /// Whether the card draws its own foil, held still, as a picture does. On screen the foil is laid
    /// over the card instead, to slide as it tilts.
    var drawsFoil = true
    /// Whether the night sky twinkles, as it does on screen but not in a picture.
    var twinkles = false
    /// Told the part of the map to show as the person pinches and drags the card. Without it, the
    /// card holds still.
    var onReframe: ((CGRect) -> Void)? = nil
    /// Told how far two fingers have moved across the map since last told, in the map's own units,
    /// to turn the World beneath the card's frame, and nil as they lift. Without it, two fingers
    /// drag the frame as one does.
    var onTurn: ((CGSize?) -> Void)? = nil
    /// The part of the map shown when a pinch or drag began.
    @State private var gestureStart: CGRect?
    /// Whether two fingers are turning the World, and whether they have since the card was touched,
    /// so a drag that becomes a turn doesn't move the frame as well.
    @State private var isTurning = false
    @State private var hasTurned = false

    static let margin: CGFloat = 22
    /// The width of the column the words take down a wide card's side.
    private static let columnWidth: CGFloat = 220
    /// The fine line round the card: how far in from the card's edge it runs, and how round its
    /// corners are.
    private static let frameInset: CGFloat = 8
    private static let frameRadius: CGFloat = 20
    /// The size of the app's icon on the pass, and the room round it; the pass is just tall enough
    /// to hold it.
    private static let tileSize: CGFloat = 40
    private static let tilePadding: CGFloat = 10
    private static let passHeight = tileSize + tilePadding * 2
    /// The foot of the card the pass takes: the pass, and the line beneath it that it sits inside.
    private static let passRoom = passHeight + frameInset + 1

    private var palette: ShareCardPalette { content.palette }
    private var size: CGSize { content.format.size }

    var body: some View {
        ZStack(alignment: .topLeading) {
            backdrop
            switch content.layout {
            case .map, .new:
                ShareCardMap(
                    map: content.map, statuses: content.statuses, palette: palette, colouring: content.colouring,
                    flags: content.colouring == .flags ? content.flags : [:],
                    smartColors: content.colouring == .smart ? content.smartColors : [:],
                    highlighted: content.layout == .new ? Set(content.newPlaceIDs) : nil, focus: content.focus,
                    insets: mapInsets, reveal: reveal)
                if content.layout == .new {
                    NewPlaceMarks(
                        map: content.map, places: newMarks, language: content.language, palette: palette,
                        focus: content.focus, insets: mapInsets)
                        .opacity(reveal)
                } else if content.showsFlags {
                    FlagPins(
                        map: content.map, statuses: content.statuses, ladder: content.ladder, flags: content.flags,
                        focus: content.focus, insets: mapInsets)
                        .opacity(reveal)
                }
                scrim
            case .wordMap:
                ShareWordMap(
                    map: content.map,
                    words: Dictionary(content.words.map { ($0.id, $0) }) { first, _ in first },
                    language: content.language, palette: palette, colouring: content.colouring, focus: content.focus,
                    insets: mapInsets)
                    .opacity(reveal)
                scrim
            case .names, .count:
                EmptyView()
            }
            words
            frame
            if drawsFoil, content.showsFoil {
                FoilSheen(shine: 0.35, strength: FoilSheen.strength(on: palette))
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        // The foil's light blends with the card alone, not with whatever the card sits on.
        .compositingGroup()
        .contentShape(Rectangle())
        .gesture(reframing, including: onReframe != nil && content.layout.showsMap ? .all : .none)
        .gesture(TwoFingerPan(isEnabled: onTurn != nil && content.layout.showsMap, onMove: turn))
        .environment(\.visitLadder, content.ladder)
        .environment(\.colorScheme, palette.colorScheme)
        // A picture keeps its layout whatever the person's text size.
        .dynamicTypeSize(.large)
    }

    /// The card's paper: the flag beneath its shade, the paper's colours, and the stars, shine or
    /// tartan over them.
    @ViewBuilder private var backdrop: some View {
        switch palette.pattern {
        case .flag:
            FlagBackdrop(flag: content.country.flagAssetName, quilt: content.visitedFlags)
        case .stripes:
            StripesPattern(stripes: content.stripes)
        case .plain, .stars, .gloss, .plaid:
            EmptyView()
        }
        LinearGradient(colors: palette.background, startPoint: .top, endPoint: .bottom)
        switch palette.pattern {
        case .stars:
            NightSky(twinkles: twinkles)
        case .gloss:
            LinearGradient(colors: [.white.opacity(0.34), .white.opacity(0)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.45))
            RadialGradient(
                colors: [.white.opacity(0.22), .white.opacity(0)], center: UnitPoint(x: 0.15, y: 0.05),
                startRadius: 0, endRadius: max(size.width, size.height) * 0.6)
        case .plaid:
            PlaidPattern(color: content.tint.color)
        case .plain, .flag, .stripes:
            EmptyView()
        }
    }

    // MARK: The words

    private var words: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                switch (content.layout.showsMap, content.format) {
                case (true, .square):
                    compactHeader
                case (true, .tall):
                    header(statSize: 96)
                case (true, .wide):
                    VStack(alignment: .leading, spacing: 16) {
                        header(statSize: 80)
                        key
                    }
                    .frame(width: Self.columnWidth, alignment: .leading)
                case (false, _):
                    // The names are the picture; the count, where it isn't the picture itself, sits in the corner.
                    if content.layout == .count {
                        titleRow
                    } else {
                        compactHeader
                    }
                }
            }
            .shadow(color: .black.opacity(palette.textShadow ? 0.35 : 0), radius: 3, y: 1)
            .padding([.top, .horizontal], Self.margin)
            if content.layout.showsMap {
                Spacer(minLength: 0)
            } else {
                typography
                    .halo(palette.halo)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, Self.margin)
                    .padding(.vertical, 14)
            }
            if content.format != .wide || !content.layout.showsMap {
                key
                    .padding(.horizontal, Self.margin)
                    .padding(.bottom, 12)
            }
            pass
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    /// The names set in the chosen typographic layout, between the name and the pass.
    @ViewBuilder private var typography: some View {
        switch content.layout {
        case .names:
            ShareNames(
                style: content.namesStyle, words: content.words, language: content.language, palette: palette,
                colouring: content.colouring)
        case .count:
            ShareCountFill(
                count: content.counted, label: content.countLabel, words: content.words, language: content.language,
                palette: palette, colouring: content.colouring, smartPalette: content.smartPalette,
                seed: content.fillSeed)
        case .map, .new, .wordMap:
            EmptyView()
        }
    }

    /// The place's flag and name alone, for the count layout, whose picture is the count.
    private var titleRow: some View {
        HStack(spacing: 10) {
            flag(width: 30)
            title
        }
    }

    /// The place's flag and name, light and airy as in the list, over the card's big stat.
    private func header(statSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                flag(width: 30)
                title
            }
            stat(size: statSize, labelSize: 13, alignment: .leading)
        }
    }

    /// The name, and the stat in the corner as on a trading card, on one line where they fit, so a
    /// square card leaves its map as much room as it can; otherwise the name above the stat.
    private var compactHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                HStack(spacing: 8) {
                    flag(width: 27)
                    titleText(size: 26).fixedSize()
                }
                .padding(.top, 4)
                Spacer(minLength: 0)
                stat(size: 46, labelSize: 10, alignment: .trailing)
                    .fixedSize()
            }
            header(statSize: 46)
        }
    }

    /// The flag, in the 3:2 shape the app's flags are drawn in, or nothing for a list without one,
    /// such as the World.
    @ViewBuilder private func flag(width: CGFloat) -> some View {
        if let name = content.country.flagAssetName {
            let size = CGSize(width: width, height: width * 2 / 3)
            let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
            FlagThumbnail(name: name, size: size)
                .frame(width: size.width, height: size.height)
                .clipShape(shape)
                .overlay { shape.strokeBorder(palette.text.opacity(0.14), lineWidth: 0.5) }
        }
    }

    /// The name on one line, a size smaller for a long one. A picture can't scroll a long name as
    /// the app does, so the very longest wrap as a last resort rather than lose their end.
    private var title: some View {
        ViewThatFits(in: .horizontal) {
            titleText(size: 30).fixedSize()
            titleText(size: 26).fixedSize()
            titleText(size: 22).fixedSize()
            titleText(size: 18).fixedSize()
            titleText(size: 18).lineLimit(2)
        }
    }

    private func titleText(size: CGFloat) -> some View {
        Text(content.country.name)
            .font(.system(size: size, weight: palette.fontDesign == .serif ? .regular : .light, design: palette.fontDesign))
            .kerning(palette.fontDesign == .serif ? 0 : -0.5)
            .foregroundStyle(palette.text)
    }

    /// How many places the person has been to, or for the new layout, how many they've just added,
    /// as a trading card's stat: big candy figures over what they count, in small spaced capitals.
    private func stat(size: CGFloat, labelSize: CGFloat, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            count(size: size)
                // Figures leave room beneath them for letters that drop below the line; the label
                // tucks up into it.
                .padding(.bottom, -size * 0.12)
            countLabel(size: labelSize)
                .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
        }
    }

    /// The count in heavy, rounded figures filled with the colours of the person's levels and lit
    /// across the top like the app's pills, glowing on a dark card. On screen it rolls up from
    /// nothing as the card's colours sweep in.
    private func count(size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            // The places just been to, as they're added: "+3".
            if content.layout == .new {
                Text(verbatim: "+")
            }
            RollingNumber(value: Double(content.layout == .new ? content.newPlaceIDs.count : content.counted) * reveal)
        }
            .font(palette.fontDesign == .serif
                ? .system(size: size, weight: .bold, design: .serif)
                : .system(size: size, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .kerning(-size / 30)
            .foregroundStyle(countFill)
            .overlay {
                LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0)], startPoint: .top, endPoint: .center)
                    .blendMode(.sourceAtop)
            }
            .compositingGroup()
            .shadow(
                color: palette.glows ? (countColors.first ?? .white).opacity(0.6) : .black.opacity(0.14),
                radius: palette.glows ? 12 : 1.5, y: palette.glows ? 0 : 1)
            .fixedSize()
    }

    /// The colours the count's figures run through: the person's levels', highest first; the main
    /// colours of the flags of the first few places been to; the first few places' own smart
    /// colours; or the colour chosen for them, or none, for the card's ink.
    private var countColors: [Color] {
        switch content.colouring {
        case .levels:
            return content.levelCounts.map(\.level.color)
        case .flags:
            var colors: [Color] = []
            for word in content.words.prefix(6) where word.isVisited {
                guard let flag = FlagColors.of(word.flag) else { continue }
                if let color = flag.colors.first(where: palette.standsOut), !colors.contains(color) {
                    colors.append(color)
                }
            }
            return Array(colors.prefix(4))
        case .smart:
            var colors: [Color] = []
            for word in content.words.prefix(8) {
                if let color = word.smart, !colors.contains(color) { colors.append(color) }
            }
            return Array(colors.prefix(4))
        case .plain:
            return palette.plainOverride.map { [$0] } ?? []
        }
    }

    /// The count's colours from the figures' top corner to their foot; a lone colour lightening
    /// towards the top; the card's ink when there are none.
    private var countFill: AnyShapeStyle {
        let colors = countColors
        switch colors.count {
        case 0:
            return AnyShapeStyle(palette.text)
        case 1:
            return AnyShapeStyle(LinearGradient(
                colors: [colors[0].mix(with: .white, by: 0.3), colors[0]], startPoint: .top, endPoint: .bottom))
        default:
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private func countLabel(size: CGFloat) -> some View {
        Text(content.layout == .new ? content.newCountLabel : content.countLabel)
            .font(.system(size: size, weight: .semibold, design: palette.fontDesign))
            .tracking(size * 0.18)
            .textCase(.uppercase)
            .foregroundStyle(palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Whether the levels' pills show: only while the places are coloured by their levels, which
    /// the pills are the key to.
    private var showsKey: Bool {
        content.showsKey && content.colouring == .levels
    }

    /// The levels with places at them, highest first, as the app's glossy pills, each with how many.
    @ViewBuilder private var key: some View {
        let entries = content.levelCounts
        if showsKey, !entries.isEmpty {
            FlowLayout(spacing: 8, lineSpacing: 6) {
                ForEach(entries, id: \.level.id) { entry in
                    VisitPillLabel(status: entry.level, suffix: " \(entry.count.formatted())")
                }
            }
        }
    }

    /// The pass along the foot, as torn from a ticket, inside the line round the card, its lower
    /// corners the line's own: the app's icon, the one the person has chosen, saying the map was
    /// logged with it, and at the other end, quietly, the day the picture was taken, where that's
    /// on. The icon sits as far in from the pass's edge as from its foot, its corners rounded to run
    /// alongside the card's.
    private var pass: some View {
        // Inside the line, which is a point thick.
        let passRadius = Self.frameRadius - 1
        let tileRadius = passRadius - Self.tilePadding
        return HStack(spacing: 12) {
            let iconShape = RoundedRectangle(cornerRadius: tileRadius, style: .continuous)
            Image(content.iconName)
                .resizable()
                .frame(width: Self.tileSize, height: Self.tileSize)
                .clipShape(iconShape)
                .overlay { iconShape.strokeBorder(palette.text.opacity(0.1), lineWidth: 0.5) }
            passLines(over: "Logged with", AppStoreLink.appName)
            Spacer(minLength: 8)
            if content.showsDate {
                // Small and quiet, so the app's name stays the pass's one big word.
                VStack(alignment: .trailing, spacing: 0) {
                    Text("As of")
                    Text(Date.now, format: .dateTime.day().month(.abbreviated).year())
                }
                .font(.system(size: 11, weight: .medium, design: palette.fontDesign))
                .foregroundStyle(palette.secondaryText)
                .fixedSize()
            }
        }
        .padding(Self.tilePadding)
        .frame(height: Self.passHeight)
        .background(
            palette.pass,
            in: UnevenRoundedRectangle(bottomLeadingRadius: passRadius, bottomTrailingRadius: passRadius, style: .continuous))
        .overlay(alignment: .top) {
            // Perforated, as where a pass tears off.
            Perforation()
                .fill(palette.perforation)
                .frame(height: 1.5)
        }
        .padding([.horizontal, .bottom], Self.frameInset + 1)
    }

    /// A small, quiet label over a word in the card's type, as a boarding pass sets its fields.
    private func passLines(over label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: palette.fontDesign))
                .foregroundStyle(palette.secondaryText)
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: palette.fontDesign))
                .foregroundStyle(palette.text)
        }
        .fixedSize()
    }

    /// A fine line round the card, as round a trading card; a double rule on the atlas's plate.
    private var frame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Self.frameRadius, style: .continuous)
                .strokeBorder(palette.frame, lineWidth: 1)
                .padding(Self.frameInset)
            if content.design == .atlas {
                RoundedRectangle(cornerRadius: Self.frameRadius - 4, style: .continuous)
                    .strokeBorder(palette.frame.opacity(0.6), lineWidth: 0.5)
                    .padding(Self.frameInset + 4)
            }
        }
        .allowsHitTesting(false)
    }

    /// The card's paper laid softly over any land framed beneath the words, so they stay clear.
    @ViewBuilder private var scrim: some View {
        let paper = palette.background[0]
        switch content.format {
        case .wide:
            LinearGradient(
                stops: [.init(color: paper, location: 0), .init(color: paper.opacity(0.85), location: 0.6), .init(color: paper.opacity(0), location: 1)],
                startPoint: .leading, endPoint: .trailing)
                .frame(width: Self.margin + Self.columnWidth + 40)
        case .square, .tall:
            LinearGradient(
                stops: [.init(color: paper, location: 0), .init(color: paper.opacity(0.85), location: 0.55), .init(color: paper.opacity(0), location: 1)],
                startPoint: .top, endPoint: .bottom)
                .frame(height: mapInsets.top + 12)
        }
    }

    // MARK: The map

    /// The room the words leave the map, which the framed part is fitted inside.
    private var mapInsets: EdgeInsets {
        switch content.format {
        case .square:
            EdgeInsets(top: Self.margin + 64, leading: 14, bottom: Self.passRoom + keyHeight + 8, trailing: 14)
        case .tall:
            EdgeInsets(top: Self.margin + 162, leading: 16, bottom: Self.passRoom + keyHeight + 12, trailing: 16)
        case .wide:
            EdgeInsets(top: Self.margin, leading: Self.margin + Self.columnWidth + 12, bottom: Self.passRoom + 10, trailing: 16)
        }
    }

    /// Roughly how tall the pills run beneath the map, three to a line.
    private var keyHeight: CGFloat {
        let count = showsKey ? content.levelCounts.count : 0
        guard count > 0 else { return 0 }
        let lines = CGFloat((count + 2) / 3)
        return lines * 28 + (lines - 1) * 6 + 12
    }

    /// Pinching zooms the map about the fingers, and dragging moves it, as a photo is framed.
    private var reframing: some Gesture {
        SimultaneousGesture(DragGesture(minimumDistance: 2), MagnifyGesture())
            .onChanged { value in
                guard let onReframe else { return }
                let start = gestureStart ?? content.focus
                if gestureStart == nil { gestureStart = start }
                let area = ShareCardMap.fitRect(in: size, insets: mapInsets)
                let scale = ShareCardMap.transform(fitting: start, into: area).a
                guard scale > 0 else { return }
                var rect = start
                if let pinch = value.second {
                    let magnification = max(pinch.magnification, 0.05)
                    let anchor = CGPoint(x: pinch.startAnchor.x * size.width, y: pinch.startAnchor.y * size.height)
                    let fixed = CGPoint(
                        x: start.midX + (anchor.x - area.midX) / scale, y: start.midY + (anchor.y - area.midY) / scale)
                    rect = CGRect(
                        x: fixed.x + (start.minX - fixed.x) / magnification,
                        y: fixed.y + (start.minY - fixed.y) / magnification,
                        width: start.width / magnification, height: start.height / magnification)
                }
                if let drag = value.first, !hasTurned {
                    let zoomed = scale * start.width / rect.width
                    rect.origin.x -= drag.translation.width / zoomed
                    rect.origin.y -= drag.translation.height / zoomed
                }
                onReframe(MapFraming.clamped(rect, within: MapFraming.wholeFocus(of: content.map)))
            }
            .onEnded { _ in
                gestureStart = nil
                if !isTurning { hasTurned = false }
            }
    }

    /// Two fingers moving together turn the World beneath the frame, as a globe is turned in the hand.
    private func turn(_ moved: CGSize?) {
        guard let onTurn else { return }
        guard let moved else {
            isTurning = false
            if gestureStart == nil { hasTurned = false }
            onTurn(nil)
            return
        }
        isTurning = true
        hasTurned = true
        let scale = ShareCardMap.transform(fitting: content.focus, into: ShareCardMap.fitRect(in: size, insets: mapInsets)).a
        guard scale > 0 else { return }
        onTurn(CGSize(width: moved.width / scale, height: moved.height / scale))
    }

    /// The places just been to, for the new layout to mark on the map, each with its name and colour.
    private var newMarks: [NewPlaceMarks.Mark] {
        let new = Set(content.newPlaceIDs)
        return content.words.filter { new.contains($0.id) }.map { word in
            NewPlaceMarks.Mark(
                id: word.id, name: word.name,
                color: palette.wordColors(word, colouring: content.colouring).colors.first ?? palette.text)
        }
    }
}

/// The flags of the places the person has been, pinned on the map where each place is, like
/// stickers on a travel map: the highest levels first, as many as fit without covering one another.
/// They glide with the map as it's framed.
private struct FlagPins: View, Animatable {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    var ladder: VisitLadder
    /// Each place's flag, by its ID.
    var flags: [String: String]
    var focus: CGRect
    var insets: EdgeInsets

    var animatableData: CGRect.AnimatableData {
        get { focus.animatableData }
        set { focus.animatableData = newValue }
    }

    /// The most pins a card takes, so they decorate the map rather than cover it.
    private static let most = 14

    private struct Pin: Identifiable {
        var id: String
        var flag: String
        var point: CGPoint
        /// A slight turn, the same each time for the same place, as a sticker pressed on by hand.
        var turn: Double
    }

    var body: some View {
        GeometryReader { proxy in
            ForEach(pins(in: proxy.size)) { pin in
                let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
                FlagThumbnail(name: pin.flag, size: CGSize(width: 24, height: 16))
                    .frame(width: 24, height: 16)
                    .clipShape(shape)
                    .padding(1.5)
                    .background(.white, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .rotationEffect(.degrees(pin.turn))
                    .position(pin.point)
            }
        }
        .allowsHitTesting(false)
    }

    private func pins(in size: CGSize) -> [Pin] {
        let transform = ShareCardMap.transform(fitting: focus, into: ShareCardMap.fitRect(in: size, insets: insets))
        let bounds = CGRect(origin: .zero, size: size).insetBy(dx: 18, dy: 18)
        let visited = map.regions
            .compactMap { region -> (MapRegion, VisitLevel, String)? in
                guard let level = statuses[region.id], level.id != VisitLevel.never.id, let flag = flags[region.id]
                else { return nil }
                return (region, level, flag)
            }
            .sorted { ladder.rank(of: $0.1) > ladder.rank(of: $1.1) }
        var placed: [Pin] = []
        var taken: [CGRect] = []
        for (region, _, flag) in visited where placed.count < Self.most {
            let point = region.center.applying(transform)
            guard bounds.contains(point) else { continue }
            let footprint = CGRect(x: point.x - 15, y: point.y - 11, width: 30, height: 22)
            guard !taken.contains(where: { $0.intersects(footprint) }) else { continue }
            taken.append(footprint)
            let turn = Double(region.id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 15) - 7
            placed.append(Pin(id: region.id, flag: flag, point: point, turn: turn))
        }
        return placed
    }
}

/// The place's own flag washed across the card; or for a list without one, such as the World, a
/// patchwork of the flags of the places the person has been, turned a little, like a quilt.
private struct FlagBackdrop: View {
    var flag: String?
    var quilt: [String]

    var body: some View {
        // Clear, so the card keeps its own size, with the flag filling it and cut to it.
        Color.clear
            .overlay {
                if let flag {
                    Image(flag)
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 1.2)
                } else if !quilt.isEmpty {
                    VStack(spacing: 3) {
                        ForEach(0..<24, id: \.self) { row in
                            HStack(spacing: 3) {
                                ForEach(0..<12, id: \.self) { column in
                                    FlagThumbnail(name: quilt[(row * 12 + column + row * 5) % quilt.count], size: CGSize(width: 54, height: 36))
                                        .frame(width: 54, height: 36)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                            }
                        }
                    }
                    .rotationEffect(.degrees(-12))
                }
            }
            .clipped()
    }
}

/// A tartan of the card's colour: broad dark bands crossing, with fine light and dark lines between.
private struct PlaidPattern: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            let dark = color.mix(with: .black, by: 0.5)
            let unit: CGFloat = 56
            let reach = max(size.width, size.height) + unit
            for offset in stride(from: -unit, through: reach, by: unit) {
                for (start, width, shade) in [
                    (CGFloat(0), unit * 0.4, dark.opacity(0.18)),
                    (unit * 0.6, CGFloat(2), Color.white.opacity(0.16)),
                    (unit * 0.8, CGFloat(1), dark.opacity(0.28)),
                ] {
                    context.fill(Path(CGRect(x: offset + start, y: 0, width: width, height: size.height)), with: .color(shade))
                    context.fill(Path(CGRect(x: 0, y: offset + start, width: size.width, height: width)), with: .color(shade))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// A row of small holes, evenly along the middle of the space, as where a pass tears off.
private struct Perforation: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.height / 2
        let count = max(Int(rect.width / 5), 1)
        let step = rect.width / CGFloat(count)
        var path = Path()
        for index in 0..<count {
            let x = rect.minX + step * (CGFloat(index) + 0.5)
            path.addEllipse(in: CGRect(x: x - radius, y: rect.midY - radius, width: radius * 2, height: radius * 2))
        }
        return path
    }
}

private extension View {
    /// The words with a soft glow round them, so they read over a busy card; just the words where
    /// the card has none.
    @ViewBuilder func halo(_ color: Color?) -> some View {
        if let color {
            shadow(color: color, radius: 0.8).shadow(color: color, radius: 2.5)
        } else {
            self
        }
    }
}

/// A rainbow foil over the card, its colours sliding as the card tilts, with a bright band of shine
/// running across it, as on a rare trading card.
struct FoilSheen: View, Animatable {
    /// Where the shine has slid to, from -1 to 1.
    var shine: Double
    /// How strongly the foil shows, from 0 to 1.
    var strength: Double

    var animatableData: Double {
        get { shine }
        set { shine = newValue }
    }

    /// Full on a dark card; half on a light one, whose paper the foil would otherwise wash out.
    static func strength(on palette: ShareCardPalette) -> Double {
        palette.colorScheme == .dark ? 1 : 0.5
    }

    private static let colors: [Color] = [
        Color(red: 1, green: 0.62, blue: 0.82), Color(red: 1, green: 0.93, blue: 0.6),
        Color(red: 0.62, green: 1, blue: 0.8), Color(red: 0.6, green: 0.88, blue: 1),
        Color(red: 0.8, green: 0.68, blue: 1), Color(red: 1, green: 0.62, blue: 0.82),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: Self.colors,
                startPoint: UnitPoint(x: -0.6 + shine * 0.45, y: 0), endPoint: UnitPoint(x: 1.6 + shine * 0.45, y: 1))
                .blendMode(.overlay)
                .opacity(0.6 * strength)
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0), location: 0.32), .init(color: .white.opacity(0.6), location: 0.5),
                    .init(color: .white.opacity(0), location: 0.68),
                ],
                startPoint: UnitPoint(x: -0.5 + shine * 0.7, y: 0), endPoint: UnitPoint(x: 0.5 + shine * 0.7, y: 1))
                .blendMode(.softLight)
                .opacity(strength)
        }
        .allowsHitTesting(false)
    }
}

/// Stars behind the night card's map, scattered the same way every time, so the picture sent is the
/// one previewed, a few of them four-pointed sparkles. On screen they twinkle.
private struct NightSky: View {
    var twinkles: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !twinkles)) { timeline in
            let time = twinkles ? timeline.date.timeIntervalSinceReferenceDate : 0
            Canvas { context, size in
                var random = SeededRandom(state: 0x5EED_CAFE)
                for index in 0..<160 {
                    let point = CGPoint(x: random.next() * size.width, y: random.next() * size.height)
                    let radius = 0.3 + pow(random.next(), 4) * 1.3
                    let phase = random.next() * 2 * .pi
                    let speed = 0.6 + random.next()
                    let flicker = twinkles ? 0.7 + 0.3 * sin(time * speed + phase) : 1
                    let brightness = (0.3 + random.next() * 0.6) * flicker
                    if index.isMultiple(of: 27) {
                        context.fill(
                            Self.sparkle(at: point, radius: 4 + radius * 2), with: .color(.white.opacity(0.85 * flicker)))
                    } else {
                        context.fill(
                            Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(.white.opacity(brightness)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// A four-pointed star, its points long and its waist narrow.
    private static func sparkle(at center: CGPoint, radius: CGFloat) -> Path {
        let waist = radius * 0.16
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y - waist))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y + waist))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y + waist))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y - waist))
        path.closeSubpath()
        return path
    }
}

/// Numbers that look random but come out the same from the same start, for stars that stay put.
private struct SeededRandom {
    var state: UInt64

    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
}
