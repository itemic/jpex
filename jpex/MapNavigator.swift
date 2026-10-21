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
    /// Counts the camera's glides, so a glide waiting a frame for a lap shift, or between the two
    /// legs of a pan-over, knows when something newer has taken the camera and stands down.
    @ObservationIgnored private var glideGeneration = 0
    /// The place picked as the newest glide set off, or as it last opened a place itself. Picked
    /// anew some other way on the way, as an Atlas card swiped to a place already in view or a
    /// place tapped over the overview, the glide stands down rather than land and take it back.
    /// A pick made in the same turn as the glide was asked for, as a place framed whole and then
    /// called out, belongs with it, so the place is noted again a turn later.
    @ObservationIgnored private var glideSelection: MapSelection?

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

    /// Whether a World that runs on round fills the clear area from top to foot when seen whole,
    /// its copies carrying on either side, rather than fitting whole inside it with sea above and
    /// below, as on the full map, which sets it. The quiz's board keeps every map whole.
    @ObservationIgnored var fillsWithCopies = false

    /// The part of the current map fitted into the clear area when it's seen whole: all of it, or
    /// with `fillsWithCopies`, for a World that runs on round in a clear area taller for its width
    /// than the World, as much of the World's width about its middle as fills that area from top to
    /// foot, the rest of it carrying on round either side.
    var fittedFocus: CGRect {
        fitted(current.focus, size: layout.size, insets: layout.insets)
    }

    /// `fittedFocus` for a map's focus in a view of `size`, with `insets` kept clear.
    func fitted(_ focus: CGRect, size: CGSize, insets: EdgeInsets) -> CGRect {
        // The World keeps its fit while a country's subdivisions are drawn over it, so flying in
        // doesn't jolt the camera: the stop flown into shares the World's map, and its camera
        // carries on from the World's just as it was.
        let isWorld = (current.base?.id ?? current.id) == CountryCatalog.world.id
        return fitted(focus, size: size, insets: insets, runsOnRound: isWorld && current.map.tileWidth != nil)
    }

    /// `fitted(_:size:insets:)` for a World map drawn in any projection, such as one the World is
    /// reshaping from or into: `runsOnRound` says whether that projection's World runs on round,
    /// as a rectangular one does, and so fills the clear area from top to foot.
    func fitted(_ focus: CGRect, size: CGSize, insets: EdgeInsets, runsOnRound: Bool) -> CGRect {
        guard fillsWithCopies, runsOnRound, focus.width > 0, focus.height > 0 else { return focus }
        let area = MapGeometry(focus: focus, size: size, zoom: 1, pan: .zero, insets: insets).fitArea
        let width = focus.height * area.width / max(area.height, 1)
        guard width < focus.width else { return focus }
        return CGRect(x: focus.midX - width / 2, y: focus.minY, width: width, height: focus.height)
    }

    /// How much of a World map's width shows when it's seen whole in a view of `size`: all of it,
    /// or for a World that runs on round, the share about its middle that fills the clear area
    /// from top to foot. While the World reshapes from one projection into another, the share
    /// shown glides from the one's to the other's (see `Reprojection`), so a rectangular World
    /// neither loses its fill as it starts nor jumps to it as it lands.
    func fittedShare(of map: TravelMap, size: CGSize, insets: EdgeInsets) -> CGFloat {
        let focus = map.focusRect(including: [])
        guard focus.width > 0 else { return 1 }
        return fitted(focus, size: size, insets: insets, runsOnRound: map.tileWidth != nil).width / focus.width
    }

    /// The current map's layout on screen with its camera.
    var geometry: MapGeometry {
        geometry(for: camera)
    }

    /// The current map's layout on screen seen through any camera.
    func geometry(for camera: MapCamera) -> MapGeometry {
        MapGeometry(
            focus: fittedFocus, size: layout.size, zoom: camera.zoom, pan: camera.pan, insets: layout.insets,
            rotation: camera.rotation)
    }

    /// Takes the map's new size, such as after rotating or unfolding the device, or the room kept
    /// clear around it, such as a panel rising, and keeps the same place in view. A map zoomed in
    /// keeps the place that was in the middle of the clear area in the middle of the new one, then
    /// stays in bounds; a map seen whole is fitted whole again when its size changes.
    /// A new size lands at once, as the device turns or folds; new room glides in step with the
    /// map's own glide into it.
    func updateLayout(_ newLayout: MapLayout) {
        let oldLayout = layout
        layout = newLayout
        guard oldLayout.size != .zero, oldLayout != newLayout, gestureStart == nil, !isFlying,
              let old = cameras[current.id]
        else { return }
        let rotation = old.rotation
        guard old.zoom > 1.01 else {
            if oldLayout.size != newLayout.size { camera = MapCamera(rotation: rotation) }
            return
        }
        // Only the full map, which sets `fillsWithCopies`, keeps its place as panels come and go;
        // the quiz's board, which times its questions to its own glides and lets its map be
        // dragged loosely past its edges, is left where it is.
        if oldLayout.size == newLayout.size, !fillsWithCopies { return }
        // The place in the middle, found with the old layout and put in the middle of the new.
        let before = MapGeometry(
            focus: fitted(current.focus, size: oldLayout.size, insets: oldLayout.insets), size: oldLayout.size,
            zoom: old.zoom, pan: old.pan, insets: oldLayout.insets, rotation: rotation)
        let oldArea = before.fitArea
        let held = before.toMap(CGPoint(x: oldArea.midX, y: oldArea.midY))
        let area = geometry.fitArea
        var kept = geometry.camera(placing: held, at: CGPoint(x: area.midX, y: area.midY), zoom: old.zoom, rotation: rotation)
        kept.pan = clampedPan(kept.pan, zoom: kept.zoom, rotation: rotation)
        guard oldLayout.size == newLayout.size else {
            camera = kept
            return
        }
        // Only the room around the map changed, which the map glides into as a panel comes and
        // goes. The camera glides with it in step, so the place in the middle rides along with the
        // middle of the clear area rather than jumping. That's less motion, not more, so it holds
        // with Reduce Motion as the room's own glide does.
        withAnimation(Self.roomChange) { camera = kept }
    }

    /// How the map glides into the room left around it as a panel comes or goes, matching the full
    /// map's own glide of that room (see `MapMotion.room`).
    static let roomChange = MapMotion.room

    // MARK: Gestures

    /// Pinch and turn around the gesture's starting point while dragging: the point of the map that
    /// was under the fingers stays under them. With `resists`, the map gives less and less the
    /// further it's pulled past its edges or its zoom limits, like a rubber band, and springs back
    /// when let go; without it, there's a little give past the limits. `rotation` is how far the
    /// fingers have turned since the gesture began; maps that never turn leave it out.
    func moveCamera(
        magnification: CGFloat, rotation: Angle = .zero, anchor: CGPoint, translation: CGSize, resists: Bool = false
    ) {
        if gestureStart == nil {
            // A finger on the map takes it from any glide still on its way.
            cancelGlide()
            // Brought within half a turn of north first, which looks just the same, so letting go
            // never sends the map the long way round.
            normaliseRotation()
            gestureStart = camera
            touch()
        }
        let start = gestureStart ?? camera
        let proposed = start.zoom * magnification
        let zoom = resists ? Self.resisted(zoom: proposed, within: 1...maximumZoom) : min(max(proposed, 0.6), maximumZoom * 1.2)
        let held = geometry(for: start).toMap(anchor)
        // The turn is kept within half a turn of north as it goes, which on screen is the same, so
        // an animation from where it's let go, to north or into the card, never takes the long way
        // round; normalising only as it settles would land in the same update as the animation.
        var moved = geometry.camera(
            placing: held, at: CGPoint(x: anchor.x + translation.width, y: anchor.y + translation.height),
            zoom: zoom, rotation: MapCamera.normalised(start.rotation + rotation))
        if resists { moved.pan = resistedPan(moved.pan, zoom: zoom, rotation: moved.rotation) }
        camera = moved
    }

    /// Turned this close to north, a map let go settles facing it.
    static let northSnap = Angle.degrees(4)

    /// Brings the camera's turn within half a turn of north without moving anything on screen.
    func normaliseRotation() {
        let rotation = MapCamera.normalised(camera.rotation)
        guard rotation != camera.rotation else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { camera.rotation = rotation }
    }

    /// Turns the map back to face north about the middle of the view, keeping the place there in the
    /// middle, as the compass does when tapped. `completion` runs once the map faces north: as the
    /// animation ends, straight away without one, or at once when it already does, so the compass
    /// can stay up until the map arrives and click as it does.
    func faceNorth(animation: Animation?, completion: (@MainActor () -> Void)? = nil) {
        normaliseRotation()
        guard camera.rotation != .zero else {
            completion?()
            return
        }
        cancelGlide()
        touch()
        let area = geometry.fitArea
        let middle = CGPoint(x: area.midX, y: area.midY)
        var target = MapCamera()
        if camera.zoom > 1.01 {
            target = geometry.camera(placing: geometry.toMap(middle), at: middle, zoom: camera.zoom, rotation: .zero)
            target.pan = clampedPan(target.pan, zoom: target.zoom, rotation: .zero)
        }
        guard let animation else {
            withAnimation(nil) { camera = target }
            completion?()
            return
        }
        withAnimation(animation) { camera = target } completion: { completion?() }
    }

    /// Pinched out this far, the map lets go: back out to the map it was flown into from, or closed.
    static let letGoZoom: CGFloat = 0.86

    /// Whether the camera has been pulled past its zoom limits or its edges, so it springs back.
    var isPastLimits: Bool {
        let zoom = camera.zoom
        guard zoom >= 0.999, zoom <= maximumZoom + 0.001 else { return true }
        let settled = zoom > 1.01 ? clampedPan(camera.pan, zoom: zoom, rotation: camera.rotation) : .zero
        return abs(settled.width - camera.pan.width) > 0.5 || abs(settled.height - camera.pan.height) > 0.5
    }

    /// A zoom past its limits, held back like a rubber band: never more than 40% closer than the
    /// closest view, or much past halfway below the whole map.
    /// World Time's flat map holds its pinch back the same way.
    static func resisted(zoom: CGFloat, within limits: ClosedRange<CGFloat>) -> CGFloat {
        let value = log(max(zoom, 0.0001))
        let low = log(limits.lowerBound)
        let high = log(limits.upperBound)
        if value > high { return exp(high + rubberBand(value - high, limit: log(1.4))) }
        if value < low { return exp(low - rubberBand(low - value, limit: log(1 / 0.55))) }
        return zoom
    }

    /// A pan past the map's edges, held back the same way, never more than a third of the view. A
    /// World that runs on round has no edges east or west, so only its top and foot hold back.
    private func resistedPan(_ proposed: CGSize, zoom: CGFloat, rotation: Angle) -> CGSize {
        let allowed = clampedPan(proposed, zoom: zoom, rotation: rotation)
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

    /// Brings zoom back within its limits and keeps the map in view, carrying any fling. A map
    /// turned only a little from north settles facing it.
    /// A World that runs on round comes back within a lap of its middle copy first, which looks
    /// just the same, so it never wanders off for good.
    func settleCamera(fling: CGSize, animation: Animation?) {
        gestureStart = nil
        normaliseRotation()
        bringBackRound()
        let rotation = abs(camera.rotation.degrees) <= Self.northSnap.degrees ? .zero : camera.rotation
        withAnimation(animation) {
            let zoom = min(max(camera.zoom, 1), maximumZoom)
            guard zoom > 1.01 else {
                camera = MapCamera(rotation: rotation)
                return
            }
            let area = geometry.fitArea
            let middle = CGPoint(x: area.midX, y: area.midY)
            var target = geometry.camera(
                placing: geometry.toMap(middle), at: CGPoint(x: middle.x + fling.width, y: middle.y + fling.height),
                zoom: zoom, rotation: rotation)
            target.pan = clampedPan(target.pan, zoom: zoom, rotation: rotation)
            camera = target
        }
    }

    func cancelGesture() {
        gestureStart = nil
    }

    /// Comes three times closer, bringing the place tapped to the middle, or pulls back to the whole
    /// map. Either way a turned map stays turned.
    func toggleZoom(at location: CGPoint, animation: Animation?) {
        cancelGlide()
        withAnimation(animation) {
            let rotation = camera.rotation
            if camera.zoom > 1.5 {
                camera = MapCamera(rotation: rotation)
            } else {
                let zoom = min(camera.zoom * 3, maximumZoom)
                let area = geometry.fitArea
                var target = geometry.camera(
                    placing: geometry.toMap(location), at: CGPoint(x: area.midX, y: area.midY), zoom: zoom, rotation: rotation)
                target.pan = clampedPan(target.pan, zoom: zoom, rotation: rotation)
                camera = target
            }
        }
    }

    /// Comes closer or pulls back by `factor` about the middle of the view, as the keyboard's
    /// zoom in and zoom out do: the place in the middle stays there, and a turned map stays turned.
    /// Pulled back to the whole map, it's fitted whole again. The quiz's board has its own
    /// north-facing `zoom(by:animation:)`.
    func zoomStep(by factor: CGFloat, animation: Animation?) {
        guard factor > 0 else { return }
        cancelGlide()
        touch()
        let zoom = min(max(camera.zoom * factor, 1), maximumZoom)
        let rotation = camera.rotation
        var target = MapCamera(rotation: rotation)
        if zoom > 1.01 {
            let area = geometry.fitArea
            let middle = CGPoint(x: area.midX, y: area.midY)
            target = geometry.camera(placing: geometry.toMap(middle), at: middle, zoom: zoom, rotation: rotation)
            target.pan = clampedPan(target.pan, zoom: zoom, rotation: rotation)
        }
        guard target != camera else { return }
        withAnimation(animation) { camera = target }
    }

    /// Back to the whole map, facing north. `completion` runs once it's there: as the animation
    /// ends, or straight away without one.
    func showAll(animation: Animation?, completion: (@MainActor () -> Void)? = nil) {
        cancelGlide()
        normaliseRotation()
        guard let animation else {
            withAnimation(nil) { camera = MapCamera() }
            completion?()
            return
        }
        withAnimation(animation) { camera = MapCamera() } completion: { completion?() }
    }

    /// The camera a glide to `target` comes to rest at: within the zoom limits about the middle of
    /// the view, kept in bounds, and facing north when it's turned only a little from it, as a map
    /// let go settles.
    func settled(_ target: MapCamera) -> MapCamera {
        let rotation = abs(MapCamera.normalised(target.rotation).degrees) <= Self.northSnap.degrees
            ? .zero : MapCamera.normalised(target.rotation)
        let zoom = min(max(target.zoom, 1), maximumZoom)
        guard zoom > 1.01 else { return MapCamera(rotation: rotation) }
        let seen = geometry(for: target)
        let area = seen.fitArea
        let middle = CGPoint(x: area.midX, y: area.midY)
        var settled = seen.camera(placing: seen.toMap(middle), at: middle, zoom: zoom, rotation: rotation)
        settled.pan = clampedPan(settled.pan, zoom: zoom, rotation: rotation)
        return settled
    }

    // MARK: Gliding

    /// How far away, in widths of the clear area at today's zoom, a place has to be before the
    /// camera pans over to it rather than sliding straight across.
    static let panOverDistance: CGFloat = 1.2

    /// How much further out than both ends of a pan-over its overview has to be for the camera to
    /// rise to it, rather than glide straight across.
    static let panOverPullOut: CGFloat = 1.25

    /// Glides the camera to `target`. Close by, it simply slides there with `animation`. Further
    /// off than `panOverDistance` with `panOver`, it pans over like a flight: up and out until both
    /// where it is and where it's going are in view, then down into the place, so the way between
    /// is seen rather than whisked past. The way down sets off while the camera is still rising,
    /// carrying its speed on, so the flight is one arc rather than up, a pause and down. A newer
    /// glide, a flight or a finger on the map takes over from one still on its way, and the second
    /// leg of a pan-over then never sets off. With no animation, as with Reduce Motion, the camera
    /// is simply there.
    ///
    /// `completion` runs once the camera has arrived, and not at all when something newer took
    /// over on the way.
    func glide(
        to target: MapCamera, animation: Animation?, panOver: Bool = true, completion: (@MainActor () -> Void)? = nil
    ) {
        performGlide(to: target, animation: animation, panOver: panOver, generation: beginGlide(), completion: completion)
    }

    /// Starts a new glide, superseding any still on its way, and returns its number.
    func beginGlide() -> Int {
        glideGeneration &+= 1
        let generation = glideGeneration
        glideSelection = selection
        Task { @MainActor in
            if self.glideGeneration == generation { self.glideSelection = self.selection }
        }
        return generation
    }

    /// Stops any glide still on its way from setting off again, such as the second leg of a
    /// pan-over, as a finger takes the map or the camera is sent somewhere else.
    func cancelGlide() {
        glideGeneration &+= 1
    }

    /// Whether glide `generation` is still the newest, so it may carry on.
    func isCurrentGlide(_ generation: Int) -> Bool {
        generation == glideGeneration && selection == glideSelection
    }

    /// The glide behind `glide(to:…)`, numbered already so a caller that waits a frame first can
    /// claim its turn before waiting. `alongside` changes what belongs with the arrival, such as
    /// the callout opening, in the same animation as the camera's last leg, so it opens where the
    /// camera lands rather than over the overview on the way.
    func performGlide(
        to target: MapCamera, animation: Animation?, panOver: Bool, generation: Int,
        alongside: (@MainActor () -> Void)? = nil, completion: (@MainActor () -> Void)? = nil
    ) {
        guard isCurrentGlide(generation) else { return }
        guard let animation else {
            withAnimation(nil) {
                camera = target
                alongside?()
                glideSelection = selection
            }
            completion?()
            return
        }
        guard panOver, let overview = overview(toward: target) else {
            withAnimation(animation) {
                camera = target
                alongside?()
                glideSelection = selection
            } completion: {
                if self.isCurrentGlide(generation) { completion?() }
            }
            return
        }
        withAnimation(.smooth(duration: 0.45)) { camera = overview }
        // The way down takes over a little over halfway up, the springs carrying the camera's
        // speed from one leg into the next, so it comes down in one arc of about a second.
        Task { @MainActor in
            try? await Task.sleep(for: Self.panOverHandover)
            guard self.isCurrentGlide(generation) else { return }
            withAnimation(.smooth(duration: 0.6)) {
                self.camera = target
                alongside?()
                self.glideSelection = self.selection
            } completion: {
                if self.isCurrentGlide(generation) { completion?() }
            }
        }
    }

    /// How far into a pan-over's rise its way down takes over.
    static let panOverHandover = Duration.milliseconds(260)

    /// The part of the map seen in the clear area through a camera.
    private func seenRect(through camera: MapCamera) -> CGRect {
        let seen = geometry(for: camera)
        let area = seen.fitArea
        let corners = [
            CGPoint(x: area.minX, y: area.minY), CGPoint(x: area.maxX, y: area.minY),
            CGPoint(x: area.minX, y: area.maxY), CGPoint(x: area.maxX, y: area.maxY),
        ].map(seen.toMap)
        let xs = corners.map(\.x)
        let ys = corners.map(\.y)
        return CGRect(x: xs.min() ?? 0, y: ys.min() ?? 0, width: (xs.max() ?? 0) - (xs.min() ?? 0), height: (ys.max() ?? 0) - (ys.min() ?? 0))
    }

    /// The camera halfway through a pan-over to `target`, pulled out to show both what's in view
    /// now and what will be, never further out than the whole map: nil when the target is close
    /// enough to slide to directly.
    private func overview(toward target: MapCamera) -> MapCamera? {
        let here = geometry
        let area = here.fitArea
        let middle = CGPoint(x: area.midX, y: area.midY)
        let from = here.toMap(middle)
        let to = geometry(for: target).toMap(CGPoint(x: area.midX, y: area.midY))
        let distance = hypot(to.x - from.x, to.y - from.y) * here.scale
        guard distance > area.width * Self.panOverDistance else { return nil }
        let both = seenRect(through: camera).union(seenRect(through: target))
        var overview = here.camera(fitting: both)
        if overview.zoom < 1 {
            overview = here.camera(centering: CGPoint(x: both.midX, y: both.midY), zoom: 1)
        }
        // An overview that hardly pulls out past one end or the other, as when the view is already
        // wide or the place is shown wide, would only stall halfway; one straight glide, zooming
        // evenly, shows the way between just as well.
        guard overview.zoom < min(camera.zoom, target.zoom) / Self.panOverPullOut else { return nil }
        overview.pan = clampedPan(overview.pan, zoom: overview.zoom, rotation: overview.rotation)
        return overview
    }

    /// Runs `move` once a silent lap shift has reached the screen: a frame later when there was
    /// one, so the shift and the glide that follows aren't folded into one change that sweeps
    /// nearly a lap the wrong way, or at once when there wasn't. A move that doesn't animate, as
    /// with Reduce Motion, has nothing to sweep, so it's made at once too, and a caller reading the
    /// camera straight afterwards, as the quiz does to land a place's outline, finds it already there.
    func afterLapShift(_ shifted: Bool, animated: Bool = true, _ move: @escaping @MainActor () -> Void) {
        guard shifted, animated else {
            move()
            return
        }
        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(16))
            move()
        }
    }

    /// Keeps a zoomed map covering the clear area, or centred in it where it is smaller. A turned
    /// map is kept by the box around it as it lies aslant. A World that runs on round is free to
    /// slide along its own east–west line without end, and is kept only from north to south.
    private func clampedPan(_ proposed: CGSize, zoom: CGFloat, rotation: Angle) -> CGSize {
        let unpanned = MapGeometry(
            focus: fittedFocus, size: layout.size, zoom: zoom, pan: .zero, insets: layout.insets, rotation: rotation)
        if wrapWidth != nil {
            return wrappingClampedPan(proposed, unpanned: unpanned)
        }
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

    // MARK: Running round

    /// How wide one lap of the World is, in map units, while the full map runs on round sideways
    /// the way the Earth does: on the World itself, with no country's subdivisions over it, in a
    /// rectangular projection, whose copies sit edge to edge either side. Nil for a globe or any
    /// other map, which keep their edges.
    var wrapWidth: CGFloat? {
        guard current.id == CountryCatalog.world.id, current.detail == nil,
              let width = current.map.tileWidth, width > 0 else { return nil }
        return width
    }

    /// The map's own east–west line on screen, aslant while it's turned: copies of a World that
    /// runs on round lie a lap apart along it.
    private static func eastward(_ rotation: Angle) -> CGVector {
        CGVector(dx: cos(rotation.radians), dy: sin(rotation.radians))
    }

    /// Keeps a World that runs on round from leaving the clear area to the north or south, measured
    /// across its own east–west line, and leaves it free along it. Facing north, that is simply the
    /// usual keeping from top to foot, with nothing to stop it sideways.
    private func wrappingClampedPan(_ proposed: CGSize, unpanned: MapGeometry) -> CGSize {
        let east = Self.eastward(unpanned.rotation)
        let south = CGVector(dx: -east.dy, dy: east.dx)
        func along(_ point: CGPoint, _ axis: CGVector) -> CGFloat { point.x * axis.dx + point.y * axis.dy }
        func span(of rect: CGRect, transform: CGAffineTransform = .identity) -> (start: CGFloat, length: CGFloat) {
            let values = [
                CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY),
            ].map { along($0.applying(transform), south) }
            let low = values.min() ?? 0
            return (low, (values.max() ?? 0) - low)
        }
        let content = span(of: current.focus, transform: unpanned.transform)
        let area = span(of: unpanned.fitArea)
        let pan = CGPoint(x: proposed.width, y: proposed.height)
        let eastward = along(pan, east)
        var southward = along(pan, south)
        if content.length > area.length {
            southward = min(max(southward, area.start + area.length - (content.start + content.length)), area.start - content.start)
        } else {
            southward = area.start + (area.length - content.length) / 2 - content.start
        }
        return CGSize(
            width: eastward * east.dx + southward * south.dx,
            height: eastward * east.dy + southward * south.dy)
    }

    /// Brings a World that has run round more than half a lap back to its middle copy, the one
    /// whose places are picked, called out and flown into, by whole laps along its east–west line,
    /// without animating: the copies are all alike, so nothing on screen moves.
    func bringBackRound() {
        guard let width = wrapWidth else { return }
        let lap = width * geometry.fitScale * camera.zoom
        guard lap > 1 else { return }
        let east = Self.eastward(camera.rotation)
        let area = geometry.fitArea
        let middle = geometry.toScreen(CGPoint(x: current.focus.midX, y: current.focus.midY))
        let offset = (middle.x - area.midX) * east.dx + (middle.y - area.midY) * east.dy
        let laps = (offset / lap).rounded()
        guard laps != 0 else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            camera.pan.width -= laps * lap * east.dx
            camera.pan.height -= laps * lap * east.dy
        }
    }

    /// Brings a World that runs on round round by whole laps, without anything moving on screen, so
    /// that the middle copy of a part of the map is the one nearest the view. The camera then goes
    /// the short way to it, and its callout and subdivisions, which belong to the middle copy, land
    /// where the camera does.
    /// Returns whether it moved, so the glide that follows can wait a frame for the shift to
    /// reach the screen (see `afterLapShift`).
    @discardableResult
    func bringRound(toward rect: CGRect) -> Bool {
        guard let width = wrapWidth, !rect.isNull else { return false }
        let area = geometry.fitArea
        let seen = geometry.toMap(CGPoint(x: area.midX, y: area.midY))
        let laps = ((seen.x - rect.midX) / width).rounded()
        let lap = width * geometry.scale
        guard laps != 0, lap > 1 else { return false }
        let east = Self.eastward(camera.rotation)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            camera.pan.width += laps * lap * east.dx
            camera.pan.height += laps * lap * east.dy
        }
        return true
    }

    /// The copy of a part of the map nearest the middle of the view, for a World that runs on
    /// round: the camera goes to the place beside it rather than all the way back round to the
    /// middle copy. Any other map has only the one.
    func nearestCopy(of rect: CGRect) -> CGRect {
        guard let width = wrapWidth, !rect.isNull else { return rect }
        let area = geometry.fitArea
        let seen = geometry.toMap(CGPoint(x: area.midX, y: area.midY))
        let laps = ((seen.x - rect.midX) / width).rounded()
        return laps == 0 ? rect : rect.offsetBy(dx: laps * width, dy: 0)
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

    /// Glides the camera to a place and opens its callout, coming no closer than `closest`, where
    /// it's given, so a tiny island keeps the sea and the lands around it in view. With `panOver`,
    /// a place far off is flown to by way of an overview (see `glide(to:…)`), and the callout
    /// opens on the last leg. It animates by itself with `animation`, so callers needn't wrap it.
    func focus(
        on place: AdministrativeDivision, closest: CGFloat? = nil, animation: Animation?, panOver: Bool = false
    ) {
        guard let region = (current.detail ?? current.map).region(id: place.id) else {
            // Nothing to fly to, but a pan-over still on its way mustn't land and open the place
            // before this one.
            cancelGlide()
            withAnimation(animation) { selection = MapSelection(place: place, regionID: nil) }
            return
        }
        let generation = beginGlide()
        let core = region.coreBounds
        let shifted = bringRound(toward: core)
        // Frame the place with plenty of map around it, never pulling back past the whole map.
        var target = geometry.camera(fitting: core.insetBy(dx: -core.width * 1.4, dy: -core.height * 1.4))
        let deepest = min(closest ?? maximumZoom, maximumZoom)
        if target.zoom < 1 || target.zoom > deepest {
            target = geometry.camera(centering: CGPoint(x: core.midX, y: core.midY), zoom: min(max(target.zoom, 1), deepest))
        }
        target.pan = clampedPan(target.pan, zoom: target.zoom, rotation: target.rotation)
        let chosen = MapSelection(place: place, regionID: region.id)
        afterLapShift(shifted, animated: animation != nil) {
            self.performGlide(
                to: target, animation: animation, panOver: panOver, generation: generation,
                alongside: { self.selection = chosen })
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
        cancelGlide()
        normaliseRotation()
        let base = current
        let region = regionID.flatMap { base.map.region(id: $0) }
        // The subdivisions arrive over the middle copy of a World that runs on round, shifted
        // there a frame before the flight sets off so it goes the short way.
        let shifted = region.map { bringRound(toward: $0.coreBounds) } ?? false
        returnCameras[current.id] = camera
        // Subdivisions that settle into the country's own map come round to face north on the way
        // in, as that map does; ones that stay over the World keep its turn.
        let framing = local == nil ? geometry : geometry.facingNorth
        var target = region.map { framing.camera(fitting: $0.coreBounds) } ?? camera
        if local != nil { target.rotation = .zero }
        afterLapShift(shifted, animated: !reduceMotion) {
            self.flyIn(to: target, collection: collection, subdivisions: subdivisions, local: local, base: base, reduceMotion: reduceMotion)
        }
    }

    /// The flight into a country's subdivisions once any lap shift has reached the screen.
    private func flyIn(
        to target: MapCamera, collection: Country, subdivisions: TravelMap, local: TravelMap?, base: MapStop,
        reduceMotion: Bool
    ) {
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
        cancelGlide()
        normaliseRotation()
        let region = regionID.flatMap { current.map.region(id: $0) }
        let shifted = region.map { bringRound(toward: $0.coreBounds) } ?? false
        returnCameras[current.id] = camera
        // The place's own map opens facing north, so the camera comes round to north on the way in.
        var target = region.map { geometry.facingNorth.camera(fitting: $0.coreBounds) } ?? camera
        target.rotation = .zero
        afterLapShift(shifted, animated: !reduceMotion) {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.75)) {
                self.selection = nil
                self.camera = target
            } completion: {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: 0.6)) {
                    self.stops.append(MapStop(collection: collection, map: map))
                } completion: {
                    self.isFlying = false
                }
            }
        }
    }

    /// Crosses back to the map before, still close in on the place, then pulls out to where it was.
    func flyBack(reduceMotion: Bool) {
        guard stops.count > 1, !isFlying else { return }
        isFlying = true
        cancelGlide()
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

    /// Whether a sideways drag turns the World: the World map in any projection, seen whole and
    /// facing north, so the drag runs along its lines of latitude.
    var canTurnGlobe: Bool {
        current.id == CountryCatalog.world.id && current.detail == nil
            && camera.zoom <= 1.01 && camera.facesNorth && reprojection == nil && !isFlying
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

    /// Whether the World is drawn on a globe whose far side is hidden, so a place round the back has
    /// to be turned to before it can be seen.
    var showsGlobe: Bool {
        worldProjection == .globe && current.id == CountryCatalog.world.id && current.detail == nil
    }

    /// How far round the globe a longitude is from the middle of its face, in degrees, east
    /// positive; nil on any map but the globe.
    func turn(toFace longitude: Double) -> Double? {
        guard showsGlobe else { return nil }
        return WorldSpinner.offset(from: centerLongitude, to: longitude)
    }

    /// Turns the globe the short way round until a longitude faces the viewer, as Learn going from
    /// one country to another round the back, then rests it there, its coastlines back in full
    /// detail, and does what follows. A longer way round turns a little longer, never more than
    /// about a second; with Reduce Motion it's simply there.
    func turnGlobe(toFace longitude: Double, reduceMotion: Bool, then finish: @escaping @MainActor () -> Void) {
        guard let offset = turn(toFace: longitude), abs(offset) > 0.5, turnStart == nil else {
            finish()
            return
        }
        driftSpeed = 0
        touch()
        let from = centerLongitude
        let turn = WorldTurn(from: from, to: from + offset, start: .now, length: min(1.1, 0.45 + abs(offset) / 300))
        spin(through: turn, reduceMotion: reduceMotion) {
            self.setGlobeLongitude(from + offset)
            self.rest()
            finish()
        }
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
    /// Reduce Motion or in Low Power Mode. Only a moving globe is looked at every frame; at rest, or
    /// on a map that can't drift, such as a country's, it's looked at a few times a second.
    /// Called off, as when ambient motion stops while the app isn't in front, a globe that was
    /// drifting rests where it is, its coastlines back in full detail.
    func driftWhileIdle(reduceMotion: Bool) async {
        guard !reduceMotion else { return }
        var last = Date.now
        var drifted = 0.0
        var hasMoved = false
        var pause = Duration.milliseconds(33)
        while !Task.isCancelled {
            try? await Task.sleep(for: pause)
            let now = Date.now
            let step = min(now.timeIntervalSince(last), 0.1)
            last = now
            guard isStill else {
                // Something else has the globe, or there's no globe to turn; let it go at once.
                driftSpeed = 0
                hasMoved = false
                pause = .milliseconds(500)
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
                pause = .milliseconds(250)
                continue
            }
            pause = .milliseconds(33)
            if wants { drifted += step }
            hasMoved = true
            // The Earth turns east, so the middle of the map moves on to the west.
            setGlobeLongitude(centerLongitude - driftSpeed * step)
        }
        if hasMoved {
            driftSpeed = 0
            rest()
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
        let oldMap = stops[index].map
        cancelGlide()
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
        let change = Reprojection(
            from: old, to: new, start: .now,
            fromShare: fittedShare(of: oldMap, size: layout.size, insets: layout.insets),
            toShare: fittedShare(of: stops[index].map, size: layout.size, insets: layout.insets))
        reprojection = change
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Reprojection.duration))
            if self.reprojection == change { self.reprojection = nil }
        }
    }

    /// Back to the first map, seen whole, as the map closes.
    func returnToStart() {
        cancelGlide()
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
    /// How much of the World's width the full map showed seen whole in the old projection, and
    /// will in the new one (see `MapNavigator.fittedShare(of:size:insets:)`): less than all of it
    /// for a World that runs on round, which fills the screen from top to foot.
    var fromShare: CGFloat = 1
    var toShare: CGFloat = 1

    /// How far along the change is, easing in and out.
    func progress(at date: Date) -> Double {
        let linear = min(max(date.timeIntervalSince(start) / Self.duration, 0), 1)
        return linear * linear * (3 - 2 * linear)
    }

    /// The share of the World's width shown partway through, gliding from the old projection's
    /// to the new one's in step with the World's shape.
    func share(at date: Date) -> CGFloat {
        fromShare + (toShare - fromShare) * CGFloat(progress(at: date))
    }
}
