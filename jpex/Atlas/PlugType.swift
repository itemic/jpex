import SwiftUI

/// One of the IEC's lettered kinds of mains plug and socket, from A, the two flat pins of North
/// America and Japan, to O, Thailand's three round pins.
enum PlugType: String, CaseIterable, Identifiable {
    case a = "A", b = "B", c = "C", d = "D", e = "E", f = "F", g = "G", h = "H"
    case i = "I", j = "J", k = "K", l = "L", m = "M", n = "N", o = "O"

    var id: Self { self }

    var key: MapKey {
        MapKey(id: rawValue, name: rawValue, color: color, spokenName: "Type \(rawValue) plugs", plug: self)
    }

    /// What it's known as, from where it began or the standard it's named for.
    var origin: String {
        switch self {
        case .a: "American"
        case .b: "American 3-pin"
        case .c: "Europlug"
        case .d: "Indian"
        case .e: "French"
        case .f: "Schuko"
        case .g: "British"
        case .h: "Israeli"
        case .i: "Australian"
        case .j: "Swiss"
        case .k: "Danish"
        case .l: "Italian"
        case .m: "South African"
        case .n: "Brazilian"
        case .o: "Thai"
        }
    }

    /// Kinds of plug that fit one another's sockets share a family of colours: blues for North
    /// America's flat pins, greens for Europe's round ones, browns for the large round pins of
    /// India and southern Africa.
    var color: Color {
        switch self {
        case .a: LevelColor.lightBlue.color
        case .b: LevelColor.blue.color
        case .c: LevelColor.lime.color
        case .d: LevelColor.brown.color
        case .e: LevelColor.mint.color
        case .f: LevelColor.green.color
        case .g: LevelColor.purple.color
        case .h: LevelColor.pink.color
        case .i: LevelColor.orange.color
        case .j: LevelColor.red.color
        case .k: LevelColor.yellow.color
        case .l: LevelColor.indigo.color
        case .m: Color(red: 0.72, green: 0.55, blue: 0.38)
        case .n: Color.teal
        case .o: Color.cyan
        }
    }
}
