import SwiftUI

/// A glossy candy button like the level pills, in any shape: white lettering on a bright colour,
/// a soft glow of the colour beneath it, and a squishy press. Unlit, only its outline and texture
/// remain, for options and for answers that weren't the one.
struct CandyButtonStyle<S: InsettableShape>: ButtonStyle {
    var color: Color
    var pattern: LevelPatternStyle?
    var shape: S
    var isLit = true

    func makeBody(configuration: Configuration) -> some View {
        CandyButton(
            label: configuration.label, isPressed: configuration.isPressed, color: color, pattern: pattern,
            shape: shape, isLit: isLit)
    }
}

extension CandyButtonStyle where S == Capsule {
    init(color: Color, pattern: LevelPatternStyle? = nil, isLit: Bool = true) {
        self.init(color: color, pattern: pattern, shape: Capsule(), isLit: isLit)
    }
}

private struct CandyButton<Label: View, S: InsettableShape>: View {
    var label: Label
    var isPressed: Bool
    var color: Color
    var pattern: LevelPatternStyle?
    var shape: S
    var isLit: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @AppStorage(LevelPattern.storageKey) private var showsPatterns = true

    var body: some View {
        label
            .foregroundStyle(isLit ? AnyShapeStyle(CandyGloss.lettering(on: color)) : AnyShapeStyle(.secondary))
            .background {
                if isLit {
                    CandyGloss(color: color, pattern: pattern)
                } else {
                    ZStack {
                        if showsPatterns || differentiateWithoutColor, let pattern {
                            LevelPattern(style: pattern, color: color.opacity(differentiateWithoutColor ? 0.55 : 0.3), cell: 6)
                        }
                        shape.strokeBorder(color.opacity(0.7), lineWidth: 1.5)
                    }
                }
            }
            .clipShape(shape)
            .contentShape(shape)
            .shadow(color: color.opacity(isLit ? 0.35 : 0), radius: isPressed ? 2 : 8, y: isPressed ? 1 : 4)
            .scaleEffect(isPressed ? 0.93 : 1)
            .opacity(isEnabled ? 1 : 0.35)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.15), value: isPressed)
            .animation(.snappy, value: isLit)
            .animation(.snappy, value: isEnabled)
    }
}
