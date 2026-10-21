import SwiftUI

/// The Atlas's key for coasts: a tile for each ocean, its seas lit on a little map of them all,
/// then the inland seas and the landlocked, side by side to scroll through. Tapping one brings
/// forward every place with a coast on it, and lists them beneath, to tap for their cards.
struct CoastsKey: View {
    var entries: [AtlasKeyEntry]
    @Binding var highlight: String?
    var localLanguage: Bool
    var onPick: (AdministrativeDivision) -> Void
    /// Whether to show the coasts as one row of small cards, each a little map of its seas, its name
    /// and its count, so the map beside or above it can be bigger.
    var isCompact: Bool = false
    /// Whether to list the brought-forward coast's places beneath, or leave that to the map, which
    /// floats the list where it has room.
    var listsPlaces: Bool = true
    /// The tallest its list of places grows before it scrolls: a few rows beneath the key, or the
    /// whole of a side of its own, as on the near side of iPhone Duo's fold, rather than a short
    /// scroller nested in a tall one.
    var listMaxHeight: CGFloat = 210
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            if isCompact {
                AtlasKeyChipRow(entries: entries, highlight: $highlight) { entry in
                    CoastMark(entry: entry, height: 28, isLit: highlight == entry.id)
                }
            } else {
                tiles
            }
            if listsPlaces, let entry = entries.first(where: { $0.id == highlight }) {
                AtlasPlaceList(entry: entry, localLanguage: localLanguage, onPick: onPick,
                    maxHeight: listMaxHeight)
                    .transition(.atlasPlaceList(reduceMotion: reduceMotion))
            }
        }
        // The list opens, changes and folds away on the panel's curve, with the glass round it;
        // the tiles and chips light up snappily on their own.
        .animation(MapMotion.panel(reduceMotion: reduceMotion), value: highlight)
    }

    private var tiles: some View {
        ScrollViewReader { scroller in
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(entries) { entry in
                        AtlasKeyTile(
                            entry: entry, isFaded: highlight != nil && highlight != entry.id,
                            isSelected: highlight == entry.id,
                            action: { highlight = highlight == entry.id ? nil : entry.id }
                        ) {
                            CoastMark(entry: entry, height: 48, isLit: highlight == entry.id)
                        }
                        .frame(width: 150)
                        .id(entry.id)
                    }
                }
                .padding(.horizontal, 14)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .onChange(of: highlight) { _, id in
                guard let id else { return }
                withAnimation(reduceMotion ? nil : .smooth) { scroller.scrollTo(id, anchor: .center) }
            }
        }
    }
}

/// A coast's mark: the little map of an ocean's seas, or a mountain in a circle for the landlocked,
/// 48 points tall on a tile or smaller on a chip. As its entry is lit, the little map pops and the
/// mountain gives a little bounce.
private struct CoastMark: View {
    var entry: AtlasKeyEntry
    var height: CGFloat
    /// Whether its entry is brought forward, which pops the little map or bounces the mountain
    /// once as it lights.
    var isLit = false

    var body: some View {
        if let key = CoastKey(rawValue: entry.id), key != .landlocked {
            OceanPicture(ocean: key, color: entry.key.color, size: CGSize(width: height * 92 / 48, height: height))
                .popsWhenLit(isLit)
        } else {
            let side = height * 44 / 48
            Image(systemName: "mountain.2.fill")
                .font(.system(size: side * 18 / 44, weight: .semibold))
                .foregroundStyle(.white)
                .bouncesWhenLit(isLit)
                .frame(width: side, height: side)
                .background(entry.key.color.gradient, in: .circle)
                .accessibilityHidden(true)
        }
    }
}

/// The world's seas in miniature, an ocean's own lit in its colour and the rest faint: the whole
/// World for an ocean, the Pacific's turned to the middle, or around the Caspian and the Dead Sea
/// for the inland seas.
private struct OceanPicture: View {
    var ocean: CoastKey
    var color: Color
    var size = CGSize(width: 92, height: 48)

    var body: some View {
        let map = TravelMap.named(
            CountryCatalog.seas.id, projection: .standard, center: ocean == .pacific ? .pacific : .europeAfrica)
        Canvas { context, size in
            guard let map else { return }
            let seaIDs = Set(CountryCatalog.seas.divisions.filter { $0.groupID == ocean.seaGroupID }.map(\.id))
            let lit = map.regions.filter { seaIDs.contains($0.id) }
            var focus = map.focusRect(including: [])
            if ocean == .inland, let first = lit.first {
                let bounds = lit.dropFirst().reduce(first.bounds) { $0.union($1.bounds) }
                focus = bounds.insetBy(dx: -bounds.width * 1.4, dy: -bounds.height * 0.5)
            }
            let scale = min(size.width / focus.width, size.height / focus.height)
            var drawing = context
            drawing.translateBy(
                x: (size.width - focus.width * scale) / 2 - focus.minX * scale,
                y: (size.height - focus.height * scale) / 2 - focus.minY * scale)
            drawing.scaleBy(x: scale, y: scale)
            let litIDs = Set(lit.map(\.id))
            for region in map.regions {
                let isLit = litIDs.contains(region.id)
                drawing.fill(
                    region.path, with: isLit ? .color(color) : .color(.secondary.opacity(0.22)), style: FillStyle(eoFill: true))
            }
        }
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }
}
