import SwiftUI

/// World Time's dial: the World seen from above the North Pole, turning beneath the Sun inside a
/// ring of the day's 24 hours, noon at the top and midnight at the foot. The night side lies in
/// shadow, deepening through twilight, and the capitals' lights come on along the dusk. A dot on
/// the ring marks the person's own hour. A country tapped lifts off the World with the countries
/// keeping its time brought forward, and its flag flies out to its hour on the ring, an arc
/// running round from the person's hour to it; a country spanning several zones lights the hours
/// they cover. A zone picked brings its countries forward the same way. The Earth and the ring are
/// drawn once and turned, so winding time stays smooth.
struct WorldTimeDial: View {
    /// The World in the polar projection, the North Pole at its middle.
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
    var geometry: DialGeometry
    /// How far the Earth is turned, in degrees clockwise, putting the meridian under the Sun at the top.
    var rotation: Double
    var sun: DayNight.Sun
    /// The person's own time of day, in hours, and as it's written.
    var hereHours: Double
    var hereTime: ClockWords.Time
    /// How far the time shown is from now, in hours, wound on or back; nil while it keeps the present.
    var wound: Double?
    /// How far the thumb is nudged along the ring, in hours, hinting that it slides; 0 at rest.
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
    /// How much the night, the ring and the markers show, each from 0 to 1, as the dial opens and closes.
    var night: Double = 1
    var ring: Double = 1
    var markers: Double = 1
    /// Whether to draw the Earth itself; while it curls up out of the list's map, that's drawn apart.
    var showsEarth = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let size = geometry.size
        ZStack {
            earth()
            // The night keeps to the far side from the Sun, which stays over noon on the ring, the
            // whole face turned however the person has turned it.
            DialNight(declination: (sun.latitude * 10).rounded() / 10, geometry: geometry)
                .equatable()
                .rotationEffect(.degrees(geometry.turn))
                .opacity(night)
            overlay(.earth)
            DialBezel(geometry: geometry, usesTwelveHours: ClockWords.usesTwelveHours)
                .equatable()
                // The ring draws itself in round the dial, the way time runs, from noon; with Reduce
                // Motion, it fades in whole.
                .mask {
                    Circle()
                        .trim(from: 0, to: reduceMotion ? 1 : ring)
                        .stroke(lineWidth: size)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(x: -1)
                        .rotationEffect(.degrees(geometry.turn))
                }
                .opacity(reduceMotion ? ring : min(ring * 3, 1))
            overlay(.ring)
        }
        .frame(width: size, height: size)
    }

    /// The Earth, drawn once and turned, kept in place while hidden so it's ready.
    private func earth() -> some View {
        let key = "\(focus?.key ?? "")/\(subdivisions.count)/\(byZone && seaTint != nil)/\(byZone && zoneBorders != nil)"
        return ZStack {
            DialEarth(
                map: map, centerLongitude: centerLongitude, statuses: statuses, focus: focus, byZone: byZone,
                zones: zones, subdivisions: subdivisions, seaTint: byZone ? seaTint : nil,
                zoneBorders: byZone ? zoneBorders : nil, geometry: geometry)
                .equatable()
                // A new focus cross-fades in, as do the countries spanning zones once their parts are
                // ready, and the sea once its zones are.
                .id(key)
                .transition(.opacity)
        }
        .rotationEffect(.degrees(rotation + geometry.turn))
        .animation(.smooth(duration: 0.35), value: key)
        .opacity(showsEarth ? 1 : 0)
    }

    private func overlay(_ layer: DialOverlay.Layer) -> some View {
        DialOverlay(
            layer: layer, geometry: geometry, rotation: rotation, centerLongitude: centerLongitude, sun: sun,
            hereHours: hereHours, hereTime: hereTime, wound: wound, thumbNudge: thumbNudge, thumbRing: thumbRing,
            dateLineDays: dateLineDays, selection: selection, outgoing: outgoing, now: now, night: night, markers: markers,
            isStill: reduceMotion)
    }
}

/// The dial's measurements at a size: the ring of hours around the edge and the Earth within it,
/// and how far the person has turned the face.
struct DialGeometry: Equatable {
    /// The dial's width across, ring and all.
    var size: CGFloat
    /// How far the whole face is turned, in degrees clockwise: the Earth, its night and the ring of
    /// hours together, so the hours still fall over their meridians wherever noon has gone.
    var turn: Double = 0

    var radius: CGFloat { size / 2 }
    var ringWidth: CGFloat { min(max(size * 0.085, 26), 40) }
    var discRadius: CGFloat { radius - ringWidth - 3 }
    var center: CGPoint { CGPoint(x: radius, y: radius) }

    /// How far out the Earth's edge lies, in the polar map's units: 60 degrees south, so the
    /// southern lands keep their room and Antarctica, which would ring the edge, is left out.
    static let extent = 5 * Double.pi / 6

    /// Screen points per unit of the polar map.
    var scale: CGFloat { discRadius / Self.extent }

    /// The angle on screen of a time of day on the ring, in degrees clockwise from three o'clock:
    /// noon at the top of the face, and the hours running anticlockwise, the way the Earth turns.
    func angle(forHours hours: Double) -> Double {
        -90 - (hours - 12) * 15 + turn
    }

    /// A point on the ring at an angle, `depth` running from its inner edge at 0 to its outer at 1.
    func ringPoint(angle: Double, depth: Double = 0.5) -> CGPoint {
        let distance = radius - ringWidth + ringWidth * depth
        let radians = angle * .pi / 180
        return CGPoint(x: center.x + distance * cos(radians), y: center.y + distance * sin(radians))
    }

    /// Where a point of the polar map lands on the dial with the Earth turned by `rotation` degrees,
    /// and the face as the person has turned it.
    func screenPoint(_ point: CGPoint, rotation: Double) -> CGPoint {
        let radians = (rotation + turn) * .pi / 180
        let x = point.x * scale, y = point.y * scale
        return CGPoint(x: center.x + x * cos(radians) - y * sin(radians), y: center.y + x * sin(radians) + y * cos(radians))
    }

    /// The point of the polar map under a point on the dial.
    func mapPoint(_ point: CGPoint, rotation: Double) -> CGPoint {
        let radians = -(rotation + turn) * .pi / 180
        let x = point.x - center.x, y = point.y - center.y
        return CGPoint(
            x: (x * cos(radians) - y * sin(radians)) / scale, y: (x * sin(radians) + y * cos(radians)) / scale)
    }

    /// From the polar map's units into the dial's points, before the Earth turns.
    var mapTransform: CGAffineTransform {
        CGAffineTransform(translationX: radius, y: radius).scaledBy(x: scale, y: scale)
    }
}

/// The countries keeping one time, brought forward while the rest of the World steps back: those
/// keeping a tapped country's time, which lifts off the World, or a zone picked from the list.
struct DialFocus: Equatable {
    /// Tells one focus from another, so the World can cross-fade between them.
    var key: String
    /// The country tapped, if a country was.
    var placeID: String?
    /// Countries whose own time it is.
    var sameTime: Set<String>
    /// Countries with only some of their zones on that time, such as Russia for Japan's.
    var partlySameTime: Set<String>
    /// The time itself, in seconds ahead of UTC, so the parts of countries keeping it come forward.
    var offset: Int?

    /// How strongly a country shows: fully for the tapped one and those keeping the time, partly
    /// for those keeping it in some zones, and faintly for the rest.
    func presence(of id: String) -> Double {
        if id == placeID || sameTime.contains(id) { return 1 }
        return partlySameTime.contains(id) ? 0.7 : 0.3
    }
}

/// What's picked, as the ring shows it: the flag of the country tapped, or of the place a zone is
/// known by, at its hour, and the hours its zones span.
struct DialSelection {
    var flagAssetName: String
    /// Its level's colour, or nil before it has one.
    var color: Color?
    /// Its own time of day, in hours, then each of its other zones'.
    var hours: Double
    var otherHours: [Double]
    /// How far ahead of the person's own its clocks are, in hours.
    var hoursAhead: Double
    /// Where it lies on the polar map, for its flag to fly out from.
    var mapPoint: CGPoint
    /// When it was tapped, for its flourishes.
    var start: Date
    /// When it was let go, if it has been: its flag flies back home from its hour, its arc and hours
    /// drawing back in after it, over `retreat`; with Reduce Motion, it fades where it is over `fade`.
    var leaving: Date? = nil

    /// How long its flag takes to fly out and land on its hour, where a ring goes out and the
    /// landing is felt.
    static let landing: TimeInterval = 0.6
    /// How long its ring takes to spread out from the hour and fade once the flag has landed.
    static let landingRing: TimeInterval = 0.5
    /// How long it takes to draw back in once let go, and with Reduce Motion, to fade.
    static let retreat: TimeInterval = 0.3
    static let fade: TimeInterval = 0.2

    /// How far its flag has flown out from the place to its hour at a moment, from 0 to 1, and how
    /// much of it shows: out over `landing` as it's picked, and back in over `retreat` once it's
    /// let go, fading as it reaches home. With Reduce Motion it's simply at its hour, and once let
    /// go, fades there.
    func arrival(at now: Date, isStill: Bool) -> (progress: Double, opacity: Double) {
        if let leaving {
            let gone = max(now.timeIntervalSince(leaving), 0)
            guard !isStill else { return (1, 1 - min(gone / Self.fade, 1)) }
            let left = 1 - min(gone / Self.retreat, 1)
            return (left, min(left * 2.5, 1))
        }
        guard !isStill else { return (1, 1) }
        return (min(max((now.timeIntervalSince(start) - 0.05) / (Self.landing - 0.05), 0), 1), 1)
    }

    /// Where the ring sent out from its hour as the flag lands has spread to, from 0 to 1, or nil
    /// before the flag lands, once the ring has faded, and with Reduce Motion or once it's let go.
    func landingRing(at now: Date, isStill: Bool) -> Double? {
        guard !isStill, leaving == nil else { return nil }
        let since = now.timeIntervalSince(start) - Self.landing
        guard since >= 0, since < Self.landingRing else { return nil }
        return since / Self.landingRing
    }
}

/// The dial's colours: a deep sea, pale land and fine dark borders, as the World looks from space,
/// so places lit in their levels' colours glow against it.
enum DialPalette {
    static let seaMiddle = Color(red: 0.11, green: 0.24, blue: 0.46)
    static let seaEdge = Color(red: 0.03, green: 0.08, blue: 0.19)
    /// The sea flat, between the two, for the map curling up before its depth comes in.
    static let sea = Color(red: 0.07, green: 0.17, blue: 0.36)
    static let land = Color(red: 0.80, green: 0.86, blue: 0.94)
    static let border = Color(red: 0.05, green: 0.12, blue: 0.27)
    static let graticule = Color.white.opacity(0.07)
    static let night = Color(red: 0, green: 0.01, blue: 0.05)
    static let lamp = Color(red: 1, green: 0.83, blue: 0.5)
    /// Antarctica would ring the dial's edge, so it's left out.
    static let antarcticaID = "WORLD-AQ"
}

/// The clocks around the World as they stand at a moment, for colouring the World by time zone and
/// bringing forward just the parts of a country keeping a time. Told apart only by the offsets kept
/// everywhere, so a layer drawn from one is redrawn only as some clock changes, not every hour.
struct ZoneMoment: Equatable {
    var date: Date
    /// Every offset kept, by every place and every part of a country spanning zones, together.
    var signature: Int

    nonisolated static func == (a: ZoneMoment, b: ZoneMoment) -> Bool {
        a.signature == b.signature
    }
}

/// The colours of a map of the world's time zones: soft pastels, a different one for each hour so
/// neighbouring zones stand apart, as on the time zone maps of old atlases. A zone half or three
/// quarters of an hour off sits between its neighbours' colours, a shade deeper.
enum ZonePalette {
    /// Peach, butter, sage, sky, lavender and rose, going round.
    private static let hours: [SIMD3<Double>] = [
        SIMD3(0.97, 0.78, 0.62), SIMD3(0.95, 0.88, 0.60), SIMD3(0.73, 0.87, 0.68),
        SIMD3(0.66, 0.84, 0.90), SIMD3(0.78, 0.76, 0.93), SIMD3(0.94, 0.72, 0.80),
    ]

    /// The colour of a time, by how far ahead of UTC it is, in seconds.
    static func color(forOffset offset: Int) -> Color {
        let shade = components(forOffset: offset)
        return Color(red: shade.x, green: shade.y, blue: shade.z)
    }

    /// The same colour as red, green and blue, from 0 to 1.
    static func components(forOffset offset: Int) -> SIMD3<Double> {
        let hour = Int((Double(offset) / 3600).rounded(.down))
        let index = ((hour % hours.count) + hours.count) % hours.count
        guard offset != hour * 3600 else { return hours[index] }
        return (hours[index] + hours[(index + 1) % hours.count]) / 2 * 0.9
    }
}

/// How World Time paints the World, on the dial and on its flat map alike.
enum WorldPainting {
    /// How deep the night lies at twilight's steps, the Sun just set and then each of civil,
    /// nautical and astronomical twilight's ends, deepening one over another.
    static let nightDepths = [0.32, 0.22, 0.18, 0.16]

    /// The countries, each in its level's colour or pale land, or by time zone, in the colour of
    /// the time it keeps, those out of focus stepping back, with fine dark borders; the country
    /// tapped lifts a little off the World, outlined in light. `transform` takes the map's units to
    /// the screen, `scale` points per unit, and `clip` is the area on screen they keep to.
    ///
    /// The countries spanning several zones are split along their subdivisions, from `subdivisions`
    /// in the same projection: coloured by time zone, each part wears its own time's colour, and
    /// with a time in focus, only the parts keeping it come forward, so picking Irkutsk time
    /// brings forward Irkutsk and Buryatia rather than all of Russia.
    static func paintCountries(
        of map: TravelMap, statuses: [String: VisitLevel], focus: DialFocus?, byZone: Bool, zones: ZoneMoment,
        subdivisions: [TravelMap], zoneBorders: ZoneBorders? = nil, transform: CGAffineTransform, scale: CGFloat, clip: Path,
        in context: GraphicsContext
    ) {
        var earth = context
        earth.clip(to: clip)
        earth.concatenate(transform)
        let date = zones.date
        func color(of id: String) -> Color {
            if byZone {
                guard let clock = mainClocks[id] else { return DialPalette.land }
                return ZonePalette.color(forOffset: clock.offset(at: date))
            }
            let level = statuses[id] ?? .never
            return level == .never ? DialPalette.land : level.color
        }
        // The countries drawn part by part, each with its parts' clocks.
        var split: [String: [(region: MapRegion, offset: Int)]] = [:]
        for subdivided in subdivisions {
            guard let first = subdivided.regions.first else { continue }
            let country = "WORLD-\(first.id.prefix { $0 != "-" })"
            guard let main = mainClocks[country] else { continue }
            let isFocused = focus.map { $0.placeID != country && ($0.sameTime.contains(country) || $0.partlySameTime.contains(country)) }
            guard byZone || isFocused == true else { continue }
            split[country] = subdivided.regions.map { region in
                (region, (TimeZoneAtlas.clock(ofSubdivision: region.id) ?? main).offset(at: date))
            }
        }
        let regions = map.regions.filter { $0.id != DialPalette.antarcticaID }
        for region in regions {
            guard let parts = split[region.id] else {
                earth.fill(region.path, with: .color(color(of: region.id).opacity(focus?.presence(of: region.id) ?? 1)), style: FillStyle(eoFill: true))
                continue
            }
            // As a whole, under its parts so no seam between them shows, stepping back unless it's the
            // one tapped; then the parts keeping the time in focus brought forward.
            let stepsBack = focus.map { $0.placeID != region.id } ?? false
            var whole = earth
            whole.opacity = stepsBack ? 0.3 : 1
            whole.drawLayer { layer in
                layer.fill(region.path, with: .color(color(of: region.id)), style: FillStyle(eoFill: true))
                guard byZone else { return }
                for part in parts {
                    layer.fill(part.region.path, with: .color(ZonePalette.color(forOffset: part.offset)), style: FillStyle(eoFill: true))
                }
            }
            if stepsBack, let offset = focus?.offset {
                for part in parts where part.offset == offset {
                    let fill = byZone ? ZonePalette.color(forOffset: part.offset) : color(of: region.id)
                    earth.fill(part.region.path, with: .color(fill), style: FillStyle(eoFill: true))
                }
            }
        }
        for region in regions {
            earth.stroke(region.path, with: .color(DialPalette.border), lineWidth: 0.5 / scale)
        }
        // Over the countries' own borders, those between places keeping different times.
        if byZone, let zoneBorders {
            paintZoneBorders(zoneBorders, hasFocus: focus != nil, scale: scale, in: earth)
        }
        guard let id = focus?.placeID, let region = map.region(id: id) else { return }
        let body = region.mainBody.applying(transform)
        let middle = CGPoint(x: body.boundingRect.midX, y: body.boundingRect.midY)
        let lift = CGAffineTransform(translationX: middle.x, y: middle.y - 1.5)
            .scaledBy(x: 1.06, y: 1.06)
            .translatedBy(x: -middle.x, y: -middle.y)
        let lifted = body.applying(lift)
        var layer = context
        layer.clip(to: clip)
        layer.drawLayer { shadowed in
            shadowed.addFilter(.shadow(color: .black.opacity(0.55), radius: 5, y: 2.5))
            shadowed.fill(lifted, with: .color(color(of: region.id)), style: FillStyle(eoFill: true))
        }
        // Lifted, a country split by its zones keeps its parts' colours.
        if byZone, let parts = split[region.id] {
            var inside = layer
            inside.clip(to: lifted, style: FillStyle(eoFill: true))
            for part in parts {
                inside.fill(
                    part.region.path.applying(transform.concatenating(lift)),
                    with: .color(ZonePalette.color(forOffset: part.offset)), style: FillStyle(eoFill: true))
            }
        }
        layer.stroke(lifted, with: .color(.white), lineWidth: 1.4)
    }

    /// The amber of a time wound away from now, on the thumb and along the hours between.
    static let wound = Color(red: 1, green: 0.76, blue: 0.3)

    /// The person's own time as a thumb on a ring or ribbon of hours, where their hour falls: a
    /// capsule holding the time between two small chevrons, there to be slid, white at the present
    /// and amber once wound away from it, lifted off the hours by a soft shadow. Near an edge of
    /// `bounds`, it keeps inside them rather than being cut off. Just landed on a time, a ring of
    /// its colour goes out round it and fades, as round a flag landing on its hour, `landing`
    /// running from 0 to 1.
    static func paintTimeThumb(
        _ time: ClockWords.Time, at point: CGPoint, height: CGFloat, isLive: Bool = true, within bounds: CGRect? = nil,
        landing: Double? = nil, in context: GraphicsContext
    ) {
        let ink = DialPalette.border
        let digits = Text(time.digits)
            .font(.system(size: height * 0.58, weight: .semibold, design: .rounded).monospacedDigit())
        let words: Text
        if let period = time.period {
            let part = Text(period).font(.system(size: height * 0.4, weight: .bold, design: .rounded))
            words = time.periodFirst ? Text("\(part) \(digits)") : Text("\(digits) \(part)")
        } else {
            words = digits
        }
        let label = context.resolve(words.foregroundStyle(ink))
        let size = label.measure(in: CGSize(width: 400, height: height))
        let grip = height * 0.34
        var rect = CGRect(
            x: point.x - size.width / 2 - height * 0.32 - grip, y: point.y - height / 2,
            width: size.width + height * 0.64 + grip * 2, height: height)
        if let bounds { rect = rect.kept(in: bounds) }
        let capsule = Path(roundedRect: rect, cornerRadius: height / 2)
        if let landing {
            // The capsule's own outline, spreading out from under it, easing out, softly blurred.
            let spread = height * 1.1 * (1 - pow(1 - landing, 3))
            let ring = rect.insetBy(dx: -spread, dy: -spread)
            var glow = context
            glow.addFilter(.blur(radius: 1.5))
            glow.stroke(
                Path(roundedRect: ring, cornerRadius: ring.height / 2),
                with: .color((isLive ? Color.white : wound).opacity(0.85 * (1 - landing))), lineWidth: 1.5 + 4 * (1 - landing))
        }
        var shadow = context
        shadow.addFilter(.shadow(color: (isLive ? Color.black : wound).opacity(0.45), radius: isLive ? 3 : 6, y: 1.5))
        shadow.fill(capsule, with: .color(isLive ? .white : wound))
        context.draw(label, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
        for (symbol, x) in [("chevron.compact.left", rect.minX + height * 0.24 + grip / 2), ("chevron.compact.right", rect.maxX - height * 0.24 - grip / 2)] {
            context.draw(
                Text(Image(systemName: symbol)).font(.system(size: height * 0.42, weight: .heavy)).foregroundStyle(ink.opacity(0.38)),
                at: CGPoint(x: x, y: rect.midY), anchor: .center)
        }
    }

    /// Where now is on a ring or ribbon of hours, once time's been wound away from it: a small pin
    /// with the word, kept inside `bounds`.
    static func paintNowPin(at point: CGPoint, height: CGFloat, within bounds: CGRect? = nil, in context: GraphicsContext) {
        let label = context.resolve(
            Text("Now").font(.system(size: height * 0.58, weight: .bold, design: .rounded)).foregroundStyle(.white))
        let size = label.measure(in: CGSize(width: 200, height: height))
        var rect = CGRect(x: point.x - size.width / 2 - height * 0.4, y: point.y - height / 2, width: size.width + height * 0.8, height: height)
        if let bounds { rect = rect.kept(in: bounds) }
        let capsule = Path(roundedRect: rect, cornerRadius: height / 2)
        context.fill(capsule, with: .color(.black.opacity(0.55)))
        context.stroke(capsule, with: .color(.white.opacity(0.7)), lineWidth: 1)
        context.draw(label, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }

    /// A ring of light spreading out from a point and fading as it goes, `progress` running from 0
    /// to 1: out to `reach` beyond a small start, easing out, softly blurred. A country tapped sends
    /// a wide one out across the World; a flag landing on its hour, a small one round it.
    static func paintRipple(at origin: CGPoint, reach: CGFloat, progress: Double, color: Color, in context: GraphicsContext) {
        let eased = 1 - pow(1 - progress, 3)
        let radius = 6 + reach * eased
        var ring = context
        ring.addFilter(.blur(radius: 1.5))
        ring.stroke(
            Path(ellipseIn: CGRect(x: origin.x - radius, y: origin.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(color.opacity(0.85 * (1 - progress))), lineWidth: 1.5 + 4 * (1 - progress))
    }

    /// A day by the date line, as a small dark tag.
    static func paintDay(_ day: String, at point: CGPoint, anchor: UnitPoint, in context: GraphicsContext) {
        let label = context.resolve(
            Text(day).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.9)))
        let size = label.measure(in: CGSize(width: 200, height: 40))
        let width = size.width + 10, height = size.height + 4
        let origin = CGPoint(x: point.x - width * anchor.x, y: point.y - height * anchor.y)
        let rect = CGRect(origin: origin, size: CGSize(width: width, height: height))
        context.fill(Path(roundedRect: rect, cornerRadius: height / 2), with: .color(.black.opacity(0.45)))
        context.draw(label, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
    }

    /// The date line, dashed like a map's, where one day turns into the next. `scale` is points
    /// per unit of the map the context draws in.
    static func paintDateLine(_ pieces: [Path], scale: CGFloat, in context: GraphicsContext) {
        for piece in pieces {
            context.stroke(
                piece, with: .color(.white.opacity(0.6)),
                style: StrokeStyle(lineWidth: 1.2 / scale, lineCap: .round, dash: [4 / scale, 3 / scale]))
        }
    }

    /// Every World place's main clock, by its ID.
    private static let mainClocks: [String: ZoneClock] = places.compactMapValues { TimeZoneAtlas.clocks(of: $0).first }

    /// Every World place by its ID, for the clock each keeps.
    private static let places: [String: AdministrativeDivision] = Dictionary(
        CountryCatalog.world.divisions.map { ($0.id, $0) }) { first, _ in first }

    /// Where the lights are, as longitude and latitude: every capital, and the cities of countries'
    /// other time zones.
    @MainActor static let lights: [CGPoint] = {
        let places = CountryCatalog.world.divisions
        let capitals = places.flatMap { CapitalCities.capitals(of: $0).compactMap(\.location) }
        let zoneCities = places.flatMap { TimeZoneAtlas.clocks(of: $0).dropFirst().compactMap(\.location) }
        return capitals + zoneCities
    }()

    /// The lights in the dark, small warm points that brighten the further the Sun has set there,
    /// quiet enough to leave the map to be read. As the night first comes in, with `night` rising
    /// from 0, they come on one by one. `point` places a light on screen, or leaves it out.
    @MainActor
    static func paintLights(
        in context: GraphicsContext, sun: DayNight.Sun, night: Double, reach: Double, point: (CGPoint) -> CGPoint?
    ) {
        guard night > 0.01 else { return }
        for (index, place) in lights.enumerated() {
            let height = asin(min(max(sun.elevationSine(latitude: place.y, longitude: place.x), -1), 1)) * 180 / .pi
            var glow = min(max((-height - 2) / 8, 0), 1)
            let stagger = Double((index * 7_919) % 97) / 97 * 0.55
            glow *= min(max((night - stagger) / 0.45, 0), 1)
            guard glow > 0.02, let spot = point(place) else { continue }
            glow = glow * glow * (3 - 2 * glow)
            let halo = 1.9 * reach
            let core = 0.7 * reach
            context.fill(
                Path(ellipseIn: CGRect(x: spot.x - halo, y: spot.y - halo, width: halo * 2, height: halo * 2)),
                with: .radialGradient(
                    Gradient(colors: [DialPalette.lamp.opacity(0.16 * glow), DialPalette.lamp.opacity(0)]),
                    center: spot, startRadius: 0, endRadius: halo))
            context.fill(
                Path(ellipseIn: CGRect(x: spot.x - core, y: spot.y - core, width: core * 2, height: core * 2)),
                with: .color(DialPalette.lamp.opacity(0.55 * glow)))
        }
    }

    /// The ring's colours through the day, from midnight round to midnight again: deep at night,
    /// rose at dawn and dusk, warm through the day. Locations are hours over 24.
    static let daylight: [Gradient.Stop] = [
        .init(color: Color(red: 0.08, green: 0.10, blue: 0.32), location: 0),
        .init(color: Color(red: 0.36, green: 0.26, blue: 0.52), location: 4 / 24),
        .init(color: Color(red: 0.93, green: 0.55, blue: 0.42), location: 6 / 24),
        .init(color: Color(red: 0.98, green: 0.72, blue: 0.45), location: 8 / 24),
        .init(color: Color(red: 1, green: 0.86, blue: 0.55), location: 12 / 24),
        .init(color: Color(red: 0.98, green: 0.72, blue: 0.45), location: 16 / 24),
        .init(color: Color(red: 0.90, green: 0.48, blue: 0.48), location: 18 / 24),
        .init(color: Color(red: 0.36, green: 0.26, blue: 0.52), location: 20 / 24),
        .init(color: Color(red: 0.08, green: 0.10, blue: 0.32), location: 1),
    ]
}

// MARK: Layers

/// The Earth, drawn once for each country tapped and turned as a whole.
private struct DialEarth: View, Equatable {
    var map: TravelMap
    var centerLongitude: Double
    var statuses: [String: VisitLevel]
    var focus: DialFocus?
    var byZone: Bool
    var zones: ZoneMoment
    var subdivisions: [TravelMap]
    var seaTint: SeaTint?
    var zoneBorders: ZoneBorders?
    var geometry: DialGeometry

    nonisolated static func == (a: DialEarth, b: DialEarth) -> Bool {
        a.centerLongitude == b.centerLongitude && a.geometry.size == b.geometry.size && a.focus == b.focus && a.statuses == b.statuses
            && a.byZone == b.byZone && a.zones == b.zones && a.subdivisions.count == b.subdivisions.count
            && a.seaTint == b.seaTint && a.zoneBorders == b.zoneBorders && a.map.regions.count == b.map.regions.count
    }

    var body: some View {
        Canvas { context, _ in
            let scale = geometry.scale
            let extent = DialGeometry.extent
            let disc = Path(ellipseIn: CGRect(x: -extent, y: -extent, width: extent * 2, height: extent * 2))
            var earth = context
            earth.concatenate(geometry.mapTransform)
            earth.fill(
                disc,
                with: .radialGradient(
                    Gradient(colors: [DialPalette.seaMiddle, DialPalette.seaEdge]), center: .zero, startRadius: 0, endRadius: extent))
            earth.clip(to: disc)
            // Coloured by time zone, the sea wears its zones too, bending round the coasts, softly
            // where they meet.
            if let seaTint {
                var sea = context
                sea.clip(to: disc.applying(geometry.mapTransform))
                sea.drawLayer { layer in
                    layer.addFilter(.blur(radius: max(geometry.size / 260, 1.5)))
                    layer.draw(
                        Image(decorative: seaTint.image, scale: 1).interpolation(.high),
                        in: CGRect(x: -extent, y: -extent, width: extent * 2, height: extent * 2).applying(geometry.mapTransform))
                }
            }
            if let graticule = map.graticule {
                earth.stroke(graticule, with: .color(DialPalette.graticule), lineWidth: 0.6 / scale)
            }
            // The zones' meridians radiate from the pole across the sea, each beneath the half
            // hour between two of the ring's hours; they stop short of the pole, where they'd crowd.
            if byZone {
                WorldPainting.paintZoneMeridians(
                    WorldPainting.zoneMeridians(in: .polar, centerLongitude: centerLongitude, south: -62, north: 74),
                    land: WorldPainting.land(of: map), focus: focus?.offset, scale: scale, in: earth)
            }
            WorldPainting.paintCountries(
                of: map, statuses: statuses, focus: focus, byZone: byZone, zones: zones, subdivisions: subdivisions,
                zoneBorders: zoneBorders, transform: geometry.mapTransform, scale: scale, clip: disc.applying(geometry.mapTransform),
                in: context)
            if byZone {
                WorldPainting.paintDateLine(
                    WorldPainting.dateLine(in: .polar, centerLongitude: centerLongitude, south: -62), scale: scale, in: earth)
            }
            // The Earth's edge sinks a little under the ring.
            let rim = geometry.discRadius
            context.fill(
                Path(ellipseIn: CGRect(x: geometry.center.x - rim, y: geometry.center.y - rim, width: rim * 2, height: rim * 2)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0.86),
                        .init(color: .black.opacity(0.4), location: 1),
                    ]),
                    center: geometry.center, startRadius: 0, endRadius: rim))
        }
        .frame(width: geometry.size, height: geometry.size)
    }
}

/// The night side, which keeps to the far side of the Earth from the Sun as the Earth turns
/// beneath it, so it's drawn once for the season and only redrawn as the season moves on.
private struct DialNight: View, Equatable {
    /// The latitude the Sun stands over, rounded, which is all the night's shape depends on here.
    var declination: Double
    var geometry: DialGeometry

    nonisolated static func == (a: DialNight, b: DialNight) -> Bool {
        a.declination == b.declination && a.geometry.size == b.geometry.size
    }

    var body: some View {
        // The Sun over the meridian at the top of the dial, which is where it always is.
        var sun = DayNight.Sun(at: .now)
        sun.latitude = declination
        sun.longitude = 0
        let shade = NightShade.make(projection: .polar, centerLongitude: -180, sun: sun, edge: 180)
        return Canvas { context, _ in
            let toScreen = geometry.mapTransform
            let rim = geometry.discRadius
            var night = context
            night.clip(to: Path(ellipseIn: CGRect(
                x: geometry.center.x - rim, y: geometry.center.y - rim, width: rim * 2, height: rim * 2)))
            night.drawLayer { layer in
                layer.addFilter(.blur(radius: max(rim / 55, 2)))
                for (band, depth) in zip(shade.bands, WorldPainting.nightDepths) {
                    layer.fill(band.path.applying(toScreen), with: .color(DialPalette.night.opacity(depth)))
                }
            }
        }
        .frame(width: geometry.size, height: geometry.size)
    }
}

/// What moves at every frame: the capitals' lights in the dark, the person's hour on the ring,
/// and the country tapped, its ripple, flag and hours. Drawn in two layers, one on the Earth
/// beneath the ring and one over the ring.
private struct DialOverlay: View {
    enum Layer {
        /// The lights, the pivot and a tapped country's ripple, on the Earth.
        case earth
        /// The person's hour and the tapped country's flag, hours and arc, over the ring.
        case ring
    }

    var layer: Layer
    var geometry: DialGeometry
    var rotation: Double
    var centerLongitude: Double
    var sun: DayNight.Sun
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
    var night: Double
    var markers: Double
    /// With Reduce Motion, a country's flag is simply at its hour, without a ripple or a flight.
    var isStill = false

    var body: some View {
        Canvas { context, _ in
            switch layer {
            case .earth:
                drawLights(in: context)
                if let dateLineDays { drawDateLineDays(dateLineDays, in: context) }
                drawPivot(in: context)
                if let selection { drawRipple(for: selection, in: context) }
            case .ring:
                guard markers > 0.01 else { return }
                var marked = context
                marked.opacity = markers
                if let wound { drawWound(wound, in: marked) }
                if let outgoing { drawSelection(outgoing, in: marked) }
                if let selection { drawSelection(selection, in: marked) }
                drawHere(in: marked)
            }
        }
        .allowsHitTesting(false)
        .frame(width: geometry.size, height: geometry.size)
    }

    private func drawLights(in context: GraphicsContext) {
        WorldPainting.paintLights(in: context, sun: sun, night: night, reach: min(max(geometry.size / 360, 0.8), 1.4)) { place in
            guard place.y > -60 else { return nil }
            return geometry.screenPoint(
                MapProjection.polar.project(CGPoint(x: DayNight.normalized(place.x - centerLongitude), y: place.y)),
                rotation: rotation)
        }
    }

    /// The North Pole, which the World turns about, set like the pivot of a watch's hands.
    private func drawPivot(in context: GraphicsContext) {
        let center = geometry.center
        context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(.black.opacity(0.35)))
        context.fill(Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)), with: .color(.white.opacity(0.9)))
    }

    /// The person's own time, riding round the ring at their hour as its thumb, amber once wound
    /// away from now, a ring going out round it as time lands.
    private func drawHere(in context: GraphicsContext) {
        let point = geometry.ringPoint(angle: geometry.angle(forHours: hereHours + thumbNudge))
        WorldPainting.paintTimeThumb(
            hereTime, at: point, height: geometry.ringWidth * 0.8, isLive: wound == nil, within: bounds, landing: thumbRing,
            in: context)
    }

    /// The dial's own square, a little in from its edges, which what rides the ring keeps inside.
    private var bounds: CGRect {
        CGRect(x: 0, y: 0, width: geometry.size, height: geometry.size).insetBy(dx: 2, dy: 2)
    }

    /// Wound away from now: the stretch of the ring from now round to the time shown, lit, and now
    /// itself pinned to the ring, so it's plain at a glance that the time shown isn't the present.
    private func drawWound(_ hours: Double, in context: GraphicsContext) {
        let nowHours = hereHours - hours
        let run = min(max(hours, -24), 24)
        var arc = Path()
        let steps = max(Int(abs(run) * 4), 2)
        for step in 0...steps {
            let point = geometry.ringPoint(angle: geometry.angle(forHours: nowHours + run * Double(step) / Double(steps)))
            if step == 0 { arc.move(to: point) } else { arc.addLine(to: point) }
        }
        context.stroke(
            arc, with: .color(WorldPainting.wound.opacity(0.42)),
            style: StrokeStyle(lineWidth: geometry.ringWidth * 0.6, lineCap: .round, lineJoin: .round))
        WorldPainting.paintNowPin(
            at: geometry.ringPoint(angle: geometry.angle(forHours: nowHours)), height: geometry.ringWidth * 0.56, within: bounds,
            in: context)
    }

    /// The days either side of the date line, a little to each side of it, where it runs straight
    /// down the 180th meridian.
    private func drawDateLineDays(_ days: DateLineDays, in context: GraphicsContext) {
        func point(at longitude: Double) -> CGPoint {
            geometry.screenPoint(
                MapProjection.polar.project(CGPoint(x: DayNight.normalized(longitude - centerLongitude), y: 24)), rotation: rotation)
        }
        WorldPainting.paintDay(days.west, at: point(at: 168), anchor: .center, in: context)
        WorldPainting.paintDay(days.east, at: point(at: -168), anchor: .center, in: context)
    }

    /// A ring of light spreading out from the country tapped, fading as it goes.
    private func drawRipple(for selection: DialSelection, in context: GraphicsContext) {
        let elapsed = now.timeIntervalSince(selection.start)
        guard elapsed < 1, !isStill, selection.leaving == nil else { return }
        let origin = geometry.screenPoint(selection.mapPoint, rotation: rotation)
        WorldPainting.paintRipple(
            at: origin, reach: geometry.discRadius * 0.5, progress: max(elapsed, 0), color: selection.color ?? .white, in: context)
    }

    /// The country tapped on the ring: the hours its zones cover, an arc from the person's hour
    /// round to its own, and its flag flying out from it to that hour, a small ring going out round
    /// it as it lands. Let go, the flag flies back home and the arc and hours draw back in after it.
    private func drawSelection(_ selection: DialSelection, in context: GraphicsContext) {
        let elapsed = now.timeIntervalSince(selection.start)
        let tint = selection.color ?? .white
        let origin = geometry.screenPoint(selection.mapPoint, rotation: rotation)
        let (arrival, shown) = selection.arrival(at: now, isStill: isStill)
        guard shown > 0.001 else { return }
        var context = context
        context.opacity *= shown
        let isLeaving = selection.leaving != nil
        let mainAngle = geometry.angle(forHours: selection.hours)

        // The hours its zones cover, as a band of its colour along the ring.
        if !selection.otherHours.isEmpty {
            let angles = ([selection.hours] + selection.otherHours).map { geometry.angle(forHours: $0) }
            let span = Self.shortestSpan(of: angles)
            var band = Path()
            band.addArc(
                center: geometry.center, radius: geometry.radius - geometry.ringWidth / 2,
                startAngle: .degrees(span.start), endAngle: .degrees(span.start + span.length * arrival), clockwise: false)
            context.stroke(band, with: .color(tint.opacity(0.45)), style: StrokeStyle(lineWidth: geometry.ringWidth * 0.62, lineCap: .round))
            for angle in angles {
                let point = geometry.ringPoint(angle: angle)
                context.fill(Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)), with: .color(.white.opacity(0.9 * arrival)))
            }
        }

        // From the person's hour round to the country's, the way time runs to it, just inside the
        // ring; let go, it draws back in with the flag.
        let sweep = isStill ? 1 : isLeaving ? arrival : min(max((elapsed - 0.25) / 0.6, 0), 1)
        if abs(selection.hoursAhead) > 0.01, sweep > 0 {
            let eased = 1 - pow(1 - sweep, 3)
            let start = geometry.angle(forHours: hereHours)
            var arc = Path()
            arc.addArc(
                center: geometry.center, radius: geometry.radius - geometry.ringWidth - 1.5,
                startAngle: .degrees(start), endAngle: .degrees(start - selection.hoursAhead * 15 * eased),
                clockwise: selection.hoursAhead > 0)
            context.stroke(arc, with: .color(.white.opacity(0.75)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // Its flag, flying out from the country to its hour with a little overshoot, or let go,
        // gliding smoothly back home.
        let target = geometry.ringPoint(angle: mainAngle)
        let travel = isLeaving ? arrival * arrival * (3 - 2 * arrival) : Self.overshoot(arrival)
        let point = CGPoint(x: origin.x + (target.x - origin.x) * travel, y: origin.y + (target.y - origin.y) * travel)
        let radius = geometry.ringWidth * 0.46 * (0.45 + 0.55 * min(arrival * 1.6, 1))
        // Landed, a small ring goes out round it, as the landing is felt.
        if let ring = selection.landingRing(at: now, isStill: isStill) {
            WorldPainting.paintRipple(at: target, reach: geometry.ringWidth * 1.1, progress: ring, color: tint, in: context)
        }
        let chip = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        var shadow = context
        shadow.addFilter(.shadow(color: .black.opacity(0.45), radius: 3, y: 1.5))
        shadow.fill(chip, with: .color(.white))
        var flag = context
        flag.clip(to: chip)
        let image = context.resolve(Image(selection.flagAssetName))
        let size = image.size
        if size.width > 0, size.height > 0 {
            // Filling the circle, cut to its middle.
            let fill = max(radius * 2 / size.width, radius * 2 / size.height)
            let drawn = CGSize(width: size.width * fill, height: size.height * fill)
            flag.draw(image, in: CGRect(x: point.x - drawn.width / 2, y: point.y - drawn.height / 2, width: drawn.width, height: drawn.height))
        }
        context.stroke(chip, with: .color(.white), lineWidth: 1.6)
    }

    /// The shortest stretch of the ring holding every one of some angles, in degrees: where it
    /// starts, and how far it runs on clockwise.
    private static func shortestSpan(of angles: [Double]) -> (start: Double, length: Double) {
        let sorted = angles.map { ($0.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) }.sorted()
        guard sorted.count > 1 else { return (sorted.first ?? 0, 0) }
        // The widest gap between neighbours is the part of the ring left out.
        var widest = (gap: 360 - sorted[sorted.count - 1] + sorted[0], end: 0)
        for index in 1..<sorted.count where sorted[index] - sorted[index - 1] > widest.gap {
            widest = (sorted[index] - sorted[index - 1], index)
        }
        let start = sorted[widest.end]
        return (start, 360 - widest.gap)
    }

    /// Eases out past the end and back, for something landing with a little bounce.
    private static func overshoot(_ t: Double) -> Double {
        let c1 = 1.4, c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
}

/// The ring of the day's hours: warm through the day at its top, deep through the night at its
/// foot, rose at dawn and dusk, with a tick every hour, a dot every quarter hour, the hours every
/// three, and the Sun at noon and the Moon at midnight.
private struct DialBezel: View, Equatable {
    var geometry: DialGeometry
    var usesTwelveHours: Bool

    nonisolated static func == (a: DialBezel, b: DialBezel) -> Bool {
        a.geometry == b.geometry && a.usesTwelveHours == b.usesTwelveHours
    }

    var body: some View {
        Canvas { context, _ in
            let g = geometry
            let outer = g.radius - 0.5
            let inner = g.radius - g.ringWidth
            let center = g.center
            var ring = Path()
            ring.addEllipse(in: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2))
            ring.addEllipse(in: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2))
            let fill = FillStyle(eoFill: true)
            context.fill(ring, with: .color(.black.opacity(0.3)), style: fill)
            var tinted = context
            tinted.opacity = 0.6
            tinted.fill(ring, with: .conicGradient(Self.daylight, center: center, angle: .zero), style: fill)
            context.stroke(
                Path(ellipseIn: CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)),
                with: .color(.white.opacity(0.2)), lineWidth: 0.75)
            context.stroke(
                Path(ellipseIn: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)),
                with: .color(.white.opacity(0.14)), lineWidth: 0.75)

            for quarter in 0..<96 {
                let hours = Double(quarter) / 4
                let angle = g.angle(forHours: hours) * .pi / 180
                let direction = CGPoint(x: cos(angle), y: sin(angle))
                func at(_ distance: CGFloat) -> CGPoint {
                    CGPoint(x: center.x + direction.x * distance, y: center.y + direction.y * distance)
                }
                if quarter % 4 == 0 {
                    let isMain = quarter % 24 == 0
                    var tick = Path()
                    tick.move(to: at(inner + 2.5))
                    tick.addLine(to: at(inner + (isMain ? 9 : 6)))
                    context.stroke(tick, with: .color(.white.opacity(isMain ? 0.85 : 0.55)), style: StrokeStyle(lineWidth: isMain ? 1.6 : 1.1, lineCap: .round))
                } else {
                    let dot = at(inner + 3.5)
                    context.fill(Path(ellipseIn: CGRect(x: dot.x - 0.6, y: dot.y - 0.6, width: 1.2, height: 1.2)), with: .color(.white.opacity(0.32)))
                }
            }

            let type = Font.system(size: max(g.ringWidth * 0.36, 10), weight: .semibold).monospacedDigit()
            for hour in stride(from: 0, to: 24, by: 3) {
                let point = g.ringPoint(angle: g.angle(forHours: Double(hour)), depth: 0.6)
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
                context.draw(label.font(type), at: point, anchor: .center)
            }
        }
        .frame(width: geometry.size, height: geometry.size)
    }

    /// Around the ring from three o'clock, clockwise: dawn at six, the night through midnight at the
    /// foot, dusk at six in the evening, and the day through noon at the top.
    private static let daylight = Gradient(stops: [
        .init(color: Color(red: 0.93, green: 0.55, blue: 0.42), location: 0),
        .init(color: Color(red: 0.36, green: 0.26, blue: 0.52), location: 0.09),
        .init(color: Color(red: 0.08, green: 0.10, blue: 0.32), location: 0.25),
        .init(color: Color(red: 0.36, green: 0.26, blue: 0.52), location: 0.41),
        .init(color: Color(red: 0.90, green: 0.48, blue: 0.48), location: 0.5),
        .init(color: Color(red: 0.98, green: 0.72, blue: 0.45), location: 0.59),
        .init(color: Color(red: 1, green: 0.86, blue: 0.55), location: 0.75),
        .init(color: Color(red: 0.98, green: 0.72, blue: 0.45), location: 0.91),
        .init(color: Color(red: 0.93, green: 0.55, blue: 0.42), location: 1),
    ])
}

extension CGRect {
    /// Moved as little as it takes to lie inside another rectangle, as far as it fits.
    func kept(in bounds: CGRect) -> CGRect {
        var rect = self
        rect.origin.x = min(max(rect.minX, bounds.minX), max(bounds.maxX - rect.width, bounds.minX))
        rect.origin.y = min(max(rect.minY, bounds.minY), max(bounds.maxY - rect.height, bounds.minY))
        return rect
    }
}
