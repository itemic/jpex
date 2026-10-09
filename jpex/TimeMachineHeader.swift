import SwiftUI

/// The top of Time Machine: in history, the year, large and light, counting through the years as
/// the scrubber moves, with the era's headline; in deep time, how
/// many millions of years ago, the geologic period and the great landmasses of the time. Compact,
/// on a short screen, it's one line over the map.
struct TimeMachineHeader: View {
    var model: TimeMachineModel
    var isCompact: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if model.presentedMode == .deepTime {
                DeepTimeHeading(ma: model.ma, period: model.currentPeriod, deepTime: model.atlas?.deepTime, isCompact: isCompact)
                    .transition(.opacity.combined(with: .offset(y: -8)))
            } else if let era = model.currentEra {
                HistoryHeading(year: model.displayYear, era: era, isScrubbing: model.isScrubbing,
                               pull: model.leadingPull, isCompact: isCompact)
                    .transition(.opacity.combined(with: .offset(y: -8)))
            } else {
                Text(" ")
                    .font(.system(size: isCompact ? 34 : 54, weight: .thin, design: .rounded))
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.white)
        .animation(.smooth(duration: 0.5), value: model.presentedMode)
    }
}

private struct HistoryHeading: View {
    var year: Int
    var era: HistoricalEra
    var isScrubbing: Bool
    /// How far the person has pulled past the first era, which blurs the year as history runs out.
    var pull: Double
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !isCompact {
                Text(era.isToday && !isScrubbing ? "Today" : "Time Machine")
                    .typeStyle(.eyebrow)
                    .foregroundStyle(TimeScrubber.glow)
                    .contentTransition(.opacity)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(year))
                    .font(.system(size: isCompact ? 34 : 54, weight: .thin, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(value: Double(year)))
                    .animation(.snappy(duration: 0.25), value: year)
                    .blur(radius: 6 * pull.clamped01)
                    .opacity(1 - 0.5 * pull.clamped01)
                if isCompact {
                    Text(era.title)
                        .font(.headline)
                        .lineLimit(1)
                        .id(era.id)
                        .transition(.opacity)
                }
            }
            if !isCompact {
                Text(era.title)
                    .font(.title3.weight(.semibold))
                    .id(era.id)
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.3), value: era.id)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(era.isToday ? "Today, \(era.title)" : "\(era.year), \(era.title)")
        .accessibilityAddTraits(.isHeader)
    }
}

private struct DeepTimeHeading: View {
    var ma: Double
    var period: DeepTime.Period?
    var deepTime: DeepTime?
    var isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !isCompact {
                Text("Deep time")
                    .typeStyle(.eyebrow)
                    .foregroundStyle(Color(red: 1, green: 0.75, blue: 0.4))
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(ma < 0.5 ? "Now" : String(Int(ma.rounded())))
                    .font(.system(size: isCompact ? 34 : 54, weight: .thin, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(value: ma))
                    .animation(.snappy(duration: 0.25), value: Int(ma.rounded()))
                if ma >= 0.5 {
                    Text("million years ago")
                        .font(isCompact ? .headline.weight(.light) : .title3.weight(.light))
                        .foregroundStyle(.secondary)
                }
                if isCompact, let period {
                    PeriodChip(period: period)
                }
            }
            if !isCompact {
                HStack(spacing: 8) {
                    if let period {
                        PeriodChip(period: period)
                    }
                    Text(landmasses)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }
        }
        .animation(.smooth(duration: 0.3), value: period?.id)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ma < 0.5 ? "Deep time, now" : "Deep time, \(DeepTimeEventCard.spokenAge(ma))")
        .accessibilityValue([period?.name, landmasses].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "))
        .accessibilityAddTraits(.isHeader)
    }

    /// The supercontinents and oceans of the moment, such as "Pangaea · Tethys Ocean".
    private var landmasses: String {
        guard let deepTime else { return "" }
        var names: [String] = []
        for label in deepTime.labels where label.isGrand && deepTime.presence(of: label, at: ma) > 0.5 && !names.contains(label.name) {
            names.append(label.name)
        }
        return names.joined(separator: " · ")
    }
}

/// A geologic period's name on a capsule in its chart colour.
private struct PeriodChip: View {
    var period: DeepTime.Period

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(period.color).frame(width: 9, height: 9)
            Text(period.name)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .glassPanel(in: Capsule(), tint: period.color)
        .fixedSize()
        .id(period.id)
        .transition(.opacity)
    }
}
