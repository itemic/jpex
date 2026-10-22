import SwiftUI

/// The sky behind World Time as it is wherever the dial's attention is: the country tapped, or the
/// person's own city. Night with its stars, the deep blues and rose of twilight, the gold of the
/// Sun low over the horizon and the blue of day, all from how high the Sun stands there, so
/// winding the dial through a day takes the sky through it too.
struct WorldTimeSky: View {
    /// The Sun's height above the horizon, in degrees.
    var elevation: Double
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    @State private var start = Date.now

    var body: some View {
        let sky = Self.colors(at: elevation)
        let starlight = Self.starlight(at: elevation)
        LinearGradient(colors: [sky.top, sky.middle, sky.horizon], startPoint: .top, endPoint: .bottom)
            .overlay {
                if starlight > 0.01 {
                    GeometryReader { proxy in
                        // Twenty frames a second is plenty for a twinkle. With Reduce Motion, in Low
                        // Power Mode or in the background, the stars hold still, each at its own
                        // brightness, still coming out and fading with the Sun's height.
                        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !allowsAmbientMotion)) { timeline in
                            Rectangle()
                                .colorEffect(ShaderLibrary.skyStars(
                                    .float2(proxy.size), .float(allowsAmbientMotion ? timeline.date.timeIntervalSince(start) : 0),
                                    .float(starlight)))
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    /// How much of the starlight shows: none by day, coming out through twilight.
    static func starlight(at elevation: Double) -> Double {
        let t = min(max((-4 - elevation) / 11, 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// The sky at the top of the screen, partway down, and at the horizon at its foot.
    struct Colors {
        var top: Color
        var middle: Color
        var horizon: Color
    }

    private typealias Shade = (top: SIMD3<Double>, middle: SIMD3<Double>, horizon: SIMD3<Double>)

    /// The sky at each height of the Sun, in degrees, from deep night to high noon. Rich enough for
    /// white type to stay clear on it at any hour.
    private static let stops: [(elevation: Double, shade: Shade)] = [
        (-90, (SIMD3(0.008, 0.012, 0.035), SIMD3(0.012, 0.020, 0.055), SIMD3(0.020, 0.032, 0.080))),
        (-18, (SIMD3(0.010, 0.016, 0.050), SIMD3(0.016, 0.026, 0.075), SIMD3(0.030, 0.045, 0.120))),
        (-12, (SIMD3(0.016, 0.028, 0.090), SIMD3(0.035, 0.050, 0.150), SIMD3(0.090, 0.085, 0.240))),
        (-6, (SIMD3(0.030, 0.055, 0.170), SIMD3(0.110, 0.110, 0.300), SIMD3(0.400, 0.220, 0.380))),
        (-2, (SIMD3(0.060, 0.110, 0.290), SIMD3(0.250, 0.230, 0.450), SIMD3(0.800, 0.410, 0.360))),
        (2, (SIMD3(0.090, 0.190, 0.430), SIMD3(0.400, 0.400, 0.560), SIMD3(0.940, 0.610, 0.360))),
        (8, (SIMD3(0.080, 0.250, 0.580), SIMD3(0.280, 0.460, 0.740), SIMD3(0.640, 0.720, 0.820))),
        (25, (SIMD3(0.055, 0.250, 0.640), SIMD3(0.190, 0.430, 0.780), SIMD3(0.420, 0.620, 0.860))),
        (90, (SIMD3(0.040, 0.225, 0.620), SIMD3(0.150, 0.400, 0.770), SIMD3(0.360, 0.580, 0.850))),
    ]

    /// The sky when the Sun stands at a height, in degrees, as World Time's zone cards wear it too.
    static func colors(at elevation: Double) -> Colors {
        let upper = stops.firstIndex { $0.elevation >= elevation } ?? stops.count - 1
        let lower = max(upper - 1, 0)
        let span = stops[upper].elevation - stops[lower].elevation
        let t = span > 0 ? min(max((elevation - stops[lower].elevation) / span, 0), 1) : 0
        func blend(_ part: (Shade) -> SIMD3<Double>) -> Color {
            let a = part(stops[lower].shade)
            let value = a + (part(stops[upper].shade) - a) * t
            return Color(red: value.x, green: value.y, blue: value.z)
        }
        return Colors(top: blend { $0.top }, middle: blend { $0.middle }, horizon: blend { $0.horizon })
    }
}
