import SwiftUI

/// World Time: the World as the face of a world-time watch, over every time kept around it. Seen
/// from above the North Pole, the World turns beneath the Sun once a day inside a ring of the day's
/// 24 hours, noon at the top and midnight at the foot, the person's own time riding round the ring
/// at their hour, the night side in shadow with the capitals' lights coming on along the dusk, and
/// the sky behind it the sky above the person's own city. Beneath it, as the quiz's answers sit
/// beneath its board, a card holds every time zone in use, each with its hours from UTC on a token,
/// its time, letters and name, wearing the sky over it, headed by the day it is for the person.
///
/// Turn the World with a finger to wind time on or back: every clock, the night and the sky follow,
/// each hour felt as it passes, and a flick carries on spinning until it settles on a quarter hour.
/// Now winds back to the present. Tap a country, as on the full map, for the time kept where the
/// finger is and how far it is from the person's: it lifts off the World with the countries keeping
/// the same time brought forward, its flag flies out to its hour on the ring, the list of zones
/// gives way to every place keeping that time, with a way back to the zones at the card's top, and
/// the sky becomes the sky over it. A country keeping several times lists every one on the card,
/// as chips, to move to any of them at a tap as a tap on that part of it does; tap the sea for the
/// time kept there. Pick a zone from the list to
/// bring forward every place keeping it, down to the provinces of a country spanning zones. A time known by several names, such as UTC+8, China
/// Standard Time in China and Taiwan Standard Time in Taiwan, leads with whichever the person picks
/// from its names, and keeps it between visits.
///
/// Time zone colours colour the World by the time each place keeps, as an atlas's map of the
/// world's time zones does, the sea wearing the time of its nearest land and the date line dashed
/// where it bends; the colours sweep round the dial from noon, or across the map. Pulled up, the
/// card of zones takes the screen, the dial tucked in small above it, with what the tz database
/// says of the time picked.
///
/// The flat map opens the dial out into a map running from edge to edge, the ring straightening into
/// a ribbon of hours along its top; the night and the ribbon slide across it, and a drag along it
/// winds time. Pinched, it zooms in, a drag then moving it about. Held like a book, iPhone Duo shows
/// both, a page each, like an atlas open at a spread; standing like a laptop, the dial or map keeps
/// to the upright side and the card to the near one.
///
/// It is the full map's Time zones layer, and opens out of the full map: the World there, settled
/// whole and facing north, curls up into the dial or the flat map and plays a day through to now,
/// and unrolls back into the full map as it closes. Its own Layers button offers the full map's
/// chooser, and picking another layer unrolls the World back into the full map showing it. With
/// Reduce Motion it fades in and out, and a flick stops where it's let go.
struct WorldTimeScreen: View {
    /// Every country's level, keyed by its place ID.
    var statuses: [String: VisitLevel]
    /// Where the map World Time opens out of is on screen, in global coordinates, for World Time to
    /// curl up out of and unroll back into. Nil when it isn't in view; World Time then grows and fades.
    var sourceFrame: CGRect?
    /// How the World lies on that map, from the World's own units to global coordinates, as the
    /// full map draws it, so the curl starts from exactly what was on screen. Nil for a list's map
    /// card, which fits the whole World into its rounded frame.
    var sourceMapTransform: CGAffineTransform? = nil
    /// The app's own appearance, which the map wears as it leaves the full map or the list and comes back.
    var appColorScheme: ColorScheme
    /// Another of the full map's layers, picked from World Time's own Layers button, told just
    /// before World Time closes back into the full map, which then shows it. Nil leaves the button out.
    var onChooseLayer: ((MapLayer) -> Void)? = nil
    var onClose: () -> Void

    /// Whether World Time shows its flat map rather than the dial, kept between visits.
    static let showsMapKey = "worldTimeShowsMap"
    /// How far the person has turned the dial's face, in degrees, kept between visits.
    static let dialTurnKey = "worldTimeDialTurn"
    /// How many times the person has been shown that their time slides, kept between visits.
    static let slideHintsKey = "worldTimeSlideHints"
    /// The zones whose names the person turned cards to, such as Asia/Taipei for Taiwan Standard
    /// Time, one to a line, kept between visits.
    static let zoneNamesKey = "worldTimeZoneNames"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.visitLadder) private var ladder
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @AppStorage(Self.showsMapKey) private var showsMap = false
    @AppStorage(Self.dialTurnKey) private var dialTurn = 0.0
    @AppStorage(Self.slideHintsKey) private var slideHints = 0
    /// When the thumb began nudging along the ring or ribbon, showing that it slides.
    @State private var slideHint: Date?
    @AppStorage(Self.zoneNamesKey) private var zoneNames = ""
    @State private var here = TimeZoneAtlas.here
    /// Whether the card of zones is pulled up to take the screen, and how far a finger is pulling it.
    @State private var isExpanded = false
    @State private var pull: CGFloat = 0
    /// The dial's face turning under a finger, from how it was and where the finger went down, and
    /// how far it has turned it; or turning back to upright by itself.
    @State private var turnStart: (turn: Double, angle: Double)?
    @State private var liveTurn: Double?
    @State private var faceTurn: FaceTurn?
    /// Laid over the map on a short, wide screen, whether the card of zones is tucked away to its side.
    @State private var isCardTucked = false
    /// The flat map's width across, for bringing it back round to how it starts.
    @State private var lastMapWidth: CGFloat = 1
    /// How far into the flat map the person has zoomed, and where; the view its land was last drawn
    /// for, crisply; the map zooming out by itself; and the view as a pinch or a drag began.
    @State private var mapView = MapView.whole
    @State private var drawnMapView = MapView.whole
    @State private var mapZoom: MapZoom?
    @State private var pinchStart: MapView?
    @State private var panStart: MapView?
    /// Whether the touch under way has pinched, so its lifting isn't taken for a tap.
    @State private var touchPinched = false
    /// Where on the flat map two fingers went down, for a pinch past the deepest to give back about.
    @State private var pinchAnchor: CGPoint = .zero
    /// How far a pinch has shrunk the flat map below its whole size, as the full map's does, to let
    /// go of World Time back into the full map; 1 at rest.
    @State private var mapShrink: CGFloat = 1
    /// The last tap on the flat map, when and where, so a second close by soon after zooms.
    @State private var lastFlatTap: (time: Date, location: CGPoint, before: Pick?)?
    /// Whether the subdivisions of the countries spanning zones are ready to split them along their zones.
    @State private var subdivisionsReady = false
    @State private var preparesSubdivisions = false
    /// When World Time began to open, and to close, and whether it curls up out of the full map's or the list's.
    @State private var opening: Date?
    @State private var closing: Date?
    @State private var curlsFromList = false
    /// Whether the bar's buttons show: from as the readout comes in until World Time closes.
    @State private var isBarShown = false
    /// Whether the full map's layer chooser stands over the card of zones.
    @State private var isChoosingLayer = false
    /// The layer picked from the chooser, for the full map to show once World Time has closed into it.
    @State private var chosenLayer: MapLayer?
    /// Whether the card is coming down and the flat map back to the whole World before World
    /// Time closes into the full map.
    @State private var isSettlingToClose = false
    /// The dial opening out into the flat map, or rolling back up, and when.
    @State private var reshaping: Reshaping?
    /// Whether iPhone Duo is held like a book, showing the dial and the flat map a page each.
    @State private var isSpread = false
    /// The time World Time rests on once wound away from now; nil while it keeps the present.
    @State private var pinned: Date?
    @State private var glide: TimeGlide?
    @State private var spin: DialSpin?
    /// The country tapped or the zone picked, and when.
    @State private var picked: Pick?
    /// What was picked, just let go or given way to something else, and when, so its flag flies
    /// back home and its arc and hours draw back in after it, rather than all going in a frame.
    @State private var released: Released?
    /// The sky moving from over one place to over another.
    @State private var skyShift: SkyShift?
    @State private var cache = WorldTimeCache()
    @State private var isAnimating = false
    @State private var animatingUntil = Date.distantPast
    /// Counts what's felt: each hour wound past, each midnight, each pick, each landing on a time
    /// or a shape.
    @State private var hourTicks = 0
    @State private var midnights = 0
    @State private var lastTick = Date.distantPast
    @State private var taps = 0
    @State private var landings = 0
    /// When time last landed, wound to a quarter hour or back to now, for a ring to go out round
    /// the thumb as the landing is felt.
    @State private var thumbLanding: Date?

    /// The SF Symbol for World Time, falling back to a plain clock before the globe with a clock.
    static var symbolName: String {
        if #available(iOS 26.0, *) { return "globe.badge.clock" }
        return "clock"
    }

    var body: some View {
        NavigationStack {
            // Measured within the bars, wherever they sit, so the time and the card keep clear of
            // them, then drawn edge to edge beneath them.
            GeometryReader { proxy in
                let insets = proxy.safeAreaInsets
                let size = CGSize(
                    width: proxy.size.width + insets.leading + insets.trailing,
                    height: proxy.size.height + insets.top + insets.bottom)
                let fold = FoldRegions(in: proxy)
                let layouts = Layouts(
                    dial: WorldTimeLayout(
                        size: size, insets: insets, fold: fold, showsMap: false, isExpanded: isExpanded, hasPick: picked != nil),
                    map: WorldTimeLayout(
                        size: size, insets: insets, fold: fold, showsMap: true, isExpanded: isExpanded, hasPick: picked != nil))
                let frame = proxy.frame(in: .global)
                let source = sourceRect(globalOrigin: CGPoint(x: frame.minX - insets.leading, y: frame.minY - insets.top), size: size)
                // Once a second at rest is plenty for the minutes and the Earth's own slow turn.
                TimelineView(.animation(minimumInterval: isMoving ? nil : 1)) { timeline in
                    scene(at: timeline.date, size: size, layouts: layouts, source: source)
                }
                .frame(width: size.width, height: size.height)
                .offset(x: -insets.leading, y: -insets.top)
                .onAppear { open(curling: source != nil) }
                .onChange(of: layouts.dial.showsBoth, initial: true) { _, both in isSpread = both }
                .onChange(of: layouts.map.flat?.width ?? 1, initial: true) { _, width in lastMapWidth = width }
            }
            // Escape on a keyboard, by an unseen button so it steps back a thing at a time.
            .background {
                Button("Step back", action: escape)
                    .keyboardShortcut(.cancelAction)
                    .opacity(0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .containerBackground(.clear, for: .navigation)
            .toolbar { toolbar }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.selection, trigger: hourTicks)
        // Winding into a new day is felt more firmly than any other hour, like a bezel's detent at 12.
        .sensoryFeedback(.impact(weight: .light, intensity: 0.8), trigger: midnights)
        .sensoryFeedback(.selection, trigger: taps)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.55), trigger: landings)
        // Felt as a pinch goes far enough to let go back to the full map.
        .sensoryFeedback(.impact(weight: .medium), trigger: isLetGoArmed) { old, new in new && !old }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, escape)
    }

    /// Escape, from a keyboard or VoiceOver's scrub, steps back one thing at a time: the layer
    /// chooser first, then what's picked, then World Time itself, back to the map or the list.
    private func escape() {
        // Already on its way out, the chooser leaves with the rest of World Time.
        guard closing == nil, !isSettlingToClose else { return }
        if isChoosingLayer {
            withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isChoosingLayer = false }
        } else if picked != nil {
            pick(nil)
        } else {
            close()
        }
    }

    // MARK: The scene

    @ViewBuilder
    private func scene(at date: Date, size: CGSize, layouts: Layouts, source: CGRect?) -> some View {
        let shown = shownDate(at: date)
        let sun = DayNight.Sun(at: shown)
        let stage = stage(at: date)
        let layout = showsMap ? layouts.map : layouts.dial
        let reshape = reshapeStage(at: date)
        let rotation = Self.rotation(for: sun, centerLongitude: center.longitude)
        // Curling up out of the full map or the list's, or unrolling back into it, into whichever shows: the
        // dial, held like a book, as the flat map fades in beside it.
        let curls = curlsFromList && source != nil && (stage.curl < 1 || closing != nil)
        let curlsIntoDial = layout.dial != nil
        let bands = cache.bands(at: shown, here: here, statuses: statuses, ladder: ladder, names: zoneNames)
        let choice = choice(at: shown, bands: bands)
        // Just let go or given way to another, still drawing back in.
        let leaving = released.flatMap { date.timeIntervalSince($0.start) < Released.length ? $0 : nil }
        // Just landed on a time, how far the ring round the thumb has spread.
        let thumbRing = thumbLanding.flatMap { landed -> Double? in
            let spread = max(date.timeIntervalSince(landed), 0) / DialSelection.landingRing
            return spread < 1 ? spread : nil
        }
        let zones = cache.zones(at: shown)
        let hereTime = ClockWords.time(shown, in: here.timeZone)
        let faceTurned = turn(at: date)
        // Wound away from now, how far, for the ring and the ribbon to make plain: still while it
        // winds back, the arc shrinking into the thumb until it lands.
        let wound: Double? = showsLive ? nil : shown.timeIntervalSince(date) / 3600
        let nudge = thumbNudge(at: date)
        let liveMapView = mapView(at: date)
        // Read so the scene draws again as the sea's zones arrive from away from the main thread.
        let _ = cache.seaVersion
        // While the dial opens into the flat map or rolls back, both are drawn for their rings to cross.
        let dialRect = layout.dial ?? (reshape != nil ? layouts.dial.dial : nil)
        let flatRect = layout.flat ?? (reshape != nil ? layouts.map.flat : nil)
        // Which of them is tucked in small, the card pulled up over its place.
        let dialTucked = layout.miniature != nil && layout.miniatureSource == dialRect
        let flatTucked = layout.miniature != nil && layout.miniatureSource == flatRect
        ZStack(alignment: .topLeading) {
            // Hides the map World Time leaves from and lands back on, so there's only ever the one
            // World: a list's map card, or the full map, under the page it lies on.
            if let source {
                RoundedRectangle(cornerRadius: sourceMapTransform == nil ? 18 : 0, style: .continuous)
                    .fill(sourceMapTransform == nil ? Color(uiColor: .systemGray6) : Color.pageBackground)
                    .environment(\.colorScheme, appColorScheme)
                    .frame(width: source.width, height: source.height)
                    .offset(x: source.minX, y: source.minY)
            }
            WorldTimeSky(elevation: skyElevation(at: date, sun: sun, bands: bands))
                .opacity(stage.sky)
            if let dialRect, let map = dialMap {
                let dialPresence = presence(ofMap: false, reshape: reshape)
                let place = layout.placement(of: dialRect)
                dial(
                    map: map, geometry: DialGeometry(size: dialRect.width, turn: faceTurned), rotation: rotation, sun: sun, shown: shown,
                    now: date, stage: stage, presence: dialPresence,
                    showsEarth: !(curls && curlsIntoDial) && reshape == nil, choice: choice, leaving: leaving, zones: zones,
                    hereTime: hereTime, wound: wound, nudge: nudge, thumbRing: thumbRing, isTucked: dialTucked)
                    .scaleEffect(stage.dialScale)
                    .scaleEffect(place.scale, anchor: .topLeading)
                    .opacity(stage.dialOpacity)
                    .offset(x: place.origin.x, y: place.origin.y)
                // Turned, the full map's compass, by the dial's corner, turning with the face; a tap
                // turns it back to noon at the top, its needle riding round with the face. Kept off
                // while the dial opens out into the flat map or rolls back up.
                if abs(remainder(faceTurned, 360)) > 0.5, !dialTucked, reshape == nil, closing == nil {
                    MapCompass(rotation: .degrees(faceTurned), action: recentreDial)
                        .accessibilityLabel("Recentre")
                        // It pops in as the face is turned, and fades as it comes upright; with
                        // Reduce Motion, it only fades.
                        .transition(.arrive(reduceMotion: reduceMotion))
                        .offset(x: dialRect.maxX - 44, y: dialRect.minY)
                }
            }
            if let flatRect, let map = flatWorld {
                let mapPresence = presence(ofMap: true, reshape: reshape)
                let place = layout.placement(of: flatRect)
                let geometry = FlatGeometry(size: flatRect.size, cornerRadius: layouts.flatCornerRadius(showing: layout))
                flat(
                    map: map, geometry: geometry, sun: sun, shown: shown, now: date, stage: stage,
                    presence: mapPresence, showsEarth: !(curls && !curlsIntoDial) && reshape == nil, choice: choice,
                    leaving: leaving, zones: zones, hereTime: hereTime, wound: wound, nudge: nudge, thumbRing: thumbRing,
                    view: liveMapView, isTucked: flatTucked)
                    .scaleEffect(stage.dialScale * mapShrink)
                    .scaleEffect(place.scale, anchor: .topLeading)
                    .opacity(stage.dialOpacity * (curls && curlsIntoDial ? stage.readout : 1))
                    .offset(x: place.origin.x, y: place.origin.y)
                // Pinched smaller than the whole World, what letting go does: back to the full map.
                // Let go there, it fades with the card as World Time closes.
                if mapShrink < 0.999, onChooseLayer != nil {
                    LetGoHint(title: "World", systemImage: "chevron.backward", progress: Double((1 - mapShrink) / (1 - Self.letGoShrink)))
                        .frame(width: flatRect.width, height: flatRect.height)
                        .offset(x: flatRect.minX, y: flatRect.minY)
                        .opacity(stage.readout)
                }

            }
            // Tucked beside the time, the dial or map lets the card back down at a tap.
            if let miniature = layout.miniature {
                Button(flatTucked ? "Show map" : "Show dial") { expand(false) }
                    .buttonStyle(MiniatureButtonStyle())
                    .frame(width: miniature.width, height: miniature.height)
                    .offset(x: miniature.minX, y: miniature.minY)
                    // The handle along the card's top does the same for VoiceOver.
                    .accessibilityHidden(true)
            }
            if let world = Geography.world {
                if curls, let source, let target = curlsIntoDial ? layout.dial : layout.flat {
                    let into = curlsIntoDial
                        ? dialPlacement(in: target, rotation: rotation + faceTurned)
                        : flatPlacement(in: target, cornerRadius: layouts.flatCornerRadius(showing: layout))
                    // Pinched away, the flat map unrolls from the size the fingers left it.
                    let end = !curlsIntoDial && mapShrink < 1
                        ? into.placement.scaled(by: mapShrink, about: CGPoint(x: target.midX, y: target.midY))
                        : into.placement
                    CurlingWorld(
                        map: cache.reshaped(world, from: projection, to: into.projection, progress: stage.curl, center: center),
                        statuses: statuses, zoneOffsets: cache.zoneOffsets(at: shown), progress: stage.curl,
                        from: listPlacement(for: source), to: end, appColorScheme: appColorScheme)
                }
                if let reshape, let dialRect = layouts.dial.dial, let flatRect = layouts.map.flat {
                    let dial = dialPlacement(in: dialRect, rotation: rotation + faceTurned)
                    let map = flatPlacement(in: flatRect, cornerRadius: layouts.map.flatCornerRadius)
                    let start = reshape.toMap ? dial : map
                    let end = reshape.toMap ? map : dial
                    CurlingWorld(
                        map: cache.reshaped(world, from: start.projection, to: end.projection, progress: reshape.shape, center: center),
                        statuses: statuses, zoneOffsets: cache.zoneOffsets(at: shown), progress: reshape.shape,
                        from: start.placement, to: end.placement, appColorScheme: appColorScheme)
                }
            }
            // Pulled, the card's top follows the finger a little way, giving as it goes.
            let lift = Self.giving(pull)
            // Tucked away over the map, the card slides off to the side; with Reduce Motion, it
            // fades where it is.
            let cardTucked = layout.cardFloats && isCardTucked
            let tuckFades = cardTucked && reduceMotion
            WorldTimeCard(
                status: caption(shown: shown, now: date), isLive: showsLive, onNow: returnToNow,
                heading: choice?.heading, bands: bands, date: shown, here: here, statuses: statuses,
                lit: choice?.litOffsets ?? [], focus: choice?.focusOffset,
                grabberRoom: layout.canExpand ? 12 : 0, isCompact: layout.card.height < 330 && !isExpanded,
                onChoose: choose, onTurn: turn,
                sharing: choice.flatMap { choice in bands.first { $0.offset == choice.focusOffset } },
                pickedPlaceID: pickedPlaceID, onPickPlace: pickPlace, onPickTime: pickTime, onLetGo: { pick(nil) })
                .overlay(alignment: .top) {
                    if layout.canExpand { grabber }
                }
                .frame(width: layout.card.width, height: max(layout.card.height - lift, 120))
                // Rising a little as it comes in and sinking as it goes; with Reduce Motion, only fading.
                .offset(
                    x: layout.card.minX + (cardTucked && !reduceMotion ? layout.card.width + 40 : 0),
                    y: layout.card.minY + lift + 24 * (reduceMotion ? 0 : 1 - stage.readout))
                .opacity(tuckFades ? 0 : stage.readout)
                // The layer chooser stands in its place while it's open.
                .opacity(isChoosingLayer ? 0 : 1)
                .allowsHitTesting(!isChoosingLayer && !tuckFades)
                .accessibilityHidden(isChoosingLayer || tuckFades)
            // Once a layer's picked, or World Time is closed with the chooser open, the chooser
            // stays and fades with the rest, rather than handing back to the card on its way out.
            if isChoosingLayer {
                layerChooser(over: layout.card)
                    .opacity(stage.readout)
                    .allowsHitTesting(closing == nil && !isSettlingToClose)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.blurReplace))
            }
            // Laid over the map, the card tucks away to the side and comes back.
            if layout.cardFloats, closing == nil {
                Button(isCardTucked ? "Show time zones" : "Hide time zones", systemImage: isCardTucked ? "chevron.left" : "chevron.right") {
                    withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isCardTucked.toggle() }
                    taps += 1
                }
                .labelStyle(.iconOnly)
                .contentTransition(.symbolEffect(.replace))
                .font(.subheadline.weight(.semibold))
                .frame(width: 30, height: 56)
                .glassPanel(in: Capsule(), interactive: true)
                .contentShape(Capsule())
                .buttonStyle(PillButtonStyle())
                .offset(
                    x: isCardTucked ? layout.card.maxX - 30 : layout.card.minX - 36,
                    y: layout.card.midY - 28)
                // With Reduce Motion the tab is simply at the card's other side as the card fades,
                // rather than travelling across.
                .transaction(value: isCardTucked) { transaction in
                    if reduceMotion { transaction.animation = nil }
                }
                .opacity(stage.readout)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .onChange(of: hourIndex(of: shown)) { old, new in tick(from: old, to: new) }
    }

    /// The dial, with the gestures that turn it and pick countries on it. `leaving` is a pick just
    /// let go or given way to another, its flag still flying home; `thumbRing`, how far the ring
    /// round the thumb has spread as time lands.
    private func dial(
        map: TravelMap, geometry: DialGeometry, rotation: Double, sun: DayNight.Sun, shown: Date, now: Date,
        stage: Stage, presence: Presence, showsEarth: Bool, choice: Choice?, leaving: Released?, zones: ZoneMoment,
        hereTime: ClockWords.Time, wound: Double?, nudge: Double, thumbRing: Double?, isTucked: Bool
    ) -> some View {
        let subdivisions = subdivisions(in: .polar)
        return WorldTimeDial(
            map: map, centerLongitude: center.longitude, statuses: statuses, focus: choice?.focus,
            byZone: true, zones: zones, subdivisions: subdivisions,
            seaTint: seaTint(in: .polar, map: map, subdivisions: subdivisions, zones: zones, focus: choice?.focus.offset),
            zoneBorders: zoneBorders(in: .polar, subdivisions: subdivisions, zones: zones, focus: choice?.focus.offset),
            geometry: geometry, rotation: rotation, sun: sun, hereHours: here.hours(at: shown), hereTime: hereTime,
            wound: wound, thumbNudge: nudge, thumbRing: thumbRing, dateLineDays: DateLineDays(at: shown),
            selection: choice?.marker(on: map, at: shown, here: here), outgoing: leaving?.marker(on: map, at: shown, here: here),
            now: now, night: stage.night * presence.night, ring: stage.ring * presence.ring, markers: stage.markers * presence.markers,
            showsEarth: showsEarth)
            .contentShape(Circle())
            .gesture(dialGesture(geometry: geometry), isEnabled: closing == nil && stage.curl >= 1 && reshaping == nil && !isTucked)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("World Time")
            .accessibilityValue("\(ClockWords.time(shown, in: here.timeZone).spoken), \(caption(shown: shown, now: now))")
            .accessibilityHint("Swipe up or down to wind time on or back an hour.")
            .accessibilityAdjustableAction { direction in
                wind(by: direction == .increment ? 3600 : -3600)
            }
            .accessibilityAction(named: "Recentre", recentreDial)
    }

    /// The flat map, with the gestures that slide time along it and pick countries on it. `leaving`
    /// is a pick just let go or given way to another, its flag still flying home; `thumbRing`, how
    /// far the ring round the thumb has spread as time lands.
    private func flat(
        map: TravelMap, geometry: FlatGeometry, sun: DayNight.Sun, shown: Date, now: Date, stage: Stage,
        presence: Presence, showsEarth: Bool, choice: Choice?, leaving: Released?, zones: ZoneMoment, hereTime: ClockWords.Time,
        wound: Double?, nudge: Double, thumbRing: Double?, view: MapView, isTucked: Bool
    ) -> some View {
        let subdivisions = subdivisions(in: .miller)
        return WorldTimeMap(
            map: map, centerLongitude: center.longitude, statuses: statuses, focus: choice?.focus,
            byZone: true, zones: zones, subdivisions: subdivisions,
            seaTint: seaTint(in: .miller, map: map, subdivisions: subdivisions, zones: zones, focus: choice?.focus.offset),
            zoneBorders: zoneBorders(in: .miller, subdivisions: subdivisions, zones: zones, focus: choice?.focus.offset),
            geometry: geometry, view: view, drawnView: drawnMapView,
            sun: sun, hereHours: here.hours(at: shown), hereTime: hereTime, wound: wound, thumbNudge: nudge,
            thumbRing: thumbRing, dateLineDays: DateLineDays(at: shown),
            selection: choice?.marker(on: map, at: shown, here: here), outgoing: leaving?.marker(on: map, at: shown, here: here),
            now: now,
            ribbon: stage.ring * presence.ring, markers: stage.markers * presence.markers, showsEarth: showsEarth)
            .contentShape(Rectangle())
            .gesture(flatGesture(geometry: geometry), isEnabled: closing == nil && stage.curl >= 1 && reshaping == nil && !isTucked)
            .simultaneousGesture(pinch(geometry: geometry), isEnabled: closing == nil && stage.curl >= 1 && reshaping == nil && !isTucked)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("World Time map")
            .accessibilityZoomAction { action in
                let middle = CGPoint(x: geometry.mapRect.width / 2, y: geometry.mapRect.height / 2)
                let factor: CGFloat = action.direction == .zoomIn ? 1.6 : 1 / 1.6
                mapView = mapView.zoomed(by: factor, about: middle, in: geometry.mapRect.size)
                drawnMapView = mapView
            }
            .accessibilityValue("\(ClockWords.time(shown, in: here.timeZone).spoken), \(caption(shown: shown, now: now))")
            .accessibilityHint("Swipe up or down to wind time on or back an hour.")
            .accessibilityAdjustableAction { direction in
                wind(by: direction == .increment ? 3600 : -3600)
            }
    }

    /// The day and the person's city while World Time keeps the present, "Thursday in Taipei", or
    /// how far it has been wound, "Friday, in 9 hours".
    private func caption(shown: Date, now: Date) -> String {
        guard !showsLive else {
            let day = ClockWords.weekday(of: shown, in: here.timeZone)
            return here.city.map { "\(day) in \($0)" } ?? day
        }
        return ClockWords.wound(to: shown, from: now, in: here.timeZone)
    }

    /// The bar keeps its room from the first frame to the last, so nothing beneath it shifts as
    /// World Time opens or closes; only its buttons fade in as the readout does, and out as World
    /// Time closes.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // Shown as a layer of the full map, the way back is to the map, as within it; opened
        // from a list's map card, World Time is closed. Escape steps back a thing at a time.
        ToolbarItem(placement: .cancellationAction) {
            Group {
                if onChooseLayer != nil {
                    Button("World", systemImage: "chevron.backward", action: close)
                        .keyboardShortcut("[", modifiers: .command)
                        .accessibilityHint("Back to the map")
                } else {
                    Button("Close", systemImage: "xmark", action: close)
                }
            }
            .opacity(isBarShown ? 1 : 0)
        }
        // Zoomed in or slid round, the flat map comes back to the whole World, as the full map's
        // Show all brings it back.
        if showsMap || isSpread {
            ToolbarItem(placement: .primaryAction) {
                Button("Show all", systemImage: "arrow.down.right.and.arrow.up.left") { recentreMap(width: lastMapWidth) }
                    .disabled(!mapView.isMoved || mapZoom != nil || closing != nil)
                    .opacity(isBarShown ? 1 : 0)
            }
        }
        // Held like a book, the dial and the map both show, so there's nothing to switch.
        if !isSpread {
            ToolbarItem(placement: .primaryAction) {
                Toggle("Flat map", systemImage: "map", isOn: Binding(get: { showsMap }, set: reshape(toMap:)))
                    .toggleStyle(.button)
                    .opacity(isBarShown ? 1 : 0)
            }
        }
        // The full map's own Layers button, the time zones being one of its layers: another goes
        // back to the full map, showing it. Like the map's, it wears the symbol of the layer
        // showing, so it reads as the same button wherever the time zones were curled open from.
        if onChooseLayer != nil {
            ToolbarItem(placement: .primaryAction) {
                Toggle(isOn: Binding(
                    get: { isChoosingLayer },
                    set: { isOn in
                        taps += 1
                        withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isChoosingLayer = isOn }
                    })) {
                    Label("Layers", systemImage: MapLayer.timeZones.symbolName)
                        .contentTransition(.symbolEffect(.replace))
                }
                .toggleStyle(.button)
                .keyboardShortcut("l", modifiers: .command)
                .accessibilityLabel("Layers")
                .accessibilityValue(MapLayer.timeZones.name)
                .disabled(isSettlingToClose)
                .opacity(isBarShown ? 1 : 0)
            }
        }
    }

    /// The full map's layer chooser, on glass where the card of zones stands, rising over the dial
    /// or map above it as far as its cards need, the time zones lit as the layer showing.
    private func layerChooser(over card: CGRect) -> some View {
        // Up over the dial or map as far as its cards need, but clear of the bars along the top.
        let room = max(card.height, min(card.maxY - 110, card.height + 260))
        return MapLayerChooser(
            current: .timeZones, isSeparate: false, maxGridHeight: max(160, room - 70),
            onChoose: chooseLayer
        ) {
            withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isChoosingLayer = false }
        }
        .glassPanel(in: .rect(cornerRadius: 28))
        .frame(width: card.width, height: room, alignment: .bottom)
        .offset(x: card.minX, y: card.maxY - room)
    }

    /// A layer picked from the chooser: the time zones are already showing, so the chooser gives
    /// way to the card again; any other closes World Time back into the full map, which shows it,
    /// the chooser staying over the card as both fade.
    private func chooseLayer(_ layer: MapLayer) {
        guard layer != .timeZones else {
            withAnimation(MapMotion.panel(reduceMotion: reduceMotion)) { isChoosingLayer = false }
            return
        }
        chosenLayer = layer
        close()
    }

    /// The handle along the top of the card of zones, to pull it up over the screen or let it back
    /// down, by a drag or a tap.
    private var grabber: some View {
        Button(isExpanded ? "Show dial" : "Show more time zones") { expand(!isExpanded) }
            .buttonStyle(GrabberButtonStyle())
            .accessibilityLabel(isExpanded ? (showsMap || isSpread ? "Show map" : "Show dial") : "Show more time zones")
            .simultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in pull = value.translation.height }
                    .onEnded { value in
                        let travel = value.predictedEndTranslation.height
                        if travel < -60, !isExpanded {
                            expand(true)
                        } else if travel > 60, isExpanded {
                            expand(false)
                        }
                        withAnimation(Motion.moving(.bouncy(duration: 0.4), reduceMotion: reduceMotion)) { pull = 0 }
                    })
            .accessibilityHint(isExpanded ? "Lets the list of time zones back down." : "Pulls the list of time zones up over the screen.")
    }

    /// A pull on the card, giving more the farther it goes.
    private static func giving(_ pull: CGFloat) -> CGFloat {
        let reach: CGFloat = 90
        return reach * pull / (abs(pull) + reach)
    }

    // MARK: Zones

    /// Leads a zone's card with another of its names from now on, such as Taiwan Standard Time for
    /// UTC+8, in place of whichever was chosen for it before. Picked, the new name's flag flies out
    /// to the ring; the zone's colours and sky stay as they are, being the same time.
    private func turn(_ band: TimeZoneBand, to name: ZoneName) {
        var chosen = Set(zoneNames.split(separator: "\n").map(String.init))
        chosen.subtract(band.names.flatMap(\.identifiers))
        if let identifier = name.identifiers.first { chosen.insert(identifier) }
        let now = Date.now
        withAnimation(.swap(reduceMotion: reduceMotion)) { zoneNames = chosen.sorted().joined(separator: "\n") }
        guard picked?.target == .zone(band.offset) else { return }
        let made = Pick(target: .zone(band.offset), start: now)
        picked = made
        animate(for: 1.3)
        feelLanding(of: made)
    }

    /// The sea tinted with its time zones for a map, once it's been worked out.
    private func seaTint(
        in projection: MapProjection, map: TravelMap, subdivisions: [TravelMap], zones: ZoneMoment, focus: Int?
    ) -> SeaTint? {
        cache.seaTint(in: projection, center: center, map: map, subdivisions: subdivisions, zones: zones, focus: focus)
    }

    /// The borders on land between places keeping different times for a map, once its lands have
    /// been worked out with the sea's zones.
    private func zoneBorders(in projection: MapProjection, subdivisions: [TravelMap], zones: ZoneMoment, focus: Int?) -> ZoneBorders? {
        cache.zoneBorders(in: projection, center: center, subdivisions: subdivisions.count, zones: zones, focus: focus)
    }

    /// The subdivisions of the countries spanning zones, in a projection, once they're ready.
    private func subdivisions(in projection: MapProjection) -> [TravelMap] {
        guard subdivisionsReady else { return [] }
        return TimeZoneAtlas.dividedCountries.compactMap { Geography.subdivisions(of: $0)?.map(projection, center: center) }
    }

    /// Reads and projects the subdivisions of the countries spanning zones after a while, a country
    /// a frame, so the World can be split along its zones without a pause.
    private func prepareSubdivisions(after delay: TimeInterval) {
        guard !subdivisionsReady, !preparesSubdivisions else { return }
        preparesSubdivisions = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            for country in TimeZoneAtlas.dividedCountries {
                guard let geography = Geography.subdivisions(of: country) else { continue }
                _ = geography.map(.polar, center: center)
                try? await Task.sleep(for: .milliseconds(16))
                _ = geography.map(.miller, center: center)
                try? await Task.sleep(for: .milliseconds(16))
            }
            subdivisionsReady = true
        }
    }

    /// Pulls the card of zones up over the screen, the dial or map tucking in beside the time, or
    /// lets it back down.
    private func expand(_ isOn: Bool) {
        guard isOn != isExpanded else { return }
        taps += 1
        withAnimation(.worldTimeReflow(reduceMotion: reduceMotion)) {
            isExpanded = isOn
            pull = 0
        }
    }

    // MARK: Time

    /// Whether World Time keeps the present, rather than resting on a time wound to or on its way there.
    private var isLive: Bool {
        spin == nil && pinned == nil && (glide == nil || glide?.to == .now)
    }

    /// Whether World Time shows itself as keeping the present: live, and not still winding back
    /// to it, so the amber arc, the Now pin, the amber thumb, the card's amber line and its Now
    /// pill stay until the World lands on now, and all turn back together as it does.
    private var showsLive: Bool {
        isLive && glide?.isReturn != true
    }

    private var isMoving: Bool {
        isAnimating || spin != nil || glide != nil
    }

    /// The time World Time shows at a moment.
    private func shownDate(at date: Date) -> Date {
        if let spin { return spin.shown }
        if let glide { return glide.shown(at: date) }
        return pinned ?? date
    }

    /// How far the Earth turns from the polar map's own way up, in degrees clockwise, to put the
    /// meridian beneath the Sun at the top. A day's turn is one whole turn anticlockwise.
    static func rotation(for sun: DayNight.Sun, centerLongitude: Double) -> Double {
        sun.longitude - centerLongitude - 180
    }

    /// The same turn, the short way round.
    private static func shortest(_ degrees: Double) -> Double {
        remainder(degrees, 360)
    }

    /// The hour on the person's own clock, counted from 1970, so passing one can be felt.
    private func hourIndex(of date: Date) -> Int {
        Int(((date.timeIntervalSince1970 + Double(here.offset(at: date))) / 3600).rounded(.down))
    }

    /// A tap for each hour wound past, no faster than a fingertip can tell them apart, and a firmer
    /// one at midnight, as the moon on the ring passes the thumb, whichever way it's wound and
    /// however fast. `old` and `new` are the hours on the person's own clock, from `hourIndex(of:)`.
    private func tick(from old: Int, to new: Int) {
        guard spin != nil || glide != nil else { return }
        let now = Date.now
        if old / 24 != new / 24 {
            lastTick = now
            midnights += 1
            return
        }
        guard now.timeIntervalSince(lastTick) > 0.045 else { return }
        lastTick = now
        hourTicks += 1
    }

    private func start(_ glide: TimeGlide) {
        self.glide = glide
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(max(glide.end.timeIntervalSinceNow, 0)))
            guard self.glide == glide else { return }
            self.glide = nil
            switch glide.to {
            case .now: pinned = nil
            case .moment(let moment): pinned = moment
            }
            landings += 1
            // Landed, a ring goes out round the thumb as the landing is felt, as round a flag
            // landing on its hour; with Reduce Motion, time is simply there.
            if !reduceMotion {
                thumbLanding = .now
                animate(for: DialSelection.landingRing + 0.05)
            }
        }
    }

    /// Back to the present, winding through the hours between at a pace that suits how far away it is.
    private func returnToNow() {
        let now = Date.now
        let shown = shownDate(at: now)
        spin = nil
        guard !reduceMotion else {
            glide = nil
            pinned = nil
            return
        }
        let hours = abs(shown.timeIntervalSince(now)) / 3600
        start(TimeGlide(from: shown, to: .now, start: now, length: min(0.45 + hours * 0.04, 1.6), isReturn: true))
    }

    /// Winds an hour on or back, as VoiceOver's swipes do, to the nearest quarter hour.
    private func wind(by seconds: TimeInterval) {
        let now = Date.now
        let target = TimeGlide.nearestQuarterHour(to: shownDate(at: now).addingTimeInterval(seconds), in: here.timeZone)
        guard abs(target.timeIntervalSince(now)) > 450 else {
            returnToNow()
            return
        }
        start(TimeGlide(from: shownDate(at: now), to: .moment(target), start: now, length: reduceMotion ? 0 : 0.45))
    }

    /// One touch on the dial, so a turn is never taken for a tap. Along the ring of hours, it winds
    /// time, the World turning beneath the Sun with the finger and carrying on after a flick; on the
    /// Earth, it turns the whole face, the World and its hours together, so any part of the World
    /// can sit at the top, and the time stays as it is. Lifted where it went down, it's a tap.
    private func dialGesture(geometry: DialGeometry) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let moved = hypot(value.translation.width, value.translation.height) >= 6
                guard spin != nil || turnStart != nil || moved else { return }
                let center = geometry.center
                let startAngle = atan2(value.startLocation.y - center.y, value.startLocation.x - center.x)
                let angle = atan2(value.location.y - center.y, value.location.x - center.x)
                let startReach = hypot(value.startLocation.x - center.x, value.startLocation.y - center.y)
                if turnStart != nil || (spin == nil && startReach < geometry.discRadius) {
                    let start = turnStart ?? (turn: turn(at: .now), angle: startAngle)
                    turnStart = start
                    faceTurn = nil
                    let turned = start.turn + (angle - start.angle) * 180 / .pi
                    // A light tick for each hour of the ring turned past, like a bezel's detents.
                    if Int((turned / 15).rounded(.down)) != Int(((liveTurn ?? start.turn) / 15).rounded(.down)) { hourTicks += 1 }
                    liveTurn = turned
                    return
                }
                let reach = hypot(value.location.x - center.x, value.location.y - center.y) / geometry.radius
                take(from: startAngle)
                spin?.turn(to: angle, at: .now, reach: reach)
            }
            .onEnded { value in
                if turnStart != nil {
                    turnStart = nil
                    dialTurn = remainder(liveTurn ?? dialTurn, 360)
                    liveTurn = nil
                    landings += 1
                    return
                }
                guard spin != nil else {
                    tapDial(at: value.location, geometry: geometry)
                    return
                }
                letGo()
            }
    }

    /// How far the dial's face is turned at a moment: under a finger, turning back by itself, or as
    /// the person left it.
    private func turn(at date: Date) -> Double {
        if let liveTurn { return liveTurn }
        guard let faceTurn else { return dialTurn }
        let t = min(max(date.timeIntervalSince(faceTurn.start) / FaceTurn.length, 0), 1)
        let eased = 1 - pow(1 - t, 3)
        return faceTurn.from + (faceTurn.to - faceTurn.from) * eased
    }

    /// Turns the dial's face back to noon at the top, the short way round.
    private func recentreDial() {
        let now = Date.now
        let from = remainder(turn(at: now), 360)
        taps += 1
        guard !reduceMotion else {
            dialTurn = 0
            return
        }
        faceTurn = FaceTurn(from: from, to: 0, start: now)
        dialTurn = 0
        animate(for: FaceTurn.length + 0.05)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(FaceTurn.length))
            if faceTurn?.start == now {
                faceTurn = nil
                landings += 1
            }
        }
    }

    /// One touch on the flat map. Along the ribbon of hours, it winds time, the night and the hours
    /// sliding with the finger, the Sun running west as time goes on, so a drag to the left winds
    /// on; on the map, it slides the World round, carrying on round the back of it, and zoomed in,
    /// moves it up and down too, the time staying as it is. Lifted where it went down, it's a tap.
    private func flatGesture(geometry: FlatGeometry) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard pinchStart == nil, !touchPinched else { return }
                guard spin != nil || panStart != nil || hypot(value.translation.width, value.translation.height) >= 6 else { return }
                let onRibbon = value.startLocation.y < geometry.mapRect.minY
                if panStart != nil || (spin == nil && !onRibbon) {
                    let start = panStart ?? mapView
                    panStart = start
                    mapZoom = nil
                    let moved = start.moved(by: value.translation, in: geometry.mapRect.size)
                    // A light tick for each hour's width of the World slid past.
                    let hour = geometry.mapRect.width * moved.zoom / 24
                    if Int((moved.pan.width / hour).rounded(.down)) != Int((mapView.pan.width / hour).rounded(.down)) { hourTicks += 1 }
                    mapView = moved
                    return
                }
                // A day's slide is the ribbon's day across, the map's width times its zoom, turned to
                // the angle a dial would have turned, so the hours keep up with the finger.
                let day = max(geometry.size.width * mapView.zoom, 1)
                take(from: Double(value.startLocation.x / day) * 2 * .pi)
                spin?.turn(to: Double(value.location.x / day) * 2 * .pi, at: .now, reach: 1)
            }
            .onEnded { value in
                if touchPinched {
                    touchPinched = false
                    return
                }
                if panStart != nil {
                    panStart = nil
                    drawnMapView = mapView
                    return
                }
                guard pinchStart == nil else { return }
                guard spin != nil else {
                    tapFlat(at: value.location, geometry: geometry)
                    return
                }
                letGo()
            }
    }

    /// How small a pinch must shrink the flat map, against its whole size, to let go back to the full map.
    private static let letGoShrink: CGFloat = 0.86

    /// Whether letting go of the pinch under way goes back to the full map.
    private var isLetGoArmed: Bool {
        onChooseLayer != nil && mapShrink < Self.letGoShrink
    }

    /// Two fingers on the flat map zoom it in or out about where they went down, the land redrawn
    /// crisply as they lift. Past the deepest or below the whole World, it gives like a rubber
    /// band, as the full map does, and springs back as they lift; shown as a layer of the full map,
    /// pinched small enough, it lets go of World Time back into the full map. A turn of time the
    /// first finger had begun goes back as they do.
    private func pinch(geometry: FlatGeometry) -> some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.02)
            .onChanged { value in
                if pinchStart == nil {
                    pinchStart = mapView
                    touchPinched = true
                    mapZoom = nil
                    if let spin {
                        pinned = spin.wasLive ? nil : spin.base
                        self.spin = nil
                    }
                    panStart = nil
                }
                guard let pinchStart else { return }
                let anchor = CGPoint(x: value.startLocation.x - geometry.mapRect.minX, y: value.startLocation.y - geometry.mapRect.minY)
                pinchAnchor = anchor
                let zoom = min(
                    max(MapNavigator.resisted(zoom: pinchStart.zoom * value.magnification, within: 1...MapView.deepest), 0.8), 7.2)
                mapView = pinchStart.zoomed(by: max(zoom, 1) / pinchStart.zoom, about: anchor, in: geometry.mapRect.size, upTo: 7.2)
                mapShrink = min(zoom, 1)
            }
            .onEnded { _ in
                pinchStart = nil
                if isLetGoArmed {
                    // Let go, the map stays the size the fingers left it, and World Time closes from
                    // there, rather than the map springing back up first. Pinched out from the whole
                    // World, it's the whole World still, so it unrolls at once; slid round, it comes
                    // back round first.
                    let width = geometry.mapRect.width
                    if !mapView.isZoomed, abs(MapView.wrap(mapView.pan.width, from: -width / 2, lap: width)) < 0.5 {
                        mapView = .whole
                        drawnMapView = .whole
                    }
                    close()
                } else {
                    withAnimation(reduceMotion ? MapMotion.fade : .bouncy(duration: 0.4)) { mapShrink = 1 }
                    if mapView.zoom > MapView.deepest {
                        // Past the deepest, it gives back to it about where the fingers were.
                        let settled = mapView.zoomed(by: MapView.deepest / mapView.zoom, about: pinchAnchor, in: geometry.mapRect.size)
                        var to = settled
                        to.pan.width = pinchAnchor.x - (pinchAnchor.x - mapView.pan.width) * MapView.deepest / mapView.zoom
                        glideMap(from: mapView, to: to, settled: settled)
                    } else {
                        if !mapView.isZoomed { mapView = .whole }
                        drawnMapView = mapView
                    }
                }
                landings += 1
                // In case the touch's own end never comes, as when both fingers lift at once.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    touchPinched = false
                }
            }
    }

    /// The flat map as it shows at a moment: as zoomed, or partway out to the whole World.
    private func mapView(at date: Date) -> MapView {
        guard let mapZoom else { return mapView }
        let t = min(max(date.timeIntervalSince(mapZoom.start) / MapZoom.length, 0), 1)
        return MapView.mix(mapZoom.from, mapZoom.to, by: 1 - pow(1 - t, 3))
    }

    /// Zooms the flat map in three times about a point of the stage, or zoomed in already, back out
    /// to the whole World.
    private func zoomMap(about location: CGPoint, geometry: FlatGeometry) {
        taps += 1
        guard mapView.zoom <= 1.5 else {
            recentreMap(width: geometry.mapRect.width)
            return
        }
        let anchor = CGPoint(x: location.x - geometry.mapRect.minX, y: location.y - geometry.mapRect.minY)
        let settled = mapView.zoomed(by: 3, about: anchor, in: geometry.mapRect.size)
        // Glided to without being brought round the World, so it zooms straight in.
        var to = settled
        to.pan.width = anchor.x - (anchor.x - mapView.pan.width) * settled.zoom / mapView.zoom
        glideMap(from: mapView, to: to, settled: settled)
    }

    /// Glides the flat map from one view to another, settling on `settled`, the same view brought
    /// round to where the map keeps it, its land redrawn crisply there.
    private func glideMap(from: MapView, to: MapView, settled: MapView) {
        mapView = settled
        guard !reduceMotion else {
            mapZoom = nil
            drawnMapView = settled
            return
        }
        let now = Date.now
        mapZoom = MapZoom(from: from, to: to, start: now)
        animate(for: MapZoom.length + 0.05)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(MapZoom.length))
            guard mapZoom?.start == now else { return }
            mapZoom = nil
            drawnMapView = settled
        }
    }

    /// Brings the flat map back to the whole World as it starts, smoothly and the short way round,
    /// `width` being the map's width across.
    private func recentreMap(width: CGFloat) {
        guard mapView.isMoved, mapZoom == nil else { return }
        let now = Date.now
        taps += 1
        guard !reduceMotion else {
            mapView = .whole
            drawnMapView = .whole
            return
        }
        // Round the back of the World, the start lies a lap along too; whichever is nearer.
        var from = mapView
        from.pan.width = MapView.wrap(from.pan.width, from: -width * from.zoom / 2, lap: width * from.zoom)
        var to = MapView.whole
        if from.pan.width < -width * from.zoom / 2 { to.pan.width = -width }
        mapZoom = MapZoom(from: from, to: to, start: now)
        mapView = .whole
        animate(for: MapZoom.length + 0.05)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(MapZoom.length))
            guard mapZoom?.start == now else { return }
            mapZoom = nil
            drawnMapView = .whole
        }
    }

    /// A finger taking hold of time from wherever it is now. The gesture's own times count from
    /// when the device started, so the clock's are used.
    private func take(from angle: Double) {
        guard spin == nil else { return }
        var taken = DialSpin(base: shownDate(at: .now), angle: angle)
        taken.wasLive = isLive
        spin = taken
        glide = nil
    }

    /// The finger lifting: a flick carries on and settles on a quarter hour, and wound back to
    /// within a few minutes of now, it picks up the present again.
    private func letGo() {
        guard let spin else { return }
        self.spin = nil
        // A touch that barely turned anything, such as a tap that slipped, changes nothing.
        guard abs(spin.turned) >= 1 else {
            pinned = spin.wasLive ? nil : spin.base
            return
        }
        let speed = reduceMotion ? 0 : spin.hoursPerSecond(at: .now)
        var landing = TimeGlide.coast(from: spin.shown, hoursPerSecond: speed, in: here.timeZone)
        if case .moment(let moment) = landing.to, abs(moment.timeIntervalSinceNow) < 450 {
            landing.to = .now
            landing.isReturn = true
        }
        if reduceMotion { landing.length = 0 }
        start(landing)
    }

    // MARK: Picking

    /// Every country by its place ID.
    private static let places: [String: AdministrativeDivision] = Dictionary(
        CountryCatalog.world.divisions.map { ($0.id, $0) }) { first, _ in first }

    /// The countries a tap can land on: all but Antarctica, which neither the dial nor the map shows.
    private static let tappable: Set<String> = Set(places.keys).subtracting([DialPalette.antarcticaID])

    private var dialMap: TravelMap? {
        Geography.world?.map(.polar, center: center)
    }

    private var flatWorld: TravelMap? {
        Geography.world?.map(.miller, center: center)
    }

    /// A tap on the Earth picks the place there, or out at sea the time kept there; a tap on the
    /// ring lets what's picked go.
    private func tapDial(at location: CGPoint, geometry: DialGeometry) {
        guard closing == nil, let map = dialMap else { return }
        let center = geometry.center
        guard hypot(location.x - center.x, location.y - center.y) <= geometry.discRadius else {
            if picked != nil { pick(nil) }
            return
        }
        let rotation = Self.rotation(for: DayNight.Sun(at: shownDate(at: .now)), centerLongitude: self.center.longitude)
        let point = geometry.mapPoint(location, rotation: rotation)
        let region = country(on: map, under: point, near: location, scale: geometry.scale) {
            geometry.screenPoint($0, rotation: rotation)
        }
        tapZone(at: point, country: region?.id, in: .polar)
    }

    /// A tap on the flat map picks the place there, or out at sea the time kept there; a tap on the
    /// ribbon lets what's picked go. Tapped twice, as on the full map, it zooms in three times about
    /// the finger, or zoomed in already, back out to the whole World, keeping what's picked.
    private func tapFlat(at location: CGPoint, geometry: FlatGeometry) {
        guard closing == nil, let map = flatWorld else { return }
        guard geometry.mapRect.contains(location) else {
            lastFlatTap = nil
            if picked != nil { pick(nil) }
            return
        }
        let now = Date.now
        if let last = lastFlatTap, now.timeIntervalSince(last.time) < 0.3,
           hypot(location.x - last.location.x, location.y - last.location.y) < 30 {
            lastFlatTap = nil
            // The first tap let go of what was picked: it's picked again, as it was, its flag back
            // on its hour rather than also flying home.
            if picked == nil, let before = last.before {
                withAnimation(.worldTimeReflow(reduceMotion: reduceMotion)) { picked = before }
                released = nil
                skyShift = nil
            }
            zoomMap(about: location, geometry: geometry)
            return
        }
        lastFlatTap = (now, location, picked)
        let point = geometry.mapPoint(location, view: mapView)
        let region = country(on: map, under: point, near: location, scale: geometry.scale * mapView.zoom) {
            geometry.stagePoint($0, view: mapView)
        }
        tapZone(at: point, country: region?.id, in: .miller)
    }

    /// A tap at a point of the dial's or the map's World, as on the full map: on land, the place
    /// under the finger, its flag flying out to its hour, the time kept where the finger is lit,
    /// and every place keeping that time listed, those on it wholly, then in part. Tapped again, it's
    /// let go; for a country spanning zones, a tap on a part keeping another time moves to that
    /// time instead. Out at sea, the time the sea keeps there, as its card in the list picks it;
    /// tapped again, let go.
    private func tapZone(at point: CGPoint, country id: String?, in projection: MapProjection) {
        let shown = shownDate(at: .now)
        if let id {
            let clock = zoneClock(of: id, at: point, in: projection)
            let tapped = clock.map { Pick.Tapped(placeID: id, identifier: $0.timeZone.identifier) }
            if pickedPlaceID == id,
               clock == nil || choice(at: shown, bands: [])?.focusOffset == clock?.offset(at: shown) {
                pick(nil)
            } else {
                pick(.place(id), tapped: tapped)
            }
            return
        }
        guard let offset = cache.seaOffset(
            at: point, in: projection, center: center, subdivisions: subdivisions(in: projection).count, date: shown)
        else { return }
        pick(picked?.target == .zone(offset) ? nil : .zone(offset))
    }

    /// The clock kept at a point of a country on a map: its own, or for a country spanning zones,
    /// that of the part of it under the point. Tapped before those parts are ready, that country's
    /// alone are read there and then, so a tap on Darwin is never taken for Sydney's time; a point
    /// just off every part, along a coast drawn a little differently, takes the nearest.
    private func zoneClock(of placeID: String, at point: CGPoint, in projection: MapProjection) -> ZoneClock? {
        guard let place = Self.places[placeID], let main = TimeZoneAtlas.clocks(of: place).first else { return nil }
        guard TimeZoneAtlas.dividedCountries.contains(place.abbreviation),
              let parts = Geography.subdivisions(of: place.abbreviation)?.map(projection, center: center),
              !parts.regions.isEmpty
        else { return main }
        let part = parts.regions.first { $0.path.contains(point, eoFill: true) }
            ?? parts.regions.min { hypot($0.center.x - point.x, $0.center.y - point.y) < hypot($1.center.x - point.x, $1.center.y - point.y) }
        return part.flatMap { TimeZoneAtlas.clock(ofSubdivision: $0.id) } ?? main
    }

    /// The clock a pick lights: for a place, the one kept where it was tapped, or its own.
    private static func clock(of place: AdministrativeDivision, tapped: Pick.Tapped?) -> ZoneClock? {
        let clocks = TimeZoneAtlas.clocks(of: place)
        guard let tapped, tapped.placeID == place.id else { return clocks.first }
        return clocks.first { $0.timeZone.identifier == tapped.identifier }
            ?? TimeZone(identifier: tapped.identifier).map { zone in
                ZoneClock(timeZone: zone, city: TimeZoneAtlas.cityName(of: tapped.identifier))
            }
            ?? clocks.first
    }

    /// The country under a point, or one too small to see close by, which gets a generous touch.
    private func country(
        on map: TravelMap, under point: CGPoint, near location: CGPoint, scale: CGFloat, onScreen: (CGPoint) -> CGPoint
    ) -> MapRegion? {
        map.hitTest(point, among: Self.tappable) ?? map.regions
            .filter { Self.tappable.contains($0.id) }
            .map { region in
                let spot = onScreen(region.center)
                return (region, hypot(spot.x - location.x, spot.y - location.y))
            }
            .filter { candidate, distance in
                distance < 20 && max(candidate.bounds.width, candidate.bounds.height) * scale < 14
            }
            .min { $0.1 < $1.1 }?.0
    }

    /// The place picked on its own, rather than a whole zone.
    private var pickedPlaceID: String? {
        guard case .place(let id)? = picked?.target else { return nil }
        return id
    }

    /// A place picked from those keeping the time picked, as a tap on it on the map picks it, the
    /// time staying lit: for a country spanning zones, its part keeping that time, so the list
    /// stays where it is. Let go when picked again.
    private func pickPlace(_ id: String) {
        guard Self.tappable.contains(id), let place = Self.places[id] else { return }
        guard pickedPlaceID != id else {
            pick(nil)
            return
        }
        let shown = shownDate(at: .now)
        let offset = choice(at: shown, bands: cache.bands(at: shown, here: here, statuses: statuses, ladder: ladder, names: zoneNames))?
            .focusOffset
        let clock = offset.flatMap { TimeZoneAtlas.clock(of: place, atOffset: $0, date: shown) }
        pick(.place(id), tapped: clock.map { Pick.Tapped(placeID: id, identifier: $0.timeZone.identifier) })
    }

    /// One of the times the place picked keeps, tapped among the card's chips by the clock it's
    /// best known by: the card, the dial and the map lead with it, as a tap on the part of the
    /// place keeping it on the map does, its flag flying out to that hour and the places keeping
    /// it filling the list. The time already led with, tapped again, lets the place go, as a
    /// second tap there does.
    private func pickTime(_ clock: ZoneClock) {
        guard let id = pickedPlaceID else { return }
        let shown = shownDate(at: .now)
        if choice(at: shown, bands: [])?.focusOffset == clock.offset(at: shown) {
            pick(nil)
        } else {
            pick(.place(id), tapped: Pick.Tapped(placeID: id, identifier: clock.timeZone.identifier))
        }
    }

    /// A zone picked from the list, or let go when picked again.
    private func choose(_ band: TimeZoneBand) {
        let target = Pick.Target.zone(band.offset)
        pick(target == picked?.target ? nil : target)
    }

    private func pick(_ target: Pick.Target?, tapped: Pick.Tapped? = nil) {
        let now = Date.now
        let shown = shownDate(at: now)
        let bands = cache.bands(at: shown, here: here, statuses: statuses, ladder: ladder, names: zoneNames)
        let from = skyPlace(for: picked?.target, bands: bands)
        let made = target.map { Pick(target: $0, tapped: tapped, start: now) }
        // Let go, or with something else picked in its place, the flag of what was picked flies back
        // home and its arc and hours draw back in as the next one's flies out; with nothing picked
        // before, a flag still flying home from the last carries on.
        let outgoing = choice(at: shown, bands: bands).map { Released(choice: $0, start: now) }
        released = outgoing ?? released
        if (made == nil) != (picked == nil) {
            // On a short screen the dial gives way to the card as something's picked, and back.
            withAnimation(.worldTimeReflow(reduceMotion: reduceMotion)) { picked = made }
        } else {
            picked = made
        }
        skyShift = SkyShift(from: from, to: skyPlace(for: target, bands: bands), start: now)
        if target != nil { taps += 1 }
        animate(for: 1.3)
        if let made { feelLanding(of: made) }
        if outgoing != nil {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Released.length))
                if released?.start == now { released = nil }
            }
        }
    }

    /// The flag landing on its hour, felt as its ring goes out round it, once it's flown out from
    /// the place picked, unless something else has been picked by then. With Reduce Motion the
    /// flag is simply there, so there's no landing to feel.
    private func feelLanding(of made: Pick) {
        guard !reduceMotion else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(DialSelection.landing))
            if picked?.start == made.start { landings += 1 }
        }
    }

    /// What's picked, as the dial, the map and the card show it at the time World Time shows.
    private func choice(at shown: Date, bands: [TimeZoneBand]) -> Choice? {
        guard let picked else { return nil }
        switch picked.target {
        case .place(let id):
            guard let place = Self.places[id], let lead = Self.clock(of: place, tapped: picked.tapped) else { return nil }
            // The clock kept where it was tapped leads, so a tap on Darwin heads the card with
            // Darwin's time and lights its zone, not Sydney's.
            let clocks = [lead] + TimeZoneAtlas.clocks(of: place).filter { $0.timeZone.identifier != lead.timeZone.identifier }
            let offset = lead.offset(at: shown)
            let level = statuses[id] ?? .never
            return Choice(
                heading: .place(place, status: level, clocks: clocks), level: level,
                litOffsets: Set(clocks.map { $0.offset(at: shown) }), focusOffset: offset,
                focus: cache.focus(on: id, offset: offset, at: shown), flagPlace: place, clocks: clocks, start: picked.start)
        case .zone(let offset):
            guard var band = bands.first(where: { $0.offset == offset }) else { return nil }
            // Picked by a tap on the World, the zone leads with the name it goes by where it was tapped.
            if let tapped = picked.tapped,
               let index = band.names.firstIndex(where: { name in
                   name.keepers.contains { $0.placeID == tapped.placeID && $0.clock.timeZone.identifier == tapped.identifier }
               }) ?? band.names.firstIndex(where: { name in name.keepers.contains { $0.placeID == tapped.placeID } }) {
                band.leading = index
            }
            let leaderID = picked.tapped?.placeID ?? band.placeID
            guard let leader = Self.places[leaderID] else { return nil }
            let level = statuses[leaderID] ?? .never
            return Choice(
                heading: .band(band), level: level, litOffsets: [offset], focusOffset: offset,
                focus: DialFocus(
                    key: "zone-\(offset)", placeID: nil, sameTime: Set(band.placeIDs), partlySameTime: Set(band.partlyPlaceIDs),
                    offset: offset),
                flagPlace: leader, clocks: [band.clock], start: picked.start)
        }
    }

    // MARK: The sky

    /// Where the sky is: over the country tapped or the place a zone is known by, or over the
    /// person's own city. Where that city isn't known, its clock says roughly how far round the
    /// World it is.
    private func skyPlace(for target: Pick.Target?, bands: [TimeZoneBand]) -> CGPoint {
        switch target {
        case .place(let id):
            if let place = Self.places[id], let location = Self.clock(of: place, tapped: picked?.tapped)?.location
                ?? TimeZoneAtlas.clocks(of: place).first?.location {
                return location
            }
        case .zone(let offset):
            if let band = bands.first(where: { $0.offset == offset }) { return band.location }
        case nil:
            break
        }
        if let location = here.location { return location }
        let now = Date.now
        let standard = Double(here.offset(at: now)) - here.timeZone.daylightSavingTimeOffset(for: now)
        return CGPoint(x: DayNight.normalized(standard / 240), y: 30)
    }

    /// How high the Sun stands where the sky is, in degrees, gliding from one place's to the
    /// next's as another is picked.
    private func skyElevation(at date: Date, sun: DayNight.Sun, bands: [TimeZoneBand]) -> Double {
        func height(_ place: CGPoint) -> Double {
            asin(min(max(sun.elevationSine(latitude: place.y, longitude: place.x), -1), 1)) * 180 / .pi
        }
        let target = height(skyPlace(for: picked?.target, bands: bands))
        guard let skyShift else { return target }
        let t = min(max(date.timeIntervalSince(skyShift.start) / 0.9, 0), 1)
        let eased = t * t * (3 - 2 * t)
        return height(skyShift.from) + (target - height(skyShift.from)) * eased
    }

    // MARK: Dial and map

    /// How long the dial takes to open out into the flat map, or the map to roll back up.
    private static let reshapeLength = 0.9

    /// Opens the dial out into the flat map, or rolls the map back up into the dial.
    private func reshape(toMap: Bool) {
        guard toMap != showsMap, closing == nil else { return }
        // Zoomed in or slid round, the map first comes back to how it starts, then rolls up.
        if !toMap, mapView.isMoved {
            recentreMap(width: lastMapWidth)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(MapZoom.length + 0.05))
                reshape(toMap: false)
            }
            return
        }
        let now = Date.now
        if !reduceMotion, !isSpread, !isExpanded {
            // Turned back partway, the World carries on from the shape it's reached, back the way it
            // came, rather than snapping to the far shape and starting over: its start is set back
            // as far as it would have had to begin to be there now.
            var start = now
            if let under = reshaping, under.toMap != toMap {
                let elapsed = now.timeIntervalSince(under.start)
                if elapsed < ReshapeStage.length { start = now.addingTimeInterval(-(ReshapeStage.length - elapsed)) }
            }
            let next = Reshaping(toMap: toMap, start: start)
            reshaping = next
            let left = max(Self.reshapeLength - now.timeIntervalSince(start), 0)
            animate(for: left + 0.1)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(left))
                if reshaping == next {
                    reshaping = nil
                    landings += 1
                }
            }
        }
        // The card and the rest move with the World as it reshapes, over the same time.
        withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: ReshapeStage.length)) { showsMap = toMap }
    }

    /// Where the dial or the map opening out of it has got to at a moment.
    private func reshapeStage(at date: Date) -> ReshapeStage? {
        guard let reshaping else { return nil }
        let t = date.timeIntervalSince(reshaping.start)
        guard t < Self.reshapeLength else { return nil }
        return ReshapeStage(toMap: reshaping.toMap, elapsed: t)
    }

    /// How much of a view's ring, night and markers shows as the dial and the map trade places: the
    /// one leaving lets go of them at once, and the one arriving gathers them as it settles.
    private func presence(ofMap isMap: Bool, reshape: ReshapeStage?) -> Presence {
        guard let reshape else { return Presence() }
        func ease(_ value: Double) -> Double {
            let t = min(max(value, 0), 1)
            return t * t * (3 - 2 * t)
        }
        let t = reshape.elapsed
        guard isMap == reshape.toMap else {
            return Presence(ring: 1 - ease(t / 0.3), night: 1 - ease(t / 0.25), markers: 1 - ease(t / 0.2))
        }
        return Presence(ring: ease((t - 0.5) / 0.35), night: ease((t - 0.6) / 0.3), markers: ease((t - 0.65) / 0.25))
    }

    /// How the World sits on the full map or the list's, where it curls up from and unrolls back into.
    private func listPlacement(for source: CGRect) -> CurlingWorld.Placement {
        let start = startTransform(for: source)
        return CurlingWorld.Placement(
            scale: start.a, origin: CGPoint(x: start.tx, y: start.ty), wearsAppColors: true, showsAntarctica: true)
    }

    /// How the World sits on the dial, turned so the Sun is at the top.
    private func dialPlacement(in rect: CGRect, rotation: Double) -> (projection: MapProjection, placement: CurlingWorld.Placement) {
        let geometry = DialGeometry(size: rect.width)
        let rim = geometry.discRadius
        return (.polar, CurlingWorld.Placement(
            scale: geometry.scale, origin: CGPoint(x: rect.midX, y: rect.midY), rotation: Self.shortest(rotation),
            clip: CGRect(x: rect.midX - rim, y: rect.midY - rim, width: rim * 2, height: rim * 2), cornerRadius: rim,
            hasPolarSea: true))
    }

    /// How the World sits on the flat map.
    private func flatPlacement(in rect: CGRect, cornerRadius: CGFloat) -> (projection: MapProjection, placement: CurlingWorld.Placement) {
        let geometry = FlatGeometry(size: rect.size, cornerRadius: cornerRadius)
        let map = geometry.mapRect.offsetBy(dx: rect.minX, dy: rect.minY)
        return (.miller, CurlingWorld.Placement(
            scale: geometry.scale, origin: CGPoint(x: map.midX, y: map.minY - FlatGeometry.top * geometry.scale),
            clip: map, cornerRadius: geometry.cornerRadius, hasBandedSea: true))
    }

    // MARK: Opening and closing

    /// How long the opening takes, the day played through included, and the closing.
    private var openingLength: TimeInterval {
        reduceMotion ? 0.35 : curlsFromList ? 3.1 : 2.6
    }

    private var closingLength: TimeInterval {
        reduceMotion ? 0.3 : curlsFromList ? 1.05 : 0.5
    }

    private func open(curling: Bool) {
        guard opening == nil else { return }
        let now = Date.now
        opening = now
        curlsFromList = curling && !reduceMotion
        animate(for: openingLength)
        prepareSubdivisions(after: 1)
        // The bar's buttons come in with the readout, as `stage(at:)` brings it in, rather than
        // standing there from the first frame while the World is still curling up.
        let readoutStarts = reduceMotion ? 0 : curlsFromList ? 0.55 : 0.3
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(readoutStarts))
            guard closing == nil else { return }
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.35)) { isBarShown = true }
        }
        // A whole day plays through, the night sweeping once round the World to now.
        if !reduceMotion {
            let delay = curlsFromList ? 0.95 : 0.5
            start(TimeGlide(from: now.addingTimeInterval(-86_400), to: .now, start: now.addingTimeInterval(delay), length: 1.9))
            // The first few times, once the day has played through, the thumb nudges along to show it slides.
            if slideHints < 3 {
                let hintStart = now.addingTimeInterval(openingLength + 0.3)
                slideHint = hintStart
                slideHints += 1
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(hintStart.timeIntervalSinceNow))
                    animate(for: Self.slideHintLength + 0.05)
                }
            }
        }
    }

    /// How long the thumb's nudge lasts.
    private static let slideHintLength = 1.3

    /// How far the thumb is nudged at a moment, in hours: twice along and back, easing out.
    private func thumbNudge(at date: Date) -> Double {
        guard let slideHint, spin == nil, glide == nil else { return 0 }
        let t = date.timeIntervalSince(slideHint)
        guard t > 0, t < Self.slideHintLength else { return 0 }
        let fade = 1 - t / Self.slideHintLength
        return 0.55 * sin(t / Self.slideHintLength * 2 * 2 * .pi) * fade * fade
    }

    private func close() {
        guard closing == nil, !isSettlingToClose else { return }
        // Going back into the full map, the card first comes down and the flat map comes back to
        // the whole World, so the World can unroll from there into the map it came out of. The
        // dial unrolls from however it's turned, as it curled up into it.
        if sourceMapTransform != nil, curlsFromList, isExpanded || (showsMap && mapView.isMoved) {
            isSettlingToClose = true
            expand(false)
            if showsMap { recentreMap(width: lastMapWidth) }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                isSettlingToClose = false
                close()
            }
            return
        }
        let now = Date.now
        // Pulled up, zoomed in, slid round or turned, the World can't unroll back into the list's
        // map, so it shrinks away.
        if sourceMapTransform == nil,
           isExpanded || (showsMap && mapView.isMoved) || (!showsMap && abs(remainder(dialTurn, 360)) > 0.5) {
            curlsFromList = false
        }
        pinned = shownDate(at: now)
        spin = nil
        glide = nil
        reshaping = nil
        closing = now
        // The bar's buttons fade out with the readout, rather than vanishing in a frame.
        withAnimation(.easeOut(duration: 0.25)) { isBarShown = false }
        animate(for: closingLength)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(closingLength))
            if let chosenLayer { onChooseLayer?(chosenLayer) }
            onClose()
        }
    }

    /// Keeps every frame coming for a while, for the opening, the closing and a pick's flourishes.
    private func animate(for duration: TimeInterval) {
        let until = Date.now.addingTimeInterval(duration)
        guard until > animatingUntil else { return }
        animatingUntil = until
        isAnimating = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            if Date.now >= animatingUntil { isAnimating = false }
        }
    }

    /// Where the full map or the list's is, in this view's space, when enough of it is in view to curl up from.
    private func sourceRect(globalOrigin: CGPoint, size: CGSize) -> CGRect? {
        guard let sourceFrame, sourceFrame.width > 60, sourceFrame.height > 40 else { return nil }
        let rect = sourceFrame.offsetBy(dx: -globalOrigin.x, dy: -globalOrigin.y)
        let visible = rect.intersection(CGRect(origin: .zero, size: size))
        guard !visible.isNull, visible.width * visible.height > rect.width * rect.height * 0.4 else { return nil }
        return rect
    }

    /// From the World's units to the screen, where the list or the full map draws its map.
    private func startTransform(for source: CGRect) -> CGAffineTransform {
        // The full map says just how it lies there; only moved into this view's space.
        if let sourceMapTransform, let sourceFrame {
            return sourceMapTransform.concatenating(
                CGAffineTransform(translationX: source.minX - sourceFrame.minX, y: source.minY - sourceFrame.minY))
        }
        guard let world = Geography.world else { return .identity }
        let flat = world.map(projection, center: center)
        return MapGeometry(focus: flat.focusRect(including: []), size: source.size, zoom: 1, pan: .zero).transform
            .concatenating(CGAffineTransform(translationX: source.minX, y: source.minY))
    }

    /// How far each part has come in at a moment of the opening or closing.
    private func stage(at date: Date) -> Stage {
        func ease(_ value: Double) -> Double {
            let t = min(max(value, 0), 1)
            return t * t * (3 - 2 * t)
        }
        let curls = curlsFromList
        if let closing {
            let t = date.timeIntervalSince(closing)
            guard !reduceMotion else {
                let away = 1 - ease(t / 0.25)
                return Stage(sky: away, ring: away, night: away, markers: away, readout: away, dialOpacity: away)
            }
            let gone = Stage(
                sky: 1 - ease((t - (curls ? 0.45 : 0.1)) / (curls ? 0.5 : 0.35)), ring: 1 - ease(t / 0.35),
                night: 1 - ease(t / 0.3), markers: 1 - ease(t / 0.2), readout: 1 - ease(t / 0.25))
            guard curls else {
                var shrinking = gone
                shrinking.dialOpacity = 1 - ease(t / 0.35)
                shrinking.dialScale = 1 - 0.12 * ease(t / 0.35)
                return shrinking
            }
            var unrolling = gone
            unrolling.curl = 1 - ease((t - 0.1) / 0.9)
            return unrolling
        }
        // Until it's opened, nothing shows but the list's own map, where World Time will start.
        guard let opening else { return Stage(curl: 0, sky: 0, ring: 0, night: 0, markers: 0, readout: 0) }
        let t = date.timeIntervalSince(opening)
        guard !reduceMotion else {
            let shown = ease(t / 0.3)
            return Stage(sky: shown, ring: shown, night: shown, markers: shown, readout: shown, dialOpacity: shown)
        }
        guard curls else {
            return Stage(
                sky: ease(t / 0.4), ring: ease((t - 0.25) / 0.7), night: ease((t - 0.5) / 0.5),
                markers: ease((t - 2.2) / 0.35), readout: ease((t - 0.3) / 0.4),
                dialScale: 0.86 + 0.14 * ease(t / 0.6), dialOpacity: ease(t / 0.5))
        }
        return Stage(
            curl: ease(t / 0.95), sky: ease((t - 0.05) / 0.45), ring: ease((t - 0.6) / 0.75),
            night: ease((t - 1) / 0.5), markers: ease((t - 2.6) / 0.35), readout: ease((t - 0.55) / 0.45))
    }
}

/// How far each part of World Time has come in, from 0 to 1, at a moment of its opening or closing.
private struct Stage {
    /// The map curling up from the list's flat map into the dial or the flat map.
    var curl: Double = 1
    var sky: Double = 1
    var ring: Double = 1
    var night: Double = 1
    var markers: Double = 1
    var readout: Double = 1
    /// The dial or map growing in and shrinking away, when there's no map of the list's to curl from.
    var dialScale: Double = 1
    var dialOpacity: Double = 1
}

/// The flat map zooming by itself from one view to another, and when it began.
private struct MapZoom {
    var from: MapView
    var to: MapView
    var start: Date

    static let length = 0.45
}

/// The dial opening out into the flat map, or the map rolling back up, and when it began.
private struct Reshaping: Equatable {
    var toMap: Bool
    var start: Date
}

/// Where a reshaping between the dial and the flat map has got to.
private struct ReshapeStage {
    var toMap: Bool
    /// Seconds since it began.
    var elapsed: Double

    /// How long the World takes to change shape, the rest of the reshaping its ring, night and
    /// markers settling.
    static let length = 0.85

    /// How far the World has reshaped, eased, from 0 at the shape it left to 1 at the one it's
    /// taking. The easing runs the same backwards, so a reshaping turned back partway, set back to
    /// begin as long before as was left of the first, picks up at just the shape it had reached.
    var shape: Double {
        let t = min(max(elapsed / Self.length, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

/// How much of a view's ring, night and markers shows, from 0 to 1.
private struct Presence {
    var ring = 1.0
    var night = 1.0
    var markers = 1.0
}

/// World Time laid out both ways, with the dial and with the flat map.
private struct Layouts {
    var dial: WorldTimeLayout
    var map: WorldTimeLayout

    /// How round the flat map's corners are in a layout showing it, or as the dial opens out into it.
    func flatCornerRadius(showing layout: WorldTimeLayout) -> CGFloat {
        layout.flat != nil ? layout.flatCornerRadius : map.flatCornerRadius
    }
}

/// A zone or a country picked, and when, for its flourishes.
private struct Pick: Equatable {
    enum Target: Equatable {
        case place(String)
        /// A zone, by how far ahead of UTC it is, in seconds.
        case zone(Int)
    }

    /// Where a zone was picked by a tap on the World: the place tapped and the zone it keeps there,
    /// for the card to lead with and the flag to fly from.
    struct Tapped: Equatable {
        var placeID: String
        var identifier: String
    }

    var target: Target
    var tapped: Tapped?
    var start: Date
}

/// The dial's face turning back to upright by itself, and when it began.
private struct FaceTurn {
    var from: Double
    var to: Double
    var start: Date

    static let length = 0.55
}

/// What's picked, worked out for the moment World Time shows: how the card heads it, which zones
/// light up and in what level, which countries come forward, and whose flag goes to the ring.
private struct Choice {
    var heading: WorldTimeCard.Heading
    var level: VisitLevel
    var litOffsets: Set<Int>
    var focusOffset: Int
    var focus: DialFocus
    /// The place whose flag flies out to the ring, and the clocks whose hours it marks there.
    var flagPlace: AdministrativeDivision
    var clocks: [ZoneClock]
    var start: Date

    /// The flag on the ring at the first clock's hour, the hours the rest cover, and the arc from
    /// the person's own hour, with the flag flying out from where the place lies on `map`.
    func marker(on map: TravelMap, at shown: Date, here: ZoneClock) -> DialSelection? {
        guard let main = clocks.first, let region = map.region(id: flagPlace.id) else { return nil }
        return DialSelection(
            flagAssetName: flagPlace.flagAssetName, color: level == .never ? nil : level.color,
            hours: main.hours(at: shown), otherHours: clocks.dropFirst().map { $0.hours(at: shown) },
            hoursAhead: Double(main.offset(at: shown) - here.offset(at: shown)) / 3600,
            mapPoint: region.center, start: start)
    }
}

/// A pick just let go or given way to another, and when, for its flag to fly back home from its
/// hour and its arc and hours to draw back in after it, or with Reduce Motion, to fade where they are.
private struct Released {
    var choice: Choice
    var start: Date

    /// How long it's drawn for once let go: long enough to draw back in, or to fade.
    static let length = max(DialSelection.retreat, DialSelection.fade) + 0.05

    /// Its flag and hours as the ring shows them, drawing back in.
    func marker(on map: TravelMap, at shown: Date, here: ZoneClock) -> DialSelection? {
        guard var marker = choice.marker(on: map, at: shown, here: here) else { return nil }
        marker.leaving = start
        return marker
    }
}

/// The sky moving from over one place, as longitude and latitude, to over another.
private struct SkyShift {
    var from: CGPoint
    var to: CGPoint
    var start: Date
}

/// Where World Time's parts sit: the dial or the flat map, and the card of time zones, the person's
/// own time riding the dial's ring or the map's ribbon. Stacked, the dial or map heads the screen,
/// the map running from edge to edge, with the card at its foot; on a wide screen, such as iPhone
/// Duo open on its side, the card sits beside them. Held like a book, iPhone Duo opens at a spread:
/// the dial on the far page, the map and the card on the near one. Standing like a laptop, the dial
/// or map keeps to the upright far side, to be seen from a little way off, and the card to the near
/// side, under the fingers.
private struct WorldTimeLayout {
    var dial: CGRect?
    var flat: CGRect?
    var card: CGRect
    /// How round the flat map's corners are: none where it runs from edge to edge of the screen.
    var flatCornerRadius: CGFloat = 16
    var isSideBySide = false
    /// Whether the card can be pulled up over the screen, as it can stacked beneath the dial or map.
    var canExpand = false
    /// Whether the card floats over the map, which takes the whole screen, as on a short, wide
    /// screen such as iPhone Duo's outer display on its side; it can be tucked away to the side.
    var cardFloats = false
    /// Where the dial or map tucks in, small, the card pulled up, and which of them does; nil while
    /// it's down.
    var miniature: CGRect?
    var miniatureSource: CGRect?

    /// Whether the dial and the flat map both show, a page each.
    var showsBoth: Bool { dial != nil && flat != nil }

    /// How the dial or map drawn in `rect` is placed: its full size, or shrunk into the miniature.
    func placement(of rect: CGRect) -> (scale: CGFloat, origin: CGPoint) {
        guard let miniature, rect == miniatureSource, rect.width > 0, rect.height > 0 else { return (1, rect.origin) }
        let scale = min(miniature.width / rect.width, miniature.height / rect.height)
        return (scale, CGPoint(x: miniature.midX - rect.width * scale / 2, y: miniature.midY - rect.height * scale / 2))
    }

    /// `hasPick` says whether a place or a time is picked, for a short stacked screen to give the
    /// card more room for the places keeping it.
    init(size: CGSize, insets: EdgeInsets, fold: FoldRegions?, showsMap: Bool, isExpanded: Bool, hasPick: Bool) {
        let content = CGRect(
            x: insets.leading, y: insets.top,
            width: max(size.width - insets.leading - insets.trailing, 1), height: max(size.height - insets.top - insets.bottom, 1))
        // One foot for every card, however it's laid out: just clear of the home indicator where
        // there is one, and a fuller margin where the window's edge is bare, as on a home-button
        // iPad or a Stage Manager window, so a card never sits a few points off the edge.
        let bottom = content.maxY - (insets.bottom > 0 ? 10 : 16)
        func square(in room: CGRect, margin: CGFloat) -> CGRect {
            let side = max(min(room.width, room.height) - margin, 140)
            return CGRect(x: room.midX - side / 2, y: room.midY - side / 2, width: side, height: side)
        }
        if let fold {
            // The fold is measured within the bars; the layout spans the whole screen.
            let far = fold.far.offsetBy(dx: insets.leading, dy: insets.top).intersection(content)
            let near = fold.near.offsetBy(dx: insets.leading, dy: insets.top).intersection(content).insetBy(dx: 12, dy: 8)
            if !fold.isAcross {
                dial = square(in: far, margin: 20)
                let map = FlatGeometry.fitting(CGSize(width: near.width, height: near.height * 0.42))
                let flat = CGRect(x: near.midX - map.width / 2, y: near.minY + 2, width: map.width, height: map.height)
                self.flat = flat
                card = CGRect(x: near.minX, y: flat.maxY + 12, width: near.width, height: max(min(near.maxY, bottom) - flat.maxY - 12, 120))
                isSideBySide = true
                // Pulled up, the card takes the near page, the map tucking in small above it.
                canExpand = true
                if isExpanded {
                    let height: CGFloat = 80
                    let width = min(height * flat.width / max(flat.height, 1), near.width)
                    let miniature = CGRect(x: near.midX - width / 2, y: near.minY + 2, width: width, height: height)
                    self.miniature = miniature
                    miniatureSource = flat
                    card = CGRect(
                        x: near.minX, y: miniature.maxY + 10, width: near.width,
                        height: max(min(near.maxY, bottom) - miniature.maxY - 10, 160))
                }
            } else {
                // Standing like a laptop: the far half upright for the dial, as large as it fits, or
                // the map running from edge to edge across it; the card on the near half.
                if showsMap {
                    let map = FlatGeometry.fitting(CGSize(width: far.width, height: far.height - 4))
                    flat = CGRect(x: far.midX - map.width / 2, y: far.midY - map.height / 2, width: map.width, height: map.height)
                    flatCornerRadius = far.width >= size.width - 1 ? 0 : 16
                } else {
                    dial = square(in: far, margin: 6)
                }
                card = CGRect(x: near.minX, y: near.minY, width: near.width, height: max(min(near.maxY, bottom) - near.minY, 120))
            }
            return
        }
        let isWide = content.width > content.height * 1.15
        let isShort = content.height < 520
        if isWide, showsMap, isShort {
            // Short and wide, as iPhone Duo's outer display on its side: the map takes the whole
            // screen, clear of the bars and the camera at its sides, and the card floats over its
            // far side.
            let map = FlatGeometry.fitting(CGSize(width: content.width, height: size.height))
            flat = CGRect(x: content.midX - map.width / 2, y: (size.height - map.height) / 2, width: map.width, height: map.height)
            let width = min(max(content.width * 0.4, 260), 380)
            card = CGRect(x: content.maxX - width - 8, y: content.minY + 6, width: width, height: bottom - content.minY - 6)
            cardFloats = true
            isSideBySide = true
            return
        }
        if showsMap {
            // The flat map as large as it can be: beside a column for the card, or running from edge
            // to edge with the card directly beneath it, whichever leaves the map more room, so
            // iPhone Duo open on its side gets the World across its width rather than a strip
            // beside the card.
            let column = min(max(content.width * 0.32, 300), 360)
            let besideRoom = CGSize(width: content.width - column - 28, height: content.height - 8)
            let beside = FlatGeometry.fitting(besideRoom)
            // Stacked, the map leaves the card about 230 points, room for its heading and a couple
            // of rows of the places keeping a time, rather than a single cramped row.
            let mapHeight = max(min(content.width / FlatGeometry.aspect, content.height - 290), 80)
            let stacked = FlatGeometry.fitting(
                CGSize(width: content.width, height: FlatGeometry.ribbonHeight + FlatGeometry.gap + mapHeight))
            func area(_ stage: CGSize) -> CGFloat {
                stage.width * (stage.height - FlatGeometry.ribbonHeight - FlatGeometry.gap)
            }
            if besideRoom.width > 120, area(beside) > area(stacked) {
                // Side by side: the map against the leading edge, centred up and down only where
                // it's shorter than the room; the card in its column beside it.
                let flat = CGRect(
                    x: content.minX + 8, y: content.minY + 4 + max((besideRoom.height - beside.height) / 2, 0),
                    width: beside.width, height: beside.height)
                self.flat = flat
                let cardX = flat.maxX + 12
                card = CGRect(x: cardX, y: content.minY + 8, width: max(content.maxX - cardX - 8, 200), height: bottom - content.minY - 8)
                isSideBySide = true
                return
            }
            // Stacked: the map runs from edge to edge of the screen, the card directly beneath it;
            // where a bar or a camera keeps to a side, as on iPhone Duo's outer display, it keeps
            // clear of them and fades out towards them.
            let flat = CGRect(x: content.midX - stacked.width / 2, y: content.minY + 4, width: stacked.width, height: stacked.height)
            self.flat = flat
            flatCornerRadius = content.width >= size.width - 1 ? 0 : 16
            canExpand = true
            card = CGRect(x: content.minX + 10, y: flat.maxY + 12, width: content.width - 20, height: max(bottom - flat.maxY - 12, 160))
        } else if isWide {
            if isShort {
                // As tall as the screen, pressed to the leading side, leaving the card a single
                // column of zones beside it.
                let side = max(min(size.height - 6, content.width - 230), 140)
                let dial = CGRect(x: content.minX + 2, y: (size.height - side) / 2, width: side, height: side)
                self.dial = dial
                let cardX = dial.maxX + 10
                card = CGRect(x: cardX, y: content.minY + 8, width: max(content.maxX - cardX - 12, 200), height: bottom - content.minY - 8)
            } else {
                // Side by side: the dial as large as the height allows, leaving the card at least
                // 300 points; the dial centred in what the card leaves.
                let side = max(min(content.height - 16, content.width - 300), 140)
                let cardWidth = min(max(content.width - side - 16, 260), 440)
                let room = CGRect(x: content.minX, y: content.minY, width: content.width - cardWidth - 12, height: content.height)
                let dial = CGRect(x: room.midX - side / 2, y: room.midY - side / 2, width: side, height: side)
                self.dial = dial
                let cardX = max(room.maxX, dial.maxX + 10)
                card = CGRect(x: cardX, y: content.minY + 8, width: max(content.maxX - cardX - 12, 200), height: bottom - content.minY - 8)
            }
            isSideBySide = true
            return
        } else {
            // Stacked with the dial: the dial as large as the screen allows, the card keeping room
            // for at least three rows of zones; with something picked on a shorter screen, room
            // for its heading and two rows of the places keeping its time, the dial giving way.
            var cardHeight = max(min(content.height * 0.36, 340), 210)
            if hasPick, content.height < 720 {
                cardHeight = max(cardHeight, min(max(300, content.height * 0.55), content.height - 180))
            }
            let room = CGRect(x: content.minX, y: content.minY, width: content.width, height: content.height - cardHeight)
            let side = max(min(content.width - 12, room.height - 8, 720), 140)
            dial = CGRect(x: content.midX - side / 2, y: room.minY + max((room.height - side) / 2, 2), width: side, height: side)
            card = CGRect(x: content.minX + 10, y: content.maxY - cardHeight, width: content.width - 20, height: bottom - (content.maxY - cardHeight))
            canExpand = true
        }
        // Pulled up, the card takes all but the top, where the dial or map tucks in, small.
        guard isExpanded, let full = dial ?? flat else { return }
        let height: CGFloat = 96
        let width = min(height * full.width / max(full.height, 1), content.width - 40)
        let miniature = CGRect(x: content.midX - width / 2, y: content.minY + 2, width: width, height: height)
        self.miniature = miniature
        miniatureSource = full
        card = CGRect(x: content.minX + 10, y: miniature.maxY + 10, width: content.width - 20, height: max(bottom - miniature.maxY - 10, 160))
    }
}

/// What World Time keeps between frames: the World partway between shapes, the time zones kept
/// around it, and which countries keep a tapped one's time.
@MainActor
@Observable
private final class WorldTimeCache {
    @ObservationIgnored private var shape: (key: String, map: TravelMap)?
    @ObservationIgnored private var focus: (key: String, focus: DialFocus)?
    @ObservationIgnored private var bands: (key: String, bands: [TimeZoneBand])?
    @ObservationIgnored private var clocks: (hour: Int, moment: ZoneMoment, offsets: [String: Int])?
    /// The sea's time zones for each map and centre, and the sea tinted with them for each projection,
    /// worked out away from the main thread, with those under way.
    @ObservationIgnored private var seaFields: [String: SeaZoneField] = [:]
    @ObservationIgnored private var seaFieldsMaking: Set<String> = []
    @ObservationIgnored private var seaTints: [MapProjection: SeaTint] = [:]
    @ObservationIgnored private var seaTintsMaking: Set<String> = []
    /// The borders on land between places keeping different times, for each projection.
    @ObservationIgnored private var zoneBorders: [MapProjection: ZoneBorders] = [:]
    /// Counts what's arrived from away from the main thread, so the scene draws again for it.
    private(set) var seaVersion = 0

    /// The World partway from one projection to another, from the lighter outlines so it keeps up
    /// at every frame, rebuilt only as it moves on; at either end, in full detail.
    func reshaped(
        _ world: Geography, from start: MapProjection, to end: MapProjection, progress: Double, center: MapCenter
    ) -> TravelMap {
        if progress >= 0.999 { return world.map(end, center: center) }
        if progress <= 0.001 { return world.map(start, center: center) }
        let step = (progress * 240).rounded() / 240
        let key = "\(start.rawValue)-\(end.rawValue)-\(center.rawValue)-\(step)"
        if let shape, shape.key == key { return shape.map }
        let map = world.lightMap(from: start, to: end, progress: step, center: center)
        shape = (key, map)
        return map
    }

    /// Every time kept around the World in an hour, which is as often as summer time can change
    /// them, each card leading with the name the person chose for it, from `names`, one zone a line.
    func bands(at date: Date, here: ZoneClock, statuses: [String: VisitLevel], ladder: VisitLadder, names: String) -> [TimeZoneBand] {
        let hour = Int((date.timeIntervalSince1970 / 3600).rounded(.down))
        let key = "\(hour)-\(statuses.count)-\(statuses.values.map { ladder.rank(of: $0) }.reduce(0, +))-\(names)"
        if let bands, bands.key == key { return bands.bands }
        let preferred = Set(names.split(separator: "\n").map(String.init))
        let made = TimeZoneAtlas.bands(at: date, here: here, preferred: preferred) { place in
            ladder.rank(of: statuses[place.id] ?? .never)
        }
        bands = (key, made)
        return made
    }

    /// The clocks around the World in an hour, told apart by every offset kept, so the World is
    /// recoloured by time zone only as some clock changes.
    func zones(at date: Date) -> ZoneMoment {
        clocks(at: date).moment
    }

    /// The sea tinted with its time zones for a map, as the clocks stand: worked out away from the
    /// main thread the first time, and again as the clocks change, the last made shown meanwhile.
    func seaTint(
        in projection: MapProjection, center: MapCenter, map: TravelMap, subdivisions: [TravelMap], zones: ZoneMoment,
        focus: Int?
    ) -> SeaTint? {
        let fieldKey = "\(projection.rawValue)-\(center.rawValue)-\(subdivisions.count)"
        let tintKey = "\(fieldKey)-\(zones.signature)-\(focus.map(String.init) ?? "all")"
        if let tint = seaTints[projection], tint.key == tintKey { return tint }
        if let field = seaFields[fieldKey] {
            if !seaTintsMaking.contains(tintKey) {
                seaTintsMaking.insert(tintKey)
                let offsets = clocks(at: zones.date).offsets
                Task.detached(priority: .userInitiated) {
                    let image = field.image(offsets: offsets, opacity: 0.26, focus: focus)
                    await self.finish(image, key: tintKey, projection: projection)
                }
            }
        } else if !seaFieldsMaking.contains(fieldKey) {
            seaFieldsMaking.insert(fieldKey)
            let lands = map.regions.filter { $0.id != DialPalette.antarcticaID }.map { (key: $0.id, path: $0.path) }
                + subdivisions.flatMap { $0.regions.map { (key: $0.id, path: $0.path) } }
            let raster = SeaZoneField.raster(for: projection, centerLongitude: center.longitude)
            Task.detached(priority: .utility) {
                let field = SeaZoneField.make(
                    lands: lands, bounds: raster.bounds, width: raster.width, height: raster.height,
                    longitudes: raster.longitudes, reach: raster.reach, wraps: raster.wraps)
                await self.finish(field, key: fieldKey)
            }
        }
        return seaTints[projection]
    }

    /// The borders on land between places keeping different times on a map, as the clocks stand,
    /// those of the time in `focus` apart, once the map's lands have been worked out; picked out
    /// afresh only as the clocks or the focus change.
    func zoneBorders(
        in projection: MapProjection, center: MapCenter, subdivisions: Int, zones: ZoneMoment, focus: Int?
    ) -> ZoneBorders? {
        let fieldKey = "\(projection.rawValue)-\(center.rawValue)-\(subdivisions)"
        let key = "\(fieldKey)-\(zones.signature)-\(focus.map(String.init) ?? "all")"
        if let borders = zoneBorders[projection], borders.key == key { return borders }
        // Meanwhile the last made, unless it was for another centre, whose lines would fall astray.
        guard let field = seaFields[fieldKey] else {
            return zoneBorders[projection].flatMap { $0.key.hasPrefix("\(projection.rawValue)-\(center.rawValue)-") ? $0 : nil }
        }
        let made = field.zoneBorders(offsets: clocks(at: zones.date).offsets, focus: focus, key: key)
        zoneBorders[projection] = made
        return made
    }

    /// The offset kept at a point of the sea on a map, once its zones have been worked out.
    func seaOffset(at point: CGPoint, in projection: MapProjection, center: MapCenter, subdivisions: Int, date: Date) -> Int? {
        guard let field = seaFields["\(projection.rawValue)-\(center.rawValue)-\(subdivisions)"] else { return nil }
        let raster = SeaZoneField.raster(for: projection, centerLongitude: center.longitude)
        return field.offset(at: point, bounds: raster.bounds, offsets: clocks(at: date).offsets)
    }

    private func finish(_ image: CGImage?, key: String, projection: MapProjection) {
        seaTintsMaking.remove(key)
        guard let image else { return }
        seaTints[projection] = SeaTint(key: key, image: image)
        seaVersion += 1
    }

    private func finish(_ field: SeaZoneField, key: String) {
        seaFields[key] = field
        seaFieldsMaking.remove(key)
        seaVersion += 1
    }

    /// Every World place's main offset from UTC in an hour, by its ID.
    func zoneOffsets(at date: Date) -> [String: Int] {
        clocks(at: date).offsets
    }

    private func clocks(at date: Date) -> (hour: Int, moment: ZoneMoment, offsets: [String: Int]) {
        let hour = Int((date.timeIntervalSince1970 / 3600).rounded(.down))
        if let clocks, clocks.hour == hour { return clocks }
        let moment = Date(timeIntervalSince1970: Double(hour) * 3600 + 1800)
        var hasher = Hasher()
        var offsets: [String: Int] = [:]
        for place in CountryCatalog.world.divisions {
            guard let offset = TimeZoneAtlas.clocks(of: place).first?.offset(at: moment) else { continue }
            offsets[place.id] = offset
            hasher.combine(offset)
        }
        for id in TimeZoneAtlas.subdivisionIDs {
            let offset = TimeZoneAtlas.clock(ofSubdivision: id)?.offset(at: moment)
            offsets[id] = offset
            hasher.combine(offset)
        }
        let made = (hour, ZoneMoment(date: moment, signature: hasher.finalize()), offsets)
        clocks = made
        return made
    }

    /// The countries whose own time is the one a country keeps where it was tapped, `offset`
    /// seconds ahead of UTC, at a moment, and those keeping it in only some of their zones. Worked
    /// out once an hour, which is as often as summer time can change it.
    func focus(on placeID: String, offset: Int, at date: Date) -> DialFocus {
        let hour = Int((date.timeIntervalSince1970 / 3600).rounded(.down))
        let key = "\(placeID)@\(offset)@\(hour)"
        if let focus, focus.key == key { return focus.focus }
        var made = DialFocus(key: "place-\(placeID)-\(offset)", placeID: placeID, sameTime: [], partlySameTime: [])
        let places = CountryCatalog.world.divisions
        if places.contains(where: { $0.id == placeID }) {
            made.offset = offset
            for other in places where other.id != placeID {
                let clocks = TimeZoneAtlas.clocks(of: other)
                if clocks.first?.offset(at: date) == offset {
                    made.sameTime.insert(other.id)
                } else if clocks.dropFirst().contains(where: { $0.offset(at: date) == offset }) {
                    made.partlySameTime.insert(other.id)
                }
            }
        }
        focus = (key, made)
        return made
    }
}

/// The handle along the top of the card of zones: a short bar, brightening and widening as it's
/// pressed, with the same give as every other control.
private struct GrabberButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(.white.opacity(configuration.isPressed ? 0.6 : 0.32))
            .frame(width: configuration.isPressed ? 44 : 36, height: 5)
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            .contentShape(.rect)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

/// The dial or map tucked beside the time, as a button over it: it dips a little as it's pressed.
private struct MiniatureButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Color.white.opacity(configuration.isPressed ? 0.08 : 0.001)
            .clipShape(.rect(cornerRadius: 14, style: .continuous))
            .contentShape(.rect)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

extension Animation {
    /// World Time making room: the card and the dial or map above it changing size and place
    /// together, as something's picked or let go and the dial gives way to the card, or as the card
    /// is pulled up or let down; with Reduce Motion, a short fade.
    static func worldTimeReflow(reduceMotion: Bool) -> Animation {
        reduceMotion ? MapMotion.fade : .smooth(duration: 0.5, extraBounce: 0.06)
    }
}

private extension CurlingWorld.Placement {
    /// The same placement shrunk by a factor about a point on screen, as a pinch shrinks the flat
    /// map about its middle.
    func scaled(by factor: CGFloat, about point: CGPoint) -> CurlingWorld.Placement {
        var scaled = self
        scaled.scale = scale * factor
        scaled.origin = CGPoint(x: point.x + (origin.x - point.x) * factor, y: point.y + (origin.y - point.y) * factor)
        scaled.clip = clip.map { rect in
            CGRect(
                x: point.x + (rect.minX - point.x) * factor, y: point.y + (rect.minY - point.y) * factor,
                width: rect.width * factor, height: rect.height * factor)
        }
        scaled.cornerRadius = cornerRadius * factor
        return scaled
    }
}
