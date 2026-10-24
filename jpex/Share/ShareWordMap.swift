import SwiftUI

/// The map drawn in words: each place's name set where the place is, over a ghost of the land. Every
/// place been to is named at one size and weight, the largest at which each can sit at its place,
/// nudged a line up or down at most where it would cover another, so none looks more important than any
/// other; the places not yet been to are named smaller and faint, where there's room. It glides as
/// it's framed, as the map does.
struct ShareWordMap: View, Animatable {
    var map: TravelMap
    var words: [String: ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring
    var focus: CGRect
    var insets: EdgeInsets

    var animatableData: CGRect.AnimatableData {
        get { focus.animatableData }
        set { focus.animatableData = newValue }
    }

    /// The range the names of the places been to are set within.
    private static let sizes: ClosedRange<CGFloat> = 6...20
    /// The size names are measured at; any other size is in proportion.
    private static let reference: CGFloat = 10
    /// Where a name may sit, in lines above or below its place, when it would cover another: a line
    /// at most, so every name stays beside its place, the names a size smaller rather than wander.
    private static let nudges: [CGFloat] = [0, -1, 1]

    private struct Label {
        var word: ShareWord
        var center: CGPoint
        /// The name's size at the reference size.
        var measured: CGSize
    }

    var body: some View {
        Canvas { context, size in
            let transform = ShareCardMap.transform(fitting: focus, into: ShareCardMap.fitRect(in: size, insets: insets))
            guard transform.a > 0, transform.a.isFinite else { return }
            // A ghost of the land, so the words have a shape to follow; a little clearer on a busy
            // card, where the pattern runs on through it.
            var ghost = context
            ghost.concatenate(transform)
            ghost.opacity = palette.halo == nil ? 0.1 : 0.16
            for region in map.regions {
                ghost.fill(region.path, with: .color(palette.text), style: FillStyle(eoFill: true))
            }
            let card = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
            func label(for region: MapRegion) -> Label? {
                guard let word = words[region.id] else { return nil }
                let center = region.center.applying(transform)
                guard card.contains(center) else { return nil }
                let measured = context.resolve(text(word, size: Self.reference))
                    .measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
                return Label(word: word, center: center, measured: measured)
            }
            let labels = map.regions.compactMap(label)
            let visited = labels.filter(\.word.isVisited)
            let others = labels.filter { !$0.word.isVisited }

            // The places been to: the largest one size at which each finds a spot.
            var low = Self.sizes.lowerBound
            var high = Self.sizes.upperBound
            if Self.arrange(visited, size: high, in: card) != nil {
                low = high
            } else {
                for _ in 0..<12 {
                    let middle = (low + high) / 2
                    if Self.arrange(visited, size: middle, in: card) != nil { low = middle } else { high = middle }
                }
            }
            // At the smallest size, any that still can't find room sit at their place regardless:
            // every place been to is named.
            let spots = Self.arrange(visited, size: low, in: card)
                ?? visited.map { Self.frame(of: $0, size: low, nudge: 0) }

            // The rest, all at one smaller size, only where they don't cover a name, and beneath them.
            let otherSize = max(low * 0.55, 4)
            var taken = spots.map { $0.insetBy(dx: -2, dy: -1) }
            for item in others {
                let spot = Self.frame(of: item, size: otherSize, nudge: 0)
                guard !taken.contains(where: { $0.intersects(spot) }) else { continue }
                context.draw(context.resolve(text(item.word, size: otherSize)), at: item.center)
                taken.append(spot)
            }

            // The names of the places been to, set together, so on a busy card one halo glows round
            // them all, its glows running into each other between neighbours.
            var named = context
            if let halo = palette.halo {
                named.addFilter(.shadow(color: halo, radius: 2.5))
                named.addFilter(.shadow(color: halo, radius: 0.8))
            }
            named.drawLayer { layer in
                for (item, spot) in zip(visited, spots) {
                    layer.draw(layer.resolve(text(item.word, size: low)), at: CGPoint(x: spot.midX, y: spot.midY))
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// A place's name, bold in its colour for somewhere been to, light and faint otherwise.
    private func text(_ word: ShareWord, size: CGFloat) -> Text {
        Text(word.name)
            .placeName(language)
            .font(.system(size: size, weight: word.isVisited ? .bold : .regular, design: palette.fontDesign))
            .foregroundStyle(palette.wordFill(word, colouring: colouring))
    }

    /// Where a name sits at a size, a number of its own lines above or below its place.
    private static func frame(of label: Label, size: CGFloat, nudge: CGFloat) -> CGRect {
        let scale = size / reference
        let width = label.measured.width * scale
        let height = label.measured.height * scale
        // Lines of type overlap a little in their own spacing above and below.
        return CGRect(
            x: label.center.x - width / 2, y: label.center.y - height / 2 + nudge * height * 0.8,
            width: width, height: height * 0.8)
    }

    /// A spot for every name at this size, each at its place or nudged a line or two from it, none
    /// covering another nor leaving the card; or nil if one can't find a spot.
    private static func arrange(_ labels: [Label], size: CGFloat, in card: CGRect) -> [CGRect]? {
        var spots: [CGRect] = []
        for label in labels {
            let spot = nudges.lazy
                .map { frame(of: label, size: size, nudge: $0) }
                .first { candidate in
                    card.contains(CGPoint(x: candidate.midX, y: candidate.midY))
                        && !spots.contains { $0.insetBy(dx: -1.5, dy: 0).intersects(candidate) }
                }
            guard let spot else { return nil }
            spots.append(spot)
        }
        return spots
    }
}
