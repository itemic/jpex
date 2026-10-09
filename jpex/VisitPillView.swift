import SwiftUI

/// Tap to climb to the next level. Touch and hold the row for every level.
struct VisitPillView: View {
    @Binding var status: VisitLevel
    var placeName: String
    /// Smaller, for extra compact rows, though still comfortably big enough to tap.
    var isSmall = false
    @Environment(\.visitLadder) private var ladder

    var body: some View {
        let next = ladder.next(after: status)
        Button {
            status = next
        } label: {
            VisitPillLabel(status: status, isSmall: isSmall)
                .pop(on: status.id)
                .frame(minHeight: isSmall ? 34 : 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel("Visit status for \(placeName)")
        .accessibilityValue(status.name)
        .accessibilityHint("Changes to \(next.name).")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if let higher = ladder.higher(than: status) { status = higher }
            case .decrement: if let lower = ladder.lower(than: status) { status = lower }
            @unknown default: break
            }
        }
    }
}
