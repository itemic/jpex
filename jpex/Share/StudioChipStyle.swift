import SwiftUI

/// A finer choice above a tool's tiles, such as the names' type, as a small capsule, highlighted in
/// grey and outlined while it's chosen.
struct StudioChipStyle: ButtonStyle {
    var isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(isOn ? .semibold : .medium))
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .foregroundStyle(isOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .background(isOn ? AnyShapeStyle(.primary.opacity(0.1)) : AnyShapeStyle(.fill.quaternary), in: Capsule())
            .overlay {
                if isOn {
                    Capsule().strokeBorder(.primary.opacity(0.55), lineWidth: 1.5)
                }
            }
            .contentShape(Capsule())
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? PillButtonStyle.cardScale : 1)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.18), value: isOn)
            .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
