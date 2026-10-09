import Foundation
import Observation

/// The person's counting choices, kept in UserDefaults across launches.
@Observable
final class CountingPreferences {
    var rules: CountingRules {
        didSet {
            if rules != oldValue { rules.save(to: defaults) }
        }
    }

    /// Mixes the person has saved to come back to, in the order they saved them.
    var presets: [CountingPreset] {
        didSet {
            if presets != oldValue, let data = try? JSONEncoder().encode(presets) {
                defaults.set(data, forKey: Self.presetsKey)
            }
        }
    }

    private let defaults: UserDefaults
    private static let presetsKey = "countingPresets"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rules = CountingRules(defaults: defaults)
        presets = defaults.data(forKey: Self.presetsKey)
            .flatMap { try? JSONDecoder().decode([CountingPreset].self, from: $0) } ?? []
    }

    /// The saved preset the rules match exactly, if any.
    var matchingPreset: CountingPreset? {
        presets.first { $0.applied(to: rules) == rules }
    }

    /// Saves the current mix under a name.
    func savePreset(named name: String) {
        presets.append(CountingPreset(name: name, rules: rules))
    }
}

/// A mix of counting choices the person saved under a name, such as "My travel club".
/// It leaves the level counted from alone, since that's chosen separately.
struct CountingPreset: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var rules: CountingRules

    func applied(to current: CountingRules) -> CountingRules {
        var applied = rules
        applied.minimumLevelID = current.minimumLevelID
        return applied
    }
}
