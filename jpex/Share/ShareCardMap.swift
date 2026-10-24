import SwiftUI

/// A list's map as the share card draws it: the land in the card's design, and the places the person
/// has been in their levels' colours, glowing on a dark card; or each wearing its own flag; or all in
/// the card's one colour. Places too small to see are marked with a dot so none goes missing. The
/// framed part of the map is fitted into the room the card's words leave, and the map runs on
/// beneath them to the card's edges. A new frame glides there, and the colours sweep in from the
/// west as the card first appears.
struct ShareCardMap: View, Animatable {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring = .levels
    /// Each place's flag, by its ID, for colouring the places by their flags.
    var flags: [String: String] = [:]
    /// Each place's own colour, by its ID, for colouring the places smartly.
    var smartColors: [String: Color] = [:]
    /// Places to pick out, such as those newly been to: the rest been to step back, faded towards
    /// the land, and these are outlined. Nil picks out none.
    var highlighted: Set<String>? = nil
    /// The part of the map to fit, in the map's own units.
    var focus: CGRect
    /// Room kept clear around the fitted part, for the words over the map.
    var insets: EdgeInsets
    /// How far the colours have swept in from the west, from 0 to 1.
    var reveal: Double = 1

    var animatableData: AnimatablePair<Double, CGRect.AnimatableData> {
        get { AnimatablePair(reveal, focus.animatableData) }
        set {
            reveal = newValue.first
            focus.animatableData = newValue.second
        }
    }

    /// The area the framed part is fitted into: the card, less the room around it.
    static func fitRect(in size: CGSize, insets: EdgeInsets) -> CGRect {
        CGRect(
            x: insets.leading, y: insets.top,
            width: max(size.width - insets.leading - insets.trailing, 1),
            height: max(size.height - insets.top - insets.bottom, 1))
    }

    /// Carries the map's units onto the card: the focus as large as fits, centred in the area.
    static func transform(fitting focus: CGRect, into area: CGRect) -> CGAffineTransform {
        let scale = min(area.width / max(focus.width, 0.0001), area.height / max(focus.height, 0.0001))
        return CGAffineTransform(
            a: scale, b: 0, c: 0, d: scale,
            tx: area.midX - focus.midX * scale, ty: area.midY - focus.midY * scale)
    }

    var body: some View {
        Canvas { context, size in
            let transform = Self.transform(fitting: focus, into: Self.fitRect(in: size, insets: insets))
            let scale = transform.a
            guard scale > 0, scale.isFinite else { return }
            var land = context
            land.concatenate(transform)
            // A whole World shows its edge and lines of latitude and longitude, and keeps its land inside.
            if let outline = map.outline {
                land.fill(outline, with: .color(palette.sea))
                if let graticule = map.graticule {
                    land.stroke(graticule, with: .color(palette.graticule), lineWidth: 0.5 / scale)
                }
                land.clip(to: outline)
            }
            // The land around the list, such as the rest of the World round a group of countries.
            for region in map.regions where statuses[region.id] == nil {
                land.fill(region.path, with: .color(palette.outsideLand), style: FillStyle(eoFill: true))
            }
            for area in map.disputedAreas {
                land.fill(area.path, with: .color(palette.outsideLand), style: FillStyle(eoFill: true))
            }
            // Places been to take their colour as the sweep passes them; the rest are plain land.
            let sweep = reveal * (size.width + 120) - 60
            var lit: [String: (level: VisitLevel, regions: [MapRegion])] = [:]
            for region in map.regions {
                guard let status = statuses[region.id] else { continue }
                if status.id != VisitLevel.never.id, region.center.applying(transform).x <= sweep {
                    lit[status.id, default: (status, [])].regions.append(region)
                } else {
                    land.fill(region.path, with: .color(palette.land), style: FillStyle(eoFill: true))
                }
            }
            let litRegions = lit.values.flatMap(\.regions)
            switch colouring {
            case .levels:
                for (level, regions) in lit.values {
                    fill(regions, with: level.color, in: context, transform: transform)
                }
            case .plain:
                fill(litRegions, with: palette.plainFill, in: context, transform: transform)
            case .flags:
                drawFlags(on: litRegions, in: context, transform: transform)
            case .smart:
                // Each colour's places together, so they glow as one.
                for (color, regions) in Dictionary(grouping: litRegions, by: { smartColors[$0.id] ?? palette.plainFill }) {
                    fill(regions, with: color, in: context, transform: transform)
                }
            }
            // Picking out some places, the others been to fade back towards the land.
            if let highlighted {
                for region in litRegions where !highlighted.contains(region.id) {
                    land.fill(region.path, with: .color(palette.land.opacity(0.7)), style: FillStyle(eoFill: true))
                }
            }
            for region in map.regions {
                land.stroke(region.path, with: .color(palette.border), lineWidth: 0.6 / scale)
            }
            if let highlighted {
                for region in litRegions where highlighted.contains(region.id) {
                    land.stroke(region.path, with: .color(palette.text.opacity(0.9)), lineWidth: 1.6 / scale)
                }
            }
            // On a colourful card, each place been to is outlined so its colour stands clear.
            if let outline = palette.visitedOutline {
                for region in litRegions {
                    land.stroke(region.path, with: .color(outline.opacity(0.9)), lineWidth: 1.1 / scale)
                }
            }
            // Boxes round insets, such as Okinawa's or Alaska's.
            for frame in map.frames {
                land.stroke(
                    Path(roundedRect: frame, cornerRadius: 8 / scale), with: .color(palette.secondaryText.opacity(0.5)),
                    style: StrokeStyle(lineWidth: 0.75 / scale, dash: [3 / scale, 3 / scale]))
            }
            // Places too small to see, such as Malta on the World, as a dot in their colour.
            for (level, regions) in lit.values {
                for region in regions {
                    let box = region.bounds.applying(transform)
                    guard max(box.width, box.height) < 3 else { continue }
                    let center = region.center.applying(transform)
                    let dot = Path(ellipseIn: CGRect(x: center.x - 2.6, y: center.y - 2.6, width: 5.2, height: 5.2))
                    context.fill(dot, with: .color(dotColor(of: region, level: level)))
                    context.stroke(dot, with: .color(palette.border), lineWidth: 0.8)
                }
            }
        }
    }

    /// Places in one colour, glowing on a dark card. The glow is set on the card's own scale, before
    /// the map's, so it's as soft on a close-up of Kyoto as on the whole World.
    private func fill(_ regions: [MapRegion], with color: Color, in context: GraphicsContext, transform: CGAffineTransform) {
        context.drawLayer { layer in
            if palette.glows {
                layer.addFilter(.shadow(color: color.opacity(0.9), radius: 6))
            }
            layer.concatenate(transform)
            if let outline = map.outline { layer.clip(to: outline) }
            for region in regions {
                layer.fill(region.path, with: .color(color), style: FillStyle(eoFill: true))
            }
        }
    }

    /// Each place wearing its own flag, cut to its outline: the flag at its own shape, just covering
    /// the place.
    private func drawFlags(on regions: [MapRegion], in context: GraphicsContext, transform: CGAffineTransform) {
        let pixels = context.environment.displayScale
        for region in regions {
            let box = region.bounds.applying(transform)
            guard max(box.width, box.height) >= 3, let name = flags[region.id],
                  let image = FlagThumbnails.image(named: name, filling: box.size, scale: pixels),
                  image.size.width > 0, image.size.height > 0
            else { continue }
            let aspect = image.size.width / image.size.height
            let cover = box.width / box.height > aspect
                ? CGSize(width: box.width, height: box.width / aspect)
                : CGSize(width: box.height * aspect, height: box.height)
            let resolved = context.resolve(Image(uiImage: image))
            context.drawLayer { layer in
                var shape = region.path.applying(transform)
                if let outline = map.outline {
                    // Kept within the World's edge, as the land is.
                    shape = shape.intersection(outline.applying(transform))
                }
                layer.clip(to: shape, style: FillStyle(eoFill: true))
                layer.draw(resolved, in: CGRect(
                    x: box.midX - cover.width / 2, y: box.midY - cover.height / 2,
                    width: cover.width, height: cover.height))
            }
        }
    }

    /// A tiny place's dot: its level's colour, its flag's main colour, its own, or the card's one colour.
    private func dotColor(of region: MapRegion, level: VisitLevel) -> Color {
        switch colouring {
        case .levels: level.color
        case .plain: palette.plainFill
        case .smart: smartColors[region.id] ?? palette.plainFill
        case .flags: flags[region.id].flatMap { FlagColors.of($0)?.colors.first } ?? level.color
        }
    }
}
