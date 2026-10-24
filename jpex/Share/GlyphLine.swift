import CoreText
import SwiftUI
import UIKit

/// A run of type as the outlines of its letters, for drawing what a Text can't: letters only
/// outlined, or set one by one along a curve. Letters a font lacks, such as Japanese in a Latin
/// face, come from the font the system falls back to, as they would in a Text.
struct GlyphLine {
    /// One letter: its outline, with its origin on the baseline at the letter's start, where along
    /// the line it starts, and how far it advances.
    struct Glyph {
        var path: Path
        var x: CGFloat
        var advance: CGFloat
    }

    var glyphs: [Glyph]
    var width: CGFloat
    /// How far the type rises above its baseline and drops below it.
    var ascent: CGFloat
    var descent: CGFloat

    init(_ string: String, font: UIFont, language: Locale.Language? = nil) {
        var attributes: [NSAttributedString.Key: Any] = [.font: font]
        if let language {
            // Han characters take their own language's shapes, such as Japanese ones for 京都府.
            attributes[NSAttributedString.Key(kCTLanguageAttributeName as String)] = language.minimalIdentifier
        }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
        self.ascent = ascent
        self.descent = descent
        var glyphs: [Glyph] = []
        for run in CTLineGetGlyphRuns(line) as? [CTRun] ?? [] {
            let count = CTRunGetGlyphCount(run)
            guard count > 0,
                  let runFont = (CTRunGetAttributes(run) as NSDictionary)[NSAttributedString.Key.font] as? UIFont
            else { continue }
            var ids = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            var advances = [CGSize](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(), &ids)
            CTRunGetPositions(run, CFRange(), &positions)
            CTRunGetAdvances(run, CFRange(), &advances)
            for index in 0..<count {
                // Fonts draw upwards from the baseline; the screen counts down.
                var flip = CGAffineTransform(scaleX: 1, y: -1)
                let outline = CTFontCreatePathForGlyph(runFont as CTFont, ids[index], &flip).map { Path($0) } ?? Path()
                glyphs.append(Glyph(path: outline, x: positions[index].x, advance: advances[index].width))
            }
        }
        self.glyphs = glyphs
    }

    /// The whole line's outline, its baseline starting at a point, its letters spaced further apart
    /// by `tracking` where it's given.
    func path(at origin: CGPoint, tracking: CGFloat = 0) -> Path {
        var whole = Path()
        for (index, glyph) in glyphs.enumerated() {
            whole.addPath(
                glyph.path,
                transform: CGAffineTransform(translationX: origin.x + glyph.x + CGFloat(index) * tracking, y: origin.y))
        }
        return whole
    }

    /// How wide the line is with its letters spaced further apart.
    func width(tracking: CGFloat) -> CGFloat {
        width + CGFloat(max(glyphs.count - 1, 0)) * tracking
    }
}
