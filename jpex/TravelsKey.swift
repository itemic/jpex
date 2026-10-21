import SwiftUI

/// The key to the person's own travels on the full map, a layer like any other: a chip for each
/// level, its colour, its name and how many places are at it. Tapping one brings those places
/// forward on the map and lists them by name, such as every country lived in, to scroll through
/// and tap to find.
struct TravelsKey: View {
    /// A level each, with the places at it.
    var entries: [AtlasKeyEntry]
    @Binding var highlight: String?
    var localLanguage: Bool
    var onPick: (AdministrativeDivision) -> Void
    /// Whether to list the brought-forward level's places beneath, or leave that to the map, which
    /// floats the list where it has room.
    var listsPlaces: Bool = true
    /// The tallest its list of places grows before it scrolls: a few rows beneath the key, or the
    /// whole of a side of its own, as on the near side of iPhone Duo's fold, rather than a short
    /// scroller nested in a tall one.
    var listMaxHeight: CGFloat = 210
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            AtlasKeyChipRow(entries: entries, highlight: $highlight) { entry in
                LevelSwatch(color: entry.key.color)
                    .popsWhenLit(highlight == entry.id)
            }
            if listsPlaces, let entry = entries.first(where: { $0.id == highlight }) {
                AtlasPlaceList(entry: entry, localLanguage: localLanguage, onPick: onPick,
                    maxHeight: listMaxHeight)
                    .transition(.atlasPlaceList(reduceMotion: reduceMotion))
            }
        }
        // The list opens, changes and folds away on the panel's curve, with the glass round it;
        // the chips light up snappily on their own.
        .animation(MapMotion.panel(reduceMotion: reduceMotion), value: highlight)
    }

    /// A level for each of the ladder's levels, with the places listed at it, A to Z.
    static func entries(
        ladder: VisitLadder, places: [AdministrativeDivision], statuses: [String: VisitLevel], localLanguage: Bool
    ) -> [AtlasKeyEntry] {
        let named = places
            .map { (place: $0, name: $0.displayName(localLanguage: localLanguage)) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map(\.place)
        return ladder.levels.map { (level: VisitLevel) -> AtlasKeyEntry in
            let at: [AdministrativeDivision] = named.filter { statuses[$0.id]?.id == level.id }
            let key = MapKey(id: level.id, name: level.name, color: level.color, spokenName: level.name)
            return AtlasKeyEntry(key: key, places: at)
        }
    }
}

/// A small tile of a level's colour, lit from above as the level pills are, which pops as its
/// level is lit.
private struct LevelSwatch: View {
    var color: Color

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        shape
            .fill(color.gradient)
            .overlay {
                shape.fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center))
            }
            .frame(width: 20, height: 14)
            .accessibilityHidden(true)
    }
}
