import Foundation
import Observation

/// The person's counting choices, kept in UserDefaults across launches.
@Observable
final class CountingPreferences {
    var rules: CountingRules {
        didSet {
            if rules != oldValue {
                rules.save(to: defaults)
                if let data = try? JSONEncoder().encode(rules) { cloud?.upload(data, for: Self.rulesKey) }
            }
        }
    }

    /// Mixes the person has saved to come back to, in the order they saved them.
    var presets: [CountingPreset] {
        didSet {
            if presets != oldValue, let data = try? JSONEncoder().encode(presets) {
                defaults.set(data, forKey: Self.presetsKey)
                cloud?.upload(data, for: Self.presetsKey)
            }
        }
    }

    /// Where the choices and presets go to reach the person's other devices.
    @ObservationIgnored private var cloud: CloudKeyValueMirror?

    private let defaults: UserDefaults
    private static let presetsKey = "countingPresets"
    /// The rules as one value in iCloud; on this device each choice keeps a key of its own.
    private static let rulesKey = "countingRules"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rules = CountingRules(defaults: defaults)
        presets = defaults.data(forKey: Self.presetsKey)
            .flatMap { try? JSONDecoder().decode([CountingPreset].self, from: $0) } ?? []
    }

    /// Keeps counting the same on all the person's devices through iCloud: a change made on another
    /// device replaces this one's. When iCloud's reach this device for the first time, its
    /// choices are taken as they are, so totals agree everywhere, and its presets join these.
    func mirror(through cloud: CloudKeyValueMirror) {
        self.cloud = cloud
        cloud.mirror(Self.rulesKey) { [weak self] in
            self.flatMap { try? JSONEncoder().encode($0.rules) }
        } receive: { [weak self] data, _ in
            guard let rules = try? JSONDecoder().decode(CountingRules.self, from: data) else { return }
            self?.rules = rules
        }
        cloud.mirror(Self.presetsKey) { [weak self] in
            guard let self, defaults.data(forKey: Self.presetsKey) != nil else { return nil }
            return try? JSONEncoder().encode(presets)
        } receive: { [weak self] data, arrival in
            self?.receivePresets(data, arrival)
        }
    }

    private func receivePresets(_ data: Data, _ arrival: CloudKeyValueMirror.Arrival) {
        guard let theirs = try? JSONDecoder().decode([CountingPreset].self, from: data) else { return }
        switch arrival {
        case .replacing:
            presets = theirs
        case .joining:
            let mine = Set(presets.map(\.id))
            presets += theirs.filter { !mine.contains($0.id) }
        }
    }

    /// The saved preset the rules match exactly, if any.
    var matchingPreset: CountingPreset? {
        presets.first { $0.applied(to: rules) == rules }
    }

    /// Saves the current mix under a name.
    func savePreset(named name: String) {
        presets.append(CountingPreset(name: name, rules: rules))
    }

    /// Back to counting as the app first did, with no presets saved.
    func reset() {
        rules = CountingRules()
        presets = []
    }
}

/// A mix of counting choices the person saved under a name, such as "My travel club".
/// It leaves the level counted from alone, since that's chosen separately, and the names of
/// seas, which count nothing.
struct CountingPreset: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var rules: CountingRules

    func applied(to current: CountingRules) -> CountingRules {
        var applied = rules
        applied.minimumLevelID = current.minimumLevelID
        applied.seaNames = current.seaNames
        return applied
    }
}
