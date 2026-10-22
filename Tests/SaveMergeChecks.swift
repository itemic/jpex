import Foundation
import SwiftData

/// Saves made on two devices, brought together by iCloud, fold into one without losing a place.
enum SaveMergeChecks {
    @MainActor static func run(in context: ModelContext) throws {
        let jp = CountryCatalog.japan
        let au = CountryCatalog.australia
        let standard = VisitLadder.standard
        let passed = standard.levels[0], alighted = standard.levels[1], visited = standard.levels[2]
        let stayed = standard.levels[3], lived = standard.levels[4]

        // Every device keeps the same save: the first by ID, with saves still to get one last,
        // and never one that can't be read over one that can.
        let first = SaveModel(), second = SaveModel(), unnamed = SaveModel()
        first.saveID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        second.saveID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        unnamed.saveID = nil
        precondition(SaveModel().saveID != nil)
        precondition(SaveModel.kept(of: [unnamed, second, first]) === first)
        precondition(SaveModel.kept(of: [second, unnamed]) === second)
        precondition(SaveModel.kept(of: []) == nil)
        let placeholder = SaveModel()
        placeholder.saveID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
        placeholder.statusesData = Data("placeholder".utf8)
        precondition(SaveModel.kept(of: [second, placeholder]) === second)
        precondition(SaveModel.kept(of: [placeholder]) === placeholder)

        // Each place takes the higher of its two levels, places known only from the original Japan
        // history included, and that history stays in step. Both histories of changes are kept.
        let mine = SaveModel(), theirs = SaveModel()
        context.insert(mine)
        context.insert(theirs)
        try mine.setStatus(visited, for: jp.divisions[0])
        try theirs.setStatus(passed, for: jp.divisions[0])
        theirs.visitStatus[1] = .stayed
        try mine.setStatus(passed, for: au.divisions[0])
        try theirs.setStatus(lived, for: au.divisions[0])
        try theirs.setStatus(stayed, for: au.divisions[1])
        theirs.logChanges([(place: au.divisions[1], level: stayed)], at: Date(timeIntervalSince1970: 100))
        mine.logChanges([(place: jp.divisions[0], level: visited)], at: Date(timeIntervalSince1970: 200))
        try mine.fold(in: theirs)
        precondition(mine.status(for: jp.divisions[0]) == visited && mine.visitStatus[0] == .visited)
        precondition(mine.status(for: jp.divisions[1]) == stayed && mine.visitStatus[1] == .stayed)
        precondition(mine.status(for: au.divisions[0]) == lived && mine.status(for: au.divisions[1]) == stayed)
        let log = try mine.changeLog()
        precondition(log.map(\.placeID) == [au.divisions[1].id, jp.divisions[0].id])
        // Folding the same save in again changes nothing.
        let folded = mine.snapshot().stored
        try mine.fold(in: theirs)
        let logAgain = try mine.changeLog()
        precondition(mine.snapshot().stored == folded && logAgain.count == 2)

        // Levels the person made win over the original five, and places on removed levels step down.
        var custom = standard
        let hiked = VisitLevel(id: UUID().uuidString, name: "Hiked", tint: .lime, symbolName: "figure.hiking")
        custom.levels.removeAll { $0.id == alighted.id }
        custom.levels.insert(hiked, at: 2) // Passed, Visited, Hiked, Stayed, Lived
        let fresh = SaveModel(), made = SaveModel()
        context.insert(fresh)
        context.insert(made)
        try fresh.setStatus(alighted, for: au.divisions[2])
        try made.setLadder(custom)
        try made.setStatus(hiked, for: au.divisions[3])
        try fresh.fold(in: made)
        precondition(fresh.ladder == custom)
        precondition(fresh.status(for: au.divisions[2]) == passed && fresh.status(for: au.divisions[3]) == hiked)

        // Where both saves have levels of their own, these stay, and a place at a level only the
        // other has keeps its level here.
        var otherCustom = standard
        let dayTrip = VisitLevel(id: UUID().uuidString, name: "Day trip", tint: .mint, symbolName: "car.fill")
        otherCustom.levels.append(dayTrip)
        let other = SaveModel()
        context.insert(other)
        try other.setLadder(otherCustom)
        try other.setStatus(dayTrip, for: au.divisions[2])
        try other.setStatus(lived, for: au.divisions[4])
        try fresh.fold(in: other)
        precondition(fresh.ladder == custom && fresh.status(for: au.divisions[2]) == passed)
        precondition(fresh.status(for: au.divisions[4]) == lived)

        // A save that can't be read changes nothing, so it can be kept until it can.
        let broken = SaveModel()
        context.insert(broken)
        broken.statusesData = Data("not statuses".utf8)
        let before = fresh.snapshot().stored
        do {
            try fresh.fold(in: broken)
            preconditionFailure("Must refuse to fold in a save that can't be read")
        } catch {
            precondition(fresh.snapshot().stored == before)
        }
        for model in [mine, theirs, fresh, made, other, broken] { context.delete(model) }
        print("PASS: saves from two devices fold into the one every device keeps, unreadable saves refused")
    }
}
