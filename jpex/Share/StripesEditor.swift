import SwiftUI

/// The striped design's stripes, as Deco sets them: each stripe's colour, a stripe added or taken
/// away, and the stripes' angle and width. It rises only part way, so the card stays in view above
/// it, changing as the stripes do.
struct StripesEditor: View {
    /// The stripes' colours, as they're kept.
    @Binding var colors: String
    @Binding var angle: Double
    @Binding var width: Double
    @Environment(\.dismiss) private var dismiss

    private var stripes: [Color] { ShareStripes.decode(colors) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Colours") {
                    HStack(spacing: 8) {
                        ForEach(stripes.indices, id: \.self) { index in
                            ColorPicker("Stripe \(index + 1)", selection: stripe(index), supportsOpacity: false)
                                .labelsHidden()
                        }
                        Spacer(minLength: 0)
                        Button("Remove a stripe", systemImage: "minus") {
                            colors = ShareStripes.encode(stripes.dropLast())
                        }
                        .disabled(stripes.count <= ShareStripes.fewest)
                        Button("Add a stripe", systemImage: "plus") {
                            var colors = stripes
                            // A lighter shade of the last, ready to recolour.
                            colors.append((colors.last ?? .gray).mix(with: .white, by: 0.35))
                            self.colors = ShareStripes.encode(colors)
                        }
                        .disabled(stripes.count >= ShareStripes.most)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                }
                Section {
                    LabeledContent {
                        Text("\(Int(angle.rounded()))°")
                            .monospacedDigit()
                    } label: {
                        Text("Angle")
                    }
                    Slider(value: $angle, in: ShareStripes.angles) {
                        Text("Angle")
                    }
                    Slider(value: $width, in: ShareStripes.widths) {
                        Text("Width")
                    } minimumValueLabel: {
                        Text("Thin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("Wide")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Stripes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(360), .medium])
        // The card above stays live, so the stripes can be watched as they change.
        .presentationBackgroundInteraction(.enabled(upThrough: .height(360)))
    }

    /// One stripe's colour, read from and written back to the colours kept.
    private func stripe(_ index: Int) -> Binding<Color> {
        Binding {
            stripes.indices.contains(index) ? stripes[index] : .gray
        } set: { color in
            var colors = stripes
            guard colors.indices.contains(index) else { return }
            colors[index] = color
            self.colors = ShareStripes.encode(colors)
        }
    }
}
