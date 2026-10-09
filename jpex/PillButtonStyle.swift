import SwiftUI

/// A squishy press for pills: it gives under your finger and springs back.
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.15), value: configuration.isPressed)
    }
}
