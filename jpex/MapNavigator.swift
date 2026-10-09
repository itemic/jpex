import SwiftUI

/// Where the full-screen map is looking: the maps flown into, each one's camera, and the place
/// whose callout is open. Cameras are kept apart from the rest so moving one redraws only the map.
@MainActor
@Observable
final class MapNavigator {
    private(set) var stops: [MapStop]
    private(set) var cameras: [String: MapCamera] = [:]
    var selection: MapSelection?
    /// Which way the last flight went, so the outgoing and incoming maps know how to cross over.
    private(set) var direction = FlightDirection.inward
    private(set) var isFlying = false
    /// Whether the camera has flown into another map yet; a map coming back into view isn't revealed again.
    private(set) var hasFlown = false
    /// How far the map has been pulled down to put it away.
    var pullOffset: CGSize = .zero
    /// A change of projection under way on the World map.
    private(set) var reprojection: Reprojection?
    /// How far a country's subdivisions have arrived over the World map, from 0 to 1.
    private(set) var detailProgress: Double = 0
    /// How far the arrived subdivisions have moved into the country's own map, from 0 to 1.
    private(set) var morphProgress: Double = 0
    /// Whether the subdivisions are leaving, so their borders fade rather than retrace.
    private(set) var isDrainingSubdivisions = false
    /// For a country's own map that its subdivisions settled into from the World: the stop it
    /// replaced and the World's camera then, for flying back out the way it came.
    @ObservationIgnored private var settledFrom: [String: (stop: MapStop, camera: MapCamera)] = [:]
    /// The size of the map on screen and the room kept clear around it, kept up to date by the map.
    @ObservationIgnored private(set) var layout = MapLayout()
    @ObservationIgnored private var returnCameras: [String: MapCamera] = [:]
    @ObservationIgnored private var gestureStart: MapCamera?

    /// Where the World map is centred, for reshaping it into another projection. Turning the
    /// World by hand settles on a new one.
    private(set) var center: MapCenter
    /// The projection the World map is drawn in.
    private(set) var worldProjection: MapProjection = .current
    /// The longitude a hand-turned globe faces, or nil while it faces its usual centre.
    private(set) var globeLongitude: Double?
    @ObservationIgnored private var turnStart: Double?
    @ObservationIgnored private var spin: Task<Void, Never>?
    /// Whether `spin` is still turning the World.
    @ObservationIgnored private var isSpinning = false
    /// When the map was last touched, for knowing when it's been left alone.
    @ObservationIgnored private var lastTouch = Date.now
    /// How fast a globe left alone is drifting, in degrees a second.
    @ObservationIgnored private var driftSpeed = 0.0

    /// The longitude the World is cut around: the turned globe's, or the usual centre's.
    var centerLongitude: Double { globeLongitude ?? center.longitude }

    init(collection: Country, map: TravelMap, center: MapCenter = .current) {
        stops = [MapStop(collection: collection, map: map)]
        self.center = center
        // A globe that had drifted in its card carries on from there, so it grows out of the card
        // without turning.
        if collection.id == CountryCatalog.world.id, worldProjection == .globe,
           let longitude = WorldSpinner.shown?.longitude(at: .now), let geography = Geography.world {
            globeLongitude = longitude
            stops[0].map = geography.map(worldProjection, centerLongitude: longitude)
        }
    }

    var current: MapStop { stops[stops.count - 1] }
    var previous: MapStop? { stops.count > 1 ? stops[stops.count - 2] : nil }

    var camera: MapCamera {
        get { cameras[current.id] ?? MapCamera() }
        set { cameras[current.id] = newValue }
    }

    var maximumZoom: CGFloat { current.collection.id == CountryCatalog.world.id ? 16 : 8 }

    /// The current map's layout on screen with its camera.
    var geometry: MapGeometry {
        MapGeometry(focus: current.focus, size: layout.size, zoom: camera.zoom, pan: camera.pan, insets: layout.insets)
    }

    /// Takes the map's new size, such as after rotating or unfolding the device, and keeps the
    /// camera's view of the map in bounds for it.
    func updateLayout(_ newLayout: MapLayout) {
        let oldLayout = layout
        layout = newLayout
        guard oldLayout.size != .zero, oldLayout.size != newLayout.size, gestureStart == nil, !isFlying,
              let zoom = cameras[current.id]?.zoom
        else { return }
        camera = zoom > 1.01 ? MapCamera(zoom: zoom, pan: clampedPan(camera.pan, zoom: zoom)) : MapCamera()
    }

    // MARK: Gestures

    /// Pinch around the gesture's starting point while dragging. With `resists`, the map gives less
    /// and less the further it's pulled past its edges or its zoom limits, like a rubber band, and
    /// springs back when let go; without it, there's a little give past the limits.
    func moveCamera(magnification: CGFloat, anchor: CGPoint, translation: CGSize, resists: Bool = false) {
        let start = gestureStart ?? camera
        if gestureStart == nil {
            gestureStart = start
            touch()
        }
        let proposed = start.zoom * magnification
        let zoom = resists ? Self.resisted(zoom: proposed, within: 1...maximumZoom) : min(max(proposed, 0.6), maximumZoom * 1.2)
        let base = CGPoint(x: (anchor.x - start.pan.width) / start.zoom, y: (anchor.y - start.pan.height) / start.zoom)
        let pan = CGSize(
            width: anchor.x + translation.width - base.x * zoom,
            height: anchor.y + translation.height - base.y * zoom)
        camera = MapCamera(zoom: zoom, pan: resists ? resistedPan(pan, zoom: zoom) : pan)
    }

    /// Pinched out this far, the map lets go: back out to the map it was flown into from, or closed.
    static let letGoZoom: CGFloat = 0.86

    /// Whether the camera has been pulled past its zoom limits or its edges, so it springs back.
    var isPastLimits: Bool {
        let zoom = camera.zoom
        guard zoom >= 0.999, zoom <= maximumZoom + 0.001 else { return true }
        let settled = zoom > 1.01 ? clampedPan(camera.pan, zoom: zoom) : .zero
        return abs(settled.width - camera.pan.width) > 0.5 || abs(settled.height - camera.pan.height) > 0.5
    }

    /// A zoom past its limits, held back like a rubber band: never more than 40% closer than the
    /// closest view, or much past halfway below the whole map.
    private static func resisted(zoom: CGFloat, within limits: ClosedRange<CGFloat>) -> CGFloat {
        let value = log(max(zoom, 0.0001))
        let low = log(limits.lowerBound)
        let high = log(limits.upperBound)
        if value > high { return exp(high + rubberBand(value - high, limit: log(1.4))) }
        if value < low { return exp(low - rubberBand(low - value, limit: log(1 / 0.55))) }
        return zoom
    }

    /// A pan past the map's edges, held back the same way, never more than a third of the view.
    private func resistedPan(_ proposed: CGSize, zoom: CGFloat) -> CGSize {
        let allowed = clampedPan(proposed, zoom: zoom)
        func resist(_ value: CGFloat, to allowed: CGFloat, limit: CGFloat) -> CGFloat {
            let past = value - allowed
            return allowed + (past < 0 ? -1 : 1) * Self.rubberBand(abs(past), limit: limit)
        }
        return CGSize(
            width: resist(proposed.width, to: allowed.width, limit: max(layout.size.width, 1) / 3),
            height: resist(proposed.height, to: allowed.height, limit: max(layout.size.height, 1) / 3))
    }

    /// How far a rubber band gives when pulled `distance`: about half of it at first, then less and
    /// less, never past `limit`.
    static func rubberBand(_ distance: CGFloat, limit: CGFloat) -> CGFloat {
        guard limit > 0 else { return 0 }
        return limit * (1 - 1 / (distance * 0.55 / limit + 1))
    }

    /// Brings zoom back within its limits and keeps the map in view, carrying any fling.
    func settleCamera(fling: CGSize, animation: Animation?) {
        gestureStart = nil
        withAnimation(animation) {
            let zoom = min(max(camera.zoom, 1), maximumZoom)
            guard zoom > 1.01 else {
                camera = MapCamera()
                return
            }
            let area = geometry.fitArea
            let base = CGPoint(x: (area.midX - camera.pan.width) / camera.zoom, y: (area.midY - camera.pan.height) / camera.zoom)
            let target = CGSize(
                width: area.midX - base.x * zoom + fling.width,
                height: area.midY - base.y * zoom + fling.height)
            camera = MapCamera(zoom: zoom, pan: clampedPan(target, zoom: zoom))
        }
    }

    func cancelGesture() {
        gestureStart = nil
    }

    func toggleZoom(at location: CGPoint, animation: Animation?) {
        withAnimation(animation) {
            if camera.zoom > 1.5 {
                camera = MapCamera()
            } else {
                let zoom = min(camera.zoom * 3, maximumZoom)
                let base = CGPoint(x: (location.x - camera.pan.width) / camera.zoom, y: (location.y - camera.pan.height) / camera.zoom)
                let area = geometry.fitArea
                let target = CGSize(width: area.midX - base.x * zoom, height: area.midY - base.y * zoom)
                camera = MapCamera(zoom: zoom, pan: clampedPan(target, zoom: zoom))
            }
        }
    }

    func showAll(animation: Animation?) {
        withAnimation(animation) { camera = MapCamera() }
    }

    /// Keeps a zoomed map covering the clear area, or centred in it where it is smaller.
    private func clampedPan(_ proposed: CGSize, zoom: CGFloat) -> CGSize {
        let unpanned = MapGeometry(focus: current.focus, size: layout.size, zoom: zoom, pan: .zero, insets: layout.insets)
        let content = current.focus.applying(unpanned.transform)
        let area = unpanned.fitArea
        func clamp(_ value: CGFloat, start: CGFloat, length: CGFloat, areaStart: CGFloat, areaLength: CGFloat) -> CGFloat {
            guard length > areaLength else { return areaStart + (areaLength - length) / 2 - start }
            return min(max(value, areaStart + areaLength - (start + length)), areaStart - start)
        }
        return CGSize(
            width: clamp(proposed.width, start: content.minX, length: content.width, areaStart: area.minX, areaLength: area.width),
            height: clamp(proposed.height, start: content.minY, length: content.height, areaStart: area.minY, areaLength: area.height))
    }

    // MARK: Places

    /// Opens the callout for the place drawn at a point, or closes it when there is none there.
    /// Small places are drawn as dots, so they get a generous touch target. Returns whether a place was found.
    @discardableResult
    func select(
        at location: CGPoint, places: [String: AdministrativeDivision],
        detailPlaces: [String: AdministrativeDivision] = [:], reduceMotion: Bool = false
    ) -> Bool {
        if let detail = current.detail {
            if let region = detail.place(at: location, geometry: geometry, among: Set(detailPlaces.keys)),
               let place = detailPlaces[region.id] {
                selection = selection?.place.id == place.id ? nil : MapSelection(place: place, regionID: region.id)
                return true
            }
            // A tap elsewhere in the world flies back out to it.
            if current.map.place(at: location, geometry: geometry, among: Set(places.keys)) != nil {
                flyBack(reduceMotion: reduceMotion)
                return true
            }
            selection = nil
            return false
        }
        guard let region = current.map.place(at: location, geometry: geometry, among: Set(places.keys)),
              let place = places[region.id]
        else {
            selection = nil
            return false
        }
        selection = selection?.place.id == place.id ? nil : MapSelection(place: place, regionID: region.id)
        return true
    }

    /// Glides the camera to a place and opens its callout.
    func focus(on place: AdministrativeDivision, animation: Animation?) {
        guard let region = (current.detail ?? current.map).region(id: place.id) else {
            withAnimation(animation) { selection = MapSelection(place: place, regionID: nil) }
            return
        }
        let core = region.coreBounds
        // Frame the place with plenty of map around it, never pulling back past the whole map.
        var target = geometry.camera(fitting: core.insetBy(dx: -core.width * 1.4, dy: -core.height * 1.4))
        if target.zoom < 1 || target.zoom > maximumZoom {
            target = geometry.camera(centering: CGPoint(x: core.midX, y: core.midY), zoom: min(max(target.zoom, 1), maximumZoom))
        }
        target.pan = clampedPan(target.pan, zoom: target.zoom)
        withAnimation(animation) {
            camera = target
            selection = MapSelection(place: place, regionID: region.id)
        }
    }

    // MARK: Flights

    /// Flies the camera into a country on the World map, then draws the country's subdivisions over
    /// it in the same projection: their outlines trace themselves in and their colours flood across
    /// while the rest of the World washes out. Given the country's own map, the subdivisions then
    /// move into it, and the country's map takes over just as if it had been opened directly.
    func fly(
        into collection: Country, subdivisions: TravelMap, local: TravelMap?, from regionID: String?, reduceMotion: Bool
    ) {
        guard !isFlying else { return }
        isFlying = true
        hasFlown = true
        returnCameras[current.id] = camera
        let base = current
        let region = regionID.flatMap { base.map.region(id: $0) }
        let target = region.map { geometry.camera(fitting: $0.coreBounds) } ?? camera
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.8)) {
            selection = nil
            camera = target
        } completion: {
            // The country shares the World's map and camera, so nothing moves as it takes over.
            self.detailProgress = 0
            self.morphProgress = 0
            self.isDrainingSubdivisions = false
            self.cameras[collection.id] = self.camera
            self.stops.append(MapStop(collection: collection, subdivisions: subdivisions, local: local, over: base))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.9)) {
                self.detailProgress = 1
            } completion: {
                if local == nil { self.isFlying = false }
            }
            guard local != nil else { return }
            // The subdivisions start moving into the country's map while the last of them colour in.
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 0.55))
                withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.9)) {
                    self.morphProgress = 1
                } completion: {
                    self.settle()
                    self.isFlying = false
                }
            }
        }
    }

    /// Swaps the arrived subdivisions for the country's own map, drawn exactly as the morph ended,
    /// so it can be explored like a map opened directly.
    private func settle() {
        let arrived = current
        guard let local = arrived.local else { return }
        settledFrom[arrived.id] = (arrived, camera)
        stops[stops.count - 1] = MapStop(collection: arrived.collection, map: local, layer: arrived.layerID)
        cameras[arrived.id] = MapCamera()
        morphProgress = 0
        detailProgress = 0
    }

    /// Fades a country's subdivisions away while the camera pulls back out to where it was.
    private func drainSubdivisions(reduceMotion: Bool) {
        let leaving = current
        let base = stops[stops.count - 2]
        let destination = returnCameras.removeValue(forKey: base.id) ?? MapCamera()
        isDrainingSubdivisions = true
        withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.85)) {
            detailProgress = 0
            camera = destination
        } completion: {
            self.isDrainingSubdivisions = false
            self.stops.removeLast()
            self.cameras[leaving.id] = nil
            self.cameras[base.id] = destination
            self.isFlying = false
        }
    }

    /// Flies the camera onto a place, then crosses over into that place's own map.
    func fly(into collection: Country, map: TravelMap, from regionID: String?, reduceMotion: Bool) {
        guard !isFlying else { return }
        isFlying = true
        hasFlown = true
        direction = .inward
        returnCameras[current.id] = camera
        let region = regionID.flatMap { current.map.region(id: $0) }
        let target = region.map { geometry.camera(fitting: $0.coreBounds) } ?? camera
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.75)) {
            selection = nil
            camera = target
        } completion: {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: 0.6)) {
                self.stops.append(MapStop(collection: collection, map: map))
            } completion: {
                self.isFlying = false
            }
        }
    }

    /// Crosses back to the map before, still close in on the place, then pulls out to where it was.
    func flyBack(reduceMotion: Bool) {
        guard stops.count > 1, !isFlying else { return }
        isFlying = true
        selection = nil
        if let settled = settledFrom[current.id] {
            // Back to the country's map as it settled, then into the World's projection, then the
            // subdivisions drain away as the camera pulls out.
            let country = current
            let unsettle = {
                self.settledFrom[country.id] = nil
                self.stops[self.stops.count - 1] = settled.stop
                self.cameras[country.id] = settled.camera
                self.detailProgress = 1
                self.morphProgress = 1
                withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .smooth(duration: 0.8)) {
                    self.morphProgress = 0
                }
                // The camera starts pulling out as the subdivisions take the World's shape again.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 0.5))
                    self.drainSubdivisions(reduceMotion: reduceMotion)
                }
            }
            if camera == MapCamera() {
                unsettle()
            } else {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) { camera = MapCamera() } completion: { unsettle() }
            }
            return
        }
        if current.detail != nil {
            drainSubdivisions(reduceMotion: reduceMotion)
            return
        }
        direction = .outward
        // Give both maps a frame to pick up the outward crossing before they swap.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(30))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: 0.55)) {
                let left = self.stops.removeLast()
                self.cameras[left.id] = nil
            } completion: {
                let destination = self.returnCameras.removeValue(forKey: self.current.id) ?? MapCamera()
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.8)) {
                    self.camera = destination
                } completion: {
                    self.isFlying = false
                }
            }
        }
    }

    // MARK: Turning the globe

    /// Whether a sideways drag turns the World: the World map in any projection, seen whole.
    var canTurnGlobe: Bool {
        current.id == CountryCatalog.world.id && current.detail == nil
            && camera.zoom <= 1.01 && reprojection == nil && !isFlying
    }

    /// Turns the World with a drag; a drag across the whole map turns it half way round.
    func turnGlobe(by translation: CGFloat) {
        spin?.cancel()
        isSpinning = false
        driftSpeed = 0
        let start = turnStart ?? centerLongitude
        if turnStart == nil {
            turnStart = start
            touch()
        }
        setGlobeLongitude(start - Double(translation / max(globeWidth, 1)) * 180)
    }

    /// Lets go of the World. Flung, it carries on at the finger's speed and slows to the centre
    /// nearest where it would have stopped, still turning the same way; let go gently, it glides to
    /// the nearest centre. Returns that centre, for saving.
    @discardableResult
    func endTurningGlobe(velocity: CGFloat, reduceMotion: Bool) -> MapCenter? {
        turnStart = nil
        touch()
        guard let from = globeLongitude else { return nil }
        // The finger's speed in degrees of longitude a second; dragging right turns the World west.
        let speed = -Double(velocity / max(globeWidth, 1)) * 180
        let fling = reduceMotion ? nil : WorldTurn.fling(from: from, speed: speed)
        let flung = from - Double(velocity * 0.2 / max(globeWidth, 1)) * 180
        guard let nearest = fling?.center ?? MapCenter.allCases.min(by: {
            abs(WorldSpinner.offset(from: $0.longitude, to: flung)) < abs(WorldSpinner.offset(from: $1.longitude, to: flung))
        }) else { return nil }
        let turn = fling?.turn
            ?? WorldTurn(from: from, to: from + WorldSpinner.offset(from: from, to: nearest.longitude), start: .now)
        spin(through: turn, reduceMotion: reduceMotion) { self.settle(at: nearest) }
        return nearest
    }

    /// Turns the World a frame at a time, then does what follows.
    private func spin(through turn: WorldTurn, reduceMotion: Bool, then finish: @escaping @MainActor () -> Void) {
        spin?.cancel()
        isSpinning = true
        spin = Task { @MainActor in
            if !reduceMotion {
                while !Task.isCancelled, Date.now.timeIntervalSince(turn.start) < turn.length {
                    setGlobeLongitude(turn.longitude(at: .now))
                    try? await Task.sleep(for: .milliseconds(16))
                }
            }
            guard !Task.isCancelled else { return }
            isSpinning = false
            finish()
        }
    }

    /// Turns a globe that drifted away from its centre back home as the map closes into its card,
    /// which shows the centre.
    func turnHome(reduceMotion: Bool) {
        guard let from = globeLongitude, turnStart == nil else { return }
        driftSpeed = 0
        touch()
        let home = center
        let turn = WorldTurn(
            from: from, to: from + WorldSpinner.offset(from: from, to: home.longitude), start: .now, length: 0.5)
        spin(through: turn, reduceMotion: reduceMotion) { self.settle(at: home) }
    }

    // MARK: Drifting

    /// Notes a touch on the map: a globe drifting on its own eases to a stop.
    func touch() {
        lastTouch = .now
    }

    /// Whether nothing else is moving the globe, so it may drift: the World seen whole on the globe,
    /// with no finger on it and no flight, turn or change of projection under way.
    private var isStill: Bool {
        worldProjection == .globe && canTurnGlobe && turnStart == nil && gestureStart == nil && !isSpinning
            && pullOffset == .zero
    }

    /// Runs while the map is open: a globe left alone for a few seconds drifts slowly east, the way
    /// the Earth turns, easing up to speed. A touch or an open callout eases it to a stop where it
    /// is, and after a couple of minutes it rests until it's next touched. Nothing drifts with
    /// Reduce Motion or in Low Power Mode.
    func driftWhileIdle(reduceMotion: Bool) async {
        guard !reduceMotion else { return }
        var last = Date.now
        var drifted = 0.0
        var hasMoved = false
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(33))
            let now = Date.now
            let step = min(now.timeIntervalSince(last), 0.1)
            last = now
            guard isStill else {
                // Something else has the globe; let it go at once.
                driftSpeed = 0
                hasMoved = false
                continue
            }
            let idle = now.timeIntervalSince(lastTouch)
            if idle < WorldDrift.idleDelay { drifted = 0 }
            let wants = idle >= WorldDrift.idleDelay && selection == nil && drifted < WorldDrift.longest
                && !ProcessInfo.processInfo.isLowPowerModeEnabled
            let target = wants ? WorldDrift.speed : 0
            // Slow to get going, quick to stop.
            let ease = target > driftSpeed ? step / WorldDrift.rampUp * 2.5 : step / WorldDrift.brakingTime * 4
            driftSpeed += (target - driftSpeed) * min(ease, 1)
            guard driftSpeed >= 0.02 || target > 0 else {
                driftSpeed = 0
                if hasMoved {
                    hasMoved = false
                    rest()
                }
                continue
            }
            if wants { drifted += step }
            hasMoved = true
            // The Earth turns east, so the middle of the map moves on to the west.
            setGlobeLongitude(centerLongitude - driftSpeed * step)
        }
    }

    /// Rests the globe where its drift stopped, with its coastlines back in full detail.
    private func rest() {
        guard let longitude = globeLongitude, let geography = Geography.world,
              let index = stops.firstIndex(where: { $0.id == CountryCatalog.world.id }) else { return }
        stops[index].map = geography.map(worldProjection, centerLongitude: longitude)
    }

    /// Rests the World at a centre, with its coastlines back in full detail.
    private func settle(at center: MapCenter) {
        guard let geography = Geography.world,
              let index = stops.firstIndex(where: { $0.id == CountryCatalog.world.id }) else { return }
        self.center = center
        globeLongitude = nil
        stops[index].map = geography.map(worldProjection, center: center)
    }

    /// The globe's width on screen.
    private var globeWidth: CGFloat {
        current.focus.width * geometry.scale
    }

    private func setGlobeLongitude(_ longitude: Double) {
        guard let geography = Geography.world,
              let index = stops.firstIndex(where: { $0.id == CountryCatalog.world.id }) else { return }
        let turned = remainder(longitude, 360)
        globeLongitude = turned
        stops[index].map = geography.turningMap(worldProjection, centerLongitude: turned)
    }

    // MARK: Projections

    /// Reshapes the Countries map into another projection, pulling back to the whole world as it does.
    func reproject(from old: MapProjection, to new: MapProjection, reduceMotion: Bool) {
        guard let geography = Geography.world,
              let index = stops.firstIndex(where: { $0.id == CountryCatalog.world.id }) else { return }
        let collection = stops[index].collection
        spin?.cancel()
        isSpinning = false
        globeLongitude = nil
        worldProjection = new
        selection = nil
        returnCameras[collection.id] = nil
        stops[index] = MapStop(collection: collection, map: geography.map(new, center: center))
        guard index == stops.count - 1, !reduceMotion else {
            cameras[collection.id] = nil
            return
        }
        withAnimation(.smooth(duration: 0.6)) { cameras[collection.id] = nil }
        let change = Reprojection(from: old, to: new, start: .now)
        reprojection = change
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Reprojection.duration))
            if self.reprojection == change { self.reprojection = nil }
        }
    }

    /// Back to the first map, seen whole, as the map closes.
    func returnToStart() {
        selection = nil
        pullOffset = .zero
        detailProgress = 0
        morphProgress = 0
        isDrainingSubdivisions = false
        settledFrom = [:]
        if stops.count > 1 {
            direction = .outward
            stops = [stops[0]]
        }
        cameras = [:]
        returnCameras = [:]
    }
}

/// One map in the stack of maps flown into, such as Countries and then Japan.
struct MapStop: Identifiable {
    var collection: Country
    var map: TravelMap
    /// The area of the map its places cover, fitted to the screen before zooming.
    var focus: CGRect
    /// A country's subdivisions drawn over the World map, when the camera flew into the country
    /// from the World rather than crossing to a map of its own.
    var detail: TravelMap?
    /// The country's own map, which the subdivisions settle into once they've arrived.
    var local: TravelMap?
    /// The World, coloured underneath a country's subdivisions.
    var base: Country?
    /// The layer a stop takes over, as a country's map does once its subdivisions settle into it.
    var layer: String?
    var id: String { collection.id }
    /// Stops drawn on the same map share a layer, so flying between them never swaps maps.
    var layerID: String { layer ?? base?.id ?? collection.id }

    init(collection: Country, map: TravelMap, layer: String? = nil) {
        self.collection = collection
        self.map = map
        self.layer = layer
        focus = map.focusRect(including: collection.divisions.map(\.id))
    }

    /// A country's subdivisions over the map of the stop it was flown into from.
    init(collection: Country, subdivisions: TravelMap, local: TravelMap?, over base: MapStop) {
        self.collection = collection
        map = base.map
        focus = base.focus
        detail = subdivisions
        self.local = local
        self.base = base.collection
    }
}

/// The place whose callout is open, and the region that was tapped for it. A region can stand for
/// another place, such as Taiwan drawn as part of China when it doesn't count as a country.
struct MapSelection: Equatable {
    var place: AdministrativeDivision
    var regionID: String?
}

struct MapLayout: Equatable {
    var size: CGSize = .zero
    var insets = EdgeInsets()
}

enum FlightDirection {
    case inward, outward
}

/// The Countries map gliding from one projection into another, every point moving at once.
struct Reprojection: Equatable {
    static let duration = 1.1

    var from: MapProjection
    var to: MapProjection
    var start: Date

    /// How far along the change is, easing in and out.
    func progress(at date: Date) -> Double {
        let linear = min(max(date.timeIntervalSince(start) / Self.duration, 0), 1)
        return linear * linear * (3 - 2 * linear)
    }
}
