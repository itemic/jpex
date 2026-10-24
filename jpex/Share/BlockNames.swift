import SwiftUI
import UIKit

/// The names layout's block: every place been to, each named once, set in heavy, narrow capitals
/// as one unbroken run of type, like a strip of tape wound into a block: a line ends wherever it
/// reaches the edge, partway through a name if need be, cutting it off there, and the next line
/// picks up just where it left off. The type is sized so the run fills its lines exactly, every
/// line edge to edge, the block solid with no gaps. The names take their levels' colours, their
/// flags' stripes, or the card's ink.
struct BlockNames: View {
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring

    /// The space between names, and how far apart lines sit, as fractions of the type's size.
    private static let gap: CGFloat = 0.3
    private static let leading: CGFloat = 1.0
    /// The most a line's spacing grows to spread a short block down the card, as a fraction of the type's size.
    private static let mostSpread: CGFloat = 0.45

    var body: some View {
        Canvas { context, size in
            draw(in: &context, room: size)
        }
        .allowsHitTesting(false)
    }

    private func draw(in context: inout GraphicsContext, room: CGSize) {
        guard !words.isEmpty, room.width > 1, room.height > 1 else { return }
        let names = words.map { $0.name.uppercased() }
        let reference: CGFloat = 100
        let measuring = Self.uiFont(size: reference, design: palette.fontDesign)
        let natural = measuring.lineHeight / reference
        let run = names.reduce(0) { $0 + ($1 as NSString).size(withAttributes: [.font: measuring]).width / reference }
            + CGFloat(names.count - 1) * Self.gap

        // The most lines whose type, sized for the run to fill them exactly, still fits down the room.
        func size(lines: Int) -> CGFloat { CGFloat(lines) * room.width / run }
        func height(lines: Int) -> CGFloat { size(lines: lines) * (natural + CGFloat(lines - 1) * Self.leading) }
        var lines = 1
        while height(lines: lines + 1) <= room.height { lines += 1 }
        // A run too short to fill even one line across without being too tall sits on one line,
        // centred, as large as the room allows down.
        let fills = height(lines: 1) <= room.height
        let type = fills ? size(lines: lines) * 0.995 : room.height / natural

        let font = Self.font(size: type, design: palette.fontDesign)
        let texts = words.map { word in
            context.resolve(
                Text(word.name.uppercased())
                    .placeName(language)
                    .font(font)
                    .foregroundStyle(palette.wordFill(word, colouring: colouring)))
        }
        let widths = texts.map { $0.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity)).width }
        let total = widths.reduce(0, +)
        // The gaps take up the last of the room, so the run ends exactly at the last line's edge.
        let length = CGFloat(lines) * room.width
        let space = fills && names.count > 1 ? max((length - total) / CGFloat(names.count - 1), type * 0.12) : type * Self.gap
        var starts: [CGFloat] = []
        var x: CGFloat = fills ? 0 : (room.width - total - space * CGFloat(names.count - 1)) / 2
        for width in widths {
            starts.append(x)
            x += width + space
        }

        // Lines spread down the room a little where there's height to spare, the block centred.
        let block = type * (natural + CGFloat(lines - 1) * Self.leading)
        let spread = lines > 1 ? min(max(room.height - block, 0) / CGFloat(lines - 1), type * Self.mostSpread) : 0
        let pitch = type * Self.leading + spread
        let top = (room.height - (type * natural + CGFloat(lines - 1) * pitch)) / 2
        for line in 0..<lines {
            let middle = top + type * natural / 2 + CGFloat(line) * pitch
            let window = CGFloat(line) * room.width
            var strip = context
            strip.clip(to: Path(CGRect(x: 0, y: middle - pitch, width: room.width, height: pitch * 2)))
            for (index, text) in texts.enumerated() {
                let start = starts[index] - (fills ? window : 0)
                guard start < room.width, start + widths[index] > 0 else { continue }
                strip.draw(text, at: CGPoint(x: start + widths[index] / 2, y: middle))
            }
        }
    }

    private static func font(size: CGFloat, design: Font.Design) -> Font {
        design == .default
            ? .system(size: size, weight: .heavy).width(.condensed)
            : .system(size: size, weight: .heavy, design: design)
    }

    private static func uiFont(size: CGFloat, design: Font.Design) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: .heavy, width: design == .default ? .condensed : .standard)
        let systemDesign: UIFontDescriptor.SystemDesign? = switch design {
        case .serif: .serif
        case .rounded: .rounded
        case .monospaced: .monospaced
        default: nil
        }
        guard let systemDesign, let descriptor = font.fontDescriptor.withDesign(systemDesign) else { return font }
        return UIFont(descriptor: descriptor, size: size)
    }
}
