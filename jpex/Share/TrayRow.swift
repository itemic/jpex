import SwiftUI

/// A row of choices beneath the share screen's card: centred where they fit across the screen, and
/// otherwise scrolling sideways, running out to the screen's edges. Its choices are made once, so
/// controls that keep their own state, such as a colour picker, work as anywhere else.
struct TrayRow<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content
    /// The row's width, which its choices are centred across where they're narrower.
    @State private var width: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) { content }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
                .frame(minWidth: width)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .scrollClipDisabled()
        .padding(.horizontal, -20)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}
