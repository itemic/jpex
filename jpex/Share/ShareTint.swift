import SwiftUI

/// A colour for the card's colourful designs, Candy and Plaid, as League Cards come in a plaid of
/// each colour.
enum ShareTint: String, CaseIterable, Identifiable, Sendable {
    case sky, coral, tangerine, sunflower, matcha, teal, grape, charcoal

    static let storageKey = "shareTint"

    var id: Self { self }

    var name: String {
        switch self {
        case .sky: "Sky"
        case .coral: "Coral"
        case .tangerine: "Tangerine"
        case .sunflower: "Sunflower"
        case .matcha: "Matcha"
        case .teal: "Teal"
        case .grape: "Grape"
        case .charcoal: "Charcoal"
        }
    }

    var color: Color {
        switch self {
        case .sky: Color(red: 0.16, green: 0.62, blue: 0.9)
        case .coral: Color(red: 0.94, green: 0.38, blue: 0.42)
        case .tangerine: Color(red: 0.96, green: 0.52, blue: 0.14)
        case .sunflower: Color(red: 0.97, green: 0.78, blue: 0.2)
        case .matcha: Color(red: 0.36, green: 0.63, blue: 0.3)
        case .teal: Color(red: 0.08, green: 0.58, blue: 0.58)
        case .grape: Color(red: 0.52, green: 0.32, blue: 0.85)
        case .charcoal: Color(red: 0.24, green: 0.25, blue: 0.29)
        }
    }

    /// Whether words on it read better dark than white, as on sunflower yellow.
    var prefersDarkText: Bool {
        self == .sunflower
    }
}
