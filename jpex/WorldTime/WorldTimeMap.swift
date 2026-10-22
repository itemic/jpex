import SwiftUI

/// World Time's flat map, for when a map suits better than the dial: the World in Miller's
/// projection, from Cape Horn up to the Arctic, in the colours of its time zones, on a dark band
/// that fades into the page. Above it runs a ribbon of the day's hours, the dial's ring laid
/// straight: noon rides over the meridian beneath the Sun, midnight opposite, and the person's own
/// time rides along it as a thumb, sliding as time winds on. Slid sideways, the map carries on
/// round the back of the World; pinched, it zooms in, the ribbon's hours spreading out with it so
/// they stay over their meridians. A zone or a country picked comes forward and its flag flies up
/// to its own hour. The land is drawn once for each view; the ribbon slides over it.
struct WorldTimeMap: View {
    /// The World in Miller's projection, centred on `centerLongitude`.
    var map: TravelMap
    var centerLongitude: Double
    var statuses: [String: VisitLevel]
    var focus: DialFocus?
    /// Whether the countries wear the colours of the times they keep rather than their levels, the
    /// clocks as they stand, and the countries spanning zones split into their parts.
    var byZone = false
    var zones: ZoneMoment
    var subdivisions: [TravelMap] = []
    /// The sea tinted with its time zones, once ready.
    var seaTint: SeaTint?
    /// The borders on land between places keeping different times, once ready.
    var zoneBorders: ZoneBorders? = nil
    var geometry: FlatGeometry
    /// How far in the map is zoomed and where, as it shows now, and as its land was last drawn: the
    /// land is moved and scaled the rest of the way while a pinch or a zoom is under way.
    var view = MapView.whole
    var drawnView = MapView.whole
    var sun: DayNight.Sun
    /// The person's own time of day, in hours, and as it's written.
    var hereHours: Double
    var hereTime: ClockWords.Time
    /// How far the time shown is from now, in hours, wound on or back; nil while it keeps the present.
    var wound: Double?
    /// How far the thumb is nudged along the ribbon, in hours, hinting that it slides; 0 at rest.
    var thumbNudge: Double = 0
    /// Just landed on a time, how far the ring going out round the thumb has spread, from 0 to 1.
    var thumbRing: Double? = nil
    /// The days either side of the date line, where it's drawn.
    var dateLineDays: DateLineDays?
    var selection: DialSelection?
    /// What was picked before, let go or given way to `selection`, its flag flying back home.
    var outgoing: DialSelection? = nil
    /// The moment drawn, for the flourishes as a country is tapped.
    var now: Date
    /// How much the ribbon and the markers show, each from 0 to 1.
    var ribbon: Double = 1
    var markers: Double = 1
    /// Whether to draw the map itself; while it reshapes into or out of the dial, that's drawn apart.
    var showsEarth = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let mapRect = geometry.mapRect
        let sunX = geometry.x(forLongitude: DayNight.normalized(sun.longitude - centerLongitude))
        let lap = mapRect.width * view.zoom
        // The land as last drawn, taken the rest of the way to the view shown.
        let step = view.zoom / drawnView.zoom
        // The whole World where it starts across the view, and again after it where the view runs
        // on round the back of the World.
        let wholeX = MapView.wrap(view.pan.width, from: -lap, lap: lap)
        ZStack(alignment: .topLeading) {
            // The ribbon and the map share one dark band, with no sky between.
            Rectangle()
                .fill(DialPalette.seaEdge)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .opacity(ribbon)
            ZStack(alignment: .topLeading) {
                earth(drawnFor: .whole)
                    .scaleEffect(view.zoom, anchor: .topLeading)
                    .offset(x: wholeX, y: view.pan.height)
                if wholeX + lap < mapRect.width - 0.5 {
                    earth(drawnFor: .whole)
                        .scaleEffect(view.zoom, anchor: .topLeading)
                        .offset(x: wholeX + lap, y: view.pan.height)
                }
                // Zoomed in, the land drawn crisply for the view lies over the whole World, which
                // carries on, if softly, wherever a pinch or a slide reaches beyond it.
                if drawnView.isZoomed {
                    earth(drawnFor: drawnView)
                        .scaleEffect(step, anchor: .topLeading)
                        .offset(x: view.pan.width - drawnView.pan.width * step, y: view.pan.height - drawnView.pan.height * step)
                }
                overlay(.earth, sunX: sunX)
            }
            .frame(width: mapRect.width, height: mapRect.height, alignment: .topLeading)
            .clipped()
            .offset(x: mapRect.minX, y: mapRect.minY)
            HourRibbon(geometry: geometry, usesTwelveHours: ClockWords.usesTwelveHours, sunX: sunX, view: view)
                .frame(width: geometry.ribbonRect.width, height: geometry.ribbonRect.height)
                .clipped()
                .opacity(ribbon)
                // The ribbon unrolls from noon outwards as it comes in; with Reduce Motion, it fades
                // in whole.
                .scaleEffect(x: reduceMotion ? 1 : 0.4 + 0.6 * ribbon, anchor: UnitPoint(x: sunX / max(geometry.size.width, 1), y: 0.5))
            overlay(.ribbon, sunX: sunX)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        // Blending into the page: fading out at its foot, and at its sides where it doesn't run from
        // edge to edge of the screen.
        .mask { PageBlend(fadesSides: geometry.cornerRadius > 0) }
    }

    /// The map drawn once for each view, kept in place while hidden so it's ready.
    private func earth(drawnFor drawn: MapView) -> some View {
        let key = "\(focus?.key ?? "")/\(subdivisions.count)/\(byZone && seaTint != nil)/\(byZone && zoneBorders != nil)"
        return ZStack {
            FlatEarth(
                map: map, centerLongitude: centerLongitude, statuses: statuses, focus: focus, byZone: byZone,
                zones: zones, subdivisions: subdivisions, seaTint: byZone ? seaTint : nil,
                zoneBorders: byZone ? zoneBorders : nil, geometry: geometry, view: drawn)
                .equatable()
                // A new focus cross-fades in, as do the countries spanning zones once their parts are
                // ready, and the sea once its zones are.
                .id(key)
                .transition(.opacity)
        }
        .animation(.smooth(duration: 0.35), value: key)
        .opacity(showsEarth ? 1 : 0)
    }

    private func overlay(_ layer: FlatOverlay.Layer, sunX: CGFloat) -> some View {
        FlatOverlay(
            layer: layer, geometry: geometry, view: view, centerLongitude: centerLongitude, sun: sun, sunX: sunX,
            hereHours: hereHours, hereTime: hereTime, wound: wound, thumbNudge: thumbNudge, thumbRing: thumbRing,
            dateLineDays: dateLineDays, selection: selection, outgoing: outgoing, now: now, markers: markers, isStill: reduceMotion)
    }
}

/// The flat map's measurements at a size: the ribbon of hours along the top, and the map beneath.
struct FlatGeometry: Equatable {
    /// The whole stage, ribbon and map.
    var size: CGSize
    /// How round the map's corners are: none where it runs from edge to edge of the screen.
    var cornerRadius: CGFloat = 16

    static let ribbonHeight: CGFloat = 30
    static let gap: CGFloat = 8
    /// The latitudes shown: from 58° south, which keeps Cape Horn and leaves out Antarctica, to 78° north.
    static let north = 78.0
    static let south = -58.0
    /// The map's top and foot, in Miller's units, north up.
    static let top = MapProjection.miller.project(CGPoint(x: 0, y: north)).y
    static let bottom = MapProjection.miller.project(CGPoint(x: 0, y: south)).y
    /// How wide the map is for how tall.
    static let aspect = 2 * Double.pi / (bottom - top)

    var ribbonRect: CGRect { CGRect(x: 0, y: 0, width: size.width, height: Self.ribbonHeight) }
    var mapRect: CGRect {
        CGRect(x: 0, y: Self.ribbonHeight + Self.gap, width: size.width, height: max(size.height - Self.ribbonHeight - Self.gap, 1))
    }

    /// Points per unit of the map, at its whole size.
    var scale: CGFloat { size.width / (2 * .pi) }

    /// From the map's units to the map's own space at its whole size, its top leading corner at the origin.
    var mapTransform: CGAffineTransform {
        CGAffineTransform(translationX: mapRect.width / 2, y: -Self.top * scale).scaledBy(x: scale, y: scale)
    }

    /// Where a point of the map lands on the stage, zoomed into and slid round as `view` has it:
    /// of its places round the World, the one nearest the middle of what shows.
    func stagePoint(_ point: CGPoint, view: MapView = .whole) -> CGPoint {
        let own = view.apply(point.applying(mapTransform))
        let lap = mapRect.width * view.zoom
        let x = MapView.wrap(own.x, from: mapRect.width / 2 - lap / 2, lap: lap)
        return CGPoint(x: mapRect.minX + x, y: mapRect.minY + own.y)
    }

    /// The point of the map under a point on the stage, zoomed into and slid round as `view` has it.
    func mapPoint(_ point: CGPoint, view: MapView = .whole) -> CGPoint {
        let own = view.unapply(CGPoint(x: point.x - mapRect.minX, y: point.y - mapRect.minY))
        let x = MapView.wrap(own.x, from: 0, lap: mapRect.width)
        return CGPoint(x: (x - mapRect.width / 2) / scale, y: own.y / scale + Self.top)
    }

    /// Where on the stage a longitude falls at the map's whole size, in degrees from its centre.
    func x(forLongitude degrees: Double) -> CGFloat {
        mapRect.midX + degrees * .pi / 180 * scale
    }

    /// Where a time of day falls on the ribbon at the map's whole size, noon over the Sun at `sunX`,
    /// brought onto the ribbon the way the day wraps round.
    func ribbonX(forHours hours: Double, sunX: CGFloat) -> CGFloat {
        var x = (sunX + (hours - 12) / 24 * size.width).truncatingRemainder(dividingBy: size.width)
        if x < 0 { x += size.width }
        return x
    }

    /// Where a time of day falls on the ribbon zoomed into as `view` has it: of the day's laps
    /// round, the one nearest the middle of what shows.
    func ribbonX(forHours hours: Double, sunX: CGFloat, view: MapView) -> CGFloat {
        let lap = size.width * view.zoom
        var x = ribbonX(forHours: hours, sunX: sunX) * view.zoom + view.pan.width
        while x - size.width / 2 > lap / 2 { x -= lap }
        while size.width / 2 - x > lap / 2 { x += lap }
        return x
    }

    /// The largest stage that fits in a space, keeping the map's shape.
    static func fitting(_ space: CGSize) -> CGSize {
        let byWidth = CGSize(width: space.width, height: ribbonHeight + gap + space.width / aspect)
        guard byWidth.height > space.height else { return byWidth }
        let width = max((space.height - ribbonHeight - gap) * aspect, 120)
        return CGSize(width: width, height: ribbonHeight + gap + width / aspect)
    }
}

/// How far into the flat map the person has zoomed, and where: a point of the map at its whole size
/// lands `zoom` times as far from the top leading corner, then moved by `pan`. Up and down the map
/// always fills its frame; sideways it runs on round the back of the World, a lap every `zoom`
/// times its width.
struct MapView: Equatable {
    var zoom: CGFloat = 1
    var pan: CGSize = .zero

    static let whole = MapView()
    /// As far in as the map goes.
    static let deepest: CGFloat = 6

    var isZoomed: Bool { zoom > 1.01 }

    /// Whether it's zoomed in or slid round from where the map starts.
    var isMoved: Bool { isZoomed || abs(pan.width) > 0.5 }

    func apply(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * zoom + pan.width, y: point.y * zoom + pan.height)
    }

    func unapply(_ point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x - pan.width) / zoom, y: (point.y - pan.height) / zoom)
    }

    var transform: CGAffineTransform {
        CGAffineTransform(translationX: pan.width, y: pan.height).scaledBy(x: zoom, y: zoom)
    }

    /// Zoomed by a factor about a point of the frame, which stays where it is, within the map's
    /// limits; as far in as `limit`, which a pinch stretches a little past the deepest, giving.
    func zoomed(by factor: CGFloat, about point: CGPoint, in size: CGSize, upTo limit: CGFloat = deepest) -> MapView {
        let zoom = min(max(self.zoom * factor, 1), limit)
        let change = zoom / self.zoom
        let pan = CGSize(width: point.x - (point.x - self.pan.width) * change, height: point.y - (point.y - self.pan.height) * change)
        return MapView(zoom: zoom, pan: pan).kept(in: size)
    }

    /// Moved by a finger's drag, within the map's limits.
    func moved(by translation: CGSize, in size: CGSize) -> MapView {
        MapView(zoom: zoom, pan: CGSize(width: pan.width + translation.width, height: pan.height + translation.height)).kept(in: size)
    }

    /// Kept so the map covers its frame from top to foot, and slid round no more than a lap.
    func kept(in size: CGSize) -> MapView {
        MapView(
            zoom: zoom,
            pan: CGSize(
                width: Self.wrap(pan.width, from: -size.width * zoom, lap: size.width * zoom),
                height: min(max(pan.height, size.height * (1 - zoom)), 0)))
    }

    /// A position brought round by whole laps to lie from `start` to a lap beyond it.
    static func wrap(_ x: CGFloat, from start: CGFloat, lap: CGFloat) -> CGFloat {
        guard lap > 0 else { return x }
        var value = (x - start).truncatingRemainder(dividingBy: lap)
        if value < 0 { value += lap }
        return start + value
    }

    /// Partway from one view to another, the short way round.
    static func mix(_ from: MapView, _ to: MapView, by t: CGFloat) -> MapView {
        MapView(
            zoom: from.zoom + (to.zoom - from.zoom) * t,
            pan: CGSize(width: from.pan.width + (to.pan.width - from.pan.width) * t, height: from.pan.height + (to.pan.height - from.pan.height) * t))
    }
}

// MARK: Layers

/// The map, drawn once for each country tapped and each view it's zoomed to.
private struct FlatEarth: View, Equatable {
    var map: TravelMap
    var centerLongitude: Double
    var statuses: [String: VisitLevel]
    var focus: DialFocus?
    var byZone: Bool
    var zones: ZoneMoment
    var subdivisions: [TravelMap]
    var seaTint: SeaTint?
    var zoneBorders: ZoneBorders?
    var geometry: FlatGeometry
    var view: MapView

    nonisolated static func == (a: FlatEarth, b: FlatEarth) -> Bool {
        a.centerLongitude == b.centerLongitude && a.geometry == b.geometry && a.focus == b.focus && a.statuses == b.statuses
            && a.byZone == b.byZone && a.zones == b.zones && a.subdivisions.count == b.subdivisions.count
            && a.seaTint == b.seaTint && a.zoneBorders == b.zoneBorders && a.view == b.view
            && a.map.regions.count == b.map.regions.count
    }

    var body: some View {
        let rect = CGRect(origin: .zero, size: geometry.mapRect.size)
        Canvas { context, _ in
            let lap = rect.width * view.zoom
            let first = MapView.wrap(view.pan.width, from: -lap, lap: lap)
            let starts = first + lap < rect.width - 0.5 ? [first, first + lap] : [first]
            let scale = geometry.scale * view.zoom
            let tall = rect.applying(view.transform)
            // The zones' meridians, straight down the map, and the land they keep off.
            let meridians = byZone
                ? WorldPainting.zoneMeridians(
                    in: .miller, centerLongitude: centerLongitude, south: FlatGeometry.south, north: FlatGeometry.north)
                : []
            let land = byZone ? WorldPainting.land(of: map) : Path()
            // The sea, deepest towards the poles.
            let equator = -FlatGeometry.top / (FlatGeometry.bottom - FlatGeometry.top)
            context.fill(
                Path(rect),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: DialPalette.seaEdge, location: 0),
                        .init(color: DialPalette.seaMiddle, location: equator),
                        .init(color: DialPalette.seaEdge, location: 1),
                    ]),
                    startPoint: CGPoint(x: rect.midX, y: tall.minY), endPoint: CGPoint(x: rect.midX, y: tall.maxY)))
            // Once where the view starts, and again round the back of the World where it runs on.
            for start in starts {
                let placed = MapView(zoom: view.zoom, pan: CGSize(width: start, height: view.pan.height))
                let transform = geometry.mapTransform.concatenating(placed.transform)
                let whole = rect.applying(placed.transform)
                // Coloured by time zone, the sea wears its zones too, bending round the coasts, softly
                // where they meet.
                if let seaTint {
                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: max(rect.width * view.zoom / 520, 1.5)))
                        layer.draw(Image(decorative: seaTint.image, scale: 1).interpolation(.high), in: whole)
                    }
                }
                if let graticule = map.graticule {
                    var lines = context
                    lines.concatenate(transform)
                    lines.stroke(graticule, with: .color(DialPalette.graticule), lineWidth: 0.6 / scale)
                }
                if byZone {
                    var lines = context
                    lines.clip(to: Path(rect))
                    lines.concatenate(transform)
                    WorldPainting.paintZoneMeridians(meridians, land: land, focus: focus?.offset, scale: scale, in: lines)
                }
                WorldPainting.paintCountries(
                    of: map, statuses: statuses, focus: focus, byZone: byZone, zones: zones, subdivisions: subdivisions,
                    zoneBorders: zoneBorders, transform: transform, scale: scale, clip: Path(rect), in: context)
                if byZone {
                    var line = context
                    line.clip(to: Path(rect))
                    line.concatenate(transform)
                    WorldPainting.paintDateLine(
                        WorldPainting.dateLine(in: .miller, centerLongitude: centerLongitude, south: FlatGeometry.south),
                        scale: scale, in: line)
                }
            }
        }
        .frame(width: rect.width, height: rect.height)
    }
}

/// The flat map's mask for blending into the page: solid, fading out over its last stretch at the
/// foot, and at the sides too where it doesn't run from edge to edge of the screen.
private struct PageBlend: View {
    var fadesSides: Bool

    var body: some View {
        VStack(spacing: 0) {
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 34)
        }
        .mask {
            HStack(spacing: 0) {
                LinearGradient(colors: [fadesSides ? .clear : .black, .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 28)
                Color.black
                LinearGradient(colors: [.black, fadesSides ? .clear : .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 28)
            }
        }
    }
}

/// The dial's ring laid straight: warm through the day at its middle, deep through the night at
/// either end, with a tick every hour, the hours every three, and the Sun at noon and the Moon at
/// midnight, noon over the meridian beneath the Sun at `sunX`. Zoomed into, the hours spread out
/// with the map, so each stays over its meridian, and the quarter hours get ticks of their own.
private struct HourRibbon: View {
    var geometry: FlatGeometry
    var usesTwelveHours: Bool
    var sunX: CGFloat
    var view: MapView

    var body: some View {
        let width = geometry.size.width
        let height = FlatGeometry.ribbonHeight
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.3)))
            let day = width * view.zoom
            // Where midnight falls, the day's start, for the day showing at the left edge.
            let midnight = (sunX - width / 2) * view.zoom + view.pan.width
            var start = midnight.truncatingRemainder(dividingBy: day)
            if start > 0 { start -= day }
            let type = Font.system(size: 11, weight: .semibold).monospacedDigit()
            // As the hours spread out, every hour gets its number, not just every third.
            let labelStep = view.zoom > 2.5 ? 1 : 3
            var dayStart = start
            while dayStart < width {
                var tinted = context
                tinted.opacity = 0.6
                tinted.fill(
                    Path(CGRect(x: dayStart, y: 0, width: day, height: height)),
                    with: .linearGradient(
                        Gradient(stops: WorldPainting.daylight), startPoint: CGPoint(x: dayStart, y: 0),
                        endPoint: CGPoint(x: dayStart + day, y: 0)))
                for quarter in 0..<96 {
                    let x = dayStart + day * CGFloat(quarter) / 96
                    guard x > -20, x < width + 20 else { continue }
                    if quarter % 4 == 0 {
                        let isMain = quarter % 24 == 0
                        var tick = Path()
                        tick.move(to: CGPoint(x: x, y: height - 2))
                        tick.addLine(to: CGPoint(x: x, y: height - (isMain ? 8 : 5)))
                        context.stroke(
                            tick, with: .color(.white.opacity(isMain ? 0.8 : 0.5)),
                            style: StrokeStyle(lineWidth: isMain ? 1.4 : 1, lineCap: .round))
                    } else {
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 0.6, y: height - 3.6, width: 1.2, height: 1.2)),
                            with: .color(.white.opacity(0.3)))
                    }
                }
                for hour in stride(from: 0, to: 24, by: labelStep) {
                    let x = dayStart + day * CGFloat(hour) / 24
                    guard x > -20, x < width + 20 else { continue }
                    let label: Text
                    switch hour {
                    case 12:
                        label = Text(Image(systemName: "sun.max.fill")).foregroundStyle(Color(red: 1, green: 0.86, blue: 0.5))
                    case 0:
                        label = Text(Image(systemName: "moon.fill")).foregroundStyle(Color(red: 0.78, green: 0.84, blue: 1))
                    default:
                        let shown = usesTwelveHours ? (hour % 12 == 0 ? 12 : hour % 12) : hour
                        label = Text(shown, format: .number).foregroundStyle(.white.opacity(0.85))
                    }
                    context.draw(label.font(type), at: CGPoint(x: x, y: height * 0.42), anchor: .center)
                }
                dayStart += day
            }
        }
        .frame(width: width, height: height)
    }
}

/// What moves at every frame on the flat map, in two layers: the lights and a tapped country's
/// ripple on the map, and over the ribbon the person's own time and the tapped country's flag and hours.
private struct FlatOverlay: View {
    enum Layer {
        /// On the map, in its own space.
        case earth
        /// Over the ribbon, in the stage's space.
        case ribbon
    }

    var layer: Layer
    var geometry: FlatGeometry
    var view: MapView
    var centerLongitude: Double
    var sun: DayNight.Sun
    /// Where the meridian beneath the Sun crosses the stage, at the map's whole size.
    var sunX: CGFloat
    var hereHours: Double
    var hereTime: ClockWords.Time
    var wound: Double?
    var thumbNudge: Double
    var thumbRing: Double?
    var dateLineDays: DateLineDays?
    var selection: DialSelection?
    /// What was picked before, let go or given way to `selection`, drawing back in beneath it.
    var outgoing: DialSelection?
    var now: Date
    var markers: Double
    var isStill: Bool

    var body: some View {
        Canvas { context, _ in
            switch layer {
            case .earth:
                if let dateLineDays { drawDateLineDays(dateLineDays, in: context) }
                if let selection { drawRipple(for: selection, in: context) }
            case .ribbon:
                guard markers > 0.01 else { return }
                var marked = context
                marked.opacity = markers
                if let wound { drawWound(wound, in: marked) }
                if let outgoing { drawSelection(outgoing, in: marked) }
                if let selection { drawSelection(selection, in: marked) }
                drawHere(in: marked)
            }
        }
        .frame(
            width: layer == .earth ? geometry.mapRect.width : geometry.size.width,
            height: layer == .earth ? geometry.mapRect.height : geometry.size.height)
        .allowsHitTesting(false)
    }

    /// A point of the map in the map's own space, zoomed into and slid round as the view has it, a
    /// little way past either side included.
    private func onMap(_ point: CGPoint) -> CGPoint {
        let own = view.apply(point.applying(geometry.mapTransform))
        return CGPoint(x: MapView.wrap(own.x, from: -24, lap: geometry.mapRect.width * view.zoom), y: own.y)
    }

    /// A ring of light spreading out from the country tapped, fading as it goes.
    private func drawRipple(for selection: DialSelection, in context: GraphicsContext) {
        let elapsed = now.timeIntervalSince(selection.start)
        guard elapsed < 1, !isStill, selection.leaving == nil else { return }
        WorldPainting.paintRipple(
            at: onMap(selection.mapPoint), reach: geometry.mapRect.height * 0.45, progress: max(elapsed, 0),
            color: selection.color ?? .white, in: context)
    }

    /// The person's own time, riding along the ribbon at their hour as its thumb, amber once wound
    /// away from now, a ring going out round it as time lands.
    private func drawHere(in context: GraphicsContext) {
        let point = CGPoint(x: geometry.ribbonX(forHours: hereHours + thumbNudge, sunX: sunX, view: view), y: geometry.ribbonRect.midY)
        WorldPainting.paintTimeThumb(
            hereTime, at: point, height: FlatGeometry.ribbonHeight - 6, isLive: wound == nil,
            within: geometry.ribbonRect.insetBy(dx: 3, dy: 0), landing: thumbRing, in: context)
    }

    /// Wound away from now: the stretch of the ribbon from now along to the time shown, lit, and now
    /// itself pinned to the ribbon, so it's plain at a glance that the time shown isn't the present.
    private func drawWound(_ hours: Double, in context: GraphicsContext) {
        let ribbon = geometry.ribbonRect
        let lap = geometry.size.width * view.zoom
        let end = geometry.ribbonX(forHours: hereHours, sunX: sunX, view: view)
        let run = min(max(hours, -24), 24) / 24 * lap
        let start = end - run
        var lit = context
        lit.clip(to: Path(ribbon))
        for shift in [-lap, 0, lap] {
            var band = Path()
            band.move(to: CGPoint(x: start + shift, y: ribbon.midY))
            band.addLine(to: CGPoint(x: end + shift, y: ribbon.midY))
            lit.stroke(
                band, with: .color(WorldPainting.wound.opacity(0.42)), style: StrokeStyle(lineWidth: ribbon.height * 0.6, lineCap: .round))
        }
        let nowX = MapView.wrap(start, from: 0, lap: lap)
        if nowX < geometry.size.width {
            WorldPainting.paintNowPin(
                at: CGPoint(x: nowX, y: ribbon.midY), height: ribbon.height * 0.56, within: ribbon.insetBy(dx: 3, dy: 0), in: context)
        }
    }

    /// The days either side of the date line, just to each side of it where it runs straight down
    /// the 180th meridian.
    private func drawDateLineDays(_ days: DateLineDays, in context: GraphicsContext) {
        let line = onMap(MapProjection.miller.project(CGPoint(x: DayNight.normalized(180 - centerLongitude), y: 24)))
        // Near either side of the map, the line shows again round the other, a day's tag on each.
        let lap = geometry.mapRect.width * view.zoom
        for x in [line.x - lap, line.x, line.x + lap] where x > -60 && x < geometry.mapRect.width + 60 {
            WorldPainting.paintDay(days.west, at: CGPoint(x: x - 5, y: line.y), anchor: .trailing, in: context)
            WorldPainting.paintDay(days.east, at: CGPoint(x: x + 5, y: line.y), anchor: .leading, in: context)
        }
    }

    /// The tapped country on the ribbon: the hours its zones cover, a line from the person's hour
    /// along to its own, and its flag flying up from the map to that hour, a small ring going out
    /// round it as it lands. Let go, the flag flies back down home and the line and hours draw back
    /// in after it.
    private func drawSelection(_ selection: DialSelection, in context: GraphicsContext) {
        let width = geometry.size.width
        let lap = width * view.zoom
        let ribbon = geometry.ribbonRect
        let elapsed = now.timeIntervalSince(selection.start)
        let (arrival, shown) = selection.arrival(at: now, isStill: isStill)
        guard shown > 0.001 else { return }
        var context = context
        context.opacity *= shown
        let isLeaving = selection.leaving != nil
        let tint = selection.color ?? .white
        var clipped = context
        clipped.clip(to: Path(roundedRect: ribbon, cornerRadius: min(geometry.cornerRadius, ribbon.height / 2)))

        // The hours its zones cover, as a band of its colour along the ribbon.
        if !selection.otherHours.isEmpty {
            let all = [selection.hours] + selection.otherHours
            let span = Self.shortestSpan(of: all)
            let start = geometry.ribbonX(forHours: span.start, sunX: sunX, view: view)
            let length = span.length / 24 * lap * arrival
            for shift in [-lap, 0, lap] {
                var band = Path()
                band.move(to: CGPoint(x: start + shift, y: ribbon.midY))
                band.addLine(to: CGPoint(x: start + shift + length, y: ribbon.midY))
                clipped.stroke(band, with: .color(tint.opacity(0.45)), style: StrokeStyle(lineWidth: ribbon.height * 0.62, lineCap: .round))
            }
            for hours in all {
                let x = geometry.ribbonX(forHours: hours, sunX: sunX, view: view)
                context.fill(
                    Path(ellipseIn: CGRect(x: x - 2, y: ribbon.midY - 2, width: 4, height: 4)), with: .color(.white.opacity(0.9 * arrival)))
            }
        }

        // From the person's hour along to the country's, the way time runs to it, under the ribbon;
        // let go, it draws back in with the flag.
        let sweep = isStill ? 1 : isLeaving ? arrival : min(max((elapsed - 0.25) / 0.6, 0), 1)
        if abs(selection.hoursAhead) > 0.01, sweep > 0 {
            let eased = 1 - pow(1 - sweep, 3)
            let start = geometry.ribbonX(forHours: hereHours, sunX: sunX, view: view)
            let end = start + selection.hoursAhead / 24 * lap * eased
            var underneath = context
            underneath.clip(to: Path(CGRect(x: 0, y: ribbon.maxY, width: width, height: FlatGeometry.gap)))
            for shift in [-lap, 0, lap] {
                var line = Path()
                line.move(to: CGPoint(x: start + shift, y: ribbon.maxY + 3))
                line.addLine(to: CGPoint(x: end + shift, y: ribbon.maxY + 3))
                underneath.stroke(line, with: .color(.white.opacity(0.75)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }

        // Its flag, flying up from the country to its hour with a little overshoot, or let go,
        // gliding smoothly back home.
        let origin = geometry.stagePoint(selection.mapPoint, view: view)
        let target = CGPoint(x: geometry.ribbonX(forHours: selection.hours, sunX: sunX, view: view), y: ribbon.midY)
        let travel = isLeaving ? arrival * arrival * (3 - 2 * arrival) : Self.overshoot(arrival)
        let point = CGPoint(x: origin.x + (target.x - origin.x) * travel, y: origin.y + (target.y - origin.y) * travel)
        let radius = ribbon.height * 0.46 * (0.45 + 0.55 * min(arrival * 1.6, 1))
        // Landed, a small ring goes out round it, as the landing is felt.
        if let ring = selection.landingRing(at: now, isStill: isStill) {
            WorldPainting.paintRipple(at: target, reach: ribbon.height * 1.1, progress: ring, color: tint, in: context)
        }
        let chip = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        var shadow = context
        shadow.addFilter(.shadow(color: .black.opacity(0.45), radius: 3, y: 1.5))
        shadow.fill(chip, with: .color(.white))
        var flag = context
        flag.clip(to: chip)
        let image = context.resolve(Image(selection.flagAssetName))
        if image.size.width > 0, image.size.height > 0 {
            let fill = max(radius * 2 / image.size.width, radius * 2 / image.size.height)
            let drawn = CGSize(width: image.size.width * fill, height: image.size.height * fill)
            flag.draw(image, in: CGRect(x: point.x - drawn.width / 2, y: point.y - drawn.height / 2, width: drawn.width, height: drawn.height))
        }
        context.stroke(chip, with: .color(.white), lineWidth: 1.6)
    }

    /// The shortest stretch of the day holding every one of some times: where it starts, in hours,
    /// and how many hours it runs on.
    private static func shortestSpan(of hours: [Double]) -> (start: Double, length: Double) {
        let sorted = hours.map { ($0.truncatingRemainder(dividingBy: 24) + 24).truncatingRemainder(dividingBy: 24) }.sorted()
        guard sorted.count > 1 else { return (sorted.first ?? 0, 0) }
        // The widest gap between neighbours is the part of the day left out.
        var widest = (gap: 24 - sorted[sorted.count - 1] + sorted[0], end: 0)
        for index in 1..<sorted.count where sorted[index] - sorted[index - 1] > widest.gap {
            widest = (sorted[index] - sorted[index - 1], index)
        }
        return (sorted[widest.end], 24 - widest.gap)
    }

    /// Eases out past the end and back, for something landing with a little bounce.
    private static func overshoot(_ t: Double) -> Double {
        let c1 = 1.4, c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
}
