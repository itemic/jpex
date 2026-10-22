import SwiftUI
import simd

/// Daylight and darkness on the World map as they are right now: the night side shaded, deepening
/// through twilight, with the capitals' lights glowing in the dark. Switched on from a list's eye
/// menu, it plays a whole day through in a moment, then creeps on with the Sun.
enum DayNight {
    static let storageKey = "mapShowsDayNight"

    /// How long the map takes to play a day through when day and night are switched on.
    static let introDuration = 2.4
    static let fadeDuration = 0.4

    /// The point on the Earth where the Sun is straight overhead at a moment, in degrees.
    struct Sun: Equatable {
        var latitude: Double
        var longitude: Double

        /// The Sun's place from its mean orbit, good to a small fraction of a degree for centuries
        /// either side of 2000: plenty for shading a map.
        init(at date: Date) {
            let radians = Double.pi / 180
            let days = date.timeIntervalSince1970 / 86_400 - 10_957.5
            let meanLongitude = 280.460 + 0.985_647_4 * days
            let anomaly = (357.528 + 0.985_600_3 * days) * radians
            let ecliptic = (meanLongitude + 1.915 * sin(anomaly) + 0.020 * sin(2 * anomaly)) * radians
            let obliquity = (23.4393 - 0.000_000_4 * days) * radians
            let rightAscension = atan2(cos(obliquity) * sin(ecliptic), cos(ecliptic)) / radians
            latitude = asin(sin(obliquity) * sin(ecliptic)) / radians
            let siderealHours = (18.697_374_558 + 24.065_709_824_419_08 * days).truncatingRemainder(dividingBy: 24)
            longitude = DayNight.normalized(rightAscension - siderealHours * 15)
        }

        /// The sine of the Sun's height above the horizon at a place.
        func elevationSine(latitude: Double, longitude: Double) -> Double {
            let radians = Double.pi / 180
            return sin(latitude * radians) * sin(self.latitude * radians)
                + cos(latitude * radians) * cos(self.latitude * radians) * cos((longitude - self.longitude) * radians)
        }
    }

    /// A longitude between -180 and 180.
    static func normalized(_ longitude: Double) -> Double {
        var value = (longitude + 180).truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value - 180
    }
}

extension EnvironmentValues {
    /// Whether World maps shade the night side, as the person chose in a list's eye menu. Maps that
    /// don't set it, such as the quiz's, stay in daylight.
    @Entry var showsDayNight = false
}

/// The night side of a World map at a moment, in the map's own units: bands of shade, each the part
/// of the World where the Sun is below its step of twilight, and the capitals' lights in the dark.
struct NightShade {
    struct Band {
        var path: Path
        var opacity: Double
    }

    struct Light {
        var point: CGPoint
        /// From 0 at dusk to 1 once it's properly dark.
        var glow: Double
    }

    var bands: [Band]
    var lights: [Light]

    /// Twilight's steps: the Sun just set, then the ends of civil, nautical and astronomical twilight.
    private static let steps: [(elevation: Double, opacity: Double)] = [(0, 0.17), (-6, 0.13), (-12, 0.11), (-18, 0.09)]

    /// The night over a map drawn in a projection around a centre longitude. `edge` is how far east
    /// and west of the centre to shade: a little past the map's sides for World maps laid side by
    /// side, so their copies' shade runs on across the joins.
    @MainActor
    static func make(projection: MapProjection, centerLongitude: Double, sun: DayNight.Sun, edge: Double) -> NightShade {
        let key = Key(
            projection: projection, center: Int((centerLongitude * 100).rounded()), edge: Int(edge),
            sunLatitude: Int((sun.latitude * 100).rounded()), sunLongitude: Int((sun.longitude * 100).rounded()))
        if let shade = cache.first(where: { $0.key == key })?.shade { return shade }
        let bands = steps.map { step in
            Band(
                path: projection == .globe
                    ? globeBand(elevation: step.elevation, center: centerLongitude, sun: sun)
                    : flatBand(elevation: step.elevation, projection: projection, center: centerLongitude, sun: sun, edge: edge),
                opacity: step.opacity)
        }
        let shade = NightShade(
            bands: bands, lights: capitalLights(projection: projection, center: centerLongitude, sun: sun))
        cache = Array((cache + [(key, shade)]).suffix(6))
        return shade
    }

    private struct Key: Equatable {
        var projection: MapProjection
        var center: Int
        var edge: Int
        var sunLatitude: Int
        var sunLongitude: Int
    }

    @MainActor private static var cache: [(key: Key, shade: NightShade)] = []

    // MARK: Flat maps

    /// The part of a flat map where the Sun is lower than `elevation`, traced along every other
    /// meridian. Night's edge crosses each meridian at most once each side of it, so the night on
    /// a meridian is one stretch of latitude, and neighbouring stretches join into bands: around a
    /// pole, or an island of darkness between them that may run off one side of the map and on at
    /// the other.
    private static func flatBand(
        elevation: Double, projection: MapProjection, center: Double, sun: DayNight.Sun, edge: Double
    ) -> Path {
        let radians = Double.pi / 180
        let sinElevation = sin(elevation * radians)
        let sunSine = sin(sun.latitude * radians)
        let sunCosine = cos(sun.latitude * radians)
        let step = 2.0
        let meridians = stride(from: -edge, through: edge, by: step).map { x -> (x: Double, night: ClosedRange<Double>?) in
            let hourAngle = (x + center - sun.longitude) * radians
            return (x, nightStretch(a: sunSine, b: sunCosine * cos(hourAngle), sinElevation: sinElevation))
        }
        func point(_ x: Double, _ latitude: Double) -> CGPoint {
            projection.project(CGPoint(x: x, y: latitude))
        }
        /// A meridian between two latitudes, followed every few degrees so it curves as the map does.
        func meridian(_ x: Double, from start: Double, to end: Double) -> [CGPoint] {
            let count = max(Int((abs(end - start) / 5).rounded(.up)), 1)
            return (0...count).map { point(x, start + (end - start) * Double($0) / Double(count)) }
        }
        var path = Path()
        var index = 0
        while index < meridians.count {
            guard meridians[index].night != nil else {
                index += 1
                continue
            }
            var run: [(x: Double, night: ClosedRange<Double>)] = []
            while index < meridians.count, let night = meridians[index].night {
                run.append((meridians[index].x, night))
                index += 1
            }
            guard let first = run.first, let last = run.last else { continue }
            var points: [CGPoint] = []
            // Where the night starts or stops between two meridians, it narrows to a point halfway.
            if first.x > -edge {
                points.append(point(first.x - step / 2, (first.night.lowerBound + first.night.upperBound) / 2))
            }
            points += run.map { point($0.x, $0.night.upperBound) }
            if last.x < edge {
                points.append(point(last.x + step / 2, (last.night.lowerBound + last.night.upperBound) / 2))
            } else {
                points += meridian(last.x, from: last.night.upperBound, to: last.night.lowerBound)
            }
            points += run.reversed().map { point($0.x, $0.night.lowerBound) }
            if first.x <= -edge {
                points += meridian(first.x, from: first.night.lowerBound, to: first.night.upperBound)
            }
            path.addLines(points)
            path.closeSubpath()
        }
        return path
    }

    /// The latitudes on one meridian, in degrees, where the Sun is below the elevation whose sine is
    /// `sinElevation`. Along a meridian the Sun's elevation sine is a·sin φ + b·cos φ, which is
    /// R·cos(φ − φ₀); it is too low more than acos(sin h ⁄ R) from φ₀ on that circle, and of that arc,
    /// only what falls between the poles counts. For twilight's steps, at or below the horizon,
    /// that arc is shorter than a half turn, so it leaves a single stretch.
    private static func nightStretch(a: Double, b: Double, sinElevation: Double) -> ClosedRange<Double>? {
        let degrees = 180 / Double.pi
        let size = (a * a + b * b).squareRoot()
        guard size > 1e-9 else { return sinElevation > 0 ? -90...90 : nil }
        let ratio = sinElevation / size
        if ratio >= 1 { return -90...90 }
        if ratio <= -1 { return nil }
        let halfDay = acos(ratio)
        let start = remainder(atan2(a, b) + halfDay, 2 * Double.pi)
        let length = 2 * Double.pi - 2 * halfDay
        let pieces = start + length <= Double.pi
            ? [(start, start + length)]
            : [(start, Double.pi), (-Double.pi, start + length - 2 * Double.pi)]
        let stretches = pieces.compactMap { low, high -> ClosedRange<Double>? in
            let bottom = max(low, -Double.pi / 2)
            let top = min(high, Double.pi / 2)
            return bottom < top ? (bottom * degrees)...(top * degrees) : nil
        }
        guard let first = stretches.first else { return nil }
        // Only above the horizon can there be two; join them rather than drop one.
        return stretches.dropFirst().reduce(first) { min($0.lowerBound, $1.lowerBound)...max($0.upperBound, $1.upperBound) }
    }

    // MARK: The globe

    /// Night on the globe: the cap of the Earth around the point opposite the Sun, traced round its
    /// edge and cut where it passes behind the globe, then closed along the rim, the way the
    /// globe's far side meets its edge.
    private static func globeBand(elevation: Double, center: Double, sun: DayNight.Sun) -> Path {
        let radians = Double.pi / 180
        let sunDirection = viewed(earth(latitude: sun.latitude, longitude: sun.longitude - center))
        let night = -sunDirection
        let radius = (90 + elevation) * radians
        // Two directions across night's edge, square to its centre and to each other.
        let reference = abs(night.z) < 0.9 ? SIMD3<Double>(0, 0, 1) : SIMD3<Double>(1, 0, 0)
        let across = simd_normalize(simd_cross(night, reference))
        let along = simd_cross(night, across)
        let count = 180
        let ring = (0..<count).map { index -> SIMD3<Double> in
            let angle = Double(index) / Double(count) * 2 * Double.pi
            return cos(radius) * night + sin(radius) * (cos(angle) * across + sin(angle) * along)
        }
        let isVisible = ring.map { $0.z >= 0 }
        var path = Path()
        guard isVisible.contains(true) else {
            // Wholly out of sight, unless the night covers the whole face turned to us.
            if night.z > 0, radius > Double.pi / 2 {
                path.addEllipse(in: CGRect(x: -1, y: -1, width: 2, height: 2))
            }
            return path
        }
        guard isVisible.contains(false) else {
            path.addLines(ring.map(onMap))
            path.closeSubpath()
            return path
        }
        /// Where an edge between a point in sight and one behind crosses the rim, as an angle round it.
        func rimAngle(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
            let crossing = a + (b - a) * (a.z / (a.z - b.z))
            return atan2(crossing.y, crossing.x)
        }
        /// The rim from one angle to another, going round the side that lies in the night.
        func rim(from start: Double, to end: Double) -> [CGPoint] {
            var turn = (end - start).truncatingRemainder(dividingBy: 2 * Double.pi)
            if turn < 0 { turn += 2 * Double.pi }
            let middle = start + turn / 2
            let isNight = simd_dot(SIMD3(cos(middle), sin(middle), 0), night) > cos(radius)
            if !isNight { turn -= 2 * Double.pi }
            let steps = max(Int((abs(turn) / (4 * radians)).rounded(.up)), 1)
            return (0...steps).map { step in
                let angle = start + turn * Double(step) / Double(steps)
                return CGPoint(x: cos(angle), y: -sin(angle))
            }
        }
        // Start just as the edge comes into sight, and walk it once round.
        guard let entry = (0..<count).first(where: { !isVisible[$0] && isVisible[($0 + 1) % count] }) else { return path }
        var points: [CGPoint] = []
        var firstEntry: Double?
        var lastExit: Double?
        for offset in 1...count {
            let previous = ring[(entry + offset - 1) % count]
            let current = ring[(entry + offset) % count]
            if previous.z < 0, current.z >= 0 {
                let angle = rimAngle(previous, current)
                if let lastExit { points += rim(from: lastExit, to: angle) }
                if firstEntry == nil { firstEntry = angle }
            } else if previous.z >= 0, current.z < 0 {
                lastExit = rimAngle(previous, current)
                points.append(CGPoint(x: cos(lastExit!), y: -sin(lastExit!)))
            }
            if current.z >= 0 { points.append(onMap(current)) }
        }
        if let lastExit, let firstEntry { points += rim(from: lastExit, to: firstEntry) }
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    /// A place as a direction from the Earth's centre, x towards the map's middle, y east, z north.
    private static func earth(latitude: Double, longitude: Double) -> SIMD3<Double> {
        let radians = Double.pi / 180
        return SIMD3(
            cos(latitude * radians) * cos(longitude * radians), cos(latitude * radians) * sin(longitude * radians),
            sin(latitude * radians))
    }

    /// A direction as the globe shows it, tilted towards the north as `MapProjection.globe` is:
    /// x across, y up and z towards the viewer.
    private static func viewed(_ point: SIMD3<Double>) -> SIMD3<Double> {
        let tilt = MapProjection.globeTilt
        return SIMD3(point.y, cos(tilt) * point.z - sin(tilt) * point.x, sin(tilt) * point.z + cos(tilt) * point.x)
    }

    /// A point on the globe's face in map units, north up.
    private static func onMap(_ point: SIMD3<Double>) -> CGPoint {
        CGPoint(x: point.x, y: -point.y)
    }

    // MARK: Lights

    /// Where the capitals are, as longitude and latitude, found once.
    @MainActor private static let capitals: [CGPoint] = CountryCatalog.world.divisions
        .flatMap { CapitalCities.capitals(of: $0).compactMap(\.location) }

    /// The capitals in the dark, each glowing more the further the Sun has set there.
    @MainActor
    private static func capitalLights(projection: MapProjection, center: Double, sun: DayNight.Sun) -> [Light] {
        capitals.compactMap { place in
            let height = asin(min(max(sun.elevationSine(latitude: place.y, longitude: place.x), -1), 1)) * 180 / .pi
            let glow = min(max((-height - 2) / 8, 0), 1)
            guard glow > 0.02 else { return nil }
            let longitude = DayNight.normalized(place.x - center)
            if projection == .globe {
                let point = viewed(earth(latitude: place.y, longitude: longitude))
                guard point.z > 0.03 else { return nil }
                return Light(point: onMap(point), glow: glow * glow * (3 - 2 * glow))
            }
            return Light(
                point: projection.project(CGPoint(x: longitude, y: place.y)), glow: glow * glow * (3 - 2 * glow))
        }
    }
}
