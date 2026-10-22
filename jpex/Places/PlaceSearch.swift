import Foundation

/// Finds places by name across every list, such as Kyoto, Texas or Bavaria, from wherever the
/// person is. Names match in either language, ignoring case and accents, from the start of any
/// word, so "york" finds New York; exact names and names that begin with the search come first.
@MainActor
enum PlaceSearch {
    /// A place found, with the list it's in.
    struct Result: Identifiable {
        var place: AdministrativeDivision
        /// The list it's in, such as Japan for Kyoto, or the World for a country.
        var collection: Country
        /// Where it is within that list: its region, or for a country, its continent. Nil where the
        /// list has just the one group, such as Germany's states, which would say nothing more.
        var groupName: String?
        var id: String { place.id }

        /// Where to find it, as an address reads: the region, then the country, such as
        /// "Kansai, Japan"; for a country, its continent; for one of a place's own subdivisions,
        /// that place and its country, such as "Tasmania, Australia" for Hobart.
        var locationName: String {
            // A country, or a sea, is found in its continent or its ocean.
            if collection.id == CountryCatalog.world.id || collection.id == CountryCatalog.seas.id {
                return groupName ?? collection.name
            }
            if let parent = collection.parentPlace, let country = CountryCatalog.country(id: parent.countryID) {
                return "\(collection.name), \(country.name)"
            }
            return groupName.map { "\($0), \(collection.name)" } ?? collection.name
        }
    }

    /// The places matching a search, best first, leaving out those listed in `excluded`, such as the
    /// list already showing its own matches. A single letter finds nothing, except in scripts such
    /// as Japanese, where one character can be a name.
    static func results(
        for query: String, in collections: [Country], excluding excluded: Country? = nil, limit: Int = 40
    ) -> [Result] {
        let needle = fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard needle.count >= 2 || needle.unicodeScalars.contains(where: { !$0.isASCII }) else { return [] }
        let skipped = Set(excluded?.divisions.map(\.id) ?? [])
        var ranked: [(rank: Int, entry: Entry)] = []
        for entry in index(of: collections) where !skipped.contains(entry.result.place.id) {
            if let rank = entry.rank(matching: needle) { ranked.append((rank, entry)) }
        }
        ranked.sort { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            return lhs.entry.result.place.name.localizedStandardCompare(rhs.entry.result.place.name) == .orderedAscending
        }
        return ranked.prefix(limit).map(\.entry.result)
    }

    /// Lowercased, without accents, and with full-width letters made plain, for comparing names.
    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    /// One place, its names already folded for matching, and split into words once.
    private struct Entry {
        var result: Result
        var names: [String]
        var words: [Substring]
        /// A short code worth matching whole, such as NSW or CA; numbers, such as Japan's, aren't.
        var code: String?

        /// How well the search matches: 0 for a whole name or code, 1 for a name's start, 2 for a
        /// later word's start, 3 anywhere inside. Nil for no match.
        func rank(matching needle: String) -> Int? {
            if code == needle || names.contains(needle) { return 0 }
            if names.contains(where: { $0.hasPrefix(needle) }) { return 1 }
            if words.contains(where: { $0.hasPrefix(needle) }) { return 2 }
            return names.contains { $0.contains(needle) } ? 3 : nil
        }
    }

    /// Every place in these lists once, kept until the lists change, as when the person counts
    /// countries another way. A place listed twice, such as Hong Kong, keeps the first list it's in.
    private static var cache: (key: [String], entries: [Entry])?

    private static func index(of collections: [Country]) -> [Entry] {
        // Each list's groups and their sizes, so a country moved to another continent is found anew.
        let key = collections.map { collection in
            "\(collection.id):" + collection.groups.map { "\($0.id)=\($0.divisions.count)" }.joined(separator: ",")
        }
        if let cache, cache.key == key { return cache.entries }
        var seen: Set<String> = []
        var entries: [Entry] = []
        for collection in collections {
            for group in collection.groups {
                for place in group.divisions where seen.insert(place.id).inserted {
                    let code = fold(place.abbreviation)
                    let names = [place.name, place.localName].compactMap { $0 }.map(fold)
                    entries.append(Entry(
                        result: Result(
                            place: place, collection: collection,
                            groupName: collection.groups.count > 1 ? group.name : nil),
                        names: names,
                        words: names.flatMap { $0.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) },
                        code: code.count >= 2 && code.allSatisfy(\.isLetter) ? code : nil))
                }
            }
        }
        cache = (key, entries)
        return entries
    }
}
