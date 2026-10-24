import SwiftUI
import UIKit

/// Names flowed into lines across a room at the largest size at which every one fits, for the names
/// layouts, which set every place at one size so none looks more important than another. Names are
/// measured once, per point of type, so any size can be tried without measuring again.
struct NameFlow {
    /// The size the type's set at.
    var size: CGFloat
    /// Each line's names, by their place in the list.
    var lines: [[Int]]

    /// Each name's width in a font, per point of the font's size.
    static func widths(of names: [String], font: (CGFloat) -> UIFont) -> [CGFloat] {
        let reference: CGFloat = 100
        let measuring = font(reference)
        return names.map { ($0 as NSString).size(withAttributes: [.font: measuring]).width / reference }
    }

    /// The largest size at which names of these widths flow into lines that fit the room: none wider
    /// than it, and the lines, from the first's top to the last's foot, no taller. Every measure is
    /// per point of type.
    /// - Parameters:
    ///   - gap: The space between names on a line.
    ///   - lineHeight: A line's own height.
    ///   - pitch: How far apart the lines' tops sit.
    ///   - largest: The largest the type may grow, so a few names don't fill the card in giant type.
    static func fit(
        widths: [CGFloat], in room: CGSize, gap: CGFloat, lineHeight: CGFloat, pitch: CGFloat,
        largest: CGFloat = .infinity
    ) -> NameFlow {
        guard !widths.isEmpty, room.width > 1, room.height > 1 else { return NameFlow(size: 12, lines: []) }
        func lines(at size: CGFloat) -> [[Int]]? {
            var lines: [[Int]] = []
            var line: [Int] = []
            var used: CGFloat = 0
            for (index, width) in widths.enumerated() {
                let name = width * size
                guard name <= room.width else { return nil }
                if line.isEmpty {
                    used = name
                } else if used + gap * size + name <= room.width {
                    used += gap * size + name
                } else {
                    lines.append(line)
                    line = []
                    used = name
                }
                line.append(index)
            }
            if !line.isEmpty { lines.append(line) }
            return lines
        }
        func fits(_ size: CGFloat) -> Bool {
            guard let lines = lines(at: size) else { return false }
            return size * (lineHeight + CGFloat(lines.count - 1) * pitch) <= room.height
        }
        var low: CGFloat = 1
        var high = min(largest, room.height / lineHeight)
        if fits(high) {
            low = high
        } else {
            for _ in 0..<26 {
                let middle = (low + high) / 2
                if fits(middle) { low = middle } else { high = middle }
            }
        }
        // A hair smaller than the measured fit, as the screen sets type a touch differently.
        let size = low * 0.97
        return NameFlow(size: size, lines: lines(at: size) ?? [Array(widths.indices)])
    }

    /// Names broken into lines that fill the width as evenly as they can, rather than as many to a
    /// line as fit and the rest left over: the gaps across the block alike, and a name alone on a
    /// line only where it's too long to share one, or nearly fills it. The last line, which is
    /// centred, may be as short as it likes. Nil where a name is wider than the room.
    /// - Parameters:
    ///   - widths: Each name's width per point of type.
    ///   - size: The type's size.
    ///   - gap: The space between names, per point.
    ///   - most: The most lines there's room for.
    static func balancedLines(
        widths: [CGFloat], size: CGFloat, width: CGFloat, gap: CGFloat, most: Int
    ) -> [[Int]]? {
        let count = widths.count
        guard count > 0, most > 0 else { return nil }
        let space = gap * size
        var prefix = [CGFloat](repeating: 0, count: count + 1)
        for index in 0..<count { prefix[index + 1] = prefix[index] + widths[index] * size }
        /// How far a line of the names from `start` up to `end` falls short, as a share of the
        /// width, squared, with a cost for a name alone; nil where they don't fit.
        func cost(_ start: Int, _ end: Int) -> Double? {
            let used = prefix[end] - prefix[start] + CGFloat(end - start - 1) * space
            guard used <= width + 0.5 else { return nil }
            guard end < count else { return 0 }
            let short = Double(max(width - used, 0) / width)
            return short * short * 100 + (end - start == 1 ? short * 60 : 0)
        }
        let lines = min(most, count)
        var best = [[Double]](repeating: [Double](repeating: .infinity, count: lines + 1), count: count + 1)
        var from = [[Int]](repeating: [Int](repeating: -1, count: lines + 1), count: count + 1)
        best[0][0] = 0
        for end in 1...count {
            for line in 1...lines {
                var start = end - 1
                while start >= 0, let cost = cost(start, end) {
                    let total = best[start][line - 1] + cost
                    if total < best[end][line] {
                        best[end][line] = total
                        from[end][line] = start
                    }
                    start -= 1
                }
            }
        }
        guard let chosen = (1...lines).min(by: { best[count][$0] < best[count][$1] }),
              best[count][chosen].isFinite
        else { return nil }
        var result: [[Int]] = []
        var end = count
        var line = chosen
        while line > 0 {
            let start = from[end][line]
            guard start >= 0 else { return nil }
            result.insert(Array(start..<end), at: 0)
            end = start
            line -= 1
        }
        return result
    }
}
