import SwiftUI

/// The Atlas's key for plugs: every kind of plug in use, large and side by side, each its face on a
/// socket plate of its colour, its letter, the name it goes by and how many places take it.
/// Tapping one brings forward every place whose sockets take it, and lists them all beneath, to
/// scroll through and tap for their cards.
struct PlugGallery: View {
    var entries: [AtlasKeyEntry]
    @Binding var highlight: String?
    var localLanguage: Bool
    var onPick: (AdministrativeDivision) -> Void
    /// Whether to show the plugs as one row of small cards, each a little faceplate, its letter and
    /// its count, so the map beside or above it can be bigger.
    var isCompact: Bool = false
    /// Whether to list the brought-forward plug's places beneath, or leave that to the map, which
    /// floats the list where it has room.
    var listsPlaces: Bool = true
    /// The tallest its list of places grows before it scrolls: a few rows beneath the key, or the
    /// whole of a side of its own, as on the near side of iPhone Duo's fold, rather than a short
    /// scroller nested in a tall one.
    var listMaxHeight: CGFloat = 210
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var highlighted: AtlasKeyEntry? {
        entries.first { $0.id == highlight }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isCompact {
                AtlasKeyChipRow(
                    entries: entries, highlight: $highlight,
                    name: { "Type \($0.key.name)" },
                    spokenName: { "Type \($0.key.name), \($0.key.plug?.origin ?? "")" }
                ) { entry in
                    if let plug = entry.key.plug {
                        PlugFaceplate(type: plug)
                            .frame(width: 28, height: 28)
                            .popsWhenLit(highlight == entry.id)
                    }
                }
            } else {
                gallery
            }
            if listsPlaces, let highlighted {
                AtlasPlaceList(entry: highlighted, localLanguage: localLanguage, onPick: onPick,
                    maxHeight: listMaxHeight)
                    .transition(.atlasPlaceList(reduceMotion: reduceMotion))
            }
        }
        // The list opens, changes and folds away on the panel's curve, with the glass round it;
        // the plugs light up snappily on their own.
        .animation(MapMotion.panel(reduceMotion: reduceMotion), value: highlight)
    }

    /// Every plug large and side by side, to scroll through.
    private var gallery: some View {
        ScrollViewReader { scroller in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(entries) { entry in
                        card(entry)
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, 12)
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

    private func card(_ entry: AtlasKeyEntry) -> some View {
        let isSelected = highlight == entry.id
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return Button {
            highlight = isSelected ? nil : entry.id
        } label: {
            VStack(spacing: 4) {
                if let plug = entry.key.plug {
                    PlugFaceplate(type: plug)
                        .frame(width: 92, height: 92)
                        .popsWhenLit(isSelected)
                        .padding(.bottom, 6)
                    Text("Type \(plug.rawValue)")
                        .font(.headline)
                    ScrollingText {
                        Text(plug.origin)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("^[\(entry.count) place](inflect: true)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 124)
            .padding(.vertical, 12)
            .background(entry.key.color.opacity(isSelected ? 0.18 : 0), in: shape)
            .overlay { shape.strokeBorder(entry.key.color.opacity(isSelected ? 0.85 : 0), lineWidth: 2) }
            .opacity(highlight != nil && !isSelected ? 0.45 : 1)
            .contentShape(shape)
        }
        // A large card, so it gives only a little under the finger.
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        // Lit in place, snappily, as the key's tiles are.
        .animation(.atlasKey(reduceMotion: reduceMotion), value: highlight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Type \(entry.key.name), \(entry.key.plug?.origin ?? ""), \(entry.count) places")
        .accessibilityHint(isSelected ? "Shows every place." : "Lists the places it fits, and brings them forward.")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
