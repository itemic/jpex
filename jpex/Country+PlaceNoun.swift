import Foundation

extension Country {
    /// One of the places it lists, lowercased to sit in a sentence: "prefecture" for Prefectures,
    /// "state or territory" for States & territories.
    var placeNoun: String {
        divisionLabel
            .components(separatedBy: " & ")
            .map { Self.singular(of: $0.lowercased()) }
            .joined(separator: " or ")
    }

    /// What one place in a group is called, for a group named for its kind of place: "State" for
    /// one of the States, "Union territory" for one of the Union territories. Groups named for
    /// where they are, such as Kantō or Europe, keep their name.
    static func memberName(ofGroup name: String) -> String {
        var words = name.components(separatedBy: " ")
        guard let last = words.last, kindsOfPlace.contains(last.lowercased()) else { return name }
        let singular = singular(of: last.lowercased())
        words[words.count - 1] = last.first?.isUppercase == true ? singular.capitalized : singular
        return words.joined(separator: " ")
    }

    /// Plural nouns for kinds of place, as groups of them are named.
    private static let kindsOfPlace: Set<String> = [
        "states", "territories", "provinces", "regions", "districts", "municipalities", "counties", "prefectures",
        "cantons", "departments", "oblasts", "republics", "krais", "okrugs", "emirates", "governorates", "cities",
        "divisions", "dependencies", "parishes", "voivodeships", "län", "communities", "entities",
    ]

    /// The first kind of place it lists, for a title with no room for "or": "state" for States &
    /// territories, "prefecture" for Prefectures.
    var shortPlaceNoun: String {
        placeNoun.components(separatedBy: " or ").first ?? placeNoun
    }

    private static func singular(of plural: String) -> String {
        if plural.hasSuffix("ies") { return String(plural.dropLast(3)) + "y" }
        if ["ches", "shes", "sses", "xes"].contains(where: plural.hasSuffix) { return String(plural.dropLast(2)) }
        if plural.hasSuffix("s") { return String(plural.dropLast()) }
        return plural
    }
}
