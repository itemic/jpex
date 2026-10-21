import Foundation

/// Saved statuses decoded once, so a screen can draw every row and total without decoding again.
struct TravelSnapshot {
    var stored: [String: String]
    var legacyJapan: [VisitStatus]
    var ladder: VisitLadder

    func status(for division: AdministrativeDivision) -> VisitLevel {
        if let level = storedLevel(for: division.id) {
            return level
        }
        // A place shared between collections may have been saved under its older world ID.
        if let legacyID = CountryCatalog.legacyStatusIDs[division.id],
           let level = storedLevel(for: legacyID) {
            return level
        }
        if let index = division.legacyJapanIndex,
           division.countryID == "JP",
           legacyJapan.indices.contains(index) {
            return ladder.level(id: legacyJapan[index].storageKey) ?? .never
        }
        return .never
    }

    func count(in divisions: [AdministrativeDivision], counting rules: CountingRules) -> Int {
        divisions.reduce(0) { $0 + (rules.counts(status(for: $1), in: ladder) ? 1 : 0) }
    }

    func strongestStatus(in divisions: [AdministrativeDivision]) -> VisitLevel {
        divisions.map(status(for:)).max { ladder.rank(of: $0) < ladder.rank(of: $1) } ?? .never
    }

    /// The number of places at each level, by level ID.
    func tally(of divisions: [AdministrativeDivision]) -> [String: Int] {
        divisions.reduce(into: [:]) { $0[status(for: $1).id, default: 0] += 1 }
    }

    /// How many saved places sit at each level across every collection, by level ID.
    /// A place listed in two collections shares one record, so it counts once.
    func placesPerLevel() -> [String: Int] {
        var records = stored
        // An older world ID is only read while the shared record has never been set.
        for (sharedID, legacyID) in CountryCatalog.legacyStatusIDs where storedLevel(for: sharedID) != nil {
            records[legacyID] = nil
        }
        for division in CountryCatalog.japan.divisions {
            guard records[division.id] == nil, let index = division.legacyJapanIndex,
                  legacyJapan.indices.contains(index) else { continue }
            records[division.id] = legacyJapan[index].storageKey
        }
        return records.values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }

    private func storedLevel(for id: String) -> VisitLevel? {
        stored[id].flatMap(ladder.level(id:))
    }
}

/// A place's level before a change, so the change can be undone.
struct LevelChange {
    var place: AdministrativeDivision
    var previous: VisitLevel
}

extension TravelSnapshot {
    /// The places a place lies within that sit below `level`, nearest first, with their levels
    /// before rising: its region, such as Île-de-France for Paris, and the countries it belongs to.
    /// None ever falls because one of its places did.
    func placesRaised(
        by level: VisitLevel, at place: AdministrativeDivision, rules: CountingRules
    ) -> [LevelChange] {
        CountryCatalog.placesContaining(place, rules: rules).compactMap { container in
            let current = status(for: container)
            return ladder.rank(of: current) < ladder.rank(of: level) ? LevelChange(place: container, previous: current) : nil
        }
    }

    /// Regions among `regionIDs` sitting below the highest level among the places within them, such
    /// as France's regions below their departments, with the level each should rise to.
    func regionsBelowTheirPlaces(among regionIDs: Set<String>) -> [(AdministrativeDivision, VisitLevel)] {
        var highest: [String: VisitLevel] = [:]
        for collection in CountryCatalog.countries where collection.id != CountryCatalog.world.id {
            for place in collection.divisions {
                guard let regionID = place.parentID, regionIDs.contains(regionID) else { continue }
                let level = status(for: place)
                guard ladder.rank(of: level) > 0 else { continue }
                if let best = highest[regionID], ladder.rank(of: best) >= ladder.rank(of: level) { continue }
                highest[regionID] = level
            }
        }
        return highest
            .compactMap { id, level in CountryCatalog.countryPlace(id: id).map { ($0, level) } }
            .filter { region, level in ladder.rank(of: status(for: region)) < ladder.rank(of: level) }
            .sorted { $0.0.id < $1.0.id }
    }

    /// Countries sitting below the highest level among their places, with the level each should rise to.
    func countriesBelowTheirPlaces(rules: CountingRules) -> [(AdministrativeDivision, VisitLevel)] {
        var highest: [String: (AdministrativeDivision, VisitLevel)] = [:]
        for collection in CountryCatalog.countries(applying: rules) where collection.id != CountryCatalog.world.id {
            for place in collection.divisions {
                let level = status(for: place)
                guard ladder.rank(of: level) > 0 else { continue }
                for country in CountryCatalog.countries(containing: place, rules: rules) {
                    if let best = highest[country.id]?.1, ladder.rank(of: best) >= ladder.rank(of: level) { continue }
                    highest[country.id] = (country, level)
                }
            }
        }
        return highest.values
            .filter { country, level in ladder.rank(of: status(for: country)) < ladder.rank(of: level) }
            .sorted { $0.0.id < $1.0.id }
    }
}
