import Foundation

/// The time World Time's dial shows, on the move: winding on or back to a moment, or to now, as it
/// does after a flick, a tap on Now, and through the day it plays as it opens.
struct TimeGlide: Equatable {
    enum Destination: Equatable {
        /// Now, which keeps moving on while the dial winds towards it.
        case now
        case moment(Date)
    }

    var from: Date
    var to: Destination
    var start: Date
    var length: TimeInterval
    /// Whether it sets off at full speed and only slows, as after a flick, rather than easing in and out.
    var coasts = false
    /// Whether it's winding back to now from a time wound away to, as Now does, or a flick landing
    /// close by now does: until it lands, the dial still shows the time as wound away, its amber
    /// arc shrinking back into the thumb, and only on landing does it all turn back to the present.
    var isReturn = false

    var end: Date { start.addingTimeInterval(length) }

    /// The time the dial shows at a moment of the glide.
    func shown(at date: Date) -> Date {
        let linear = length > 0 ? min(max(date.timeIntervalSince(start) / length, 0), 1) : 1
        let eased = coasts ? 1 - pow(1 - linear, 3) : linear * linear * (3 - 2 * linear)
        let target: Date
        switch to {
        case .now: target = date
        case .moment(let moment): target = moment
        }
        return from.addingTimeInterval(target.timeIntervalSince(from) * eased)
    }

    /// Carries on from a flick at the finger's own speed, in hours of time a second, and comes to
    /// rest on the nearest quarter hour of the person's own clock, the way the flick was going.
    /// A let-go too gentle to be a flick just settles on the nearest quarter hour.
    static func coast(from shown: Date, hoursPerSecond speed: Double, in zone: TimeZone, start: Date = .now) -> TimeGlide {
        guard abs(speed) >= 0.6 else {
            return TimeGlide(
                from: shown, to: .moment(nearestQuarterHour(to: shown, in: zone)), start: start, length: 0.32)
        }
        // Where friction alone would bring it to rest, at most two days away.
        let travel = min(max(speed * 0.45, -48), 48) * 3600
        var target = nearestQuarterHour(to: shown.addingTimeInterval(travel), in: zone)
        // Never back against the flick.
        if (target.timeIntervalSince(shown) > 0) != (speed > 0) {
            target = target.addingTimeInterval(speed > 0 ? 900 : -900)
        }
        // Easing out by a cubic sets off at three times the average speed, so match the finger's.
        let hours = abs(target.timeIntervalSince(shown)) / 3600
        let length = min(max(3 * hours / abs(speed), 0.4), 2.8)
        return TimeGlide(from: shown, to: .moment(target), start: start, length: length, coasts: true)
    }

    /// The quarter hour nearest a moment on a clock, such as 9:45 for 9:41. Zones half or three
    /// quarters of an hour off UTC still land on their own quarter hours.
    static func nearestQuarterHour(to date: Date, in zone: TimeZone) -> Date {
        let offset = Double(zone.secondsFromGMT(for: date))
        let local = date.timeIntervalSince1970 + offset
        let rounded = (local / 900).rounded() * 900
        return Date(timeIntervalSince1970: rounded - offset)
    }
}

/// A finger turning World Time's dial. Time follows the turn, an hour for every 15 degrees,
/// forward as the Earth turns: anticlockwise, seen from above the North Pole.
struct DialSpin {
    /// The time shown when the finger took hold.
    var base: Date
    /// The finger's last angle around the dial's centre, in radians.
    var lastAngle: Double
    /// How far the finger has turned the dial, in degrees, clockwise positive.
    var turned: Double = 0
    /// Whether the dial kept the present when the finger took hold, to go back to if it barely turned.
    var wasLive = false
    /// Recent turns and when, for the speed of a flick.
    private var samples: [(time: Date, turned: Double)] = []

    init(base: Date, angle: Double) {
        self.base = base
        lastAngle = angle
    }

    /// The time shown.
    var shown: Date {
        base.addingTimeInterval(-turned / 15 * 3600)
    }

    /// Follows the finger to a new angle around the centre. `reach` is how far out it is, as a share
    /// of the dial's radius: close to the pivot a small move sweeps a wide angle, so it counts for less.
    mutating func turn(to angle: Double, at time: Date, reach: Double) {
        let delta = remainder((angle - lastAngle) * 180 / .pi, 360)
        lastAngle = angle
        turned += delta * min(max(reach / 0.4, 0.15), 1)
        samples.append((time, turned))
        samples.removeAll { time.timeIntervalSince($0.time) > 0.12 }
    }

    /// How fast the finger was winding time as it let go, in hours a second, forward positive.
    /// A finger that came to a stop before lifting carries no speed.
    func hoursPerSecond(at time: Date) -> Double {
        guard let first = samples.first, let last = samples.last,
              time.timeIntervalSince(last.time) < 0.08
        else { return 0 }
        let span = last.time.timeIntervalSince(first.time)
        guard span > 0.015 else { return 0 }
        return -(last.turned - first.turned) / span / 15
    }
}
