import SwiftUI

/// One way to list a country, as a card like the quiz's answers and World Time's zones: a small
/// map of the country at that level, its places in their levels' colours where the person has
/// been, then the level's name over how many of its places count. It's a label, for a Button or a
/// Menu, which wear `PillButtonStyle`. Colour is kept for the levels: a card that's chosen is
/// highlighted in grey and outlined rather than lit.
struct LevelCard: View {
    var title: String
    var counted: Int
    var total: Int
    /// The country's map at this level, or nil for no picture.
    var map: TravelMap?
    var statuses: [String: VisitLevel]
    /// The strongest level reached, kept for callers; the card no longer takes its colour.
    var level: VisitLevel = .never
    var isOn = false
    /// For a card that opens a menu, such as of the places with lists of their own.
    var opensMenu = false
    /// Small, as beside a list's total for the level it isn't showing.
    var isCompact = false
    /// Whether it says how many places count, which the level shown leaves to the total beside it.
    var showsCount = true
    @ScaledMetric(relativeTo: .callout) private var pictureWidth = 34
    @ScaledMetric(relativeTo: .callout) private var pictureHeight = 30
    @ScaledMetric(relativeTo: .footnote) private var compactPictureWidth = 30
    @ScaledMetric(relativeTo: .footnote) private var compactPictureHeight = 26

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: isCompact ? 12 : 16, style: .continuous)
        HStack(spacing: isCompact ? 8 : 10) {
            if let map {
                LevelMapPicture(map: map, statuses: statuses)
                    .frame(
                        width: isCompact ? compactPictureWidth : pictureWidth,
                        height: isCompact ? compactPictureHeight : pictureHeight)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(titleFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showsCount {
                    // Rolls to a new count, as the total beside it does.
                    Text("\(Text(counted, format: .number).fontWeight(.semibold)) / \(total.formatted())")
                        .font((isCompact ? Font.caption2 : .caption).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(counted)))
                }
            }
            .frame(maxWidth: isCompact ? nil : .infinity, alignment: .leading)
            if opensMenu {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, isCompact ? 9 : 10)
        .padding(.vertical, isCompact ? 7 : 9)
        .frame(maxWidth: isCompact ? nil : .infinity, alignment: .leading)
        .foregroundStyle(.primary)
        .background(isOn ? AnyShapeStyle(.primary.opacity(0.1)) : AnyShapeStyle(.fill.quaternary), in: shape)
        .overlay {
            if isOn {
                shape.strokeBorder(.primary.opacity(0.55), lineWidth: 1.5)
            }
        }
        .contentShape(shape)
        .animation(.easeInOut(duration: 0.18), value: isOn)
        .animation(Motion.count, value: counted)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(counted) of \(total)")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    /// The chosen one's name bolder, so it stands out without a colour of its own, at the same
    /// size, so the cards in a row stay the same height.
    private var titleFont: Font {
        (isCompact ? Font.footnote : .callout).weight(isOn ? .semibold : .medium)
    }
}

/// Another way a list could count its country's places, such as France's departments beside its
/// regions, for a small card beside the total that switches to it.
struct LevelSwitch: Identifiable {
    var id: String
    var title: String
    /// A shorter name for a narrow screen, such as LGAs for local government areas.
    var shortTitle: String? = nil
    var counted: Int
    var total: Int
    var map: TravelMap?
    var statuses: [String: VisitLevel]
    var action: () -> Void = {}
    /// For a level counted place by place, such as Australia's local government areas, which only
    /// some of its states have here, the places to choose from in a menu instead.
    var choices: [LevelMenuChoice] = []
}

/// One place to choose in a level's menu, such as Tasmania for its local government areas.
struct LevelMenuChoice: Identifiable {
    var id: String
    var title: String
    var counted: Int
    var total: Int
    var action: () -> Void
}

/// A country's main body at one level, drawn small: every place outlined, those the person has been
/// to filled in their level's colour. Far-flung insets, such as France's overseas regions, are left
/// out, so the country fills it.
private struct LevelMapPicture: View {
    var map: TravelMap
    var statuses: [String: VisitLevel]

    var body: some View {
        let regions = map.regions.filter { region in !map.frames.contains { $0.intersects(region.bounds) } }
        let bounds = regions.reduce(CGRect.null) { $0.union($1.bounds) }
        Canvas { context, size in
            guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else { return }
            let scale = min(size.width / bounds.width, size.height / bounds.height)
            let transform = CGAffineTransform(
                translationX: (size.width - bounds.width * scale) / 2, y: (size.height - bounds.height * scale) / 2)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: -bounds.minX, y: -bounds.minY)
            for region in regions {
                let path = region.path.applying(transform)
                let level = statuses[region.id] ?? .never
                // A solid grey where the person hasn't been, so the country reads clearly at this size,
                // and hairline borders, which still show how finely it's divided.
                context.fill(
                    path, with: .color(level == .never ? Color(uiColor: .systemGray2) : level.color),
                    style: FillStyle(eoFill: true))
                context.stroke(path, with: .color(Color(uiColor: .systemBackground).opacity(0.75)), lineWidth: 0.3)
            }
        }
    }
}
