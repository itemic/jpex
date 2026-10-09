import SwiftUI

/// Never been and every level as pills, lowest to highest, in an even grid. The chosen one lights up.
struct StatusLadder: View {
    @Binding var selection: VisitLevel
    @Environment(\.visitLadder) private var ladder
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pops: [String: Int] = [:]

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(ladder.allLevels) { status in
                Button {
                    pops[status.id, default: 0] += 1
                    selection = status
                } label: {
                    VisitPillLabel(status: status, isLit: status.id == selection.id, fillsWidth: true)
                        .pop(on: pops[status.id, default: 0])
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PillButtonStyle())
                .accessibilityLabel(status.name)
                .accessibilityAddTraits(status.id == selection.id ? .isSelected : [])
            }
        }
        .frame(maxWidth: 420)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Visit status")
    }
}
