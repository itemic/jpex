import SwiftUI

extension WorldGroup {
    var symbolName: String {
        switch self {
        case .unitedNations: "globe"
        case .g7: "7.circle.fill"
        case .g20: "20.circle.fill"
        case .europeanUnion: "star.circle.fill"
        case .schengen: "airplane"
        case .eurozone: "eurosign"
        case .nato: "shield.fill"
        case .commonwealth: "crown.fill"
        case .asean: "leaf.fill"
        case .africanUnion: "globe.europe.africa.fill"
        case .arabLeague: "moon.stars.fill"
        case .oecd: "chart.line.uptrend.xyaxis"
        case .brics: "square.grid.2x2.fill"
        case .gulfCooperation: "sun.max.fill"
        case .opec: "drop.fill"
        case .mercosur: "sparkles"
        case .caricom: "water.waves"
        case .efta: "arrow.left.arrow.right"
        case .nordic: "snowflake"
        case .baltic: "wind"
        case .benelux: "bicycle"
        }
    }

    /// The colour of the group's badge, after its emblem where it has one.
    var color: Color {
        switch self {
        case .unitedNations: Color(red: 0.00, green: 0.62, blue: 0.86)
        case .europeanUnion, .schengen, .eurozone: Color(red: 0.00, green: 0.20, blue: 0.60)
        case .nato: Color(red: 0.00, green: 0.18, blue: 0.40)
        case .g7, .g20, .oecd: .indigo
        case .commonwealth: .purple
        case .asean: Color(red: 0.00, green: 0.25, blue: 0.62)
        case .africanUnion: Color(red: 0.16, green: 0.55, blue: 0.27)
        case .arabLeague, .gulfCooperation: .green
        case .brics: .orange
        case .opec: Color(red: 0.25, green: 0.25, blue: 0.27)
        case .mercosur: .blue
        case .caricom: .teal
        case .efta: .red
        case .nordic: .cyan
        case .baltic: .mint
        case .benelux: .orange
        }
    }

    /// The symbol's colour on the badge: gold on the European blues, as on their flag.
    var symbolColor: Color {
        switch self {
        case .europeanUnion, .schengen, .eurozone: .yellow
        default: .white
        }
    }

    var emblem: GroupEmblem {
        GroupEmblem(symbolName: symbolName, color: color, symbolColor: symbolColor, flagAssetName: flagAssetName)
    }

    /// The colour a copy of the group starts with: the nearest of those the person's own groups wear.
    var copyTint: LevelColor {
        switch self {
        case .unitedNations, .nordic: .lightBlue
        case .europeanUnion, .schengen, .eurozone, .asean, .mercosur: .blue
        case .nato, .g7, .g20, .oecd: .indigo
        case .commonwealth: .purple
        case .africanUnion, .arabLeague, .gulfCooperation: .green
        case .brics, .benelux: .orange
        case .opec: .brown
        case .caricom, .baltic: .mint
        case .efta: .red
        }
    }
}

extension CustomWorldGroup {
    var emblem: GroupEmblem {
        GroupEmblem(
            symbolName: symbolName, color: tint.color, symbolColor: flag?.symbolColor.color ?? .white,
            flag: flag?.resolvingSymbols(fallback: symbolName))
    }
}

extension CustomGroupDraft {
    /// The badge as it'll be saved.
    var emblem: GroupEmblem {
        group.emblem
    }
}

extension CustomWorldGroups {
    /// The badge of a group of countries, the World's or the person's own; nil for any other list.
    func emblem(for collection: Country) -> GroupEmblem? {
        collection.worldGroup?.emblem ?? group(collectionID: collection.id)?.emblem
    }
}

/// How a group of countries is drawn: its symbol on a tile in its colour, or on a flag of the
/// person's design.
struct GroupEmblem: Hashable {
    /// The symbol, or empty for none.
    var symbolName: String
    var color: Color
    var symbolColor: Color = .white
    /// A flag to draw in place of the plain tile.
    var flag: GroupFlag? = nil
    /// The group's own flag as an image, such as the EU's, which stands without a symbol.
    var flagAssetName: String? = nil
}

/// A group's badge, at any size: its own flag, or its symbol on a tile in its colour or over a
/// flag of the person's design. The symbol grows with the badge.
struct WorldGroupBadge: View {
    var emblem: GroupEmblem
    /// How tall the symbol stands, as a share of the badge's height.
    var symbolScale: CGFloat = 0.58

    var body: some View {
        Group {
            if let asset = emblem.flagAssetName {
                Image(asset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let flag = emblem.flag {
                FlagPatternView(flag: flag)
            } else {
                Rectangle().fill(emblem.color.gradient)
            }
        }
        .overlay {
            if emblem.flagAssetName != nil {
                // The group's own flag stands without a symbol.
            } else if let flag = emblem.flag {
                // Each symbol in its spot on the flag, sized for it.
                GeometryReader { proxy in
                    let size = proxy.size
                    let placements = flag.placements
                    ForEach(placements, id: \.symbol.id) { placement in
                        let anchor = flag.anchor(of: placement.area)
                        let scale = flag.symbolScale(at: placement.area, count: placements.count) * symbolScale / 0.58
                        Image(systemName: placement.symbol.name)
                            .font(.system(size: size.height * scale, weight: .bold))
                            .foregroundStyle(placement.symbol.color.color)
                            .shadow(color: .black.opacity(0.18), radius: 0.5, y: 0.5)
                            .position(x: anchor.x * size.width, y: anchor.y * size.height)
                    }
                }
            } else if !emblem.symbolName.isEmpty {
                GeometryReader { proxy in
                    Image(systemName: emblem.symbolName)
                        .font(.system(size: proxy.size.height * symbolScale, weight: .bold))
                        .foregroundStyle(emblem.symbolColor)
                        .shadow(color: .black.opacity(emblem.flag == nil ? 0 : 0.18), radius: 0.5, y: 0.5)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
    }
}

/// A flag's pattern in its colours, drawn to fill whatever it's given, with a soft sheen from the
/// top like the app's other tiles. Each colour is laid over the one before, so no hairline of the
/// field shows between parts.
struct FlagPatternView: View {
    var flag: GroupFlag

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let colors = (0..<3).map { flag.color(at: $0).color }
            func fill(_ path: Path, _ index: Int) {
                context.fill(path, with: .color(colors[index]))
            }
            func fill(_ rect: CGRect, _ index: Int) {
                fill(Path(rect), index)
            }
            fill(CGRect(origin: .zero, size: size), 0)
            // A cross's arm, a fifth of the flag's height.
            let bar = h * 0.2
            // The half below the diagonal from the foot of the hoist to the top of the fly.
            var lowerTriangle = Path()
            lowerTriangle.move(to: CGPoint(x: w, y: 0))
            lowerTriangle.addLine(to: CGPoint(x: w, y: h))
            lowerTriangle.addLine(to: CGPoint(x: 0, y: h))
            lowerTriangle.closeSubpath()
            func circle(radius: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: w / 2 - radius, y: h / 2 - radius, width: radius * 2, height: radius * 2))
            }
            switch flag.pattern {
            case .plain:
                break
            case .horizontalBicolor:
                fill(CGRect(x: 0, y: h / 2, width: w, height: h / 2), 1)
            case .verticalBicolor:
                fill(CGRect(x: w / 2, y: 0, width: w / 2, height: h), 1)
            case .horizontalTricolor:
                fill(CGRect(x: 0, y: h / 3, width: w, height: h * 2 / 3), 1)
                fill(CGRect(x: 0, y: h * 2 / 3, width: w, height: h / 3), 2)
            case .verticalTricolor:
                fill(CGRect(x: w / 3, y: 0, width: w * 2 / 3, height: h), 1)
                fill(CGRect(x: w * 2 / 3, y: 0, width: w / 3, height: h), 2)
            case .nordicCross:
                // Its upright set towards the hoist, as on the Nordic flags.
                fill(CGRect(x: w * 0.36 - bar / 2, y: 0, width: bar, height: h), 1)
                fill(CGRect(x: 0, y: (h - bar) / 2, width: w, height: bar), 1)
            case .cross:
                fill(CGRect(x: (w - bar) / 2, y: 0, width: bar, height: h), 1)
                fill(CGRect(x: 0, y: (h - bar) / 2, width: w, height: bar), 1)
            case .saltire:
                var saltire = Path()
                saltire.move(to: .zero)
                saltire.addLine(to: CGPoint(x: w, y: h))
                saltire.move(to: CGPoint(x: 0, y: h))
                saltire.addLine(to: CGPoint(x: w, y: 0))
                context.stroke(saltire, with: .color(colors[1]), lineWidth: bar)
            case .diagonal:
                fill(lowerTriangle, 1)
            case .centreBand:
                // Spain's: the middle band twice the height of each beside it.
                fill(CGRect(x: 0, y: h / 4, width: w, height: h / 2), 1)
            case .pale:
                // Canada's: the middle band twice the width of each side.
                fill(CGRect(x: w / 4, y: 0, width: w / 2, height: h), 1)
            case .fiveStripes:
                // Thailand's: a centre band twice the height of each stripe around it.
                fill(CGRect(x: 0, y: h / 6, width: w, height: h * 2 / 3), 1)
                fill(CGRect(x: 0, y: h / 3, width: w, height: h / 3), 2)
            case .hoistBand:
                // The United Arab Emirates': an upright band at the hoist, beside two bands.
                fill(CGRect(x: w / 4, y: 0, width: w * 3 / 4, height: h / 2), 1)
                fill(CGRect(x: w / 4, y: h / 2, width: w * 3 / 4, height: h / 2), 2)
            case .borderedCross:
                // Norway's: a Nordic cross with a border of its own.
                let outer = h * 0.26
                let inner = h * 0.13
                fill(CGRect(x: w * 0.36 - outer / 2, y: 0, width: outer, height: h), 1)
                fill(CGRect(x: 0, y: (h - outer) / 2, width: w, height: outer), 1)
                fill(CGRect(x: w * 0.36 - inner / 2, y: 0, width: inner, height: h), 2)
                fill(CGRect(x: 0, y: (h - inner) / 2, width: w, height: inner), 2)
            case .quartered:
                fill(CGRect(x: w / 2, y: 0, width: w / 2, height: h / 2), 1)
                fill(CGRect(x: 0, y: h / 2, width: w / 2, height: h / 2), 1)
            case .diagonalBand:
                // Tanzania's: a band from the foot of the hoist to the top of the fly.
                fill(lowerTriangle, 2)
                var band = Path()
                band.move(to: CGPoint(x: 0, y: h))
                band.addLine(to: CGPoint(x: w, y: 0))
                context.stroke(band, with: .color(colors[1]), lineWidth: h * 0.32)
            case .canton:
                fill(CGRect(x: 0, y: 0, width: w / 2, height: h / 2), 1)
            case .stripesAndCanton:
                for stripe in stride(from: 1, to: 7, by: 2) {
                    fill(CGRect(x: 0, y: h * CGFloat(stripe) / 7, width: w, height: h / 7), 1)
                }
                fill(CGRect(x: 0, y: 0, width: w * 0.42, height: h * 4 / 7), 2)
            case .border:
                fill(CGRect(origin: .zero, size: size), 1)
                fill(CGRect(origin: .zero, size: size).insetBy(dx: h * 0.12, dy: h * 0.12), 0)
            case .roundel:
                fill(circle(radius: h * 0.4), 1)
                fill(circle(radius: h * 0.2), 2)
            case .diamond:
                // Brazil's: a lozenge reaching almost to every edge.
                var diamond = Path()
                diamond.move(to: CGPoint(x: w * 0.08, y: h / 2))
                diamond.addLine(to: CGPoint(x: w / 2, y: h * 0.1))
                diamond.addLine(to: CGPoint(x: w * 0.92, y: h / 2))
                diamond.addLine(to: CGPoint(x: w / 2, y: h * 0.9))
                diamond.closeSubpath()
                fill(diamond, 1)
            case .chequered:
                let side = h / 4
                var squares = Path()
                for row in 0..<4 {
                    for column in 0..<Int((w / side).rounded(.up)) where (row + column) % 2 == 1 {
                        squares.addRect(CGRect(x: CGFloat(column) * side, y: CGFloat(row) * side, width: side, height: side))
                    }
                }
                fill(squares, 1)
            case .triangle:
                fill(CGRect(x: 0, y: h / 2, width: w, height: h / 2), 1)
                var triangle = Path()
                triangle.move(to: .zero)
                triangle.addLine(to: CGPoint(x: w * 0.45, y: h / 2))
                triangle.addLine(to: CGPoint(x: 0, y: h))
                triangle.closeSubpath()
                fill(triangle, 2)
            case .stripes:
                for stripe in stride(from: 1, to: 7, by: 2) {
                    fill(CGRect(x: 0, y: h * CGFloat(stripe) / 7, width: w, height: h / 7), 1)
                }
            case .disc:
                let radius = h * 0.3
                fill(Path(ellipseIn: CGRect(x: w / 2 - radius, y: h / 2 - radius, width: radius * 2, height: radius * 2)), 1)
            }
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.22), .white.opacity(0)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.6)))
        }
    }
}
