import SwiftUI

/// The running total at the top of a list, counting places from the level chosen in Settings.
/// As a badge, just the count sits small in glass over a corner of the list's map instead.
struct TravelTotalView: View {
    var tally: [String: Int]
    var total: Int
    var horizontalSafeArea: EdgeInsets
    var minimumStatus: VisitLevel
    var isBadge = false
    /// The kind of places it counts, where the list can count more than one kind, such as France's
    /// regions: highlighted beside the count, ahead of the others.
    var label: String? = nil
    /// A shorter name for the kind counted on a narrow screen, such as LGAs for local government
    /// areas, as the other kinds' cards have.
    var shortLabel: String? = nil
    /// The country's map at the kind of places counted, and their levels, for the highlighted
    /// card's little picture, as the other kinds' cards have.
    var labelMap: TravelMap? = nil
    var labelStatuses: [String: VisitLevel] = [:]
    /// Where the highlighted card sits among the others, so every kind of place keeps its spot as
    /// the list switches between them, such as Regions before Departments, and only the highlight moves.
    var labelPosition = 0
    /// The other kinds it could count, such as France's departments beside its regions: small cards
    /// beside the count, each switching the list to them.
    var otherLevels: [LevelSwitch] = []
    @Environment(\.visitLadder) private var ladder
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var counted: Int {
        ladder.levels(from: minimumStatus).reduce(0) { $0 + tally[$1.id, default: 0] }
    }

    var body: some View {
        Group {
            if isBadge {
                badge
            } else {
                full
            }
        }
        .animation(Motion.count, value: counted)
    }

    /// Just the count, small in glass, so it hides as little of the map as it can.
    private var badge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(counted, format: .number)
                .typeStyle(.count)
                .contentTransition(.numericText(value: Double(counted)))
            Text("/ \(total.formatted())")
                .typeStyle(.countTotal)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .glassPanel(in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenCount)
    }

    /// Whether the count starts above the lowest level, as when Settings counts from Visited, so
    /// the header says so.
    private var countsFromAbove: Bool {
        ladder.rank(of: minimumStatus) > 1
    }

    /// What the count counts, for VoiceOver.
    private var spokenCount: String {
        countsFromAbove ? "\(counted) of \(total), counting \(minimumStatus.name) or higher" : "\(counted) of \(total)"
    }

    private var full: some View {
        // At the largest text sizes, the kinds of places counted go beneath the count.
        let wrapsLevels = dynamicTypeSize.isAccessibilitySize && (label != nil || !otherLevels.isEmpty)
        return VStack(alignment: .leading, spacing: 8) {
            // The count never shrinks: where it and the kinds of places counted don't fit on one
            // line, the kinds go beneath it instead.
            if wrapsLevels {
                countLine(withLevels: false)
                levels
            } else {
                ViewThatFits(in: .horizontal) {
                    countLine(withLevels: true)
                    VStack(alignment: .leading, spacing: 8) {
                        countLine(withLevels: false)
                        levels
                    }
                }
            }
            StatusTallyBar(tally: tally, total: total, minimumStatus: minimumStatus)
                .frame(height: 8)
        }
        // On a wide page, such as iPad's, the count and its bar keep to a readable width, centred.
        .frame(maxWidth: 1040)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.leading, horizontalSafeArea.leading)
        .padding(.trailing, horizontalSafeArea.trailing)
        .padding(.bottom, 20)
    }

    /// The big count, with the reminder of where counting starts, and, `withLevels`, the kinds of
    /// places counted beside it. Everything on the line shares its baseline: the cards' counts sit
    /// on the same line as the big one, so the cards hang from it rather than centring on it.
    private func countLine(withLevels: Bool) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(counted, format: .number)
                    .typeStyle(.heroCount)
                    .contentTransition(.numericText(value: Double(counted)))
                Text("/ \(total.formatted())")
                    .typeStyle(.heroTotal)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenCount)
            Spacer(minLength: 0)
            // Only when counting from above the lowest level: a quiet, untappable reminder of
            // where counting starts, set in Settings. It springs in from its trailing edge, or
            // with Reduce Motion, fades.
            if countsFromAbove {
                VisitPillLabel(status: minimumStatus, suffix: "+", isSmall: true)
                    .opacity(0.75)
                    .accessibilityHidden(true)
                    .transition(.arrive(reduceMotion: reduceMotion, anchor: .trailing))
            }
            if withLevels {
                levels
            }
        }
        .animation(Motion.moving(.snappy, reduceMotion: reduceMotion), value: countsFromAbove)
    }

    /// Every kind of place it could count as a small card, in a fixed order, the one counted
    /// highlighted without a colour of its own.
    @ViewBuilder private var levels: some View {
        if label != nil || !otherLevels.isEmpty {
            let position = min(max(labelPosition, 0), otherLevels.count)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                ForEach(otherLevels.prefix(position)) { level in
                    otherLevelCard(level)
                        .buttonStyle(PillButtonStyle())
                        .fixedSize()
                }
                if let label {
                    let title = horizontalSizeClass == .compact ? shortLabel ?? label : label
                    LevelCard(
                        title: title, counted: counted, total: total, map: labelMap, statuses: labelStatuses, isOn: true,
                        isCompact: true)
                        .fixedSize()
                        .accessibilityLabel(label)
                        .accessibilityAddTraits(.isHeader)
                }
                ForEach(otherLevels.dropFirst(position)) { level in
                    otherLevelCard(level)
                        .buttonStyle(PillButtonStyle())
                        .fixedSize()
                }
            }
        }
    }

    /// Another level's small card: a button that switches to it, or for one with places to choose
    /// from, such as Australia's local government areas, a menu of them. On a narrow screen it goes
    /// by its short name where it has one, leaving the count its room.
    @ViewBuilder private func otherLevelCard(_ level: LevelSwitch) -> some View {
        let shortTitle = horizontalSizeClass == .compact ? level.shortTitle : nil
        let card = LevelCard(
            title: shortTitle ?? level.title, counted: level.counted, total: level.total, map: level.map,
            statuses: level.statuses, opensMenu: !level.choices.isEmpty, isCompact: true)
        if level.choices.isEmpty {
            Button(action: level.action) { card }
                .accessibilityHint("Counts \(level.title.lowercased()) instead.")
        } else {
            Menu {
                ForEach(level.choices) { choice in
                    Button(action: choice.action) {
                        Text(choice.title)
                        Text("\(choice.counted)/\(choice.total)")
                    }
                }
            } label: {
                card
            }
            .menuStyle(.button)
            .accessibilityLabel(level.title)
            .accessibilityHint("Chooses a place to count its \(level.title.lowercased()).")
        }
    }
}
