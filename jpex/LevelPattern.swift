import SwiftUI

/// A bold texture over a level's colour, so levels can be told apart by shading as well as
/// colour: polka dots for the first level, candy-stripe bands like the progress bars for the
/// next, then a checkerboard, holes, bands and more. Each level takes its texture from its place on
/// the ladder, so neighbouring levels always differ.
struct LevelPattern: View {
    var style: LevelPatternStyle
    var color: Color = .white
    /// The size of one repeat of the pattern, in points.
    var cell: CGFloat = 6
    /// The level's symbol, for the pattern that repeats it.
    var symbol: String? = nil

    /// Whether pills and maps show their patterns. Differentiate Without Colour always shows them.
    static let storageKey = "levelPatterns"

    var body: some View {
        Canvas { context, size in
            Self.draw(style, in: context, area: CGRect(origin: .zero, size: size), cell: cell, color: color, symbol: symbol)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Fills an area with the pattern. The pattern hangs from `origin`, so it moves with the shape
    /// it's drawn over. Returns roughly how many marks were drawn, so a busy map can stop early.
    @discardableResult
    static func draw(
        _ style: LevelPatternStyle, in context: GraphicsContext, area: CGRect, origin: CGPoint = .zero,
        cell: CGFloat, color: Color, limit: Int = 4000, symbol: String? = nil
    ) -> Int {
        guard cell > 0, !area.isEmpty, !area.isNull else { return 0 }
        if style == .symbol, let symbol {
            return drawSymbols(symbol, in: context, area: area, origin: origin, cell: cell, color: color, limit: limit)
        }
        let pattern = style.path(in: area, origin: origin, cell: cell, limit: limit)
        if let lineWidth = pattern.lineWidth {
            context.stroke(pattern.path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        } else {
            context.fill(pattern.path, with: .color(color))
        }
        return pattern.marks
    }

    /// The level's own symbol, repeated in staggered rows like the polka dots.
    private static func drawSymbols(
        _ name: String, in context: GraphicsContext, area: CGRect, origin: CGPoint, cell: CGFloat, color: Color, limit: Int
    ) -> Int {
        var image = context.resolve(Image(systemName: name))
        image.shading = .color(color)
        let step = cell * 1.5
        let rowStep = step * 0.88
        let side = cell * 0.95
        var marks = 0
        let firstRow = Int(((area.minY - origin.y) / rowStep).rounded(.down)) - 1
        let lastRow = Int(((area.maxY - origin.y) / rowStep).rounded(.up)) + 1
        outer: for row in firstRow...max(firstRow, lastRow) {
            let shift = row.isMultiple(of: 2) ? 0 : step / 2
            let firstColumn = Int(((area.minX - shift - origin.x) / step).rounded(.down)) - 1
            let lastColumn = Int(((area.maxX - shift - origin.x) / step).rounded(.up)) + 1
            for column in firstColumn...max(firstColumn, lastColumn) {
                let center = CGPoint(x: origin.x + shift + CGFloat(column) * step, y: origin.y + CGFloat(row) * rowStep)
                context.draw(image, in: CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side))
                marks += 1
                if marks >= limit { break outer }
            }
        }
        return marks
    }
}

/// The textures levels wear, one for each place on the ladder. Every one is chunky enough to
/// read at a glance on a small pill.
enum LevelPatternStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    // Saved by name with a level's choice, so keep existing names unchanged.
    case dots, candyStripes, checkerboard, holes, bands, diamonds, crosshatch, zigzag, triangles, columns
    /// The level's own symbol, repeated. Only ever chosen by hand.
    case symbol

    var id: Self { self }

    /// The pattern's name, for a picker and VoiceOver.
    var name: String {
        switch self {
        case .dots: "Polka Dots"
        case .candyStripes: "Candy Stripes"
        case .checkerboard: "Checkerboard"
        case .holes: "Holes"
        case .bands: "Bands"
        case .diamonds: "Diamonds"
        case .crosshatch: "Crosshatch"
        case .zigzag: "Zigzag"
        case .triangles: "Triangles"
        case .columns: "Columns"
        case .symbol: "Symbol"
        }
    }

    /// The texture for the level at this rank, 1 for the lowest level. Never been has none.
    init?(rank: Int) {
        guard rank > 0 else { return nil }
        let automatic = Self.allCases.filter { $0 != .symbol }
        self = automatic[(rank - 1) % automatic.count]
    }

    /// The pattern's marks over an area, and the line width when they're strokes rather than fills.
    func path(in area: CGRect, origin: CGPoint, cell: CGFloat, limit: Int) -> (path: Path, lineWidth: CGFloat?, marks: Int) {
        var path = Path()
        var marks = 0
        // The rows or columns of a grid with this step that touch the area, counted from the origin.
        func range(_ minimum: CGFloat, _ maximum: CGFloat, _ start: CGFloat, step: CGFloat) -> ClosedRange<Int> {
            let first = Int(((minimum - start) / step).rounded(.down)) - 1
            let last = Int(((maximum - start) / step).rounded(.up)) + 1
            return first...max(first, last)
        }
        /// Calls `mark` at the centre of every cell of a staggered grid, every other row shifted by half.
        func honeycomb(step: CGFloat, _ mark: (CGPoint) -> Void) {
            let rowStep = step * 0.88
            outer: for row in range(area.minY, area.maxY, origin.y, step: rowStep) {
                let shift = row.isMultiple(of: 2) ? 0 : step / 2
                for column in range(area.minX - shift, area.maxX - shift, origin.x, step: step) {
                    mark(CGPoint(x: origin.x + shift + CGFloat(column) * step, y: origin.y + CGFloat(row) * rowStep))
                    marks += 1
                    if marks >= limit { break outer }
                }
            }
        }
        switch self {
        case .dots, .symbol:
            honeycomb(step: cell) { center in
                let radius = cell * 0.3
                path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }
            return (path, nil, marks)
        case .holes:
            honeycomb(step: cell) { center in
                let radius = cell * 0.26
                path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }
            return (path, cell * 0.17, marks)
        case .diamonds:
            honeycomb(step: cell) { center in
                let half = cell * 0.34
                path.move(to: CGPoint(x: center.x, y: center.y - half))
                path.addLine(to: CGPoint(x: center.x + half, y: center.y))
                path.addLine(to: CGPoint(x: center.x, y: center.y + half))
                path.addLine(to: CGPoint(x: center.x - half, y: center.y))
                path.closeSubpath()
            }
            return (path, nil, marks)
        case .triangles:
            honeycomb(step: cell) { center in
                let half = cell * 0.36
                path.move(to: CGPoint(x: center.x, y: center.y - half))
                path.addLine(to: CGPoint(x: center.x + half, y: center.y + half * 0.75))
                path.addLine(to: CGPoint(x: center.x - half, y: center.y + half * 0.75))
                path.closeSubpath()
            }
            return (path, nil, marks)
        case .checkerboard:
            let step = cell * 0.6
            outer: for row in range(area.minY, area.maxY, origin.y, step: step) {
                for column in range(area.minX, area.maxX, origin.x, step: step) where (row + column).isMultiple(of: 2) {
                    path.addRect(CGRect(x: origin.x + CGFloat(column) * step, y: origin.y + CGFloat(row) * step, width: step, height: step))
                    marks += 1
                    if marks >= limit { break outer }
                }
            }
            return (path, nil, marks)
        case .candyStripes:
            // Bands leaning like the stripes that drift across the app's progress bars.
            let period = cell * 1.4
            let height = area.height + 2 * cell
            let top = area.minY - cell
            for band in range(area.minX - height, area.maxX, origin.x, step: period) {
                let x = origin.x + CGFloat(band) * period
                path.move(to: CGPoint(x: x, y: top + height))
                path.addLine(to: CGPoint(x: x + height, y: top))
                path.addLine(to: CGPoint(x: x + height + period * 0.5, y: top))
                path.addLine(to: CGPoint(x: x + period * 0.5, y: top + height))
                path.closeSubpath()
                marks += 1
            }
            return (path, nil, marks)
        case .bands:
            let step = cell * 0.9
            for row in range(area.minY, area.maxY, origin.y, step: step) {
                path.addRect(CGRect(x: area.minX, y: origin.y + CGFloat(row) * step, width: area.width, height: step * 0.45))
                marks += 1
            }
            return (path, nil, marks)
        case .columns:
            let step = cell * 0.9
            for column in range(area.minX, area.maxX, origin.x, step: step) {
                path.addRect(CGRect(x: origin.x + CGFloat(column) * step, y: area.minY, width: step * 0.45, height: area.height))
                marks += 1
            }
            return (path, nil, marks)
        case .crosshatch:
            let span = area.width + area.height
            for line in range(area.minX - area.height, area.maxX + area.height, origin.x, step: cell) {
                let x = origin.x + CGFloat(line) * cell
                path.move(to: CGPoint(x: x, y: area.minY))
                path.addLine(to: CGPoint(x: x + span, y: area.minY + span))
                path.move(to: CGPoint(x: x, y: area.minY))
                path.addLine(to: CGPoint(x: x - span, y: area.minY + span))
                marks += 2
            }
            return (path, cell * 0.22, marks)
        case .zigzag:
            let columns = range(area.minX, area.maxX, origin.x, step: cell)
            for row in range(area.minY, area.maxY, origin.y, step: cell * 0.9) {
                let y = origin.y + CGFloat(row) * cell * 0.9
                path.move(to: CGPoint(x: origin.x + CGFloat(columns.lowerBound) * cell, y: y))
                for column in columns {
                    let x = origin.x + CGFloat(column) * cell
                    path.addLine(to: CGPoint(x: x + cell / 2, y: y - cell * 0.32))
                    path.addLine(to: CGPoint(x: x + cell, y: y))
                }
                marks += columns.count
            }
            return (path, cell * 0.2, marks)
        }
    }
}
