import SwiftUI

/// A squishy press for pills: it gives under your finger and springs back, or with Reduce Motion,
/// eases there and back without the spring.
///
/// Round icon buttons give the full squish. Large cards, tiles and pills on the map and in the
/// Atlas give only a little, `cardScale`, so calm glass stays calm and the candy is left to the games.
struct PillButtonStyle: ButtonStyle {
    /// How small the label gets while it's held: 0.88 by default, a round button's full squish.
    var pressedScale: CGFloat = 0.88
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The gentler give of a large card, tile or pill on the map or in the Atlas.
    static let cardScale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(Motion.moving(Motion.press, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}
