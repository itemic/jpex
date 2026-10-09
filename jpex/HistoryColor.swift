import SwiftUI

/// The colours Time Machine fills its maps with: mid-tones that read on a dark sea, each country
/// keeping its own from era to era, and each empire wearing its homeland's.
enum HistoryColor: String, CaseIterable, Sendable {
    case rose, coral, amber, sand, olive, sage, teal, sky, indigo, violet, plum, slate, rust, gold
    /// Land with no state to draw, and land no one claimed.
    case earth, ice

    var resolved: Color.Resolved {
        let (red, green, blue): (Float, Float, Float) = switch self {
        case .rose: (0.89, 0.55, 0.63)
        case .coral: (0.92, 0.56, 0.45)
        case .amber: (0.90, 0.69, 0.36)
        case .sand: (0.82, 0.74, 0.56)
        case .olive: (0.62, 0.66, 0.40)
        case .sage: (0.51, 0.71, 0.56)
        case .teal: (0.33, 0.67, 0.68)
        case .sky: (0.45, 0.67, 0.89)
        case .indigo: (0.49, 0.52, 0.87)
        case .violet: (0.64, 0.50, 0.85)
        case .plum: (0.75, 0.48, 0.71)
        case .slate: (0.56, 0.60, 0.68)
        case .rust: (0.79, 0.45, 0.33)
        case .gold: (0.86, 0.79, 0.42)
        case .earth: (0.47, 0.42, 0.34)
        case .ice: (0.86, 0.90, 0.95)
        }
        // Given in sRGB; Color.Resolved converts them to the linear light it keeps.
        return Color.Resolved(red: red, green: green, blue: blue, opacity: 1)
    }

    var color: Color { Color(resolved) }
}

extension Color.Resolved {
    /// Partway from this colour to another, in linear light, so the blend doesn't muddy.
    func mixed(with other: Color.Resolved, by t: Float) -> Color.Resolved {
        var color = self
        color.linearRed += (other.linearRed - linearRed) * t
        color.linearGreen += (other.linearGreen - linearGreen) * t
        color.linearBlue += (other.linearBlue - linearBlue) * t
        color.opacity += (other.opacity - opacity) * t
        return color
    }
}
