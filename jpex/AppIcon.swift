import UIKit

/// An icon the app can wear on the Home Screen: Japan in the original sky blue or another
/// colour, another country's outline, or a Chinese or European licence plate. Made by
/// `Scripts/make_app_icons.py`.
struct AppIcon: Identifiable, Hashable, RawRepresentable {
  /// The stem the icon's assets are named with, such as `JapanRed` or `Plate-BJ`.
  var rawValue: String
  var name: String
  var collection: Collection

  enum Collection {
    /// Japan's colours, which keep the original 都道府県 artwork.
    case japan
    /// Other countries' outlines, each on its own colour.
    case otherMaps
    /// China's licence plates, each with its place's one-character short name.
    case chinesePlates
    /// The blue band of European Union plates, each with its country's code.
    case europeanPlates
  }

  var id: String { rawValue }

  init?(rawValue: String) {
    guard let icon = Self.all.first(where: { $0.rawValue == rawValue }) else { return nil }
    self = icon
  }

  private init(_ rawValue: String, name: String, collection: Collection) {
    self.rawValue = rawValue
    self.name = name
    self.collection = collection
  }

  static let storageKey = "appIcon"

  /// The original icon, the app's primary one.
  static let japan = AppIcon("Japan", name: "Sky", collection: .japan)

  static let japanColours = [
    japan,
    AppIcon("JapanRed", name: "Red", collection: .japan),
    AppIcon("JapanGreen", name: "Matcha", collection: .japan),
    AppIcon("JapanPink", name: "Sakura", collection: .japan),
    AppIcon("JapanPurple", name: "Fuji", collection: .japan),
    AppIcon("JapanNight", name: "Night", collection: .japan),
  ]

  private static let taiwan = AppIcon("Taiwan", name: "Taiwan", collection: .otherMaps)

  private static let allOtherMaps = [
    AppIcon("Korea", name: "South Korea", collection: .otherMaps),
    taiwan,
    AppIcon("UnitedStates", name: "United States", collection: .otherMaps),
    AppIcon("UnitedKingdom", name: "United Kingdom", collection: .otherMaps),
    AppIcon("France", name: "France", collection: .otherMaps),
    AppIcon("Italy", name: "Italy", collection: .otherMaps),
    AppIcon("Australia", name: "Australia", collection: .otherMaps),
  ]

  /// Other countries' outlines, leaving out any not offered in the person's region.
  static var otherMaps: [AppIcon] {
    allOtherMaps.filter { $0.isOffered(in: Locale.current.region) }
  }

  /// A plate for every place in China with a short name, in the catalog's order.
  static let chinesePlates: [AppIcon] = CountryCatalog.china.divisions.compactMap { place in
    place.shortName == nil
      ? nil : AppIcon("Plate-\(place.abbreviation)", name: place.name, collection: .chinesePlates)
  }

  /// A plate for every member of the European Union, by name.
  static let europeanPlates: [AppIcon] = europeanUnionCodes.compactMap { code in
    CountryCatalog.world.divisions.first { $0.abbreviation == code }.map { country in
      AppIcon("EUPlate-\(code)", name: country.name, collection: .europeanPlates)
    }
  }
  .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

  /// The members of the European Union, by ISO code.
  private static let europeanUnionCodes = [
    "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV",
    "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE",
  ]

  private static let all = japanColours + allOtherMaps + chinesePlates + europeanPlates

  /// Whether to offer this icon to someone whose device is set to a region. Taiwan isn't
  /// offered where the region is set to mainland China.
  func isOffered(in region: Locale.Region?) -> Bool {
    self == Self.taiwan ? region != .chinaMainland : true
  }

  var isJapan: Bool { collection == .japan }

  /// The alternate icon's name in the asset catalog; nil for the primary icon.
  var alternateIconName: String? {
    self == .japan ? nil : "AppIcon-\(rawValue)"
  }

  /// A small copy to show in the app, since an app icon set can't be loaded as an image.
  var previewImageName: String {
    "IconPreview-\(rawValue)"
  }

  /// The icon on the Home Screen right now.
  @MainActor static var current: AppIcon {
    let name = UIApplication.shared.alternateIconName
    return all.first { $0.alternateIconName == name } ?? .japan
  }

  @MainActor static var isSupported: Bool {
    UIApplication.shared.supportsAlternateIcons
  }

  /// Puts this icon on the Home Screen. The system tells the person it changed.
  @MainActor func apply() async throws {
    guard UIApplication.shared.alternateIconName != alternateIconName else { return }
    try await UIApplication.shared.setAlternateIconName(alternateIconName)
  }
}
