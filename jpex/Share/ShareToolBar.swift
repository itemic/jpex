import SwiftUI

/// The share screen's tools along a glass bar, as a photo editor's: each a symbol over its name, the
/// chosen one lit by a lens that slides across to it. Shuffle stands beside the bar on glass of its
/// own, as it changes the whole card at once rather than bringing up choices.
struct ShareToolBar: View {
    @Binding var selection: ShareTool
    /// Turns the card over to a design picked at random.
    var shuffle: () -> Void
    @Namespace private var lens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(ShareTool.allCases) { tool in
                    let isOn = tool == selection
                    Button {
                        withAnimation(Motion.moving(.snappy(duration: 0.3), reduceMotion: reduceMotion)) { selection = tool }
                    } label: {
                        item(tool.name, symbolName: tool.symbolName)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(isOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                            .background {
                                if isOn {
                                    Capsule()
                                        .fill(.primary.opacity(0.1))
                                        .matchedGeometryEffect(id: "lens", in: lens)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(PillButtonStyle(pressedScale: PillButtonStyle.cardScale))
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            .padding(4)
            .glassPanel(in: Capsule())
            Button(action: shuffle) {
                item("Shuffle", symbolName: "shuffle")
                    .padding(.horizontal, 4)
                    .foregroundStyle(.primary)
                    .contentShape(Capsule())
            }
            .buttonStyle(PillButtonStyle())
            .padding(4)
            .glassPanel(in: Capsule())
            .accessibilityHint("Turns the card over to a design picked at random.")
        }
    }

    /// A tool's symbol over its name.
    private func item(_ name: String, symbolName: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbolName)
                .font(.system(size: 17, weight: .medium))
                .frame(height: 22)
            ScrollingText {
                Text(name)
                    .font(.caption2.weight(.semibold))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 7)
    }
}
