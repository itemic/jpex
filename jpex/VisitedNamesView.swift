import SwiftUI

/// Every place with a level, set as type: the better you know a place, the larger its name,
/// each in its level's colour. Names drift in one after another, and a tap finds the place on the map.
struct VisitedNamesView: View {
    var places: [AdministrativeDivision]
    var statuses: [String: VisitLevel]
    var localLanguage: Bool
    var onSelect: (AdministrativeDivision) -> Void
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var largestSize = 34
    @State private var hasAppeared = false

    var body: some View {
        let named = rankedPlaces
        Group {
            if named.isEmpty {
                Text("Tap a place on the map to give it a level.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FlowLayout(spacing: 12, lineSpacing: 2) {
                    ForEach(Array(named.enumerated()), id: \.element.place.id) { index, item in
                        nameButton(for: item.place, level: item.level)
                            .opacity(hasAppeared ? 1 : 0)
                            .blur(radius: hasAppeared || reduceMotion ? 0 : 6)
                            .offset(y: hasAppeared || reduceMotion ? 0 : 14)
                            .animation(
                                .smooth(duration: 0.55).delay(reduceMotion ? 0 : min(Double(index) * 0.035, 0.9)),
                                value: hasAppeared)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.smooth, value: named.map(\.level.id))
            }
        }
        .onAppear { hasAppeared = true }
    }

    private func nameButton(for place: AdministrativeDivision, level: VisitLevel) -> some View {
        let emphasis = Double(ladder.rank(of: level)) / Double(max(ladder.levels.count, 1))
        let name = place.displayName(localLanguage: localLanguage)
        let language = place.language(of: name)
        return Button {
            onSelect(place)
        } label: {
            Text(name)
                .placeName(language, kerning: -0.4)
                .font(.system(
                    size: largestSize * (0.5 + 0.5 * emphasis),
                    weight: PlaceTypesetting.weight(emphasis > 0.75 ? .regular : .light, for: language)))
                .foregroundStyle(level.color.gradient)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(NameButtonStyle())
        .accessibilityLabel("\(place.name), \(level.name)")
        .accessibilityHint("Shows it on the map.")
    }

    /// Places with a level, best known first, then alphabetically.
    private var rankedPlaces: [(place: AdministrativeDivision, level: VisitLevel)] {
        places
            .compactMap { place in
                guard let level = statuses[place.id], ladder.rank(of: level) > 0 else { return nil }
                return (place, level)
            }
            .sorted { first, second in
                let firstRank = ladder.rank(of: first.level)
                let secondRank = ladder.rank(of: second.level)
                guard firstRank == secondRank else { return firstRank > secondRank }
                return first.place.name.localizedStandardCompare(second.place.name) == .orderedAscending
            }
    }
}

/// Names dip and fade a little while pressed.
private struct NameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}
