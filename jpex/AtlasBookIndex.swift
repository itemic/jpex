import SwiftUI

/// The right-hand page of the Atlas book while the map shows another layer, such as driving side:
/// the layer's key along its head, and beneath it an index, as at the back of an atlas, every
/// entry of the key with all the places it holds, A to Z. Lighting an entry in the key turns the
/// index to it and brings it forward, the others fading back; tapping a place finds it on the map.
struct AtlasBookIndex<Key: View>: View {
    var entries: [AtlasKeyEntry]
    /// The entry lit in the key, by ID.
    var highlight: String?
    var localLanguage: Bool
    /// How far the page's contents keep in from the spine, clear of the crease of a partly folded
    /// device.
    var spineInset: CGFloat = 0
    var onPick: (AdministrativeDivision) -> Void
    /// The layer's key, as it stands on its own side of the fold.
    @ViewBuilder var key: Key
    @ScaledMetric(relativeTo: .subheadline) private var textScale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            key
                .glassPanel(in: .rect(cornerRadius: 28))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            ScrollViewReader { scroller in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22, pinnedViews: [.sectionHeaders]) {
                        ForEach(entries) { entry in
                            section(for: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
                // Lighting an entry turns the index to it.
                .onChange(of: highlight) { _, id in
                    guard let id else { return }
                    withAnimation(Motion.moving(Motion.glide, reduceMotion: reduceMotion)) {
                        scroller.scrollTo(id, anchor: .top)
                    }
                }
            }
            // Places running on past the head and foot of the index fade away there.
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 12)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 24)
                }
            }
        }
        .padding(.leading, spineInset)
        // The same paper as the Atlas's pages, fading in over the map along the spine.
        .background {
            AtlasBookPaper()
        }
        .fontDesign(.rounded)
    }

    /// An entry's heading, its colour, name and how many places it holds, pinned as its places
    /// scroll beneath it, then its places as cards, as in the key's own list.
    private func section(for entry: AtlasKeyEntry) -> some View {
        let isDimmed = highlight != nil && highlight != entry.id
        return Section {
            if entry.places.isEmpty {
                Text("None yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150 * textScale), spacing: 8)], spacing: 8) {
                    ForEach(entry.places) { place in
                        let name = place.displayName(localLanguage: localLanguage)
                        PlaceChoiceCard(
                            name: name, language: place.language(of: name),
                            flagAssetName: UIImage(named: place.flagAssetName) == nil ? nil : place.flagAssetName,
                            symbolName: "flag", tint: entry.key.color, pressedScale: PillButtonStyle.cardScale
                        ) {
                            onPick(place)
                        }
                        .accessibilityHint("Finds it on the map.")
                    }
                }
            }
        } header: {
            HStack(spacing: 10) {
                Circle()
                    .fill(entry.key.color.gradient)
                    .frame(width: 12, height: 12)
                ScrollingName(text: entry.key.name)
                    .font(.headline)
                Spacer(minLength: 8)
                Text(entry.count, format: .number)
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .background(AtlasBook.paper)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
        .opacity(isDimmed ? 0.4 : 1)
        .animation(.atlasKey(reduceMotion: reduceMotion), value: highlight)
    }
}

/// The Atlas book's paper behind a right-hand page: running on to the screen's edges, under the
/// bars, so the page is one sheet, and fading in over the map along the spine, so the map runs
/// softly on into the page.
struct AtlasBookPaper: View {
    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: AtlasBook.paper.opacity(0), location: 0),
                    .init(color: AtlasBook.paper.opacity(0.85), location: 0.6),
                    .init(color: AtlasBook.paper, location: 1),
                ],
                startPoint: .leading, endPoint: .trailing)
                .frame(width: AtlasBook.overlap)
            AtlasBook.paper
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
