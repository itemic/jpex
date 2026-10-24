import SwiftUI

/// Names in lines across the room, the lines together centred down it: each full line stretched to
/// the room's width by widening the gaps between its names, as a justified block; or every line
/// centred. The last line is centred either way.
struct NameLines: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat
    var justifies = true
    /// Which names go on each line, where they've been planned, by their place among the names;
    /// otherwise as many to a line as fit.
    var plan: [[Int]]? = nil

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let lines = arrange(width: width, subviews: subviews)
        let height = lines.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(lines.count - 1, 0))
        return CGSize(width: proposal.width ?? (lines.map(\.width).max() ?? 0), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let lines = arrange(width: bounds.width, subviews: subviews)
        let total = lines.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(lines.count - 1, 0))
        var y = bounds.minY + (bounds.height - total) / 2
        for (number, line) in lines.enumerated() {
            let isLast = number == lines.count - 1
            let stretches = justifies && !isLast && line.indices.count > 1
            let gap = stretches ? spacing + (bounds.width - line.width) / CGFloat(line.indices.count - 1) : spacing
            var x = stretches ? bounds.minX : bounds.minX + (bounds.width - line.width) / 2
            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                // The names of a line stand on its foot.
                subviews[index].place(at: CGPoint(x: x, y: y + line.height - size.height), proposal: ProposedViewSize(size))
                x += size.width + gap
            }
            y += line.height + lineSpacing
        }
    }

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Line] {
        if let plan, plan.joined().allSatisfy(subviews.indices.contains) {
            return plan.map { indices in
                var line = Line()
                for index in indices {
                    let size = subviews[index].sizeThatFits(.unspecified)
                    line.width = line.indices.isEmpty ? size.width : line.width + spacing + size.width
                    line.height = max(line.height, size.height)
                    line.indices.append(index)
                }
                return line
            }
        }
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !line.indices.isEmpty, line.width + spacing + size.width > width {
                lines.append(line)
                line = Line()
            }
            line.width = line.indices.isEmpty ? size.width : line.width + spacing + size.width
            line.height = max(line.height, size.height)
            line.indices.append(index)
        }
        if !line.indices.isEmpty { lines.append(line) }
        return lines
    }
}
