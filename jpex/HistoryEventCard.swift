import SwiftUI

/// One change between eras, in a small glass card: the flags before and after, the year, and
/// what happened. The card in the middle of the row lights up, and its places glow on
/// the map; tapping it flies the map there.
struct HistoryEventCard: View {
    var event: HistoricalEvent
    var atlas: TimeMachineAtlas
    var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                flags
                Spacer(minLength: 4)
                Text(String(event.year))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                    .foregroundStyle(TimeScrubber.glow)
                    .fixedSize()
                    .layoutPriority(1)
            }
            Text(event.title)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassPanel(in: RoundedRectangle(cornerRadius: 20, style: .continuous), tint: isFocused ? TimeScrubber.glow : nil)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(TimeScrubber.glow.opacity(isFocused ? 0.5 : 0), lineWidth: 1)
        }
        .scaleEffect(isFocused ? 1 : 0.96)
        .animation(.smooth(duration: 0.3), value: isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.year), \(event.title)")
        .accessibilityHint("Shows where on the map.")
    }

    /// The flags before the change, an arrow, and the flags after — or the change's symbol where
    /// there are no flags to show.
    @ViewBuilder private var flags: some View {
        let before = event.from.map(atlas.polity)
        let after = event.to.map(atlas.polity)
        if before.isEmpty && after.isEmpty {
            Image(systemName: event.kind.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TimeScrubber.glow)
                .frame(height: 22)
        } else {
            HStack(spacing: 6) {
                FlagStack(polities: before)
                if !before.isEmpty && !after.isEmpty {
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                FlagStack(polities: after)
            }
        }
    }
}

/// A few flags overlapping like a fanned hand, with a count for any more.
struct FlagStack: View {
    var polities: [HistoricalPolity]
    var height: CGFloat = 22

    var body: some View {
        let shown = polities.prefix(3)
        HStack(spacing: -height * 0.5) {
            ForEach(Array(shown.enumerated()), id: \.offset) { index, polity in
                HistoricalFlag(polity: polity, height: height)
                    .zIndex(Double(shown.count - index))
            }
            if polities.count > shown.count {
                Text("+\(polities.count - shown.count)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.leading, height * 0.5 + 4)
                    .fixedSize()
            }
        }
    }
}

/// A polity's flag at a given height, or a quiet placeholder in its colour where there's no flag.
struct HistoricalFlag: View {
    var polity: HistoricalPolity
    var height: CGFloat

    var body: some View {
        Group {
            if let name = polity.flagAssetName, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(.white.opacity(0.12))
                    Image(systemName: "flag.fill")
                        .font(.system(size: height * 0.45))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: height * 1.5, height: height)
        .clipShape(.rect(cornerRadius: 3))
        .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(.white.opacity(0.25), lineWidth: 0.5) }
        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        .accessibilityLabel(polity.name)
    }
}

/// A moment in deep time, such as the asteroid, in the same kind of card as history's events.
struct DeepTimeEventCard: View {
    var event: DeepTime.Event
    var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: event.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Spacer(minLength: 4)
                Text(DeepTimeEventCard.age(event.ma))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                    .foregroundStyle(color)
            }
            Text(event.title)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassPanel(in: RoundedRectangle(cornerRadius: 20, style: .continuous), tint: isFocused ? color : nil)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(color.opacity(isFocused ? 0.5 : 0), lineWidth: 1)
        }
        .scaleEffect(isFocused ? 1 : 0.96)
        .animation(.smooth(duration: 0.3), value: isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(DeepTimeEventCard.spokenAge(event.ma)), \(event.title)")
        .accessibilityHint("Travels to this moment.")
    }

    private var color: Color {
        switch event.kind {
        case .impact: .orange
        case .extinction: Color(red: 1, green: 0.45, blue: 0.4)
        case .life: Color(red: 0.55, green: 0.9, blue: 0.55)
        case .rift, .collision: TimeScrubber.glow
        }
    }

    /// "66 Ma", or "300,000 years" for moments closer than a million years ago.
    static func age(_ ma: Double) -> String {
        if ma < 1 {
            let years = Int((ma * 1_000_000 / 1000).rounded()) * 1000
            return years == 0 ? "Now" : "\(years.formatted()) yrs"
        }
        return "\(ma.formatted(.number.precision(.fractionLength(0...1)))) Ma"
    }

    static func spokenAge(_ ma: Double) -> String {
        if ma < 1 { return "\(Int((ma * 1_000_000).rounded()).formatted()) years ago" }
        return "\(ma.formatted(.number.precision(.fractionLength(0...1)))) million years ago"
    }
}
