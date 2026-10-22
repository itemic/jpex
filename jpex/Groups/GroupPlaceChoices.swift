import Foundation

/// What a group's editor offers to choose from: every country as the person counts them, under
/// their continents, along with any member they don't count, and the level they've reached in each.
struct GroupPlaceChoices {
    var continents: [DivisionGroup]
    /// Every place, in the order they're shown.
    var places: [AdministrativeDivision]
    /// Each place's level, by place ID.
    private var levels: [String: VisitLevel]

    /// The choices for a group starting with these members, so a member the person doesn't count
    /// as a country, such as a territory switched off, can still be seen and taken out.
    init(rules: CountingRules, snapshot: TravelSnapshot, members: Set<String>) {
        let counted = Set(CountryCatalog.world(applying: rules).divisions.map(\.id))
        let offered = CountryCatalog.groupablePlaces(applying: rules).filter {
            counted.contains($0.id) || members.contains($0.id)
        }
        continents = CountryCatalog.continents(of: offered)
        places = continents.flatMap(\.divisions)
        levels = Dictionary(places.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first }
    }

    func level(of place: AdministrativeDivision) -> VisitLevel {
        levels[place.id] ?? .never
    }

    /// The places at exactly this level.
    func places(at level: VisitLevel) -> [AdministrativeDivision] {
        places.filter { levels[$0.id]?.id == level.id }
    }

    /// The places that count as having been, from the level counting starts at.
    func placesBeen(rules: CountingRules, ladder: VisitLadder) -> [AdministrativeDivision] {
        places.filter { rules.counts(level(of: $0), in: ladder) }
    }

    /// The continents with only the places whose names hold what's been typed, and when asked,
    /// only the places chosen.
    func continents(matching query: String, within chosen: Set<String>? = nil) -> [DivisionGroup] {
        let typed = Self.folded(query)
        return continents.compactMap { continent in
            var group = continent
            group.divisions = continent.divisions.filter { place in
                guard chosen?.contains(place.id) ?? true else { return false }
                return typed.isEmpty
                    || [place.name, place.localName].contains { $0.map { Self.folded($0).contains(typed) } ?? false }
            }
            return group.divisions.isEmpty ? nil : group
        }
    }

    /// A name as it'd be typed: without case or accents.
    static func folded(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespaces).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
