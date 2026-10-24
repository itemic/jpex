import SwiftUI
import UIKit

/// The names layout's outline style: every place been to in heavy, wide capitals, justified into a
/// block as on a gig poster, every other name drawn only in outline: the first solid, the next
/// outlined in its colours, and so on.
struct OutlineNames: View {
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring

    /// The space between names, and how far apart the lines' tops sit, per point of type: tight, as
    /// a poster's capitals are set.
    private static let gap: CGFloat = 0.34
    private static let pitch: CGFloat = 0.96
    /// How tall the capitals stand, per point.
    private static let capHeight = uiFont(size: 100).capHeight / 100

    var body: some View {
        Canvas { context, size in
            let names = words.map { $0.name.uppercased() }
            let widths = NameFlow.widths(of: names, font: Self.uiFont)
            let flow = NameFlow.fit(
                widths: widths, in: size, gap: Self.gap, lineHeight: Self.capHeight, pitch: Self.pitch, largest: 96)
            let font = Self.uiFont(size: flow.size)
            let capital = flow.size * Self.capHeight
            // The names shared out evenly over as many lines as there's room for.
            let most = max(Int((size.height / flow.size - Self.capHeight) / Self.pitch) + 1, 1)
            let plan = NameFlow.balancedLines(widths: widths, size: flow.size, width: size.width, gap: Self.gap, most: most)
            let lines = (plan ?? flow.lines).map { line in
                line.map { (index: $0, glyphs: GlyphLine(names[$0], font: font, language: language)) }
            }
            let total = capital + flow.size * Self.pitch * CGFloat(max(lines.count - 1, 0))
            var baseline = (size.height - total) / 2 + capital
            for (number, line) in lines.enumerated() {
                let isLast = number == lines.count - 1
                // A name alone on a line but the last spaces its letters out to reach across it.
                let tracking = !isLast && line.count == 1
                    ? min((size.width - line[0].glyphs.width) / CGFloat(max(line[0].glyphs.glyphs.count - 1, 1)), flow.size * 0.3)
                    : 0
                let width = line.reduce(0) { $0 + $1.glyphs.width(tracking: max(tracking, 0)) }
                // Full lines reach right across; the last is centred.
                let stretches = !isLast && line.count > 1
                let gap = stretches ? (size.width - width) / CGFloat(line.count - 1) : flow.size * Self.gap
                var x = stretches ? 0 : (size.width - width - gap * CGFloat(line.count - 1)) / 2
                for item in line {
                    let spacing = max(tracking, 0)
                    let outline = item.glyphs.path(at: CGPoint(x: x, y: baseline), tracking: spacing)
                    let bounds = CGRect(
                        x: x, y: baseline - capital, width: item.glyphs.width(tracking: spacing), height: capital)
                    let shading = palette.wordShading(words[item.index], colouring: colouring, in: bounds)
                    if item.index.isMultiple(of: 2) {
                        context.fill(outline, with: shading)
                    } else {
                        // Merged first, as a letter's strokes overlap inside it, and would each be outlined.
                        context.stroke(
                            outline.normalized(eoFill: false), with: shading,
                            style: StrokeStyle(lineWidth: max(flow.size * 0.035, 0.6), lineJoin: .round))
                    }
                    x += item.glyphs.width(tracking: max(tracking, 0)) + gap
                }
                baseline += flow.size * Self.pitch
            }
        }
        .allowsHitTesting(false)
    }

    /// The system's black weight, at its widest.
    static func uiFont(size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .black, width: .expanded)
    }
}
