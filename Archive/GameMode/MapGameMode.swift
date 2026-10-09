import SwiftUI

/// The two ways to play Game Mode.
enum MapGameMode: String, CaseIterable, Identifiable {
    /// A place lights up on the map, and you pick its name from four.
    case nameIt
    /// You're given a place's name, and tap it on the map.
    case findIt

    var id: Self { self }

    var name: String {
        switch self {
        case .nameIt: "Name It"
        case .findIt: "Find It"
        }
    }

    var symbolName: String {
        switch self {
        case .nameIt: "questionmark.bubble.fill"
        case .findIt: "hand.tap.fill"
        }
    }

    /// The candy colour the mode wears: its tile, its progress bar, and in Name It, the place in question.
    var color: Color {
        switch self {
        case .nameIt: LevelColor.lightBlue.color
        case .findIt: LevelColor.pink.color
        }
    }

    /// What you do, in a collection's own terms, such as "Name the prefecture that lights up".
    func summary(placeNoun: String) -> String {
        switch self {
        case .nameIt: "Name the \(placeNoun) that lights up"
        case .findIt: "Find each \(placeNoun) on the map"
        }
    }
}
