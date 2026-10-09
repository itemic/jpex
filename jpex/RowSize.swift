import Foundation

/// How tall a list's rows are: roomy, compact, or extra compact, the smallest, with as many places
/// on screen as will fit. Chosen in Settings or the list's View menu, or with a pinch on the list.
enum RowSize: String, CaseIterable, Identifiable {
    case standard
    case compact
    case extraCompact

    static let storageKey = "rowSize"

    /// Before there were three sizes, compact rows were a switch. Whatever it was left at carries over.
    static var saved: RowSize {
        UserDefaults.standard.bool(forKey: "compactList") ? .compact : .standard
    }

    var id: Self { self }

    var name: String {
        switch self {
        case .standard: "Standard"
        case .compact: "Compact"
        case .extraCompact: "Extra Compact"
        }
    }

    var symbolName: String {
        switch self {
        case .standard: "rectangle.grid.1x2"
        case .compact: "rectangle.grid.1x3"
        case .extraCompact: "text.justify"
        }
    }

    /// Whether the name keeps to one line, with anything beneath it set beside it instead.
    var isCompact: Bool { self != .standard }

    /// The next size down, for a pinch in, or none from the smallest.
    var smaller: RowSize? {
        switch self {
        case .standard: .compact
        case .compact: .extraCompact
        case .extraCompact: nil
        }
    }

    /// The next size up, for a pinch out, or none from the largest.
    var larger: RowSize? {
        switch self {
        case .standard: nil
        case .compact: .standard
        case .extraCompact: .compact
        }
    }
}
