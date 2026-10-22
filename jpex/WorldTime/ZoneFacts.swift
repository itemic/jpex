import SwiftUI

/// What's fun to know of a time beyond its hour, in a line: exactly where it's kept, down to the
/// provinces of a country spanning zones, then its zones' names in the tz database, as every
/// computer knows them, set as code. Every zone keeping the time is there, however many: a line
/// too long for the card, as Central European Summer Time's thirty-odd zones make, scrolls
/// sideways rather than wrapping or leaving any out. When the clocks change in the next
/// fortnight, a note says so beneath.
struct ZoneFacts: View {
    /// Where the time is kept, as an address: "Irkutsk Oblast and Buryatia, Russia".
    var keptIn: String? = nil
    /// Its zones in the tz database, such as Asia/Irkutsk.
    var identifiers: [String]
    var clock: ZoneClock
    /// The moment World Time shows.
    var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SidewaysLine {
                HStack(spacing: 6) {
                    if let keptIn {
                        Label(keptIn, systemImage: "mappin")
                            .labelStyle(PlaceLabelStyle())
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    ForEach(identifiers, id: \.self) { identifier in
                        Text(identifier)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.1), in: .rect(cornerRadius: 5, style: .continuous))
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
            }
            if let change {
                // Gliding across to show its end where it's too long, as in larger text.
                ScrollingText { Label(change, systemImage: "clock.arrow.2.circlepath") }
                    .font(.caption)
                    .foregroundStyle(WorldPainting.wound)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [keptIn.map { "Kept in \($0)" }, "\(identifiers.formatted(.list(type: .and))) in the tz database", change]
                .compactMap { $0 }.joined(separator: ". "))
    }

    /// The clocks' next change, when it's within the next fortnight.
    private var change: String? {
        guard let change = ZoneHistory.nextChange(in: clock.timeZone, after: date),
              change.date.timeIntervalSince(date) < 14 * 86_400
        else { return nil }
        return ClockWords.clockChange(change, in: clock.timeZone)
    }
}

/// Every time a place spanning zones keeps, in a line of chips running from the farthest behind
/// UTC to the farthest ahead, as the list of zones does: each time's hours from UTC in its colour
/// on the map, the time there, a day on or back marked as on a timetable, then the cities keeping
/// it, "Easter Island", or where two share it, "Phoenix and Los Angeles". The time the card leads
/// with is lit, calmly, in a wash of its own colour inside a ring of it, as a zone lights up in
/// the list. Tapping another leads with that one instead, as a tap on the part of the place
/// keeping it on the map does; tapping the lit one lets the place go, as a second tap there does.
/// Too many for the card, as Russia's eleven are, they scroll sideways, the lit one brought into
/// view.
struct KeptTimeChips: View {
    var times: [KeptTime]
    /// The time the card leads with, by its offset.
    var lit: Int
    /// The moment World Time shows.
    var date: Date
    var here: ZoneClock
    /// A time tapped, by the clock it's best known by.
    var onPick: (ZoneClock) -> Void

    var body: some View {
        SidewaysLine(focus: lit) {
            HStack(spacing: 6) {
                ForEach(times) { time in
                    KeptTimeChip(time: time, date: date, here: here, isLit: time.offset == lit) {
                        if let clock = time.clocks.first { onPick(clock) }
                    }
                    .id(time.offset)
                }
            }
            // Room above and below for a chip's pop, which the line would otherwise cut off.
            .padding(.vertical, 3)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Times kept")
    }
}

/// One of the times a place keeps, as a chip: its hours from UTC in its colour on the map, the
/// time there, then the cities keeping it, quieter. It springs as it's pressed and pops as it's
/// tapped; lit, it wears a faint wash of its colour inside a ring of it, never the games' candy.
private struct KeptTimeChip: View {
    var time: KeptTime
    /// The moment World Time shows.
    var date: Date
    var here: ZoneClock
    var isLit: Bool
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pops = 0

    var body: some View {
        let zone = time.clocks.first?.timeZone ?? TimeZone(secondsFromGMT: time.offset) ?? here.timeZone
        let shown = ClockWords.time(date, in: zone)
        let day = ClockWords.dayShift(at: date, in: zone, comparedWith: here.timeZone)
        let color = ZonePalette.color(forOffset: time.offset)
        Button {
            pops += 1
            action()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                OffsetNumber(offset: time.offset, size: 14)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    TimeLabel(time: shown, digits: .zoneChipTime, period: .zoneChipPeriod)
                    if day != 0 {
                        Text(day > 0 ? "+1" : "−1")
                            .font(.caption2.weight(.bold))
                            .baselineOffset(6)
                    }
                }
                // Whole, always: the line scrolls sideways rather than cutting any name short.
                Text(time.cities)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(isLit ? AnyShapeStyle(color.opacity(0.14)) : AnyShapeStyle(.fill.quaternary), in: Capsule())
            .overlay {
                Capsule().strokeBorder(isLit ? AnyShapeStyle(color.opacity(0.6)) : AnyShapeStyle(.clear), lineWidth: 1.5)
            }
            .pop(on: pops)
            .contentShape(Capsule())
        }
        .buttonStyle(PillButtonStyle())
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .bouncy(duration: 0.4, extraBounce: 0.12), value: isLit)
        .accessibilityLabel("\(ZoneClock.utcName(offset: time.offset)), \(time.cities)")
        .accessibilityValue(
            [shown.spoken, day > 0 ? "tomorrow" : day < 0 ? "yesterday" : nil].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(isLit ? "Lets go of the place." : "Leads with this time, as tapping where it's kept on the map does.")
        .accessibilityAddTraits(isLit ? .isSelected : [])
    }
}

/// One line of chips or tags, never wrapped and never cut short: still where it fits, and where
/// it's too long, scrolling sideways, fading out at whichever edge it carries on past. It reaches
/// out into the card's margins, so it scrolls from one edge of the card to the other while lining
/// up with the text above it. The item `focus` names is brought into view as it changes: straight
/// there the first time, gliding there after, and simply there with Reduce Motion on.
private struct SidewaysLine<Content: View>: View {
    /// The ID of the item to keep in view, such as the lit chip's offset.
    var focus: Int? = nil
    /// The card's margin beside the line, as its heading is set in, which the line reaches out into.
    var margin: CGFloat = 18
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var overflow = SidewaysOverflow()
    @State private var hasFocused = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                content
            }
            .contentMargins(.horizontal, margin, for: .scrollContent)
            .scrollIndicators(.hidden)
            // Still, not springing under a swipe, where it all fits.
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onScrollGeometryChange(for: SidewaysOverflow.self) { geometry in
                SidewaysOverflow(
                    before: geometry.contentOffset.x > -geometry.contentInsets.leading + 1,
                    after: geometry.contentOffset.x + geometry.containerSize.width
                        < geometry.contentSize.width + geometry.contentInsets.trailing - 1)
            } action: { _, overflow in
                withAnimation(.easeOut(duration: 0.2)) { self.overflow = overflow }
            }
            .mask {
                // A soft edge only where the line carries on out of sight.
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [.black.opacity(overflow.before ? 0 : 1), .black], startPoint: .leading, endPoint: .trailing)
                        .frame(width: margin + 4)
                    Color.black
                    LinearGradient(
                        colors: [.black, .black.opacity(overflow.after ? 0 : 1)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: margin + 12)
                }
            }
            // Out into the card's margins, after the mask, so the mask spans that room too.
            .padding(.horizontal, -margin)
            .task(id: focus) {
                guard let focus else { return }
                // Once the line is laid out.
                try? await Task.sleep(for: .milliseconds(40))
                guard !Task.isCancelled else { return }
                withAnimation(hasFocused && !reduceMotion ? .smooth(duration: 0.4) : nil) {
                    proxy.scrollTo(focus, anchor: .center)
                }
                hasFocused = true
            }
        }
    }
}

/// Whether a sideways line has more to scroll to before or after what's in view.
private struct SidewaysOverflow: Equatable {
    var before = false
    var after = false
}

/// A place's pin close beside its name.
private struct PlaceLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
                .imageScale(.small)
            configuration.title
        }
    }
}

extension TypeStyle {
    /// A time on its chip among the times a place keeps.
    static let zoneChipTime = TypeStyle(size: 15, textStyle: .subheadline, weight: .medium, hasTabularFigures: true)
    /// The part of the day beside a chip's time.
    static let zoneChipPeriod = TypeStyle(size: 11, textStyle: .caption2, weight: .semibold)
}
