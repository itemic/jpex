#if os(visionOS)
import SwiftUI

/// What a map out in the room has beneath it: its list's name and how many of its places count,
/// on glass, so they read against whatever's behind them.
struct SpatialMapLabel: View {
    var title: String
    var counted: Int
    var total: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text("\(counted) / \(total)")
                .font(.title3)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .glassBackgroundEffect(in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(counted) of \(total)")
    }
}
#endif
