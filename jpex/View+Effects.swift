import SwiftUI

extension View {
    /// Liquid Glass where available, optionally tinted with a level's colour and responding to
    /// touch, falling back to a material with its own soft shadow on earlier systems.
    func glassPanel(in shape: some Shape, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GlassPanel(shape: shape, tint: tint, interactive: interactive))
    }
}

private struct GlassPanel<S: Shape>: ViewModifier {
    var shape: S
    var tint: Color?
    var interactive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(tint?.opacity(0.16)).interactive(interactive), in: shape)
        } else {
            content.background {
                shape
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
            }
        }
    }
}

extension ShapeStyle where Self == Color {
    /// The soft gray behind the lists and their maps, the same as the map's sea, so a map never
    /// looks cut out of a white page.
    static var pageBackground: Color { Color(uiColor: .systemGray6) }
}
