import SwiftUI

/// The Atlas's key for driving side: a tile each for keeping left and keeping right, each with a
/// stretch of road and a car in the lane you'd drive in. Tapping one lists every place that drives
/// that way beneath, to scroll through and tap for their cards.
struct DrivingSideKey: View {
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
                    RoadPicture(
                        keepsLeft: entry.id == DrivingSide.left.rawValue, color: entry.key.color, height: 28,
                        isLit: highlight == entry.id)
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
        HStack(alignment: .top, spacing: 10) {
            ForEach(entries) { entry in
                AtlasKeyTile(
                    entry: entry, isFaded: highlight != nil && highlight != entry.id, isSelected: highlight == entry.id,
                    action: { highlight = highlight == entry.id ? nil : entry.id }
                ) {
                    RoadPicture(
                        keepsLeft: entry.id == DrivingSide.left.rawValue, color: entry.key.color,
                        isLit: highlight == entry.id)
                }
            }
        }
        .padding(.horizontal, 14)
    }
}

/// Two lanes of road seen from above, a car in the lane you'd drive in and the oncoming way marked
/// faintly in the other. Drawn 48 points tall on a tile, or smaller on the key's compact chips, the
/// road keeping its proportions. The car gives a little bounce as its entry is lit.
private struct RoadPicture: View {
    var keepsLeft: Bool
    var color: Color
    var height: CGFloat = 48
    /// Whether its entry is brought forward, which bounces the car once as it lights.
    var isLit = false

    /// How much smaller than the tile's road this one is.
    private var scale: CGFloat { height / 48 }

    var body: some View {
        let width = 76 * scale
        HStack(spacing: 0) {
            lane(isYours: keepsLeft)
            lane(isYours: !keepsLeft)
        }
        .frame(width: width, height: height)
        .background(Color(white: 0.3), in: .rect(cornerRadius: 10 * scale, style: .continuous))
        .overlay {
            // The line down the middle.
            Path { path in
                path.move(to: CGPoint(x: width / 2, y: 4 * scale))
                path.addLine(to: CGPoint(x: width / 2, y: height - 4 * scale))
            }
            .stroke(
                .white.opacity(0.85),
                style: StrokeStyle(lineWidth: max(1, 1.5 * scale), lineCap: .round, dash: [5 * scale, 4 * scale]))
        }
        .accessibilityHidden(true)
    }

    private func lane(isYours: Bool) -> some View {
        Group {
            if isYours {
                Image(systemName: "car.rear.fill")
                    .font(.system(size: 20 * scale, weight: .semibold))
                    .foregroundStyle(color.gradient)
                    .bouncesWhenLit(isLit)
            } else {
                Image(systemName: "arrow.down")
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
