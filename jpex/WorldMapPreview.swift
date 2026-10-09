import SwiftUI

/// The World map as it will look: it reshapes when the projection changes, and turns, like the
/// globe spinning, when the centre changes. Drag sideways to spin it by hand; let go and it
/// glides on to the nearest centre.
struct WorldMapPreview: View {
    var saveModel: SaveModel?
    var projection: MapProjection
    @Binding var center: MapCenter
    /// Off, the map sits still and plain: no turning by hand and no countries coloured by level,
    /// as when lists don't show their map.
    var isActive = true
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reshape: Reprojection?
    @State private var spinner = WorldSpinner()

    var body: some View {
        let world = CountryCatalog.world(applying: counting.rules)
        let snapshot = saveModel?.snapshot()
        let statuses = Dictionary(uniqueKeysWithValues: world.divisions.map {
            ($0.id, isActive ? snapshot?.status(for: $0) ?? .never : .never)
        })
        TimelineView(.animation(paused: reshape == nil && !spinner.isTurning)) { timeline in
            if let map = shownMap(at: timeline.date) {
                let focus = map.focusRect(including: [])
                if reshape == nil, Self.rectangularProjections.contains(projection) {
                    // A rectangular world runs on round the Earth, so it fills the row edge to edge,
                    // its copies side by side, with no margin at all.
                    TiledMap(aspectRatio: focus.width / max(focus.height, 1)) {
                        // Each copy meets the next without a seam, and lays out no copies of its own.
                        TravelMapCanvas(
                            map: map, statuses: statuses, minimumStatus: counting.rules.minimumLevel(in: ladder),
                            focus: focus, revealsOnAppear: false, wrapsAround: true, tiles: false)
                    }
                } else {
                    TravelMapCanvas(
                        map: map, statuses: statuses, minimumStatus: counting.rules.minimumLevel(in: ladder),
                        // A margin of sea all round, so no projection's edge touches the row's sides.
                        insets: EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18),
                        focus: focus, revealsOnAppear: false)
                }
            }
        }
        // Fills whatever room it's given, running edge to edge, with the map fitted inside.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .turnsWorld(spinner, center: $center, isEnabled: isActive)
        .onChange(of: center) { old, new in
            guard !reduceMotion else { return }
            spinner.glide(from: old, to: new)
        }
        .onChange(of: projection) { old, new in
            guard !reduceMotion else { return }
            let change = Reprojection(from: old, to: new, start: .now)
            reshape = change
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(Reprojection.duration))
                if reshape == change { reshape = nil }
            }
        }
    }

    /// Projections drawn as rectangles, which can be laid side by side without a seam.
    private static let rectangularProjections: Set<MapProjection> = [.mercator, .miller, .gallPeters, .equirectangular]

    private func shownMap(at date: Date) -> TravelMap? {
        guard let world = Geography.world else { return nil }
        if let longitude = spinner.longitude(at: date) {
            return world.turningMap(projection, centerLongitude: longitude)
        }
        if let reshape {
            return world.map(from: reshape.from, to: reshape.to, progress: reshape.progress(at: date), center: center)
        }
        return world.map(projection, center: center)
    }
}

/// One map drawn to the row's full height, with copies either side to fill its width, the middle
/// copy centred. A map wider than the row is simply cropped at its sides.
private struct TiledMap<Tile: View>: View {
    var aspectRatio: Double
    @ViewBuilder var tile: Tile

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let width = max(height * aspectRatio, 1)
            // An odd count, so one copy sits in the middle with equal parts either side.
            let copies = Int((proxy.size.width / width).rounded(.up)) | 1
            HStack(spacing: 0) {
                ForEach(0..<copies, id: \.self) { _ in
                    tile.frame(width: width, height: height)
                }
            }
            .frame(width: proxy.size.width, height: height)
            .clipped()
        }
    }
}

extension View {
    /// Lets a World map be spun by dragging sideways. Let go and it glides on to the nearest
    /// centre, which it saves. Up-and-down drags are left for scrolling.
    func turnsWorld(_ spinner: WorldSpinner, center: Binding<MapCenter>, isEnabled: Bool = true) -> some View {
        modifier(WorldTurning(spinner: spinner, center: center, isEnabled: isEnabled))
    }
}

extension View {
    /// Lets a globe left alone for a few seconds drift slowly east, for a couple of minutes at most,
    /// easing to a stop when touched. Off with Reduce Motion or in Low Power Mode.
    func driftsWorld(_ spinner: WorldSpinner, center: MapCenter, isEnabled: Bool) -> some View {
        modifier(WorldDrifting(spinner: spinner, center: center, isEnabled: isEnabled))
    }
}

private struct WorldDrifting: ViewModifier {
    var spinner: WorldSpinner
    var center: MapCenter
    var isEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Key: Equatable {
        var isOn: Bool
        var center: MapCenter
    }

    func body(content: Content) -> some View {
        content.task(id: Key(isOn: isEnabled && !reduceMotion, center: center)) {
            guard isEnabled, !reduceMotion else {
                spinner.brake()
                return
            }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                if spinner.hasDriftedLongEnough || ProcessInfo.processInfo.isLowPowerModeEnabled {
                    spinner.brake()
                } else if spinner.wantsToDrift {
                    spinner.startDrift(from: center)
                }
            }
            // Out of sight, it comes to rest rather than carrying on unseen.
            spinner.brake()
        }
    }
}

private struct WorldTurning: ViewModifier {
    var spinner: WorldSpinner
    @Binding var center: MapCenter
    var isEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width = 1.0

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onGeometryChange(for: Double.self) { $0.size.width } action: { width = max($0, 1) }
                .contentShape(.rect)
                .gesture(SidewaysPan { translation in
                    spinner.drag(by: translation, width: width, from: center)
                } onEnd: { translation, predicted in
                    if let nearest = spinner.release(
                        translation: translation, flungBy: predicted, width: width, reduceMotion: reduceMotion
                    ) {
                        center = nearest
                    }
                })
                // As the map settles on its centre, not as the finger lifts, the same as the full map.
                .sensoryFeedback(.alignment, trigger: spinner.landings)
        } else {
            content
        }
    }
}

/// Where a World map turned by hand is pointing: following the finger while it drags, then
/// carrying on with the fling's speed to a centre. A globe left alone drifts slowly east, the way
/// the Earth turns, and rests where it eases to a stop. Nil longitudes mean the map rests at its
/// saved centre.
@MainActor @Observable
final class WorldSpinner {
    /// The longitude the map was at when the drag began, and where the drag has turned it to.
    private var spin: (start: Double, longitude: Double)?
    private var turn: WorldTurn?
    /// The globe drifting on its own while it's left alone.
    private var drift: WorldDrift?
    /// Where a drift came to a stop, until the globe is turned by hand.
    private var restingLongitude: Double?
    /// When the map was last touched or changed, for knowing when it's been left alone.
    @ObservationIgnored private(set) var lastTouch = Date.now
    /// A drift comes once each time the map is left alone, so a map left for good comes to rest.
    @ObservationIgnored private var hasDriftedSinceTouch = false

    var isTurning: Bool { spin != nil || turn != nil || drift != nil }

    /// Counts the times the map settles on a centre after being turned, for a click as it lands.
    private(set) var landings = 0

    /// Whether the only motion is the slow drift, which needs far fewer frames than a finger.
    var isOnlyDrifting: Bool { spin == nil && turn == nil && drift != nil }

    func longitude(at date: Date) -> Double? {
        spin?.longitude ?? turn?.longitude(at: date) ?? drift?.longitude(at: date) ?? restingLongitude
    }

    /// The World in this projection as turned at this moment, or nil while it rests at its centre.
    /// At rest away from its centre, the coastlines come back in full detail.
    func turnedWorld(_ projection: MapProjection, at date: Date) -> TravelMap? {
        guard let longitude = longitude(at: date) else { return nil }
        return isTurning
            ? Geography.world?.turningMap(projection, centerLongitude: longitude)
            : Geography.world?.map(projection, centerLongitude: longitude)
    }

    /// Half a turn of the Earth across the map's width, so the World follows the finger.
    func drag(by translation: Double, width: Double, from center: MapCenter) {
        let start = spin?.start ?? longitude(at: .now) ?? center.longitude
        touch()
        turn = nil
        drift = nil
        restingLongitude = nil
        publish()
        spin = (start, start - translation / max(width, 1) * 180)
    }

    /// Ends a drag and returns the centre the World comes to rest on. A fling carries on at the
    /// finger's speed, slowing to the centre nearest where it would have stopped, still turning the
    /// same way; a gentle let-go glides to the nearest. Nothing moves when motion is reduced.
    func release(translation: Double, flungBy predicted: Double, width: Double, reduceMotion: Bool) -> MapCenter? {
        guard let spin else { return nil }
        self.spin = nil
        touch()
        // The finger's speed in degrees of longitude a second; dragging right turns the World west.
        let speed = -(predicted - translation) / 0.2 / max(width, 1) * 180
        if !reduceMotion, let fling = WorldTurn.fling(from: spin.longitude, speed: speed) {
            play(fling.turn)
            return fling.center
        }
        let flung = spin.start - predicted / max(width, 1) * 180
        guard let nearest = MapCenter.allCases.min(by: {
            abs(Self.offset(from: $0.longitude, to: flung)) < abs(Self.offset(from: $1.longitude, to: flung))
        }) else { return nil }
        if reduceMotion {
            // Nothing glides, so it settles at once.
            landings += 1
        } else {
            glide(fromLongitude: spin.longitude, to: nearest.longitude)
        }
        return nearest
    }

    /// Turns the short way round to a new centre, carrying on from wherever a turn under way has reached.
    func glide(from old: MapCenter, to new: MapCenter) {
        guard spin == nil else { return }
        // A fling already on its way to this centre keeps its speed and direction.
        if let turn, abs(Self.offset(from: turn.to, to: new.longitude)) < 0.5 { return }
        let from = longitude(at: .now) ?? old.longitude
        drift = nil
        restingLongitude = nil
        publish()
        guard Self.offset(from: from, to: new.longitude) != 0 else { return }
        glide(fromLongitude: from, to: new.longitude)
    }

    /// One whole turn of the Earth, westward, back round to the same centre: just for fun, as when
    /// the list is pulled down past its top. Waits for a turn already under way.
    func spinAround(from center: MapCenter) {
        guard spin == nil, turn == nil else { return }
        touch()
        let from = longitude(at: .now) ?? center.longitude
        drift = nil
        restingLongitude = nil
        publish()
        // Westward back to the centre, from a globe resting elsewhere, then once more round.
        var westward = (from - center.longitude).truncatingRemainder(dividingBy: 360)
        if westward < 0 { westward += 360 }
        play(WorldTurn(from: from, to: from - westward - 360, start: .now))
    }

    private func glide(fromLongitude from: Double, to longitude: Double) {
        play(WorldTurn(from: from, to: from + Self.offset(from: from, to: longitude), start: .now))
    }

    /// Plays a turn, then lets the map rest at its centre, with a click as it lands.
    private func play(_ next: WorldTurn) {
        turn = next
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(next.length))
            guard let self, self.turn == next else { return }
            self.turn = nil
            self.landings += 1
        }
    }

    // MARK: Drifting

    /// Notes a touch or a change on the map: a drift under way eases to a stop, and the map waits
    /// to be left alone again before drifting once more.
    func touch() {
        lastTouch = .now
        hasDriftedSinceTouch = false
        brake()
    }

    /// Whether the globe has been left alone long enough to drift, and hasn't drifted since.
    var wantsToDrift: Bool {
        spin == nil && turn == nil && drift == nil && !hasDriftedSinceTouch
            && Date.now.timeIntervalSince(lastTouch) > WorldDrift.idleDelay
    }

    /// Whether a drift has gone on long enough, so a map left for good comes to rest.
    var hasDriftedLongEnough: Bool {
        drift.map { $0.braking == nil && Date.now.timeIntervalSince($0.start) > WorldDrift.longest } ?? false
    }

    /// Sets the globe drifting from wherever it rests.
    func startDrift(from center: MapCenter) {
        guard spin == nil, turn == nil, drift == nil else { return }
        hasDriftedSinceTouch = true
        drift = WorldDrift(from: restingLongitude ?? center.longitude, start: .now)
        restingLongitude = nil
        publish()
    }

    /// Eases a drift to a stop where it is, and rests there.
    func brake() {
        guard var slowing = drift, slowing.braking == nil else { return }
        slowing.braking = .now
        drift = slowing
        publish()
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(WorldDrift.brakingTime))
            guard let self, self.drift == slowing else { return }
            self.restingLongitude = slowing.longitude(at: .now)
            self.drift = nil
            self.publish()
        }
    }

    /// Back to the saved centre at once, as when the full map has taken this one's place.
    func reset() {
        spin = nil
        turn = nil
        drift = nil
        restingLongitude = nil
        lastTouch = .now
        hasDriftedSinceTouch = false
        publish()
    }

    /// How the World card's globe is turned away from its saved centre by drifting: what maps that
    /// take its place, such as the full map growing out of it or the flight into a country, start
    /// from, so they don't jump.
    struct Shown {
        var drift: WorldDrift?
        var rest: Double?
        var since: Date
        /// When the card stopped showing it, as when it was turned by hand or the list changed.
        var until: Date?

        /// Where the globe was turned to at a moment, or nil if it wasn't drifting or resting then.
        func longitude(at date: Date) -> Double? {
            guard date >= since.addingTimeInterval(-0.05), until.map({ date <= $0.addingTimeInterval(0.3) }) ?? true
            else { return nil }
            return drift?.longitude(at: date) ?? rest
        }
    }

    /// The drift or rest of the globe card in view, kept as times and speeds so anything can tell
    /// where it was at any moment. Only a drifting globe sets it.
    private(set) static var shown: Shown?

    /// The spinner whose globe `shown` describes; another one turning doesn't end it.
    private static var publisher: ObjectIdentifier?

    /// Records what this globe is showing for the maps that take its place, and when that ended.
    private func publish() {
        if drift != nil || restingLongitude != nil {
            Self.shown = Shown(drift: drift, rest: restingLongitude, since: .now)
            Self.publisher = ObjectIdentifier(self)
        } else if Self.publisher == ObjectIdentifier(self), Self.shown?.until == nil {
            Self.shown?.until = .now
        }
    }

    /// The shortest way round from one longitude to another, in degrees east.
    nonisolated static func offset(from start: Double, to end: Double) -> Double {
        var degrees = (end - start).truncatingRemainder(dividingBy: 360)
        if degrees > 180 { degrees -= 360 }
        if degrees < -180 { degrees += 360 }
        return degrees
    }
}

extension TravelMap {
    /// Whether a map's places are the World's countries, which can be turned to another centre.
    /// Collections share at most a handful of World records, such as Taiwan in China's list.
    static func showsWorld(places: some Collection<String>) -> Bool {
        places.count { $0.hasPrefix("WORLD-") } > 50
    }
}

/// The map's centre gliding from one longitude to another.
struct WorldTurn: Equatable {
    static let duration = 0.9

    var from: Double
    var to: Double
    var start: Date
    var length: TimeInterval = WorldTurn.duration
    /// Whether it sets off at full speed and only slows, as after a fling, rather than easing in and out.
    var coasts = false

    func longitude(at date: Date) -> Double {
        let linear = min(max(date.timeIntervalSince(start) / length, 0), 1)
        let eased = coasts ? 1 - pow(1 - linear, 3) : linear * linear * (3 - 2 * linear)
        var longitude = from + (to - from) * eased
        longitude = (longitude + 180).truncatingRemainder(dividingBy: 360)
        if longitude < 0 { longitude += 360 }
        return longitude - 180
    }

    /// Carries on from a fling at the finger's own speed, in degrees a second, east positive. The
    /// World slows as if it turned on a well-oiled axle and comes to rest on the centre nearest
    /// where it would have stopped by itself, still turning the way it was flung: a hard fling
    /// can go once or twice round. Nil for a let-go too gentle to be a fling.
    static func fling(from longitude: Double, speed: Double, start: Date = .now) -> (turn: WorldTurn, center: MapCenter)? {
        guard abs(speed) >= 60 else { return nil }
        // Where friction alone would bring it to rest.
        let natural = longitude + min(max(speed * 0.55, -800), 800)
        var best: (offset: Double, center: MapCenter)?
        for center in MapCenter.allCases {
            for lap in -3...3 {
                let offset = center.longitude + Double(lap) * 360 - longitude
                // Only centres ahead, in the direction it's turning.
                guard offset * speed > 0 else { continue }
                if best.map({ abs(longitude + offset - natural) < abs(longitude + $0.offset - natural) }) ?? true {
                    best = (offset, center)
                }
            }
        }
        guard let best else { return nil }
        // Easing out by a cubic sets off at three times the average speed, so match the finger's.
        let length = min(max(3 * abs(best.offset) / abs(speed), 0.5), 3.2)
        return (WorldTurn(from: longitude, to: longitude + best.offset, start: start, length: length, coasts: true), best.center)
    }
}

/// A globe drifting slowly east on its own, the way the Earth turns: easing up to speed from rest,
/// and once braked, slowing to a stop.
struct WorldDrift: Equatable {
    /// Degrees a second: once round in a little over two minutes.
    static let speed = 2.5
    static let rampUp = 2.0
    static let brakingTime = 0.6
    /// How long the globe waits, left alone, before it drifts.
    static let idleDelay = 4.0
    /// How long it drifts at most before coming to rest until it's next touched.
    static let longest = 120.0

    var from: Double
    var start: Date
    var braking: Date?

    func longitude(at date: Date) -> Double {
        let running = max((braking ?? date).timeIntervalSince(start), 0)
        var travelled = running < Self.rampUp
            ? Self.speed * running * running / (2 * Self.rampUp)
            : Self.speed * (running - Self.rampUp / 2)
        if let braking {
            let speed = Self.speed * min(running / Self.rampUp, 1)
            let slowing = min(max(date.timeIntervalSince(braking), 0), Self.brakingTime)
            travelled += speed * (slowing - slowing * slowing / (2 * Self.brakingTime))
        }
        // The Earth turns east, so the land in the middle moves on and land from the west comes in.
        return DayNight.normalized(from - travelled)
    }
}

/// A pan that only starts when the finger moves more sideways than up or down, so a scrolling
/// page around it still scrolls, and a tap on what it covers still taps.
struct SidewaysPan: UIGestureRecognizerRepresentable {
    var onChange: (Double) -> Void
    /// The translation when the finger lifts, and where its speed would have carried it.
    var onEnd: (Double, Double) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed:
            onChange(translation)
        case .ended, .cancelled, .failed:
            onEnd(translation, translation + recognizer.velocity(in: recognizer.view).x * 0.2)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
