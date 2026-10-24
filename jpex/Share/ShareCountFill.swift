import SwiftUI
import UIKit

/// The count as the card's whole picture: its figures drawn huge, faintly, and filled, like letters
/// cut from a page of type, with the names of the places been to, over and over in their colours,
/// with what they count in spaced capitals beneath. Each line of names starts its own way along, at
/// its own name, so the figures' edges cut every line somewhere different rather than down a column
/// of word ends; a new arrangement each time the share screen opens.
struct ShareCountFill: View {
    var count: Int
    var label: String
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring
    /// The design's lively colours, for names coloured smartly, dealt out name by name.
    var smartPalette: [Color] = []
    /// Which arrangement of the lines this is: the same seed gives the same one, so the picture
    /// sent is the one previewed.
    var seed = 0

    var body: some View {
        GeometryReader { proxy in
            let labelHeight: CGFloat = 24
            let room = CGSize(width: proxy.size.width, height: max(proxy.size.height - labelHeight, 1))
            VStack(spacing: 0) {
                Canvas { context, size in
                    draw(in: &context, room: size)
                }
                .frame(width: room.width, height: room.height)
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: palette.fontDesign))
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundStyle(palette.secondaryText)
                    .frame(height: labelHeight)
            }
        }
    }

    private func draw(in context: inout GraphicsContext, room: CGSize) {
        let figures = count.formatted()
        let size = Self.figureSize(for: figures, in: room, design: palette.fontDesign)
        let outline = GlyphLine(figures, font: Self.uiFont(size: size, design: palette.fontDesign)).path(at: .zero)
        let bounds = outline.boundingRect
        guard bounds.width > 0, bounds.height > 0 else { return }
        let shape = outline.offsetBy(dx: room.width / 2 - bounds.midX, dy: room.height / 2 - bounds.midY)
        // The figures' own shape, faintly, beneath the names that fill them.
        context.fill(shape, with: .color(palette.text.opacity(0.07)))
        guard !words.isEmpty else { return }

        let type: CGFloat = 11
        let pitch = type * 1.08
        let font = Font.system(size: type, weight: .heavy, design: palette.fontDesign).width(.condensed)
        var random = Scatter(seed: UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9 &+ UInt64(count))
        var resolved: [String: (text: GraphicsContext.ResolvedText, width: CGFloat)] = [:]
        func name(_ word: ShareWord, tone: Int) -> (text: GraphicsContext.ResolvedText, width: CGFloat) {
            let key = "\(word.id) \(tone)"
            if let known = resolved[key] { return known }
            let text = context.resolve(
                Text(word.name.uppercased())
                    .placeName(language)
                    .font(font)
                    .foregroundStyle(fill(of: word, tone: tone)))
            let made = (text, text.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity)).width)
            resolved[key] = made
            return made
        }

        var texture = context
        texture.clip(to: shape)
        let area = shape.boundingRect
        var placed = 0
        var y = area.minY + pitch * 0.4
        while y < area.maxY + pitch {
            // Each line starts its own way along, and at its own name.
            var x = area.minX - random.next() * type * 10
            var pick = Int(random.next() * CGFloat(words.count)) % words.count
            while x < area.maxX {
                // Smartly coloured, each copy takes the next colour; otherwise a name is always its own.
                let tone = colouring == .smart && !smartPalette.isEmpty ? placed % smartPalette.count : 0
                let (text, width) = name(words[pick], tone: tone)
                texture.draw(text, at: CGPoint(x: x + width / 2, y: y))
                x += width + type * 0.35
                pick = (pick + 1) % words.count
                placed += 1
            }
            y += pitch
        }
    }

    /// A name's colours: its level's, its flag's or the plain one, as everywhere else; or smartly,
    /// the lively colours dealt out name by name, so the same place comes in several.
    private func fill(of word: ShareWord, tone: Int) -> AnyShapeStyle {
        guard word.isVisited else { return AnyShapeStyle(palette.text.opacity(0.7)) }
        guard colouring == .smart, !smartPalette.isEmpty else { return palette.wordFill(word, colouring: colouring) }
        return AnyShapeStyle(smartPalette[tone % smartPalette.count])
    }

    /// The figures' type: the system's black weight, rounded, or the card's serif.
    private static func uiFont(size: CGFloat, design: Font.Design) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: .black)
        let systemDesign: UIFontDescriptor.SystemDesign = design == .serif ? .serif : .rounded
        guard let descriptor = font.fontDescriptor.withDesign(systemDesign) else { return font }
        return UIFont(descriptor: descriptor, size: size)
    }

    /// As large as the figures can be and still fit the room, across and down.
    private static func figureSize(for figures: String, in room: CGSize, design: Font.Design) -> CGFloat {
        let reference: CGFloat = 100
        let font = uiFont(size: reference, design: design)
        let width = (figures as NSString).size(withAttributes: [.font: font]).width
        guard width > 0 else { return reference }
        let across = reference * room.width * 0.96 / width
        // The figures' height is their cap height; the line around them is taller.
        let down = reference * room.height * 0.92 / max(font.capHeight, 1)
        return min(across, down)
    }
}

/// Numbers that look random but come out the same from the same seed, from 0 up to 1.
private struct Scatter {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> CGFloat {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        mixed ^= mixed >> 31
        return CGFloat(mixed >> 11) / CGFloat(UInt64(1) << 53)
    }
}
