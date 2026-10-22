import SwiftUI

/// A place's one-character short name set as on a mainland Chinese licence plate: white on the
/// plates' blue, inside a fine white rim. Grey, like the flags, for places not yet been to.
struct LicencePlateBadge: View {
  var shortName: String
  var size: CGFloat
  var isDimmed = false

  /// The blue of China's standard car plates.
  static let plateBlue = Color(red: 0.06, green: 0.27, blue: 0.72)

  var body: some View {
    let corner = size * 0.2
    Text(verbatim: shortName)
      .placeName(PlaceTypesetting.language(forCode: "CN"))
      .font(.system(size: size * 0.62, weight: .semibold))
      .foregroundStyle(.white)
      .frame(width: size, height: size)
      .background {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
          .fill(Self.plateBlue.gradient)
          .overlay {
            RoundedRectangle(cornerRadius: corner * 0.7, style: .continuous)
              .strokeBorder(.white.opacity(0.9), lineWidth: max(1, size * 0.045))
              .padding(size * 0.08)
          }
      }
      .grayscale(isDimmed ? 1 : 0)
      .opacity(isDimmed ? 0.55 : 1)
      .accessibilityHidden(true)
  }
}
