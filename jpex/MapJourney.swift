import SwiftUI

/// The list's map flying from one list to the next as one takes the other's place: out of the
/// country before, its subdivisions moving back onto the World and fading as the camera pulls out,
/// then into the next, the camera diving in, its subdivisions tracing themselves in over the World
/// and moving into the country's own map, just as the full-screen map flies in.
///
/// The journey centres the World where no country it visits is cut in two by the map's edge, such
/// as Russia or Fiji across the 180th meridian, turning the World there before diving in and back
/// to the person's own centre after pulling out.
struct MapJourney {
    /// The arrival the journey plays, which also marks when it began.
    var arrival: CollectionArrival
    var world: TravelMap
    var worldStatuses: [String: VisitLevel]
    /// The part of the World fitted to the view before any zooming, as on the World's own card.
    var worldFocus: CGRect
    /// The country flown out of, when the journey starts in one.
    var departure: Leg?
    /// The country flown into, when the journey ends in one.
    var destination: Leg?
    var projection: MapProjection
    /// The longitude at the middle of the World the person keeps, where a journey back to it ends.
    var restingLongitude: Double
    /// Where a journey from the World starts: its centre, or wherever its globe had drifted to.
    var startLongitude: Double
    /// The longitude at the middle of the World while the journey is in a country.
    var longitude: Double
    /// How long the World turns to `longitude` before diving into a country, and back after pulling out.
    var turnIn: TimeInterval = 0
    var turnOut: TimeInterval = 0
    /// Whether it dives into one of a country's places on the country's own map and back out, as from
    /// one of France's regions to its departments, the rest of the country staying in view.
    var isRegionDive = false
    /// How far the rest of the map washes out as the subdivisions arrive: most of the way over the
    /// World, a little on a country's own map, where the other regions stay in view.
    var detailWash = 0.6

    /// A country's part of the journey.
    struct Leg {
        /// The country's region on the World map.
        var regionID: String
        /// The main body of the country on the World map, which the camera dives in on.
        var core: CGRect
        /// The country's subdivisions in the World's projection, with their levels.
        var detail: MapDetail
        /// The country's own map, which the subdivisions settle into.
        var local: TravelMap
    }

    /// The map partway through: where the camera is, and how far the subdivisions have come.
    struct Frame {
        var camera: MapCamera
        var leg: Leg?
        var detailProgress: Double
        var morphProgress: Double
        var isLeaving: Bool
        /// The country being dived into, outlined until its subdivisions arrive.
        var selection: String?
        /// The longitude at the middle of the World while it turns, or nil once it's in place.
        var turningLongitude: Double?
    }

    static let departureDuration: TimeInterval = 1.35
    static let destinationDuration: TimeInterval = 2

    /// How long a dive into a region takes: in, the region's places tracing themselves in, a pause,
    /// then back out to the whole country.
    static let regionDiveDuration: TimeInterval = 2.3

    var duration: TimeInterval {
        if isRegionDive { return Self.regionDiveDuration }
        return turnIn + (departure == nil ? 0 : Self.departureDuration) + (destination == nil ? 0 : Self.destinationDuration)
            + turnOut
    }

    /// The journey an arrival makes, or nil when there's nowhere to fly: no list before, the same
    /// list, or a country without subdivisions to draw or out of sight, such as on the far side of the globe.
    @MainActor
    init?(
        arrival: CollectionArrival, collections: [Country], snapshot: TravelSnapshot,
        projection: MapProjection, center: MapCenter
    ) {
        // Between a country's list and its places' own lists, the journey stays on the country's map.
        if let journey = Self(withinCountry: arrival, collections: collections, snapshot: snapshot) {
            self = journey
            return
        }
        // From one of a country's regions to its places at another level, such as France's
        // departments, the journey stays on the country's map, and never flies out to the World.
        if arrival.fromPlaceID != nil {
            guard let journey = Self(regionDive: arrival, collections: collections, snapshot: snapshot) else { return nil }
            self = journey
            return
        }
        let worldID = CountryCatalog.world.id
        guard let fromID = arrival.fromID, fromID != arrival.toID,
              let world = collections.first(where: { $0.id == worldID }),
              let resting = TravelMap.named(worldID, projection: projection, center: center)
        else { return nil }
        // Centred where the countries on the way stay whole, at whichever of their levels.
        let regionIDs = [fromID, arrival.toID].filter { $0 != worldID }.compactMap { id in
            let code = collections.first { $0.id == id }?.countryListID ?? id
            return CountryCatalog.world.divisions.first { $0.abbreviation == code }?.id
        }
        let covered = regionIDs.reduce(into: Set<Int>()) { $0.formUnion(Self.coveredDegrees(of: $1)) }
        // Leaving the World, the flight sets off from wherever its globe had drifted to.
        let departing = fromID == worldID
            ? WorldSpinner.shown?.longitude(at: arrival.date) ?? center.longitude : center.longitude
        let longitude = Self.bestLongitude(covering: covered, from: departing, onGlobe: projection == .globe)
        let isTurned = Self.turn(from: center.longitude, to: longitude) != 0
        guard let map = isTurned ? Geography.world?.map(projection, centerLongitude: longitude) : resting else { return nil }
        func leg(_ id: String) -> Leg? {
            Self.leg(
                for: id, collections: collections, world: map, snapshot: snapshot, projection: projection, center: center,
                longitude: isTurned ? longitude : nil)
        }
        let departure = fromID == worldID ? nil : leg(fromID)
        let destination = arrival.toID == worldID ? nil : leg(arrival.toID)
        guard (fromID == worldID) == (departure == nil), (arrival.toID == worldID) == (destination == nil) else { return nil }
        self.arrival = arrival
        self.world = map
        worldStatuses = Dictionary(world.divisions.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first }
        // Fitted as the World at rest is, so the journey starts and lands exactly where it sits.
        worldFocus = resting.focusRect(including: worldStatuses.keys)
        self.departure = departure
        self.destination = destination
        self.projection = projection
        restingLongitude = center.longitude
        startLongitude = departing
        self.longitude = longitude
        turnIn = fromID == worldID ? Self.turnDuration(from: departing, to: longitude) : 0
        turnOut = arrival.toID == worldID ? Self.turnDuration(from: longitude, to: center.longitude) : 0
    }

    /// The journey from one of a country's regions to its places at another level, such as from
    /// Île-de-France among France's regions to the departments: on the country's own map, the camera
    /// dives into the region and its places trace themselves in over it, the other regions and the
    /// borders staying in view a little fainter, then pulls back out to the whole country, where the
    /// new list's map takes over. Nil unless both lists are levels of one country.
    @MainActor
    private init?(regionDive arrival: CollectionArrival, collections: [Country], snapshot: TravelSnapshot) {
        guard let fromID = arrival.fromID, let placeID = arrival.fromPlaceID,
              let from = collections.first(where: { $0.id == fromID }),
              let to = collections.first(where: { $0.id == arrival.toID }),
              from.countryListID == to.countryListID, from.parentPlace == nil, to.parentPlace == nil,
              let map = TravelMap.named(from.id), let local = TravelMap.named(to.id),
              let region = map.region(id: placeID)
        else { return nil }
        let core = region.coreBounds
        let places = to.divisions.filter { $0.parentID == placeID }
        guard core.width > 0, core.height > 0, !places.isEmpty else { return nil }
        // The region's places alone, drawn where they sit on the country's map: both levels share it.
        let ids = Set(places.map(\.id))
        var detailMap = local
        detailMap.regions = local.regions.filter { ids.contains($0.id) }
        detailMap.frames = []
        let statuses = Dictionary(places.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first }
        self.arrival = arrival
        world = map
        worldStatuses = Dictionary(from.divisions.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first }
        // Fitted as the country's map at rest is, so the journey starts and lands exactly where it sits.
        worldFocus = map.focusRect(including: worldStatuses.keys)
        departure = nil
        destination = Leg(
            regionID: placeID, core: core,
            detail: MapDetail(map: detailMap, statuses: statuses, ownerRegionIDs: [placeID]), local: local)
        projection = .current
        restingLongitude = 0
        startLongitude = 0
        longitude = 0
        isRegionDive = true
        detailWash = 0.25
    }

    /// A dive into a region `elapsed` seconds in: in on the region with a little of the country
    /// around it, its places tracing themselves in, a pause, then back out to the whole country.
    private func regionDiveFrame(_ dive: Leg, at elapsed: TimeInterval, size: CGSize, insets: EdgeInsets) -> Frame {
        let base = MapGeometry(focus: worldFocus, size: size, zoom: 1, pan: .zero, insets: insets)
        let close = base.camera(fitting: Self.diveArea(around: dive.core, within: worldFocus))
        let camera = elapsed < 1.4
            ? Self.glide(from: MapCamera(), to: close, around: dive.core.center, progress: Self.smoother(elapsed / 0.85), base: base)
            : Self.glide(
                from: close, to: MapCamera(), around: dive.core.center, progress: Self.smoother((elapsed - 1.4) / 0.85),
                base: base)
        return Frame(
            camera: camera, leg: dive, detailProgress: Self.smooth((elapsed - 0.35) / 0.8), morphProgress: 0,
            isLeaving: false, selection: elapsed < 0.6 ? dive.regionID : nil)
    }

    /// The area to dive in on for a region: the region with room around it for its neighbours, and
    /// never less than about a third of the country across, so a small region isn't blown up.
    private static func diveArea(around core: CGRect, within focus: CGRect) -> CGRect {
        let room = max(core.width, core.height) * 0.35
        var area = core.insetBy(dx: -room, dy: -room)
        let least = CGSize(width: focus.width / 2.6, height: focus.height / 2.6)
        if area.width < least.width { area = area.insetBy(dx: -(least.width - area.width) / 2, dy: 0) }
        if area.height < least.height { area = area.insetBy(dx: 0, dy: -(least.height - area.height) / 2) }
        return area
    }

    /// The journey between a country's list and one of its places' own lists, such as Australia's
    /// states and Tasmania's local government areas, or between two of those lists, played on the
    /// country's own map in the World's place: the camera dives into the place, and its subdivisions
    /// trace themselves in over it and settle into their own map, as a country's do over the World.
    /// Nil for any other pair of lists, or a list whose map can't be placed on its country's.
    @MainActor
    private init?(withinCountry arrival: CollectionArrival, collections: [Country], snapshot: TravelSnapshot) {
        guard let fromID = arrival.fromID, fromID != arrival.toID,
              let from = collections.first(where: { $0.id == fromID }),
              let to = collections.first(where: { $0.id == arrival.toID }),
              from.parentPlace != nil || to.parentPlace != nil, from.countryListID == to.countryListID,
              let country = collections.first(where: { $0.id == from.countryListID }),
              [from, to].allSatisfy({ $0.id == country.id || $0.parentPlace != nil }),
              let map = TravelMap.named(country.id)
        else { return nil }
        func leg(_ list: Country) -> Leg? {
            guard let place = list.parentPlace, let region = map.region(id: place.id),
                  let local = TravelMap.named(list.id), let placed = local.placedOnParent
            else { return nil }
            let core = region.coreBounds
            guard core.width > 0, core.height > 0 else { return nil }
            let statuses = Dictionary(list.divisions.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first }
            return Leg(
                regionID: place.id, core: core,
                detail: MapDetail(map: placed, statuses: statuses, ownerRegionIDs: [place.id]), local: local)
        }
        let departure = from.parentPlace == nil ? nil : leg(from)
        let destination = to.parentPlace == nil ? nil : leg(to)
        guard (from.parentPlace == nil) == (departure == nil), (to.parentPlace == nil) == (destination == nil) else { return nil }
        self.arrival = arrival
        world = map
        worldStatuses = Dictionary(country.divisions.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first }
        // Fitted as the country's map at rest is, so the journey starts and lands exactly where it sits.
        worldFocus = map.focusRect(including: worldStatuses.keys)
        self.departure = departure
        self.destination = destination
        // A country's map doesn't turn, so the World's centring plays no part.
        projection = .current
        restingLongitude = 0
        startLongitude = 0
        longitude = 0
    }

    /// The World partway through turning, drawn with lighter outlines so it can redraw every frame.
    @MainActor
    func world(turnedTo longitude: Double) -> TravelMap {
        Geography.world?.turningMap(projection, centerLongitude: longitude) ?? world
    }

    @MainActor
    private static func leg(
        for id: String, collections: [Country], world: TravelMap, snapshot: TravelSnapshot,
        projection: MapProjection, center: MapCenter, longitude: Double?
    ) -> Leg? {
        let geography = Geography.subdivisions(of: id)
        guard let collection = collections.first(where: { $0.id == id }),
              let local = TravelMap.named(id),
              let subdivisions = longitude.map({ geography?.map(projection, centerLongitude: $0) })
                ?? geography?.map(projection, center: center),
              let place = CountryCatalog.world.divisions.first(where: { $0.abbreviation == collection.countryListID }),
              let region = world.region(id: place.id)
        else { return nil }
        let core = region.coreBounds
        guard core.width > 0, core.height > 0 else { return nil }
        let statuses = Dictionary(collection.divisions.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first }
        // The World's regions the subdivisions cover give way as they arrive: the country itself,
        // and places such as Hong Kong that are listed in both.
        var owners = Set(subdivisions.regions.map(\.id).filter { statuses[$0] != nil })
        owners.insert(place.id)
        return Leg(
            regionID: place.id, core: core,
            detail: MapDetail(map: subdivisions, statuses: statuses, ownerRegionIDs: owners), local: local)
    }

    /// The map `elapsed` seconds in, on a view of this size.
    func frame(at elapsed: TimeInterval, size: CGSize, insets: EdgeInsets) -> Frame {
        if isRegionDive, let destination {
            return regionDiveFrame(destination, at: elapsed, size: size, insets: insets)
        }
        // First the World turns to where the country sits whole, before the camera dives in.
        if elapsed < turnIn {
            return turningFrame(from: startLongitude, to: longitude, progress: elapsed / turnIn)
        }
        let elapsed = elapsed - turnIn
        // Back out on the World, it turns home to the person's own centre.
        if departure != nil, destination == nil, turnOut > 0, elapsed >= Self.departureDuration {
            return turningFrame(from: longitude, to: restingLongitude, progress: (elapsed - Self.departureDuration) / turnOut)
        }
        let base = MapGeometry(focus: worldFocus, size: size, zoom: 1, pan: .zero, insets: insets)
        let wide = wideCamera(base)
        if let departure, elapsed < Self.departureDuration || destination == nil {
            // The subdivisions move back onto the World, then fade as the camera pulls out.
            let out = Self.smooth((elapsed - 0.45) / 0.9)
            return Frame(
                camera: Self.glide(
                    from: base.camera(fitting: departure.core), to: wide, around: departure.core.center,
                    progress: Self.smoother(out), base: base),
                leg: departure, detailProgress: 1 - out, morphProgress: 1 - Self.smooth(elapsed / 0.75),
                isLeaving: elapsed >= 0.45)
        }
        guard let destination else {
            return Frame(camera: MapCamera(), detailProgress: 0, morphProgress: 0, isLeaving: false)
        }
        // The camera dives in on the country, its subdivisions trace themselves in, then they move
        // into the country's own map.
        let time = elapsed - (departure == nil ? 0 : Self.departureDuration)
        return Frame(
            camera: Self.glide(
                from: wide, to: base.camera(fitting: destination.core), around: destination.core.center,
                progress: Self.smoother(time / 0.85), base: base),
            leg: destination, detailProgress: Self.smooth((time - 0.6) / 0.9),
            morphProgress: Self.smooth((time - 1.1) / 0.9), isLeaving: false,
            selection: time < 0.9 ? destination.regionID : nil)
    }

    /// The whole World turning between two centres, the shorter way round.
    private func turningFrame(from start: Double, to end: Double, progress: Double) -> Frame {
        let turned = start + Self.turn(from: start, to: end) * Self.smoother(progress)
        return Frame(
            camera: MapCamera(), detailProgress: 0, morphProgress: 0, isLeaving: false,
            turningLongitude: Self.normalized(turned))
    }

    /// The view between the two countries: both in sight when going from one to another, or the
    /// whole World.
    private func wideCamera(_ base: MapGeometry) -> MapCamera {
        guard let departure, let destination else { return MapCamera() }
        let both = departure.core.union(destination.core)
        let room = max(both.width, both.height) * 0.6
        let camera = base.camera(fitting: both.insetBy(dx: -room, dy: -room))
        return camera.zoom > 1 ? camera : MapCamera()
    }

    /// The camera partway from one view to another around a point on the map: zooming at an even
    /// pace while the point glides across the screen to where it ends up, as if diving in on it or
    /// pulling out from it.
    private static func glide(
        from start: MapCamera, to end: MapCamera, around point: CGPoint, progress: Double, base: MapGeometry
    ) -> MapCamera {
        let share = CGFloat(min(max(progress, 0), 1))
        let zoom = exp(log(start.zoom) + (log(end.zoom) - log(start.zoom)) * share)
        // Where the point sits before any zoom or pan; the camera scales that and adds its pan.
        let still = base.toScreen(point)
        let from = CGPoint(x: still.x * start.zoom + start.pan.width, y: still.y * start.zoom + start.pan.height)
        let to = CGPoint(x: still.x * end.zoom + end.pan.width, y: still.y * end.zoom + end.pan.height)
        let now = CGPoint(x: from.x + (to.x - from.x) * share, y: from.y + (to.y - from.y) * share)
        return MapCamera(zoom: zoom, pan: CGSize(width: now.x - still.x * zoom, height: now.y - still.y * zoom))
    }

    // MARK: Centring

    /// The whole degrees of longitude, from -180 to 179, a region of the World covers, kept once found.
    @MainActor private static var coverage: [String: Set<Int>] = [:]

    @MainActor
    private static func coveredDegrees(of regionID: String) -> Set<Int> {
        if let degrees = coverage[regionID] { return degrees }
        // On a plate carrée centred on Greenwich, across the map is simply longitude.
        guard let plate = Geography.world?.map(.equirectangular, centerLongitude: 0),
              let region = plate.region(id: regionID)
        else { return [] }
        let frame = plate.outline?.boundingRect ?? CGRect(origin: .zero, size: plate.size)
        guard frame.width > 0 else { return [] }
        func longitude(_ point: CGPoint) -> Double { (point.x - frame.minX) / frame.width * 360 - 180 }
        var degrees = Set<Int>()
        var previous: Double?
        func cover(_ point: CGPoint) {
            let current = longitude(point)
            // Along an edge, every degree between its ends; an edge never spans half the Earth.
            if let previous, abs(current - previous) < 90 {
                for degree in Int(min(previous, current).rounded(.down))...Int(max(previous, current).rounded(.down)) {
                    degrees.insert(degree)
                }
            } else {
                degrees.insert(Int(current.rounded(.down)))
            }
            previous = current
        }
        region.path.forEach { element in
            switch element {
            case .move(let point): previous = nil; cover(point)
            case .line(let point), .quadCurve(let point, _), .curve(let point, _, _): cover(point)
            case .closeSubpath: previous = nil
            }
        }
        degrees = Set(degrees.map { ($0 + 540) % 360 - 180 })
        coverage[regionID] = degrees
        return degrees
    }

    /// The best longitude for the middle of the map, given the degrees the countries cover. On a
    /// flat map, the person's own centre while its edges leave them whole, or else the nearest one
    /// that does, with the edge in the widest stretch of open sea. On the globe, facing them.
    static func bestLongitude(covering degrees: Set<Int>, from start: Double, onGlobe: Bool) -> Double {
        guard !degrees.isEmpty, degrees.count < 360 else { return start }
        // The widest run of uncovered degrees, going east around the Earth.
        var gapStart = 0, gapLength = 0
        for first in -180..<180 where !degrees.contains(first) && degrees.contains((first + 539) % 360 - 180) {
            var length = 0
            while length < 360, !degrees.contains((first + length + 540) % 360 - 180) { length += 1 }
            if length > gapLength { (gapStart, gapLength) = (first, length) }
        }
        guard gapLength > 0 else { return start }
        if onGlobe {
            // Facing the middle of the countries: opposite the middle of the open stretch.
            let facing = normalized(Double(gapStart) + Double(gapLength) / 2 + 180)
            return abs(turn(from: start, to: facing)) < 10 ? start : facing
        }
        let margin = min(4, Double(gapLength) / 2)
        let low = Double(gapStart) + margin, high = Double(gapStart + gapLength) - margin
        let edge = start + 180
        let intoGap = (edge - Double(gapStart)).truncatingRemainder(dividingBy: 360)
        let offset = intoGap < 0 ? intoGap + 360 : intoGap
        if offset >= margin, offset <= Double(gapLength) - margin { return start }
        // Move the edge the shorter way to the nearer end of the open stretch.
        let nearer = abs(turn(from: edge, to: low)) <= abs(turn(from: edge, to: high)) ? low : high
        return normalized(nearer + 180)
    }

    /// The turn from one longitude to another the shorter way round, in degrees, east positive.
    static func turn(from start: Double, to end: Double) -> Double {
        let difference = normalized(end - start)
        return abs(difference) < 0.05 ? 0 : difference
    }

    /// A longitude between -180 and 180.
    static func normalized(_ longitude: Double) -> Double {
        var value = (longitude + 180).truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value - 180
    }

    /// Long enough to follow a turn of this size, and none at all for no turn.
    private static func turnDuration(from start: Double, to end: Double) -> TimeInterval {
        let degrees = abs(turn(from: start, to: end))
        return degrees == 0 ? 0 : 0.35 + degrees / 180 * 0.55
    }

    private static func smooth(_ progress: Double) -> Double {
        let t = min(max(progress, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Gentler at both ends than `smooth`, for the camera.
    private static func smoother(_ progress: Double) -> Double {
        let t = min(max(progress, 0), 1)
        return t * t * t * (t * (6 * t - 15) + 10)
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
