import Foundation

/// How a country with lists of its places' own subdivisions, such as Australia with Tasmania's
/// local government areas, counts at either level, as France does its regions and departments:
/// the level shown named above the total, the other a small card beside it. On the country's list,
/// that card opens a menu of the places with lists of their own; on one of those lists, it goes
/// back up to the country's places.
enum SubdivisionLevels {
    /// The kind of places a list's total counts, named above it where its country has lists of its
    /// places' own subdivisions, such as States & territories or Local government areas. Nil on
    /// every other list.
    static func label(of collection: Country) -> String? {
        CountryCatalog.subdivisionLists(of: collection).isEmpty ? nil : collection.divisionLabel
    }

    /// The same, shorter, for a phone, where it has a short name, such as LGAs.
    static func shortLabel(of collection: Country) -> String? {
        label(of: collection).flatMap { CountryCatalog.shortLevelLabels[$0] }
    }

    /// The other level, as a small card beside the total. None for any other list.
    @MainActor static func switches(
        for collection: Country, snapshot: TravelSnapshot, rules: CountingRules,
        onOpen: @escaping (String) -> Void, onSwitch: @escaping (String) -> Void
    ) -> [LevelSwitch] {
        let lists = CountryCatalog.subdivisionLists(of: collection)
        guard !lists.isEmpty, let country = CountryCatalog.country(id: collection.countryListID) else { return [] }
        if collection.parentPlace != nil {
            return [
                LevelSwitch(
                    id: country.id, title: country.divisionLabel, shortTitle: CountryCatalog.shortLevelLabels[country.divisionLabel],
                    counted: snapshot.count(in: country.divisions, counting: rules), total: country.divisions.count,
                    map: TravelMap.named(country.id),
                    statuses: Dictionary(country.divisions.map { ($0.id, snapshot.status(for: $0)) }) { first, _ in first },
                    action: { onSwitch(country.id) })
            ]
        }
        // Every place's subdivisions together, each place on the country's map in the strongest
        // level reached in it.
        let subdivisions = lists.flatMap(\.divisions)
        let label = CountryCatalog.subdivisionLabel(of: collection) ?? ""
        return [
            LevelSwitch(
                id: "\(country.id)-subdivisions", title: label, shortTitle: CountryCatalog.shortLevelLabels[label],
                counted: snapshot.count(in: subdivisions, counting: rules), total: subdivisions.count,
                map: TravelMap.named(country.id),
                statuses: Dictionary(lists.compactMap { list in
                    list.parentPlace.map { ($0.id, snapshot.strongestStatus(in: list.divisions)) }
                }) { first, _ in first },
                choices: lists.map { list in
                    LevelMenuChoice(
                        id: list.id, title: list.name, counted: snapshot.count(in: list.divisions, counting: rules),
                        total: list.divisions.count, action: { onOpen(list.id) })
                })
        ]
    }
}
