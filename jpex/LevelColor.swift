import SwiftUI

/// The colours a level can take. Levels save the case name, so keep existing names unchanged.
enum LevelColor: String, CaseIterable, Identifiable, Codable, Sendable {
    case red
    case orange
    case yellow
    case lime
    case green
    case mint
    case lightBlue
    case blue
    case indigo
    case purple
    case pink
    case brown
    /// Reserved for places not visited yet, so it's never offered for a level.
    case gray

    var id: Self { self }

    /// Every colour a level can choose, in rainbow order.
    static var choices: [LevelColor] {
        allCases.filter { $0 != .gray }
    }

    var color: Color {
        switch self {
        case .red: Color("sdgRed")
        case .orange: Color("sdgOrange")
        case .yellow: Color("sdgYellow")
        case .lime: Color(red: 0.55, green: 0.78, blue: 0.25)
        case .green: Color("sdgGreen")
        case .mint: .mint
        case .lightBlue: Color("sdgBlue")
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: Color("sdgPink")
        case .brown: .brown
        case .gray: .gray
        }
    }

    /// The colour's name, for VoiceOver.
    var name: String {
        switch self {
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .lime: "Lime"
        case .green: "Green"
        case .mint: "Mint"
        case .lightBlue: "Light Blue"
        case .blue: "Blue"
        case .indigo: "Indigo"
        case .purple: "Purple"
        case .pink: "Pink"
        case .brown: "Brown"
        case .gray: "Grey"
        }
    }
}
