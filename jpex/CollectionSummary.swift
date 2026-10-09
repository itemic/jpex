import Foundation

/// How far through a country's subdivisions the person is, for linking to that collection.
struct CollectionSummary {
    var label: String
    var counted: Int
    var total: Int
    var strongestStatus: VisitLevel
    /// How many places sit at each level, by level ID, for a stacked bar.
    var tally: [String: Int]
    var minimumStatus: VisitLevel

    init(collection: Country, snapshot: TravelSnapshot, rules: CountingRules) {
        label = collection.divisionLabel
        counted = snapshot.count(in: collection.divisions, counting: rules)
        total = collection.divisions.count
        strongestStatus = snapshot.strongestStatus(in: collection.divisions)
        tally = snapshot.tally(of: collection.divisions)
        minimumStatus = rules.minimumLevel(in: snapshot.ladder)
    }
}
