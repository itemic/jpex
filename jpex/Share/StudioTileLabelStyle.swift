import SwiftUI

/// A choice beneath the share screen's card as a small tile, its symbol over its name, highlighted in
/// grey and outlined while it's chosen, as the list's level cards are. A long name widens its tile
/// rather than being cut short.
struct StudioTileLabelStyle: LabelStyle {
    var isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        VStack(spacing: 6) {
            configuration.icon
                .font(.system(size: 19, weight: .medium))
                .frame(height: 26)
            configuration.title
                .font(.caption.weight(isOn ? .semibold : .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 78, minHeight: 66)
        .fixedSize()
        .foregroundStyle(isOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
        .background(isOn ? AnyShapeStyle(.primary.opacity(0.1)) : AnyShapeStyle(.fill.quaternary), in: shape)
        .overlay {
            if isOn {
                shape.strokeBorder(.primary.opacity(0.55), lineWidth: 1.5)
            }
        }
        .contentShape(shape)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeInOut(duration: 0.18), value: isOn)
    }
}
