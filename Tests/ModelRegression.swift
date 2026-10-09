import Foundation
import SwiftData

@main struct ModelRegression {
    @MainActor static func main() throws {
        let jp = CountryCatalog.japan
        let au = CountryCatalog.australia
        let fr = CountryCatalog.france
        let de = CountryCatalog.germany
        precondition(jp.divisions.count == 47)
        precondition(au.divisions.count == 16)
        precondition(fr.divisions.count == 101 && fr.groups.count == 18)
        precondition(de.divisions.count == 16)
        let divisionCounts = Dictionary(uniqueKeysWithValues: CountryCatalog.countries.map { ($0.id, $0.divisions.count) })
        precondition(divisionCounts == [
            "WORLD": 251, "JP": 47, "AU": 16, "CA": 13, "CN": 33, "FR": 101,
            "DE": 16, "IT": 20, "ES": 19, "CH": 26, "GB": 4, "US": 56,
            "KR": 16, "TW": 22, "AT": 9, "NL": 12, "BE": 11, "PL": 16, "PT": 20, "NO": 15,
            "BR": 27, "AR": 24, "MX": 32, "MY": 16, "TH": 77, "PH": 83, "ID": 38, "IN": 36,
            "IE": 26, "SE": 21, "DK": PlaceReorganisation.eastDenmark.isInEffect ? 4 : 5, "FI": 19, "CZ": 14, "HR": 21, "GR": 14, "HU": 20, "CL": 16, "CO": 33, "PE": 26, "TR": 81, "AE": 7, "LK": 9, "NZ": 17, "ZA": 9,
            "IS": 8, "EE": 15, "LT": 10, "SK": 8, "RO": 42, "BG": 28, "UA": 27, "EG": 27, "KE": 47, "EC": 24, "BO": 9, "UY": 19, "CU": 16, "NP": 7, "MN": 22, "SA": 13,
            "RU": 83,
            "JO": 12, "OM": 11, "QA": 8, "KW": 6, "BH": 4, "IR": 31, "IQ": 19, "KH": 25, "LA": 18, "BD": 8, "BT": 20, "PG": 22, "FJ": 5,
            "VE": 25, "PY": 18, "GT": 22, "CR": 7, "PA": 14, "DO": 32, "JM": 14, "HN": 18, "SV": 14, "NG": 37, "TZ": 31, "GH": 16, "SN": 14, "RW": 5, "NA": 14, "TN": 24, "DZ": 69,
            "RS": 25, "BA": 12, "AL": 12, "ME": 25, "LV": 42, "LU": 12, "MT": 68, "BY": 7, "AM": 11, "KZ": 20, "UZ": 14, "KG": 9,
        ])
        let frenchDepartmentCodes = (1...95).filter { $0 != 20 }.map { String(format: "%02d", $0) }
            + ["2A", "2B", "971", "972", "973", "974", "976"]
        precondition(Set(fr.divisions.map(\.id)) == Set(frenchDepartmentCodes.map { "FR-\($0)" }))
        precondition(au.groups.map { $0.divisions.count } == [6, 3, 7])
        precondition(Set(CountryCatalog.countries.map(\.id)).isSuperset(of: ["JP", "AU", "FR", "DE"]))
        // IDs are unique within each collection. A place may appear in two collections only when
        // Countries deliberately shares another collection's record for it.
        var collectionsByID: [String: Set<String>] = [:]
        for country in CountryCatalog.countries {
            precondition(Set(country.divisions.map(\.id)).count == country.divisions.count)
            for division in country.divisions { collectionsByID[division.id, default: []].insert(country.id) }
        }
        let sharedIDs = Set(CountryCatalog.sharedPlaceIDs.values)
        precondition(collectionsByID.filter { $0.value.count > 1 }.keys.allSatisfy(sharedIDs.contains))
        precondition(sharedIDs.allSatisfy { collectionsByID[$0]?.count == 2 && collectionsByID[$0]!.contains("WORLD") })
        precondition(Set(CountryCatalog.legacyStatusIDs.values).count == CountryCatalog.legacyStatusIDs.count)

        // Counting rules shape Countries without touching any other collection.
        let standardCountries = CountryCatalog.world(applying: CountingRules())
        precondition(standardCountries.divisions.count == 243)
        precondition(Set(["HK", "MO", "TW", "GB", "GL"]).isSubset(of: Set(standardCountries.divisions.map(\.abbreviation))))
        precondition(!standardCountries.divisions.contains { ["AQ", "BV", "UM", "ENG"].contains($0.abbreviation) })
        var everything = CountingRules()
        everything.splitsUnitedKingdom = true
        everything.includesRemotePlaces = true
        let splitCountries = CountryCatalog.world(applying: everything)
        precondition(splitCountries.divisions.count == 253)
        let europe = splitCountries.groups.first { $0.id == "WORLD-europe" }!.divisions.map(\.name)
        precondition(europe.contains("Scotland") && !europe.contains("United Kingdom"))
        precondition(europe.firstIndex(of: "England")! < europe.firstIndex(of: "Estonia")!)
        precondition(splitCountries.groups.allSatisfy { group in group.divisions.allSatisfy { $0.groupID == group.id } })
        var strict = CountingRules()
        strict.includesSpecialRegions = false
        strict.includesTaiwan = false
        strict.includesTerritories = false
        // Western Sahara, the Cook Islands and Niue have groups of their own now.
        strict.includesAssociatedStates = false
        strict.excludedPlaces = ["EH"]
        precondition(CountryCatalog.world(applying: strict).divisions.count == 196)
        // The standards count the UN's members, then its observers, then every self-governing state.
        func count(_ standard: CountingStandard) -> Int {
            CountryCatalog.world(applying: standard.applied(to: CountingRules())).divisions.count
        }
        precondition(count(.unMembers) == 193)
        precondition(count(.unObservers) == 195)
        precondition(count(.sovereignStates) == 200)
        precondition(count(.everywhere) == 251)
        // Northern Cyprus counts only when chosen; until then the whole island is Cyprus.
        precondition(!standardCountries.divisions.contains { $0.abbreviation == "XC" })
        precondition(CountingStandard.everywhere.applied(to: CountingRules()).includesWorldPlace(code: "XC"))
        precondition(!CountingStandard.sovereignStates.applied(to: CountingRules()).includesWorldPlace(code: "XC"))
        precondition(CountryCatalog.mapRegionOwners(applying: CountingRules())["WORLD-XC"] == "WORLD-CY")
        // Rules saved before it had a switch count it only if they counted everywhere, so they still do.
        let everywhereBefore = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(CountingStandard.everywhere.applied(to: CountingRules()))) as! [String: Any]
        let olderEverywhere = try JSONDecoder().decode(
            CountingRules.self,
            from: JSONSerialization.data(withJSONObject: everywhereBefore.filter { $0.key != "includesDeFactoStates" }))
        precondition(olderEverywhere.standard == .everywhere)
        let olderDefaults = try JSONDecoder().decode(CountingRules.self, from: Data("{}".utf8))
        precondition(!olderDefaults.includesDeFactoStates)
        precondition(CountingStandard.unMembers.applied(to: CountingRules()).standard == .unMembers)
        var tuned = CountingStandard.unObservers.applied(to: CountingRules())
        tuned.setIncludes(code: "XK", true)
        precondition(tuned.standard == nil && tuned.includesWorldPlace(code: "XK") && !tuned.includesWorldPlace(code: "EH"))
        let strictCollections = CountryCatalog.countries(applying: strict)
        precondition(strictCollections.filter { !["WORLD", "CN"].contains($0.id) }
            .elementsEqual(CountryCatalog.countries.filter { !["WORLD", "CN"].contains($0.id) }))
        // Taiwan joins China's list while it isn't counted as a country, sharing the Countries record.
        let strictChina = strictCollections.first { $0.id == "CN" }!
        precondition(strictChina.divisions.count == 34 && strictChina.divisions.contains { $0.id == "WORLD-TW" })
        precondition(CountryCatalog.countries(applying: CountingRules()).first { $0.id == "CN" }!.divisions.count == 33)
        // A place lifts the Countries entries it belongs to; entries in Countries lift nothing.
        func owners(_ place: AdministrativeDivision, _ rules: CountingRules) -> [String] {
            CountryCatalog.countries(containing: place, rules: rules).map(\.id)
        }
        precondition(owners(jp.divisions[0], CountingRules()) == ["WORLD-JP"])
        let taipei = CountryCatalog.taiwan.divisions.first { $0.id == "TW-TPE" }!
        precondition(owners(taipei, CountingRules()) == ["WORLD-TW"])
        precondition(owners(taipei, strict) == ["WORLD-TW", "WORLD-CN"])
        let hongKong = CountryCatalog.china.divisions.first { $0.id == "CN-HK" }!
        precondition(owners(hongKong, CountingRules()).isEmpty && owners(hongKong, strict) == ["WORLD-CN"])
        let scotland = CountryCatalog.unitedKingdom.divisions.first { $0.abbreviation == "SCT" }!
        precondition(owners(scotland, CountingRules()) == ["WORLD-GB"] && owners(scotland, everything).isEmpty)
        let guadeloupe = CountryCatalog.france.divisions.first { $0.id == "FR-971" }!
        precondition(owners(guadeloupe, CountingRules()).isEmpty && owners(guadeloupe, strict) == ["WORLD-FR"])
        precondition(owners(CountryCatalog.world.divisions.first { $0.abbreviation == "CA" }!, CountingRules()).isEmpty)
        let strictOwners = CountryCatalog.mapRegionOwners(applying: strict)
        precondition(strictOwners["WORLD-TW"] == "WORLD-CN" && strictOwners["CN-HK"] == "WORLD-CN")
        precondition(strictOwners["WORLD-GL"] == "WORLD-DK" && strictOwners["WORLD-EH"] == nil)
        precondition(CountryCatalog.mapRegionOwners(applying: CountingRules())["WORLD-TW"] == nil)
        // A country spanning two continents can be listed under either; others stay put.
        var chosen = CountingRules()
        chosen.continentChoices = ["RU": "asia", "TR": "europe", "FR": "oceania"]
        let rearranged = CountryCatalog.world(applying: chosen)
        let rearrangedAsia = rearranged.groups.first { $0.id == "WORLD-asia" }!
        let rearrangedEurope = rearranged.groups.first { $0.id == "WORLD-europe" }!
        precondition(rearrangedAsia.divisions.contains { $0.abbreviation == "RU" && $0.groupID == "WORLD-asia" })
        precondition(rearrangedEurope.divisions.contains { $0.abbreviation == "TR" && $0.groupID == "WORLD-europe" })
        precondition(!rearrangedAsia.divisions.contains { $0.abbreviation == "TR" })
        precondition(rearrangedEurope.divisions.contains { $0.abbreviation == "FR" })
        precondition(rearranged.divisions.count == standardCountries.divisions.count)
        let asianNames = rearrangedAsia.divisions.map(\.name)
        precondition(asianNames == asianNames.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        func section(of id: String, _ rules: CountingRules) -> String? {
            CountryCatalog.sections(applying: rules).first { $0.countries.contains { $0.id == id } }?.title
        }
        precondition(section(of: "TR", CountingRules()) == "Asia" && section(of: "TR", chosen) == "Europe")
        // World places show their formal name beneath; subdivisions and local names come first.
        let worldChina = CountryCatalog.world.divisions.first { $0.abbreviation == "CN" }!
        precondition(worldChina.subtitle(localLanguage: false) == "People's Republic of China")
        precondition(CountryCatalog.world.divisions.first { $0.abbreviation == "JP" }!.formalName == nil)
        let chinaWithTaiwan = CountryCatalog.countries(applying: strict).first { $0.id == "CN" }!
        precondition(chinaWithTaiwan.divisions.first { $0.id == "WORLD-TW" }!.subtitle(localLanguage: false) == "台湾")
        precondition(jp.divisions[0].formalName == nil && jp.divisions[0].subtitle(localLanguage: false) == "北海道")
        precondition(Set(CountryCatalog.formalNames.keys).isSubset(of: Set(CountryCatalog.world.divisions.map(\.abbreviation))))
        let standard = VisitLadder.standard
        func level(_ id: String) -> VisitLevel { standard.level(id: id)! }
        var visitedOrMore = CountingRules()
        visitedOrMore.minimumLevelID = "visited"
        precondition(!visitedOrMore.counts(level("alighted"), in: standard) && visitedOrMore.counts(level("visited"), in: standard)
            && !CountingRules().counts(.never, in: standard))
        precondition(Set(jp.divisions.compactMap(\.legacyJapanIndex)) == Set(0..<47))
        precondition(au.divisions.allSatisfy { $0.legacyJapanIndex == nil })
        for country in CountryCatalog.countries {
            precondition(country.groups.allSatisfy { group in
                group.divisions.allSatisfy { $0.countryID == country.id && $0.groupID == group.id }
            })
        }
        let oldEncoded = Data("[{\"never\":{}},{\"passed\":{}},{\"alighted\":{}},{\"visited\":{}},{\"stayed\":{}},{\"lived\":{}}]".utf8)
        let decodedLegacy = try JSONDecoder().decode([VisitStatus].self, from: oldEncoded)
        precondition(decodedLegacy == VisitStatus.allCases)
        let encoded = try JSONEncoder().encode(VisitStatus.allCases)
        let legacyObject = try JSONSerialization.jsonObject(with: oldEncoded) as! NSArray
        let currentObject = try JSONSerialization.jsonObject(with: encoded) as! NSArray
        precondition(legacyObject == currentObject)

        let schema = Schema([SaveModel.self])
        let memory = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let memoryContext = ModelContext(memory)
        let scratch = SaveModel()
        memoryContext.insert(scratch)
        scratch.visitStatus = [.visited] // An incomplete historical record remains safe.
        precondition(scratch.status(for: jp.divisions[0]) == level("visited"))
        precondition(scratch.status(for: jp.divisions[46]) == .never)
        try scratch.setStatus(level("lived"), for: jp.divisions[46])
        precondition(scratch.visitStatus.count == 47 && scratch.visitStatus[0] == .visited)
        precondition(scratch.markedCount(in: jp) == 2)
        precondition(scratch.score(in: jp) == 8)
        try scratch.setStatus(level("passed"), for: au.divisions[0])
        precondition(scratch.markedCount(in: au) == 1 && scratch.snapshot().count(in: au.divisions, counting: visitedOrMore) == 0)
        precondition(scratch.markedCount(in: jp) == 2)
        try scratch.setStatus(level("visited"), for: fr.divisions[0])
        try scratch.setStatus(level("stayed"), for: de.divisions[0])

        // Places that merged carry over the best level set on the places they replaced, once.
        UserDefaults.standard.removeObject(forKey: SaveModel.appliedReorganisationsKey)
        let merging = SaveModel()
        memoryContext.insert(merging)
        merging.statusesData = try JSONEncoder().encode(["KR-46": "visited", "KR-29": "stayed"])
        let kr = CountryCatalog.countries.first { $0.id == "KR" }!
        let jeonnamGwangju = kr.divisions.first { $0.id == "KR-JG" }!
        precondition(!kr.divisions.contains { $0.id == "KR-46" || $0.id == "KR-29" })
        let applied = try merging.applyPlaceReorganisations()
        precondition(applied.contains(PlaceReorganisation.jeonnamGwangju.id))
        precondition(merging.status(for: jeonnamGwangju) == level("stayed"))
        precondition(PlaceReorganisation.mapResourceID(for: "KR") == "KR")
        precondition(PlaceReorganisation.mapResourceID(for: "DK") == (PlaceReorganisation.eastDenmark.isInEffect ? "DK-2027" : "DK"))
        UserDefaults.standard.removeObject(forKey: SaveModel.appliedReorganisationsKey)
        precondition(scratch.markedCount(in: fr) == 1 && scratch.markedCount(in: de) == 1)
        precondition(scratch.markedCount(in: au) == 1 && scratch.markedCount(in: jp) == 2)
        let us = CountryCatalog.unitedStates
        try scratch.setStatus(level("lived"), for: us.divisions[0])
        precondition(scratch.markedCount(in: us) == 1 && scratch.markedCount(in: CountryCatalog.world) == 0)
        // Countries catch up with their highest place, and a place lifts only countries below it.
        let catchUp = scratch.snapshot().countriesBelowTheirPlaces(rules: CountingRules())
        precondition(Dictionary(uniqueKeysWithValues: catchUp.map { ($0.0.id, $0.1.id) }) == [
            "WORLD-JP": "lived", "WORLD-AU": "passed", "WORLD-FR": "visited", "WORLD-DE": "stayed", "WORLD-US": "lived",
        ])
        let ontario = CountryCatalog.canada.divisions[0]
        let raised = scratch.snapshot().countriesRaised(by: level("stayed"), at: ontario, rules: CountingRules())
        precondition(raised.map(\.place.id) == ["WORLD-CA"] && raised[0].previous == .never)
        precondition(scratch.snapshot().countriesRaised(by: .never, at: ontario, rules: CountingRules()).isEmpty)
        precondition(scratch.snapshot().countriesRaised(by: level("passed"), at: jp.divisions[0], rules: CountingRules())
            .map(\.place.id) == ["WORLD-JP"])

        // Shared places: one record, visible from both collections.
        let chinaHongKong = CountryCatalog.china.divisions.first { $0.id == "CN-HK" }!
        let countriesHongKong = CountryCatalog.world.divisions.first { $0.abbreviation == "HK" }!
        try scratch.setStatus(level("stayed"), for: chinaHongKong)
        precondition(scratch.status(for: countriesHongKong) == level("stayed"))
        let puertoRico = CountryCatalog.unitedStates.divisions.first { $0.id == "US-PR" }!
        try scratch.setStatus(level("alighted"), for: CountryCatalog.world.divisions.first { $0.abbreviation == "PR" }!)
        precondition(scratch.status(for: puertoRico) == level("alighted"))
        let england = CountryCatalog.world(applying: everything).divisions.first { $0.abbreviation == "ENG" }!
        try scratch.setStatus(level("lived"), for: england)
        precondition(scratch.status(for: CountryCatalog.unitedKingdom.divisions[0]) == level("lived"))
        precondition(scratch.snapshot().count(in: CountryCatalog.world(applying: everything).divisions, counting: CountingRules()) == 3)
        precondition(scratch.snapshot().count(in: CountryCatalog.world(applying: everything).divisions, counting: visitedOrMore) == 2)
        precondition(scratch.snapshot().tally(of: CountryCatalog.world(applying: everything).divisions)["stayed"] == 1)
        let mainlandChina = CountryCatalog.china.divisions[0]
        try scratch.setStatus(.never, for: mainlandChina)
        precondition(scratch.status(for: mainlandChina) == .never)

        // Statuses saved under the older world IDs are still found from both collections.
        let legacyRecord = SaveModel()
        memoryContext.insert(legacyRecord)
        legacyRecord.statusesData = try JSONEncoder().encode(["WORLD-MO": "visited", "WORLD-GP": "lived", "CN-HK": "passed", "WORLD-HK": "lived"])
        let macao = CountryCatalog.china.divisions.first { $0.id == "CN-MO" }!
        precondition(legacyRecord.status(for: macao) == level("visited"))
        precondition(legacyRecord.status(for: CountryCatalog.world.divisions.first { $0.abbreviation == "MO" }!) == level("visited"))
        precondition(legacyRecord.status(for: CountryCatalog.france.divisions.first { $0.id == "FR-971" }!) == level("lived"))
        precondition(legacyRecord.status(for: chinaHongKong) == level("passed")) // A current record wins over an older one.
        // Only the record each place reads from counts toward its level, so WORLD-HK is ignored.
        precondition(legacyRecord.snapshot().placesPerLevel()["lived"] == 1)
        try legacyRecord.setStatus(.never, for: macao)
        precondition(legacyRecord.status(for: macao) == .never)
        memoryContext.delete(legacyRecord)

        try scratch.setStatus(.never, for: jp.divisions[0])
        precondition(scratch.status(for: jp.divisions[0]) == .never && scratch.visitStatus[0] == .never)
        scratch.statusesData = try JSONEncoder().encode(["FUTURE-42": "futureStatus"])
        try scratch.setStatus(level("visited"), for: au.divisions[1])
        let futureEntries = try JSONDecoder().decode([String: String].self, from: scratch.statusesData!)
        precondition(futureEntries["FUTURE-42"] == "futureStatus")
        let badData = Data("invalid saved data".utf8)
        scratch.statusesData = badData
        let legacyBefore = scratch.visitStatus
        do {
            try scratch.setStatus(level("stayed"), for: jp.divisions[1])
            preconditionFailure("Must refuse to overwrite undecodable data")
        } catch {
            precondition(scratch.statusesData == badData && scratch.visitStatus == legacyBefore)
        }
        print("PASS: catalog identity, legacy Codable, short data, country isolation, reset, unknown entries, corrupted data")
        try LevelChecks.run(in: memoryContext)

        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let configuration = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<SaveModel>())
        precondition(records.count == 1)
        let record = records[0]
        // Compare IDs: the first run renames a level, and places must stay on it after reopening.
        precondition(record.status(for: jp.divisions[0]).id == "passed")
        precondition(record.status(for: jp.divisions[12]).id == "lived")
        precondition(record.status(for: jp.divisions[46]).id == "stayed")
        if CommandLine.arguments.count == 2 {
            precondition(record.statusesData == nil && record.levelsData == nil && record.ladder == standard)
            precondition(record.markedCount(in: jp) == 3)
            try record.setStatus(level("stayed"), for: au.divisions[0])
            try record.setStatus(level("visited"), for: au.divisions[15])
            try record.setStatus(level("visited"), for: fr.divisions.first { $0.id == "FR-2A" }!)
            try record.setStatus(level("stayed"), for: fr.divisions.first { $0.id == "FR-976" }!)
            try record.setStatus(level("lived"), for: de.divisions[0])
            var renamed = standard
            renamed.levels[3].name = "Slept"
            renamed.levels.append(VisitLevel(id: "regression-born", name: "Born", tint: .pink, symbolName: "star.fill"))
            try record.setLadder(renamed)
            try record.setStatus(renamed.levels[5], for: de.divisions[1])
            try context.save()
            print("PASS: migrated real legacy SwiftData store, preserved Japan, saved Australian, French, and German divisions and custom levels")
        } else {
            precondition(record.ladder.levels.map(\.name) == ["Passed", "Alighted", "Visited", "Slept", "Lived", "Born"])
            precondition(record.status(for: jp.divisions[46]).name == "Slept")
            precondition(record.status(for: de.divisions[1]).name == "Born")
            precondition(record.status(for: au.divisions[0]).id == "stayed")
            precondition(record.status(for: au.divisions[15]).id == "visited")
            precondition(record.markedCount(in: au) == 2)
            precondition(record.markedCount(in: jp) == 3)
            precondition(record.status(for: fr.divisions.first { $0.id == "FR-2A" }!).id == "visited")
            precondition(record.status(for: fr.divisions.first { $0.id == "FR-976" }!).id == "stayed")
            precondition(record.status(for: de.divisions[0]).id == "lived")
            print("PASS: new process reopened disk store with Japan, Australia, France, Germany, and custom levels intact")
        }
    }
}
