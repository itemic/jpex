import SwiftUI

/// Something the Atlas knows about a place, such as what lies on the far side of the Earth from
/// it, as one line in the style of Learn's codes: a small coloured symbol, a short label and its
/// value. The full map's callout lists them this way.
struct MapFactRow: View {
    var fact: MapFact

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: fact.symbolName)
                .font(.caption.weight(.medium))
                .foregroundStyle(fact.tint)
            Text(fact.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize()
            // On one line, gliding to show the rest where it's long, never wrapping.
            ScrollingText {
                Text(fact.value)
                    .font(.subheadline)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fact.spoken)
    }
}
