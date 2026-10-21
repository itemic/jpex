import SwiftUI

/// The Atlas's key for voltage: a tile each for about 110 volts, about 230, and places with both.
/// Tapping one lists every place with it beneath, to scroll through and tap for their cards.
struct VoltageKey: View {
    var entries: [AtlasKeyEntry]
    @Binding var highlight: String?
    var localLanguage: Bool
    var onPick: (AdministrativeDivision) -> Void
    /// Whether to show the entries as one row of small cards, each a little picture, its name and
    /// its count, so the map beside or above it can be bigger.
    var isCompact: Bool = false
    /// Whether to list the brought-forward entry's places beneath, or leave that to the map, which
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
                    VoltageMark(entry: entry, side: 28, isLit: highlight == entry.id)
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
        HStack(alignment: .top, spacing: 8) {
            ForEach(entries) { entry in
                AtlasKeyTile(
                    entry: entry, isFaded: highlight != nil && highlight != entry.id, isSelected: highlight == entry.id,
                    action: { highlight = highlight == entry.id ? nil : entry.id }
                ) {
                    VoltageMark(entry: entry, side: 44, isLit: highlight == entry.id)
                }
            }
        }
        .padding(.horizontal, 14)
    }
}

/// A voltage's mark: a bolt in a circle of its colour, two bolts' worth for places with both. The
/// bolt gives a little bounce as its entry is lit.
private struct VoltageMark: View {
    var entry: AtlasKeyEntry
    var side: CGFloat
    /// Whether its entry is brought forward, which bounces the bolt once as it lights.
    var isLit = false

    var body: some View {
        Image(systemName: entry.id == MainsVoltage.both.rawValue ? "bolt.horizontal.fill" : "bolt.fill")
            .font(.system(size: side * 20 / 44, weight: .semibold))
            .foregroundStyle(.white)
            .bouncesWhenLit(isLit)
            .frame(width: side, height: side)
            .background(entry.key.color.gradient, in: .circle)
            .accessibilityHidden(true)
    }
}
