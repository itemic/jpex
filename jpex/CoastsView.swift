import SwiftUI

/// The seas a country has coasts on, longest coast first, in a line beneath its total: each one a
/// chip in the colour of the person's level for it, which opens it in Seas. A country with no
/// coast says it's landlocked instead, still showing any inland sea it lies on, such as the Caspian.
struct CoastsView: View {
  var seas: [AdministrativeDivision]
  var isLandlocked: Bool
  var horizontalSafeArea: EdgeInsets
  var status: (AdministrativeDivision) -> VisitLevel
  var onOpen: (AdministrativeDivision) -> Void

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 6) {
        Label(isLandlocked ? "Landlocked" : "Coasts", systemImage: isLandlocked ? "mountain.2.fill" : "water.waves")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
          .padding(.trailing, 4)
          .accessibilityAddTraits(.isHeader)
        ForEach(seas) { sea in
          let level = status(sea)
          Button {
            onOpen(sea)
          } label: {
            SeaChip(name: sea.name, level: level)
          }
          .buttonStyle(PillButtonStyle())
          .accessibilityLabel(sea.name)
          .accessibilityValue(level.name)
          .accessibilityHint("Opens it in Seas.")
        }
      }
      .padding(.horizontal)
      .padding(.leading, horizontalSafeArea.leading)
      .padding(.trailing, horizontalSafeArea.trailing)
    }
    .scrollIndicators(.hidden)
    .padding(.bottom, 16)
  }
}

/// One sea as a chip: its name beside a dot in the colour of the person's level for it, the whole
/// chip washed in that colour once they've been.
private struct SeaChip: View {
  var name: String
  var level: VisitLevel

  var body: some View {
    let isNever = level == .never
    HStack(spacing: 6) {
      Circle()
        .fill(isNever ? AnyShapeStyle(.clear) : AnyShapeStyle(level.color))
        .strokeBorder(isNever ? AnyShapeStyle(.secondary) : AnyShapeStyle(.clear), lineWidth: 1)
        .frame(width: 8, height: 8)
      Text(name)
        .font(.subheadline)
        .lineLimit(1)
    }
    .padding(.horizontal, 11)
    .padding(.vertical, 6)
    .background(isNever ? AnyShapeStyle(.fill.quaternary) : AnyShapeStyle(level.color.opacity(0.18)), in: .capsule)
    .contentShape(.capsule)
    .animation(.smooth(duration: 0.6), value: level)
  }
}
