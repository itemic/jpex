import SwiftUI
import UIKit

/// Shares a picture of a list's map, made like a trading card, on a screen of its own, as a photo
/// editor is. As it opens, the list's map peels off the page like a sticker, flies to the middle and
/// turns over to show the card; as it closes, the card turns back into the map, which flies home and
/// sticks back down. The card stands in the middle as it will be sent: it tilts with the device and
/// catches the light, its map can be pinched and dragged to frame it, and it turns over to show each
/// new design, over a soft blur of its own colours. Its tools run along the foot, each bringing up
/// its own choices; Share is at the top.
struct ShareMapView: View {
    var country: Country
    var saveModel: SaveModel
    /// Whether the list shows places by their local names, such as 北海道, which the card's
    /// typographic layouts follow.
    var localLanguage: Bool
    /// The list's map, for the card to peel off; without it, the card's dealt in.
    var origin: ShareOrigin?
    /// Told once the map has started to peel off the page, for the list to put its own away.
    var onPresent: () -> Void = {}
    /// Closes the screen, once the card's back on the page.
    var onClose: (() -> Void)?
    /// Whether it opens on the places most newly been to, as from a toast's Share.
    var startsOnNew = false
    @Environment(\.dismiss) private var dismiss
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    /// The shape the person last chose for this list, since what suits one map, such as the wide
    /// World, doesn't suit another; until they choose, it's the shape that suits the map.
    @AppStorage private var chosenFormat: MapShareContent.Format?
    @AppStorage(MapShareContent.Layout.storageKey) private var layout = MapShareContent.Layout.map
    @AppStorage(MapShareContent.NamesStyle.storageKey) private var namesStyle = MapShareContent.NamesStyle.block
    @AppStorage(MapShareContent.Colouring.storageKey) private var colouring = MapShareContent.Colouring.levels
    @AppStorage(MapShareContent.Design.storageKey) private var design = MapShareContent.Design.paper
    @AppStorage(ShareTint.storageKey) private var tint = ShareTint.sky
    @AppStorage(ShareStripes.colorsKey) private var stripeColors = ShareStripes.encode(ShareStripes.defaultColors)
    @AppStorage(ShareStripes.angleKey) private var stripeAngle = ShareStripes.defaultAngle
    @AppStorage(ShareStripes.widthKey) private var stripeWidth = ShareStripes.defaultWidth
    @AppStorage(Self.showsKeyKey) private var showsKey = true
    @AppStorage(Self.showsFlagsKey) private var showsFlags = false
    @AppStorage(Self.showsFoilKey) private var showsFoil = false
    @AppStorage(Self.showsDateKey) private var showsDate = true
    /// The colour chosen for places coloured plainly, kept as a six-digit code; empty for the
    /// design's own.
    @AppStorage(Self.plainColourKey) private var plainColour = ""
    /// Which order the smart colours are dealt in, turned by Shuffle colours.
    @AppStorage(Self.smartSeedKey) private var smartSeed = 0
    /// What the card's made from, gathered once as the screen opens, so framing the map doesn't
    /// gather it all again at every step of a pinch.
    @State private var base: ShareBase?
    @State private var isMissingMap = false
    /// Each design as a small card, drawn once, for choosing between them.
    @State private var swatches: [MapShareContent.Design: Image] = [:]
    /// How the map's framed, starting on the whole of it each time.
    @State private var framing = MapFraming.whole
    /// Which way the World's turned beneath the frame, starting as the list shows it each time; nil
    /// for a map that doesn't turn, such as a country's.
    @State private var orientation: WorldOrientation?
    /// The World as two fingers turn it, drawn from lighter outlines until they lift.
    @State private var turningMap: TravelMap?
    @State private var tool = ShareTool.layout
    /// The arrangement of the names filling the count's figures, new each time the screen opens.
    @State private var fillSeed = Int.random(in: 1...Int(Int32.max))
    @State private var isEditingStripes = false
    @State private var tilt = CardTilt()
    /// How far the map's colours have swept in.
    @State private var reveal = 0.0
    /// How far the card has turned over, in degrees; half a turn shows its back.
    @State private var turn = 0.0
    /// The foil's shine drifting to and fro by itself where nothing tilts the card, as in Simulator.
    @State private var drift = -1.0
    /// How far the screen's own things, its backdrop and tools, have come up over the list.
    @State private var shown = 0.0
    /// The list's map on its way between the page and the card: how far it's flown, and how far its
    /// corner's peeled back.
    @State private var flight = 0.0
    @State private var peel = 0.0
    /// Whether the list's map is out as a sticker, rather than the card standing in its place.
    @State private var isStickerOut = true
    /// Whether the card's back is the list's map, as the card arrives from it and goes back to it,
    /// rather than the app's own back.
    @State private var backIsSticker = false
    @State private var isCardShown = false
    /// How far the card has been dealt onto the screen, where there's no map to peel it off.
    @State private var deal = 0.0
    /// Where the card stands on screen, for the map to land there.
    @State private var cardFrame: CGRect = .zero
    @State private var hasArrived = false
    /// Whether the card has arrived and turned over, so the screen's choices can be made.
    @State private var isSettled = false
    @State private var isLeaving = false
    /// Counts the map peeling off, landing and sticking back down, each for a tap felt.
    @State private var peels = 0
    @State private var landings = 0
    @State private var stickings = 0
    /// Counts each picture taken, for its flash and click.
    @State private var flashes = 0
    @State private var isFlashing = false
    @State private var canShareToStories = false
    /// The picture being sent, while the share sheet's up.
    @State private var sharedPicture: MapSharePicture?
    /// The room the screen shows, inside its safe area, such as beside iPhone Duo's side bar.
    @State private var page = CGSize(width: 320, height: 640)
    /// A small copy of the picture, for the screen's soft backdrop, drawn again whenever the card
    /// changes.
    @State private var thumbnail: Image?
    @State private var thumbnails = 0

    private static let showsKeyKey = "shareShowsKey"
    private static let showsFlagsKey = "shareShowsFlags"
    private static let showsFoilKey = "shareShowsFoil"
    private static let showsDateKey = "shareShowsDate"
    private static let plainColourKey = "sharePlainColour"
    private static let smartSeedKey = "shareSmartSeed"
    /// The colours offered for places coloured plainly, beside the design's own and any other.
    private static let plainSwatches: [(name: String, color: Color)] =
        [("White", .white), ("Black", Color(white: 0.08))]
            + ShareTint.allCases.filter { $0 != .charcoal }.map { ($0.name, $0.color) }
    /// How round the card's corners are, in its own points.
    fileprivate static let cardCornerRadius: CGFloat = 24
    /// The room the tools' choices take above the tool bar: a row of tiles, and a row of finer
    /// choices above it.
    private static let trayHeight: CGFloat = 134

    init(
        country: Country, saveModel: SaveModel, localLanguage: Bool, origin: ShareOrigin? = nil,
        onPresent: @escaping () -> Void = {}, onClose: (() -> Void)? = nil, startsOnNew: Bool = false
    ) {
        self.country = country
        self.saveModel = saveModel
        self.localLanguage = localLanguage
        self.origin = origin
        self.onPresent = onPresent
        self.onClose = onClose
        self.startsOnNew = startsOnNew
        _chosenFormat = AppStorage("\(MapShareContent.Format.storageKey).\(country.id)")
    }

    /// The colour chosen for places coloured plainly, or nil for the design's own.
    private var plainColor: Color? {
        plainColour.isEmpty ? nil : ShareStripes.color(code: plainColour)
    }

    private var stripes: ShareStripes {
        ShareStripes(colors: ShareStripes.decode(stripeColors), angle: stripeAngle, width: stripeWidth)
    }

    /// Whether the tools stand beside the card rather than beneath it, on a screen too short for both,
    /// as an iPhone on its side.
    private var isSideBySide: Bool {
        page.width > page.height * 1.2 && page.height < 560
    }

    /// Choices reshape the card on the layout's curve, or with Reduce Motion, settle at once.
    private var change: Animation {
        Motion.moving(Motion.layout, reduceMotion: reduceMotion)
    }

    var body: some View {
        let content = base.map(makeContent(from:))
        ZStack {
            backdrop(content)
                .opacity(shown)
            if let content {
                studio(content)
            } else if isMissingMap {
                VStack(spacing: 0) {
                    topBar(nil)
                    ContentUnavailableView("No map to share", systemImage: "map")
                }
                .opacity(shown)
            }
        }
        .overlay { sticker }
        // The list stays in view behind the screen as the map peels off it, but out of reach.
        .accessibilityAddTraits(.isModal)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { page = $0 }
        .onAppear(perform: appear)
        .onDisappear { tilt.stop() }
        .onChange(of: cardFrame) { arrive() }
        .task(id: content.map(thumbnailKey)) { await drawThumbnail() }
        .onChange(of: tint) {
            // The colourful designs' small cards take on the new colour.
            guard let base, !swatches.isEmpty else { return }
            for design in MapShareContent.Design.allCases where design.usesTint {
                swatches[design] = drawSwatch(of: design, from: base)
            }
        }
        .task(id: stripes) {
            // The striped design's small card takes on new stripes once a slider settles.
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled, let base, !swatches.isEmpty else { return }
            swatches[.stripes] = drawSwatch(of: .stripes, from: base)
        }
        .onChange(of: tool) {
            // The designs' small cards, drawn once they're first wanted.
            if tool == .design, swatches.isEmpty, let base { swatches = drawSwatches(from: base) }
        }
        .sheet(isPresented: $isEditingStripes) {
            StripesEditor(colors: $stripeColors, angle: $stripeAngle, width: $stripeWidth)
        }
        .sensoryFeedback(.selection, trigger: layout)
        .sensoryFeedback(.selection, trigger: namesStyle)
        .sensoryFeedback(.selection, trigger: design)
        .sensoryFeedback(.selection, trigger: tint)
        .sensoryFeedback(.selection, trigger: chosenFormat)
        .sensoryFeedback(.selection, trigger: framing == .whole ? 0 : framing == .travels ? 1 : framing == .new ? 2 : 3)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: peels)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: landings)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: stickings)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: flashes)
    }

    // MARK: Arriving and leaving

    private func appear() {
        guard base == nil, !isMissingMap else { return }
        canShareToStories = InstagramStories.isAvailable
        guard let gathered = gatherBase() else {
            isMissingMap = true
            isStickerOut = false
            withAnimation(.smooth(duration: 0.3)) { shown = 1 }
            return
        }
        base = gathered
        orientation = WorldOrientation(of: gathered.map)
        // The new places' card, where there are new places for it.
        if gathered.newPlaceIDs.isEmpty {
            if layout == .new { layout = .map }
        } else if startsOnNew || layout == .new {
            layout = .new
            framing = .new
        }
        // The card arrives once it knows where it stands: see `arrive()`.
    }

    /// The card's arrival, once the screen knows where it stands: peeled off the list's map where
    /// there's one to peel; otherwise dealt in as the screen fades up; with Reduce Motion, faded in.
    private func arrive() {
        guard !hasArrived, base != nil, cardFrame.width > 0 else { return }
        hasArrived = true
        guard origin != nil, !reduceMotion else {
            isStickerOut = false
            if reduceMotion {
                reveal = 1
                deal = 1
                withAnimation(.easeInOut(duration: 0.25)) {
                    shown = 1
                    isCardShown = true
                } completion: { settle() }
            } else {
                isCardShown = true
                withAnimation(.smooth(duration: 0.4)) { shown = 1 }
                withAnimation(.bouncy(duration: 0.8, extraBounce: 0.12)) { deal = 1 } completion: { settle() }
                startRevealing(after: 0.25)
            }
            return
        }
        // The map's corner lifts off the page...
        onPresent()
        peels += 1
        withAnimation(.easeIn(duration: 0.38)) { peel = 1 } completion: {
            guard !isLeaving else { return }
            // ...and the whole map comes away, smoothing out as it flies to the card's place, the
            // screen coming up round it.
            withAnimation(.smooth(duration: 0.75)) { flight = 1 } completion: { land() }
            withAnimation(.easeOut(duration: 0.5)) { peel = 0 }
            withAnimation(.easeInOut(duration: 0.7)) { shown = 1 }
        }
    }

    /// The map lands where the card stands, and the card, the map its back, turns over to show its
    /// face, its colours sweeping in.
    private func land() {
        guard !isLeaving else { return }
        var swap = Transaction()
        swap.disablesAnimations = true
        withTransaction(swap) {
            backIsSticker = true
            turn = 180
            deal = 1
            isCardShown = true
            isStickerOut = false
        }
        landings += 1
        withAnimation(.bouncy(duration: 0.7, extraBounce: 0.1)) { turn = 360 } completion: {
            backIsSticker = false
            settle()
        }
        startRevealing(after: 0.2)
    }

    /// The card has arrived: it starts leaning with the device, and the screen's choices can be made.
    private func settle() {
        guard !isLeaving else { return }
        isSettled = true
        guard !reduceMotion else { return }
        tilt.start()
        if !tilt.isAvailable {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { drift = 1 }
        }
    }

    private func startRevealing(after delay: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            withAnimation(.easeInOut(duration: 1.3)) { reveal = 1 }
        }
    }

    /// Closes the screen: the card turns back over to the list's map, which flies home and sticks
    /// back down on the page as the screen fades away round it. Without a map to go back to, or
    /// with Reduce Motion, the screen fades.
    private func leave() {
        guard !isLeaving else { return }
        isLeaving = true
        tilt.stop()
        guard origin != nil, !reduceMotion, hasArrived, !isStickerOut, cardFrame.width > 0 else {
            withAnimation(.easeInOut(duration: 0.25)) {
                shown = 0
                isCardShown = false
                if isStickerOut { flight = 0 }
            } completion: { close() }
            return
        }
        backIsSticker = true
        withAnimation(.easeIn(duration: 0.24)) { turn += 180 } completion: {
            var swap = Transaction()
            swap.disablesAnimations = true
            withTransaction(swap) {
                isStickerOut = true
                isCardShown = false
            }
            withAnimation(.smooth(duration: 0.55)) {
                flight = 0
                shown = 0
            } completion: {
                stickings += 1
                close()
            }
            // Its corner lifts as it's carried, and smooths down as it sticks.
            withAnimation(.easeOut(duration: 0.25)) { peel = 0.35 } completion: {
                withAnimation(.easeIn(duration: 0.28)) { peel = 0 }
            }
        }
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    /// The list's map, peeling off the page or stuck to it, on its way to or from the card.
    @ViewBuilder private var sticker: some View {
        if let origin, isStickerOut, !reduceMotion {
            GeometryReader { proxy in
                let global = proxy.frame(in: .global)
                let landing = cardFrame.width > 0 ? Self.fit(origin.image.size, in: cardFrame) : origin.frame
                PeelingSticker(
                    image: origin.image,
                    from: origin.frame.offsetBy(dx: -global.minX, dy: -global.minY),
                    to: landing.offsetBy(dx: -global.minX, dy: -global.minY),
                    flight: flight, peel: peel,
                    landedCornerRadius: Self.cardCornerRadius * cardScale)
            }
            .ignoresSafeArea()
        }
    }

    /// How much the card's drawn larger or smaller on screen than its own size.
    private var cardScale: CGFloat {
        guard let base, cardFrame.width > 0 else { return 1 }
        return cardFrame.width / makeContent(from: base).format.size.width
    }

    /// A size, as large as fits in a rectangle without changing its shape, centred in it.
    fileprivate static func fit(_ size: CGSize, in rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: rect.midX - fitted.width / 2, y: rect.midY - fitted.height / 2, width: fitted.width, height: fitted.height)
    }

    // MARK: Gathering

    private func gatherBase() -> ShareBase? {
        guard let map = TravelMap.named(country.id, projection: projection, center: center) else { return nil }
        let snapshot = saveModel.snapshot()
        let statuses = Dictionary(uniqueKeysWithValues: country.divisions.map { ($0.id, snapshot.status(for: $0)) })
        let newIDs = NewPlaces.ids(in: country, log: (try? saveModel.changeLog()) ?? [], snapshot: snapshot)
        return ShareBase(
            map: map, statuses: statuses,
            counted: snapshot.count(in: country.divisions, counting: counting.rules),
            iconName: AppIcon.current.previewImageName,
            wholeFocus: MapFraming.wholeFocus(of: map),
            travelsFocus: MapFraming.travelsFocus(of: map, statuses: statuses),
            newPlaceIDs: newIDs,
            newFocus: MapFraming.travelsFocus(of: map, statuses: statuses.filter { newIDs.contains($0.key) }))
    }

    private func makeContent(from base: ShareBase) -> MapShareContent {
        MapShareContent(
            country: country, map: turningMap ?? base.map, statuses: base.statuses, ladder: ladder, counted: base.counted,
            iconName: base.iconName, format: chosenFormat ?? .suggested(for: base.map), layout: layout,
            namesStyle: namesStyle, newPlaceIDs: base.newPlaceIDs, colouring: colouring, design: design, tint: tint, stripes: stripes,
            localLanguage: localLanguage, focus: framing.focus(whole: base.wholeFocus, travels: base.travelsFocus, new: base.newFocus),
            showsKey: showsKey, showsFlags: showsFlags, showsFoil: showsFoil,
            showsDate: showsDate, plainColor: plainColor, smartSeed: smartSeed, fillSeed: fillSeed)
    }

    /// Each design as a small square card of the whole map, plain, for choosing between them.
    private func drawSwatches(from base: ShareBase) -> [MapShareContent.Design: Image] {
        var swatches: [MapShareContent.Design: Image] = [:]
        for design in MapShareContent.Design.allCases {
            swatches[design] = drawSwatch(of: design, from: base)
        }
        return swatches
    }

    private func drawSwatch(of design: MapShareContent.Design, from base: ShareBase) -> Image? {
        let content = MapShareContent(
            country: country, map: base.map, statuses: base.statuses, ladder: ladder, counted: base.counted,
            iconName: base.iconName, format: .square, layout: .map, namesStyle: .block, newPlaceIDs: [], colouring: .levels,
            design: design, tint: tint, stripes: stripes, localLanguage: localLanguage, focus: base.wholeFocus,
            showsKey: false, showsFlags: false, showsFoil: false, showsDate: false, plainColor: nil, smartSeed: 0, fillSeed: 0)
        return MapSharePicture.image(of: content, scale: 0.8).map { Image(uiImage: $0) }
    }

    /// Changes whenever the picture would look different, to draw the small copy again.
    private func thumbnailKey(_ content: MapShareContent) -> String {
        let focus = content.focus.integral
        return [
            content.format.rawValue, content.layout.rawValue, content.namesStyle.rawValue, content.colouring.rawValue,
            content.design.rawValue, content.tint.rawValue,
            stripeColors, "\(stripeAngle)", "\(stripeWidth)", "\(content.localLanguage)", "\(content.showsKey)",
            "\(content.showsFlags)", "\(content.showsFoil)", "\(content.showsDate)",
            plainColour, "\(smartSeed)", "\(fillSeed)",
            "\(focus.minX)", "\(focus.minY)", "\(focus.width)",
            orientation.map { "\($0.longitude) \($0.tilt)" } ?? "",
        ].joined(separator: " ")
    }

    /// Draws the small copy once the card has settled for a moment, not at every step of a pinch,
    /// nor while it's arriving, so drawing doesn't catch its flight.
    private func drawThumbnail() async {
        try? await Task.sleep(for: .milliseconds(350))
        while !Task.isCancelled, !isSettled {
            try? await Task.sleep(for: .milliseconds(150))
        }
        guard !Task.isCancelled, let base else { return }
        thumbnail = MapSharePicture.image(of: makeContent(from: base), scale: 0.5).map { Image(uiImage: $0) }
        thumbnails += 1
        // The designs' small cards, once the card has settled, unless they've been wanted already.
        if swatches.isEmpty { swatches = drawSwatches(from: base) }
    }

    // MARK: The screen

    /// A soft blur of the card's own colours, washed towards the page, so the card stands out over
    /// its own light.
    private func backdrop(_ content: MapShareContent?) -> some View {
        ZStack {
            Color.pageBackground
            if let content {
                LinearGradient(
                    colors: [content.palette.storyTop, content.palette.storyBottom], startPoint: .top, endPoint: .bottom)
                    .opacity(0.35)
            }
            if let thumbnail {
                Color.clear
                    .overlay {
                        thumbnail
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 70, opaque: true)
                            .saturation(1.3)
                    }
                    .clipped()
                    .opacity(0.6)
                    .id(thumbnails)
                    .transition(.opacity)
            }
            Color.pageBackground.opacity(0.35)
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.9), value: thumbnails)
        .accessibilityHidden(true)
    }

    @ViewBuilder private func studio(_ content: MapShareContent) -> some View {
        if isSideBySide {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    topBar(content)
                    stage(content)
                }
                controls(content)
                    .frame(width: 380)
            }
        } else {
            VStack(spacing: 0) {
                topBar(content)
                stage(content)
                controls(content)
            }
        }
    }

    /// Close, and on the far side, Share, with a smaller Instagram beside it where it's installed.
    private func topBar(_ content: MapShareContent?) -> some View {
        HStack(spacing: 10) {
            // Escape closes it, as it does any sheet.
            Button("Close", systemImage: "xmark", action: leave)
                .keyboardShortcut(.cancelAction)
                .modifier(StudioRoundButton())
            Spacer(minLength: 0)
            if let content {
                if canShareToStories {
                    Button("Instagram") { shareToStory(content) }
                        .modifier(StudioCapsuleButton())
                        .accessibilityHint("Adds the card to an Instagram story.")
                }
                shareButton(content)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .opacity(shown)
        .allowsHitTesting(!isLeaving)
    }

    /// The card, as large as the room between the top and the tools allows.
    private func stage(_ content: MapShareContent) -> some View {
        GeometryReader { proxy in
            let size = content.format.size
            let scale = max(min((proxy.size.width - 40) / size.width, (proxy.size.height - 36) / size.height, 1.9), 0.1)
            card(content, scale: scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
                // Where the card stands, from the room around it, as the card's own leaning and
                // turning would move it.
                .onGeometryChange(for: CGRect.self) { geometry in
                    let room = geometry.frame(in: .global)
                    return CGRect(
                        x: room.midX - size.width * scale / 2, y: room.midY - size.height * scale / 2,
                        width: size.width * scale, height: size.height * scale)
                } action: { cardFrame = $0 }
        }
    }

    /// The card exactly as it will be sent, scaled to the room, held in the hand: it leans with the
    /// device and its gloss and foil catch the light.
    private func card(_ content: MapShareContent, scale: CGFloat) -> some View {
        let size = content.format.size
        let shape = RoundedRectangle(cornerRadius: Self.cardCornerRadius * scale, style: .continuous)
        return MapShareCard(
            content: content, reveal: reveal, drawsFoil: false, twinkles: !reduceMotion,
            onReframe: { framing = .custom($0) }, onTurn: orientation == nil ? nil : { turnWorld(by: $0) })
            .modifier(CardTurn(
                turn: turn,
                back: CardBackFace(size: size, iconName: content.iconName, sticker: backIsSticker ? origin?.image : nil)))
            .scaleEffect(scale)
            .frame(width: size.width * scale, height: size.height * scale)
            .modifier(HeldCard(
                tilt: tilt, drift: drift, showsSheen: !backIsSticker, showsFoil: content.showsFoil,
                foilStrength: FoilSheen.strength(on: content.palette), shape: shape))
            .overlay {
                // The camera's flash as the picture's taken.
                shape.fill(.white)
                    .opacity(isFlashing ? 0.85 : 0)
                    .allowsHitTesting(false)
            }
            .modifier(Dealt(progress: deal))
            .opacity(isCardShown ? 1 : 0)
            .allowsHitTesting(isSettled && !isLeaving)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Picture of your map")
            .accessibilityValue(content.summary)
            .accessibilityActions {
                if orientation != nil, content.layout.showsMap {
                    Button("Show further east") { turnWorld(east: 30) }
                    Button("Show further west") { turnWorld(east: -30) }
                }
            }
    }

    /// The tray of the chosen tool's choices, over the tool bar.
    private func controls(_ content: MapShareContent) -> some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                finerChoices(content)
                choices(content)
            }
            .frame(height: Self.trayHeight)
            .id(tool)
            .transition(.opacity)
            ShareToolBar(selection: $tool, shuffle: shuffle)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .opacity(shown)
        .offset(y: (1 - shown) * 60)
        .allowsHitTesting(isSettled && !isLeaving)
    }

    // MARK: Choices

    /// The chosen tool's main choices, as tiles.
    @ViewBuilder private func choices(_ content: MapShareContent) -> some View {
        switch tool {
        case .layout:
            TrayRow {
                ForEach(MapShareContent.Layout.allCases.filter { $0 != .new || base?.newPlaceIDs.isEmpty == false }) { option in
                    Button {
                        withAnimation(change) {
                            layout = option
                            // The new places' card shows them close up.
                            if option == .new { framing = .new }
                        }
                    } label: {
                        Label(option.name, systemImage: option.symbolName)
                            .labelStyle(StudioTileLabelStyle(isOn: option == layout))
                    }
                    .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
                    .accessibilityAddTraits(option == layout ? .isSelected : [])
                }
            }
        case .design:
            TrayRow(spacing: 12) {
                ForEach(MapShareContent.Design.allCases) { option in
                    Button { choose(option) } label: {
                        DesignTile(name: option.name, swatch: swatches[option], isOn: option == design)
                    }
                    .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
                }
            }
        case .colouring:
            TrayRow {
                ForEach(MapShareContent.Colouring.allCases) { option in
                    Button {
                        withAnimation(change) { colouring = option }
                    } label: {
                        Label(option.name, systemImage: option.symbolName)
                            .labelStyle(StudioTileLabelStyle(isOn: option == colouring))
                    }
                    .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
                    .accessibilityAddTraits(option == colouring ? .isSelected : [])
                }
            }
        case .shape:
            TrayRow {
                ForEach(MapShareContent.Format.allCases) { option in
                    Button {
                        withAnimation(change) { chosenFormat = option }
                    } label: {
                        Label {
                            Text(option.name)
                        } icon: {
                            // The shape itself, drawn to its proportions.
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .strokeBorder(.primary.opacity(option == content.format ? 0.8 : 0.4), lineWidth: 1.5)
                                .frame(width: option.size.width / 26, height: option.size.height / 26)
                        }
                        .labelStyle(StudioTileLabelStyle(isOn: option == content.format))
                    }
                    .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
                    .accessibilityAddTraits(option == content.format ? .isSelected : [])
                }
            }
        case .extras:
            TrayRow {
                Toggle("Foil", systemImage: "sparkles", isOn: $showsFoil.animation(change))
                // Flags are pinned where places are, so only on the map itself.
                if layout == .map {
                    Toggle("Flag pins", systemImage: "flag", isOn: $showsFlags.animation(change))
                }
                Toggle("Date", systemImage: "calendar", isOn: $showsDate.animation(change))
            }
            .toggleStyle(StudioTileToggleStyle())
        }
    }

    /// The chosen tool's finer choices, above its tiles, where its choice has any: the names' type,
    /// how the map's framed, the design's colour or stripes, and the levels' key.
    @ViewBuilder private func finerChoices(_ content: MapShareContent) -> some View {
        switch tool {
        case .layout:
            if layout == .names {
                TrayRow(spacing: 8) {
                    ForEach(MapShareContent.NamesStyle.allCases) { style in
                        Button {
                            withAnimation(change) { namesStyle = style }
                        } label: {
                            NamesStyleSpecimen(style: style)
                        }
                        .buttonStyle(StudioChipStyle(isOn: style == namesStyle))
                    }
                }
            } else if layout.showsMap {
                TrayRow(spacing: 8) {
                    if layout == .new {
                        Button("New places", systemImage: "sparkles") { reframe(.new) }
                            .buttonStyle(StudioChipStyle(isOn: framing == .new))
                            .disabled(base?.newFocus == nil)
                    }
                    Button("Whole map", systemImage: "map") { reframe(.whole) }
                        .buttonStyle(StudioChipStyle(isOn: framing == .whole))
                    Button("My travels", systemImage: "viewfinder") { reframe(.travels) }
                        .buttonStyle(StudioChipStyle(isOn: framing == .travels))
                        .disabled(base?.travelsFocus == nil)
                    Text(orientation == nil ? "or pinch the card" : "or pinch, or spin with two fingers")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
        case .design:
            if design.usesTint {
                TrayRow(spacing: 8) {
                    ForEach(ShareTint.allCases) { option in
                        Button {
                            withAnimation(change) { tint = option }
                        } label: {
                            Swatch(color: option.color, isOn: option == tint)
                        }
                        .buttonStyle(PillButtonStyle())
                        .accessibilityLabel(option.name)
                        .accessibilityAddTraits(option == tint ? .isSelected : [])
                    }
                }
            } else if design == .stripes {
                TrayRow(spacing: 8) {
                    ForEach(ShareStripes.presets(levels: ladder.levels.map(\.color))) { preset in
                        let isOn = stripeColors == ShareStripes.encode(preset.colors)
                        Button {
                            withAnimation(change) { stripeColors = ShareStripes.encode(preset.colors) }
                        } label: {
                            StripesPattern(stripes: ShareStripes(colors: preset.colors, angle: stripeAngle, width: 7))
                                .frame(width: 46, height: 30)
                                .clipShape(Capsule())
                                .overlay { Capsule().strokeBorder(.primary.opacity(0.12), lineWidth: 0.5) }
                                .padding(3)
                                .overlay {
                                    if isOn {
                                        Capsule().strokeBorder(.primary.opacity(0.6), lineWidth: 1.5)
                                    }
                                }
                        }
                        .buttonStyle(PillButtonStyle())
                        .accessibilityLabel(preset.name)
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                    Button("Edit", systemImage: "slider.horizontal.3") { isEditingStripes = true }
                        .buttonStyle(StudioChipStyle(isOn: false))
                        .accessibilityLabel("Edit stripes")
                }
            }
        case .colouring:
            switch colouring {
            case .levels:
                // The levels' pills are a key to the colours only while they're the levels'.
                Toggle("Levels key", systemImage: "list.bullet", isOn: $showsKey.animation(change))
                    .toggleStyle(StudioChipToggleStyle())
            case .plain:
                plainChoices
            case .smart:
                // The same colours, dealt out afresh.
                Button("Shuffle colours", systemImage: "dice") {
                    withAnimation(change) { smartSeed = Int.random(in: 1...Int(Int32.max)) }
                }
                .buttonStyle(StudioChipStyle(isOn: false))
            case .flags:
                EmptyView()
            }
        case .shape, .extras:
            EmptyView()
        }
    }

    /// The colours to set the places in plainly: the design's own, a few to pick from, or any other.
    private var plainChoices: some View {
        TrayRow(spacing: 8) {
            Button("Auto") {
                withAnimation(change) { plainColour = "" }
            }
            .buttonStyle(StudioChipStyle(isOn: plainColour.isEmpty))
            .accessibilityHint("Uses the design's own colour.")
            ForEach(Self.plainSwatches, id: \.name) { swatch in
                let code = ShareStripes.code(of: swatch.color)
                Button {
                    withAnimation(change) { plainColour = code }
                } label: {
                    Swatch(color: swatch.color, isOn: plainColour == code)
                }
                .buttonStyle(PillButtonStyle())
                .accessibilityLabel(swatch.name)
                .accessibilityAddTraits(plainColour == code ? .isSelected : [])
            }
            ColorPicker("Another colour", selection: chosenPlainColor, supportsOpacity: false)
                .labelsHidden()
                .padding(.leading, 4)
        }
    }

    /// The colour chosen for places coloured plainly, for picking any colour at all.
    private var chosenPlainColor: Binding<Color> {
        Binding {
            plainColor ?? .white
        } set: { color in
            plainColour = ShareStripes.code(of: color)
        }
    }

    /// The whole map, or just around the places the person has been, the map gliding there.
    private func reframe(_ new: MapFraming) {
        withAnimation(Motion.moving(.smooth(duration: 0.9), reduceMotion: reduceMotion)) { framing = new }
    }

    /// Turns the World beneath the card's frame as two fingers move across it, by a distance in the
    /// map's own units, from lighter outlines; once they lift, it's drawn in full detail, and the
    /// frames round the person's travels are found again on it.
    private func turnWorld(by distance: CGSize?) {
        guard let base, let orientation, let projection = base.map.projection else { return }
        guard let distance else {
            guard turningMap != nil, let rested = orientation.map(of: country.id, projection: projection, isMoving: false)
            else { return }
            self.base = base.showing(rested)
            turningMap = nil
            return
        }
        if turningMap == nil { holdFrame(on: base) }
        let turned = orientation.moved(by: distance, on: turningMap ?? base.map)
        guard let map = turned.map(of: country.id, projection: projection, isMoving: true) else { return }
        self.orientation = turned
        turningMap = map
    }

    /// Turns the World a step, bringing places further east or west into the middle, for VoiceOver,
    /// which doesn't spin with two fingers.
    private func turnWorld(east degrees: Double) {
        guard let base, var turned = orientation, let projection = base.map.projection else { return }
        turned.longitude = remainder(turned.longitude + degrees, 360)
        guard let map = turned.map(of: country.id, projection: projection, isMoving: false) else { return }
        holdFrame(on: base)
        orientation = turned
        self.base = base.showing(map)
    }

    /// Keeps the frame where it is as the World turns beneath it, rather than following the
    /// person's travels round.
    private func holdFrame(on base: ShareBase) {
        guard framing != .whole else { return }
        framing = .custom(framing.focus(whole: base.wholeFocus, travels: base.travelsFocus, new: base.newFocus))
    }

    /// Turns the card over to its back and round again in the new design, or with Reduce Motion,
    /// fades to it.
    private func choose(_ option: MapShareContent.Design) {
        guard option != design else { return }
        turnOver { design = option }
    }

    /// A design picked at random, another than the one showing, in a random colour and stripes,
    /// coloured by levels, flags, smartly or plainly, sometimes in foil: the card turns over to it.
    private func shuffle() {
        guard isSettled else { return }
        let nextDesign = MapShareContent.Design.allCases.filter { $0 != design }.randomElement() ?? design
        let nextTint = ShareTint.allCases.filter { $0 != tint }.randomElement() ?? tint
        let nextStripes = ShareStripes.random(levels: ladder.levels.map(\.color))
        let nextColouring = MapShareContent.Colouring.allCases.randomElement() ?? colouring
        let nextFoil = Int.random(in: 0..<4) == 0
        let nextSeed = Int.random(in: 1...Int(Int32.max))
        let nextFill = Int.random(in: 1...Int(Int32.max))
        turnOver {
            design = nextDesign
            tint = nextTint
            stripeColors = ShareStripes.encode(nextStripes.colors)
            stripeAngle = nextStripes.angle
            stripeWidth = nextStripes.width
            colouring = nextColouring
            showsFoil = nextFoil
            smartSeed = nextSeed
            fillSeed = nextFill
        }
    }

    /// Turns the card over to its back, makes the change while it faces away, and turns it round
    /// again, showing the change; with Reduce Motion, fades to it.
    private func turnOver(_ apply: @escaping () -> Void) {
        guard !reduceMotion else {
            withAnimation(.smooth(duration: 0.25)) { apply() }
            return
        }
        withAnimation(.easeIn(duration: 0.2)) {
            turn += 180
        } completion: {
            apply()
            withAnimation(.bouncy(duration: 0.7, extraBounce: 0.12)) { turn += 180 }
        }
    }

    // MARK: Sharing

    /// Share, in the card's own colour: the picture's taken, and the share sheet offers it to any app
    /// that takes photos.
    private func shareButton(_ content: MapShareContent) -> some View {
        Button {
            flash { sharedPicture = MapSharePicture(content: content) }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
        }
        .buttonStyle(CandyButtonStyle(color: content.palette.accent))
        .background { ShareSheetPresenter(picture: $sharedPicture) }
    }

    private func shareToStory(_ content: MapShareContent) {
        flash()
        guard let sticker = MapSharePicture.sticker(of: content) else { return }
        let palette = content.palette
        Task { _ = await InstagramStories.share(sticker: sticker, top: palette.storyTop, bottom: palette.storyBottom) }
    }

    /// A camera's flash over the card and a click, as the picture's taken: `taken` runs at the flash's
    /// height, so the flash goes off at once, however long the picture takes to draw.
    private func flash(taken: @escaping () -> Void = {}) {
        flashes += 1
        guard !reduceMotion else {
            taken()
            return
        }
        withAnimation(.linear(duration: 0.06)) {
            isFlashing = true
        } completion: {
            taken()
            withAnimation(.easeOut(duration: 0.5)) { isFlashing = false }
        }
    }
}

/// A colour to pick, as a round swatch with a fine edge, ringed while it's the one chosen.
private struct Swatch: View {
    var color: Color
    var isOn: Bool

    var body: some View {
        Circle()
            .fill(color.gradient)
            .overlay { Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 1) }
            .frame(width: 30, height: 30)
            .padding(4)
            .overlay {
                if isOn {
                    Circle().strokeBorder(.primary.opacity(0.6), lineWidth: 2)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: isOn)
    }
}

/// What the card's made from, gathered once as the share screen opens.
private struct ShareBase {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    var counted: Int
    var iconName: String
    var wholeFocus: CGRect
    /// The frame around the places been to, or nil where that's the whole map anyway.
    var travelsFocus: CGRect?
    /// The places most newly been to, and the frame around them, or nil where that's the whole map.
    var newPlaceIDs: [String]
    var newFocus: CGRect?

    /// The same on the World turned another way, its frames worked out afresh.
    func showing(_ turned: TravelMap) -> ShareBase {
        var base = self
        base.map = turned
        base.wholeFocus = MapFraming.wholeFocus(of: turned)
        base.travelsFocus = MapFraming.travelsFocus(of: turned, statuses: statuses)
        base.newFocus = MapFraming.travelsFocus(of: turned, statuses: statuses.filter { newPlaceIDs.contains($0.key) })
        return base
    }
}

/// A round glass button at the top of the share screen, its symbol alone.
private struct StudioRoundButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .labelStyle(.iconOnly)
                .font(.system(size: 17, weight: .semibold))
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        } else {
            content
                .labelStyle(.iconOnly)
                .font(.system(size: 17, weight: .semibold))
                .buttonStyle(RoundMaterialButtonStyle())
        }
    }
}

/// A small glass button at the top of the share screen with its name in words, such as Instagram,
/// giving way to Share beside it.
private struct StudioCapsuleButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.glass)
                .controlSize(.regular)
        } else {
            content
                .font(.subheadline.weight(.semibold))
                .buttonStyle(CapsuleMaterialButtonStyle())
        }
    }
}

/// A capsule button on a material, where Liquid Glass isn't available.
private struct CapsuleMaterialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(.regularMaterial, in: Capsule())
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.15), value: configuration.isPressed)
    }
}

/// A round button on a material, where Liquid Glass isn't available.
private struct RoundMaterialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(.regularMaterial, in: Circle())
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.15), value: configuration.isPressed)
    }
}

/// The card held in the hand: it leans as the device does, a gloss, and the foil when it's on,
/// catching the light as it moves, with a shadow that shifts beneath it.
private struct HeldCard<S: Shape>: ViewModifier {
    var tilt: CardTilt
    /// The shine's drift where nothing tilts the card.
    var drift: Double
    /// Whether the card's gloss and foil show, as they don't on the list's map as it turns into the card.
    var showsSheen: Bool
    var showsFoil: Bool
    var foilStrength: Double
    var shape: S

    func body(content: Content) -> some View {
        let shine = tilt.isAvailable ? max(-1, min(1, tilt.x - tilt.y)) : drift
        content
            .overlay {
                if showsSheen {
                    ZStack {
                        if showsFoil {
                            FoilSheen(shine: shine, strength: foilStrength)
                        }
                        Gloss(shine: shine)
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(shape)
            .rotation3DEffect(.degrees(tilt.x * 10), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(-tilt.y * 10), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .shadow(color: .black.opacity(0.24), radius: 22, x: -tilt.x * 12, y: 16 + tilt.y * 8)
    }
}

/// A soft band of light across the card, as on a laminated card, sliding as it tilts.
private struct Gloss: View, Animatable {
    var shine: Double

    var animatableData: Double {
        get { shine }
        set { shine = newValue }
    }

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0), location: 0.36), .init(color: .white.opacity(0.2), location: 0.5),
                .init(color: .white.opacity(0), location: 0.64),
            ],
            startPoint: UnitPoint(x: -0.3 + shine * 0.5, y: 0), endPoint: UnitPoint(x: 0.7 + shine * 0.5, y: 1))
            .blendMode(.screen)
    }
}

/// Turns a card about its upright axis, showing its back while it faces away, as a card turned over
/// in the hand.
private struct CardTurn<Back: View>: ViewModifier, Animatable {
    /// How far it's turned, in degrees.
    var turn: Double
    var back: Back

    var animatableData: Double {
        get { turn }
        set { turn = newValue }
    }

    func body(content: Content) -> some View {
        let facing = turn.truncatingRemainder(dividingBy: 360)
        let showsBack = (90..<270).contains(facing)
        ZStack {
            content
                .opacity(showsBack ? 0 : 1)
            back
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showsBack ? 1 : 0)
        }
        .rotation3DEffect(.degrees(turn), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }
}

/// The card's back: the list's map, as the card arrives from it and goes back to it, drawn just as
/// the map flying in is, so one takes the other's place unseen; and otherwise the app's own back.
private struct CardBackFace: View {
    var size: CGSize
    var iconName: String
    var sticker: UIImage?

    var body: some View {
        if let sticker {
            let fitted = ShareMapView.fit(sticker.size, in: CGRect(origin: .zero, size: size))
            Image(uiImage: sticker)
                .resizable()
                .frame(width: fitted.width, height: fitted.height)
                .clipShape(RoundedRectangle(cornerRadius: ShareMapView.cardCornerRadius, style: .continuous))
                .frame(width: size.width, height: size.height)
        } else {
            CardBack(size: size, iconName: iconName)
        }
    }
}

/// The back of the card, seen as it turns over: the app's sky-blue candy with the icon the person
/// has chosen and the app's name, the same whichever design is on the front.
private struct CardBack: View {
    var size: CGSize
    var iconName: String

    private static let sky = Color(red: 0.16, green: 0.62, blue: 0.9)

    var body: some View {
        let iconShape = RoundedRectangle(cornerRadius: 96 * 0.225, style: .continuous)
        ZStack {
            CandyGloss(color: Self.sky, pattern: nil)
            VStack(spacing: 14) {
                Image(iconName)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .clipShape(iconShape)
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
                Text(AppStoreLink.appName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(CandyGloss.lettering(on: Self.sky))
            }
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.55), lineWidth: 1)
                .padding(8)
        }
        .frame(width: size.width, height: size.height)
    }
}

/// A card dealt onto the table: it springs up from below, turning straight as it lands.
private struct Dealt: ViewModifier {
    var progress: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(0.8 + 0.2 * progress)
            .rotationEffect(.degrees(10 * (1 - progress)))
            .offset(y: 160 * (1 - progress))
            .opacity(progress)
    }
}
