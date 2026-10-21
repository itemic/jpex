import Foundation
import SwiftData

@Model
final class SaveModel {
    // Keep this property and VisitStatus's Codable representation unchanged so
    // SwiftData can migrate existing Japan-only stores without losing history.
    var visitStatus: [VisitStatus] = []

    // An optional addition allows lightweight migration of existing stores.
    // Entries use permanent country-qualified IDs, never names or list indices.
    var statusesData: Data?

    // The person's levels, also optional for lightweight migration.
    // Nil until they first change the default levels.
    var levelsData: Data?

    // Every change of level made by hand, dated, oldest first, also optional for lightweight
    // migration. Kept for what's to come, such as when a place was first visited or a year in
    // review; nothing reads it yet. Nil until the first change.
    var changeLogData: Data?

    init() {
        visitStatus = Array(repeating: .never, count: 47)
    }

    /// The person's levels, or the defaults until they change them.
    var ladder: VisitLadder {
        guard let ladder = try? decodedLadder(), ladder.isValid else { return .standard }
        return ladder
    }

    /// The last snapshot decoded and the saved data it came from, so a screen drawn many times a
    /// second, such as a list whose pinned map shrinks as it scrolls, doesn't decode it every time.
    @Transient private var snapshotCache = SnapshotCache()

    /// Decodes saved statuses once; use it to draw a whole screen. The same saved data gives back
    /// the snapshot already decoded.
    func snapshot() -> TravelSnapshot {
        let key = SnapshotCache.Key(statuses: statusesData, levels: levelsData, legacyJapan: visitStatus)
        if let cached = snapshotCache.snapshot, snapshotCache.key == key { return cached }
        let snapshot = TravelSnapshot(stored: (try? decodedStatuses()) ?? [:], legacyJapan: visitStatus, ladder: ladder)
        snapshotCache.key = key
        snapshotCache.snapshot = snapshot
        return snapshot
    }

    func status(for division: AdministrativeDivision) -> VisitLevel {
        snapshot().status(for: division)
    }

    /// Updates both representations for Japan. The original data stays readable
    /// throughout migration; Australia and later countries use only stable IDs.
    /// Invalid new data is never silently replaced by an empty dictionary.
    func setStatus(_ level: VisitLevel, for division: AdministrativeDivision) throws {
        guard ladder.level(id: level.id) != nil else { throw LevelError.missingLevel }
        var stored = try decodedStatuses()
        stored[division.id] = level.id
        let encoded = try JSONEncoder().encode(stored)

        if let index = division.legacyJapanIndex, division.countryID == "JP", index >= 0 {
            var legacy = visitStatus
            if legacy.count <= index {
                legacy.append(contentsOf: repeatElement(.never, count: index + 1 - legacy.count))
            }
            // The original history only knows the default levels; others leave it at never been.
            legacy[index] = VisitStatus(storageKey: level.id) ?? .never
            visitStatus = legacy
        }
        statusesData = encoded
    }

    /// Notes, dated, that places were just set to these levels, after their statuses are set: each
    /// with the level it had in `previous`, and whether it rose by itself, as one of `raised`.
    /// A log that can't be read is left as it is rather than replaced, and the change goes unlogged.
    func logChanges(
        _ changes: [(place: AdministrativeDivision, level: VisitLevel)], from previous: TravelSnapshot? = nil,
        raised: Set<String> = [], at date: Date = .now
    ) {
        guard !changes.isEmpty, var log = try? decodedChangeLog() else { return }
        log.append(contentsOf: changes.map { change in
            PlaceChange(
                placeID: change.place.id, levelID: change.level.id, date: date,
                previousLevelID: previous?.status(for: change.place).id,
                wasRaised: raised.contains(change.place.id) ? true : nil)
        })
        if let encoded = try? JSONEncoder().encode(log) { changeLogData = encoded }
    }

    /// Every change of level logged, oldest first.
    func changeLog() throws -> [PlaceChange] {
        try decodedChangeLog()
    }

    /// Saves new levels. Places at a level that was removed move down to the closest
    /// remaining level below it, or to never been, so no place points at a missing level.
    /// Saved levels or statuses that can't be read are never overwritten.
    func setLadder(_ newLadder: VisitLadder) throws {
        guard newLadder.isValid else { throw LevelError.invalidLevels }
        let replacements = try decodedLadder().replacements(becoming: newLadder)
        let encodedLadder = try JSONEncoder().encode(newLadder)
        guard !replacements.isEmpty else {
            levelsData = encodedLadder
            return
        }
        let original = try decodedStatuses()
        var stored = original.mapValues { replacements[$0]?.id ?? $0 }
        var legacy = visitStatus
        for division in CountryCatalog.japan.divisions {
            guard let index = division.legacyJapanIndex, legacy.indices.contains(index) else { continue }
            // A place known only from the original history gets a record of its own.
            if stored[division.id] == nil, let replacement = replacements[legacy[index].storageKey] {
                stored[division.id] = replacement.id
            }
            if let id = stored[division.id], id != original[division.id] {
                legacy[index] = VisitStatus(storageKey: id) ?? .never
            }
        }
        let encodedStatuses = try JSONEncoder().encode(stored)
        visitStatus = legacy
        statusesData = encodedStatuses
        levelsData = encodedLadder
    }

    /// Puts every place, in every collection, back to never been. The person's levels stay as they are.
    /// Saved at once, and undo forgets the steps before it, which could otherwise bring back parts.
    func resetPlaces() {
        statusesData = nil
        visitStatus = Array(repeating: .never, count: 47)
        changeLogData = nil
        finishReset()
    }

    /// Puts every place back to never been and the levels back to the original five.
    func resetEverything() {
        statusesData = nil
        visitStatus = Array(repeating: .never, count: 47)
        levelsData = nil
        changeLogData = nil
        finishReset()
    }

    private func finishReset() {
        try? modelContext?.save()
        NotificationCenter.default.post(name: .placesDidReset, object: self)
    }

    func statuses(for divisions: [AdministrativeDivision]) -> [VisitLevel] {
        let snapshot = snapshot()
        return divisions.map(snapshot.status(for:))
    }

    /// Places at any level, wherever counting starts.
    func markedCount(in divisions: [AdministrativeDivision]) -> Int {
        statuses(for: divisions).filter { $0 != .never }.count
    }

    func markedCount(in country: Country) -> Int {
        markedCount(in: country.divisions)
    }

    func score(in divisions: [AdministrativeDivision]) -> Int {
        let snapshot = snapshot()
        return divisions.reduce(0) { $0 + snapshot.ladder.rank(of: snapshot.status(for: $1)) }
    }

    func score(in country: Country) -> Int {
        score(in: country.divisions)
    }

    func strongestStatus(in divisions: [AdministrativeDivision]) -> VisitLevel {
        snapshot().strongestStatus(in: divisions)
    }

    func strongestStatus(in country: Country) -> VisitLevel {
        strongestStatus(in: country.divisions)
    }

    private func decodedStatuses() throws -> [String: String] {
        guard let statusesData else { return [:] }
        // Preserve unknown future IDs and status values when saving other entries.
        return try JSONDecoder().decode([String: String].self, from: statusesData)
    }

    private func decodedChangeLog() throws -> [PlaceChange] {
        guard let changeLogData else { return [] }
        return try JSONDecoder().decode([PlaceChange].self, from: changeLogData)
    }

    private func decodedLadder() throws -> VisitLadder {
        guard let levelsData else { return .standard }
        return try JSONDecoder().decode(VisitLadder.self, from: levelsData)
    }
}

/// A place set to a level, and when. Kept by permanent IDs, so it follows renames.
struct PlaceChange: Codable, Equatable {
    var placeID: String
    var levelID: String
    var date: Date
    /// The level it had just before, where known.
    var previousLevelID: String? = nil
    /// Whether it rose by itself, as a country does when one of its places rises, rather than by hand.
    var wasRaised: Bool? = nil
}

/// Why a change to levels or places was refused.
enum LevelError: LocalizedError {
    case missingLevel
    case invalidLevels

    var errorDescription: String? {
        switch self {
        case .missingLevel: "That level no longer exists."
        case .invalidLevels: "Every level needs its own name, and there must be at least one."
        }
    }
}

extension Notification.Name {
    /// Every place went back to never been, so undo has nothing left to put back.
    static let placesDidReset = Notification.Name("placesDidReset")
}

/// Holds the last decoded snapshot. A class, so filling it in while a view draws changes nothing
/// that views watch.
final class SnapshotCache {
    struct Key: Equatable {
        var statuses: Data?
        var levels: Data?
        var legacyJapan: [VisitStatus]
    }

    var key: Key?
    var snapshot: TravelSnapshot?
}
