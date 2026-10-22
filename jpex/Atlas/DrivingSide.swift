import SwiftUI

/// The side of the road a place drives on. Sources are in LAYER_SOURCES.md.
enum DrivingSide: String, CaseIterable {
    case left, right

    /// The side a place drives on, by its ISO 3166 code, or nil where there are no public roads,
    /// such as Antarctica.
    static func of(_ code: String) -> DrivingSide? {
        if roadless.contains(code) { return nil }
        return keepsLeft.contains(code) ? .left : .right
    }

    var name: String {
        switch self {
        case .left: "Left"
        case .right: "Right"
        }
    }

    /// What the callout says, such as "Drives on the left".
    var fact: String {
        switch self {
        case .left: "Drives on the left"
        case .right: "Drives on the right"
        }
    }

    var key: MapKey {
        MapKey(id: rawValue, name: name, color: color, spokenName: fact)
    }

    private var color: Color {
        switch self {
        case .left: LevelColor.orange.color
        case .right: LevelColor.lightBlue.color
        }
    }

    /// Places that keep left, as about a third of the world's people do: mostly Britain and the
    /// places it once ran, and Japan and its neighbours.
    private static let keepsLeft: Set<String> = [
        // Europe. Gibraltar keeps right, unlike the United Kingdom.
        "GB", "IE", "IM", "JE", "GG", "MT", "CY", "XC",
        // Asia. Hong Kong and Macao keep left, unlike the rest of China.
        "JP", "IN", "PK", "BD", "LK", "NP", "BT", "MV", "TH", "MY", "SG", "BN", "ID", "TL", "HK", "MO",
        // Africa
        "ZA", "LS", "SZ", "BW", "NA", "ZW", "ZM", "MW", "MZ", "TZ", "KE", "UG", "MU", "SC", "SH",
        // The Americas. Guyana and Suriname are South America's only two; the US Virgin Islands
        // keep left, unlike the rest of the United States.
        "JM", "BS", "BB", "TT", "GY", "SR", "AG", "DM", "GD", "KN", "LC", "VC", "AI", "BM", "KY", "MS",
        "TC", "VG", "VI", "FK",
        // Oceania. Samoa switched from the right in September 2009.
        "AU", "NZ", "PG", "FJ", "SB", "TO", "WS", "KI", "TV", "NR", "CK", "NU", "PN", "NF", "CC", "CX",
    ]

    /// Places with no public roads or no one to drive on them: those with no permanent population,
    /// the bases of Diego Garcia and Wake Island among them, and Tokelau, which has no cars.
    private static let roadless: Set<String> = ["AQ", "BV", "GS", "HM", "IO", "TF", "TK", "UM"]
}
