import Foundation

/// What the tz database built into the system knows of a zone beyond its offset now: when its
/// clocks next change, for summer time or for good. Read from the system's own time zones, so it's
/// as current as the system is.
enum ZoneHistory {
    /// A change of a zone's clocks: when, and how far they move, in seconds, forward positive.
    struct Change: Equatable {
        var date: Date
        var seconds: Int
    }

    /// The next time a zone's clocks change after a moment, for summer time or for good.
    static func nextChange(in zone: TimeZone, after date: Date) -> Change? {
        guard let next = zone.nextDaylightSavingTimeTransition(after: date) else { return nil }
        let before = zone.secondsFromGMT(for: next.addingTimeInterval(-1))
        let after = zone.secondsFromGMT(for: next.addingTimeInterval(1))
        guard before != after else { return nil }
        return Change(date: next, seconds: after - before)
    }
}
