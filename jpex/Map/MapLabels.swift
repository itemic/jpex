import SwiftUI

/// A place's name to set on the map.
struct MapLabel: Equatable {
    var text: String
    /// The language the name is written in, when it's a local name.
    var language: Locale.Language?
    /// The place's level rank: places you know better claim room first.
    var rank: Int
}

/// Sets place names on a map: only where a name fits inside its place, never overlapping
/// another, with the places you know best and then the biggest claiming room first.
/// Each name sits on a soft halo so it reads over any colour.
enum MapLabels {
    static func draw(
        _ labels: [String: MapLabel], regions: [MapRegion], in context: GraphicsContext,
        geometry: MapGeometry, opacity: Double, limit: Int = 60
    ) {
        guard opacity > 0.01, !labels.isEmpty else { return }
        var layer = context
        layer.opacity = opacity
        layer.drawLayer { labelsLayer in
            labelsLayer.addFilter(.shadow(color: Color(uiColor: .systemBackground).opacity(0.9), radius: 1.6))
            labelsLayer.addFilter(.shadow(color: Color(uiColor: .systemBackground).opacity(0.5), radius: 4))
            for placement in layout(labels, regions: regions, in: labelsLayer, geometry: geometry, limit: limit) {
                placement.name.draw(in: labelsLayer, centeredAt: placement.center)
            }
        }
    }

    /// The room each name set by `draw` takes on screen, with a little space around it, so things
    /// drawn over the map, such as cities' names, can keep clear of them.
    static func frames(
        _ labels: [String: MapLabel], regions: [MapRegion], in context: GraphicsContext,
        geometry: MapGeometry, limit: Int = 60
    ) -> [CGRect] {
        layout(labels, regions: regions, in: context, geometry: geometry, limit: limit).map(\.claim)
    }

    /// Where each name goes: only where it fits inside its place, never overlapping another.
    private static func layout(
        _ labels: [String: MapLabel], regions: [MapRegion], in context: GraphicsContext,
        geometry: MapGeometry, limit: Int
    ) -> [Placement] {
        guard !labels.isEmpty else { return [] }
        let visible = CGRect(origin: .zero, size: geometry.size).insetBy(dx: 4, dy: 4)
        var candidates: [(region: MapRegion, label: MapLabel, box: CGRect)] = []
        for region in regions {
            guard let label = labels[region.id] else { continue }
            let box = region.bounds.applying(geometry.transform)
            // Too small for even a short name, or off screen: skip before measuring anything.
            guard box.width >= 34, box.height >= 13, box.intersects(visible),
                  CGFloat(label.text.count) * 4.5 < box.width * 1.6
            else { continue }
            candidates.append((region, label, box))
        }
        candidates.sort { first, second in
            if first.label.rank != second.label.rank { return first.label.rank > second.label.rank }
            return first.box.width * first.box.height > second.box.width * second.box.height
        }
        var placements: [Placement] = []
        for candidate in candidates.prefix(limit * 2) {
            let box = candidate.box
            let size = min(max(min(box.height * 0.22, box.width * 0.11), 10), 15).rounded()
            let room = CGSize(width: box.width * 0.9, height: box.height * 0.8)
            // A name sits on one line, or breaks into two at the space nearest its middle;
            // it never breaks inside a word.
            guard let name = fittedName(candidate.label, size: size, room: room, in: context) else { continue }
            let center = geometry.toScreen(candidate.region.center)
            let rect = CGRect(
                x: center.x - name.size.width / 2, y: center.y - name.size.height / 2,
                width: name.size.width, height: name.size.height)
            let claim = rect.insetBy(dx: -4, dy: -2)
            guard visible.contains(center), !placements.contains(where: { $0.claim.intersects(claim) }) else { continue }
            placements.append(Placement(name: name, center: center, claim: claim))
            if placements.count >= limit { break }
        }
        return placements
    }

    private struct Placement {
        var name: FittedName
        var center: CGPoint
        var claim: CGRect
    }

    /// A name's lines, each measured, if they fit the room.
    private static func fittedName(
        _ label: MapLabel, size: CGFloat, room: CGSize, in context: GraphicsContext
    ) -> FittedName? {
        let unbounded = CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        for lines in [[label.text], twoLines(label.text)].compactMap({ $0 }) {
            let resolved = lines.map { line in
                context.resolve(
                    Text(line)
                        .placeName(label.language, kerning: size > 12 ? 0.2 : 0)
                        .font(.system(size: size, weight: label.rank > 0 ? .semibold : .medium))
                        .foregroundStyle(label.rank > 0 ? .primary : .secondary))
            }
            let sizes = resolved.map { $0.measure(in: unbounded) }
            let total = CGSize(width: sizes.map(\.width).max() ?? 0, height: sizes.map(\.height).reduce(0, +) * 0.92)
            if total.width <= room.width, total.height <= room.height {
                return FittedName(lines: Array(zip(resolved, sizes)), size: total)
            }
        }
        return nil
    }

    /// The name split at the space nearest its middle, or nil for a single word.
    private static func twoLines(_ name: String) -> [String]? {
        let spaces = name.indices.filter { name[$0] == " " }
        let middle = name.count / 2
        guard let split = spaces.min(by: {
            abs(name.distance(from: name.startIndex, to: $0) - middle)
                < abs(name.distance(from: name.startIndex, to: $1) - middle)
        }) else { return nil }
        return [String(name[..<split]), String(name[name.index(after: split)...])]
    }
}

/// A name ready to draw: one or two lines, each centred under the one before.
private struct FittedName {
    var lines: [(text: GraphicsContext.ResolvedText, size: CGSize)]
    var size: CGSize

    func draw(in context: GraphicsContext, centeredAt center: CGPoint) {
        var y = center.y - size.height / 2
        for line in lines {
            context.draw(line.text, at: CGPoint(x: center.x, y: y + line.size.height / 2), anchor: .center)
            y += line.size.height * 0.92
        }
    }
}
