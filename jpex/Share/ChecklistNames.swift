import SwiftUI
import UIKit

/// The names layout's checklist: every place been to typed out as a list, each ticked off in a box of
/// its colours, in as many columns as let the type be largest.
struct ChecklistNames: View {
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring

    /// How far apart the rows' tops sit, the box's width and the space after it, and the space
    /// between columns, per point of type.
    private static let pitch: CGFloat = 1.5
    private static let box: CGFloat = 1.05
    private static let boxGap: CGFloat = 0.45
    private static let columnGap: CGFloat = 1.3
    /// A row's own height, per point.
    private static let lineHeight = uiFont(size: 100).lineHeight / 100

    /// The type's size, and the rows each column holds, by their place in the list.
    private struct Arrangement {
        var size: CGFloat
        var columns: [Range<Int>]
    }

    var body: some View {
        GeometryReader { proxy in
            let arrangement = arrangement(in: proxy.size)
            let size = arrangement.size
            HStack(alignment: .top, spacing: size * Self.columnGap) {
                ForEach(arrangement.columns, id: \.lowerBound) { rows in
                    VStack(alignment: .leading, spacing: size * (Self.pitch - Self.lineHeight)) {
                        ForEach(words[rows]) { word in
                            row(word, size: size)
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func row(_ word: ShareWord, size: CGFloat) -> some View {
        HStack(spacing: size * Self.boxGap) {
            Image(systemName: word.isVisited ? "checkmark.square.fill" : "square")
                .font(.system(size: size * 0.95, weight: .semibold))
                .foregroundStyle(palette.wordFill(word, colouring: colouring))
                .frame(width: size * Self.box)
            Text(word.name)
                .placeName(language)
                .font(Self.font(size: size))
                .foregroundStyle(word.isVisited ? palette.text : palette.secondaryText)
                .fixedSize()
        }
    }

    /// The most columns, up to four, that let the type be largest, every row in each column but
    /// the last, which takes what's left.
    private func arrangement(in room: CGSize) -> Arrangement {
        let count = words.count
        guard count > 0, room.width > 1, room.height > 1 else { return Arrangement(size: 12, columns: []) }
        let widest = (NameFlow.widths(of: words.map(\.name), font: Self.uiFont).max() ?? 1) + Self.box + Self.boxGap
        var best = Arrangement(size: 0, columns: [])
        for columns in 1...min(4, count) {
            let rows = (count + columns - 1) / columns
            let across = room.width / (CGFloat(columns) * widest + CGFloat(columns - 1) * Self.columnGap)
            let down = room.height / (CGFloat(rows) * Self.pitch - (Self.pitch - Self.lineHeight))
            let size = min(across, down, 34) * 0.97
            if size > best.size {
                best = Arrangement(
                    size: size,
                    columns: stride(from: 0, to: count, by: rows).map { $0..<min($0 + rows, count) })
            }
        }
        return best
    }

    /// American Typewriter, as a list typed on a trip; the system's monospaced type should it be missing.
    static func font(size: CGFloat) -> Font {
        hasTypewriter ? .custom("AmericanTypewriter-Semibold", fixedSize: size) : .system(size: size, design: .monospaced)
    }

    private static func uiFont(size: CGFloat) -> UIFont {
        UIFont(name: "AmericanTypewriter-Semibold", size: size)
            ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    private static let hasTypewriter = UIFont(name: "AmericanTypewriter-Semibold", size: 12) != nil
}
