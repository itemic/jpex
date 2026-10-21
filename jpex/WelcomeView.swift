import CoreHaptics
import SwiftUI

/// The first launch, without a word. Deep space is flown through and the World spins in from far
/// away. Then it tours: it turns to a country, dives in until its subdivisions show, and lights a
/// few of them up, each climbing through the levels with a ring of colour at every step, before
/// they drain away and the World pulls back out for the next. After the tour the World is the
/// person's to spin with a finger, and countries twinkle across it as Game Mode's lobby lights
/// them, their borders glowing and their names floating above. A tap on a country raises a bar of
/// glass naming it, its levels dancing until one is picked, which lights the country up; a drag or
/// tap at any time ends the tour early. The arrow turns the World to the map's own centre, unrolls it
/// flat into the World map, and lands it on the World list's map as space falls away, so the app
/// begins from it. Nothing here is saved. With Reduce Motion, the World is simply there, turned
/// only by hand, and leaving fades.
struct WelcomeView: View {
    /// Every country's level, for the map the World unrolls into.
    var worldStatuses: [String: VisitLevel]
    /// The person's own list with the most places marked, toured first with their own levels.
    var personalLeg: WelcomeLeg? = nil
    /// Where the World list's map is on screen, for the World to land on.
    var landing: ListMapLocation
    /// The World has begun to leave: the World's list should be open beneath it, ready to land on.
    var onLanding: () -> Void
    /// The landing is over, and the welcome can go, with the countries the person lit up on the way.
    var onFinish: (_ lit: [String: VisitLevel]) -> Void

    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Off in Low Power Mode and with Reduce Motion, so space holds still and the frame rate drops.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    @Environment(\.scenePhase) private var scenePhase
    /// The app's own appearance, which the welcome's dark space leaves in place for the map it lands.
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @AppStorage("localLanguage") private var localLanguage = false
    /// When the World set off from deep space.
    @State private var start = Date.now
    /// The World in the person's hands, once they've touched it, which ends the tour.
    @State private var hand: HandSpin?
    /// When the arrow was tapped, and how the World was then, which sets it unrolling.
    @State private var leaving: Leaving?
    /// Countries the person has given a level, each with the level picked.
    @State private var touched: [String: Touch] = [:]
    /// The country last tapped, named in the bar of glass with its levels.
    @State private var chosen: Chosen?
    /// Countries twinkling on the globe, their borders glowing and their names above them.
    @State private var twinkles: [Twinkle] = []
    /// Counts the person's touches on the globe, each of which sets the twinkling going again.
    @State private var wakes = 0
    @State private var showsArrow = false
    /// Whether the tour has played through, after which the World only drifts, at a calmer frame rate.
    @State private var isTourOver = false
    /// Counts the tour's arrivals in each country, and the person's taps on countries, for a tap felt.
    @State private var dives = 0
    @State private var touches = 0
    /// Where the globe sits once it has arrived, and where the scene starts, in global coordinates.
    @State private var globeSlot: CGRect = .zero
    @State private var sceneOrigin: CGPoint = .zero
    @State private var globes = GlobeCache()
    @State private var haptics = ArrivalHaptics()

    /// How long the World takes to fly in and come to rest.
    private static let arrival = 3.0
    /// How far the World turns as it flies in, in degrees.
    private static let spin = 420.0
    /// Each stop on the tour: turning to the country, diving in, lighting places, their colours
    /// draining away, and pulling back out.
    private static let turn = 1.1
    private static let diveIn = 0.9
    private static let lighting = 2.2
    private static let draining = 0.5
    private static let pullOut = 0.8
    /// Seconds between one level and the next as a place climbs, and between places starting.
    private static let step = 0.26
    private static let stagger = 0.15
    /// Degrees a second the World turns by itself once the tour is over or the person lets go.
    private static let drift = 4.0
    /// How long a flick keeps the World turning, as the time for its speed to fall by two thirds.
    private static let inertia = 0.8
    /// Leaving: turning to the map's centre, unrolling, then fading away.
    private static let turning = 0.7
    private static let unrolling = 1.7
    private static let fading = 0.45
    /// How long a country twinkles, long enough to read its name, and how many at once at most.
    private static let twinkleLength = 2.6
    private static let mostTwinkles = 4
    /// How long the twinkling goes on after the person last touched the World before it rests.
    private static let twinklingTime = 40.0

    /// The World's countries by their places on the globe, for their names and flags.
    private static let countries: [String: AdministrativeDivision] = Dictionary(
        CountryCatalog.world.divisions.map { ($0.id, $0) }
    ) { first, _ in first }

    // MARK: The tour

    /// Japan, Italy, Brazil and the United States, heading west around the World.
    private static let standardLegs: [WelcomeLeg] = [("JP", 137.0), ("IT", 12.5), ("BR", -52.0), ("US", -97.0)]
        .compactMap { id, longitude in
            guard let country = CountryCatalog.country(id: id),
                  let worldPlace = CountryCatalog.world.divisions.first(where: { $0.abbreviation == id })
            else { return nil }
            // Seven places spread through the list, so they're spread across the country.
            let divisions = country.divisions
            let heights = [1.0, 0.6, 0.8, 0.4, 1.0, 0.7, 0.3]
            let places = heights.indices.compactMap { index -> WelcomeLeg.Place? in
                let position = (index * divisions.count + divisions.count / 2) / heights.count
                return divisions.indices.contains(position)
                    ? WelcomeLeg.Place(id: divisions[position].id, height: heights[index]) : nil
            }
            return WelcomeLeg(collectionID: id, worldPlaceID: worldPlace.id, longitude: longitude, places: places)
        }

    /// The tour's stops: the person's own list first, where there is one, then the rest.
    private var legs: [WelcomeLeg] {
        guard let personalLeg else { return Self.standardLegs }
        return [personalLeg] + Self.standardLegs.filter { $0.worldPlaceID != personalLeg.worldPlaceID }
    }

    /// The World at a moment of the tour or in the person's hands, before it's drawn.
    private struct Moment {
        var longitude: Double
        /// Turning, so lighter outlines are enough.
        var isTurning: Bool
        /// The country dived into, if any, and how far: 0 out on the whole World, 1 close in.
        var leg: WelcomeLeg?
        var dive: Double = 0
        /// The country's places lit up, and how strongly, 1 down to 0 as they drain away.
        var levels: [String: VisitLevel] = [:]
        var fill: Double = 1
        var ripples: [(placeID: String, color: Color, progress: Double)] = []
        /// How much of the globe shows, for the tour's fades with Reduce Motion.
        var opacity: Double = 1
    }

    /// Where the tour is `t` seconds after the World set off.
    private func tourMoment(at t: Double) -> Moment {
        let legs = legs
        guard let first = legs.first else { return Moment(longitude: center.longitude, isTurning: false) }
        if reduceMotion { return stillTourMoment(at: t, legs: legs) }
        if t < Self.arrival {
            return Moment(longitude: first.longitude - Self.spin * pow(1 - max(t, 0) / Self.arrival, 3), isTurning: true)
        }
        var elapsed = t - Self.arrival
        for (index, leg) in legs.enumerated() {
            let turn = index == 0 ? 0 : Self.turn
            let length = turn + Self.diveIn + Self.lighting + Self.draining + Self.pullOut
            guard elapsed >= length else {
                if elapsed < turn {
                    let from = legs[index - 1].longitude
                    let longitude = from + Self.shortestTurn(from: from, to: leg.longitude) * smootherstep(elapsed / turn)
                    return Moment(longitude: longitude, isTurning: true)
                }
                return diving(into: leg, at: elapsed - turn)
            }
            elapsed -= length
        }
        // The tour over, the World turns slowly by itself, whole.
        return Moment(longitude: legs[legs.count - 1].longitude - Self.drift * elapsed, isTurning: true)
    }

    /// The tour without motion, for Reduce Motion: each country shown close in, fading in, its places
    /// lighting up level by level and draining, then fading out for the next; at the end, the whole
    /// World facing the map's own centre.
    private func stillTourMoment(at t: Double, legs: [WelcomeLeg]) -> Moment {
        let fade = 0.6
        let length = fade + Self.lighting + Self.draining + fade
        var elapsed = max(t, 0)
        for leg in legs {
            guard elapsed >= length else {
                var moment = diving(into: leg, at: elapsed - fade + Self.diveIn)
                moment.dive = 1
                moment.ripples = []
                moment.opacity = min(smoothstep(0, fade, elapsed), 1 - smoothstep(length - fade, length, elapsed))
                return moment
            }
            elapsed -= length
        }
        var moment = Moment(longitude: center.longitude, isTurning: false)
        moment.opacity = smoothstep(0, fade, elapsed)
        return moment
    }

    /// In a country `elapsed` seconds after it began to dive in: its places climbing the levels
    /// one after another, a ring of colour at each step, then draining away as the World pulls back.
    /// The person's own places climb to the levels they're at; with many, each rings only once.
    private func diving(into leg: WelcomeLeg, at elapsed: Double) -> Moment {
        let held = Self.diveIn + Self.lighting + Self.draining
        let dive = elapsed < Self.diveIn
            ? smootherstep(elapsed / Self.diveIn)
            : elapsed < held ? 1 : 1 - smootherstep((elapsed - held) / Self.pullOut)
        var moment = Moment(longitude: leg.longitude, isTurning: false, leg: leg, dive: dive)
        let levels = ladder.levels
        guard !levels.isEmpty else { return moment }
        let lit = elapsed - Self.diveIn
        // Long ladders climb faster, so every level shows before the colours drain away, and many
        // places start closer together.
        let step = min(Self.step, 1.3 / Double(levels.count))
        let stagger = min(Self.stagger, 1.0 / Double(max(leg.places.count, 1)))
        let ringsEveryStep = leg.places.count <= 10
        for (index, place) in leg.places.enumerated() {
            let since = lit - Double(index) * stagger
            guard since >= 0 else { continue }
            let own = place.levelID.flatMap { ladder.level(id: $0) }.map { ladder.rank(of: $0) }
            let top = max(1, min(own ?? Int((place.height * Double(levels.count)).rounded()), levels.count))
            let rank = min(Int(since / step) + 1, top)
            moment.levels[place.id] = levels[rank - 1]
            // With many places, each rings only once it reaches its top, and not while still climbing.
            for reached in stride(from: ringsEveryStep ? 1 : top, through: rank, by: 1) {
                let progress = (since - Double(reached - 1) * step) / 0.9
                if progress < 1 { moment.ripples.append((place.id, levels[reached - 1].color, progress)) }
            }
        }
        moment.fill = 1 - smootherstep((lit - Self.lighting) / Self.draining)
        return moment
    }

    /// The World in the person's hands: easing out of wherever the tour was, turned by their finger,
    /// then coasting on and slowing to a gentle turn of its own the way they last sent it.
    private func handMoment(_ hand: HandSpin, at date: Date) -> Moment {
        let easing = reduceMotion ? 0 : 1 - smootherstep(date.timeIntervalSince(hand.since) / 0.7)
        var moment = Moment(
            longitude: hand.longitude, isTurning: true, leg: hand.leg, dive: hand.dive * easing, levels: hand.levels,
            fill: hand.fill * easing)
        if let dragTurn = hand.dragTurn {
            moment.longitude += dragTurn
        } else {
            let coasting = date.timeIntervalSince(hand.released)
            let direction: Double = hand.velocity > 0 ? 1 : -1
            moment.longitude += hand.velocity * Self.inertia * (1 - exp(-coasting / Self.inertia))
            if !reduceMotion {
                moment.longitude += direction * Self.drift * max(coasting - 1, 0) * smootherstep(coasting / 2.5)
            }
        }
        return moment
    }

    private func moment(at date: Date) -> Moment {
        if let hand { return handMoment(hand, at: date) }
        return tourMoment(at: date.timeIntervalSince(start))
    }

    // MARK: View

    var body: some View {
        ZStack {
            // Space runs edge to edge, under the bars and around the camera.
            GeometryReader { proxy in
                // At most 60 frames a second while the tour plays; 30 once it's over, in Low Power Mode
                // and with Reduce Motion, enough for a drift and for fades; none while the app isn't in front.
                TimelineView(.animation(
                    minimumInterval: isTourOver || !allowsAmbientMotion ? 1.0 / 30 : 1.0 / 60,
                    paused: scenePhase != .active)
                ) { timeline in
                    scene(at: timeline.date, size: proxy.size)
                }
                .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { sceneOrigin = $0 }
            }
            .ignoresSafeArea()
            // What to touch keeps within the safe area, clear of the camera and the fold.
            GeometryReader { proxy in
                controls(size: proxy.size, fold: FoldRegions(in: proxy))
            }
        }
        .environment(\.colorScheme, .dark)
        // In front of everything, a place rising here may break out over the screen.
        .environment(\.breaksOutOntoScreen, true)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        // The escape gesture leaves, as the arrow does.
        .accessibilityAction(.escape, leave)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: dives)
        .sensoryFeedback(trigger: touches) { _, _ in .impact(weight: .medium, intensity: 0.7) }
        .sensoryFeedback(.selection, trigger: chosen?.id)
        .task { await arrive() }
        // Countries twinkle once the World is the person's, and start again with each touch.
        .task(id: isTwinkling ? wakes : -1) { await twinkle() }
        .onDisappear { haptics.stop() }
    }

    /// Space, and the World in it, as they are at a moment.
    private func scene(at date: Date, size: CGSize) -> some View {
        let frame = worldFrame(at: date, size: size)
        return ZStack {
            Rectangle()
                .colorEffect(ShaderLibrary.starfield(
                    .float2(Float(size.width), Float(size.height)),
                    // Still, without twinkling or drifting, in Low Power Mode and with Reduce Motion.
                    .float(allowsAmbientMotion ? Float(date.timeIntervalSince(start)) : 0),
                    .float(Float(travel(at: date)))))
                .opacity(frame.space)
            if let map = frame.map {
                SpaceGlobe(
                    map: map, frame: frame.rect, camera: frame.camera, statuses: frame.statuses, detail: frame.detail,
                    detailStatuses: frame.detailStatuses, detailOpacity: frame.detailOpacity, detailFill: frame.detailFill,
                    daylight: frame.daylight, roundness: frame.roundness, ripples: frame.ripples, glows: frame.glows)
                    // By day, in the app's own colours, to match the list's map it lands on.
                    .environment(\.colorScheme, colorScheme)
                    .opacity(frame.globeOpacity)
                    // Landing, its edges fade into the page as the list's map does.
                    .mask {
                        ZStack {
                            Color.black.opacity(1 - frame.daylight)
                            EdgeFade()
                                .frame(width: max(frame.rect.width, 1), height: max(frame.rect.height, 1))
                                .position(x: frame.rect.midX, y: frame.rect.midY)
                                .opacity(frame.daylight)
                        }
                    }
            }
            ForEach(frame.captions, id: \.regionID) { caption in
                GlobeCaption(caption: caption)
                    // Kept clear of the screen's sides, so a long name near the rim still reads whole.
                    .position(x: min(max(caption.point.x, 90), max(size.width - 90, 90)), y: caption.point.y - 20)
            }
        }
        .opacity(fadeOut(at: date))
        .allowsHitTesting(false)
    }

    /// How far the viewer has flown through space: fast as the World flies in, then a slow drift.
    private func travel(at date: Date) -> Double {
        guard allowsAmbientMotion else { return 0 }
        let t = max(date.timeIntervalSince(start), 0)
        let settle = 1.1
        return 0.03 * t + 1.1 * settle * (1 - exp(-t / settle))
    }

    /// The World at a moment: its outlines, where and how close they're drawn, in what colours, and
    /// how much of space shows.
    private func worldFrame(at date: Date, size: CGSize) -> WorldFrame {
        let slot = globeSlot.offsetBy(dx: -sceneOrigin.x, dy: -sceneOrigin.y)
        guard let world = Geography.world, slot.width > 1 else { return WorldFrame() }
        let touchedLevels = touched.mapValues(\.level)
        guard let leaving else {
            let moment = moment(at: date)
            // Flying in, from a speck in the distance.
            let t = date.timeIntervalSince(start)
            let near = reduceMotion ? 1 : 1 - pow(1 - min(max(t / (Self.arrival * 0.72), 0), 1), 4)
            let side = slot.width * (0.05 + 0.95 * near)
            let rect = CGRect(x: slot.midX - side / 2, y: slot.midY - side / 2, width: side, height: side)
            // Drifting by itself after the tour, the World is cut afresh only every quarter degree.
            let map = globes.globe(
                world, longitude: moment.longitude, isTurning: moment.isTurning,
                step: isTourOver && hand == nil ? 0.25 : 0.05)
            var frame = WorldFrame(map: map, rect: rect, statuses: touchedLevels)
            frame.globeOpacity = moment.opacity
            frame.camera = camera(on: map, in: rect, leg: moment.leg, dive: moment.dive)
            // Subdivisions only while the World holds still; turned by hand, it pulls out without them.
            if let leg = moment.leg, moment.dive > 0.02, !moment.isTurning {
                frame.detail = globes.detail(leg.collectionID, longitude: moment.longitude)
                frame.detailStatuses = moment.levels
                frame.detailOpacity = smoothstep(0.35, 0.9, moment.dive)
                frame.detailFill = moment.fill
            }
            frame.ripples = moment.ripples.compactMap { ripple in
                (frame.detail?.region(id: ripple.placeID)).map {
                    GlobeRipple(center: $0.center, color: ripple.color, progress: ripple.progress, reach: 34)
                }
            } + touchRipples(on: map, at: date)
            lightUp(&frame, on: map, at: date)
            return frame
        }
        let elapsed = date.timeIntervalSince(leaving.date)
        if reduceMotion || elapsed < Self.turning {
            // Pulling back out and turning to face the map's own centre, ready to unroll.
            let turn = reduceMotion ? 0 : smootherstep(elapsed / Self.turning)
            let longitude = leaving.longitude + Self.shortestTurn(from: leaving.longitude, to: center.longitude) * turn
            let map = globes.globe(world, longitude: longitude, isTurning: !reduceMotion)
            var frame = WorldFrame(map: map, rect: slot, statuses: touchedLevels)
            frame.camera = camera(on: map, in: slot, leg: leaving.leg, dive: leaving.dive * (1 - turn))
            return frame
        }
        // Unrolling flat and gliding onto the list's map as space falls away.
        let progress = smootherstep((elapsed - Self.turning) / Self.unrolling)
        let target = landingRect(size: size)
        var frame = WorldFrame(
            map: globes.unrolled(world, to: projection, center: center, progress: progress),
            rect: CGRect(
                x: slot.minX + (target.minX - slot.minX) * progress, y: slot.minY + (target.minY - slot.minY) * progress,
                width: slot.width + (target.width - slot.width) * progress,
                height: slot.height + (target.height - slot.height) * progress),
            statuses: worldStatuses)
        frame.space = 1 - smoothstep(0.15, 0.85, progress)
        frame.daylight = smoothstep(0.3, 1, progress)
        frame.roundness = 1 - smoothstep(0, 0.45, progress)
        return frame
    }

    /// Close in on a country by `dive`, from the whole World at 0 to the country filling the globe's
    /// space at 1.
    private func camera(on map: TravelMap, in rect: CGRect, leg: WelcomeLeg?, dive: Double) -> MapCamera {
        guard dive > 0.001, let leg, let region = map.region(id: leg.worldPlaceID), rect.width > 1 else { return MapCamera() }
        let geometry = MapGeometry(focus: map.focusRect(including: []), size: rect.size, zoom: 1, pan: .zero)
        let core = region.coreBounds
        var target = geometry.camera(fitting: core.insetBy(dx: -core.width * 0.3, dy: -core.height * 0.3))
        if target.zoom > 5 {
            target = geometry.camera(centering: CGPoint(x: core.midX, y: core.midY), zoom: 5)
        }
        return MapCamera(
            zoom: 1 + (target.zoom - 1) * dive,
            pan: CGSize(width: target.pan.width * dive, height: target.pan.height * dive))
    }

    /// Rings of colour from countries the person has just tapped or given a level.
    private func touchRipples(on map: TravelMap, at date: Date) -> [GlobeRipple] {
        let ripples = touched.compactMap { id, touch -> GlobeRipple? in
            let progress = date.timeIntervalSince(touch.date) / 1.1
            guard progress < 1, let region = map.region(id: id) else { return nil }
            return GlobeRipple(center: region.center, color: touch.ripple, progress: progress, reach: 70)
        }
        guard let chosen, let region = map.region(id: chosen.id) else { return ripples }
        let progress = date.timeIntervalSince(chosen.date) / 0.9
        return progress < 1 ? ripples + [GlobeRipple(center: region.center, color: .white, progress: progress, reach: 50)] : ripples
    }

    /// The countries twinkling, their borders glowing as they light up and fade, each with its name
    /// rising above it; and the country in the bar, glowing steadily in its level's colour.
    private func lightUp(_ frame: inout WorldFrame, on map: TravelMap, at date: Date) {
        let transform = screenTransform(of: map, in: frame.rect, camera: frame.camera)
        for twinkle in twinkles where twinkle.id != chosen?.id {
            let progress = date.timeIntervalSince(twinkle.start) / Self.twinkleLength
            guard progress > 0, progress < 1, let region = map.region(id: twinkle.id),
                  let country = Self.countries[twinkle.id] else { continue }
            let body = region.coreBounds
            let envelope = sin(.pi * progress)
            frame.glows.append(GlobeGlow(regionID: twinkle.id, color: twinkle.color, strength: envelope, body: body))
            let top = body.applying(transform)
            let name = country.displayName(localLanguage: localLanguage)
            frame.captions.append(GlobeCaption.Content(
                regionID: twinkle.id, name: name, language: country.language(of: name), flagAssetName: country.flagAssetName,
                point: CGPoint(x: top.midX, y: top.minY), progress: progress))
        }
        if let chosen, let region = map.region(id: chosen.id) {
            let level = touched[chosen.id]?.level ?? .never
            // A slow breath, so the country in the bar stands out from those twinkling.
            let breath = allowsAmbientMotion ? (sin(date.timeIntervalSinceReferenceDate * 2 * .pi / 1.6) + 1) / 2 : 1
            frame.glows.append(GlobeGlow(
                regionID: chosen.id, color: level == .never ? .white : level.color, strength: 0.75 + 0.25 * breath,
                body: region.coreBounds))
        }
    }

    /// From the map's own units to the scene's, as the globe is drawn.
    private func screenTransform(of map: TravelMap, in rect: CGRect, camera: MapCamera) -> CGAffineTransform {
        MapGeometry(focus: map.focusRect(including: []), size: rect.size, zoom: camera.zoom, pan: camera.pan)
            .transform.concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    }

    /// The World list's map, if it's on screen to land on, in the scene's space; otherwise a map
    /// across the middle of the screen, which fades away.
    private func landingRect(size: CGSize) -> CGRect {
        let screen = CGRect(origin: .zero, size: size)
        if landing.collectionID == CountryCatalog.world.id,
           let frame = landing.frame?.offsetBy(dx: -sceneOrigin.x, dy: -sceneOrigin.y),
           frame.width > 40, frame.intersection(screen).height > frame.height * 0.6 {
            return frame
        }
        let width = size.width - 32
        return CGRect(x: 16, y: (size.height - width / 1.9) / 2, width: width, height: width / 1.9)
    }

    /// How much of the welcome still shows: all of it until the World has landed, then fading.
    private func fadeOut(at date: Date) -> Double {
        guard let leaving else { return 1 }
        let landed = reduceMotion ? 0 : Self.turning + Self.unrolling
        return 1 - smoothstep(0, 1, (date.timeIntervalSince(leaving.date) - landed) / Self.fading)
    }

    // MARK: Controls

    /// The globe's space, where a finger turns the World and a tap lights a country, and below it
    /// the levels and the arrow. Upright, the arrow sits beneath the globe; on its side, in a
    /// column of its own beside the globe; and while iPhone Duo is partly folded, the globe takes the far side and the arrow
    /// the near side.
    @ViewBuilder
    private func controls(size: CGSize, fold: FoldRegions?) -> some View {
        ZStack {
            // Edge to edge, so a touch beside the controls never reaches the list's toolbar beneath,
            // which on iPhone Duo sits in the side strip, outside the safe area.
            Color.clear
                .contentShape(Rectangle())
                .gesture(spinning)
                .onTapGesture(coordinateSpace: .global) { location in touch(at: location) }
                .ignoresSafeArea()
            if let fold {
                globeSpace(side: min(fold.far.width, fold.far.height) * 0.86)
                    .position(x: fold.far.midX, y: fold.far.midY)
                bar
                    .position(x: fold.near.midX, y: fold.near.midY)
            } else if size.width > size.height * 1.15 {
                // Two columns: the globe in the leading room, the bar centred in a column of its
                // own at the trailing side, so it never covers the World or catches a tap meant
                // for a country.
                let barWidth = min(max(size.width * 0.36, 280), 400)
                let globeRoom = size.width - barWidth - 40
                globeSpace(side: min(size.height * 0.88, globeRoom * 0.94))
                    .position(x: globeRoom / 2 + 12, y: size.height / 2)
                bar
                    .frame(width: barWidth)
                    .position(x: size.width - barWidth / 2 - 20, y: size.height / 2)
            } else {
                globeSpace(side: min(size.width * 0.86, size.height * 0.6))
                    .position(x: size.width / 2, y: size.height * 0.44)
                bar
                    .padding(.bottom, 16)
                    .frame(width: size.width, height: size.height, alignment: .bottom)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// The square the globe comes to rest in, measured so the scene can draw the World there.
    private func globeSpace(side: CGFloat) -> some View {
        Color.clear
            .frame(width: max(side, 1), height: max(side, 1))
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { globeSlot = $0 }
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel("The World")
            .accessibilityValue("A spinning globe")
            .accessibilityHint("Drag to spin it. Tap a country to choose its level.")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }

    /// The levels as dots, lit as far as anything on the globe has climbed, or the country tapped
    /// in its bar of glass with its levels, over the arrow onward.
    private var bar: some View {
        VStack(spacing: 18) {
            // One slot, so a new country's bar, or the dots, cross the old one in place rather than
            // standing above it for a moment and pushing the arrow about.
            ZStack(alignment: .bottom) {
                if let chosen, let country = Self.countries[chosen.id] {
                    WelcomePlaceBar(
                        place: country, status: touched[chosen.id]?.level ?? .never, localLanguage: localLanguage
                    ) { level in
                        give(level, to: chosen.id)
                    }
                    .frame(maxWidth: 440)
                    .padding(.horizontal, 16)
                    // A new country's bar takes the old one's place, its badges popping in afresh.
                    .id(chosen.id)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .scale(scale: 0.85, anchor: .bottom).combined(with: .opacity).combined(with: .offset(y: 16)),
                                removal: .scale(scale: 0.95).combined(with: .opacity)))
                } else {
                    // Still once the tour is over: then only taps change the dots, and those redraw them anyway.
                    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: leaving != nil || isTourOver || scenePhase != .active)) { timeline in
                        LevelDots(levels: ladder.levels, reached: reachedRank(at: timeline.date))
                    }
                    .transition(.opacity)
                }
            }
            // The way in: large, in the accent's own glass, with a soft glow breathing behind it.
            Button(action: leave) {
                Label("Continue", systemImage: "arrow.right")
                    .labelStyle(.iconOnly)
                    .font(.title.weight(.bold))
                    .symbolEffect(.wiggle.right, options: .repeat(.periodic(3, delay: 3.5)), isActive: showsArrow && allowsAmbientMotion)
                    .frame(width: 64, height: 64)
            }
            .keyboardShortcut(.defaultAction)
            .modifier(ProminentGlassCircle())
            .tint(.accentColor)
            .background { ArrowGlow() }
            .disabled(leaving != nil)
        }
        .appearing(showsArrow, isLeaving: leaving != nil)
    }

    /// The highest level anything on the globe shows at a moment.
    private func reachedRank(at date: Date) -> Int {
        let moment = moment(at: date)
        let shown = moment.fill > 0.5 ? Array(moment.levels.values) : []
        return (shown + touched.values.map(\.level)).map(ladder.rank(of:)).max() ?? 0
    }

    // MARK: Actions

    /// Flying in with a rumble, and the arrow appearing once the World is near, then a tap felt as
    /// the tour arrives in each country.
    private func arrive() async {
        start = .now
        guard !reduceMotion else {
            showsArrow = true
            // The tour still plays, as fades, and is over once every country has shown.
            try? await Task.sleep(for: .seconds(Double(legs.count) * (1.2 + Self.lighting + Self.draining)))
            isTourOver = true
            return
        }
        haptics.playArrival(duration: Self.arrival)
        try? await Task.sleep(for: .seconds(1.4))
        showsArrow = true
        var landingTime = Self.arrival - 1.4 + Self.diveIn
        for _ in legs {
            try? await Task.sleep(for: .seconds(landingTime))
            guard hand == nil, leaving == nil else { return }
            dives += 1
            landingTime = Self.lighting + Self.draining + Self.pullOut + Self.turn + Self.diveIn
        }
        try? await Task.sleep(for: .seconds(Self.lighting + Self.draining + Self.pullOut))
        isTourOver = true
    }

    /// A finger turns the World, the tour giving way at its touch; let go, it coasts on.
    private var spinning: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard leaving == nil else { return }
                let now = Date.now
                var spin = hand ?? takingHold(at: now)
                if spin.dragTurn == nil {
                    // A new touch picks the World up wherever it had turned to.
                    spin.longitude = handMoment(spin, at: now).longitude
                    spin.dragTurn = 0
                }
                spin.dragTurn = -value.translation.width * degreesPerPoint
                hand = spin
            }
            .onEnded { value in
                guard leaving == nil, var spin = hand else { return }
                spin.longitude += spin.dragTurn ?? 0
                spin.dragTurn = nil
                spin.released = .now
                spin.velocity = max(min(-value.velocity.width * degreesPerPoint, 720), -720)
                hand = spin
                wakes += 1
            }
    }

    /// How far a finger's drag turns the World: across the globe's width is half way round.
    private var degreesPerPoint: Double {
        180 / max(globeSlot.width, 200)
    }

    /// A tap on a country raises its bar, with its levels to pick from, leaving its level as it is;
    /// a tap on the sea or in space puts the bar away.
    private func touch(at location: CGPoint) {
        guard leaving == nil else { return }
        let now = Date.now
        if hand == nil { hand = takingHold(at: now) }
        wakes += 1
        let frame = worldFrame(at: now, size: .zero)
        guard let map = frame.map else { return }
        let geometry = MapGeometry(
            focus: map.focusRect(including: []), size: frame.rect.size, zoom: frame.camera.zoom, pan: frame.camera.pan)
        let point = CGPoint(x: location.x - sceneOrigin.x - frame.rect.minX, y: location.y - sceneOrigin.y - frame.rect.minY)
        let region = map.place(at: point, geometry: geometry, among: Set(map.regions.map(\.id)))
        withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .bouncy(duration: 0.5, extraBounce: 0.1)) {
            if let region, Self.countries[region.id] != nil {
                // Tapped again, the country keeps its bar as it is.
                if chosen?.id != region.id { chosen = Chosen(id: region.id, date: now) }
            } else {
                chosen = nil
            }
        }
    }

    /// A level picked in the bar lights the country up in its colour, or with never been, puts it back.
    private func give(_ level: VisitLevel, to id: String) {
        guard leaving == nil else { return }
        let current = touched[id]?.level ?? .never
        guard level != current else { return }
        touched[id] = Touch(level: level, date: .now, ripple: level == .never ? .white : level.color)
        touches += 1
    }

    /// Whether countries twinkle: once the World is the person's, while it's in front and may move.
    private var isTwinkling: Bool {
        (isTourOver || hand != nil) && leaving == nil && allowsAmbientMotion && scenePhase == .active
    }

    /// Countries on the face of the World light up one after another, a few at once and spread
    /// well apart, their borders glowing and their names above them, until a while after the
    /// person last touched it. The ones lit fade out as they would.
    private func twinkle() async {
        guard isTwinkling else { return }
        let colors = MapGameMode.allCases.map(\.color).shuffled()
        var count = twinkles.count
        try? await Task.sleep(for: .seconds(0.4))
        let restsAt = Date.now.addingTimeInterval(Self.twinklingTime)
        while !Task.isCancelled, Date.now < restsAt {
            let now = Date.now
            twinkles.removeAll { now.timeIntervalSince($0.start) >= Self.twinkleLength }
            if twinkles.count < Self.mostTwinkles, let id = twinkleCandidate(at: now) {
                twinkles.append(Twinkle(id: id, color: colors[count % colors.count], start: now))
                count += 1
            }
            // Staggered, so they come and go one after another rather than all together.
            try? await Task.sleep(for: .seconds(Self.twinkleLength / Double(Self.mostTwinkles) + 0.1))
        }
    }

    /// A country to twinkle next: big enough to see, well inside the globe's face rather than
    /// on its rim, and well apart from those already lit.
    private func twinkleCandidate(at date: Date) -> String? {
        let frame = worldFrame(at: date, size: .zero)
        guard let map = frame.map, let outline = map.outline else { return nil }
        let transform = screenTransform(of: map, in: frame.rect, camera: frame.camera)
        let ball = outline.boundingRect.applying(transform)
        let radius = ball.width / 2
        let lit = twinkles.compactMap { map.region(id: $0.id)?.center.applying(transform) }
        let candidates = map.regions.filter { region in
            guard Self.countries[region.id] != nil, region.id != chosen?.id,
                  !twinkles.contains(where: { $0.id == region.id }) else { return false }
            let box = region.bounds.applying(transform)
            let center = region.center.applying(transform)
            return max(box.width, box.height) >= 14
                && hypot(center.x - ball.midX, center.y - ball.midY) < radius * 0.72
                && lit.allSatisfy { hypot($0.x - center.x, $0.y - center.y) >= radius * 0.45 }
        }
        return candidates.randomElement()?.id
    }

    /// The World taken in hand at a moment, the tour easing away from where it was.
    private func takingHold(at date: Date) -> HandSpin {
        let moment = tourMoment(at: date.timeIntervalSince(start))
        return HandSpin(
            since: date, leg: moment.leg, dive: moment.dive, levels: moment.levels, fill: moment.fill,
            longitude: moment.longitude, released: date)
    }

    /// Sets the World turning, unrolling and landing, with the World's list opened beneath it, then
    /// lets the welcome go once it has faded.
    private func leave() {
        guard leaving == nil else { return }
        let now = Date.now
        let moment = moment(at: now)
        haptics.stop()
        leaving = Leaving(date: now, longitude: moment.longitude, leg: moment.leg, dive: moment.dive)
        onLanding()
        Task {
            let landed = reduceMotion ? 0 : Self.turning + Self.unrolling
            try? await Task.sleep(for: .seconds(landed + Self.fading))
            onFinish(touched.compactMapValues { $0.level == .never ? nil : $0.level })
        }
    }

    /// The shorter way round from one longitude to another, in degrees, east positive.
    private static func shortestTurn(from start: Double, to end: Double) -> Double {
        var turn = (end - start).truncatingRemainder(dividingBy: 360)
        if turn > 180 { turn -= 360 }
        if turn < -180 { turn += 360 }
        return turn
    }

    /// The World in the person's hands, from when they first touched it.
    private struct HandSpin {
        var since: Date
        /// How the tour was when they took hold, to ease away from.
        var leg: WelcomeLeg?
        var dive: Double
        var levels: [String: VisitLevel]
        var fill: Double
        /// The longitude when the finger last came down or lifted.
        var longitude: Double
        /// While a finger is on the World, how far it has turned it, in degrees.
        var dragTurn: Double?
        /// When the finger last lifted, and how fast it was turning the World then, in degrees a second.
        var released: Date
        var velocity: Double = 0
    }

    private struct Leaving {
        var date: Date
        var longitude: Double
        var leg: WelcomeLeg?
        var dive: Double
    }

    /// A country the person has given a level: the level, when, and the colour of its ring.
    private struct Touch {
        var level: VisitLevel
        var date: Date
        var ripple: Color
    }

    /// The country in the bar, and when it was tapped.
    private struct Chosen {
        var id: String
        var date: Date
    }

    /// A country lighting up and fading once, in one of Game Mode's colours.
    private struct Twinkle {
        var id: String
        var color: Color
        var start: Date
    }
}

/// A twinkling country's flag and name, rising gently above it as it lights up and fades, white
/// on a dark halo to read over the globe.
private struct GlobeCaption: View {
    var caption: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Content {
        var regionID: String
        var name: String
        var language: Locale.Language?
        var flagAssetName: String
        /// The top of the country's main body, in the scene's space.
        var point: CGPoint
        /// From 0 as it lights up to 1 as it has faded.
        var progress: Double
    }

    var body: some View {
        let envelope = sin(.pi * min(max(caption.progress, 0), 1))
        HStack(spacing: 7) {
            Image(caption.flagAssetName)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 2))
                .frame(width: 24, height: 16)
            Text(caption.name)
                .placeName(caption.language, kerning: -0.4)
                .font(.title3.weight(PlaceTypesetting.weight(.light, for: caption.language)))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .shadow(color: .black, radius: 1)
        .shadow(color: .black.opacity(0.9), radius: 3)
        .shadow(color: .black.opacity(0.6), radius: 10)
        .fixedSize()
        .scaleEffect(reduceMotion ? 1 : 0.94 + 0.06 * envelope, anchor: .bottom)
        .offset(y: reduceMotion ? 0 : 7 - 14 * caption.progress)
        .opacity(envelope)
        .accessibilityHidden(true)
    }
}

/// A stop on the welcome's tour: a country, the longitude that faces it, and the places it lights.
struct WelcomeLeg: Sendable {
    var collectionID: String
    /// The country among the World's places, which the globe closes in on.
    var worldPlaceID: String
    var longitude: Double
    var places: [Place]

    struct Place: Sendable {
        var id: String
        /// How far up the levels it climbs, from just above 0 to 1 for the top.
        var height: Double = 1
        /// The level it climbs to instead, for the person's own places: the one they're at.
        var levelID: String? = nil
    }
}

/// The World at one moment of the welcome.
private struct WorldFrame {
    var map: TravelMap?
    var rect: CGRect = .zero
    var camera = MapCamera()
    var statuses: [String: VisitLevel] = [:]
    var detail: TravelMap?
    var detailStatuses: [String: VisitLevel] = [:]
    var detailOpacity: Double = 0
    var detailFill: Double = 1
    var ripples: [GlobeRipple] = []
    var glows: [GlobeGlow] = []
    var captions: [GlobeCaption.Content] = []
    /// How much of the World shows, for fades in place of motion.
    var globeOpacity: Double = 1
    /// How much of space shows behind the World.
    var space: Double = 1
    var daylight: Double = 0
    var roundness: Double = 1
}

/// One dot for each level, filled in its colour up to the level reached, the reached one long.
private struct LevelDots: View {
    var levels: [VisitLevel]
    var reached: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(levels) { level in
                let rank = (levels.firstIndex(of: level) ?? 0) + 1
                Capsule()
                    .fill(rank <= reached ? AnyShapeStyle(level.color.gradient) : AnyShapeStyle(.white.opacity(0.22)))
                    .frame(width: rank == reached ? 24 : 8, height: 8)
            }
        }
        .animation(.bouncy, value: reached)
        // Unseen, the dots say what the levels are, in order.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Levels")
        .accessibilityValue(levels.map(\.name).formatted(.list(type: .and)))
    }
}

/// Where the open list's map is on screen. Kept aside from view state, since it moves with every
/// scroll and is read only by the welcome, as the World lands on it.
final class ListMapLocation {
    var frame: CGRect?
    var collectionID: String?

    func note(_ frame: CGRect, in collectionID: String) {
        self.frame = frame
        self.collectionID = collectionID
    }
}

/// The World's outlines for the welcome, the last ones kept, so a globe at rest isn't cut afresh
/// at every frame. A turning globe uses lighter outlines, quick to cut at every frame; one at rest,
/// the full detail.
private final class GlobeCache {
    private var globe: (longitude: Double, isTurning: Bool, map: TravelMap)?
    private var detailMap: (key: String, map: TravelMap)?
    private var unrolled: (key: String, map: TravelMap)?

    @MainActor func globe(_ world: Geography, longitude: Double, isTurning: Bool, step: Double = 0.05) -> TravelMap {
        let rounded = (longitude / step).rounded() * step
        if let globe, globe.longitude == rounded, globe.isTurning == isTurning { return globe.map }
        let map = isTurning
            ? world.turningMap(.globe, centerLongitude: rounded)
            : world.map(.globe, centerLongitude: rounded)
        globe = (rounded, isTurning, map)
        return map
    }

    /// A country's subdivisions on the globe turned to a longitude.
    @MainActor func detail(_ collectionID: String, longitude: Double) -> TravelMap? {
        let rounded = (longitude * 20).rounded() / 20
        let key = "\(collectionID)@\(rounded)"
        if let detailMap, detailMap.key == key { return detailMap.map }
        guard let map = Geography.subdivisions(of: collectionID)?.map(.globe, centerLongitude: rounded) else { return nil }
        detailMap = (key, map)
        return map
    }

    @MainActor func unrolled(_ world: Geography, to projection: MapProjection, center: MapCenter, progress: Double) -> TravelMap {
        let key = "\(projection.rawValue)-\(center.rawValue)-\(Int((progress * 400).rounded()))"
        if let unrolled, unrolled.key == key { return unrolled.map }
        // Lighter outlines while unrolling, quick enough for every frame; the full detail once flat,
        // to match the list's map exactly.
        let map = projection == .globe || progress >= 1
            ? world.map(projection, center: center)
            : world.lightMap(from: .globe, to: projection, progress: progress, center: center)
        unrolled = (key, map)
        return map
    }
}

/// A low rumble that swells as the World flies in from deep space and fades as it slows, with a
/// soft thud as it comes to rest. Silent on devices without haptics.
private final class ArrivalHaptics {
    private var engine: CHHapticEngine?

    func playArrival(duration: TimeInterval) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            // Stops by itself once the rumble has played, rather than idling until the welcome ends.
            engine.isAutoShutdownEnabled = true
            try engine.start()
            let rumble = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.12),
                ],
                relativeTime: 0, duration: duration)
            let thud = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                ],
                relativeTime: duration)
            let swell = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.05),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.5, value: 0.9),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration * 0.85, value: 0.08),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration, value: 0),
                ],
                relativeTime: 0)
            let pattern = try CHHapticPattern(events: [rumble, thud], parameterCurves: [swell])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
    }
}

/// A round, prominent Liquid Glass button where there is one, or else a round bordered prominent one.
private struct ProminentGlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent).buttonBorderShape(.circle)
        } else {
            content.buttonStyle(.borderedProminent).buttonBorderShape(.circle)
        }
    }
}

/// A soft glow of the accent colour behind the arrow, slowly swelling and settling, or with Reduce
/// Motion, in Low Power Mode or while the app isn't in front, holding still, with nothing left
/// running behind it.
private struct ArrowGlow: View {
    /// Off with Reduce Motion, in Low Power Mode and while the app isn't in front.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion

    var body: some View {
        Group {
            if allowsAmbientMotion {
                glow
                    .phaseAnimator([false, true]) { view, isSwelled in
                        view
                            .scaleEffect(isSwelled ? 1.6 : 1.1)
                            .opacity(isSwelled ? 0.35 : 0.8)
                    } animation: { _ in
                        .easeInOut(duration: 1.8)
                    }
            } else {
                // Its own view, so the breathing starts afresh whenever it may move again.
                glow
                    .scaleEffect(1.25)
                    .opacity(0.6)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var glow: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.5))
            .blur(radius: 20)
    }
}

private extension View {
    /// Rises gently into place once `isShown`, and sinks away again when leaving; with Reduce
    /// Motion, fades.
    func appearing(_ isShown: Bool, isLeaving: Bool) -> some View {
        modifier(Appearing(isShown: isShown && !isLeaving, isLeaving: isLeaving))
    }
}

private struct Appearing: ViewModifier {
    var isShown: Bool
    var isLeaving: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : (isLeaving ? -12 : 18))
            .blur(radius: isShown || reduceMotion ? 0 : 6)
            .animation(isLeaving ? .smooth(duration: 0.4) : .smooth(duration: 0.8), value: isShown)
            .allowsHitTesting(isShown)
    }
}

/// Eases smoothly in and out between 0 and 1, with no jolt at either end.
private func smootherstep(_ x: Double) -> Double {
    let t = min(max(x, 0), 1)
    return t * t * t * (t * (t * 6 - 15) + 10)
}

/// 0 below `low`, 1 above `high`, and a smooth climb between.
private func smoothstep(_ low: Double, _ high: Double, _ x: Double) -> Double {
    let t = min(max((x - low) / (high - low), 0), 1)
    return t * t * (3 - 2 * t)
}
