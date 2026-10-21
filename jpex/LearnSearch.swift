import Foundation

/// Finds places in Learn by anything their cards show: their names, in either language or in
/// full, their capitals, any of their codes, and the region they're in. Case, accents and a code's
/// own marks don't matter, so "81" finds +81 and "jp" finds .jp. Whole names and codes come first,
/// then those the search begins, then a later word's start, then anywhere inside a name, and last
/// a region's places. Where nothing matches, a whole airport code, aircraft registration, phone
/// number or postcode finds the place its prefix belongs to: RJTT, JA8089 or +81 3 1234 Japan,
/// 2000 New South Wales, and 75001 Paris.
@MainActor
struct LearnSearch {
    /// A place found, and what of it matched.
    struct Result: Identifiable {
        var place: AdministrativeDivision
        /// Where it is in Learn's row.
        var index: Int
        var match: Match
        var id: String { place.id }
    }

    /// What of a place a search matched.
    enum Match: Equatable {
        /// Its name, as Learn shows it.
        case name
        /// Its name in the other language, or its formal name, such as Republic of Korea.
        case otherName(String)
        /// One of its capitals, by any of its names.
        case capital(String)
        /// One of its codes, such as +81, or one of several, such as Brazil's PR.
        case code(MapGame.CodeKind, String)
        /// The region it's in, such as Kansai.
        case region(String)

        var isCode: Bool {
            if case .code = self { return true }
            return false
        }
    }

    /// A place arrived at from the search, and what it was found by, for its card to point out.
    struct Landing: Equatable {
        var placeID: String
        var match: Match
        /// Each arrival anew, even at the same place twice.
        var id = UUID()
    }

    /// Text with the part a search matched in bold, as Spotlight shows it: the search as typed, or
    /// without a code's marks, such as 81 in +81. A code found by a longer one, such as RJ by
    /// RJTT, is bold throughout.
    static func emphasised(_ text: String, matching query: String, isCode: Bool = false) -> AttributedString {
        var attributed = AttributedString(text)
        let typed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let plain = Needle.plain(typed)
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]
        let found = typed.isEmpty ? nil : text.range(of: typed, options: options)
            ?? (isCode && !plain.isEmpty ? text.range(of: plain, options: options) : nil)
        if let found, let range = Range(found, in: attributed) {
            attributed[range].inlinePresentationIntent = .stronglyEmphasized
        } else if isCode, !typed.isEmpty {
            attributed.inlinePresentationIntent = .stronglyEmphasized
        }
        return attributed
    }

    /// A run of places in one region, in Learn's order, for the list before anything is searched.
    struct Region: Identifiable {
        /// Nil where places aren't told apart by region.
        var name: String?
        var places: [Result]
        var id: Int { places.first?.index ?? 0 }
    }

    private var entries: [Entry]
    /// Every place in Learn's order, in runs by region where places are told apart by region.
    private(set) var regions: [Region] = []

    /// Everything each place in a deck can be found by, in the deck's order, and its runs by
    /// region where the deck tells its places apart by region.
    init(deck: LearnDeck, localLanguage: Bool) {
        let groups = deck.groupsByID
        let hasRegions = deck.collection.groups.count > 1
        entries = deck.places.enumerated().map { index, place in
            var fields = [Field(match: .name, text: place.displayName(localLanguage: localLanguage))]
            for other in [place.alternateName(localLanguage: localLanguage), place.formalName].compactMap({ $0 }) {
                fields.append(Field(match: .otherName(other), text: other))
            }
            for name in deck.capitals(of: place).flatMap(\.names) {
                fields.append(Field(match: .capital(name), text: name))
            }
            for (kind, code) in deck.codes(of: place) {
                for single in code.components(separatedBy: PlaceCodes.separator) {
                    fields.append(Field(kind: kind, code: single))
                }
            }
            if hasRegions, let group = groups[place.groupID] {
                let shown = group.displayName(localLanguage: localLanguage)
                for name in Set([group.name, group.localName].compactMap { $0 }) {
                    fields.append(Field(match: .region(shown), text: name))
                }
            }
            return Entry(result: Result(place: place, index: index, match: .name), fields: fields)
        }
        // The runs the deck's own row is marked out by, so the list before a search matches it.
        regions = deck.sections.map { section in
            Region(
                name: deck.showsRegions ? section.name(localLanguage: localLanguage) : nil,
                places: section.range.map { entries[$0].result })
        }
    }

    /// The places matching a search, best first, then in Learn's order. Empty for an empty search.
    func results(for query: String) -> [Result] {
        let needle = Needle(query)
        guard !needle.text.isEmpty else { return [] }
        var found: [(rank: Int, result: Result)] = []
        for entry in entries {
            // A place's names before its capitals, codes and region, where they match as well.
            var best: (rank: Int, match: Match)?
            for field in entry.fields {
                guard let rank = field.rank(matching: needle), rank < (best?.rank ?? .max) else { continue }
                best = (rank, field.match)
                if rank == 0 { break }
            }
            if let best {
                var result = entry.result
                result.match = best.match
                found.append((best.rank, result))
            }
        }
        if found.isEmpty { return prefixed(by: needle) }
        // Matching as well, places by name before places by code, so "a" lists Albania before AF.
        found.sort { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.result.match.isCode != rhs.result.match.isCode { return !lhs.result.match.isCode }
            return lhs.result.index < rhs.result.index
        }
        return found.map(\.result)
    }

    /// Where nothing else matches, the places whose prefix a longer code begins with: an airport
    /// code or aircraft registration, a phone number, or a postcode. Of prefixes that nest, such
    /// as Hokkaido's 011 inside 01, the longest wins.
    private func prefixed(by needle: Needle) -> [Result] {
        let plain = needle.plain
        guard plain.count >= 3 else { return [] }
        let isDigits = plain.allSatisfy(\.isNumber)
        var found: [MapGame.CodeKind: [(length: Int, result: Result)]] = [:]
        for entry in entries {
            for field in entry.fields {
                guard case .code(let kind, _) = field.match, !field.key.isEmpty, plain.count > field.key.count,
                      plain.hasPrefix(field.key) else { continue }
                let applies = switch kind {
                // ICAO codes are four letters, such as RJTT for Haneda.
                case .airport: plain.count == 4 && !isDigits && plain.allSatisfy(\.isLetter)
                // Registrations carry a dash or numbers, such as G-EUPT or JA8089.
                case .aircraft: needle.text.contains("-") || plain.contains(where: \.isNumber)
                case .phone, .postcode: isDigits
                // French postcodes begin with their department's number.
                case .number: isDigits && plain.count == 5 && entry.result.place.countryID == "FR"
                default: false
                }
                guard applies else { continue }
                var result = entry.result
                result.match = field.match
                found[kind, default: []].append((field.key.count, result))
            }
        }
        let longest = found.values.flatMap { matches in
            let length = matches.map(\.length).max() ?? 0
            return matches.filter { $0.length == length }.map(\.result)
        }
        // A place found by two prefixes shows once.
        var seen: Set<String> = []
        return longest.sorted { $0.index < $1.index }.filter { seen.insert($0.id).inserted }
    }

    /// One place and everything it can be found by.
    private struct Entry {
        var result: Result
        var fields: [Field]
    }

    /// Something a place can be found by, folded once for comparing.
    private struct Field {
        var match: Match
        var key: String
        var words: [Substring]

        /// A name: a place's, a capital's or a region's.
        init(match: Match, text: String) {
            self.match = match
            key = Needle.fold(text)
            words = key.split { !$0.isLetter && !$0.isNumber }
        }

        /// A code, without its marks, such as 81 for +81; a time zone keeps its sign, UTC+9.
        init(kind: MapGame.CodeKind, code: String) {
            match = .code(kind, code)
            let folded = Needle.fold(code)
            key = kind == .timeZone ? Needle.zone(folded) : Needle.plain(folded)
            words = []
        }

        /// How well a search matches: 0 whole, 1 from the start, 2 from a later word's start, 3
        /// anywhere inside a name, and 4 a region's places. Codes match whole or from the start
        /// only, so 1 doesn't find every code with a 1 in it. Nil for no match.
        func rank(matching needle: Needle) -> Int? {
            switch match {
            case .code(let kind, _):
                let typed = kind == .timeZone ? needle.zone : needle.plain
                guard !typed.isEmpty else { return nil }
                return key == typed ? 0 : key.hasPrefix(typed) ? 1 : nil
            case .region:
                // A single letter would find nearly every place this way.
                guard needle.text.count >= 2 else { return nil }
                return key.hasPrefix(needle.text) || words.contains { $0.hasPrefix(needle.text) } ? 4 : nil
            case .name, .otherName, .capital:
                if key == needle.text { return 0 }
                if key.hasPrefix(needle.text) { return 1 }
                if words.contains(where: { $0.hasPrefix(needle.text) }) { return 2 }
                // A single letter would be inside nearly every name, but one character of a script
                // such as Japanese or Chinese can be telling, such as the 京 in 東京.
                guard needle.text.count >= 2 || !needle.text.unicodeScalars.allSatisfy(\.isASCII) else { return nil }
                return key.contains(needle.text) ? 3 : nil
            }
        }
    }

    /// A search, folded each way it's compared.
    private struct Needle {
        /// For names.
        var text: String
        /// For codes, without their marks.
        var plain: String
        /// For time zones, keeping their sign, GMT read as UTC.
        var zone: String

        init(_ query: String) {
            text = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
            plain = Self.plain(text)
            zone = Self.zone(text)
        }

        /// Lowercased, without accents, with full-width letters made plain and a minus sign as a dash.
        static func fold(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
                .replacingOccurrences(of: "−", with: "-")
        }

        /// Letters and numbers alone, such as jp for .jp.
        static func plain(_ text: String) -> String {
            String(text.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
        }

        /// Without spaces, and GMT as UTC, such as utc+9 for "GMT + 9". UTC itself, written
        /// UTC±0, is found however it's typed: utc, utc0, utc+0, gmt-0.
        static func zone(_ text: String) -> String {
            let joined = text.filter { !$0.isWhitespace }
            let utc = joined.hasPrefix("gmt") ? "utc" + joined.dropFirst(3) : joined
            return ["utc±0", "utc+0", "utc-0", "utc0"].contains(utc) ? "utc" : utc
        }
    }
}
