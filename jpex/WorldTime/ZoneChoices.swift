import SwiftUI

/// Every time kept around the World as a grid of cards to tap, like the quiz's list of answers:
/// each zone's hours from UTC in its colour on the time zone map, so the list is the map's key,
/// then its time at the moment the dial shows, the letters it goes by and its name. A
/// time known by several names, as UTC+8 is China Standard Time in China and Taiwan Standard Time in
/// Taiwan, lists them all at a long press, to lead with any. Each card wears the sky over its zone,
/// so winding time sends dawn and dusk washing across the list. The person's own zone is marked,
/// and the zones of the country tapped on the dial, or the zone picked here, light up calmly. A
/// zone lights up in its own colour on the map, the same whichever name it goes by. On a narrow
/// screen the zones run one to a row, their names whole. It fades out at an edge only where it
/// carries on.
///
/// With a place or a zone picked, every place keeping that time takes the zones' place, as cards
/// with their flags like the quiz's list of every answer: the places whose own time it is, then
/// those keeping it in only part of their land, by where in them. Tapping one picks it, as tapping
/// it on the map does. The zones come back, fading in where the places were, once the pick is let
/// go, by the card's way back to them, a tap on the World, or Escape.
struct ZoneChoices: View {
    var bands: [TimeZoneBand]
    /// The moment the dial shows.
    var date: Date
    var here: ZoneClock
    /// The zones lit up, by offset.
    var lit: Set<Int>
    /// The zone to bring into view, as one is picked or lights up.
    var focus: Int?
    /// The time picked, whose places head the list; nil while nothing is.
    var sharing: TimeZoneBand? = nil
    /// The place picked, lit among those keeping its time.
    var pickedPlaceID: String? = nil
    var statuses: [String: VisitLevel] = [:]
    var onChoose: (TimeZoneBand) -> Void
    /// A zone's card turned to lead with another of its names.
    var onTurn: (TimeZoneBand, ZoneName) -> Void
    /// A place keeping the time picked, tapped, by its ID.
    var onPickPlace: (String) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The list's width, which sets how many cards fit across, and its height.
    @State private var columnWidth: CGFloat = 0
    @State private var listHeight: CGFloat = 0
    /// The narrowest a card can be, so names have room, growing with the text: one to a row on a
    /// phone, several across on a wider screen.
    @ScaledMetric(relativeTo: .subheadline) private var cardWidth = 236

    var body: some View {
        let hereOffset = here.offset(at: date)
        let sun = DayNight.Sun(at: date)
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id(Self.topID)
                    // The places keeping the time picked, or with nothing picked, every zone: one
                    // fading into the other, rising a touch unless Reduce Motion is on. Both share
                    // one slot from the top, so as they trade places the list is never the two
                    // stacked, and the zone let go is found where it really is.
                    ZStack(alignment: .top) {
                        if let sharing {
                            SameTimePlaces(band: sharing, pickedPlaceID: pickedPlaceID, statuses: statuses, onPick: onPickPlace)
                                .padding(.top, -14)
                                .transition(swap)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 10)], spacing: 10) {
                                ForEach(bands) { band in
                                    ZoneCard(
                                        band: band, date: date, here: here, isHere: band.offset == hereOffset,
                                        isLit: lit.contains(band.offset), sunHeight: band.sunHeight(for: sun)
                                    ) {
                                        onChoose(band)
                                    } onTurn: { name in
                                        onTurn(band, name)
                                    }
                                    .id(band.offset)
                                }
                            }
                            .transition(swap)
                        }
                    }
                }
            }
            // Ending 16 pt above the card's rounded foot, as every grid in glass does, so the last
            // cards never crowd its curve.
            .cardGridScrolling(bottomInset: 8)
            // Summer time adding or taking away a zone while winding moves the cards round it into
            // place on a spring; with Reduce Motion, on a short ease.
            .animation(Motion.moving(.snappy, reduceMotion: reduceMotion), value: bands.map(\.id))
            // On World Time's own curve, so the places and the zones trade in step with the card
            // changing size round them.
            .animation(.worldTimeReflow(reduceMotion: reduceMotion), value: sharing?.offset)
            // Opens on the person's own time, once the grid has its cards, and finds it again
            // whenever the cards rearrange, as when iPhone Duo opens, folds or turns; with a time
            // picked, on the places keeping it.
            .task(id: columnWidth) {
                try? await Task.sleep(for: .milliseconds(60))
                if sharing != nil {
                    proxy.scrollTo(Self.topID, anchor: .top)
                } else {
                    proxy.scrollTo(focus ?? hereOffset, anchor: .center)
                }
            }
            // A header coming in above the list leaves less room: the zone lit glides back into view.
            .task(id: listHeight) {
                guard sharing == nil, let focus else { return }
                try? await Task.sleep(for: .milliseconds(80))
                withAnimation(scrolling) { proxy.scrollTo(focus, anchor: .center) }
            }
            .onGeometryChange(for: CGSize.self) { CGSize(width: $0.size.width.rounded(), height: $0.size.height.rounded()) } action: {
                columnWidth = $0.width
                listHeight = $0.height
            }
            // A time picked brings its places in at the top; let go, the zones come back on the
            // one it was.
            .onChange(of: sharing?.offset) { old, new in
                if new != nil {
                    withAnimation(scrolling) { proxy.scrollTo(Self.topID, anchor: .top) }
                } else if let old {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(60))
                        withAnimation(scrolling) { proxy.scrollTo(old, anchor: .center) }
                    }
                }
            }
        }
        .fontDesign(.rounded)
    }

    private static let topID = "top"

    /// How the list glides to what matters; with Reduce Motion, it simply goes there.
    private var scrolling: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.4)
    }

    /// How the places keeping a time and the zones give way to each other: a calm fade, the one
    /// coming in rising a little; with Reduce Motion, a fade alone.
    private var swap: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 10))
    }
}

/// Every place keeping a time, as cards with their flags: those whose own time it is under one
/// heading, those keeping it in only part of their land under another, by where in them, each in
/// alphabetical order. The place picked is lit, and a dot on a flag marks the person's level there.
private struct SameTimePlaces: View {
    var band: TimeZoneBand
    var pickedPlaceID: String?
    var statuses: [String: VisitLevel]
    var onPick: (String) -> Void
    /// The narrowest a card can be, so names have room, growing with the text.
    @ScaledMetric(relativeTo: .subheadline) private var cardWidth = 150

    var body: some View {
        let own = band.sharers.filter(\.isOwnTime)
        let partly = band.sharers.filter { !$0.isOwnTime }
        LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 8)], spacing: 8) {
            if !own.isEmpty {
                Section {
                    ForEach(own) { card(for: $0) }
                } header: {
                    CardGridHeader(title: Text("On \(Text(utcOffset: band.offset))"), detail: Self.count(own.count))
                }
            }
            if !partly.isEmpty {
                Section {
                    ForEach(partly) { card(for: $0) }
                } header: {
                    CardGridHeader(title: Text("Partly on \(Text(utcOffset: band.offset))"), detail: Self.count(partly.count))
                }
            }
        }
    }

    private func card(for sharer: TimeZoneBand.Sharer) -> some View {
        let level = statuses[sharer.placeID] ?? .never
        return PlaceChoiceCard(
            name: sharer.name, flagAssetName: sharer.flagAssetName, tint: ZonePalette.color(forOffset: band.offset),
            levelColor: level == .never ? nil : level.color, isSelected: sharer.placeID == pickedPlaceID,
            spokenDetail: [sharer.isOwnTime ? nil : "In part", level == .never ? nil : level.name]
                .compactMap { $0 }.joined(separator: ", ")
        ) {
            onPick(sharer.placeID)
        }
        .accessibilityHint("Picks it, as tapping it on the map does.")
        .id(sharer.placeID)
    }

    /// How many places, in words: "1 place", "12 places".
    private static func count(_ number: Int) -> String {
        number == 1 ? "1 place" : "\(number) places"
    }
}

/// A zone to choose, as a card like the quiz's answers: its hours from UTC in its colour, the time
/// there with the letters the zone goes by, a day on or back marked as on a timetable, and its name
/// gliding across when too long to fit, rolling up anew as it's turned to another, all over the sky
/// as it is there. The person's own zone carries a location arrow; lit, it lights up calmly, as the
/// boards in Countries settings do, in a wash of the zone's own colour on the map inside a ring of
/// it, never in the games' candy.
private struct ZoneCard: View {
    var band: TimeZoneBand
    var date: Date
    var here: ZoneClock
    var isHere: Bool
    var isLit: Bool
    /// How high the Sun stands over the zone, in degrees, for the sky the card wears.
    var sunHeight: Double
    var onChoose: () -> Void
    var onTurn: (ZoneName) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pops = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let time = ClockWords.time(date, in: band.clock.timeZone)
        let day = ClockWords.dayShift(at: date, in: band.clock.timeZone, comparedWith: here.timeZone)
        let name = band.name(at: date)
        let letters = band.abbreviation(at: date)
        Button {
            pops += 1
            onChoose()
        } label: {
            HStack(spacing: 11) {
                OffsetBadge(offset: band.offset)
                VStack(alignment: .leading, spacing: 2) {
                    // The letters step aside where the card is too narrow for them beside the time.
                    ViewThatFits(in: .horizontal) {
                        timeRow(time: time, day: day, letters: letters)
                        timeRow(time: time, day: day, letters: nil)
                    }
                    // A new name rolls up into place, as on a departures board, within its own line,
                    // so the card never grows a line taller while the two pass.
                    ZStack(alignment: .leading) {
                        ScrollingText(trigger: pops) {
                            Text(zoneName: name, offset: band.offset)
                                .font(.caption)
                        }
                        .id(name)
                        .transition(reduceMotion ? .opacity : .push(from: .bottom))
                    }
                    .clipped()
                    .foregroundStyle(.secondary)
                }
                .clipped()
                .animation(.swap(reduceMotion: reduceMotion), value: name)
                .frame(maxWidth: .infinity, alignment: .leading)
                if isHere {
                    Image(systemName: "location.fill")
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.primary)
            .background {
                // The sky over the zone: night deep, dawn and dusk rose and gold, day blue; lit, washed
                // faintly with the zone's colour.
                let sky = WorldTimeSky.colors(at: sunHeight)
                ZStack {
                    LinearGradient(colors: [sky.top, sky.middle, sky.horizon], startPoint: .top, endPoint: .bottom)
                        .opacity(0.55)
                    shape.fill(.fill.quaternary)
                    if isLit {
                        shape.fill(litColor.opacity(0.14))
                    }
                }
                .animation(.smooth(duration: 0.6), value: (sunHeight / 3).rounded())
            }
            .clipShape(shape)
            .overlay {
                if isLit {
                    shape.strokeBorder(litColor.opacity(0.6), lineWidth: 1.5)
                } else if isHere {
                    shape.strokeBorder(.white.opacity(0.35), lineWidth: 1)
                }
            }
            .pop(on: pops)
            .contentShape(shape)
        }
        .buttonStyle(PillButtonStyle())
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .bouncy(duration: 0.4, extraBounce: 0.12), value: isLit)
        // Every name the time goes by, to lead with any of them.
        .contextMenu {
            if band.names.count > 1 {
                Picker("Name", selection: Binding(get: { band.name.id }, set: { id in
                    if let name = band.names.first(where: { $0.id == id }) { onTurn(name) }
                })) {
                    ForEach(band.names) { name in
                        Text(name.name)
                            .badge(name.keepers.map(\.label).formatted(.list(type: .and)))
                            .tag(name.id)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        .accessibilityLabel([band.utcName, letters, name].compactMap { $0 }.joined(separator: ", "))
        .accessibilityValue(
            [time.spoken, day > 0 ? "tomorrow" : day < 0 ? "yesterday" : nil, Self.spokenSky(at: sunHeight)]
                .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(isHere ? "Your time. Brings the places keeping it forward." : "Brings the places keeping this time forward.")
        .accessibilityAddTraits(isLit ? .isSelected : [])
        .accessibilityActions {
            if band.names.count > 1 {
                Button("Next name, \(band.nextName.name)") { onTurn(band.nextName) }
            }
        }
    }

    /// The time, a day on or back marked as on a timetable, and the letters the zone goes by.
    private func timeRow(time: ClockWords.Time, day: Int, letters: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            TimeLabel(time: time, digits: .zoneTime, period: .zonePeriod)
            if day != 0 {
                Text(day > 0 ? "+1" : "−1")
                    .font(.caption2.weight(.bold))
                    .baselineOffset(7)
            }
            if let letters {
                ZoneLetters(letters: letters, isLit: isLit)
                    .padding(.leading, 4)
            }
        }
        .fixedSize()
    }

    /// The zone's own colour on the map, which it lights up in.
    private var litColor: Color {
        ZonePalette.color(forOffset: band.offset)
    }

    /// The sky the card wears, said: daylight, twilight or night.
    private static func spokenSky(at height: Double) -> String {
        height > 0 ? "daylight" : height > -6 ? "twilight" : "night"
    }
}

/// A zone's hours from UTC, the number itself in the zone's own colour on the time zone map, so the
/// list reads as the map's key: +8, −5, and the zones a quarter, half or three quarters of an hour
/// off with fractions, +5½ and +5¾, the way a timetable writes them; UTC itself is ±0. Every zone's
/// number takes the same room, so the list keeps a straight edge, and it rolls over as summer time
/// moves the zone on or back.
private struct OffsetBadge: View {
    var offset: Int
    /// The room every zone's number takes, growing with the text.
    @ScaledMetric(relativeTo: .title3) private var width = 52
    @ScaledMetric(relativeTo: .title3) private var height = 32

    var body: some View {
        // The widest, such as +12¾, fits whole; were text larger still, the room grows with it.
        OffsetNumber(offset: offset, size: 21)
            .frame(minWidth: width, minHeight: height)
            .animation(.snappy, value: offset)
    }
}

extension Text {
    /// A time's offset written out from UTC, "UTC+8", the offset itself in the time's colour on the
    /// map, as `OffsetNumber` draws it, and "UTC" in the text's own, so "On UTC+8" over the places
    /// keeping it reads with the map's key. UTC itself is "UTC±0", its ±0 coloured all the same.
    init(utcOffset offset: Int) {
        let number = Text(ZoneClock.utcOffsetName(offset: offset))
            .foregroundStyle(ZonePalette.color(forOffset: offset).gradient)
        self.init("UTC\(number)")
    }

    /// A zone's name, its offset in its colour where it has no name but that, as "UTC+11".
    init(zoneName name: String, offset: Int) {
        if name == ZoneClock.utcName(offset: offset) {
            self.init(utcOffset: offset)
        } else {
            self.init(verbatim: name)
        }
    }
}

/// A time's hours from UTC, the number itself in the time's colour on the map: +8, −5, +5½, ±0.
/// Changing, as summer time moves a zone or a place leads with another of its times, the number
/// rolls over to the new one; with Reduce Motion, it fades across instead.
struct OffsetNumber: View {
    var offset: Int
    /// The size of the hours' digits; the sign and any fraction are a little smaller.
    var size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0.5) {
            Text(sign)
                .font(.system(size: size * 0.67, weight: .heavy, design: .rounded))
            Text(abs(offset) / 3600, format: .number)
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .contentTransition(reduceMotion ? .opacity : .numericText(value: Double(offset)))
            if let fraction {
                Text(fraction)
                    .font(.system(size: size * 0.67, weight: .heavy, design: .rounded))
            }
        }
        .foregroundStyle(ZonePalette.color(forOffset: offset).gradient)
        .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
        .lineLimit(1)
        .fixedSize()
        .accessibilityHidden(true)
    }

    /// Ahead, behind, or UTC itself.
    private var sign: String {
        offset > 0 ? "+" : offset < 0 ? "−" : "±"
    }

    /// A zone a quarter, half or three quarters of an hour off the hour.
    private var fraction: String? {
        switch abs(offset) % 3600 / 60 {
        case 15: "¼"
        case 30: "½"
        case 45: "¾"
        default: nil
        }
    }
}

/// The letters a zone goes by, such as JST, as a small tag beside its time.
private struct ZoneLetters: View {
    var letters: String
    var isLit: Bool

    var body: some View {
        Text(letters)
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(.white.opacity(isLit ? 0.28 : 0.16), in: .rect(cornerRadius: 5, style: .continuous))
            .fixedSize()
    }
}

extension TypeStyle {
    /// A zone's time on its card in World Time's list.
    static let zoneTime = TypeStyle(size: 17, textStyle: .callout, weight: .medium, hasTabularFigures: true)
    /// The part of the day beside a zone's time.
    static let zonePeriod = TypeStyle(size: 12, textStyle: .caption, weight: .semibold)
}
