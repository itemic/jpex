import SwiftUI

/// The ways to quiz yourself on a map.
enum MapGameMode: String, CaseIterable, Identifiable {
    // Saved by these names, from before the modes were renamed; keep them unchanged.
    /// Identify: a place lights up on the map, and you type or pick its name.
    case nameIt
    /// Find: you're given a place's name, and tap it on the map.
    case findIt
    /// Flag: you're shown a place's flag, and pick its name.
    case flags
    /// Capital: you're given a place, and type or pick its capital.
    case capitals
    /// Outline: you're shown a place's shape alone, and type or pick its name.
    case outline
    /// Code: you're shown a place's code, such as DE, .jp or +44, and type or pick the place.
    case code
    /// Dot: one dot marks a place on a plain map, and you type or pick its name.
    case dot
    /// Member?: for a group of countries, such as the EU, a country lights up and you say whether
    /// it's in or out.
    case member

    var id: Self { self }

    var name: String {
        switch self {
        case .nameIt: "Identify"
        case .findIt: "Find"
        case .flags: "Flag"
        case .capitals: "Capital"
        case .outline: "Outline"
        case .code: "Code"
        case .dot: "Dot"
        case .member: "Member?"
        }
    }

    var symbolName: String {
        switch self {
        case .nameIt: "questionmark.bubble.fill"
        case .findIt: "hand.tap.fill"
        case .flags: "flag.fill"
        case .capitals: "building.columns.fill"
        case .outline: "lasso"
        case .code: "barcode"
        case .dot: "smallcircle.filled.circle.fill"
        case .member: "person.text.rectangle.fill"
        }
    }

    /// The candy colour the mode wears: its tile, its progress bar, and in Identify, the place in question.
    var color: Color {
        switch self {
        case .nameIt: LevelColor.lightBlue.color
        case .findIt: LevelColor.pink.color
        case .flags: LevelColor.purple.color
        case .capitals: LevelColor.orange.color
        case .outline: LevelColor.mint.color
        case .code: LevelColor.blue.color
        case .dot: LevelColor.lime.color
        // Caramel, apart from the rest, for the one quiz that's only for groups.
        case .member: LevelColor.brown.color
        }
    }

    /// Whether it can be answered by typing as well as from a list.
    var canBeTyped: Bool {
        self != .findIt && self != .flags && self != .member
    }

    /// Whether the lobby's answer style applies: typed, four to pick from, or all. Flag takes only
    /// the last two, and Find and Member? have their own ways to answer.
    var takesAnswerStyle: Bool {
        self != .findIt && self != .member
    }

    /// What you do, in a collection's own terms, such as "Type the name of the prefecture that
    /// lights up", for VoiceOver's hint on its tile.
    func summary(placeNoun: String, method: MapGame.AnswerMethod) -> String {
        let typing = method == .typing
        return switch self {
        case .nameIt: typing ? "Type the name of the \(placeNoun) that lights up" : "Name the \(placeNoun) that lights up"
        case .findIt: "Find each \(placeNoun) on the map"
        case .flags: "Name the \(placeNoun) each flag belongs to"
        case .capitals: typing ? "Type the capital of each \(placeNoun)" : "Pick the capital of each \(placeNoun)"
        case .outline: typing ? "Type the name of each \(placeNoun) from its outline" : "Name each \(placeNoun) from its outline"
        case .code: typing ? "Type the \(placeNoun) each code belongs to" : "Pick the \(placeNoun) each code belongs to"
        case .dot: typing ? "Type the name of the \(placeNoun) marked with a dot" : "Name the \(placeNoun) marked with a dot"
        case .member: "Say whether each \(placeNoun) that lights up is a member"
        }
    }
}
