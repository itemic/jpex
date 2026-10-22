import Foundation

/// How World Time words its clocks: a time in the person's own style, the hours between two
/// clocks, the day one is on compared with the other, and how far the dial has been wound from now.
enum ClockWords {
    /// A clock's hour and minute, such as "9:41", and apart from them the part of the day, such as
    /// "pm", where the person's locale tells the time in twelve hours.
    struct Time: Equatable {
        var digits: String
        var period: String?
        /// Whether the locale says the part of the day first, as in 下午9:41.
        var periodFirst = false

        var spoken: String {
            guard let period else { return digits }
            return periodFirst ? "\(period) \(digits)" : "\(digits) \(period)"
        }
    }

    static func time(_ date: Date, in zone: TimeZone) -> Time {
        let digits = date.formatted(Date.FormatStyle(timeZone: zone).hour(.defaultDigits(amPM: .omitted)).minute(.twoDigits))
        guard let pattern = twelveHourPattern else { return Time(digits: digits) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let isMorning = calendar.component(.hour, from: date) < 12
        return Time(
            digits: digits, period: isMorning ? periodFormatter.amSymbol : periodFormatter.pmSymbol,
            periodFirst: (pattern.firstIndex(of: "a") ?? pattern.endIndex) < (pattern.firstIndex { "hHkK".contains($0) } ?? pattern.endIndex))
    }

    /// Whether the person's locale tells the time in twelve hours rather than twenty-four.
    static var usesTwelveHours: Bool { twelveHourPattern != nil }

    /// The locale's pattern for an hour, such as "h a", when it has a part of the day in it.
    private static let twelveHourPattern: String? = {
        let pattern = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) ?? ""
        return pattern.contains("a") ? pattern : nil
    }()

    private static let periodFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter
    }()

    /// How far one clock is from the person's: "2 hours ahead of you", "30 minutes behind you", or
    /// just "Now" where it keeps the person's own time.
    static func difference(_ seconds: Int) -> String {
        guard seconds != 0 else { return "Now" }
        let span = Duration.seconds(abs(seconds)).formatted(.units(allowed: [.hours, .minutes], width: .wide))
        return seconds > 0 ? "\(span) ahead of you" : "\(span) behind you"
    }

    /// The same, briefly: "2 hr ahead", "30 min behind", "5 hr, 45 min ahead".
    static func shortDifference(_ seconds: Int) -> String {
        guard seconds != 0 else { return "Your time" }
        let span = Duration.seconds(abs(seconds)).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        return seconds > 0 ? "\(span) ahead" : "\(span) behind"
    }

    /// "Tomorrow" or "Yesterday" where a clock has moved on to another day than the person's.
    static func day(at date: Date, in zone: TimeZone, comparedWith here: TimeZone) -> String? {
        switch dayShift(at: date, in: zone, comparedWith: here) {
        case 1: "Tomorrow"
        case -1: "Yesterday"
        default: nil
        }
    }

    /// How many days a clock is on from the person's at a moment: 1 a day ahead, -1 a day behind.
    static func dayShift(at date: Date, in zone: TimeZone, comparedWith here: TimeZone) -> Int {
        dayNumber(of: date, in: zone) - dayNumber(of: date, in: here)
    }

    /// The day of the week a moment falls on in a zone, such as "Thursday".
    static func weekday(of date: Date, in zone: TimeZone) -> String {
        date.formatted(Date.FormatStyle(timeZone: zone).weekday(.wide))
    }

    /// How far the dial has been wound from now, with the day it's come to: "Friday, in 9 hr" or
    /// "Thursday, 2 hr, 15 min ago".
    static func wound(to date: Date, from now: Date, in zone: TimeZone) -> String {
        let seconds = date.timeIntervalSince(now)
        let span = Duration.seconds(Int64(abs(seconds).rounded()))
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2))
        let day = weekday(of: date, in: zone)
        guard abs(seconds) >= 60 else { return day }
        return seconds > 0 ? "\(day), in \(span)" : "\(day), \(span) ago"
    }

    /// The next change of a zone's clocks: "Clocks go back an hour on Sunday 25 October".
    static func clockChange(_ change: ZoneHistory.Change, in zone: TimeZone) -> String {
        let minutes = abs(change.seconds) / 60
        let amount = minutes == 60 ? "an hour" : minutes % 60 == 0 ? "\(minutes / 60) hours" : "\(minutes) minutes"
        let day = change.date.formatted(Date.FormatStyle(timeZone: zone).weekday(.wide).day().month(.wide))
        return "Clocks go \(change.seconds > 0 ? "forward" : "back") \(amount) on \(day)"
    }

    /// Days since 1970 on a clock's own calendar, for telling whether two clocks share a day.
    private static func dayNumber(of date: Date, in zone: TimeZone) -> Int {
        Int(((date.timeIntervalSince1970 + Double(zone.secondsFromGMT(for: date))) / 86_400).rounded(.down))
    }
}
