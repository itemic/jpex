import Foundation

/// What the totals count: the lowest level that counts as having been somewhere,
/// and which places the Countries collection treats as separate countries.
struct CountingRules: Equatable, Sendable {
    /// Kept by ID, so it follows the level through renames and reordering.
    var minimumLevelID = "passed"
    var includesSpecialRegions = true
    var includesTaiwan = true
    var splitsUnitedKingdom = false
    var includesTerritories = true
    var includesRemotePlaces = false
    var includesObservers = true
    var includesPartlyRecognised = true
    var includesAssociatedStates = true
    /// States recognised by no UN member but the one that backs them, such as Northern Cyprus.
    /// Off unless chosen, so places such as Cyprus stay whole.
    var includesDeFactoStates = false
    /// Places switched off one by one, by ISO code, within groups that are otherwise counted,
    /// such as a single territory the person doesn't count.
    var excludedPlaces: Set<String> = []
    /// The continent chosen for each country whose main territory spans two, by ISO code,
    /// such as "asia" for Russia. Countries not listed keep their usual continent.
    var continentChoices: [String: String] = [:]

    /// The level counting starts from, or the lowest level if that one has been removed.
    func minimumLevel(in ladder: VisitLadder) -> VisitLevel {
        ladder.levels.first { $0.id == minimumLevelID } ?? ladder.levels.first ?? .never
    }

    func counts(_ level: VisitLevel, in ladder: VisitLadder) -> Bool {
        let rank = ladder.rank(of: level)
        return rank > 0 && rank >= ladder.rank(of: minimumLevel(in: ladder))
    }
}

extension CountingRules {
    private enum Key {
        static let minimumLevel = "countFromStatus"
        static let specialRegions = "countsHongKongAndMacao"
        static let taiwan = "countsTaiwan"
        static let unitedKingdomNations = "countsUKNations"
        static let territories = "countsTerritories"
        static let remotePlaces = "countsRemotePlaces"
        static let observers = "countsUNObservers"
        static let partlyRecognised = "countsPartlyRecognised"
        static let associatedStates = "countsAssociatedStates"
        static let deFactoStates = "countsDeFactoStates"
        static let continentChoices = "continentChoices"
        static let excludedPlaces = "excludedWorldPlaces"
    }

    init(defaults: UserDefaults) {
        self.init()
        if let id = defaults.string(forKey: Key.minimumLevel), id != VisitLevel.never.id {
            minimumLevelID = id
        }
        includesSpecialRegions = defaults.object(forKey: Key.specialRegions) as? Bool ?? includesSpecialRegions
        includesTaiwan = defaults.object(forKey: Key.taiwan) as? Bool ?? includesTaiwan
        splitsUnitedKingdom = defaults.object(forKey: Key.unitedKingdomNations) as? Bool ?? splitsUnitedKingdom
        includesTerritories = defaults.object(forKey: Key.territories) as? Bool ?? includesTerritories
        includesRemotePlaces = defaults.object(forKey: Key.remotePlaces) as? Bool ?? includesRemotePlaces
        continentChoices = defaults.dictionary(forKey: Key.continentChoices) as? [String: String] ?? continentChoices
        excludedPlaces = Set(defaults.stringArray(forKey: Key.excludedPlaces) ?? [])
        includesObservers = defaults.object(forKey: Key.observers) as? Bool ?? includesObservers
        // Western Sahara, the Cook Islands and Niue used to count with territories, so until
        // their own groups are set they follow whatever territories were set to.
        includesPartlyRecognised = defaults.object(forKey: Key.partlyRecognised) as? Bool ?? includesPartlyRecognised
        includesAssociatedStates = defaults.object(forKey: Key.associatedStates) as? Bool ?? includesTerritories
        if defaults.object(forKey: Key.partlyRecognised) == nil, !includesTerritories {
            excludedPlaces.insert("EH")
        }
        includesDeFactoStates = defaults.object(forKey: Key.deFactoStates) as? Bool ?? countsEverywhereElse
    }

    func save(to defaults: UserDefaults) {
        defaults.set(minimumLevelID, forKey: Key.minimumLevel)
        defaults.set(includesSpecialRegions, forKey: Key.specialRegions)
        defaults.set(includesTaiwan, forKey: Key.taiwan)
        defaults.set(splitsUnitedKingdom, forKey: Key.unitedKingdomNations)
        defaults.set(includesTerritories, forKey: Key.territories)
        defaults.set(includesRemotePlaces, forKey: Key.remotePlaces)
        defaults.set(continentChoices, forKey: Key.continentChoices)
        defaults.set(excludedPlaces.sorted(), forKey: Key.excludedPlaces)
        defaults.set(includesObservers, forKey: Key.observers)
        defaults.set(includesPartlyRecognised, forKey: Key.partlyRecognised)
        defaults.set(includesAssociatedStates, forKey: Key.associatedStates)
        defaults.set(includesDeFactoStates, forKey: Key.deFactoStates)
    }

    /// Whether every other group counts in full. Rules saved before de facto states had a group
    /// of their own count them only then, so rules that counted everywhere still do.
    private var countsEverywhereElse: Bool {
        OptionalPlaceGroup.allCases.allSatisfy { $0 == .deFactoStates || includes($0) }
            && excludedPlaces.isEmpty && !splitsUnitedKingdom
    }
}

extension CountingRules {
    /// Whether a group is switched on. Places in it can still be switched off one by one.
    func includes(_ group: OptionalPlaceGroup) -> Bool {
        switch group {
        case .specialRegions: includesSpecialRegions
        case .taiwan: includesTaiwan
        case .territories: includesTerritories
        case .remotePlaces: includesRemotePlaces
        case .observers: includesObservers
        case .partlyRecognised: includesPartlyRecognised
        case .associatedStates: includesAssociatedStates
        case .deFactoStates: includesDeFactoStates
        }
    }

    /// Switches a whole group on or off, forgetting any places switched off one by one in it.
    mutating func setIncludes(_ group: OptionalPlaceGroup, _ isIncluded: Bool) {
        switch group {
        case .specialRegions: includesSpecialRegions = isIncluded
        case .taiwan: includesTaiwan = isIncluded
        case .territories: includesTerritories = isIncluded
        case .remotePlaces: includesRemotePlaces = isIncluded
        case .observers: includesObservers = isIncluded
        case .partlyRecognised: includesPartlyRecognised = isIncluded
        case .associatedStates: includesAssociatedStates = isIncluded
        case .deFactoStates: includesDeFactoStates = isIncluded
        }
        excludedPlaces.subtract(CountryCatalog.places(in: group).map(\.abbreviation))
    }

    /// Counts or stops counting one place. Counting a place in a group that's off switches the
    /// group on with only that place; switching off the last place in a group switches it off.
    mutating func setIncludes(code: String, _ isIncluded: Bool) {
        guard let group = CountryCatalog.optionalPlaceGroup(code: code) else { return }
        let codes = CountryCatalog.places(in: group).map(\.abbreviation)
        if isIncluded {
            if !includes(group) {
                setIncludes(group, true)
                excludedPlaces.formUnion(codes)
            }
            excludedPlaces.remove(code)
        } else {
            excludedPlaces.insert(code)
            if codes.allSatisfy(excludedPlaces.contains) { setIncludes(group, false) }
        }
    }

    /// How many of a group's places count.
    func includedCount(in group: OptionalPlaceGroup) -> Int {
        CountryCatalog.places(in: group).count { includesWorldPlace(code: $0.abbreviation) }
    }
}

/// Places that some travellers count as countries and others don't.
enum OptionalPlaceGroup: String, CaseIterable, Identifiable, Sendable {
    case observers, partlyRecognised, taiwan, associatedStates, deFactoStates, specialRegions, territories
    case remotePlaces

    var id: Self { self }
}

extension CountingRules {
    /// The standard these rules match exactly, or nil when they've been tuned by hand.
    var standard: CountingStandard? {
        CountingStandard.allCases.first { $0.applied(to: self) == self }
    }
}

/// Well-known ways of deciding what counts as a country, each a starting point to tune from.
enum CountingStandard: String, CaseIterable, Identifiable, Sendable {
    /// The 193 member states of the United Nations.
    case unMembers
    /// UN members plus its two observer states, the Holy See and Palestine.
    case unObservers
    /// Every state that governs itself, recognised by all or only some: UN members, observers,
    /// Kosovo, Taiwan, Western Sahara, the Cook Islands and Niue.
    case sovereignStates
    /// Every place in the list: territories, remote islands and de facto states such as Northern
    /// Cyprus included.
    case everywhere

    var id: Self { self }

    var name: String {
        switch self {
        case .unMembers: "UN members"
        case .unObservers: "UN & observers"
        case .sovereignStates: "Sovereign states"
        case .everywhere: "Everywhere"
        }
    }

    var detail: String {
        switch self {
        case .unMembers: "Member states of the United Nations"
        case .unObservers: "Plus Vatican City and Palestine"
        case .sovereignStates: "Plus Kosovo, Taiwan and other self-governing states"
        case .everywhere: "Every territory and remote island too"
        }
    }

    var symbolName: String {
        switch self {
        case .unMembers: "building.columns.fill"
        case .unObservers: "eye.fill"
        case .sovereignStates: "flag.2.crossed.fill"
        case .everywhere: "globe.desk.fill"
        }
    }

    /// The rules with this standard's choices, keeping the level counted from and the continents.
    func applied(to rules: CountingRules) -> CountingRules {
        var rules = rules
        let groups: Set<OptionalPlaceGroup> = switch self {
        case .unMembers: []
        case .unObservers: [.observers]
        case .sovereignStates: [.observers, .partlyRecognised, .taiwan, .associatedStates]
        case .everywhere: Set(OptionalPlaceGroup.allCases)
        }
        for group in OptionalPlaceGroup.allCases {
            rules.setIncludes(group, groups.contains(group))
        }
        rules.excludedPlaces = []
        rules.splitsUnitedKingdom = false
        return rules
    }
}

extension CountingRules: Codable {
    private enum CodingKeys: String, CodingKey {
        case minimumLevelID, includesSpecialRegions, includesTaiwan, splitsUnitedKingdom, includesTerritories
        case includesRemotePlaces, includesObservers, includesPartlyRecognised, includesAssociatedStates
        case includesDeFactoStates, excludedPlaces, continentChoices
    }

    /// Reads saved rules, falling back to the defaults for anything they predate.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        minimumLevelID = try container.decodeIfPresent(String.self, forKey: .minimumLevelID) ?? minimumLevelID
        includesSpecialRegions = try container.decodeIfPresent(Bool.self, forKey: .includesSpecialRegions) ?? includesSpecialRegions
        includesTaiwan = try container.decodeIfPresent(Bool.self, forKey: .includesTaiwan) ?? includesTaiwan
        splitsUnitedKingdom = try container.decodeIfPresent(Bool.self, forKey: .splitsUnitedKingdom) ?? splitsUnitedKingdom
        includesTerritories = try container.decodeIfPresent(Bool.self, forKey: .includesTerritories) ?? includesTerritories
        includesRemotePlaces = try container.decodeIfPresent(Bool.self, forKey: .includesRemotePlaces) ?? includesRemotePlaces
        includesObservers = try container.decodeIfPresent(Bool.self, forKey: .includesObservers) ?? includesObservers
        includesPartlyRecognised = try container.decodeIfPresent(Bool.self, forKey: .includesPartlyRecognised) ?? includesPartlyRecognised
        includesAssociatedStates = try container.decodeIfPresent(Bool.self, forKey: .includesAssociatedStates) ?? includesAssociatedStates
        excludedPlaces = try container.decodeIfPresent(Set<String>.self, forKey: .excludedPlaces) ?? excludedPlaces
        continentChoices = try container.decodeIfPresent([String: String].self, forKey: .continentChoices) ?? continentChoices
        includesDeFactoStates = try container.decodeIfPresent(Bool.self, forKey: .includesDeFactoStates) ?? countsEverywhereElse
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minimumLevelID, forKey: .minimumLevelID)
        try container.encode(includesSpecialRegions, forKey: .includesSpecialRegions)
        try container.encode(includesTaiwan, forKey: .includesTaiwan)
        try container.encode(splitsUnitedKingdom, forKey: .splitsUnitedKingdom)
        try container.encode(includesTerritories, forKey: .includesTerritories)
        try container.encode(includesRemotePlaces, forKey: .includesRemotePlaces)
        try container.encode(includesObservers, forKey: .includesObservers)
        try container.encode(includesPartlyRecognised, forKey: .includesPartlyRecognised)
        try container.encode(includesAssociatedStates, forKey: .includesAssociatedStates)
        try container.encode(includesDeFactoStates, forKey: .includesDeFactoStates)
        try container.encode(excludedPlaces, forKey: .excludedPlaces)
        try container.encode(continentChoices, forKey: .continentChoices)
    }
}
