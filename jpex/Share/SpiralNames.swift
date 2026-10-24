import SwiftUI
import UIKit

/// The names layout's spiral: every place been to in one line of capitals wound round and round
/// into the middle of the card, like a record's groove, a small star between each name and the
/// next. The type is as large as lets the whole line wind in before it reaches the middle.
struct SpiralNames: View {
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring

    /// How far apart the turns sit, and the room a star takes between names, per point of type.
    private static let turnSpacing: CGFloat = 1.18
    private static let starRoom: CGFloat = 1.1
    /// How tall the capitals stand, per point.
    private static let capHeight = uiFont(size: 100).capHeight / 100

    var body: some View {
        Canvas { context, size in
            guard !words.isEmpty else { return }
            let names = words.map { $0.name.uppercased() }
            let length = NameFlow.widths(of: names, font: Self.uiFont).reduce(0, +) + Self.starRoom * CGFloat(names.count)
            let half = min(size.width, size.height) / 2
            let type = Self.size(fitting: length, within: half)
            let font = Self.uiFont(size: type)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = Self.outerRadius(within: half, type: type)
            let spacing = type * Self.turnSpacing
            // Clockwise from the top, a turn's spacing nearer the middle at each turn.
            var angle: CGFloat = 0
            func radius(at angle: CGFloat) -> CGFloat { max(outer - spacing * angle / (2 * .pi), 1) }
            /// Where a length along the spiral from here has its middle, and where it ends.
            func step(_ length: CGFloat) -> (middle: CGFloat, end: CGFloat) {
                let middle = angle + length / 2 / radius(at: angle)
                return (middle, angle + length / radius(at: middle))
            }
            func point(at angle: CGFloat) -> CGPoint {
                let radius = radius(at: angle)
                return CGPoint(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle))
            }
            for (index, word) in words.enumerated() {
                let line = GlyphLine(names[index], font: font, language: language)
                let colors = palette.wordColors(word, colouring: colouring).colors
                for (number, glyph) in line.glyphs.enumerated() {
                    let place = step(glyph.advance)
                    let at = point(at: place.middle)
                    // Each letter upright on the line, its capitals centred on it, leaning round as it goes.
                    let transform = CGAffineTransform(translationX: at.x, y: at.y)
                        .rotated(by: place.middle)
                        .translatedBy(x: -glyph.advance / 2, y: type * Self.capHeight / 2)
                    // A flag's stripes run along the name, a stripe to each stretch of letters.
                    let stripe = colors[min(number * colors.count / max(line.glyphs.count, 1), colors.count - 1)]
                    context.fill(glyph.path.applying(transform), with: .color(stripe))
                    angle = place.end
                }
                let star = step(type * Self.starRoom)
                context.fill(
                    Self.sparkle(at: point(at: star.middle), radius: type * 0.24),
                    with: .color(palette.secondaryText.opacity(0.8)))
                angle = star.end
            }
        }
        .allowsHitTesting(false)
    }

    /// The outermost turn's radius, which leaves the capitals on it room inside the card.
    private static func outerRadius(within half: CGFloat, type: CGFloat) -> CGFloat {
        half - type * capHeight * 0.6
    }

    /// The largest type at which a line of this length, per point, winds from the outer turn to a
    /// little way short of the middle, where the turns would grow too tight to read.
    private static func size(fitting length: CGFloat, within half: CGFloat) -> CGFloat {
        func fits(_ type: CGFloat) -> Bool {
            let outer = outerRadius(within: half, type: type)
            let inner = max(half * 0.16, type * 1.4)
            guard outer > inner else { return false }
            // A spiral's length is its area over the spacing of its turns.
            let room = .pi * (outer * outer - inner * inner) / (type * turnSpacing)
            return type * length <= room * 0.96
        }
        var low: CGFloat = 2
        var high = half / 2
        for _ in 0..<24 {
            let middle = (low + high) / 2
            if fits(middle) { low = middle } else { high = middle }
        }
        return low
    }

    /// A four-pointed star, its points long and its waist narrow.
    private static func sparkle(at center: CGPoint, radius: CGFloat) -> Path {
        let waist = radius * 0.22
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y - waist))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x + waist, y: center.y + waist))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y + waist))
        path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x - waist, y: center.y - waist))
        path.closeSubpath()
        return path
    }

    private static func uiFont(size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .heavy, width: .condensed)
    }
}
