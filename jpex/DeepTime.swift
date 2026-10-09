import SwiftUI
import simd

/// How the continents drifted over the last few hundred million years: each tectonic plate turns
/// about a pole on the globe, and between the moments reconstructions give, glides evenly from
/// one position to the next. Turned back far enough, the plates gather into Pangaea.
struct DeepTime: Sendable {
    /// How far back the plates go, in millions of years.
    var maxMa: Double
    var plates: [Plate]
    /// Which plate each unit rides on, in the order of the atlas's units, or nil for none.
    var unitPlates: [Int?]
    /// When land that is young, such as Iceland, rose from the sea, by unit; before then it fades.
    var unitEmerged: [Double?]
    var periods: [Period]
    var labels: [Label]
    var events: [Event]

    struct Plate: Sendable {
        var id: String
        var name: String
        var keyframes: [Keyframe]
        var color: Color.Resolved
    }

    struct Keyframe: Sendable {
        var ma: Double
        var rotation: simd_quatd
    }

    /// A span of the geologic time scale, such as the Cretaceous, in its chart colour.
    struct Period: Sendable, Identifiable {
        var name: String
        var start: Double
        var end: Double
        var color: Color
        var id: String { name }
    }

    /// A name that rides on a plate for a span of time, such as Pangaea or the Tethys Ocean.
    struct Label: Sendable {
        var name: String
        var from: Double
        var to: Double
        var plate: Int
        /// Where it sits, in today's longitude and latitude on its plate.
        var location: CGPoint
        /// Supercontinents and oceans are set larger than a continent's own name.
        var isGrand: Bool
    }

    struct Event: Sendable, Identifiable {
        var ma: Double
        var title: String
        var detail: String
        var plate: Int?
        var location: CGPoint?
        var kind: Kind
        var id: String { "\(ma)-\(title)" }

        enum Kind: String, Sendable {
            case impact, extinction, rift, collision, life

            var systemImage: String {
                switch self {
                case .impact: "sparkle"
                case .extinction: "flame.fill"
                case .rift: "arrow.trianglehead.branch"
                case .collision: "mountain.2.fill"
                case .life: "leaf.fill"
                }
            }
        }
    }

    init(file: PlatesFile, units: [TimeMachineAtlas.Unit]) {
        maxMa = file.maxMa
        plates = file.plates.enumerated().map { index, item in
            let keyframes = (file.rotations[item.id] ?? [])
                .sorted { $0.ma < $1.ma }
                .map { Keyframe(ma: $0.ma, rotation: Self.quaternion(lat: $0.lat, lon: $0.lon, angle: $0.angle)) }
            return Plate(id: item.id, name: item.name, keyframes: keyframes, color: Self.plateColor(for: item.id, index: index))
        }
        var plateOfCode: [String: Int] = [:]
        for (index, plate) in file.plates.enumerated() {
            for code in plate.units { plateOfCode[code] = index }
        }
        unitPlates = units.map { unit in
            plateOfCode[unit.id] ?? plateOfCode[unit.country]
                ?? plateOfCode[TimeMachineAtlas.parentCode(of: unit.country)]
        }
        let emerged = file.emerged ?? [:]
        unitEmerged = units.map { unit in
            emerged[unit.id] ?? emerged[unit.country] ?? emerged[TimeMachineAtlas.parentCode(of: unit.country)]
        }
        periods = (file.periods ?? []).map {
            Period(name: $0.name, start: $0.start, end: $0.end, color: Color(hex: $0.color) ?? .gray)
        }
        let plateIndex = Dictionary(file.plates.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        let grandNames: Set<String> = ["Pangaea", "Panthalassa", "Tethys Ocean", "Laurasia", "Gondwana", "Atlantic Ocean"]
        labels = (file.labels ?? []).compactMap { item in
            guard let plate = plateIndex[item.plate], item.at.count == 2 else { return nil }
            return Label(name: item.name, from: max(item.from, item.to), to: min(item.from, item.to), plate: plate,
                         location: CGPoint(x: item.at[0], y: item.at[1]), isGrand: grandNames.contains(item.name))
        }
        events = (file.events ?? []).map { item in
            Event(ma: min(item.ma, file.maxMa), title: item.title, detail: item.detail ?? "",
                  plate: item.plate.flatMap { plateIndex[$0] },
                  location: item.at.flatMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil },
                  kind: Event.Kind(rawValue: item.kind ?? "") ?? .life)
        }
        .sorted { $0.ma > $1.ma }
    }

    /// Each plate's turn from where it is today to where it was `ma` million years ago.
    func rotations(at ma: Double) -> [simd_quatd] {
        plates.map { plate in
            let frames = plate.keyframes
            guard let first = frames.first else { return simd_quatd(ix: 0, iy: 0, iz: 0, r: 1) }
            guard ma > first.ma else { return first.rotation }
            for (earlier, later) in zip(frames, frames.dropFirst()) where ma <= later.ma {
                let t = (ma - earlier.ma) / max(later.ma - earlier.ma, 1e-9)
                return simd_slerp(earlier.rotation, later.rotation, t)
            }
            return frames.last?.rotation ?? first.rotation
        }
    }

    /// The span of the time scale `ma` falls in.
    func period(at ma: Double) -> Period? {
        periods.first { ma < $0.start && ma >= $0.end } ?? periods.max { $0.start < $1.start }
    }

    /// How present a unit is: 1 once it has risen, fading out before then.
    func presence(ofUnit index: Int, at ma: Double) -> Double {
        guard let emerged = unitEmerged[index] else { return 1 }
        let fade = max(emerged * 0.25, 2)
        return min(max(1 - (ma - emerged) / fade, 0), 1)
    }

    /// How present a label is at a moment, easing in and out at the ends of its span.
    func presence(of label: Label, at ma: Double) -> Double {
        let edge = max((label.from - label.to) * 0.12, 4)
        // A name lasting back to the start of deep time stays at full strength there.
        let fromEnd = label.from >= maxMa - 0.01 ? 1 : min(max((label.from - ma) / edge, 0), 1)
        let fromStart = label.to <= 0.01 ? 1 : min(max((ma - label.to) / edge, 0), 1)
        return min(fromEnd, fromStart)
    }

    /// Spec rotation: about the pole at `lat`, `lon`, by `angle` degrees, counter-clockwise looking
    /// down on the pole from outside the Earth.
    static func quaternion(lat: Double, lon: Double, angle: Double) -> simd_quatd {
        let axis = unitVector(lon: lon, lat: lat)
        return simd_quatd(angle: angle * .pi / 180, axis: axis)
    }

    static func unitVector(lon: Double, lat: Double) -> simd_double3 {
        let lambda = lon * .pi / 180
        let phi = lat * .pi / 180
        return simd_double3(cos(phi) * cos(lambda), cos(phi) * sin(lambda), sin(phi))
    }

    /// Earthy colours for land in deep time, so it reads as ground rather than as countries.
    private static func plateColor(for id: String, index: Int) -> Color.Resolved {
        let named: [String: HistoryColor] = [
            "NA": .olive, "SA": .sage, "AF": .amber, "EU": .sand, "IN": .rust, "AU": .coral,
            "AN": .ice, "AQ": .ice, "MA": .gold, "MG": .gold, "ZE": .teal, "ZL": .teal, "AR": .sand,
        ]
        if let color = named[id] { return color.resolved }
        let fallback: [HistoryColor] = [.olive, .sage, .amber, .sand, .rust, .coral, .gold, .teal]
        return fallback[index % fallback.count].resolved
    }
}

extension Color {
    /// A colour from a hex string such as "#7FC64E".
    init?(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }
}
