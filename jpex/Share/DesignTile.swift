import SwiftUI

/// One of the card's designs beneath the share screen's card: a small copy of the card in it, over
/// its name, outlined while it's chosen.
struct DesignTile: View {
    var name: String
    var swatch: Image?
    var isOn: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        VStack(spacing: 7) {
            Group {
                if let swatch {
                    swatch
                        .resizable()
                        .scaledToFit()
                } else {
                    shape.fill(.fill.tertiary)
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(shape)
            .overlay { shape.strokeBorder(.primary.opacity(0.1), lineWidth: 0.5) }
            .padding(3)
            .overlay {
                if isOn {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(.primary.opacity(0.6), lineWidth: 1.5)
                }
            }
            Text(name)
                .font(.caption.weight(isOn ? .semibold : .medium))
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(isOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
        }
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.18), value: isOn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
