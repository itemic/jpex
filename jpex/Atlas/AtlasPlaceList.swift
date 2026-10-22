import SwiftUI

/// Every place a key of the Atlas applies to, such as every place whose sockets take a type G plug,
/// as cards of flags and names to scroll through, A to Z, in the quiz's language for its list of
/// every answer. Tapping one finds it on the map and opens its callout. Brought forward for another
/// entry, the same list changes its cards in place, the old ones fading as the new ones come, and
/// goes back to its top, rather than one list leaving and another arriving.
struct AtlasPlaceList: View {
    var entry: AtlasKeyEntry
    var localLanguage: Bool
    var onPick: (AdministrativeDivision) -> Void
    /// The tallest the list grows before it scrolls: a few rows beneath a key, or more when the map
    /// floats it where there's room.
    var maxHeight: CGFloat = 210
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How tall the cards stand, so a short list takes only the room it needs.
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        // One slot, so going between a level with nothing at it and one with places, the two
        // cross-fade where they stand, the glass gliding between their heights, rather than
        // standing one above the other while they trade places.
        ZStack(alignment: .top) {
            if entry.places.isEmpty {
                // A level with nothing at it yet, rather than an empty box.
                Text("None yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .transition(.opacity)
            } else {
                list
                    .transition(.opacity)
            }
        }
    }

    private var list: some View {
        ScrollViewReader { scroller in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150 * textScale), spacing: 8)], spacing: 8) {
                    ForEach(entry.places) { card($0) }
                }
                .id(Self.topID)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    // The first measure is taken at once, unanimated, so the list rises to its
                    // right size in one go rather than opening at its tallest and then shrinking.
                    // Later ones, from one entry's places to another's, glide.
                    var transaction = Transaction()
                    transaction.disablesAnimations = contentHeight == 0
                    withTransaction(transaction) { contentHeight = height }
                }
            }
            .onChange(of: entry.id) {
                scroller.scrollTo(Self.topID, anchor: .top)
            }
        }
        // The quiz's chrome for its cards: soft edges only where there's more to scroll to.
        .cardGridScrolling()
        .padding(.horizontal, 14)
        // Exactly as tall as its cards and the margins round them, up to `maxHeight`, then it
        // scrolls, its cards always from the top; a frame that only capped the height would grow
        // to the cap wherever it's offered more, leaving a few cards adrift in empty glass. The
        // height glides with the change from one entry's places to another's, on the panel's
        // curve, so the list and the glass round it move as one.
        .frame(height: min(contentHeight > 0 ? contentHeight + 16 : maxHeight, maxHeight), alignment: .top)
        .animation(MapMotion.panel(reduceMotion: reduceMotion), value: contentHeight)
        // Unseen until the cards are measured, so the list's first, provisional height never shows.
        .opacity(contentHeight > 0 ? 1 : 0)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Places with \(entry.key.spokenName)")
    }

    private static let topID = "top"

    /// A place as a card in the quiz's language: its flag and its name, which glides to show its
    /// end rather than cutting off, as Antigua and Barbuda's does.
    private func card(_ place: AdministrativeDivision) -> some View {
        let name = place.displayName(localLanguage: localLanguage)
        return PlaceChoiceCard(
            name: name, language: place.language(of: name),
            flagAssetName: UIImage(named: place.flagAssetName) == nil ? nil : place.flagAssetName,
            symbolName: "flag", tint: entry.key.color, pressedScale: PillButtonStyle.cardScale
        ) {
            onPick(place)
        }
        .accessibilityHint("Finds it on the map.")
    }
}
