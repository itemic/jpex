import Foundation

/// JapanEx's six levels, scored from 0 for never been to 5 for lived. They're this app's
/// original levels, whose names and symbols they share.
enum JapanExLevel: Int, CaseIterable, Identifiable, Sendable {
  case never, passed, alighted, visited, stayed, lived

  var id: Self { self }

  /// The digit JapanEx reads for a prefecture at this level.
  var score: Int { rawValue }

  /// The original level with this score.
  var originalLevel: VisitLevel {
    self == .never ? .never : VisitLadder.standard.levels[rawValue - 1]
  }

  var name: String { originalLevel.name }

  /// The JapanEx level matching one of the original levels, by its ID, or nil for a level the
  /// person added.
  init?(originalLevelID id: String) {
    if id == VisitLevel.never.id {
      self = .never
    } else if let index = VisitLadder.standard.levels.firstIndex(where: { $0.id == id }) {
      self.init(rawValue: index + 1)
    } else {
      return nil
    }
  }
}
