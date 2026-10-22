import SwiftUI

/// The ways to quiz yourself on a map. Map, Flag, Capital, Outline and Code each go both ways,
/// sharing a tile in the lobby: identify the place from where it is, its flag, capital, outline or
/// code, or identify where a place is, or its flag, capital, outline or code. Map's own way, with
/// the borders hidden, is Dot.
enum MapGameMode: String, CaseIterable, Identifiable {
    // Saved by these names, from before the modes were renamed; keep them unchanged.
    /// Identify: a place lights up on the map, and you type or pick its name.
    case nameIt
    /// Find: you're given a place's name, and tap it on the map.
    case findIt
    /// Flag: you're shown a place's flag, and pick its name.
    case flags
    /// Flag the other way: you're given a place, lit up on the map, and pick its flag.
    case pickFlag
    /// Capital: you're given a place, and type or pick its capital.
    case capitals
    /// Whose capital?: you're given a capital, and type or pick the place it's the capital of.
    case whoseCapital
    /// Outline: you're shown a place's shape alone, and type or pick its name.
    case outline
    /// Outline the other way: you're given a place, and pick its shape.
    case pickOutline
    /// Code: you're shown a place's code, such as DE, .jp or +44, and type or pick the place.
    case code
    /// Code the other way: you're given a place, lit up on the map, and type or pick its code.
    case pickCode
    /// Dot: one dot marks a place on a plain map, and you type or pick its name.
    case dot
    /// List All: every place in play, typed in any order, each filling in on the map as it's named.
    case listAll
    /// Everything: on the World, the states, provinces and regions of the countries in play, each
    /// lighting up on the World map with its country's own borders drawn in, to name.
    case everything
    /// Member?: for a group of countries, such as the EU, a country lights up and you say whether
    /// it's in or out.
    case member

    var id: Self { self }

    /// The lobby's tiles, in order: one for each topic, for both its ways round.
    static let tiles: [MapGameMode] = [.nameIt, .flags, .capitals, .outline, .code, .listAll, .everything, .member]

    /// The tile it's played from: its own, or for Find and Dot, Map's, and for the other way round
    /// of Flag, Capital, Outline or Code, theirs.
    var tile: MapGameMode {
        switch self {
        case .findIt, .dot: .nameIt
        case .pickFlag: .flags
        case .whoseCapital: .capitals
        case .pickOutline: .outline
        case .pickCode: .code
        default: self
        }
    }

    /// The ways a tile plays, identifying the place first, then identifying where it is, or its
    /// flag, capital, outline or code. Dot isn't one of Map's: it's Map with the borders hidden.
    var directions: [MapGameMode] {
        switch self {
        case .nameIt: [.nameIt, .findIt]
        case .flags: [.flags, .pickFlag]
        case .capitals: [.whoseCapital, .capitals]
        case .outline: [.outline, .pickOutline]
        case .code: [.code, .pickCode]
        default: [self]
        }
    }

    /// Whether it identifies the place, from where it is on the map, its flag, capital, outline or
    /// code, where its tile goes both ways; otherwise it identifies where the place is, or its flag,
    /// capital, outline or code.
    var identifiesPlace: Bool {
        [.nameIt, .dot, .flags, .whoseCapital, .outline, .code].contains(self)
    }

    /// Whether its board can be played with the borders hidden: Map either way round.
    var hidesBorders: Bool {
        tile == .nameIt
    }

    var name: String {
        switch self {
        case .nameIt, .findIt, .dot: "Map"
        case .flags, .pickFlag: "Flag"
        case .capitals, .whoseCapital: "Capital"
        case .outline, .pickOutline: "Outline"
        case .code, .pickCode: "Code"
        case .listAll: "List all"
        case .everything: "Everything"
        case .member: "Member?"
        }
    }

    /// Which way round it plays, where its tile goes both ways, as its toggle says it: Map's Identify
    /// or Find, and for the rest, under Identify, the place, or its flag, capital, outline or code.
    var directionName: String {
        switch self {
        case .nameIt, .dot: "Identify"
        case .findIt: "Find"
        case .flags, .whoseCapital, .outline, .code: "Place"
        case .pickFlag: "Flag"
        case .capitals: "Capital"
        case .pickOutline: "Outline"
        case .pickCode: "Code"
        default: name
        }
    }

    /// The heading over a tile's ways round: Map's are ways to play; the rest's, what to identify.
    var directionsTitle: String {
        self == .nameIt ? "Mode" : "Identify"
    }

    var symbolName: String {
        switch self {
        case .nameIt, .findIt, .dot: "map.fill"
        case .flags, .pickFlag: "flag.fill"
        case .capitals, .whoseCapital: "building.columns.fill"
        case .outline, .pickOutline: "lasso"
        case .code, .pickCode: "barcode"
        case .listAll: "checklist"
        case .everything: "square.grid.3x3.fill"
        case .member: "person.text.rectangle.fill"
        }
    }

    /// The symbol for which way round it plays, beside its name where its tile goes both ways.
    var directionSymbolName: String {
        switch self {
        case .findIt: "hand.tap.fill"
        default: identifiesPlace ? "mappin.and.ellipse" : symbolName
        }
    }

    /// The candy colour the mode wears: its tile, its progress bar, and in Identify, the place in question.
    var color: Color {
        switch self {
        case .nameIt, .findIt, .dot: LevelColor.lightBlue.color
        case .flags, .pickFlag: LevelColor.purple.color
        case .capitals, .whoseCapital: LevelColor.orange.color
        case .outline, .pickOutline: LevelColor.mint.color
        case .code, .pickCode: LevelColor.blue.color
        // Green, as the map fills in as each place is named.
        case .listAll: LevelColor.green.color
        // A deep gold, for the biggest quiz of all.
        case .everything: Color(red: 0.86, green: 0.6, blue: 0.05)
        // Caramel, apart from the rest, for the one quiz that's only for groups.
        case .member: LevelColor.brown.color
        }
    }

    /// The ways of answering it can take, as the lobby offers them: typed, four to pick from, or
    /// every one in play. None for Find, Member? and List All, which have their own.
    var answerStyles: [MapGame.AnswerStyle] {
        switch self {
        case .nameIt, .capitals, .whoseCapital, .outline, .code, .dot: [.type, .four, .all]
        // A flag or a shape can't be typed.
        case .flags, .pickFlag, .pickOutline: [.four, .all]
        case .pickCode: [.type, .four, .all]
        // Every state and province on a continent is too many to deal four from fairly: they're
        // typed, with Auto-fill to offer the nearest, or picked from them all, narrowed by typing.
        case .everything: [.type, .all]
        case .findIt, .member, .listAll: []
        }
    }

    /// Whether typing it can offer the nearest names to pick from as you go, with Auto-fill: where
    /// names are typed, not codes.
    var offersAutoFill: Bool {
        answerStyles.contains(.type) && self != .pickCode
    }

    /// What you do, in a collection's own terms, such as "Type the name of the prefecture that
    /// lights up", for VoiceOver's hint on its tile and beneath its name in the lobby.
    func summary(placeNoun: String, method: MapGame.AnswerMethod) -> String {
        let typing = method == .typing
        return switch self {
        case .nameIt: typing ? "Type the name of the \(placeNoun) that lights up" : "Name the \(placeNoun) that lights up"
        case .findIt: "Find each \(placeNoun) on the map"
        case .flags: "Name the \(placeNoun) each flag belongs to"
        case .pickFlag: "Pick the flag of each \(placeNoun)"
        case .capitals: typing ? "Type the capital of each \(placeNoun)" : "Pick the capital of each \(placeNoun)"
        case .whoseCapital: typing ? "Type the \(placeNoun) each capital belongs to" : "Pick the \(placeNoun) each capital belongs to"
        case .outline: typing ? "Type the name of each \(placeNoun) from its outline" : "Name each \(placeNoun) from its outline"
        case .pickOutline: "Pick the outline of each \(placeNoun)"
        case .code: typing ? "Type the \(placeNoun) each code belongs to" : "Pick the \(placeNoun) each code belongs to"
        case .pickCode: typing ? "Type the code of each \(placeNoun)" : "Pick the code of each \(placeNoun)"
        case .dot: typing ? "Type the name of the \(placeNoun) marked with a dot" : "Name the \(placeNoun) marked with a dot"
        case .listAll: "Type every \(placeNoun) you can, in any order"
        case .everything: "Type the name of each state, province or region that lights up"
        case .member: "Say whether each \(placeNoun) that lights up is a member"
        }
    }
}
