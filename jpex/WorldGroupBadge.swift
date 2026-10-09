import SwiftUI

extension WorldGroup {
    var symbolName: String {
        switch self {
        case .unitedNations: "globe"
        case .g7: "7.circle.fill"
        case .g20: "20.circle.fill"
        case .europeanUnion: "star.circle.fill"
        case .schengen: "airplane"
        case .eurozone: "eurosign"
        case .nato: "shield.fill"
        case .commonwealth: "crown.fill"
        case .asean: "leaf.fill"
        case .africanUnion: "globe.europe.africa.fill"
        case .arabLeague: "moon.stars.fill"
        case .oecd: "chart.line.uptrend.xyaxis"
        case .brics: "square.grid.2x2.fill"
        case .gulfCooperation: "sun.max.fill"
        case .opec: "drop.fill"
        case .mercosur: "sparkles"
        case .caricom: "water.waves"
        case .efta: "arrow.left.arrow.right"
        case .nordic: "snowflake"
        case .baltic: "wind"
        case .benelux: "bicycle"
        }
    }

    /// The colour of the group's badge, after its emblem where it has one.
    var color: Color {
        switch self {
        case .unitedNations: Color(red: 0.00, green: 0.62, blue: 0.86)
        case .europeanUnion, .schengen, .eurozone: Color(red: 0.00, green: 0.20, blue: 0.60)
        case .nato: Color(red: 0.00, green: 0.18, blue: 0.40)
        case .g7, .g20, .oecd: .indigo
        case .commonwealth: .purple
        case .asean: Color(red: 0.00, green: 0.25, blue: 0.62)
        case .africanUnion: Color(red: 0.16, green: 0.55, blue: 0.27)
        case .arabLeague, .gulfCooperation: .green
        case .brics: .orange
        case .opec: Color(red: 0.25, green: 0.25, blue: 0.27)
        case .mercosur: .blue
        case .caricom: .teal
        case .efta: .red
        case .nordic: .cyan
        case .baltic: .mint
        case .benelux: .orange
        }
    }

    /// The symbol's colour on the badge: gold on the European blues, as on their flag.
    var symbolColor: Color {
        switch self {
        case .europeanUnion, .schengen, .eurozone: .yellow
        default: .white
        }
    }
}

/// A group's badge in the sidebar: its symbol on a tile in its colour.
struct WorldGroupBadge: View {
    var group: WorldGroup

    var body: some View {
        Rectangle()
            .fill(group.color.gradient)
            .overlay {
                Image(systemName: group.symbolName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(group.symbolColor)
            }
    }
}
