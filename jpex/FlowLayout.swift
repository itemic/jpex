import SwiftUI

/// Sets views in lines like words in a paragraph, wrapping when a line is full.
/// Views in a line share a baseline, so text of different sizes reads as one line of type.
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = lines.map(\.width).max() ?? 0
        let height = lines.last.map { $0.top + $0.height } ?? 0
        return CGSize(width: proposal.width.map { min(width, $0) } ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for line in arrange(width: bounds.width, subviews: subviews) {
            for item in line.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + line.top + line.baseline - item.baseline),
                    proposal: ProposedViewSize(item.size))
            }
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            let ideal = subviews[index].sizeThatFits(.unspecified)
            // A view wider than a whole line gets the line to itself and wraps within it.
            let size = ideal.width > width
                ? subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil))
                : ideal
            let baseline = subviews[index].dimensions(in: ProposedViewSize(size))[VerticalAlignment.firstTextBaseline]
            if !line.items.isEmpty, line.width + spacing + size.width > width {
                lines.append(line)
                line = Line(top: line.top + line.height + lineSpacing)
            }
            let x = line.items.isEmpty ? 0 : line.width + spacing
            line.items.append(Item(index: index, x: x, size: size, baseline: baseline))
            line.width = x + size.width
            line.baseline = max(line.baseline, baseline)
            line.descent = max(line.descent, size.height - baseline)
        }
        if !line.items.isEmpty { lines.append(line) }
        return lines
    }

    private struct Line {
        var top: CGFloat = 0
        var items: [Item] = []
        var width: CGFloat = 0
        var baseline: CGFloat = 0
        var descent: CGFloat = 0
        var height: CGFloat { baseline + descent }
    }

    private struct Item {
        var index: Int
        var x: CGFloat
        var size: CGSize
        var baseline: CGFloat
    }
}
