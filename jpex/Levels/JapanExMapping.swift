import Foundation

/// Which of JapanEx's six levels each of the person's levels shows as, once their levels differ
/// from the original five. A level without a choice is matched automatically.
struct JapanExMapping: Equatable, Sendable, RawRepresentable {
  /// The person's choices, by their level's ID.
  var choices: [String: JapanExLevel] = [:]

  static let storageKey = "japanExMapping"

  init() {}

  init?(rawValue: String) {
    guard let scores = try? JSONDecoder().decode([String: Int].self, from: Data(rawValue.utf8)) else { return nil }
    choices = scores.compactMapValues(JapanExLevel.init(rawValue:))
  }

  var rawValue: String {
    let data = try? JSONEncoder().encode(choices.mapValues(\.score))
    return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
  }

  /// The JapanEx level a level shows as. Never been is always never, and while the person uses
  /// the original five levels each keeps its own; otherwise it's their choice, or a match.
  func japanExLevel(for level: VisitLevel, in ladder: VisitLadder) -> JapanExLevel {
    if level.id == VisitLevel.never.id { return .never }
    if JapanEx.usesOriginalLevels(ladder) { return JapanExLevel(originalLevelID: level.id) ?? .never }
    return choices[level.id] ?? Self.automatic(for: level, in: ladder)
  }

  /// Whether any of the ladder's levels has a chosen JapanEx level, rather than a match.
  func hasChoices(in ladder: VisitLadder) -> Bool {
    ladder.levels.contains { choices[$0.id] != nil }
  }

  /// The match for a level with no choice: an original level keeps its own JapanEx level, and
  /// one the person added is placed by how far up their ladder it is.
  static func automatic(for level: VisitLevel, in ladder: VisitLadder) -> JapanExLevel {
    if let original = JapanExLevel(originalLevelID: level.id) { return original }
    let rank = ladder.rank(of: level)
    guard rank > 0, !ladder.levels.isEmpty else { return .never }
    let spread = (Double(rank) * 5 / Double(ladder.levels.count)).rounded()
    return JapanExLevel(rawValue: min(5, max(1, Int(spread)))) ?? .passed
  }
}
