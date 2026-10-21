import SwiftUI

/// Draws a collection's map, each place filled with its status colour.
/// Colours sweep in from west to east when the map appears. A place that rises lifts while its
/// new colour floods out from its centre, and sends a ripple of that colour across the map; a
/// place that falls quietly drains back, and the places around a rising one lift a little as its
/// ripple passes them. Where the map is in front, a rising place breaks out of it instead: it lifts
/// off over everything around the map and lands back with sparks, and on the full map its ripple
/// spreads across the screen as it lands. Full-screen maps also set place names on the map. With day and night on, the
/// World's night side is shaded and the capitals there light up.
struct TravelMapCanvas: View, Animatable {
    var map: TravelMap
    /// Statuses for the places in the current collection. Other outlines draw as plain land.
    var statuses: [String: VisitLevel]
    var minimumStatus: VisitLevel
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
    /// How far the map is turned on screen, clockwise, about the middle of the area it fits into.
    /// Only the full map turns under two fingers; every other map faces north.
    var rotation: Angle = .zero
    /// Room kept clear around the fitted map, such as for bars and panels floating over it.
    var insets = EdgeInsets()
    /// The area to fit on screen, when it should differ from the places being coloured.
    var focus: CGRect?
    /// Colours sweep in when the map first appears. A map growing out of its card is already coloured.
    var revealsOnAppear = true
    /// When set, places at other levels fade back.
    var highlight: VisitLevel?
    /// A place to outline, such as the one whose details are open.
    var selection: String?
    /// Every part of a place drawn in several, outlined together with `selection`, so tapping
    /// Scotland outlines the whole United Kingdom its callout names, not Scotland alone.
    var selectionParts: Set<String> = []
    /// The colour to trace the selected place in, over a soft glow of the same colour, as Learn
    /// does; without one it's outlined in the primary colour.
    var selectionTint: Color? = nil
    /// Whether the outline traces itself in round each place newly picked, as a pen would: in its
    /// tint, as Learn's does, or in the primary colour, as round a place whose callout opens on
    /// the full map. Otherwise it's simply there, as while Learn's places are scrubbed past.
    var tracesSelection = false
    /// Changes to pulse a tinted outline: it dims and traces round again, to say where the place is.
    var selectionPulses = 0
    /// A country's subdivisions drawn over this map in the same projection, such as Japan's
    /// prefectures over the World. They trace themselves in as `detailProgress` runs from 0 to 1.
    var detail: MapDetail?
    var detailProgress: Double = 0
    /// The country's own map, which the subdivisions settle into as `morphProgress` runs from 0 to
    /// 1: each one moves from its place on the World to its place on the country's map.
    var morph: TravelMap?
    var morphProgress: Double = 0
    /// Whether the subdivisions are leaving: their borders then fade away rather than retracing.
    var detailIsLeaving = false
    /// How far the rest of the map washes out as a detail arrives: most of the way for a country's
    /// subdivisions over the World, a little for a region's over its country's own map, where the
    /// other regions stay in view.
    var detailWash = 0.6
    /// Names to set on places large enough to hold them, by region. Only full-screen maps pass them.
    var labels: [String: MapLabel] = [:]
    /// Whether the names show. Switched on or off, they fade in or out on the map's own clock.
    var showsLabels = true
    /// Whether to paint the sea and its grid across the whole view. Copies of a map laid side by
    /// side leave it to one of them.
    var drawsBackdrop = true
    /// Whether copies of a rectangular World sit side by side, meeting at its edges. Then the
    /// copies join without a seam: the sea and its grid run on across the joins from the backdrop,
    /// the edge is drawn only along the top and foot, and borders aren't traced down the cut.
    var wrapsAround = false
    /// Whether a rectangular World fills the view edge to edge with copies of itself either side,
    /// the way the Earth runs on round. Views that lay out their own copies turn this off.
    var tiles = true
    /// Levels a place blends into quietly, without lifting, flooding or rippling, as an answer
    /// shown in the quiz does: only a place earned rises with a flourish.
    var quietLevelIDs: Set<String> = []
    /// Whether the camera glides in a straight line, zooming evenly: the place in the middle of the
    /// view travels straight to where it's going, and each doubling of the zoom takes as long as the
    /// last, so a flight from one side of the World to the other neither swoops off course nor
    /// rushes the last of its zoom. Left unset, every map glides straight except copies laid out by
    /// their view, such as the quiz's board, whose veil and spotlights move with the camera's plain
    /// zoom and pan beside the map and must stay in step with it.
    var glidesStraight: Bool? = nil
    /// The camera part way through a glide, in the form it glides in; nil at rest, when `zoom` and
    /// `pan` say it all.
    private var glide: CameraGlide?
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.breaksOutOntoScreen) private var breaksOutOntoScreen
    @Environment(\.spreadsRipplesAcrossScreen) private var spreadsRipplesAcrossScreen
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @AppStorage(LevelPattern.storageKey) private var showsPatterns = true
    @State private var revealStart: Date?
    @State private var hasRevealed = false
    @State private var changes: [String: StatusChange] = [:]
    @State private var ripple: MapRipple?
    @State private var highlightChange = HighlightChange(from: nil, start: .distantPast)
    @State private var isAnimating = false
    @State private var animationGeneration = 0
    @State private var animatingUntil = Date.distantPast
    /// Places around one that has just risen, which lift a little as its ripple reaches them.
    @State private var nudges: [String: Nudge] = [:]
    @Environment(\.showsDayNight) private var showsDayNight
    /// What else World maps show, such as countries coloured by the side of the road they drive on.
    @Environment(\.worldLayers) private var worldLayers
    /// The countries' colouring just changed, which sweeps the new colours across from west to east.
    @State private var colouringChange: ColouringChange?
    /// A layer's key just brought forward or let go, which fades the other countries back or up.
    @State private var layerHighlightChange = LayerHighlightChange(from: nil, start: .distantPast)
    /// The Equator and tropics, or the antipodes, just switched on or off, to draw them in or fade them out.
    @State private var latitudesChange: NightChange?
    @State private var antipodesChange: NightChange?
    /// Day and night just switched on, which plays a day through, or off, which fades the night away.
    @State private var nightChange: NightChange?
    /// The place names just switched on or off, as from the chooser or as the map opens and closes.
    @State private var labelsChange: NightChange?
    /// Moves on every half minute while the night is shown, so its shade keeps creeping west with the Sun.
    @State private var nightClock = Date.now
    /// When the tinted outline began tracing round the place picked, or pulsing; nil while it's
    /// whole. Kept on the map's own clock, apart from the camera's animation, so a new outline
    /// starting never cuts short the camera gliding to its place.
    @State private var selectionTrace: SelectionTrace?

    /// Lets zoom, pan, turn, the room around the map, the subdivisions' arrival and the selected
    /// place's outline tracing itself in glide when they change inside an animation.
    ///
    /// The camera glides in two forms at once. One is its plain zoom and pan, for maps that keep in
    /// step with views beside them. The other glides straight: the zoom's logarithm, so it zooms
    /// evenly, and the place in the middle of the view, which then moves in a straight line. That
    /// place can't be worked out here, without the size of the view, so it travels as two parts
    /// that each move in a straight line and only meet once the view's size is known: the pan
    /// turned back to north and divided by the zoom, and one over the zoom. The body puts them
    /// together (see `CameraGlide`).
    var animatableData: AnimatablePair<
        AnimatablePair<AnimatablePair<CGFloat, CGSize.AnimatableData>, EdgeInsets.AnimatableData>,
        AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, CameraGlide.AnimatableData>>
    > {
        get {
            AnimatablePair(
                AnimatablePair(AnimatablePair(zoom, pan.animatableData), insets.animatableData),
                AnimatablePair(
                    AnimatablePair(detailProgress, morphProgress),
                    AnimatablePair(rotation.radians, CameraGlide(zoom: zoom, pan: pan, rotation: rotation).animatableData)))
        }
        set {
            zoom = newValue.first.first.first
            pan.animatableData = newValue.first.first.second
            insets.animatableData = newValue.first.second
            detailProgress = newValue.second.first.first
            morphProgress = newValue.second.first.second
            rotation = .radians(newValue.second.second.first)
            glide = CameraGlide(animatableData: newValue.second.second.second)
        }
    }

    /// The zoom and pan to draw with in a view of `size`: the straight glide's, while there is one
    /// and the map glides straight, or else the plain ones.
    private func shownCamera(in size: CGSize) -> (zoom: CGFloat, pan: CGSize) {
        guard glidesStraight ?? tiles, let glide else { return (zoom, pan) }
        let area = MapGeometry(focus: focusRect, size: size, zoom: 1, pan: .zero, insets: insets).fitArea
        return glide.camera(middle: CGPoint(x: area.midX, y: area.midY), rotation: rotation)
    }

    /// Every region outlined as selected: the place picked and all its parts.
    private var selectedIDs: Set<String> {
        guard let selection else { return selectionParts }
        return selectionParts.union([selection])
    }

    var body: some View {
        let clock = nightClock
        GeometryReader { proxy in
            let shown = shownCamera(in: proxy.size)
            let geometry = MapGeometry(
                focus: focusRect, size: proxy.size, zoom: shown.zoom, pan: shown.pan, insets: insets, rotation: rotation)
            let tiling = tiling(in: geometry)
            let wraps = (wrapsAround || tiling.lap > 0) && map.outline.map(Self.isRectangular) == true
            TimelineView(.animation(paused: !isAnimating)) { timeline in
                let now = timeline.date
                let rippleElapsed = ripple.map { now.timeIntervalSince($0.start) } ?? .infinity
                let origin = ripple.flatMap { region(id: $0.regionID) }.map { geometry.toScreen($0.center) } ?? .zero
                ZStack {
                    // The middle copy paints the sea and grid for them all; each copy sits a lap further
                    // along the map's own east–west line, which runs aslant while the map is turned.
                    ForEach(tiling.copies, id: \.self) { copy in
                        let shifted = copy == 0 ? geometry : geometry.sliding(by: CGFloat(copy) * tiling.lap)
                        canvas(geometry: shifted, now: now, clock: clock, isCopy: copy != 0, wraps: wraps)
                    }
                }
                    .layerEffect(
                        ShaderLibrary.mapRipple(
                            .float2(origin), .float(rippleElapsed.isFinite ? rippleElapsed : 0),
                            .float(9), .float(14), .float(3.2), .float(MapTiming.rippleSpeed), .color(ripple?.color ?? .white)
                        ),
                        maxSampleOffset: CGSize(width: 10, height: 10),
                        isEnabled: !reduceMotion && rippleElapsed >= 0 && rippleElapsed < MapTiming.ripple
                    )
            }
            // Where the map is in front, a rising place breaks out of it: it lifts off over everything
            // around the map, and as it lands on the full map, the ripple's light carries on across
            // the screen.
            .onChange(of: ripple?.start) {
                guard breaksOutOntoScreen, !reduceMotion, let ripple,
                      let region = region(id: ripple.regionID) else { return }
                // The global frame includes any scale the map is shown at, such as while it grows open.
                let frame = proxy.frame(in: .global)
                let scale = proxy.size.width > 0 ? frame.width / proxy.size.width : 1
                let toScreen = geometry.transform
                    .concatenating(CGAffineTransform(scaleX: scale, y: scale))
                    .concatenating(CGAffineTransform(translationX: frame.minX, y: frame.minY))
                // Only a place in view on the map breaks out of it, not one the camera has left out.
                let point = region.center.applying(toScreen)
                let isInView = frame.contains(point) && ToastCenter.shared.isOnScreen(point)
                if ripple.liftsOff, !isInView || !liftOff(region, for: ripple, toScreen: toScreen) {
                    standDown(ripple)
                    return
                }
                guard spreadsRipplesAcrossScreen, isInView else { return }
                ToastCenter.shared.ripple(from: point, color: ripple.color, start: ripple.start)
            }
        }
        .onAppear(perform: startReveal)
        .onChange(of: statuses) { old, new in noteChanges(from: old, to: new, isDetail: false) }
        .onChange(of: detail?.statuses) { old, new in noteChanges(from: old ?? [:], to: new ?? [:], isDetail: true) }
        .onChange(of: highlight) { old, _ in
            highlightChange = HighlightChange(from: old, start: .now)
            animate(for: MapTiming.highlight)
        }
        .onChange(of: showsDayNight) { _, isOn in
            nightClock = .now
            guard !reduceMotion else {
                nightChange = nil
                return
            }
            nightChange = NightChange(isOn: isOn, start: .now)
            animate(for: isOn ? DayNight.introDuration : DayNight.fadeDuration)
        }
        // A place newly picked traces its outline in, and a pulse dims a tinted one and traces it
        // round again; with Reduce Motion, or while places are scrubbed past, it's simply there.
        .onChange(of: selectedIDs) { _, ids in
            guard tracesSelection, !reduceMotion, !ids.isEmpty else {
                selectionTrace = nil
                return
            }
            selectionTrace = SelectionTrace(start: .now, from: 0, duration: MapTiming.selectionTrace)
            animate(for: MapTiming.selectionTrace)
        }
        .onChange(of: selectionPulses) {
            guard selectionTint != nil, !reduceMotion else { return }
            selectionTrace = SelectionTrace(start: .now, from: 0.55, duration: MapTiming.selectionPulse)
            animate(for: MapTiming.selectionPulse)
        }
        // The new colours sweep across the World from west to east; with Reduce Motion every
        // country fades into its new colour at once, in one short blend.
        .onChange(of: worldLayers.colouring) { old, _ in
            colouringChange = ColouringChange(from: old, start: .now, sweeps: !reduceMotion)
            animate(for: reduceMotion ? MapTiming.layerBlend : MapTiming.layerSweep)
        }
        .onChange(of: worldLayers.highlight) { old, _ in
            layerHighlightChange = LayerHighlightChange(from: old, start: .now)
            animate(for: MapTiming.highlight)
        }
        // The lines draw themselves across the World and the antipodes rise into view from west
        // to east; with Reduce Motion both only fade in where they are. Either way they fade out.
        .onChange(of: worldLayers.showsLatitudes) { _, isOn in
            latitudesChange = NightChange(isOn: isOn, start: .now, fades: reduceMotion)
            animate(for: isOn && !reduceMotion ? MapTiming.latitudesDrawIn : DayNight.fadeDuration)
        }
        .onChange(of: worldLayers.showsAntipodes) { _, isOn in
            antipodesChange = NightChange(isOn: isOn, start: .now, fades: reduceMotion)
            animate(for: isOn && !reduceMotion ? MapTiming.antipodesRise : DayNight.fadeDuration)
        }
        // The place names fade in or out where they are, whatever switched them.
        .onChange(of: showsLabels) { _, isOn in
            labelsChange = NightChange(isOn: isOn, start: .now, fades: true)
            animate(for: MapTiming.highlight)
        }
        // Only a map in longitude and latitude, the World, has a night to move on.
        .task(id: showsDayNight && map.projection != nil) {
            guard showsDayNight, map.projection != nil else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { return }
                nightClock = .now
            }
        }
    }

    // MARK: Drawing

    /// Which copies of the map to draw, by how many laps from the middle one, and how wide a lap is
    /// on screen. Only a rectangular World tiles, and only the copies that reach into view are drawn.
    /// Turned, the copies run on along the map's own east–west line, so the view is measured on the map.
    private func tiling(in geometry: MapGeometry) -> (copies: [Int], lap: CGFloat) {
        guard tiles, !map.isSphere, let outline = map.outline, Self.isRectangular(outline) else { return ([0], 0) }
        guard geometry.rotation == .zero else {
            let edges = outline.boundingRect
            let lap = edges.width * geometry.scale
            guard lap > 1, edges.width > 0 else { return ([0], 0) }
            let seen = geometry.visibleMapRect
            let first = Int(((seen.minX - edges.maxX) / edges.width).rounded(.up))
            let last = Int(((seen.maxX - edges.minX) / edges.width).rounded(.down))
            return (Self.copies(from: first, through: last), lap)
        }
        let box = outline.boundingRect.applying(geometry.transform)
        let lap = box.width
        guard lap > 1 else { return ([0], 0) }
        let first = Int((-box.maxX / lap).rounded(.up))
        let last = Int(((geometry.size.width - box.minX) / lap).rounded(.down))
        return (Self.copies(from: first, through: last), lap)
    }

    /// The middle copy, which paints the backdrop, and the copies in view, however many laps along
    /// a World that runs on round has been dragged, but never more than nine at once.
    private static func copies(from first: Int, through last: Int) -> [Int] {
        guard first <= last else { return [0] }
        return [0] + stride(from: first, through: min(last, first + 8), by: 1).filter { $0 != 0 }
    }

    /// One copy of the map. Side copies leave the backdrop to the middle one, and leave out a
    /// country's subdivisions arriving over the World, which happens only in the middle.
    private func canvas(geometry: MapGeometry, now: Date, clock: Date, isCopy: Bool = false, wraps: Bool) -> some View {
        Canvas { context, size in
            let environment = context.environment
            let palette = Dictionary(ladder.allLevels.map { ($0.id, $0.color.resolve(in: environment)) }) { first, _ in first }
            let land = Color(uiColor: .systemGray4).resolve(in: environment)
            let outside = Color(uiColor: .systemGray5).resolve(in: environment)
            let border = Color(uiColor: .systemBackground)
            let scale = geometry.scale
            var mapContext = context
            mapContext.concatenate(geometry.transform)
            // While a country's subdivisions arrive, the country itself gives way and the rest of the
            // World washes out; once they settle into the country's own map, the World is gone.
            let detailShare = detail == nil ? 0 : Double(eased(detailProgress))
            let morphShare = detail == nil || morph == nil ? 0 : Double(eased(morphProgress))
            let worldPresence = (1 - detailWash * detailShare) * (1 - morphShare)
            let owners = detail?.ownerRegionIDs ?? []
            // On the World, the countries can wear something other than the person's levels, such
            // as the side of the road they drive on. Every layer's colours, by key.
            let colouring = map.outline != nil ? worldLayers.colouring : .travels
            let keyColors = Dictionary(
                MapColouring.allCases.flatMap(\.keys).map { ($0.id, $0.color.resolve(in: environment)) }
            ) { first, _ in first }

            if drawsBackdrop && !isCopy {
                drawBackdrop(in: context, size: size, geometry: geometry, wraps: wraps)
            }
            if wraps, let box = map.outline?.boundingRect {
                // The backdrop already carries the sea and its grid across every copy; land only
                // stops at the top and foot, so the copies meet without a join.
                mapContext.clip(to: Path(CGRect(x: box.minX - box.width, y: box.minY, width: box.width * 3, height: box.height)))
            } else if let outline = map.outline {
                // A whole-globe map shows the globe's shape faintly behind the land, with its lines
                // of latitude and longitude, so each projection's character comes through.
                var sea = mapContext
                sea.opacity = (1 - 0.4 * detailShare) * (1 - morphShare)
                sea.fill(outline, with: .color(Color(uiColor: .systemGray6)))
                if let graticule = map.graticule {
                    sea.stroke(graticule, with: .color(.primary.opacity(0.06)), lineWidth: 0.5 / scale)
                }
                // Land stays within the world's edge: Mercator's rounded card, the globe's rim.
                mapContext.clip(to: outline)
            }
            // In the Atlas's coasts, the seas themselves, in their oceans' colours, beneath the land.
            drawSeas(in: mapContext, colouring: colouring, keyColors: keyColors, now: now)
            // Borders, drawn apart from fills so that where copies of a wrapping World meet, the
            // cut through places on the join isn't traced as a border.
            var borders = mapContext
            if wraps, let box = map.outline?.boundingRect {
                let reach = 1.2 / scale
                for edge in [box.minX, box.maxX] {
                    borders.clip(
                        to: Path(CGRect(x: edge - reach, y: box.minY - box.height, width: reach * 2, height: box.height * 3)),
                        options: .inverse)
                }
            }
            for frame in map.frames {
                // Drawn on the map and carried onto the screen, so the box turns with it.
                let box = Path(roundedRect: frame, cornerRadius: 8 / scale).applying(geometry.transform)
                context.stroke(box, with: .color(.secondary.opacity(0.3)), style: StrokeStyle(lineWidth: 0.75, dash: [3, 3]))
            }
            // Outlines outside the collection first, so places in it always draw on top.
            // The globe shows every country, counted or not. A country's own map shows only its own
            // places, so Taiwan appears on China's map only while it counts as part of China.
            var outsideColor = outside
            outsideColor.opacity *= Float(worldPresence)
            if worldPresence > 0 {
                for region in map.regions where map.outline != nil && statuses[region.id] == nil {
                    var color = outsideColor
                    if colouring != .travels {
                        // Coloured by a layer, places outside a group of countries still say what
                        // they are, more quietly than its members.
                        color = mix(layerColor(of: region.id, colouring: colouring, keyColors: keyColors, land: outside, now: now), outside, 0.5)
                        color.opacity *= Float(worldPresence)
                    }
                    mapContext.fill(region.path, with: .color(Color(color)), style: FillStyle(eoFill: true))
                    borders.stroke(region.path, with: .color(border), lineWidth: 0.6 / scale)
                }
            }
            var markers: [(MapRegion, Color.Resolved)] = []
            let selected = selectedIDs
            let patterns = patternLayout(for: map.regions, statuses: statuses, geometry: geometry, budget: 1800)
            for region in map.regions {
                guard let status = statuses[region.id] else { continue }
                let isGivingWay = owners.contains(region.id)
                let onScreen = region.bounds.applying(geometry.transform)
                let floods = !reduceMotion && morphShare == 0 && !(detailShare > 0 && isGivingWay)
                    && max(onScreen.width, onScreen.height) >= 7
                var color = worldColor(
                    for: region, status: status, colouring: colouring, now: now, palette: palette, keyColors: keyColors,
                    land: land, geometry: geometry, floods: floods)
                if isGivingWay {
                    // The country's own coarser outline fades out entirely beneath its subdivisions.
                    color = mix(color, land, Float(detailShare))
                    color.opacity *= Float(1 - detailShare)
                } else {
                    color = mix(color, land, Float(detailWash * detailShare))
                    color.opacity *= Float(worldPresence)
                }
                guard color.opacity > 0.001 else { continue }
                mapContext.fill(region.path, with: .color(Color(color)), style: FillStyle(eoFill: true))
                if !isGivingWay || detailShare < 0.5 {
                    borders.stroke(region.path, with: .color(border), lineWidth: 0.6 / scale)
                }
                // A level's pattern belongs to the level, so a layer's colours go without.
                if !isGivingWay, colouring == .travels {
                    drawPattern(
                        for: region, status: status, color: color, onScreen: onScreen, in: mapContext,
                        geometry: geometry, layout: patterns)
                }
                // Places too small to see get a dot, once there is something to show.
                let hasSomethingToShow = colouring == .travels
                    ? status != .never : !colouring.keyIDs(ofRegion: region.id).isEmpty
                if max(onScreen.width, onScreen.height) < 7, hasSomethingToShow || selected.contains(region.id), detailShare < 0.3 {
                    markers.append((region, color))
                }
            }
            var worldOverlays = context
            worldOverlays.opacity = worldPresence
            drawDisputed(of: map, in: worldOverlays, geometry: geometry, border: border)
            // The countries again at their antipodes, faint, over the land and sea they lie beneath.
            var antipodes = context
            antipodes.opacity = worldPresence
            drawAntipodes(
                in: antipodes, geometry: geometry, now: now, wraps: wraps, colouring: colouring, palette: palette,
                keyColors: keyColors)
            if let detail, detailShare > 0, !isCopy {
                drawDetail(
                    detail, share: detailShare, morphShare: morphShare, context: context, mapContext: mapContext,
                    geometry: geometry, now: now, palette: palette, land: land, border: border, markers: &markers)
            }
            // The places around one that rises lift a little as its ripple reaches them, less the
            // further away they are, as if they felt it pass.
            // Under a layer's colours, only subdivisions drawn over the World show their levels rising.
            for (id, nudge) in nudges where morphShare == 0 && !reduceMotion
                && (colouring == .travels || detail?.statuses[id] != nil) {
                guard changes[id] == nil, !(detailShare > 0 && owners.contains(id)),
                      let region = region(id: id), let status = detail?.statuses[id] ?? statuses[id]
                else { continue }
                let onScreen = region.bounds.applying(geometry.transform)
                guard max(onScreen.width, onScreen.height) >= 7, onScreen.intersects(CGRect(origin: .zero, size: size))
                else { continue }
                let arrival = Double(nudge.distance * scale) / MapTiming.rippleSpeed
                let local = (now.timeIntervalSince(nudge.start) - arrival) / MapTiming.nudge
                guard local > 0, local < 1 else { continue }
                let pop = sin(.pi * local)
                let lift = 1 + 0.06 * nudge.closeness * pop
                var nudgeContext = mapContext
                nudgeContext.translateBy(x: region.center.x, y: region.center.y)
                nudgeContext.scaleBy(x: lift, y: lift)
                nudgeContext.translateBy(x: -region.center.x, y: -region.center.y)
                nudgeContext.addFilter(.shadow(color: .black.opacity(0.14 * nudge.closeness * pop), radius: 4 / scale))
                let color = fill(for: region, status: status, now: now, palette: palette, land: land, geometry: geometry)
                nudgeContext.fill(region.path, with: .color(Color(color)), style: FillStyle(eoFill: true))
                nudgeContext.stroke(region.path, with: .color(border), lineWidth: 0.6 / scale)
            }
            // A place that rises lifts off the map for a moment while its new colour floods out from
            // its centre. A country rising along with it follows a beat later, more quietly.
            // A place that falls doesn't lift; its colour simply drains back.
            // A place lifting off the map is drawn above it instead, keeping its old colour here.
            for (id, change) in changes where morphShare == 0 && change.rises && !change.liftsOff
                && (colouring == .travels || detail?.statuses[id] != nil) {
                let elapsed = now.timeIntervalSince(change.start)
                guard elapsed >= 0, elapsed < MapTiming.flood, !reduceMotion, !(detailShare > 0 && owners.contains(id)),
                      let region = region(id: id), let status = detail?.statuses[id] ?? statuses[id]
                else { continue }
                let onScreen = region.bounds.applying(geometry.transform)
                guard max(onScreen.width, onScreen.height) >= 7 else { continue }
                let pop = sin(.pi * min(elapsed / MapTiming.pop, 1))
                let lift = 1 + (change.isSecondary ? 0.07 : 0.16) * pop
                var popContext = mapContext
                popContext.translateBy(x: region.center.x, y: region.center.y)
                popContext.scaleBy(x: lift, y: lift)
                popContext.translateBy(x: -region.center.x, y: -region.center.y)
                popContext.addFilter(.shadow(
                    color: .black.opacity((change.isSecondary ? 0.12 : 0.25) * pop), radius: 6 / scale))
                guard !change.isSecondary else {
                    let color = fill(for: region, status: status, now: now, palette: palette, land: land, geometry: geometry)
                    popContext.fill(region.path, with: .color(Color(color)), style: FillStyle(eoFill: true))
                    continue
                }
                let old = Color(target(for: change.from, now: now, palette: palette, land: land))
                let new = Color(target(for: status, now: now, palette: palette, land: land))
                popContext.fill(region.path, with: .color(old), style: FillStyle(eoFill: true))
                var flood = popContext
                flood.clip(to: region.path, style: FillStyle(eoFill: true))
                let bounds = region.bounds
                let reach = [bounds.origin, CGPoint(x: bounds.maxX, y: bounds.minY),
                             CGPoint(x: bounds.minX, y: bounds.maxY), CGPoint(x: bounds.maxX, y: bounds.maxY)]
                    .map { hypot($0.x - region.center.x, $0.y - region.center.y) }
                    .max() ?? 0
                let radius = max(reach * 1.2 * CGFloat(eased(elapsed / MapTiming.flood)), 0.0001)
                flood.fill(
                    Path(ellipseIn: CGRect(
                        x: region.center.x - radius, y: region.center.y - radius, width: radius * 2, height: radius * 2)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: new, location: 0), .init(color: new, location: 0.8),
                            .init(color: new.opacity(0), location: 1),
                        ]),
                        center: region.center, startRadius: 0, endRadius: radius))
            }
            drawNight(in: context, geometry: geometry, now: now, clock: clock, wraps: wraps, presence: 1 - morphShare)
            // How strongly the place names show, as they fade in or out when switched.
            let names = labels.isEmpty ? 0 : labelPresence(at: now)
            drawLatitudes(
                in: context, geometry: geometry, now: now, wraps: wraps, presence: worldPresence,
                names: isCopy ? 0 : names)
            for (region, color) in markers {
                let center = geometry.toScreen(region.center)
                // Under a layer every small place has a colour, so their dots stay small and quiet:
                // one the same colour as the land around it all but disappears.
                let isSelected = selected.contains(region.id)
                let isQuiet = colouring != .travels && !isSelected
                let radius: CGFloat = isQuiet ? 2.4 : 3.5
                let dot = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                context.fill(dot, with: .color(Color(color)))
                if !isQuiet {
                    context.stroke(
                        dot, with: .color(isSelected ? selectionTint ?? .primary : border), lineWidth: isSelected ? 2 : 1)
                }
            }
            if names > 0 {
                // The World's names give way to the subdivisions' as they arrive, and both fade
                // away as the subdivisions set off for the country's own map.
                let settingOff = names * (1 - Double(eased(morphShare / 0.2)))
                MapLabels.draw(
                    labels, regions: map.regions, in: context, geometry: geometry, opacity: settingOff * (1 - detailShare))
                if let detail, detailShare > 0 {
                    MapLabels.draw(
                        labels, regions: detail.map.regions, in: context, geometry: geometry,
                        opacity: settingOff * detailShare)
                }
                // The country's own names fade in where its places land, over the last of the
                // morph, and carry on unchanged once its map takes over; flying back out, they
                // fade before the places set off back to the World.
                if let detail, let morph, morphShare > 0.75, !isCopy {
                    MapLabels.draw(
                        labels, regions: morph.regions, in: context,
                        geometry: destinationGeometry(of: morph, detail: detail, size: geometry.size),
                        opacity: names * Double(eased((morphShare - 0.75) / 0.25)))
                }
            }
            if morphShare == 0, !selected.isEmpty {
                drawSelection(
                    selected.subtracting(markers.map(\.0.id)), in: context, mapContext: mapContext, geometry: geometry,
                    reveal: selectionTrace?.progress(at: now) ?? 1)
            }
            if let outline = map.outline, morphShare < 1, !wraps {
                var edge = context
                edge.concatenate(geometry.transform)
                edge.opacity = 1 - morphShare
                if map.isSphere {
                    // Light from the upper left and a little shade towards the rim make it a sphere.
                    let rim = outline.boundingRect
                    let radius = max(rim.width, rim.height) / 2
                    edge.fill(outline, with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.22), .white.opacity(0), .black.opacity(0.10)]),
                        center: CGPoint(x: rim.midX - radius * 0.35, y: rim.midY - radius * 0.4),
                        startRadius: 0, endRadius: radius * 1.45))
                }
                edge.stroke(outline, with: .color(.primary.opacity(0.12)), lineWidth: 0.75 / scale)
            }
        }
    }

    /// Outlines the selected place, every part of it alike, in sorted order so the parts never
    /// swap places from one frame to the next. Each part traces itself round as `reveal` runs to
    /// 1: tinted, as Learn picks a place, in the tint over a soft glow of the same colour that
    /// follows the line; otherwise as a plain line in the primary colour, as round a place whose
    /// callout has just opened.
    private func drawSelection(
        _ ids: Set<String>, in context: GraphicsContext, mapContext: GraphicsContext, geometry: MapGeometry,
        reveal: Double
    ) {
        let regions = ids.sorted().compactMap { region(id: $0) }
        guard !regions.isEmpty else { return }
        let scale = geometry.scale
        let reveal = min(max(reveal, 0), 1)
        guard reveal > 0 else { return }
        let traced = regions.map { reveal >= 1 ? $0.path : $0.path.trimmedPath(from: 0, to: reveal) }
        guard let tint = selectionTint else {
            // Its ends rounded, so the line's leading tip looks drawn rather than cut.
            let line = StrokeStyle(lineWidth: 2 / scale, lineCap: .round, lineJoin: .round)
            for path in traced {
                mapContext.stroke(path, with: .color(.primary), style: line)
            }
            return
        }
        // The glow is blurred on the screen, so it stays as soft however close the map is.
        var glow = context
        glow.addFilter(.blur(radius: 3))
        for path in traced {
            glow.stroke(
                path.applying(geometry.transform), with: .color(tint.opacity(0.3)),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
        }
        // The traced line's ends are rounded, so its leading tip looks drawn rather than cut.
        let line = StrokeStyle(lineWidth: 2 / scale, lineCap: .round, lineJoin: .round)
        for path in traced {
            mapContext.stroke(path, with: .color(tint), style: line)
        }
    }

    /// The sea, filling the whole view so the map never looks like a picture floating on white.
    /// Around a rectangular World, such as Mercator's, its lines of longitude and latitude carry on
    /// past its edges, moving with it; other projections' curved edges keep a plain sea.
    private func drawBackdrop(in context: GraphicsContext, size: CGSize, geometry: MapGeometry, wraps: Bool = false) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(uiColor: .systemGray6)))
        guard let outline = map.outline, let graticule = map.graticule, Self.isRectangular(outline) else { return }
        // Straight lines of the graticule: meridians keep their x, parallels their y.
        var meridians: [CGFloat] = []
        var parallels: [CGFloat] = []
        var first: CGPoint?
        var last: CGPoint?
        func finishLine() {
            guard let first, let last else { return }
            if abs(first.x - last.x) < 0.0001 { meridians.append(first.x) }
            if abs(first.y - last.y) < 0.0001 { parallels.append(first.y) }
        }
        graticule.forEach { element in
            switch element {
            case .move(let point):
                finishLine()
                first = point
                last = point
            case .line(let point), .quadCurve(let point, _), .curve(let point, _, _):
                last = point
            case .closeSubpath:
                break
            }
        }
        finishLine()
        let lap = outline.boundingRect.width
        guard lap > 0 else { return }
        let visible = geometry.visibleMapRect
        var grid = Path()
        // The meridians come round again every lap of the World.
        for meridian in meridians {
            var x = meridian + ((visible.minX - meridian) / lap).rounded(.down) * lap
            while x <= visible.maxX {
                grid.move(to: geometry.toScreen(CGPoint(x: x, y: visible.minY)))
                grid.addLine(to: geometry.toScreen(CGPoint(x: x, y: visible.maxY)))
                x += lap
            }
        }
        for parallel in parallels where parallel >= visible.minY && parallel <= visible.maxY {
            grid.move(to: geometry.toScreen(CGPoint(x: visible.minX, y: parallel)))
            grid.addLine(to: geometry.toScreen(CGPoint(x: visible.maxX, y: parallel)))
        }
        var lines = context
        guard !wraps else {
            // Copies of the World side by side leave their lines to the backdrop, which carries
            // them on across the joins, and their edge is only the top and the foot.
            lines.stroke(grid, with: .color(.primary.opacity(0.06)), lineWidth: 0.5)
            let box = outline.boundingRect
            var edges = Path()
            for y in [box.minY, box.maxY] {
                edges.move(to: geometry.toScreen(CGPoint(x: visible.minX, y: y)))
                edges.addLine(to: geometry.toScreen(CGPoint(x: visible.maxX, y: y)))
            }
            lines.stroke(edges, with: .color(.primary.opacity(0.12)), lineWidth: 0.75)
            return
        }
        // Inside its edge, the World draws its own lines.
        lines.clip(to: outline.applying(geometry.transform), options: .inverse)
        lines.stroke(grid, with: .color(.primary.opacity(0.06)), lineWidth: 0.5)
    }

    /// Whether a World's edge is a rectangle, perhaps with rounded corners, as Mercator's is: points
    /// just inside each corner of its bounds fall inside it.
    static func isRectangular(_ outline: Path) -> Bool {
        let box = outline.boundingRect
        let inset = box.height * 0.12
        return [
            CGPoint(x: box.minX + inset, y: box.minY + inset), CGPoint(x: box.maxX - inset, y: box.minY + inset),
            CGPoint(x: box.minX + inset, y: box.maxY - inset), CGPoint(x: box.maxX - inset, y: box.maxY - inset),
        ].allSatisfy { outline.contains($0) }
    }

    /// A country's subdivisions arriving over the map: their outlines trace themselves in while
    /// their colours flood across from west to east. Then, with the country's own map to settle
    /// into, each one moves and reshapes from its place on the World to its place on that map.
    private func drawDetail(
        _ detail: MapDetail, share: Double, morphShare: Double, context: GraphicsContext, mapContext: GraphicsContext,
        geometry: MapGeometry, now: Date, palette: [String: Color.Resolved], land: Color.Resolved,
        border: Color, markers: inout [(MapRegion, Color.Resolved)]
    ) {
        let scale = geometry.scale
        let extent = detail.extent
        // Where the country's own map sits once it fills the view, as it does when opened directly.
        let destination: (map: TravelMap, geometry: MapGeometry)? = if morphShare > 0, let morph {
            (morph, destinationGeometry(of: morph, detail: detail, size: geometry.size))
        } else {
            nil
        }
        let patterns = patternLayout(for: detail.map.regions, statuses: detail.statuses, geometry: geometry, budget: 1200)
        for region in detail.map.regions {
            guard let status = detail.statuses[region.id] else { continue }
            let onScreen = region.bounds.applying(geometry.transform)
            let floods = !reduceMotion && destination == nil && max(onScreen.width, onScreen.height) >= 7
            var color = fill(
                for: region, status: status, now: now, palette: palette, land: land, geometry: geometry, floods: floods)
            let position = (region.center.x - extent.minX) / max(extent.width, 0.0001)
            let flood = (share - 0.15 - 0.45 * position) / 0.4
            color = mix(land, color, eased(flood))
            color.opacity *= Float(min(share * 2.5, 1))
            if let destination, let target = destination.map.region(id: region.id) {
                let move = DetailMove(
                    from: region, to: target, geometry: geometry, destination: destination.geometry, progress: morphShare)
                var leaving = color
                leaving.opacity *= Float(1 - morphShare)
                var arriving = color
                arriving.opacity *= Float(morphShare)
                context.fill(move.leavingPath, with: .color(Color(leaving)), style: FillStyle(eoFill: true))
                context.fill(move.arrivingPath, with: .color(Color(arriving)), style: FillStyle(eoFill: true))
                context.stroke(move.leavingPath, with: .color(border.opacity(1 - morphShare)), lineWidth: 0.6)
                context.stroke(move.arrivingPath, with: .color(border.opacity(morphShare)), lineWidth: 0.6)
                continue
            }
            mapContext.fill(region.path, with: .color(Color(color)), style: FillStyle(eoFill: true))
            if share > 0.9 {
                drawPattern(
                    for: region, status: status, color: color, onScreen: onScreen, in: mapContext,
                    geometry: geometry, layout: patterns)
            }
            if share > 0.6, max(onScreen.width, onScreen.height) < 7, status != .never || region.id == selection {
                markers.append((region, color))
            }
        }
        if destination == nil {
            // Borders trace themselves in on the way in, and fade on the way out.
            for region in detail.map.regions where detail.statuses[region.id] != nil {
                if detailIsLeaving {
                    mapContext.stroke(region.path, with: .color(border.opacity(share)), lineWidth: 0.6 / scale)
                } else {
                    let outline = share < 0.999 ? region.path.trimmedPath(from: 0, to: share) : region.path
                    mapContext.stroke(outline, with: .color(border), lineWidth: 0.6 / scale)
                }
            }
        }
        var softened = context
        softened.opacity = share * (1 - morphShare)
        drawDisputed(of: detail.map, in: softened, geometry: geometry, border: border)
        if let destination {
            // The country's map arrives with its inset boxes and its own soft borders.
            for frame in destination.map.frames {
                let box = Path(roundedRect: frame.applying(destination.geometry.transform), cornerRadius: 8)
                context.stroke(
                    box, with: .color(.secondary.opacity(0.3 * morphShare)), style: StrokeStyle(lineWidth: 0.75, dash: [3, 3]))
            }
            var arriving = context
            arriving.opacity = morphShare
            drawDisputed(of: destination.map, in: arriving, geometry: destination.geometry, border: border)
        }
    }

    /// Where a country's own map sits once it fills the view, as it does when opened directly, for
    /// its subdivisions to settle into.
    private func destinationGeometry(of morph: TravelMap, detail: MapDetail, size: CGSize) -> MapGeometry {
        MapGeometry(focus: morph.focusRect(including: detail.statuses.keys), size: size, zoom: 1, pan: .zero, insets: insets)
    }

    /// How strongly the place names show, from 0 to 1: all the way while they're on, and fading in
    /// or out on the map's own clock for a moment after they're switched.
    private func labelPresence(at now: Date) -> Double {
        guard let labelsChange else { return showsLabels ? 1 : 0 }
        let shown = Double(eased(now.timeIntervalSince(labelsChange.start) / MapTiming.highlight))
        return labelsChange.isOn ? shown : 1 - shown
    }

    /// The night side of a World map, shaded in steps through twilight and softened, with the
    /// capitals' lights glowing in the dark. Switched on, it plays the last day through in a moment;
    /// switched off, it fades. Each copy of a World laid side by side shades its own lap, the
    /// shade running a little past it so the copies meet without a join.
    private func drawNight(
        in context: GraphicsContext, geometry: MapGeometry, now: Date, clock: Date, wraps: Bool, presence: Double
    ) {
        guard let projection = map.projection, let center = map.centerLongitude, let outline = map.outline else { return }
        var opacity = presence
        // The clock moving on is what redraws a resting map; the time itself is read fresh.
        var date = max(clock, .now)
        if let nightChange {
            let elapsed = now.timeIntervalSince(nightChange.start)
            if nightChange.isOn {
                guard showsDayNight else { return }
                opacity *= min(max(elapsed / 0.35, 0), 1)
                if elapsed < DayNight.introDuration {
                    // A whole day plays through, the night sweeping once round the World to now.
                    date = date.addingTimeInterval(-86_400 * (1 - Double(eased(elapsed / DayNight.introDuration))))
                }
            } else {
                opacity *= 1 - min(max(elapsed / DayNight.fadeDuration, 0), 1)
            }
        } else if !showsDayNight {
            return
        }
        guard opacity > 0.001 else { return }
        let isRectangular = !map.isSphere && Self.isRectangular(outline)
        let shade = NightShade.make(
            projection: projection, centerLongitude: center, sun: DayNight.Sun(at: date), edge: isRectangular ? 190 : 180)
        let isDark = context.environment.colorScheme == .dark
        let tint = isDark ? Color(red: 0, green: 0.01, blue: 0.05) : Color(red: 0.04, green: 0.07, blue: 0.22)
        let strength = isDark ? 1.3 : 1
        var night = context
        night.opacity = opacity
        night.clip(to: wraps ? Path(outline.boundingRect).applying(geometry.transform) : outline.applying(geometry.transform))
        let mapWidth = geometry.focus.width * geometry.scale
        night.drawLayer { layer in
            layer.addFilter(.blur(radius: min(max(mapWidth / 140, 1.5), 8)))
            for band in shade.bands {
                layer.fill(band.path.applying(geometry.transform), with: .color(tint.opacity(band.opacity * strength)))
            }
        }
        // The lights keep their size on screen, growing only a little as the map comes closer.
        let reach = min(max(geometry.zoom.squareRoot(), 1), 2.2)
        let warm = Color(red: 1, green: 0.83, blue: 0.5)
        for light in shade.lights {
            let point = geometry.toScreen(light.point)
            let glow = 3.4 * reach
            let core = 0.95 * reach
            night.fill(
                Path(ellipseIn: CGRect(x: point.x - glow, y: point.y - glow, width: glow * 2, height: glow * 2)),
                with: .radialGradient(
                    Gradient(colors: [warm.opacity(0.5 * light.glow), warm.opacity(0)]),
                    center: point, startRadius: 0, endRadius: glow))
            night.fill(
                Path(ellipseIn: CGRect(x: point.x - core, y: point.y - core, width: core * 2, height: core * 2)),
                with: .color(warm.opacity(0.9 * light.glow)))
        }
    }

    // MARK: World layers

    /// A place's colour on the World right now: its level's, or a layer's key's, sweeping from
    /// one to the other across the map from west to east just after the colouring changes.
    private func worldColor(
        for region: MapRegion, status: VisitLevel, colouring: MapColouring, now: Date,
        palette: [String: Color.Resolved], keyColors: [String: Color.Resolved], land: Color.Resolved,
        geometry: MapGeometry, floods: Bool
    ) -> Color.Resolved {
        func color(under colouring: MapColouring, floods: Bool) -> Color.Resolved {
            colouring == .travels
                ? fill(for: region, status: status, now: now, palette: palette, land: land, geometry: geometry, floods: floods)
                : layerColor(of: region.id, colouring: colouring, keyColors: keyColors, land: land, now: now)
        }
        let current = color(under: colouring, floods: floods)
        guard let change = colouringChange, map.outline != nil, change.from != colouring else { return current }
        let position = (region.center.x - focusRect.minX) / max(focusRect.width, 1)
        let progress = change.progress(at: now, position: Double(position))
        guard progress < 1 else { return current }
        return mix(color(under: change.from, floods: false), current, eased(max(progress, 0)))
    }

    /// In the Atlas's coasts, the seas softly in their oceans' colours beneath the land, so each
    /// country's colour matches the water it's on. They sweep in and out from west to east with the
    /// countries, and a key brought forward lights its seas as well as its countries.
    private func drawSeas(
        in context: GraphicsContext, colouring: MapColouring, keyColors: [String: Color.Resolved], now: Date
    ) {
        let change = colouringChange.flatMap { $0.from == colouring ? nil : $0 }
        guard colouring == .coasts || change?.from == .coasts, map.outline != nil,
              let projection = map.projection, let longitude = map.centerLongitude,
              let seas = Geography.subdivisions(of: CountryCatalog.seas.id)?.map(projection, centerLongitude: longitude)
        else { return }
        let clear = Color.Resolved(red: 0, green: 0, blue: 0, opacity: 0)
        for sea in seas.regions {
            var color = layerColor(of: sea.id, colouring: .coasts, keyColors: keyColors, land: clear, now: now)
            if let change {
                let position = (sea.center.x - focusRect.minX) / max(focusRect.width, 1)
                let shown = eased(change.progress(at: now, position: Double(position)))
                color.opacity *= Float(colouring == .coasts ? shown : 1 - shown)
            }
            color.opacity *= 0.4
            guard color.opacity > 0.001 else { continue }
            context.fill(sea.path, with: .color(Color(color)), style: FillStyle(eoFill: true))
        }
    }

    /// A place's colour under a layer: its first key's, or, while a key it has is brought forward,
    /// that one's. Places without the key brought forward fade back; places the layer says
    /// nothing about, such as Antarctica for driving side, are plain land.
    private func layerColor(
        of regionID: String, colouring: MapColouring, keyColors: [String: Color.Resolved], land: Color.Resolved, now: Date
    ) -> Color.Resolved {
        let ids = colouring.keyIDs(ofRegion: regionID)
        guard let first = ids.first, var color = keyColors[first] else { return land }
        let highlight = worldLayers.highlight.flatMap { colouring.key(id: $0) == nil ? nil : $0 }
        if let highlight, ids.contains(highlight), let lit = keyColors[highlight] { color = lit }
        let fadeProgress = min(now.timeIntervalSince(layerHighlightChange.start) / MapTiming.highlight, 1)
        let wasDimmed = layerHighlightChange.from.map { colouring.key(id: $0) != nil && !ids.contains($0) } ?? false
        let isDimmed = highlight.map { !ids.contains($0) } ?? false
        let dim = (wasDimmed ? 1 : 0) + ((isDimmed ? 1 : 0) - (wasDimmed ? 1 : 0)) * eased(fadeProgress)
        color.opacity *= Float(1 - 0.75 * dim)
        return color
    }

    /// How far a layer that just switched on or off has come into view, from 0 to 1, at a share of
    /// the way across the map; nil once it's gone. Sweeps in from the west, or with Reduce Motion
    /// fades in everywhere at once, and fades out all at once.
    private func layerPresence(isOn: Bool, change: NightChange?, duration: Double, position: Double, now: Date) -> Double? {
        guard let change else { return isOn ? 1 : nil }
        let elapsed = now.timeIntervalSince(change.start)
        if change.isOn {
            guard isOn else { return nil }
            guard !change.fades else { return Double(eased(elapsed / DayNight.fadeDuration)) }
            return Double(eased((elapsed - 0.5 * duration * position) / (0.5 * duration)))
        }
        let left = 1 - min(max(elapsed / DayNight.fadeDuration, 0), 1)
        return left > 0.001 ? left : nil
    }

    /// The countries again at their antipodes, mirrored and faint, as one translucent sheet of land
    /// with a soft edge, so they read as the far side of the Earth showing through rather than land
    /// of their own: each in its colour, a level's or a layer's, and the rest a cool ghost. They
    /// rise into view from west to east as they switch on.
    private func drawAntipodes(
        in context: GraphicsContext, geometry: MapGeometry, now: Date, wraps: Bool, colouring: MapColouring,
        palette: [String: Color.Resolved], keyColors: [String: Color.Resolved]
    ) {
        guard let outline = map.outline, let projection = map.projection, let center = map.centerLongitude,
              worldLayers.showsAntipodes || antipodesChange != nil,
              let antipodes = Antipodes.map(projection, centerLongitude: center)
        else { return }
        let visible = CGRect(origin: .zero, size: geometry.size).insetBy(dx: -20, dy: -20)
        let isDark = context.environment.colorScheme == .dark
        let ghost = Color(uiColor: .systemIndigo).resolve(in: context.environment)
        var sheet = context
        sheet.opacity *= isDark ? 0.42 : 0.32
        sheet.clip(to: wraps ? Path(outline.boundingRect).applying(geometry.transform) : outline.applying(geometry.transform))
        // Drawn as one layer, so its edge is traced once round the coasts, not along every border.
        sheet.drawLayer { edged in
            edged.addFilter(.shadow(color: Color(ghost).opacity(0.9), radius: 1.2))
            edged.drawLayer { land in
                for region in antipodes.regions {
                    let path = region.path.applying(geometry.transform)
                    guard path.boundingRect.intersects(visible) else { continue }
                    let position = (region.center.x - focusRect.minX) / max(focusRect.width, 1)
                    guard let presence = layerPresence(
                        isOn: worldLayers.showsAntipodes, change: antipodesChange, duration: MapTiming.antipodesRise,
                        position: position, now: now)
                    else { continue }
                    var color = ghost
                    if colouring == .travels {
                        if let status = statuses[region.id], status != .never, let level = palette[status.id] { color = level }
                    } else if !colouring.keyIDs(ofRegion: region.id).isEmpty {
                        color = layerColor(of: region.id, colouring: colouring, keyColors: keyColors, land: ghost, now: now)
                    }
                    color.opacity *= Float(presence)
                    land.fill(path, with: .color(Color(color)), style: FillStyle(eoFill: true))
                }
            }
        }
    }

    /// The Equator, the tropics and the polar circles, drawing themselves across the World from
    /// west to east as they switch on, or with Reduce Motion fading in where they lie: the Equator
    /// a firm line, the tropics dashed in the Sun's warm colour and the polar circles dotted in ice
    /// blue. Full maps name them where they come into view on the left, as strongly as `names`
    /// says, so the names come and go with the places'.
    private func drawLatitudes(
        in context: GraphicsContext, geometry: MapGeometry, now: Date, wraps: Bool, presence: Double, names: Double
    ) {
        guard let projection = map.projection, let outline = map.outline,
              worldLayers.showsLatitudes || latitudesChange != nil
        else { return }
        var drawIn = 1.0
        var opacity = presence
        if let latitudesChange {
            let elapsed = now.timeIntervalSince(latitudesChange.start)
            if latitudesChange.isOn {
                guard worldLayers.showsLatitudes else { return }
                if latitudesChange.fades {
                    opacity *= min(max(elapsed / DayNight.fadeDuration, 0), 1)
                } else {
                    drawIn = Double(eased(elapsed / MapTiming.latitudesDrawIn))
                }
            } else {
                opacity *= 1 - min(max(elapsed / DayNight.fadeDuration, 0), 1)
            }
        }
        guard opacity > 0.001, drawIn > 0.001 else { return }
        let isRectangular = !map.isSphere && Self.isRectangular(outline)
        let lines = LatitudeLines.drawn(in: projection, edge: isRectangular ? 190 : 180)
        let isDark = context.environment.colorScheme == .dark
        let mapWidth = geometry.focus.width * geometry.scale
        let weight = min(max(mapWidth / 420, 0.8), 1.6)
        var drawing = context
        drawing.opacity = opacity
        drawing.clip(to: wraps ? Path(outline.boundingRect).applying(geometry.transform) : outline.applying(geometry.transform))
        for drawn in lines {
            let style = Self.latitudeStyle(of: drawn.line.kind, isDark: isDark, weight: weight)
            let path = drawn.path.applying(geometry.transform)
            drawing.stroke(drawIn < 1 ? path.trimmedPath(from: 0, to: drawIn) : path, with: .color(style.color), style: style.stroke)
            guard names > 0.001, drawIn >= 1 else { continue }
            // The name sits just above the line, where it first comes into view from the left.
            let room = CGRect(origin: .zero, size: geometry.size).insetBy(dx: 14, dy: 24)
            let start = drawn.pieces.lazy.flatMap { $0 }
                .map { $0.applying(geometry.transform) }
                .first { room.contains($0) && $0.x < room.maxX - 120 }
            guard let start else { continue }
            var named = drawing
            named.opacity = opacity * names
            named.draw(
                Text(drawn.line.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(style.color),
                at: CGPoint(x: start.x + 2, y: start.y - 2), anchor: .bottomLeading)
        }
    }

    private static func latitudeStyle(
        of kind: LatitudeLines.Kind, isDark: Bool, weight: CGFloat
    ) -> (color: Color, stroke: StrokeStyle) {
        switch kind {
        case .equator:
            return (.primary.opacity(isDark ? 0.6 : 0.5), StrokeStyle(lineWidth: 1.2 * weight, lineCap: .round))
        case .tropic:
            return (
                Color(red: 0.93, green: 0.52, blue: 0.16).opacity(0.9),
                StrokeStyle(lineWidth: 1.1 * weight, lineCap: .round, dash: [5 * weight, 3.5 * weight]))
        case .polar:
            return (
                Color(red: 0.32, green: 0.62, blue: 0.95).opacity(0.9),
                StrokeStyle(lineWidth: 1.4 * weight, lineCap: .round, dash: [0.1, 3.6 * weight]))
        }
    }

    /// A place on the map or among the subdivisions drawn over it.
    private func region(id: String) -> MapRegion? {
        detail?.map.region(id: id) ?? map.region(id: id)
    }

    /// Borders whose status is disputed are drawn soft instead of hard: one blurred pass along the
    /// edges of disputed areas and along contested lines. Fills are untouched, so a place you've
    /// been shows its colour like any other.
    private func drawDisputed(of map: TravelMap, in context: GraphicsContext, geometry: MapGeometry, border: Color) {
        guard !map.disputedAreas.isEmpty || !map.disputedLines.isEmpty else { return }
        let visible = CGRect(origin: .zero, size: geometry.size).insetBy(dx: -8, dy: -8)
        var edges = Path()
        for area in map.disputedAreas where area.bounds.applying(geometry.transform).intersects(visible) {
            edges.addPath(area.path.applying(geometry.transform))
        }
        for line in map.disputedLines {
            let path = line.applying(geometry.transform)
            if path.boundingRect.intersects(visible) { edges.addPath(path) }
        }
        guard !edges.isEmpty else { return }
        // Just softer than an ordinary border, growing a little as the map grows on screen.
        let mapWidth = geometry.focus.width * geometry.scale
        let width = min(max(mapWidth / 420, 0.8), 1.8)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: width * 0.6))
            layer.stroke(edges, with: .color(border.opacity(0.85)), lineWidth: width)
        }
    }

    /// A place's colour right now. `floods` says the new colour will flood over this place from its
    /// centre, so until the flood has spread it keeps its old colour beneath; otherwise it blends.
    private func fill(
        for region: MapRegion, status: VisitLevel, now: Date, palette: [String: Color.Resolved],
        land: Color.Resolved, geometry: MapGeometry, floods: Bool = false
    ) -> Color.Resolved {
        var color = target(for: status, now: now, palette: palette, land: land)
        if let change = changes[region.id] {
            let elapsed = now.timeIntervalSince(change.start)
            let old = target(for: change.from, now: now, palette: palette, land: land)
            if elapsed < 0 {
                color = old
            } else if change.liftsOff {
                // Lifted off the map, it takes its new colour here as it lands.
                if elapsed < PlaceLift.landing { color = old }
            } else if change.rises, !change.isSecondary, floods {
                if elapsed < MapTiming.flood { color = old }
            } else if elapsed < MapTiming.blend {
                color = mix(old, color, eased(elapsed / MapTiming.blend))
            }
        }
        if let revealStart, status != .never {
            // West to east: each place starts colouring in a little after the one before it.
            let position = (region.center.x - focusRect.minX) / max(focusRect.width, 1)
            let progress = (now.timeIntervalSince(revealStart) - 0.55 * position) / 0.4
            if progress < 1 { color = mix(land, color, eased(max(progress, 0))) }
        }
        return color
    }

    private func target(for status: VisitLevel, now: Date, palette: [String: Color.Resolved], land: Color.Resolved) -> Color.Resolved {
        var color = status == .never ? land : palette[status.id] ?? land
        if status != .never && ladder.rank(of: status) < ladder.rank(of: minimumStatus) { color.opacity *= 0.5 }
        let fadeProgress = min(now.timeIntervalSince(highlightChange.start) / MapTiming.highlight, 1)
        let wasDimmed = highlightChange.from.map { $0.id != status.id } ?? false
        let isDimmed = highlight.map { $0.id != status.id } ?? false
        let dim = (wasDimmed ? 1 : 0) + ((isDimmed ? 1 : 0) - (wasDimmed ? 1 : 0)) * eased(fadeProgress)
        color.opacity *= Float(1 - 0.75 * dim)
        return color
    }

    // MARK: Geometry

    private var focusRect: CGRect {
        focus ?? map.focusRect(including: statuses.keys)
    }

    // MARK: Animation

    private func startReveal() {
        guard revealsOnAppear, !reduceMotion, !hasRevealed else { return }
        hasRevealed = true
        revealStart = .now
        animate(for: 1)
    }

    private func noteChanges(from old: [String: VisitLevel], to new: [String: VisitLevel], isDetail: Bool) {
        // Only a place moving to another level counts; renaming or recolouring a level doesn't.
        let changed = new.compactMap { id, status -> (id: String, from: VisitLevel, to: VisitLevel)? in
            guard let previous = old[id], previous.id != status.id else { return nil }
            return (id, previous, status)
        }
        guard !changed.isEmpty, changed.count < 6 else { return }
        let now = Date.now
        // With subdivisions over the World, a country changing is following one of its places.
        let isSecondary = !isDetail && detail != nil
        let start = isSecondary ? now.addingTimeInterval(MapTiming.followDelay) : now
        for change in changed {
            changes[change.id] = StatusChange(
                from: change.from, start: start, rises: rises(change.from, to: change.to), isSecondary: isSecondary)
        }
        // Only the place itself, rising, sends a ripple in its new colour, and the places around it
        // feel it pass. Breaking out of the map, it lifts off first, and both wait for it to land.
        // Not while subdivisions are moving into their country's own map, where it isn't drawn
        // where the map would say.
        var landing = 0.0
        if !isSecondary, let first = changed.first, rises(first.from, to: first.to) {
            let liftsOff = breaksOutOntoScreen && !reduceMotion && (morph == nil || morphProgress == 0)
            landing = liftsOff ? PlaceLift.landing : 0
            changes[first.id]?.liftsOff = liftsOff
            let lands = now.addingTimeInterval(landing)
            ripple = MapRipple(regionID: first.id, start: lands, from: first.from, to: first.to, liftsOff: liftsOff)
            nudges = neighbours(of: first.id, among: new, isDetail: isDetail, excluding: Set(changed.map(\.id)), start: lands)
        }
        animate(for: MapTiming.ripple + landing + (isSecondary ? MapTiming.followDelay : 0))
    }

    /// Lifts a place that has just risen off the map, over the screen around it, from where it sits
    /// on screen now. False, lifting nothing, when it can't be seen there.
    private func liftOff(_ region: MapRegion, for ripple: MapRipple, toScreen: CGAffineTransform) -> Bool {
        let center = region.center.applying(toScreen)
        var outline = region.mainBody.applying(toScreen)
        let box = outline.boundingRect
        // A place too small to see is drawn as a dot, so the dot lifts instead.
        if max(box.width, box.height) < 7 {
            outline = Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7))
        }
        return ToastCenter.shared.lift(PlaceLift(
            outline: outline, center: center, from: liftColor(for: ripple.from), to: liftColor(for: ripple.to),
            symbolName: ripple.to.symbolName,
            height: Double(ladder.rank(of: ripple.to)) / Double(max(ladder.levels.count, 1)),
            start: ripple.start.addingTimeInterval(-PlaceLift.landing)))
    }

    /// A place that was to lift off but is out of sight rises on the map alone, as it would
    /// anywhere else, from now.
    private func standDown(_ ripple: MapRipple) {
        let now = Date.now
        changes[ripple.regionID]?.liftsOff = false
        nudges = nudges.mapValues { nudge in
            var nudge = nudge
            nudge.start = now
            return nudge
        }
        self.ripple?.liftsOff = false
        self.ripple?.start = now
    }

    /// A level's colour as it fills a place on the map, for the place lifted off it.
    private func liftColor(for status: VisitLevel) -> Color {
        guard status != .never else { return Color(uiColor: .systemGray4) }
        return ladder.rank(of: status) < ladder.rank(of: minimumStatus) ? status.color.opacity(0.5) : status.color
    }

    /// Whether a change is a rise to celebrate: up the ladder, to a level that isn't a quiet one.
    private func rises(_ from: VisitLevel, to: VisitLevel) -> Bool {
        ladder.rank(of: to) > ladder.rank(of: from) && !quietLevelIDs.contains(to.id)
    }

    /// The places around one that has just risen, nearest first: those whose outlines come close to
    /// it, each feeling it less the further away it lies.
    private func neighbours(
        of id: String, among places: [String: VisitLevel], isDetail: Bool, excluding: Set<String>, start: Date
    ) -> [String: Nudge] {
        let regions = isDetail ? detail?.map.regions ?? [] : map.regions
        guard let origin = regions.first(where: { $0.id == id }) else { return [:] }
        let reach = max(max(origin.bounds.width, origin.bounds.height) * 2.5, focusRect.width * 0.05)
        var found: [(id: String, nudge: Nudge)] = []
        for region in regions where places[region.id] != nil && !excluding.contains(region.id) {
            let a = origin.bounds
            let b = region.bounds
            let gap = hypot(max(0, a.minX - b.maxX, b.minX - a.maxX), max(0, a.minY - b.maxY, b.minY - a.maxY))
            guard gap < reach * 0.35 else { continue }
            let distance = hypot(region.center.x - origin.center.x, region.center.y - origin.center.y)
            let closeness = 1 - Double(min(distance / (reach * 2), 1))
            guard closeness > 0.05 else { continue }
            found.append((region.id, Nudge(start: start, distance: distance, closeness: closeness)))
        }
        let nearest = found.sorted { $0.nudge.distance < $1.nudge.distance }.prefix(10)
        return Dictionary(nearest.map { ($0.id, $0.nudge) }) { first, _ in first }
    }

    /// Whether a place is large enough on screen to wear its level's pattern.
    private func showsPattern(onScreen: CGRect, in geometry: MapGeometry) -> Bool {
        onScreen.width >= 20 && onScreen.height >= 12 && onScreen.intersects(CGRect(origin: .zero, size: geometry.size))
    }

    /// Where each patterned place's pattern goes, and its cell size in map space: 12 points on
    /// screen, opened up evenly across the whole map when that would take more than `budget`
    /// cells, so every place keeps its pattern rather than the first few drawn using them all up.
    private func patternLayout(
        for regions: [MapRegion], statuses: [String: VisitLevel], geometry: MapGeometry, budget: Int
    ) -> PatternLayout {
        let base: CGFloat = 12
        let scale = geometry.scale
        guard showsPatterns || differentiateWithoutColor else { return PatternLayout(cell: base / scale) }
        let visible = CGRect(origin: .zero, size: geometry.size).applying(geometry.transform.inverted())
        var layout = PatternLayout(cell: base / scale)
        var cells: CGFloat = 0
        for region in regions {
            guard let status = statuses[region.id], ladder.patternStyle(of: status) != nil,
                  showsPattern(onScreen: region.bounds.applying(geometry.transform), in: geometry)
            else { continue }
            let areas = Self.landAreas(of: region.path, within: visible, minimumSide: 6 / scale)
            layout.areas[region.id] = areas
            cells += areas.reduce(0) { $0 + $1.width * $1.height } * scale * scale / (base * base)
        }
        if cells > CGFloat(budget) {
            layout.cell *= (cells / CGFloat(budget)).squareRoot()
        }
        return layout
    }

    /// The bounds of each piece of a place's outline within view, merged where they overlap, so a
    /// place in pieces far apart, such as the United States and Alaska, isn't patterned across all
    /// the sea between them, and nothing is patterned twice.
    private static func landAreas(of path: Path, within visible: CGRect, minimumSide: CGFloat) -> [CGRect] {
        var pieces: [CGRect] = []
        var current = CGRect.null
        func include(_ point: CGPoint) {
            current = current.union(CGRect(origin: point, size: .zero))
        }
        path.forEach { element in
            switch element {
            case .move(let point):
                if !current.isNull { pieces.append(current) }
                current = CGRect(origin: point, size: .zero)
            case .line(let point):
                include(point)
            case .quadCurve(let point, let control):
                include(point)
                include(control)
            case .curve(let point, let control1, let control2):
                include(point)
                include(control1)
                include(control2)
            case .closeSubpath:
                break
            }
        }
        if !current.isNull { pieces.append(current) }
        var merged: [CGRect] = []
        for piece in pieces {
            var area = piece.intersection(visible)
            guard !area.isNull, max(area.width, area.height) >= minimumSide else { continue }
            // Fold in every area this one overlaps, until it overlaps none.
            while let index = merged.firstIndex(where: { $0.intersects(area) }) {
                area = area.union(merged.remove(at: index))
            }
            merged.append(area)
        }
        return merged
    }

    /// The level's pattern over a place large enough to show it, when patterns are on.
    private func drawPattern(
        for region: MapRegion, status: VisitLevel, color: Color.Resolved, onScreen: CGRect,
        in mapContext: GraphicsContext, geometry: MapGeometry, layout: PatternLayout
    ) {
        guard showsPatterns || differentiateWithoutColor,
              let style = ladder.patternStyle(of: status), let areas = layout.areas[region.id],
              changes[region.id] == nil, color.opacity > 0.05
        else { return }
        var patternContext = mapContext
        patternContext.clip(to: region.path, style: FillStyle(eoFill: true))
        let strength = differentiateWithoutColor ? 0.5 : 0.28
        for area in areas {
            _ = LevelPattern.draw(
                style, in: patternContext, area: area, cell: layout.cell,
                color: .white.opacity(strength * Double(color.opacity)), limit: 3000, symbol: status.symbolName)
        }
    }

    private func animate(for duration: TimeInterval) {
        animationGeneration += 1
        let generation = animationGeneration
        // A short animation starting partway through a longer one, such as a place rising while
        // the day plays through, doesn't cut the longer one short.
        animatingUntil = max(animatingUntil, Date.now.addingTimeInterval(duration + 0.1))
        let until = animatingUntil
        isAnimating = true
        Task {
            try? await Task.sleep(for: .seconds(max(until.timeIntervalSinceNow, 0)))
            guard generation == animationGeneration else { return }
            isAnimating = false
            revealStart = nil
            changes = [:]
            ripple = nil
            nudges = [:]
        }
    }
}

/// A tinted outline tracing itself round a place: from how much of it to whole, starting when, and
/// over how long, easing out as a pen slows to finish a line.
private struct SelectionTrace {
    var start: Date
    var from: Double
    var duration: TimeInterval

    func progress(at date: Date) -> Double {
        let linear = min(max(date.timeIntervalSince(start) / duration, 0), 1)
        let eased = 1 - pow(1 - linear, 3)
        return from + (1 - from) * eased
    }
}

/// A country's subdivisions drawn over the World map in the same projection.
struct MapDetail {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    /// The World's regions the subdivisions cover, such as WORLD-JP, which give way as they arrive.
    var ownerRegionIDs: Set<String>
    /// The area the subdivisions cover, for colouring them in from west to east.
    var extent: CGRect

    init(map: TravelMap, statuses: [String: VisitLevel], ownerRegionIDs: Set<String>) {
        self.map = map
        self.statuses = statuses
        self.ownerRegionIDs = ownerRegionIDs
        extent = map.regions.map(\.bounds).reduce(CGRect.null) { $0.union($1) }
    }
}

/// One subdivision partway between its place on the World and its place on its country's own
/// map: both shapes are carried to the same in-between box, one fading out as the other fades in.
private struct DetailMove {
    var leavingPath: Path
    var arrivingPath: Path

    init(from region: MapRegion, to target: MapRegion, geometry: MapGeometry, destination: MapGeometry, progress: Double) {
        let fromBox = region.bounds.applying(geometry.transform)
        let toBox = target.bounds.applying(destination.transform)
        let t = CGFloat(progress)
        let box = CGRect(
            x: fromBox.minX + (toBox.minX - fromBox.minX) * t,
            y: fromBox.minY + (toBox.minY - fromBox.minY) * t,
            width: fromBox.width + (toBox.width - fromBox.width) * t,
            height: fromBox.height + (toBox.height - fromBox.height) * t)
        leavingPath = region.path.applying(geometry.transform).applying(Self.fitting(fromBox, into: box))
        arrivingPath = target.path.applying(destination.transform).applying(Self.fitting(toBox, into: box))
    }

    private static func fitting(_ source: CGRect, into box: CGRect) -> CGAffineTransform {
        guard source.width > 0.0001, source.height > 0.0001 else {
            return CGAffineTransform(translationX: box.midX - source.midX, y: box.midY - source.midY)
        }
        return CGAffineTransform(translationX: -source.minX, y: -source.minY)
            .concatenating(CGAffineTransform(scaleX: box.width / source.width, y: box.height / source.height))
            .concatenating(CGAffineTransform(translationX: box.minX, y: box.minY))
    }
}

/// Converts between map units and points on screen for a fitted, zoomed, turned and panned map.
/// The map is fitted into the fit area and zoomed, then turned about the middle of the fit area,
/// then panned, so a pan is always a plain move across the screen whichever way the map faces.
struct MapGeometry {
    var focus: CGRect
    var size: CGSize
    var zoom: CGFloat
    var pan: CGSize
    /// Room kept clear around the fitted map; the map still draws beneath it.
    var insets = EdgeInsets()
    /// How far the map is turned, clockwise on screen, about the middle of the fit area.
    var rotation: Angle = .zero

    /// The part of the view the map fits into before zooming.
    var fitArea: CGRect {
        CGRect(
            x: insets.leading, y: insets.top,
            width: max(size.width - insets.leading - insets.trailing, 1),
            height: max(size.height - insets.top - insets.bottom, 1))
    }

    var fitScale: CGFloat {
        guard focus.width > 0, focus.height > 0 else { return 1 }
        return min(fitArea.width / focus.width, fitArea.height / focus.height)
    }

    /// Screen points per map unit.
    var scale: CGFloat { fitScale * zoom }

    var transform: CGAffineTransform {
        let originX = fitArea.midX - focus.midX * fitScale
        let originY = fitArea.midY - focus.midY * fitScale
        guard rotation.radians != 0 else {
            return CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: originX * zoom + pan.width, ty: originY * zoom + pan.height)
        }
        // Fitted and zoomed, then turned about the middle of the fit area, then panned.
        let middle = CGPoint(x: fitArea.midX, y: fitArea.midY)
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: originX * zoom - middle.x, ty: originY * zoom - middle.y)
            .concatenating(CGAffineTransform(rotationAngle: rotation.radians))
            .concatenating(CGAffineTransform(translationX: middle.x + pan.width, y: middle.y + pan.height))
    }

    /// The same layout facing north, for framing a map that is about to stop being turned.
    var facingNorth: MapGeometry {
        var geometry = self
        geometry.rotation = .zero
        return geometry
    }

    /// The part of the map in view, as a rectangle in map units: all of it, and a little more where
    /// the map is turned and the view's corners reach out across it.
    var visibleMapRect: CGRect {
        let corners = [
            CGPoint.zero, CGPoint(x: size.width, y: 0), CGPoint(x: 0, y: size.height), CGPoint(x: size.width, y: size.height),
        ].map(toMap)
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
    }

    /// The same map moved `distance` points along its own east–west line, as a copy of a tiled World
    /// lies a lap along from the middle one.
    func sliding(by distance: CGFloat) -> MapGeometry {
        var geometry = self
        geometry.pan.width += distance * cos(rotation.radians)
        geometry.pan.height += distance * sin(rotation.radians)
        return geometry
    }

    /// The camera that puts a point on the map at a point on screen, at a given zoom and turn.
    func camera(placing point: CGPoint, at screenPoint: CGPoint, zoom: CGFloat, rotation: Angle) -> MapCamera {
        var unpanned = self
        unpanned.zoom = zoom
        unpanned.pan = .zero
        unpanned.rotation = rotation
        let landed = unpanned.toScreen(point)
        return MapCamera(
            zoom: zoom, pan: CGSize(width: screenPoint.x - landed.x, height: screenPoint.y - landed.y), rotation: rotation)
    }

    /// The pan that puts a point on the map at the centre of the fit area at a given zoom, keeping the map's turn.
    func camera(centering point: CGPoint, zoom: CGFloat) -> MapCamera {
        camera(placing: point, at: CGPoint(x: fitArea.midX, y: fitArea.midY), zoom: zoom, rotation: rotation)
    }

    /// The zoom and pan that fit a map rectangle into the fit area, leaving a little room around it.
    /// A turned map keeps its turn, and fits the rectangle as it lies aslant.
    func camera(fitting rect: CGRect) -> MapCamera {
        guard rect.width > 0 || rect.height > 0 else { return MapCamera(zoom: zoom, pan: pan, rotation: rotation) }
        let padded = rect.insetBy(dx: -max(rect.width, rect.height * 0.2) * 0.04, dy: -max(rect.height, rect.width * 0.2) * 0.04)
        // How much room the rectangle takes on screen once turned, for each unit of scale.
        let cosine = abs(cos(rotation.radians))
        let sine = abs(sin(rotation.radians))
        let width = padded.width * cosine + padded.height * sine
        let height = padded.width * sine + padded.height * cosine
        let targetScale = min(fitArea.width / max(width, 0.001), fitArea.height / max(height, 0.001))
        return camera(centering: CGPoint(x: padded.midX, y: padded.midY), zoom: targetScale / fitScale)
    }

    func toScreen(_ point: CGPoint) -> CGPoint { point.applying(transform) }
    func toMap(_ point: CGPoint) -> CGPoint { point.applying(transform.inverted()) }
}

/// How far a map is zoomed in, where it has been dragged to and how far it has been turned.
struct MapCamera: Equatable {
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
    /// Clockwise on screen. Only the full map turns; every other camera faces north.
    var rotation: Angle = .zero

    /// Whether the map faces north, near enough that no compass is needed to say so.
    var facesNorth: Bool { abs(Self.normalised(rotation).degrees) < 0.5 }

    /// The same turn within half a turn either way of north, so animating home never goes the long way round.
    static func normalised(_ rotation: Angle) -> Angle {
        .degrees(remainder(rotation.degrees, 360))
    }
}

/// A camera in the form it glides in, so it moves in a straight line and zooms evenly.
///
/// The map is fitted, zoomed by `z`, turned by `R` about the middle `M` of the fit area, then
/// panned, so the place `c` at that middle, measured from the middle of the fitted map in fitted
/// points as `u`, satisfies `z·u + (z − 1)·M = −R⁻¹·pan`. Gliding `u` in a straight line and
/// `log z` evenly is what's wanted, but `M` depends on the view's size, which an animation's
/// values can't see. So `u` is split into `lead`, `−R⁻¹·pan / z`, and `inverseZoom`, `1 / z`:
/// `u = lead − M·(1 − inverseZoom)`. Both parts are straight in `u` for any `M`, so gliding each in
/// a straight line glides `u` in one too, and they're put back together once `M` is known. At
/// rest the round trip gives back the very pan it started from.
struct CameraGlide {
    var logZoom: Double
    var inverseZoom: Double
    var lead: CGSize

    init(zoom: CGFloat, pan: CGSize, rotation: Angle) {
        let zoom = max(zoom, 0.0001)
        let cosine = cos(rotation.radians)
        let sine = sin(rotation.radians)
        // The pan turned back to face north.
        let unturned = CGSize(
            width: pan.width * cosine + pan.height * sine,
            height: -pan.width * sine + pan.height * cosine)
        logZoom = log(Double(zoom))
        inverseZoom = Double(1 / zoom)
        lead = CGSize(width: -unturned.width / zoom, height: -unturned.height / zoom)
    }

    init(animatableData: AnimatableData) {
        logZoom = animatableData.first.first
        inverseZoom = animatableData.first.second
        lead = CGSize(width: animatableData.second.first, height: animatableData.second.second)
    }

    typealias AnimatableData = AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<CGFloat, CGFloat>>

    var animatableData: AnimatableData {
        AnimatablePair(AnimatablePair(logZoom, inverseZoom), AnimatablePair(lead.width, lead.height))
    }

    /// The zoom and pan this glide has reached, for a fit area whose middle is `middle`, turned by
    /// `rotation`.
    func camera(middle: CGPoint, rotation: Angle) -> (zoom: CGFloat, pan: CGSize) {
        let zoom = CGFloat(exp(logZoom))
        let held = 1 - CGFloat(inverseZoom)
        let u = CGPoint(x: lead.width - middle.x * held, y: lead.height - middle.y * held)
        let v = CGPoint(x: zoom * u.x + (zoom - 1) * middle.x, y: zoom * u.y + (zoom - 1) * middle.y)
        let cosine = cos(rotation.radians)
        let sine = sin(rotation.radians)
        return (zoom, CGSize(width: -(v.x * cosine - v.y * sine), height: -(v.x * sine + v.y * cosine)))
    }
}

/// The map's own clock: how long what it draws for itself takes, apart from any animation, so
/// colours, outlines and ripples never cut short the camera gliding at the same time. Others time
/// themselves to it, as the full map waits for a fact's colours to finish sweeping away before
/// World Time curls up out of it.
enum MapTiming {
    static let blend = 0.55
    static let pop = 0.5
    /// How long a rising place's new colour takes to spread out to its edges.
    static let flood = 0.65
    static let ripple = 1.6
    static let highlight = 0.3
    /// How long a country rising with one of its places waits before it follows.
    static let followDelay = 0.22
    /// How fast a rising place's ripple spreads across the map, in points a second.
    static let rippleSpeed = 700.0
    /// How long a place takes to lift and settle as the ripple passes it.
    static let nudge = 0.45
    /// How long a new colouring takes to sweep across the World from west to east, and how long
    /// each country takes to change as it passes.
    static let layerSweep = 1.1
    static let layerBlend = 0.4
    /// How long the Equator and tropics take to draw themselves across the World.
    static let latitudesDrawIn = 1.2
    /// How long the antipodes take to rise into view.
    static let antipodesRise = 0.9
    /// How long a tinted outline takes to trace itself round a place picked, as in Learn.
    static let selectionTrace = 0.45
    /// How long a tinted outline takes to dim and trace round again when pulsed.
    static let selectionPulse = 0.5
}

/// A place lifting a little as the ripple from a neighbour that rose passes it.
private struct Nudge {
    /// When the neighbour rose; the ripple reaches this place a moment later.
    var start: Date
    /// How far it is from the neighbour, centre to centre, in map units.
    var distance: CGFloat
    /// From 0, barely touched, to 1, right next to it.
    var closeness: Double
}

/// Day and night, or another layer, being switched on or off.
private struct NightChange {
    var isOn: Bool
    var start: Date
    /// Whether a layer switched on only fades in where it is, as with Reduce Motion, rather than
    /// drawing or rising across the World.
    var fades = false
}

/// The countries' colouring changing, from what they were coloured by before.
private struct ColouringChange {
    var from: MapColouring
    var start: Date
    /// Whether the new colours sweep across from west to east; with Reduce Motion, every country
    /// blends into its new colour at once instead.
    var sweeps = true

    /// How far a place `position` of the way across the map from the west has come from the old
    /// colours to the new: below 0 until the sweep reaches it, and 1 or more once it has changed.
    func progress(at now: Date, position: Double) -> Double {
        let wait = sweeps ? (MapTiming.layerSweep - MapTiming.layerBlend) * position : 0
        return (now.timeIntervalSince(start) - wait) / MapTiming.layerBlend
    }
}

/// A layer's key brought forward or let go, from the one brought forward before, if any.
private struct LayerHighlightChange {
    var from: String?
    var start: Date
}

private struct StatusChange {
    var from: VisitLevel
    var start: Date
    /// Rising floods in the new colour and lifts; falling drains quietly.
    var rises: Bool
    /// A country following one of its places, a beat later and more quietly.
    var isSecondary: Bool
    /// Lifted off the map, so it's drawn above it until it lands, rather than here.
    var liftsOff = false
}

private struct MapRipple {
    var regionID: String
    /// When the ripple sets off: as the place rises, or once it has lifted off and landed.
    var start: Date
    var from: VisitLevel
    var to: VisitLevel
    var liftsOff = false

    /// The colour of the level the place rose to, carried on the wave's crests.
    var color: Color { to.color }
}

private struct HighlightChange {
    var from: VisitLevel?
    var start: Date
}

private func eased(_ progress: Double) -> Float {
    let t = Float(min(max(progress, 0), 1))
    return t * t * (3 - 2 * t)
}

private func mix(_ a: Color.Resolved, _ b: Color.Resolved, _ t: Float) -> Color.Resolved {
    Color.Resolved(
        red: a.red + (b.red - a.red) * t,
        green: a.green + (b.green - a.green) * t,
        blue: a.blue + (b.blue - a.blue) * t,
        opacity: a.opacity + (b.opacity - a.opacity) * t
    )
}

/// Where a map's patterns go: each patterned place's pieces of land in view, and one cell size for all.
private struct PatternLayout {
    var cell: CGFloat
    var areas: [String: [CGRect]] = [:]
}

extension TravelMap {
    /// How wide one lap of a rectangular World is, in map units, for maps that tile edge to edge.
    /// Nil for any other map.
    var tileWidth: CGFloat? {
        guard !isSphere, let outline, TravelMapCanvas.isRectangular(outline) else { return nil }
        return outline.boundingRect.width
    }

    /// A point on any copy of a tiled World, moved onto the middle copy, where its places are.
    func untiled(_ point: CGPoint) -> CGPoint {
        guard let width = tileWidth, width > 0, let edge = outline?.boundingRect.minX else { return point }
        var x = (point.x - edge).truncatingRemainder(dividingBy: width)
        if x < 0 { x += width }
        return CGPoint(x: edge + x, y: point.y)
    }
}
