import SwiftUI

/// The level pills' glossy fill, for anything sweet: a bright colour with a shine across its top,
/// a saturated lift beneath the shine and a darker foot, over a simple texture when level patterns
/// are on.
struct CandyGloss: View {
    var color: Color
    var pattern: LevelPatternStyle?
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @AppStorage(LevelPattern.storageKey) private var showsPatterns = true

    var body: some View {
        ZStack {
            color
            if showsPatterns || differentiateWithoutColor, let pattern {
                LevelPattern(style: pattern, color: .white.opacity(differentiateWithoutColor ? 0.42 : 0.24), cell: 6)
                    .id(pattern)
                    .transition(.opacity)
            }
            Color.white
                .mask(LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
            color.brightness(0.2).saturation(2)
                .mask(LinearGradient(colors: [.black.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
            color.brightness(-0.2)
                .mask(LinearGradient(colors: [.clear, .black.opacity(0.3)], startPoint: .top, endPoint: .bottom))
        }
    }

    /// White lettering that sits on the gloss like the pills' names: lit from above, with a faint
    /// glow of the colour around it.
    static func lettering(on color: Color) -> some ShapeStyle {
        .white.gradient
            .shadow(.inner(color: .white.opacity(0.1), radius: 1, x: 0, y: 1))
            .shadow(.drop(radius: 0.5, x: 0, y: 1))
            .shadow(.drop(color: .black.opacity(0.1), radius: 10, x: 0, y: -1))
            .shadow(.drop(color: color, radius: 2, x: 0, y: -1))
    }
}
