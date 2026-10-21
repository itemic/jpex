import SwiftUI

/// The glass card beneath World Time's dial, as the quiz's card sits beneath its board: the day it
/// is for the person, or how far time has been wound with the way back to now, then what's picked,
/// over every time kept around the World to choose from. A country tapped on the dial
/// heads it with its flag and level, its name, its time large, and how far that is from the
/// person's own, a day on or back where the date line falls between them. A country keeping
/// several times, as Russia keeps eleven, lists every one of them beneath, short card or tall, as
/// a line of chips with the one it leads with lit, to lead with any other at a tap; on a tall card,
/// that time's zones in the tz database follow. A zone picked from the list heads it with its name
/// and UTC offset, then exactly where the time is kept and its names in the tz database. However
/// long the name, the time stays large beside it, the name gliding across to show its end. Either
/// way, every place keeping that time takes the zones' place in the list beneath, as cards with
/// their flags, each to pick in turn, and a capsule at the top leads back to the time zones,
/// letting go of the pick.
struct WorldTimeCard: View {
    enum Heading {
        case place(AdministrativeDivision, status: VisitLevel, clocks: [ZoneClock])
        case band(TimeZoneBand)
    }

    /// What the time shown is, heading the card: "Friday in Taipei", or wound away from now,
    /// "Friday, in 9 hours", with the way back to now beside it.
    var status: String
    var isLive: Bool
    var onNow: () -> Void
    var heading: Heading?
    var bands: [TimeZoneBand]
    /// The moment the dial shows.
    var date: Date
    var here: ZoneClock
    var statuses: [String: VisitLevel]
    /// The zones lit up, by offset.
    var lit: Set<Int>
    /// The zone to bring into view in the list.
    var focus: Int?
    /// Room along the top for the handle that pulls the card up.
    var grabberRoom: CGFloat = 0
    /// Whether the card is short, keeping its heading to the name, the time and how far it is; the
    /// rest shows as it's pulled up.
    var isCompact = false
    var onChoose: (TimeZoneBand) -> Void
    /// A zone turned to lead with another of its names.
    var onTurn: (TimeZoneBand, ZoneName) -> Void
    /// The time picked, whose places head the list; nil while nothing is.
    var sharing: TimeZoneBand? = nil
    /// The place picked, lit among those keeping its time.
    var pickedPlaceID: String? = nil
    /// A place keeping the time picked, tapped in the list, by its ID.
    var onPickPlace: (String) -> Void = { _ in }
    /// One of the times the place picked keeps, tapped among its chips, by the clock it's best
    /// known by: led with, as a tap on the part of the place keeping it on the map does.
    var onPickTime: (ZoneClock) -> Void = { _ in }
    /// The way back to the time zones: lets go of the place or zone picked, as picking it again does.
    var onLetGo: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether a place or a zone is picked, its places standing in the list for the zones.
    private var isPicked: Bool {
        heading != nil || sharing != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            statusRow
            if let heading {
                // Short or tall, the heading keeps one slot, the one cross-fading into the other as
                // the card is pulled up or let down, never the two stacked while they pass.
                ZStack(alignment: .topLeading) {
                    if isCompact {
                        compactHeader(heading)
                    } else {
                        header(heading)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
            ZoneChoices(
                bands: bands, date: date, here: here, lit: lit, focus: focus, sharing: sharing,
                pickedPlaceID: pickedPlaceID, statuses: statuses, onChoose: onChoose, onTurn: onTurn,
                onPickPlace: onPickPlace)
                .padding(.horizontal, 12)
        }
        .padding(.top, grabberRoom)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Tinted, faintly, with the colour of the time picked, as it is on the map.
        .glassPanel(in: .rect(cornerRadius: 28, style: .continuous), tint: heading == nil ? nil : focus.map { ZonePalette.color(forOffset: $0) })
        // On World Time's own curve, so as something's picked or let go, the glass changes size
        // in step with the card's frame and the dial giving way to it.
        .animation(.worldTimeReflow(reduceMotion: reduceMotion), value: headingID)
    }

    /// The day it is for the person; wound away from now, how far, in amber like the thumb on the
    /// dial's ring, and the way back. With something picked, the way back to the time zones leads
    /// the line, where a way back always sits.
    private var statusRow: some View {
        HStack(spacing: 10) {
            if isPicked {
                Button("Time zones", systemImage: "chevron.backward", action: onLetGo)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .glassPanel(in: Capsule(), interactive: true)
                    .contentShape(Capsule())
                    .buttonStyle(PillButtonStyle())
                    .fixedSize()
                    .accessibilityHint("Lets go of what's picked and shows every time zone.")
                    // It pops in from its leading edge as something's picked, as Now does at the
                    // other end of the line, and fades once it's let go; with Reduce Motion, it only fades.
                    .transition(.arrive(reduceMotion: reduceMotion, anchor: .leading))
            }
            ScrollingText { Text(status).contentTransition(.opacity) }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isLive ? AnyShapeStyle(.secondary) : AnyShapeStyle(WorldPainting.wound))
                .padding(.horizontal, isLive ? 0 : 10)
                .padding(.vertical, isLive ? 0 : 4)
                .background {
                    if !isLive {
                        Capsule().fill(WorldPainting.wound.opacity(0.18))
                            .overlay { Capsule().strokeBorder(WorldPainting.wound.opacity(0.5), lineWidth: 1) }
                    }
                }
            Spacer(minLength: 8)
            if !isLive {
                Button("Now", systemImage: "arrow.uturn.backward", action: onNow)
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .glassPanel(in: Capsule(), interactive: true)
                    .contentShape(Capsule())
                    .buttonStyle(PillButtonStyle())
                    .accessibilityHint("Winds back to the present.")
                    // It pops in as time's wound away, and fades once it's back; with Reduce
                    // Motion, it only fades.
                    .transition(.arrive(reduceMotion: reduceMotion))
            }
        }
        .frame(minHeight: 30)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .bouncy(duration: 0.35), value: isLive)
    }

    private var headingID: String? {
        switch heading {
        case .place(let place, _, _): place.id
        case .band(let band): "band-\(band.offset)"
        case nil: nil
        }
    }

    @ViewBuilder
    private func header(_ heading: Heading) -> some View {
        switch heading {
        case let .place(place, status, clocks):
            if let main = clocks.first {
                let words = caption(for: main, city: clocks.count > 1 ? main.city : nil)
                let time = ClockWords.time(date, in: main.timeZone)
                let offset = main.offset(at: date)
                let times = TimeZoneAtlas.times(of: place, at: date, including: main)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        // The flag wears the person's level beneath it, like a badge, leaving the
                        // name the line to itself beside the time.
                        VStack(spacing: 6) {
                            Image(place.flagAssetName)
                                .resizable()
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: 5))
                                .frame(width: 44, height: 30)
                                .grayscale(status == .never ? 1 : 0)
                                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                            if status != .never {
                                VisitPillLabel(status: status, isSmall: true)
                                    .fixedSize()
                            }
                        }
                        .padding(.top, 3)
                        .accessibilityHidden(true)
                        titled(time: time) {
                            // Afresh for each place, so a long name picked after another glides too;
                            // the two cross-fade in one line rather than stand one above the other.
                            ZStack(alignment: .leading) {
                                ScrollingText { Text(place.name) }
                                    .typeStyle(.compactPlaceName)
                                    .id(place.id)
                            }
                        } detail: {
                            subtitle(offset: offset, letters: main.abbreviation(at: date), text: words)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(status == .never ? place.name : "\(place.name), \(status.name)")
                    .accessibilityValue("\(time.spoken), \(words)")
                    // Every time the place keeps, the one it leads with lit, over that time's own
                    // zones in the tz database: all of them for a place keeping only the one.
                    VStack(alignment: .leading, spacing: 6) {
                        if times.count > 1 {
                            KeptTimeChips(times: times, lit: offset, date: date, here: here, onPick: onPickTime)
                        }
                        ZoneFacts(identifiers: Self.identifiers(of: clocks, keeping: offset, at: date), clock: main, date: date)
                    }
                }
                // Led with another of its times, the time and its offset roll over to it and its zones fade across.
                .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy(duration: 0.3), value: offset)
            }
        case .band(let band):
            let words = caption(for: band.clock, city: nil)
            VStack(alignment: .leading, spacing: 10) {
                titled(time: ClockWords.time(date, in: band.clock.timeZone)) {
                    // Turned to another of its names, the new one rolls up into place within its own
                    // line; a long one, such as Australian Eastern Daylight Time, glides across to
                    // show its end.
                    ZStack(alignment: .leading) {
                        ScrollingText { Text(zoneName: band.name(at: date), offset: band.offset) }
                            .typeStyle(.compactPlaceName)
                            .id(band.name.id)
                            .transition(reduceMotion ? .opacity : .push(from: .bottom))
                    }
                    .clipped()
                } detail: {
                    subtitle(offset: band.offset, letters: band.abbreviation(at: date), text: words)
                }
                .clipped()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(band.name(at: date)), \(band.utcName)")
                if !isCompact {
                    // The new name's facts fade across the old in one slot.
                    ZStack(alignment: .topLeading) {
                        ZoneFacts(keptIn: band.name.keptIn, identifiers: band.name.identifiers, clock: band.clock, date: date)
                            .id(band.name.id)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.swap(reduceMotion: reduceMotion), value: band.name.id)
        }
    }

    /// The heading on a short card, on one line, so the places keeping its time have the room: the
    /// flag for a place, the name gliding across where it's too long, then the time's hours from
    /// UTC in its colour and the time there. A place keeping several times adds a line of them all
    /// beneath, as chips, so even short, the card shows every one and leads with any at a tap.
    @ViewBuilder
    private func compactHeader(_ heading: Heading) -> some View {
        switch heading {
        case let .place(place, status, clocks):
            if let main = clocks.first {
                let time = ClockWords.time(date, in: main.timeZone)
                let words = caption(for: main, city: clocks.count > 1 ? main.city : nil)
                let offset = main.offset(at: date)
                let times = TimeZoneAtlas.times(of: place, at: date, including: main)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 10) {
                        Image(place.flagAssetName)
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 4))
                            .frame(width: 30, height: 22)
                            .grayscale(status == .never ? 1 : 0)
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        compactLine(name: Text(place.name), offset: offset, time: time)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(place.name)
                    .accessibilityValue("\(time.spoken), \(words)")
                    if times.count > 1 {
                        KeptTimeChips(times: times, lit: offset, date: date, here: here, onPick: onPickTime)
                    }
                }
                .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy(duration: 0.3), value: offset)
            }
        case .band(let band):
            let time = ClockWords.time(date, in: band.clock.timeZone)
            // Turned to another name, the new line rolls up into place within the old one's room.
            ZStack(alignment: .leading) {
                compactLine(name: Text(zoneName: band.name(at: date), offset: band.offset), offset: band.offset, time: time)
                    .id(band.name.id)
                    .transition(reduceMotion ? .opacity : .push(from: .bottom))
            }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(band.name(at: date)), \(band.utcName)")
            .accessibilityValue("\(time.spoken), \(caption(for: band.clock, city: nil))")
            .animation(.swap(reduceMotion: reduceMotion), value: band.name.id)
        }
    }

    /// A name, then the hours from UTC and the time, on one line.
    private func compactLine(name: Text, offset: Int, time: ClockWords.Time) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            ScrollingText { name }
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            OffsetNumber(offset: offset, size: 15)
            TimeLabel(time: time, digits: .zoneTime, period: .zonePeriod, rolls: true)
                .fixedSize()
        }
    }

    /// The zones in the tz database keeping the time a place's heading leads with, each once, the
    /// one it leads with first: every one of a place keeping a single time, or of a place keeping
    /// several, those of the time lit among them, so the line names what the heading shows.
    private static func identifiers(of clocks: [ZoneClock], keeping offset: Int, at date: Date) -> [String] {
        var seen: Set<String> = []
        return clocks.filter { $0.offset(at: date) == offset }
            .map(\.timeZone.identifier)
            .filter { seen.insert($0).inserted }
    }

    /// A heading's name and the time there, the time large at the trailing edge and the name
    /// beside it, gliding across where it's too long, so Brunei Darussalam's time is as large as
    /// Hong Kong's. Only text so large that the time leaves the name almost no room sets the time,
    /// still large, beneath the name; a name's length never does.
    private func titled<Title: View, Detail: View>(
        time: ClockWords.Time, @ViewBuilder title: () -> Title, @ViewBuilder detail: () -> Detail
    ) -> some View {
        let title = title()
        let detail = detail()
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    title
                    detail
                }
                // Asked how wide it would be, the name claims only `nameRoom`, so its length
                // never decides the layout; it takes whatever the time leaves.
                .frame(minWidth: 0, idealWidth: Self.nameRoom, maxWidth: .infinity, alignment: .leading)
                TimeLabel(time: time, digits: .panelCount, period: .panelTotal, rolls: true)
            }
            VStack(alignment: .leading, spacing: 4) {
                title
                TimeLabel(time: time, digits: .panelCount, period: .panelTotal, rolls: true)
                detail
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The least room a name glides in beside the large time.
    private static let nameRoom: CGFloat = 72

    /// The time's hours from UTC in its colour on the map, the letters it goes by as a small tag,
    /// then how it stands against the person's, all on one line.
    private func subtitle(offset: Int, letters: String?, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            OffsetNumber(offset: offset, size: 15)
            if let letters {
                Text(letters)
                    .font(.caption.weight(.bold))
                    .tracking(0.4)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.16), in: .rect(cornerRadius: 6, style: .continuous))
                    .fixedSize()
            }
            ScrollingText { Text(text) }
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// The day where the date line falls between, the city a country of several zones keeps its
    /// main time in, and the hours from the person's own, briefly: "Tomorrow in Canberra, 2 hr
    /// ahead", or where it keeps the person's own time, just "Your time", wherever in it.
    private func caption(for clock: ZoneClock, city: String?) -> String {
        let seconds = clock.offset(at: date) - here.offset(at: date)
        guard seconds != 0 else { return "Your time" }
        let difference = ClockWords.shortDifference(seconds)
        let day = ClockWords.day(at: date, in: clock.timeZone, comparedWith: here.timeZone)
        switch (day, city) {
        case let (day?, city?): return "\(day) in \(city), \(difference)"
        case let (day?, nil): return "\(day), \(difference)"
        case let (nil, city?): return "In \(city), \(difference)"
        case (nil, nil): return difference
        }
    }
}
