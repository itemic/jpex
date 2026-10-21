import SwiftUI

/// One colour of the Atlas's key as a tile: a small picture of what it means, its name and how
/// many places have it. Tapping it brings those places forward on the map and lists them, and the
/// other tiles fade back; tapping it again shows them all.
struct AtlasKeyTile<Picture: View>: View {
    var entry: AtlasKeyEntry
    /// Whether another tile is brought forward instead of this one.
    var isFaded: Bool
    var isSelected: Bool
    var action: () -> Void
    @ViewBuilder var picture: Picture
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                picture
                    .frame(height: 48, alignment: .leading)
                VStack(alignment: .leading, spacing: 1) {
                    ScrollingText {
                        Text(entry.key.name)
                            .font(.headline)
                    }
                    Text("^[\(entry.count) place](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(entry.key.color.opacity(isSelected ? 0.2 : 0.07), in: shape)
            .overlay {
                shape.strokeBorder(entry.key.color.opacity(isSelected ? 0.85 : 0.2), lineWidth: isSelected ? 2 : 1)
            }
            .opacity(isFaded ? 0.45 : 1)
            .contentShape(shape)
        }
        // A tile is a large card, so it gives only a little under the finger.
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .animation(.atlasKey(reduceMotion: reduceMotion), value: isSelected)
        .animation(.atlasKey(reduceMotion: reduceMotion), value: isFaded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(entry.key.spokenName), ^[\(entry.count) place](inflect: true)"))
        .accessibilityHint(isSelected ? "Shows every place." : "Lists these places, and brings them forward on the map.")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A key's entries in its compact form, for when the map needs the room: one row of small cards in
/// the quiz's language that scrolls sideways, each its little picture, its name and, quietly beside
/// it, how many places have it. Tapping one brings it forward, ringed calmly in its colour while the
/// others fade back, and the row glides to keep it in view; tapping it again shows them all.
struct AtlasKeyChipRow<Mark: View>: View {
    var entries: [AtlasKeyEntry]
    @Binding var highlight: String?
    /// What a chip says, such as "Type G" or "Left".
    var name: (AtlasKeyEntry) -> String = { $0.key.name }
    /// What VoiceOver says for a chip, before its count.
    var spokenName: (AtlasKeyEntry) -> String = { $0.key.spokenName }
    /// The entry's picture, drawn to fit a 28-point square or a little wider.
    @ViewBuilder var mark: (AtlasKeyEntry) -> Mark
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether there are chips to scroll to before or after the ones in view.
    @State private var hidden = (before: false, after: false)

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(entries) { entry in
                        chip(entry)
                            .id(entry.id)
                    }
                }
                // A count rolls to its new value as a place joins or leaves its entry, as when a
                // level is set from a callout, its chip and the chips after it gliding to their
                // new widths with it.
                .animation(Motion.count, value: entries.map(\.count))
                .padding(.horizontal, 14)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .onScrollGeometryChange(for: [Bool].self) { geometry in
                let after = geometry.contentSize.width - geometry.contentOffset.x - geometry.containerSize.width
                return [geometry.contentOffset.x > 1, after > 1]
            } action: { _, edges in
                hidden = (edges[0], edges[1])
            }
            // Chips that run on past either end fade away there, rather than being cut through.
            .mask {
                HStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(hidden.before ? 0 : 1), .black], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 22)
                    Color.black
                    LinearGradient(colors: [.black, .black.opacity(hidden.after ? 0 : 1)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 30)
                }
            }
            .onChange(of: highlight) { _, id in
                guard let id else { return }
                withAnimation(reduceMotion ? nil : .smooth) { scroller.scrollTo(id, anchor: .center) }
            }
        }
        .animation(.atlasKey(reduceMotion: reduceMotion), value: highlight)
    }

    private func chip(_ entry: AtlasKeyEntry) -> some View {
        let isSelected = highlight == entry.id
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Button {
            highlight = isSelected ? nil : entry.id
        } label: {
            HStack(spacing: 8) {
                mark(entry)
                    .frame(minWidth: 28, minHeight: 28)
                Text(name(entry))
                    .font(.callout)
                    .fixedSize()
                Text(entry.count.formatted())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(entry.count)))
                    .fixedSize()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    shape.fill(entry.key.color.opacity(0.14))
                } else {
                    shape.fill(.quaternary)
                }
            }
            .overlay { shape.strokeBorder(entry.key.color.opacity(isSelected ? 0.6 : 0), lineWidth: 1.5) }
            .opacity(highlight != nil && !isSelected ? 0.45 : 1)
            .contentShape(shape)
        }
        .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(spokenName(entry)), ^[\(entry.count) place](inflect: true)"))
        .accessibilityHint(isSelected ? "Shows every place." : "Lists these places, and brings them forward on the map.")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension Animation {
    /// How a key of the Atlas moves as an entry is brought forward: a snappy spring, or a short
    /// cross-fade when Reduce Motion is on. On the full map this is kept for lighting an entry in
    /// place; anything that changes the panel's shape moves on `MapMotion.panel(reduceMotion:)`.
    static func atlasKey(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .snappy
    }
}

/// How the full map and the Atlas move, as one vocabulary, so that a panel, its glass and the room
/// the map makes for it all travel on the same curve, and Reduce Motion is honoured the same way
/// throughout: the camera cuts, and everything else falls back to a short fade.
///
/// It's calm glass here; the candy belongs to the games. A spring answers anything a person did.
/// What the map draws for itself, such as colours sweeping across the World or an outline tracing
/// round a place, keeps to the map's own clock instead (see `MapTiming`), so it never cuts short a
/// camera gliding at the same time.
enum MapMotion {
    /// What motion falls back to with Reduce Motion: a short, even fade, or a short ease where
    /// there's nothing to fade.
    static let fade = Animation.easeInOut(duration: 0.2)

    /// A panel changing shape or place: one panel giving way to the next on its glass, the glass
    /// reshaping round it, a key's list opening or folding away, a key put away to its tab, the
    /// Atlas's row coming and going, and a panel moving to its side as the screen turns.
    static func panel(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : .smooth(duration: 0.45)
    }

    /// The map gliding into the room a panel leaves it, on the panel's own curve, with the camera
    /// in step so the place in the middle rides along with the middle of the clear area, and the
    /// callout and compass along with the map. It holds with Reduce Motion: gliding in step is
    /// less motion than the map jumping and everything on it catching up.
    static let room = Animation.smooth(duration: 0.45)

    /// A small control answering a touch where it is, such as the scrubber's bubble rising over
    /// its knob, or a callout settling once it's been measured.
    static func control(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : .snappy(duration: 0.3)
    }

    /// A callout arriving at its place, growing out of its point with a little bounce, the same
    /// beside a list's row as on the map.
    static func arrive(reduceMotion: Bool) -> Animation {
        reduceMotion ? fade : LevelTapback.opening
    }

    /// A callout going: quickly, so one swapped for another, as the map flies from one place to
    /// the next, never lingers half-faded beside the new one.
    static func leave(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .smooth(duration: 0.2)
    }

    /// The camera's own moves, which cut with Reduce Motion rather than glide.
    static func camera(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    /// The camera gliding to a place picked, searched for or shown in the Atlas.
    static let glide = Animation.smooth(duration: 0.8)

    /// The map growing out of its card to fill the screen, or with Reduce Motion fading in where
    /// it will stand, at its full size from the start.
    static func grow(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: 0.55, extraBounce: 0.06)
    }

    /// The map shrinking back into its card, or with Reduce Motion fading away where it stands.
    static func shrink(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .smooth(duration: 0.5)
    }
}

extension View {
    /// Bounces the SF Symbol in a key entry's picture once as the entry is lit, a small payoff
    /// for the tap, as the layer's own symbol bounces as its key appears. Only lighting bounces,
    /// not letting go, and nothing bounces with Reduce Motion.
    func bouncesWhenLit(_ isLit: Bool) -> some View {
        modifier(LitBounce(isLit: isLit))
    }
}

/// Counts each time a key entry is lit, for its picture's symbol to bounce once.
private struct LitBounce: ViewModifier {
    var isLit: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lightings = 0

    func body(content: Content) -> some View {
        content
            .symbolEffect(.bounce, value: lightings)
            .onChange(of: isLit) { _, isLit in
                if isLit, !reduceMotion { lightings += 1 }
            }
    }
}

extension View {
    /// Pops a key entry's picture once as the entry is lit, for pictures with no symbol to bounce:
    /// a level's swatch, a plug's faceplate, an ocean's little map. Only lighting pops, not letting
    /// go, and nothing pops with Reduce Motion.
    func popsWhenLit(_ isLit: Bool) -> some View {
        modifier(LitPop(isLit: isLit))
    }
}

/// Counts each time a key entry is lit, for its picture to pop once.
private struct LitPop: ViewModifier {
    var isLit: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lightings = 0

    func body(content: Content) -> some View {
        content
            .pop(on: lightings)
            .onChange(of: isLit) { _, isLit in
                if isLit, !reduceMotion { lightings += 1 }
            }
    }
}

extension AnyTransition {
    /// How the list of a key entry's places comes and goes: rising from beneath, or only fading
    /// when Reduce Motion is on.
    static func atlasPlaceList(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom))
    }
}
