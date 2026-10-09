import Foundation
import SwiftData

/// Custom levels: renaming, reordering, adding and removing levels never strands a place.
enum LevelChecks {
    @MainActor static func run(in context: ModelContext) throws {
        let jp = CountryCatalog.japan
        let au = CountryCatalog.australia
        let standard = VisitLadder.standard
        let passed = standard.levels[0], alighted = standard.levels[1], visited = standard.levels[2]
        let stayed = standard.levels[3], lived = standard.levels[4]

        // The default levels keep the original keys, so earlier saves stay attached.
        precondition(standard.isValid)
        precondition(standard.levels.map(\.id) == VisitStatus.allCases.filter { $0 != .never }.map(\.storageKey))
        precondition(standard.allLevels.first == .never && standard.level(id: "never") == .never)
        precondition(standard.next(after: .never) == passed && standard.next(after: lived) == .never)
        precondition(standard.higher(than: .never) == passed && standard.higher(than: lived) == nil)
        precondition(standard.lower(than: passed) == .never && standard.lower(than: .never) == nil)
        precondition(Array(standard.levels(from: visited)) == [visited, stayed, lived])
        precondition(Array(standard.levels(from: .never)) == standard.levels)

        // Ladders that would break counting or identity are refused.
        func named(_ id: String) -> VisitLevel { VisitLevel(id: id, name: id, tint: .red, symbolName: "circle") }
        precondition(!VisitLadder(levels: []).isValid)
        precondition(!VisitLadder(levels: [passed, passed]).isValid)
        precondition(!VisitLadder(levels: [named("never")]).isValid)
        precondition(!VisitLadder(levels: [named(" ")]).isValid)
        precondition(!VisitLadder(levels: (0...VisitLadder.maximumCount).map { named("level\($0)") }).isValid)

        let model = SaveModel()
        context.insert(model)
        precondition(model.levelsData == nil && model.ladder == standard)
        // Hokkaido and Aomori are known only from the original history; Iwate has a newer record.
        model.visitStatus[0] = .alighted
        model.visitStatus[1] = .passed
        try model.setStatus(alighted, for: jp.divisions[2])
        try model.setStatus(stayed, for: au.divisions[0])
        precondition(model.snapshot().placesPerLevel()["alighted"] == 2)

        // Renaming, recolouring and adding a level keep every place where it was.
        var custom = standard
        custom.levels[1].name = "Stopped"
        custom.levels[1].tint = .purple
        let hiked = VisitLevel(id: UUID().uuidString, name: "Hiked", tint: .lime, symbolName: "figure.hiking")
        custom.levels.insert(hiked, at: 3) // Passed, Stopped, Visited, Hiked, Stayed, Lived
        try model.setLadder(custom)
        precondition(model.ladder == custom && model.levelsData != nil)
        precondition(model.status(for: jp.divisions[0]).name == "Stopped")
        precondition(model.status(for: jp.divisions[2]) == custom.levels[1])
        try model.setStatus(hiked, for: au.divisions[1])
        try model.setStatus(hiked, for: jp.divisions[3])
        // The original history can't hold a level the person added.
        precondition(model.visitStatus[3] == .never && model.status(for: jp.divisions[3]) == hiked)
        precondition(model.score(in: au) == 5 + 4)

        // Counting follows the order, and starts from the lowest level when its own is gone.
        var fromHiked = CountingRules()
        fromHiked.minimumLevelID = hiked.id
        precondition(model.snapshot().count(in: au.divisions, counting: fromHiked) == 2)
        precondition(model.snapshot().count(in: jp.divisions, counting: fromHiked) == 1)
        var fromMissing = CountingRules()
        fromMissing.minimumLevelID = "missing"
        precondition(fromMissing.minimumLevel(in: custom) == passed)
        precondition(model.snapshot().count(in: jp.divisions, counting: fromMissing) == 4)

        // Reordering changes which level is strongest without moving any place.
        var reordered = custom
        reordered.levels.swapAt(3, 4) // Passed, Stopped, Visited, Stayed, Hiked, Lived
        try model.setLadder(reordered)
        precondition(model.strongestStatus(in: au) == hiked && model.status(for: au.divisions[0]) == stayed)

        // Removing levels moves their places down to the closest remaining level,
        // including places known only from the original history.
        let counts = model.snapshot().placesPerLevel()
        precondition(counts["alighted"] == 2 && counts[hiked.id] == 2 && counts["passed"] == 1 && counts["stayed"] == 1)
        var removed = reordered
        removed.levels.removeAll { $0.id == "alighted" || $0.id == hiked.id } // Passed, Visited, Stayed, Lived
        precondition(reordered.replacements(becoming: removed) == ["alighted": passed, hiked.id: stayed])
        try model.setLadder(removed)
        precondition(model.status(for: jp.divisions[0]) == passed && model.visitStatus[0] == .passed)
        precondition(model.status(for: jp.divisions[2]) == passed && model.visitStatus[2] == .passed)
        precondition(model.status(for: jp.divisions[3]) == stayed && model.visitStatus[3] == .stayed)
        precondition(model.status(for: au.divisions[1]) == stayed)
        precondition(model.snapshot().placesPerLevel()["alighted"] == nil)

        // Removing the lowest level sends its places to never been, and counting starts from the new lowest.
        var withoutPassed = removed
        withoutPassed.levels.removeFirst() // Visited, Stayed, Lived
        try model.setLadder(withoutPassed)
        precondition(model.status(for: jp.divisions[1]) == .never && model.visitStatus[1] == .never)
        precondition(model.status(for: jp.divisions[0]) == .never)
        precondition(CountingRules().minimumLevel(in: withoutPassed) == visited)

        // Restoring the defaults brings back the original levels; places at added levels step down.
        var withDayTrip = withoutPassed
        let dayTrip = VisitLevel(id: UUID().uuidString, name: "Day trip", tint: .mint, symbolName: "car.fill")
        withDayTrip.levels.insert(dayTrip, at: 1) // Visited, Day trip, Stayed, Lived
        try model.setLadder(withDayTrip)
        try model.setStatus(dayTrip, for: au.divisions[2])
        try model.setLadder(.standard)
        precondition(model.ladder == standard && model.status(for: au.divisions[2]) == visited)

        // A place can't take a level that no longer exists, and unreadable levels are never overwritten.
        do {
            try model.setStatus(dayTrip, for: au.divisions[3])
            preconditionFailure("Must refuse a level that no longer exists")
        } catch LevelError.missingLevel {}
        do {
            try model.setLadder(VisitLadder(levels: []))
            preconditionFailure("Must refuse a ladder without levels")
        } catch LevelError.invalidLevels {}
        let unreadable = Data("not levels".utf8)
        model.levelsData = unreadable
        precondition(model.ladder == standard)
        do {
            try model.setLadder(custom)
            preconditionFailure("Must refuse to overwrite unreadable levels")
        } catch {
            precondition(model.levelsData == unreadable)
        }
        context.delete(model)
        print("PASS: custom levels rename, reorder, add, remove, restore, refuse missing and unreadable levels")
    }
}
