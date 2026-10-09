import Foundation

/// The six fixed statuses from the first version of the app. Places now use the person's
/// own levels; this type remains to read and mirror the original Japan history.
// Do not add a raw value: the original SwiftData store uses this enum's
// synthesized associated-case Codable representation, such as {"visited":{}}.
enum VisitStatus: CaseIterable, Codable, Sendable {
    case never
    case passed
    case alighted
    case visited
    case stayed
    case lived

    /// The matching level ID. The default levels keep these keys, so places saved
    /// before levels could be customised stay attached to them.
    var storageKey: String {
        switch self {
        case .never: "never"
        case .passed: "passed"
        case .alighted: "alighted"
        case .visited: "visited"
        case .stayed: "stayed"
        case .lived: "lived"
        }
    }

    init?(storageKey: String) {
        switch storageKey {
        case "never": self = .never
        case "passed": self = .passed
        case "alighted": self = .alighted
        case "visited": self = .visited
        case "stayed": self = .stayed
        case "lived": self = .lived
        default: return nil
        }
    }
}
