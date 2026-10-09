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

    private static func singular(of plural: String) -> String {
        if plural.hasSuffix("ies") { return String(plural.dropLast(3)) + "y" }
        if ["ches", "shes", "sses", "xes"].contains(where: plural.hasSuffix) { return String(plural.dropLast(2)) }
        if plural.hasSuffix("s") { return String(plural.dropLast()) }
        return plural
    }
}
