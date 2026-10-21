import SwiftUI

/// A place to choose from a list of all, as a card in the quiz's own language for its list of every
/// answer: a soft rounded card with the place's flag at the front, or a symbol in its colour, and
/// its name in a light hand, gliding across to show the rest when it's too long to fit, never cut
/// short. It springs as it's pressed and pops as it's tapped. Chosen, it lights up calmly, as the
/// boards in Countries settings do, in a faint wash of its colour inside a ring of it, never in
/// the games' candy. Where the person has been, a dot in their level's colour sits on the flag's
/// corner, as in the group editor.
///
/// Shared by any list of places to pick from outside the games, such as World Time's places
/// keeping one time; lay several out in a `FadingCardGrid`.
struct PlaceChoiceCard: View {
    /// The name on the card: a place's own, or an address such as "Kansai, Japan".
    var name: String
    /// The language the name is in, for typesetting a local name in its own script.
    var language: Locale.Language? = nil
    var flagAssetName: String? = nil
    /// A symbol at the front in place of a flag, drawn in `tint`.
    var symbolName: String? = nil
    /// The colour the card lights up in when chosen, and its symbol's.
    var tint: Color = .accentColor
    /// The person's level there, as a dot on the flag's corner; nil where they haven't been.
    var levelColor: Color? = nil
    var isSelected = false
    /// More for VoiceOver to say after the name, such as the person's level there.
    var spokenDetail: String? = nil
    /// What a tap does, for VoiceOver, such as "Puts it in the group."
    var spokenHint: String? = nil
    /// How long the card waits before lighting up or going out, so many chosen at once, as by
    /// the group editor's All, light up one after another.
    var selectionDelay: Double = 0
    /// Whether a chosen card carries a tick at its end, in its colour, as in the group editor.
    var showsCheckmark = false
    /// How far the card gives under the finger: a pill's full squish by default, or on the map and
    /// in the Atlas, where it's calm glass, only a little (`PillButtonStyle.cardScale`).
    var pressedScale: CGFloat = 0.88
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pops = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        Button {
            pops += 1
            action()
        } label: {
            HStack(spacing: 10) {
                mark
                // Whole when it fits; a long name glides to its end now and then, never cut short.
                ScrollingText(trigger: pops) {
                    Text(name)
                        .placeName(language)
                }
                .font(.callout.weight(PlaceTypesetting.weight(.light, for: language)))
                .frame(maxWidth: .infinity, alignment: .leading)
                if showsCheckmark && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(tint)
                        // It comes and goes on the card's own timing, so in a cascade it waits its
                        // turn too.
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AnyShapeStyle(tint.opacity(0.14)) : AnyShapeStyle(.fill.quaternary), in: shape)
            .overlay {
                shape.strokeBorder(isSelected ? AnyShapeStyle(tint.opacity(0.6)) : AnyShapeStyle(.clear), lineWidth: 1.5)
            }
            .pop(on: pops)
            .contentShape(shape)
        }
        .buttonStyle(PillButtonStyle(pressedScale: pressedScale))
        .sensoryFeedback(.selection, trigger: pops)
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.2)
                : .bouncy(duration: 0.4, extraBounce: 0.12).delay(selectionDelay),
            value: isSelected)
        .accessibilityLabel(name)
        .accessibilityValue(spokenDetail ?? "")
        .accessibilityHint(spokenHint ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The flag, whole at its own proportions in a box of its own, with the level's dot on its
    /// corner; or the symbol in its colour, in the same room so names line up down the grid,
    /// bouncing as the card is chosen.
    @ViewBuilder
    private var mark: some View {
        if let flagAssetName {
            Image(flagAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 22)
                .overlay(alignment: .bottomTrailing) {
                    if let levelColor {
                        Circle()
                            .fill(levelColor)
                            .frame(width: 9, height: 9)
                            .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                            .offset(x: 4, y: 3)
                    }
                }
                .accessibilityHidden(true)
        } else if let symbolName {
            Image(systemName: symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .bouncesWhenLit(isSelected)
                .frame(width: 30, height: 22)
                .accessibilityHidden(true)
        }
    }
}
