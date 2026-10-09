import SwiftUI

/// A bar stacked from each level's colour, strongest first, so a region shows its whole mix of
/// levels at a glance. Levels below the counting threshold stay visible but faded. Stripes drift
/// while there is more to discover, and a band of light crosses the bar once it fills.
struct StatusTallyBar: View {
    var tally: [String: Int]
    var total: Int
    var minimumStatus: VisitLevel
    /// Thin bars can leave the stripes out.
    var showsStripes = true
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var shines = 0

    private var segments: [VisitLevel] {
        ladder.levels.reversed()
    }

    private var marked: Int {
        segments.reduce(0) { $0 + tally[$1.id, default: 0] }
    }

    private var isComplete: Bool {
        total > 0 && marked >= total
    }

    var body: some View {
        let threshold = ladder.rank(of: minimumStatus)
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(segments) { status in
                    let count = tally[status.id, default: 0]
                    Rectangle()
                        .fill(status.color)
                        .overlay {
                            if differentiateWithoutColor, geometry.size.height >= 4, count > 0,
                               let style = ladder.patternStyle(of: status) {
                                LevelPattern(
                                    style: style, color: .white.opacity(0.55), cell: max(geometry.size.height * 0.75, 3),
                                    symbol: status.symbolName)
                            }
                        }
                        .opacity(ladder.rank(of: status) >= threshold ? 1 : 0.35)
                        .frame(width: geometry.size.width * Double(count) / Double(max(total, 1)))
                }
            }
            .overlay {
                if showsStripes {
                    StripeOverlay(isMoving: marked > 0 && !isComplete && !reduceMotion, trigger: marked)
                        .opacity(isComplete ? 0 : 1)
                }
            }
            .overlay(alignment: .leading) {
                ShineSweep(width: geometry.size.width, trigger: shines)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
        }
        .animation(.smooth, value: tally)
        .animation(.smooth, value: minimumStatus)
        .onChange(of: isComplete) { _, complete in
            if complete && !reduceMotion { shines += 1 }
        }
        .accessibilityHidden(true)
    }
}

extension StatusTallyBar {
    /// How many places sit at each level, strongest first, for VoiceOver: "3 Lived, 2 Visited".
    static func breakdown(of tally: [String: Int], in ladder: VisitLadder) -> String {
        ladder.levels.reversed()
            .compactMap { level in tally[level.id].flatMap { $0 > 0 ? "\($0) \(level.name)" : nil } }
            .formatted(.list(type: .and))
    }
}
