import SwiftUI

/// Draws a collection's map, each place filled with its status colour.
/// Colours sweep in from west to east when the map appears. A place that rises lifts while its
/// new colour floods out from its centre, and sends a ripple of that colour across the map; a
/// place that falls quietly drains back, and the places around a rising one lift a little as its
/// ripple passes them. Full-screen maps also set place names on the map. With day and night on, the
/// World's night side is shaded and the capitals there light up.
struct TravelMapCanvas: View, Animatable {
    var map: TravelMap
    /// Statuses for the places in the current collection. Other outlines draw as plain land.
    var statuses: [String: VisitLevel]
    var minimumStatus: VisitLevel
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
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
    /// Names to set on places large enough to hold them, by region. Only full-screen maps pass them.
    var labels: [String: MapLabel] = [:]
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
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    /// Day and night just switched on, which plays a day through, or off, which fades the night away.
    @State private var nightChange: NightChange?
    /// Moves on every half minute while the night is shown, so its shade keeps creeping west with the Sun.
    @State private var nightClock = Date.now

    /// Lets zoom, pan, the room around the map and the subdivisions' arrival glide when they change
    /// inside an animation.
    var animatableData: AnimatablePair<
        AnimatablePair<AnimatablePair<CGFloat, CGSize.AnimatableData>, EdgeInsets.AnimatableData>,
        AnimatablePair<Double, Double>
    > {
        get {
            AnimatablePair(
                AnimatablePair(AnimatablePair(zoom, pan.animatableData), insets.animatableData),
                AnimatablePair(detailProgress, morphProgress))
        }
        set {
            zoom = newValue.first.first.first
            pan.animatableData = newValue.first.first.second
            insets.animatableData = newValue.first.second
            detailProgress = newValue.second.first
            morphProgress = newValue.second.second
        }
    }

    var body: some View {
        let clock = nightClock
        GeometryReader { proxy in
            let geometry = MapGeometry(focus: focusRect, size: proxy.size, zoom: zoom, pan: pan, insets: insets)
            let tiling = tiling(in: geometry)
            let wraps = (wrapsAround || tiling.lap > 0) && map.outline.map(Self.isRectangular) == true
            TimelineView(.animation(paused: !isAnimating)) { timeline in
                let now = timeline.date
                let rippleElapsed = ripple.map { now.timeIntervalSince($0.start) } ?? .infinity
                let origin = ripple.flatMap { region(id: $0.regionID) }.map { geometry.toScreen($0.center) } ?? .zero
                ZStack {
                    // The middle copy paints the sea and grid for them all; each copy sits a lap further along.
                    ForEach(tiling.copies, id: \.self) { copy in
                        let shifted = copy == 0 ? geometry : MapGeometry(
                            focus: focusRect, size: proxy.size, zoom: zoom,
                            pan: CGSize(width: pan.width + CGFloat(copy) * tiling.lap, height: pan.height), insets: insets)
                        canvas(geometry: shifted, now: now, clock: clock, isCopy: copy != 0, wraps: wraps)
                    }
                }
                    .layerEffect(
                        ShaderLibrary.mapRipple(
                            .float2(origin), .float(rippleElapsed.isFinite ? rippleElapsed : 0),
                            .float(9), .float(14), .float(3.2), .float(MapTiming.rippleSpeed), .color(ripple?.color ?? .white)
                        ),
                        maxSampleOffset: CGSize(width: 10, height: 10),
                        isEnabled: !reduceMotion && rippleElapsed < MapTiming.ripple
                    )
            }
            // On the full map, the ripple's light carries on past the map's edges, across the screen.
            .onChange(of: ripple?.start) {
                guard spreadsRipplesAcrossScreen, !reduceMotion, let ripple,
                      let region = region(id: ripple.regionID) else { return }
                let point = geometry.toScreen(region.center)
                // The global frame includes any scale the map is shown at, such as while it grows open.
                let frame = proxy.frame(in: .global)
                let scale = proxy.size.width > 0 ? frame.width / proxy.size.width : 1
                ToastCenter.shared.ripple(
                    from: CGPoint(x: frame.minX + point.x * scale, y: frame.minY + point.y * scale), color: ripple.color)
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
        .task(id: showsDayNight) {
            guard showsDayNight else { return }
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
    private func tiling(in geometry: MapGeometry) -> (copies: [Int], lap: CGFloat) {
        guard tiles, !map.isSphere, let outline = map.outline, Self.isRectangular(outline) else { return ([0], 0) }
        let box = outline.boundingRect.applying(geometry.transform)
        let lap = box.width
        guard lap > 1 else { return ([0], 0) }
        let first = max(Int((-box.maxX / lap).rounded(.up)), -4)
        let last = min(Int(((geometry.size.width - box.minX) / lap).rounded(.down)), 4)
        return ([0] + stride(from: first, through: last, by: 1).filter { $0 != 0 }, lap)
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
            let worldPresence = (1 - 0.6 * detailShare) * (1 - morphShare)
            let owners = detail?.ownerRegionIDs ?? []

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
                let box = Path(roundedRect: frame.applying(geometry.transform), cornerRadius: 8)
                context.stroke(box, with: .color(.secondary.opacity(0.3)), style: StrokeStyle(lineWidth: 0.75, dash: [3, 3]))
            }
            // Outlines outside the collection first, so places in it always draw on top.
            // The globe shows every country, counted or not. A country's own map shows only its own
            // places, so Taiwan appears on China's map only while it counts as part of China.
            var outsideColor = outside
            outsideColor.opacity *= Float(worldPresence)
            if worldPresence > 0 {
                for region in map.regions where map.outline != nil && statuses[region.id] == nil {
                    mapContext.fill(region.path, with: .color(Color(outsideColor)), style: FillStyle(eoFill: true))
                    borders.stroke(region.path, with: .color(border), lineWidth: 0.6 / scale)
                }
            }
            var markers: [(MapRegion, Color.Resolved)] = []
            let patterns = patternLayout(for: map.regions, statuses: statuses, geometry: geometry, budget: 1800)
            for region in map.regions {
                guard let status = statuses[region.id] else { continue }
                let isGivingWay = owners.contains(region.id)
                let onScreen = region.bounds.applying(geometry.transform)
                let floods = !reduceMotion && morphShare == 0 && !(detailShare > 0 && isGivingWay)
                    && max(onScreen.width, onScreen.height) >= 7
                var color = fill(
                    for: region, status: status, now: now, palette: palette, land: land, geometry: geometry, floods: floods)
                if isGivingWay {
                    // The country's own coarser outline fades out entirely beneath its subdivisions.
                    color = mix(color, land, Float(detailShare))
                    color.opacity *= Float(1 - detailShare)
                } else {
                    color = mix(color, land, Float(0.6 * detailShare))
                    color.opacity *= Float(worldPresence)
                }
                guard color.opacity > 0.001 else { continue }
                mapContext.fill(region.path, with: .color(Color(color)), style: FillStyle(eoFill: true))
                if !isGivingWay || detailShare < 0.5 {
                    borders.stroke(region.path, with: .color(border), lineWidth: 0.6 / scale)
                }
                if !isGivingWay {
                    drawPattern(
                        for: region, status: status, color: color, onScreen: onScreen, in: mapContext,
                        geometry: geometry, layout: patterns)
                }
                // Places too small to see get a dot, once there is something to show.
                if max(onScreen.width, onScreen.height) < 7, status != .never || region.id == selection, detailShare < 0.3 {
                    markers.append((region, color))
                }
            }
            var worldOverlays = context
            worldOverlays.opacity = worldPresence
            drawDisputed(of: map, in: worldOverlays, geometry: geometry, border: border)
            if let detail, detailShare > 0, !isCopy {
                drawDetail(
                    detail, share: detailShare, morphShare: morphShare, context: context, mapContext: mapContext,
                    geometry: geometry, now: now, palette: palette, land: land, border: border, markers: &markers)
            }
            // The places around one that rises lift a little as its ripple reaches them, less the
            // further away they are, as if they felt it pass.
            for (id, nudge) in nudges where morphShare == 0 && !reduceMotion {
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
            for (id, change) in changes where morphShare == 0 && change.rises {
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
            for (region, color) in markers {
                let center = geometry.toScreen(region.center)
                let dot = Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7))
                context.fill(dot, with: .color(Color(color)))
                context.stroke(dot, with: .color(region.id == selection ? .primary : border), lineWidth: region.id == selection ? 2 : 1)
            }
            if !labels.isEmpty, morphShare == 0 {
                // The World's names give way to the subdivisions' as they arrive.
                MapLabels.draw(labels, regions: map.regions, in: context, geometry: geometry, opacity: 1 - detailShare)
                if let detail, detailShare > 0 {
                    MapLabels.draw(labels, regions: detail.map.regions, in: context, geometry: geometry, opacity: detailShare)
                }
            }
            if morphShare == 0, let selection, let region = region(id: selection), !markers.contains(where: { $0.0.id == selection }) {
                mapContext.stroke(region.path, with: .color(.primary), style: StrokeStyle(lineWidth: 2 / scale, lineJoin: .round))
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
        let corner = geometry.toMap(.zero)
        let opposite = geometry.toMap(CGPoint(x: size.width, y: size.height))
        let visible = CGRect(
            x: min(corner.x, opposite.x), y: min(corner.y, opposite.y),
            width: abs(opposite.x - corner.x), height: abs(opposite.y - corner.y))
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
            (morph, MapGeometry(
                focus: morph.focusRect(including: detail.statuses.keys), size: geometry.size, zoom: 1, pan: .zero,
                insets: insets))
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
        night.clip(to: wraps ? Path(outline.boundingRect.applying(geometry.transform)) : outline.applying(geometry.transform))
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
        // feel it pass.
        if !isSecondary, let first = changed.first, rises(first.from, to: first.to) {
            ripple = MapRipple(regionID: first.id, start: now, color: first.to.color)
            nudges = neighbours(of: first.id, among: new, isDetail: isDetail, excluding: Set(changed.map(\.id)), start: now)
        }
        animate(for: MapTiming.ripple + (isSecondary ? MapTiming.followDelay : 0))
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

/// Converts between map units and points on screen for a fitted, zoomed and panned map.
struct MapGeometry {
    var focus: CGRect
    var size: CGSize
    var zoom: CGFloat
    var pan: CGSize
    /// Room kept clear around the fitted map; the map still draws beneath it.
    var insets = EdgeInsets()

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
        return CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: originX * zoom + pan.width, ty: originY * zoom + pan.height)
    }

    /// The pan that puts a point on the map at the centre of the fit area at a given zoom.
    func camera(centering point: CGPoint, zoom: CGFloat) -> MapCamera {
        let scale = fitScale * zoom
        let originX = fitArea.midX - focus.midX * fitScale
        let originY = fitArea.midY - focus.midY * fitScale
        return MapCamera(
            zoom: zoom,
            pan: CGSize(
                width: fitArea.midX - point.x * scale - originX * zoom,
                height: fitArea.midY - point.y * scale - originY * zoom))
    }

    /// The zoom and pan that fit a map rectangle into the fit area, leaving a little room around it.
    func camera(fitting rect: CGRect) -> MapCamera {
        guard rect.width > 0 || rect.height > 0 else { return MapCamera(zoom: zoom, pan: pan) }
        let padded = rect.insetBy(dx: -max(rect.width, rect.height * 0.2) * 0.04, dy: -max(rect.height, rect.width * 0.2) * 0.04)
        let targetScale = min(fitArea.width / max(padded.width, 0.001), fitArea.height / max(padded.height, 0.001))
        let targetZoom = targetScale / fitScale
        let originX = fitArea.midX - focus.midX * fitScale
        let originY = fitArea.midY - focus.midY * fitScale
        return MapCamera(
            zoom: targetZoom,
            pan: CGSize(
                width: fitArea.midX - padded.midX * targetScale - originX * targetZoom,
                height: fitArea.midY - padded.midY * targetScale - originY * targetZoom))
    }

    func toScreen(_ point: CGPoint) -> CGPoint { point.applying(transform) }
    func toMap(_ point: CGPoint) -> CGPoint { point.applying(transform.inverted()) }
}

/// How far a map is zoomed in and where it has been dragged to.
struct MapCamera: Equatable {
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
}

private enum MapTiming {
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

/// Day and night being switched on or off.
private struct NightChange {
    var isOn: Bool
    var start: Date
}

private struct StatusChange {
    var from: VisitLevel
    var start: Date
    /// Rising floods in the new colour and lifts; falling drains quietly.
    var rises: Bool
    /// A country following one of its places, a beat later and more quietly.
    var isSecondary: Bool
}

private struct MapRipple {
    var regionID: String
    var start: Date
    /// The colour of the level the place rose to, carried on the wave's crests.
    var color: Color = .white
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
