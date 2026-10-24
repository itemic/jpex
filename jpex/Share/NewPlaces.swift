import Foundation

/// The places in a list most newly been to, read from the log of changes: those first set from never
/// been to a level within a day of the latest such change, and been to still, for a card saying
/// "+3 new prefectures".
enum NewPlaces {
    /// How far back from the latest new place the others count as new along with it.
    static let window: TimeInterval = 24 * 60 * 60

    /// The newest places' IDs, in the list's own order.
    static func ids(in country: Country, log: [PlaceChange], snapshot: TravelSnapshot) -> [String] {
        let members = Set(country.divisions.map(\.id))
        let never = VisitLevel.never.id
        // Each place's level as the log goes, for changes logged without the level they left.
        var levels: [String: String] = [:]
        var firstVisits: [(id: String, date: Date)] = []
        for change in log where members.contains(change.placeID) {
            let before = change.previousLevelID ?? levels[change.placeID] ?? never
            if before == never, change.levelID != never {
                firstVisits.append((change.placeID, change.date))
            }
            levels[change.placeID] = change.levelID
        }
        // Only places been to still, so one added and taken away again sets no day of its own.
        let visited = Set(country.divisions.filter { snapshot.status(for: $0).id != never }.map(\.id))
        let kept = firstVisits.filter { visited.contains($0.id) }
        guard let latest = kept.map(\.date).max() else { return [] }
        let recent = Set(kept.filter { $0.date >= latest.addingTimeInterval(-window) }.map(\.id))
        return country.divisions.filter { recent.contains($0.id) }.map(\.id)
    }
}
