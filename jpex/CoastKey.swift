import SwiftUI

/// The ocean a place has coasts on, as the Atlas colours the World by: the oceans the Seas list
/// groups its seas in, the inland seas, or none at all. Sources are in SEA_SOURCES.md.
enum CoastKey: String, CaseIterable {
    case pacific, atlantic, mediterranean, indian, southern, arctic, inland, landlocked

    /// The key for a sea, from the ocean the Seas list puts it in.
    init?(seaGroupID: String) {
        self.init(rawValue: String(seaGroupID.dropFirst("SEAS-ocean-".count)))
        if self == .landlocked { return nil }
    }

    /// The Seas list's group of seas it stands for. Nil for landlocked.
    var seaGroupID: String? {
        self == .landlocked ? nil : "SEAS-ocean-\(rawValue)"
    }

    var name: String {
        if self == .landlocked { return "Landlocked" }
        return CountryCatalog.seas.groups.first { $0.id == seaGroupID }?.name ?? rawValue.capitalized
    }

    /// Its name in a line of them on a place's card, such as "Atlantic, Mediterranean".
    var shortName: String {
        switch self {
        case .pacific: "Pacific"
        case .atlantic: "Atlantic"
        case .mediterranean: "Mediterranean"
        case .indian: "Indian"
        case .southern: "Southern"
        case .arctic: "Arctic"
        case .inland: "Inland seas"
        case .landlocked: "Landlocked"
        }
    }

    var key: MapKey {
        MapKey(id: rawValue, name: name, color: color, spokenName: spokenName)
    }

    private var spokenName: String {
        switch self {
        case .landlocked: "Landlocked"
        case .inland: "Coasts on inland seas"
        default: "Coasts on the \(name)"
        }
    }

    private var color: Color {
        switch self {
        case .pacific: LevelColor.blue.color
        case .atlantic: LevelColor.lightBlue.color
        case .mediterranean: LevelColor.indigo.color
        case .indian: LevelColor.green.color
        case .southern: LevelColor.purple.color
        case .arctic: LevelColor.mint.color
        case .inland: LevelColor.brown.color
        case .landlocked: LevelColor.orange.color
        }
    }
}
