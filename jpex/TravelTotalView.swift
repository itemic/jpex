import SwiftUI

/// The running total at the top of a list, with the level that counts as having been there.
/// As a badge, just the count sits small in glass over a corner of the list's map instead.
struct TravelTotalView: View {
    var tally: [String: Int]
    var total: Int
    var horizontalSafeArea: EdgeInsets
    @Binding var minimumStatus: VisitLevel
    var isBadge = false
    @Environment(\.visitLadder) private var ladder
    /// Counts choices made from this menu, so its tick plays only for them, not for changes made
    /// elsewhere, such as in Settings.
    @State private var picks = 0

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
        .animation(.snappy, value: counted)
        .sensoryFeedback(.selection, trigger: picks)
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
        .accessibilityLabel("\(counted) of \(total)")
    }

    private var countFrom: some View {
        Menu {
            Picker("Count from", selection: Binding(
                get: { minimumStatus },
                set: { level in
                    guard level.id != minimumStatus.id else { return }
                    minimumStatus = level
                    picks += 1
                })
            ) {
                ForEach(ladder.levels) { status in
                    Label(status.name, systemImage: status.symbolName).tag(status)
                }
            }
        } label: {
            VisitPillLabel(status: minimumStatus, suffix: "+")
                .pop(on: minimumStatus.id)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Count from")
        .accessibilityValue(minimumStatus.name)
    }

    private var full: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(counted, format: .number)
                        .typeStyle(.heroCount)
                        .contentTransition(.numericText(value: Double(counted)))
                    Text("/ \(total.formatted())")
                        .typeStyle(.heroTotal)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(counted) of \(total)")
                Spacer(minLength: 0)
                countFrom
            }
            StatusTallyBar(tally: tally, total: total, minimumStatus: minimumStatus)
                .frame(height: 8)
        }
        .padding(.horizontal)
        .padding(.leading, horizontalSafeArea.leading)
        .padding(.trailing, horizontalSafeArea.trailing)
        .padding(.bottom, 20)
    }
}
