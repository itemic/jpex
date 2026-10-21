import SwiftUI

/// One colour of the Atlas's key, with every one of the World's places that has it: type G, and
/// the 57 places whose sockets take it.
struct AtlasKeyEntry: Identifiable {
    var key: MapKey
    /// Every place that has it, A to Z, such as every place whose sockets take the Europlug, C,
    /// whether it's their main socket or one they take as well.
    var places: [AdministrativeDivision]

    var id: String { key.id }

    var count: Int { places.count }

    /// A colouring's key, in its own order, leaving out colours no place has. Worked out once.
    @MainActor
    static func entries(for colouring: MapColouring) -> [AtlasKeyEntry] {
        if let cached = cache[colouring] { return cached }
        let places = CountryCatalog.world.divisions
        let entries = colouring.keys.compactMap { key -> AtlasKeyEntry? in
            let having = places.filter { colouring.keyIDs(ofRegion: $0.id).contains(key.id) }
            guard !having.isEmpty else { return nil }
            return AtlasKeyEntry(
                key: key,
                places: having.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
        }
        cache[colouring] = entries
        return entries
    }

    @MainActor private static var cache: [MapColouring: [AtlasKeyEntry]] = [:]
}
