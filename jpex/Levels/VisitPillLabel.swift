import SwiftUI

/// The glossy status capsule used throughout the app. Its name rolls up when a place rises a
/// level and down when it falls, and each level's colour carries its own simple texture.
struct VisitPillLabel: View {
    var status: VisitLevel
    var suffix = ""
    var isLit = true
    var fillsWidth = false
    /// Smaller type and a tighter fit, for extra compact rows.
    var isSmall = false
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @AppStorage(LevelPattern.storageKey) private var showsPatterns = true

    private var isPatterned: Bool { showsPatterns || differentiateWithoutColor }

    var body: some View {
        Text(status.name.uppercased() + suffix)
            .foregroundStyle(isLit ? AnyShapeStyle(litText) : AnyShapeStyle(.secondary))
            .font((isSmall ? Font.footnote : .subheadline).weight(.semibold))
            .kerning(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .contentTransition(.numericText(value: Double(ladder.rank(of: status))))
            .padding(isSmall ? 3 : 4)
            .padding(.horizontal, isSmall ? 3 : 4)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .background {
                if isLit {
                    gloss
                } else {
                    ZStack {
                        if isPatterned {
                            pattern(color: status.color.opacity(differentiateWithoutColor ? 0.55 : 0.35))
                        }
                        Capsule().strokeBorder(status.color.opacity(0.7), lineWidth: 1.5)
                    }
                }
            }
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isLit ? 0.2 : 0), radius: 1, x: 0, y: 1)
            .animation(.snappy, value: status)
            .animation(.snappy, value: isLit)
    }

    @ViewBuilder
    private func pattern(color: Color) -> some View {
        if let style = ladder.patternStyle(of: status) {
            LevelPattern(style: style, color: color, cell: 8, symbol: status.symbolName)
                .id(style)
                .transition(.opacity)
        }
    }

    private var litText: some ShapeStyle {
        .white.gradient
            .shadow(.inner(color: .white.opacity(0.1), radius: 1, x: 0, y: 1))
            .shadow(.drop(radius: 0.5, x: 0, y: 1))
            .shadow(.drop(color: .black.opacity(0.1), radius: 10, x: 0, y: -1))
            .shadow(.drop(color: status.color, radius: 2, x: 0, y: -1))
    }

    private var gloss: some View {
        ZStack {
            status.color
            if isPatterned {
                pattern(color: .white.opacity(differentiateWithoutColor ? 0.42 : 0.24))
            }
            Color.white
                .mask(LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
            status.color.brightness(0.2).saturation(2)
                .mask(LinearGradient(colors: [.black.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
            status.color.brightness(-0.2)
                .mask(LinearGradient(colors: [.clear, .black.opacity(0.3)], startPoint: .top, endPoint: .bottom))
        }
    }
}
