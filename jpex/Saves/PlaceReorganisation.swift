import Foundation

/// A change to a country's places, such as two regions merging, and the day it takes effect.
/// From that day lists show the new place, maps draw its outline, and the level set on the places
/// it replaced carries over to it once: the best of them, so no visit is lost.
struct PlaceReorganisation: Sendable {
    var id: String
    /// Midnight where the change happens, on the day it takes effect.
    var effective: Date
    /// Each new place, and the places it replaces.
    var merges: [String: [String]]
    /// The collection whose bundled maps change, and the maps to use from that day, such as
    /// `map_DK-2027.json` in place of `map_DK.json`. Nil when the bundled maps already show it.
    var maps: (collectionID: String, resource: String)?

    var isInEffect: Bool { Date.now >= effective }

    /// South Jeolla and Gwangju became Jeonnam-Gwangju Special Metropolitan City on 1 July 2026.
    static let jeonnamGwangju = PlaceReorganisation(
        id: "KR-2026-jeonnam-gwangju",
        effective: day(2026, 7, 1, in: "Asia/Seoul"),
        merges: ["KR-JG": ["KR-46", "KR-29"]])

    /// The Capital Region and Zealand become Region East Denmark on 1 January 2027.
    static let eastDenmark = PlaceReorganisation(
        id: "DK-2027-east",
        effective: day(2027, 1, 1, in: "Europe/Copenhagen"),
        merges: ["DK-EAST": ["DK-84", "DK-85"]],
        maps: ("DK", "DK-2027"))

    static let all = [jeonnamGwangju, eastDenmark]

    /// The name a collection's bundled maps go by today, such as `DK-2027` for Denmark from 2027.
    static func mapResourceID(for collectionID: String) -> String {
        all.first { $0.isInEffect && $0.maps?.collectionID == collectionID }?.maps?.resource ?? collectionID
    }

    private static func day(_ year: Int, _ month: Int, _ day: Int, in zone: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone) ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }
}

extension SaveModel {
    static let appliedReorganisationsKey = "appliedPlaceReorganisations"

    /// Carries levels over to places that replaced others, for each change in effect not yet applied.
    /// Returns the changes applied, for the caller to record once it has saved.
    func applyPlaceReorganisations() throws -> [String] {
        let applied = Set(UserDefaults.standard.stringArray(forKey: Self.appliedReorganisationsKey) ?? [])
        let due = PlaceReorganisation.all.filter { $0.isInEffect && !applied.contains($0.id) }
        guard !due.isEmpty else { return [] }
        let snapshot = snapshot()
        let ladder = ladder
        let places = Dictionary(
            CountryCatalog.countries.flatMap(\.divisions).map { ($0.id, $0) }) { first, _ in first }
        var done: [String] = []
        // A list built before the change took effect, such as in an app left open over New Year,
        // doesn't have the new places yet; those changes wait for the next launch.
        for reorganisation in due where reorganisation.merges.keys.allSatisfy({ places[$0] != nil }) {
            for (newID, oldIDs) in reorganisation.merges {
                guard let place = places[newID] else { continue }
                let carried = oldIDs
                    .compactMap { snapshot.stored[$0].flatMap(ladder.level(id:)) }
                    .max { ladder.rank(of: $0) < ladder.rank(of: $1) }
                guard let carried, ladder.rank(of: carried) > ladder.rank(of: snapshot.status(for: place)) else { continue }
                try setStatus(carried, for: place)
            }
            done.append(reorganisation.id)
        }
        return done
    }
}
