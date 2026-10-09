import Foundation

/// Which part of the Earth sits at the middle of the World map. Maps made in different places
/// are centred differently; many in East Asia put Asia and the Pacific in the middle.
enum MapCenter: String, CaseIterable, Identifiable, Sendable {
    case europeAfrica, asia, pacific, americas

    var id: Self { self }

    /// The centre the World map uses until the person picks another.
    static let standard = MapCenter.europeAfrica
    static let storageKey = "worldMapCenter"

    /// The person's choice, for code outside views.
    static var current: MapCenter {
        UserDefaults.standard.string(forKey: storageKey).flatMap(MapCenter.init(rawValue:)) ?? .standard
    }

    var name: String {
        switch self {
        case .europeAfrica: "Europe & Africa"
        case .asia: "Asia"
        case .pacific: "Pacific"
        case .americas: "Americas"
        }
    }

    /// The longitude at the middle of the map, in degrees east.
    var longitude: Double {
        switch self {
        case .europeAfrica: 0
        case .asia: 105
        case .pacific: 150
        case .americas: -90
        }
    }

    /// The globe symbol showing this side of the Earth.
    var globeSymbolName: String {
        switch self {
        case .europeAfrica: "globe.europe.africa.fill"
        case .asia: "globe.central.south.asia.fill"
        case .pacific: "globe.asia.australia.fill"
        case .americas: "globe.americas.fill"
        }
    }

    /// Position around the Earth from west to east, starting with the Americas.
    var eastwardOrder: Int {
        switch self {
        case .americas: 0
        case .europeAfrica: 1
        case .asia: 2
        case .pacific: 3
        }
    }
}
