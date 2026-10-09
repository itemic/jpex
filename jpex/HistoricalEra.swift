import CoreGraphics

/// A moment in Time Machine's history, such as 1914, with what had changed since the one before.
struct HistoricalEra: Identifiable, Sendable {
    var id: String
    var year: Int
    var title: String
    var summary: String
    var events: [HistoricalEvent]

    /// Today's era, the last, which is labelled by name rather than by its year.
    var isToday: Bool { id == "today" }
}

/// Something that changed the map between one era and the next, such as Italy taking Libya.
struct HistoricalEvent: Identifiable, Sendable {
    var year: Int
    var title: String
    var detail: String
    /// Where it happened, in longitude and latitude, for its pin on the map.
    var location: CGPoint?
    /// The units or countries it changed, which glow while it's shown.
    var unitIDs: [String]
    /// Polities before and after, whose flags show either side of an arrow.
    var from: [String]
    var to: [String]
    var kind: Kind

    var id: String { "\(year)-\(title)" }

    enum Kind: String, Sendable {
        case independence, unification, partition, annexation, dissolution, colonization
        case decolonization, flag, rename, treaty, revolution

        /// A symbol for events with no flags to show.
        var systemImage: String {
            switch self {
            case .independence, .decolonization: "flag.fill"
            case .unification: "arrow.trianglehead.merge"
            case .partition, .dissolution: "arrow.trianglehead.branch"
            case .annexation, .colonization: "arrow.down.right.and.arrow.up.left"
            case .flag: "flag.fill"
            case .rename: "character.cursor.ibeam"
            case .treaty: "signature"
            case .revolution: "flame.fill"
            }
        }
    }
}
