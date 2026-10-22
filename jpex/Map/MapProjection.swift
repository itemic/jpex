import Foundation

/// Ways to flatten the globe for the Countries map.
enum MapProjection: String, CaseIterable, Identifiable, Sendable {
    case winkelTripel, robinson, equalEarth, mercator, globe
    /// More ways to see the world: rounded compromises, true-size ellipses, and the classic grids.
    case naturalEarth, eckertFour, hammer, sinusoidal, miller, gallPeters, equirectangular
    /// Just for fun: the world as an ellipse, as a heart, and as the UN's emblem sees it.
    case mollweide, heart, polar

    var id: Self { self }

    /// The projection Countries uses until the person picks another.
    static let standard = MapProjection.winkelTripel
    static let storageKey = "worldProjection"

    /// The person's choice, for code outside views.
    static var current: MapProjection {
        UserDefaults.standard.string(forKey: storageKey).flatMap(MapProjection.init(rawValue:)) ?? .standard
    }

    var name: String {
        switch self {
        case .winkelTripel: "Winkel Tripel"
        case .robinson: "Robinson"
        case .equalEarth: "Equal Earth"
        case .mercator: "Mercator"
        case .globe: "Globe"
        case .naturalEarth: "Natural Earth"
        case .eckertFour: "Eckert IV"
        case .hammer: "Hammer"
        case .sinusoidal: "Sinusoidal"
        case .miller: "Miller"
        case .gallPeters: "Gall–Peters"
        case .equirectangular: "Equirectangular"
        case .mollweide: "Mollweide"
        case .heart: "Heart"
        case .polar: "Polar"
        }
    }

    /// The tilt of the globe towards the north, where most of the land is.
    static let globeTilt = 20 * Double.pi / 180
    /// Mercator's poles lie at infinity, so the map keeps to the latitudes people live in.
    static let mercatorLatitudes = (south: -62.0, north: 84.0)

    /// Whether a point faces the viewer. Only the globe has a far side.
    func isVisible(_ point: CGPoint) -> Bool {
        guard self == .globe else { return true }
        let longitude = point.x * .pi / 180
        let latitude = point.y * .pi / 180
        return sin(Self.globeTilt) * sin(latitude) + cos(Self.globeTilt) * cos(latitude) * cos(longitude) >= 0
    }

    /// Projects a point given as longitude and latitude in degrees into map units, north up.
    func project(_ point: CGPoint) -> CGPoint {
        let longitude = point.x * .pi / 180
        let latitude = point.y * .pi / 180
        switch self {
        case .winkelTripel:
            let alpha = acos(cos(latitude) * cos(longitude / 2))
            let sincAlpha = alpha < 1e-9 ? 1 : sin(alpha) / alpha
            let x = 0.5 * (longitude * Self.winkelParallelCosine + 2 * cos(latitude) * sin(longitude / 2) / sincAlpha)
            let y = 0.5 * (latitude + sin(latitude) / sincAlpha)
            return CGPoint(x: x, y: -y)
        case .robinson:
            let degrees = min(abs(point.y), 90)
            let index = min(Int(degrees / 5), Self.robinsonTable.count - 2)
            let fraction = (degrees - Double(index) * 5) / 5
            let lower = Self.robinsonTable[index]
            let upper = Self.robinsonTable[index + 1]
            let length = lower.length + (upper.length - lower.length) * fraction
            let height = lower.height + (upper.height - lower.height) * fraction
            return CGPoint(x: 0.8487 * length * longitude, y: -1.3523 * height * (point.y < 0 ? -1 : 1))
        case .equalEarth:
            let (a1, a2, a3, a4) = (1.340264, -0.081106, 0.000893, 0.003796)
            let theta = asin(3.0.squareRoot() / 2 * sin(latitude))
            let theta2 = theta * theta
            let theta6 = theta2 * theta2 * theta2
            let x = 2 * 3.0.squareRoot() * longitude * cos(theta)
                / (3 * (9 * a4 * theta6 * theta2 + 7 * a3 * theta6 + 3 * a2 * theta2 + a1))
            let y = theta * (a1 + a2 * theta2 + theta6 * (a3 + a4 * theta2))
            return CGPoint(x: x, y: -y)
        case .mercator:
            let south = Self.mercatorLatitudes.south * .pi / 180
            let north = Self.mercatorLatitudes.north * .pi / 180
            let clamped = min(max(latitude, south), north)
            return CGPoint(x: longitude, y: -log(tan(.pi / 4 + clamped / 2)))
        case .naturalEarth:
            // Šavrič and colleagues' polynomial compromise: flat poles with softly rounded corners.
            let phi2 = latitude * latitude
            let phi4 = phi2 * phi2
            let phi6 = phi4 * phi2
            let phi8 = phi4 * phi4
            let phi10 = phi8 * phi2
            let phi12 = phi6 * phi6
            let length = 0.870700 - 0.131979 * phi2 - 0.013791 * phi4 + 0.003971 * phi10 - 0.001529 * phi12
            let y = latitude * (1.007226 + 0.015085 * phi2 - 0.044475 * phi6 + 0.028874 * phi8 - 0.005916 * phi10)
            return CGPoint(x: longitude * length, y: -y)
        case .eckertFour:
            // Equal-area, with the poles drawn as lines half the equator's length and rounded sides.
            // θ comes from θ + sin θ cos θ + 2 sin θ = (2 + π/2) sin φ, by Newton's method.
            let target = (2 + .pi / 2) * sin(latitude)
            var theta = latitude / 2
            for _ in 0..<12 {
                let step = (theta + sin(theta) * cos(theta) + 2 * sin(theta) - target) / (2 * cos(theta) * (1 + cos(theta)))
                theta -= step.isFinite ? step : 0
                if abs(step) < 1e-10 { break }
            }
            let x = 2 / (Double.pi * (4 + .pi)).squareRoot() * longitude * (1 + cos(theta))
            let y = 2 * (Double.pi / (4 + .pi)).squareRoot() * sin(theta)
            return CGPoint(x: x, y: -y)
        case .hammer:
            // Equal-area in an ellipse, its meridians curving more gently towards the edges than Mollweide's.
            let z = (1 + cos(latitude) * cos(longitude / 2)).squareRoot()
            let x = 2 * 2.0.squareRoot() * cos(latitude) * sin(longitude / 2) / z
            let y = 2.0.squareRoot() * sin(latitude) / z
            return CGPoint(x: x, y: -y)
        case .sinusoidal:
            // Every parallel at its true length, so the world tapers to a point at each pole.
            return CGPoint(x: longitude * cos(latitude), y: -latitude)
        case .miller:
            // Mercator softened so the poles fit: a rectangle with the far north less swollen.
            return CGPoint(x: longitude, y: -1.25 * log(tan(.pi / 4 + 0.4 * latitude)))
        case .gallPeters:
            // Every country at its true size in a rectangle, stretched tall near the equator.
            return CGPoint(x: longitude / 2.0.squareRoot(), y: -2.0.squareRoot() * sin(latitude))
        case .equirectangular:
            // Longitude and latitude as a plain grid, twice as wide as it is tall.
            return CGPoint(x: longitude, y: -latitude)
        case .mollweide:
            // An ellipse twice as wide as it is tall, every place its true size. θ comes from
            // 2θ + sin 2θ = π sin φ, found in a few steps of Newton's method.
            var theta = latitude
            for _ in 0..<12 {
                let step = (2 * theta + sin(2 * theta) - .pi * sin(latitude)) / (2 + 2 * cos(2 * theta))
                theta -= step.isFinite ? step : 0
                if abs(step) < 1e-10 { break }
            }
            return CGPoint(x: 2 * 2.0.squareRoot() / .pi * longitude * cos(theta), y: -2.0.squareRoot() * sin(theta))
        case .heart:
            // Werner's projection: parallels are arcs around the North Pole at their true length,
            // which curls the world into a heart with the pole in its dimple.
            let distance = .pi / 2 - latitude
            let angle = distance < 1e-9 ? longitude : longitude * cos(latitude) / distance
            return CGPoint(x: distance * sin(angle), y: distance * cos(angle))
        case .polar:
            // Azimuthal equidistant around the North Pole, as on the UN's emblem: every place at its
            // true distance and direction from the pole, Antarctica stretched around the rim.
            let distance = .pi / 2 - latitude
            return CGPoint(x: distance * sin(longitude), y: distance * cos(longitude))
        case .globe:
            // Seen from far away, tilted a little towards the north. Points on the far side settle
            // on the rim, so every projection moves the same points and can morph into this one.
            let tilt = Self.globeTilt
            let x = cos(latitude) * sin(longitude)
            let y = cos(tilt) * sin(latitude) - sin(tilt) * cos(latitude) * cos(longitude)
            let facing = sin(tilt) * sin(latitude) + cos(tilt) * cos(latitude) * cos(longitude)
            guard facing < 0 else { return CGPoint(x: x, y: -y) }
            let length = max((x * x + y * y).squareRoot(), 1e-9)
            return CGPoint(x: x / length, y: -y / length)
        }
    }

    /// The cosine of Winkel's standard parallel, arccos(2/π).
    private static let winkelParallelCosine = 2 / Double.pi

    /// Robinson's lengths of parallels and distances from the equator, every 5 degrees of latitude.
    private static let robinsonTable: [(length: Double, height: Double)] = [
        (1.0000, 0.0000), (0.9986, 0.0620), (0.9954, 0.1240), (0.9900, 0.1860), (0.9822, 0.2480),
        (0.9730, 0.3100), (0.9600, 0.3720), (0.9427, 0.4340), (0.9216, 0.4958), (0.8962, 0.5571),
        (0.8679, 0.6176), (0.8350, 0.6769), (0.7986, 0.7346), (0.7597, 0.7903), (0.7186, 0.8435),
        (0.6732, 0.8936), (0.6213, 0.9394), (0.5722, 0.9761), (0.5322, 1.0000),
    ]
}
