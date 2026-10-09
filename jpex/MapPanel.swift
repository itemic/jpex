import SwiftUI

/// The panel over the foot of the map: how many places count, a pill per level that brings
/// those places forward, and, opened up, every place with a level set as type.
/// Where the device folds, the panel gets a region of its own and the names fill it.
struct MapPanel: View {
    var collection: Country
    var statuses: [String: VisitLevel]
    var counted: Int
    var tally: [String: Int]
    @Binding var highlight: VisitLevel?
    @Binding var showsNames: Bool
    /// True when the panel sits in its own region beside the map rather than over it.
    var isSeparate: Bool
    var maxNamesHeight: CGFloat
    var localLanguage: Bool
    var onSelect: (AdministrativeDivision) -> Void
    @Environment(\.visitLadder) private var ladder
    @State private var namesHeight: CGFloat = 0
    @State private var namesOverflow = NamesOverflow()
    /// Whether there are more level pills to scroll to before or after the visible ones.
    @State private var legendOverflow = NamesOverflow()
    @Namespace private var count

    private var isOpen: Bool { showsNames || isSeparate }

    var body: some View {
        VStack(alignment: .leading, spacing: isOpen ? 12 : 0) {
            if isOpen {
                header
                    .padding(.horizontal, 18)
                    .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .bottomLeading)))
            }
            HStack(spacing: 4) {
                if !isOpen {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(counted, format: .number)
                            .typeStyle(.count)
                            .contentTransition(.numericText(value: Double(counted)))
                        Text("/ \(collection.divisions.count.formatted())")
                            .typeStyle(.countTotal)
                            .foregroundStyle(.secondary)
                    }
                    .matchedGeometryEffect(id: "count", in: count, properties: .position, anchor: .leading)
                    .padding(.leading, 18)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(counted) of \(collection.divisions.count) counted")
                    .transition(.opacity.combined(with: .scale(scale: 1.6, anchor: .leading)))
                }
                legend
                if !isSeparate {
                    toggle
                        .padding(.trailing, 8)
                }
            }
            if isOpen {
                names
                    .transition(.opacity)
            }
        }
        .padding(.vertical, isOpen ? 16 : 6)
        .frame(maxWidth: isSeparate ? .infinity : 600, maxHeight: isSeparate ? .infinity : nil, alignment: .top)
        // Bringing a level forward tints the glass with that level's colour.
        .glassPanel(in: .rect(cornerRadius: 28), tint: highlight?.color)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .frame(maxHeight: isSeparate ? .infinity : nil, alignment: .bottom)
        .sensoryFeedback(.selection, trigger: highlight)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: -2) {
            Text(collection.divisionLabel)
                .typeStyle(.eyebrow)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(counted, format: .number)
                    .typeStyle(.panelCount)
                    .contentTransition(.numericText(value: Double(counted)))
                Text("/ \(collection.divisions.count.formatted())")
                    .typeStyle(.panelTotal)
                    .foregroundStyle(.secondary)
            }
            .matchedGeometryEffect(id: "count", in: count, properties: .position, anchor: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(counted) of \(collection.divisions.count) \(collection.divisionLabel.lowercased()) counted")
    }

    /// A pill for every level. When they don't all fit the closed bar, each shrinks to a glossy
    /// count in its level's colour and pattern, so none is cut off; scrolling is the last resort.
    private var legend: some View {
        ViewThatFits(in: .horizontal) {
            legendPills(compact: false)
            if !isOpen {
                legendPills(compact: true)
            }
            scrollingLegend
        }
    }

    private func legendPills(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            ForEach(ladder.levels) { level in
                let count = tally[level.id, default: 0]
                let isHighlighted = highlight?.id == level.id
                Button {
                    withAnimation(.snappy) { highlight = isHighlighted ? nil : level }
                } label: {
                    if compact {
                        VisitPillLabel(status: countOnly(level, count), isLit: highlight == nil || isHighlighted)
                            .frame(minWidth: 34)
                    } else {
                        VisitPillLabel(status: level, suffix: " \(count)", isLit: highlight == nil || isHighlighted)
                    }
                }
                .buttonStyle(PillButtonStyle())
                .accessibilityLabel("\(level.name), \(count)")
                .accessibilityHint(isHighlighted ? "Shows every level." : "Brings these places forward.")
                .accessibilityAddTraits(isHighlighted ? .isSelected : [])
            }
        }
        .fixedSize()
        .padding(.horizontal, isOpen ? 18 : 8)
        .padding(.vertical, 10)
    }

    /// The level wearing just its count as a name, for the compact closed bar.
    private func countOnly(_ level: VisitLevel, _ count: Int) -> VisitLevel {
        var short = level
        short.name = count.formatted()
        return short
    }

    private var scrollingLegend: some View {
        ScrollView(.horizontal) {
            legendPills(compact: !isOpen)
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: NamesOverflow.self) { geometry in
            let hiddenAfter = geometry.contentSize.width - geometry.contentOffset.x - geometry.containerSize.width
            return NamesOverflow(above: geometry.contentOffset.x > 1, below: hiddenAfter > 1)
        } action: { _, overflow in
            legendOverflow = overflow
        }
        // Pills that run past either end fade away rather than being cut through.
        .mask {
            HStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(legendOverflow.above ? 0 : 1), .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 22)
                Color.black
                LinearGradient(colors: [.black, .black.opacity(legendOverflow.below ? 0 : 1)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 30)
            }
        }
    }

    private var toggle: some View {
        Button(showsNames ? "Hide names" : "Show names", systemImage: "chevron.up") {
            withAnimation(.smooth(duration: 0.45)) { showsNames.toggle() }
        }
        .labelStyle(.iconOnly)
        .font(.subheadline.weight(.semibold))
        .rotationEffect(.degrees(showsNames ? 180 : 0))
        .frame(width: 40, height: 40)
        .contentShape(Circle())
        .buttonStyle(PillButtonStyle())
        .foregroundStyle(.secondary)
    }

    private var names: some View {
        ScrollView {
            VisitedNamesView(
                places: collection.divisions, statuses: statuses, localLanguage: localLanguage, onSelect: onSelect
            )
            .padding(.horizontal, 18)
            .padding(.top, 2)
            .padding(.bottom, 12)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { namesHeight = $0 }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: NamesOverflow.self) { geometry in
            let hiddenBelow = geometry.contentSize.height - geometry.contentOffset.y - geometry.containerSize.height
            return NamesOverflow(above: geometry.contentOffset.y > 1, below: hiddenBelow > 1)
        } action: { _, overflow in
            namesOverflow = overflow
        }
        // Names that run past the panel's edge fade away rather than being cut through.
        .mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(namesOverflow.above ? 0 : 1), .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 24)
                Color.black
                LinearGradient(colors: [.black, .black.opacity(namesOverflow.below ? 0 : 1)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 36)
            }
        }
        .frame(height: isSeparate ? nil : min(namesHeight, maxNamesHeight))
        .frame(maxHeight: isSeparate ? .infinity : nil)
    }
}

/// Whether there is more to scroll to before (above) or after (below) what's visible.
private struct NamesOverflow: Equatable {
    var above = false
    var below = false
}
