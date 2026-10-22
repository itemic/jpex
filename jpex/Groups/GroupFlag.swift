import SwiftUI

/// A badge for a group of the person's own drawn as a flag, such as a tricolour or a Nordic
/// cross, in colours from a flag-maker's palette, with the group's symbol over it if it has one.
struct GroupFlag: Codable, Hashable, Sendable {
    var pattern: FlagPattern
    /// Three colours, always: each pattern paints as many of them as it has parts, in order, so
    /// moving from one pattern to another keeps the colours chosen.
    var colors: [FlagColor]
    /// The colour of the group's one symbol, for a design saved before a flag could carry several.
    var symbolColor: FlagColor = .white
    /// The symbols on the flag, each in a spot of its own. Nil for a design saved before a flag could
    /// carry several, whose one symbol is the group's own, in `symbolColor`, wherever suits.
    var symbols: [FlagSymbol]? = nil

    init(pattern: FlagPattern, colors: [FlagColor], symbolColor: FlagColor = .white, symbols: [FlagSymbol]? = nil) {
        self.pattern = pattern
        self.colors = colors
        self.symbolColor = symbolColor
        self.symbols = symbols
        while self.colors.count < 3 { self.colors.append(Self.fallbackColors[self.colors.count]) }
    }

    /// The design with its symbols spelt out: its own, or the group's one symbol from before.
    func resolvingSymbols(fallback symbolName: String) -> GroupFlag {
        var flag = self
        if flag.symbols == nil {
            flag.symbols = symbolName.isEmpty ? [] : [FlagSymbol(name: symbolName, color: symbolColor)]
        }
        return flag
    }

    // MARK: Symbols

    /// Where each symbol sits: in the spot chosen for it, or for one left to the flag, the best
    /// spot for the pattern still free, such as the canton of a flag that has one.
    var placements: [(symbol: FlagSymbol, area: FlagArea)] {
        let list = symbols ?? []
        var taken = Set(list.compactMap(\.area))
        var free = pattern.preferredAreas.filter { !taken.contains($0) }.makeIterator()
        return list.map { symbol in
            if let area = symbol.area { return (symbol, area) }
            let area = free.next() ?? .centre
            taken.insert(area)
            return (symbol, area)
        }
    }

    /// Where a spot is, as a share of the flag's width and height: the middle of the part of the
    /// pattern there, such as the canton, a band at the hoist or the crossing of a cross.
    func anchor(of area: FlagArea) -> CGPoint {
        var xs: [CGFloat] = [1 / 6, 1 / 2, 5 / 6]
        var ys: [CGFloat] = [1 / 4, 1 / 2, 3 / 4]
        switch pattern {
        case .horizontalTricolor: ys = [1 / 6, 1 / 2, 5 / 6]
        case .verticalBicolor: xs = [1 / 4, 1 / 2, 3 / 4]
        case .centreBand: ys = [1 / 8, 1 / 2, 7 / 8]
        case .pale: xs = [1 / 8, 1 / 2, 7 / 8]
        case .hoistBand: xs[0] = 1 / 8
        case .triangle: xs[0] = 0.15
        case .nordicCross, .borderedCross:
            xs = [0.15, 0.36, 0.71]
            ys = [0.2, 0.5, 0.8]
        case .cross:
            xs = [0.22, 0.5, 0.78]
            ys = [0.2, 0.5, 0.8]
        case .quartered, .canton: xs = [1 / 4, 1 / 2, 3 / 4]
        case .stripesAndCanton:
            xs[0] = 0.21
            ys[0] = 2 / 7
        case .diagonal, .diagonalBand:
            xs = [0.22, 0.5, 0.78]
        default: break
        }
        return CGPoint(x: xs[area.column], y: ys[area.row])
    }

    /// How tall a symbol stands in a spot, as a share of the flag's height: large in the middle,
    /// smaller elsewhere, and kept within a band, a disc or a canton.
    func symbolScale(at area: FlagArea, count: Int) -> CGFloat {
        let scale: CGFloat = switch (pattern, area) {
        case (.disc, .centre), (.diamond, .centre), (.centreBand, .centre), (.verticalTricolor, .centre), (.cross, .centre): 0.42
        case (.roundel, .centre), (.horizontalTricolor, .centre), (.fiveStripes, .centre): 0.3
        case (_, .centre): 0.52
        case (.canton, .topHoist), (.stripesAndCanton, .topHoist), (.quartered, _): 0.36
        case (.hoistBand, .topHoist), (.hoistBand, .hoist), (.hoistBand, .bottomHoist), (.triangle, .hoist),
            (.nordicCross, _), (.borderedCross, _):
            0.28
        default: 0.32
        }
        // Several share the flag, so none crowds the rest.
        return count > 2 ? min(scale, 0.36) : scale
    }

    /// Which of the pattern's colours is at a point, given as a share of the width and height.
    func partIndex(at point: CGPoint) -> Int {
        let u = point.x
        let v = point.y
        switch pattern {
        case .plain: return 0
        case .horizontalBicolor: return v < 0.5 ? 0 : 1
        case .verticalBicolor: return u < 0.5 ? 0 : 1
        case .horizontalTricolor: return v < 1 / 3 ? 0 : v < 2 / 3 ? 1 : 2
        case .verticalTricolor: return u < 1 / 3 ? 0 : u < 2 / 3 ? 1 : 2
        case .centreBand: return (0.25...0.75).contains(v) ? 1 : 0
        case .pale: return (0.25...0.75).contains(u) ? 1 : 0
        case .fiveStripes: return (1 / 3...2 / 3).contains(v) ? 2 : (1 / 6...5 / 6).contains(v) ? 1 : 0
        case .stripes: return Int(v * 7) % 2
        case .hoistBand: return u < 0.25 ? 0 : v < 0.5 ? 1 : 2
        case .nordicCross: return abs(u - 0.36) < 0.067 || abs(v - 0.5) < 0.1 ? 1 : 0
        case .borderedCross:
            if abs(u - 0.36) < 0.043 || abs(v - 0.5) < 0.065 { return 2 }
            return abs(u - 0.36) < 0.087 || abs(v - 0.5) < 0.13 ? 1 : 0
        case .cross: return abs(u - 0.5) < 0.067 || abs(v - 0.5) < 0.1 ? 1 : 0
        case .saltire: return abs(v - u) < 0.12 || abs(u + v - 1) < 0.12 ? 1 : 0
        case .quartered: return (u < 0.5) == (v < 0.5) ? 0 : 1
        case .diagonal: return u + v < 1 ? 0 : 1
        case .diagonalBand: return abs(u + v - 1) < 0.19 ? 1 : u + v < 1 ? 0 : 2
        case .triangle: return u < 0.45 * (1 - abs(2 * v - 1)) ? 2 : v < 0.5 ? 0 : 1
        case .canton: return u < 0.5 && v < 0.5 ? 1 : 0
        case .stripesAndCanton: return u < 0.42 && v < 4 / 7 ? 2 : Int(v * 7) % 2
        case .border: return u < 0.08 || u > 0.92 || v < 0.12 || v > 0.88 ? 1 : 0
        case .disc, .roundel:
            let distance = hypot((u - 0.5) * 1.5, v - 0.5)
            if pattern == .roundel { return distance < 0.2 ? 2 : distance < 0.4 ? 1 : 0 }
            return distance < 0.3 ? 1 : 0
        case .diamond: return abs(u - 0.5) / 0.42 + abs(v - 0.5) / 0.4 <= 1 ? 1 : 0
        case .chequered: return (Int(v * 4) + Int(u * 6)) % 2
        }
    }

    /// A symbol colour that stands out from what lies beneath a spot.
    func contrastingColor(at area: FlagArea) -> FlagColor {
        let background = color(at: partIndex(at: anchor(of: area)))
        return background.isLight ? .navy : .white
    }

    /// Adds a symbol where it suits the pattern best, in a colour that stands out there.
    mutating func addSymbol(named name: String) -> FlagSymbol {
        var symbol = FlagSymbol(name: name, color: .white)
        var list = symbols ?? []
        list.append(symbol)
        symbols = list
        if let area = placements.last?.area {
            symbol.color = contrastingColor(at: area)
            list[list.count - 1] = symbol
            symbols = list
        }
        return symbol
    }

    /// A plain flag in the colour nearest one of the levels' colours, to start designing from.
    init(plain tint: LevelColor) {
        self.init(pattern: .plain, colors: [FlagColor(nearest: tint), .white, .red])
    }

    /// The colours a design starts with where it has fewer than three.
    private static let fallbackColors: [FlagColor] = [.blue, .white, .red]

    func color(at index: Int) -> FlagColor {
        colors.indices.contains(index) ? colors[index] : Self.fallbackColors[index % 3]
    }

    /// The colours the pattern paints, in order.
    var usedColors: [FlagColor] {
        (0..<pattern.colorCount).map(color(at:))
    }

    /// The colour beneath the symbol, in the middle of the flag.
    var centerColor: FlagColor {
        color(at: pattern.centerColorIndex)
    }

    /// The group's accent for its cards and buttons: the first colour the flag paints that has
    /// one. White and black have none.
    var accent: LevelColor? {
        usedColors.lazy.compactMap(\.accent).first
    }

    /// A design at random, for Shuffle: any pattern but a plain one, in colours that never meet
    /// themselves, mostly with one of these symbols where it suits, in a colour that stands out.
    static func random(symbols names: [String]) -> GroupFlag {
        let pattern = FlagPattern.allCases.filter { $0 != .plain }.randomElement() ?? .verticalTricolor
        var colors = Array(FlagColor.allCases.shuffled().prefix(3))
        // Most flags light one part against the others, so one of the colours is often white or gold.
        if Bool.random(), !colors.contains(where: \.isLight) {
            colors[Int.random(in: 0..<pattern.colorCount)] = [FlagColor.white, .gold].randomElement() ?? .white
        }
        var flag = GroupFlag(pattern: pattern, colors: colors, symbols: [])
        if Double.random(in: 0..<1) < 0.85, let name = names.randomElement() {
            _ = flag.addSymbol(named: name)
        }
        return flag
    }
}

/// A symbol on a group's flag: which, where and in what colour.
struct FlagSymbol: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var name: String
    /// The spot chosen for it, or nil to leave it to wherever suits the pattern.
    var area: FlagArea? = nil
    var color: FlagColor
}

/// A spot on a flag for a symbol: one of nine, in rows from the top and columns from the hoist,
/// the side by the pole, to the fly.
enum FlagArea: String, CaseIterable, Identifiable, Codable, Sendable {
    // Saved by name, so keep existing names unchanged. Row by row, as read.
    case topHoist, top, topFly, hoist, centre, fly, bottomHoist, bottom, bottomFly

    var id: Self { self }

    var row: Int { (Self.allCases.firstIndex(of: self) ?? 4) / 3 }
    var column: Int { (Self.allCases.firstIndex(of: self) ?? 4) % 3 }

    /// Its name, for VoiceOver.
    var name: String {
        switch self {
        case .topHoist: "Top left"
        case .top: "Top"
        case .topFly: "Top right"
        case .hoist: "Left"
        case .centre: "Centre"
        case .fly: "Right"
        case .bottomHoist: "Bottom left"
        case .bottom: "Bottom"
        case .bottomFly: "Bottom right"
        }
    }
}

extension FlagPattern {
    /// The spots a symbol suits best, best first: the canton where there is one, a band at the
    /// hoist or a triangle, otherwise the middle, then the corners.
    var preferredAreas: [FlagArea] {
        let first: [FlagArea] = switch self {
        case .canton, .stripesAndCanton, .nordicCross, .borderedCross, .diagonal, .diagonalBand: [.topHoist]
        case .quartered: [.topHoist, .bottomFly]
        case .hoistBand, .triangle: [.hoist]
        case .verticalTricolor: [.centre, .hoist, .fly]
        case .horizontalTricolor: [.centre, .top, .bottom]
        default: [.centre]
        }
        let rest: [FlagArea] = [.centre, .topHoist, .bottomFly, .topFly, .bottomHoist, .hoist, .fly, .top, .bottom]
        return first + rest.filter { !first.contains($0) }
    }
}

/// How a flag is divided, after the world's own: bands and stripes, crosses, and shapes such as a
/// diagonal, a canton or a disc. Listed in that order, which is how they're offered.
enum FlagPattern: String, CaseIterable, Identifiable, Codable, Sendable {
    // Saved by name, so keep existing names unchanged; the order here is only the order offered.
    // Bands and stripes.
    case plain, horizontalBicolor, verticalBicolor, horizontalTricolor, verticalTricolor
    case centreBand, pale, fiveStripes, stripes, hoistBand
    // Crosses.
    case nordicCross, borderedCross, cross, saltire, quartered
    // Shapes.
    case diagonal, diagonalBand, triangle, canton, stripesAndCanton, border, disc, roundel, diamond
    case chequered

    var id: Self { self }

    /// A pattern saved by name; one no longer offered, such as Sunburst, comes back plain, so the
    /// group it belongs to still loads.
    init(from decoder: Decoder) throws {
        let name = try decoder.singleValueContainer().decode(String.self)
        self = FlagPattern(rawValue: name) ?? .plain
    }

    var name: String {
        switch self {
        case .plain: "Plain"
        case .horizontalBicolor: "Bicolour"
        case .verticalBicolor: "Vertical bicolour"
        case .horizontalTricolor: "Tricolour"
        case .verticalTricolor: "Vertical tricolour"
        case .centreBand: "Wide band"
        case .pale: "Canadian pale"
        case .fiveStripes: "Five stripes"
        case .stripes: "Stripes"
        case .hoistBand: "Hoist band"
        case .nordicCross: "Nordic cross"
        case .borderedCross: "Bordered cross"
        case .cross: "Cross"
        case .saltire: "Saltire"
        case .quartered: "Quartered"
        case .diagonal: "Diagonal"
        case .diagonalBand: "Diagonal band"
        case .triangle: "Triangle"
        case .canton: "Canton"
        case .stripesAndCanton: "Stripes & canton"
        case .border: "Border"
        case .disc: "Disc"
        case .roundel: "Roundel"
        case .diamond: "Diamond"
        case .chequered: "Chequered"
        }
    }

    /// What each colour paints, in order, such as the field and the cross.
    var partNames: [String] {
        switch self {
        case .plain: ["Colour"]
        case .horizontalBicolor: ["Top", "Bottom"]
        case .verticalBicolor: ["Left", "Right"]
        case .horizontalTricolor: ["Top", "Middle", "Bottom"]
        case .verticalTricolor: ["Left", "Middle", "Right"]
        case .centreBand: ["Outer", "Middle"]
        case .pale: ["Sides", "Middle"]
        case .fiveStripes: ["Outer", "Inner", "Centre"]
        case .stripes: ["Stripes", "Between"]
        case .hoistBand: ["Band", "Top", "Bottom"]
        case .nordicCross, .cross, .saltire: ["Field", "Cross"]
        case .borderedCross: ["Field", "Border", "Cross"]
        case .quartered: ["Quarters", "Between"]
        case .diagonal: ["Upper", "Lower"]
        case .diagonalBand: ["Upper", "Band", "Lower"]
        case .triangle: ["Top", "Bottom", "Triangle"]
        case .canton: ["Field", "Canton"]
        case .stripesAndCanton: ["Stripes", "Between", "Canton"]
        case .border: ["Field", "Border"]
        case .disc: ["Field", "Disc"]
        case .roundel: ["Field", "Ring", "Centre"]
        case .diamond: ["Field", "Diamond"]
        case .chequered: ["Squares", "Between"]
        }
    }

    var colorCount: Int {
        partNames.count
    }

    /// Which colour the middle of the flag is, where the symbol sits.
    var centerColorIndex: Int {
        switch self {
        case .fiveStripes, .borderedCross, .roundel: 2
        case .horizontalTricolor, .verticalTricolor, .centreBand, .pale, .stripes, .hoistBand, .nordicCross, .cross,
            .saltire, .diagonalBand, .stripesAndCanton, .disc, .diamond:
            1
        case .plain, .horizontalBicolor, .verticalBicolor, .quartered, .diagonal, .triangle, .canton, .border,
            .chequered:
            0
        }
    }
}

/// A flag-maker's palette: the deep reds, blues and greens of the world's flags, with gold,
/// white and black, which the levels' own colours don't have.
enum FlagColor: String, CaseIterable, Identifiable, Codable, Sendable {
    // Saved by name, so keep existing names unchanged.
    case red, maroon, orange, gold, green, darkGreen, teal, skyBlue, blue, navy, purple, pink, brown, white, black

    var id: Self { self }

    var color: Color {
        switch self {
        case .red: Color(red: 0.81, green: 0.07, blue: 0.15)
        case .maroon: Color(red: 0.55, green: 0.11, blue: 0.22)
        case .orange: Color(red: 1.00, green: 0.51, blue: 0.00)
        case .gold: Color(red: 1.00, green: 0.80, blue: 0.00)
        case .green: Color(red: 0.00, green: 0.60, blue: 0.27)
        case .darkGreen: Color(red: 0.00, green: 0.40, blue: 0.20)
        case .teal: Color(red: 0.00, green: 0.60, blue: 0.65)
        case .skyBlue: Color(red: 0.45, green: 0.68, blue: 0.87)
        case .blue: Color(red: 0.00, green: 0.33, blue: 0.64)
        case .navy: Color(red: 0.00, green: 0.14, blue: 0.41)
        case .purple: Color(red: 0.40, green: 0.18, blue: 0.56)
        case .pink: Color(red: 0.95, green: 0.55, blue: 0.70)
        case .brown: Color(red: 0.55, green: 0.35, blue: 0.17)
        case .white: .white
        case .black: Color(white: 0.08)
        }
    }

    /// Its name, for VoiceOver.
    var name: String {
        switch self {
        case .red: "Red"
        case .maroon: "Maroon"
        case .orange: "Orange"
        case .gold: "Gold"
        case .green: "Green"
        case .darkGreen: "Dark green"
        case .teal: "Teal"
        case .skyBlue: "Sky blue"
        case .blue: "Blue"
        case .navy: "Navy"
        case .purple: "Purple"
        case .pink: "Pink"
        case .brown: "Brown"
        case .white: "White"
        case .black: "Black"
        }
    }

    /// The levels' colour nearest it, for a group's cards and buttons; none for white and black.
    var accent: LevelColor? {
        switch self {
        case .red, .maroon: .red
        case .orange: .orange
        case .gold: .yellow
        case .green, .darkGreen: .green
        case .teal: .mint
        case .skyBlue: .lightBlue
        case .blue: .blue
        case .navy: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        case .white, .black: nil
        }
    }

    /// Whether it's pale enough that a white symbol would be lost on it.
    var isLight: Bool {
        switch self {
        case .gold, .skyBlue, .pink, .white: true
        default: false
        }
    }

    /// The flag colour nearest one of the levels' colours.
    init(nearest tint: LevelColor) {
        self = switch tint {
        case .red: .red
        case .orange: .orange
        case .yellow: .gold
        case .lime, .green: .green
        case .mint: .teal
        case .lightBlue: .skyBlue
        case .blue: .blue
        case .indigo: .navy
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        case .gray: .black
        }
    }
}
