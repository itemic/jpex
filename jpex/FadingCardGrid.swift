import SwiftUI

/// A scrolling grid of cards in the quiz's language for its list of every answer: as many columns
/// as fit at `minimumWidth` each, growing with the text, two across a phone and more on a wider
/// screen, 8 points apart. It fades out at its top or foot only where there's more to scroll to,
/// and reaches out into its holder's margins so a card's pop and glow are never cut off at the
/// sides. Its cards are built lazily, so it holds hundreds of places without a pause.
///
/// Group cards under a `CardGridHeader` in `Section`s. Wrap it in a `ScrollViewReader` to bring a
/// card into view by its ID. For other content to scroll with the cards, give any vertical
/// `ScrollView` the same chrome with `cardGridScrolling(bottomInset:)`.
struct FadingCardGrid<Content: View>: View {
    /// The narrowest a card can be at the standard text size, so names have room.
    var minimumWidth: CGFloat = 150
    /// Room beneath the last card, as for the home indicator where the grid runs to the screen's foot.
    var bottomInset: CGFloat = 0
    @ViewBuilder var content: Content
    /// How much larger the person's text is than standard, for the cards to grow with it.
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth * textScale), spacing: 8)], spacing: 8) {
                content
            }
        }
        .cardGridScrolling(bottomInset: bottomInset)
    }
}

/// A heading over a group of cards in a grid: its name in bold, then a count or a word more beside
/// it in grey, as the group editor heads each continent.
struct CardGridHeader: View {
    private var title: Text
    var detail: String?

    init(title: String, detail: String? = nil) {
        self.init(title: Text(title), detail: detail)
    }

    /// A heading already set as text, part of it in a colour of its own, such as World Time's
    /// "On UTC+8" with the offset in its zone's colour on the map.
    init(title: Text, detail: String? = nil) {
        self.title = title
        self.detail = detail
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            ScrollingText { title }
                .font(.headline)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .fixedSize()
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 14)
        .padding(.bottom, 2)
    }
}

extension View {
    /// The card grids' scrolling chrome for a vertical `ScrollView`: a little room above and below
    /// the cards, `bottomInset` more at the foot; out into the holder's margins at the sides, so a
    /// card's pop and glow aren't cut off; no scroll bars, no bounce when it all fits; and a soft
    /// edge at the top or foot only where there's more to scroll to.
    func cardGridScrolling(bottomInset: CGFloat = 0) -> some View {
        modifier(CardGridScrolling(bottomInset: bottomInset))
    }
}

/// The card grids' scrolling chrome, keeping track of which edges have more beyond them.
private struct CardGridScrolling: ViewModifier {
    var bottomInset: CGFloat
    @State private var edges = CardGridEdges()

    func body(content: Content) -> some View {
        content
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins(.bottom, 8 + bottomInset, for: .scrollContent)
            // Room either side for a card's glow and its pop, which the scroll view would cut off.
            .contentMargins(.horizontal, 12, for: .scrollContent)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: CardGridEdges.self) { geometry in
                CardGridEdges(
                    hasMoreAbove: geometry.contentOffset.y > -geometry.contentInsets.top + 1,
                    hasMoreBelow: geometry.contentOffset.y + geometry.containerSize.height
                        < geometry.contentSize.height + geometry.contentInsets.bottom - 1)
            } action: { _, edges in
                withAnimation(.easeOut(duration: 0.2)) { self.edges = edges }
            }
            .mask {
                // A soft edge only where the cards carry on out of sight.
                VStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(edges.hasMoreAbove ? 0 : 1), .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 22)
                    Color.black
                    LinearGradient(colors: [.black, .black.opacity(edges.hasMoreBelow ? 0 : 1)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 30 + bottomInset * 0.5)
                }
            }
            // Out into the holder's own margins, after the mask, so the mask spans that room too.
            .padding(.horizontal, -12)
    }
}

/// Whether a grid has more to scroll to above and below what's in view.
private struct CardGridEdges: Equatable {
    var hasMoreAbove = false
    var hasMoreBelow = false
}
