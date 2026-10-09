import SwiftUI

/// A quick level picker that floats beside a place, like a Messages tapback: the place's flag,
/// waving harder the higher its level, then a capsule of glossy badges, one per level, with the
/// current one ringed and named. Tap a badge to set it, or anywhere else to put it away. A place with
/// subdivisions of its own also gets a way into them. Rather than dimming everything around it, it
/// glows in its level's colour, brighter than the page where the display has HDR headroom.
/// On a map it points at its place, with the kind of place it is in small capitals above its name.
struct LevelTapback: View {
    var status: VisitLevel
    var place: AdministrativeDivision
    var localLanguage: Bool
    /// The place's own subdivisions, such as Japan's prefectures.
    var collection: CollectionSummary?
    /// A line in small capitals above the name, such as "State".
    var eyebrow: String? = nil
    /// Where it points at its place, as on a map. Nil floats it free, as beside a list row.
    var pointer: CalloutPointer? = nil
    var onSelect: (VisitLevel) -> Void
    var onOpenCollection: () -> Void
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var badgeSize = 42
    @State private var hasAppeared = false
    /// How wide the row of badges came out, which the way into the place's subdivisions matches.
    @State private var badgesWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Room for the header, which is overlaid so long names can't widen the picker.
            Color.clear
                .frame(width: 0, height: eyebrow == nil ? 40 : 54)
                .padding([.horizontal, .top], 12)
            // The badges hug their width, and scroll only when a long ladder won't fit.
            ViewThatFits(in: .horizontal) {
                badges
                ScrollView(.horizontal) { badges }
                    .scrollIndicators(.hidden)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { badgesWidth = $0 }
            if let collection {
                Button(action: onOpenCollection) {
                    // Across the picker's whole width, its bar taking up the room between.
                    HStack(spacing: 8) {
                        ScrollingText {
                            Text(collection.label)
                                .font(.subheadline.weight(.semibold))
                        }
                        .layoutPriority(1)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(collection.counted, format: .number)
                                .typeStyle(.count)
                            Text("/ \(collection.total.formatted())")
                                .typeStyle(.countTotal)
                                .foregroundStyle(.secondary)
                        }
                        .fixedSize()
                        StatusTallyBar(
                            tally: collection.tally, total: collection.total, minimumStatus: collection.minimumStatus,
                            showsStripes: false)
                            .frame(minWidth: 32, maxWidth: .infinity)
                            .frame(height: 5)
                        Image(systemName: "chevron.forward")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    // Spans the picker: the badges' width, less this row's margins and padding.
                    .frame(width: badgesWidth > 40 ? badgesWidth - 40 : nil)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.primary.opacity(0.06), in: .capsule)
                    .contentShape(.capsule)
                }
                .buttonStyle(PillButtonStyle())
                .padding([.horizontal, .bottom], 8)
                .accessibilityLabel("\(collection.label), \(collection.counted) of \(collection.total)")
            }
        }
        .overlay(alignment: .top) {
            header.padding([.horizontal, .top], 12)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(pointer?.pointsDown == true ? .bottom : .top, pointer == nil ? 0 : CalloutShape.pointerHeight)
        .glassPanel(in: shape, tint: status == .never ? nil : status.color, interactive: true)
        .background {
            // A halo behind the glass, which the glass takes up as if lit from within.
            shape
                .fill(glow)
                .padding(-3)
                .blur(radius: 16)
                .opacity(0.55)
                .accessibilityHidden(true)
        }
        .overlay {
            shape
                .stroke(glow.opacity(0.9), lineWidth: 1.2)
                .padding(0.6)
                .allowsHitTesting(false)
        }
        .animation(.smooth(duration: 0.5), value: status)
        .onAppear { hasAppeared = true }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Level for \(place.name)")
    }

    /// A rounded panel, with a point towards its place when it has one.
    private var shape: AnyShape {
        let radius = badgeSize / 2 + 12
        guard let pointer else { return AnyShape(.rect(cornerRadius: radius, style: .continuous)) }
        return AnyShape(CalloutShape(pointerX: pointer.x, pointsDown: pointer.pointsDown, cornerRadius: radius))
    }

    /// The picker's glow: its level's colour, or white before the place has one.
    private var glow: Color {
        (status == .never ? Color.white : status.color).glowing(by: 1.5)
    }

    /// The flag, in colour once the place has a level, beside the place's names. Names too long for
    /// the picker scroll to show their ends rather than cutting off.
    private var header: some View {
        HStack(spacing: 12) {
            Image(place.flagAssetName)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 6))
                .grayscale(status == .never ? 1 : 0)
                .frame(width: 60, height: 40)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                .animation(.smooth(duration: 0.8), value: status)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                if let eyebrow {
                    ScrollingText {
                        Text(eyebrow)
                            .typeStyle(.smallEyebrow)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 2)
                }
                let name = place.displayName(localLanguage: localLanguage)
                ScrollingText {
                    Text(name)
                        .typeStyle(.compactPlaceName, language: place.language(of: name))
                }
                if let subtitle = place.subtitle(localLanguage: localLanguage) {
                    ScrollingText {
                        Text(subtitle)
                            .placeName(place.language(of: subtitle))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var badges: some View {
        let levels = ladder.allLevels
        return HStack(spacing: 6) {
            ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                // The first and last names line up with their badge's outer edge, so they stay inside.
                badge(for: level, nameAlignment: index == 0 ? .leading : index == levels.count - 1 ? .trailing : .center)
                    .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.3)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.15) : .bouncy(duration: 0.4, extraBounce: 0.2).delay(Double(index) * 0.03),
                        value: hasAppeared)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 20)
        .padding(.bottom, collection == nil ? 8 : 0)
    }

    private func badge(for level: VisitLevel, nameAlignment: HorizontalAlignment) -> some View {
        let isCurrent = level.id == status.id
        return Button {
            onSelect(level)
        } label: {
            Image(systemName: level.symbolName)
                .font(.system(size: badgeSize * 0.4, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5)
                .frame(width: badgeSize, height: badgeSize)
                .background { BadgeGloss(color: level.color) }
                .clipShape(.circle)
                .padding(3)
                .overlay {
                    Circle().strokeBorder(isCurrent ? level.color.glowing(by: 1) : .clear, lineWidth: 2.5)
                }
                .overlay(alignment: Alignment(horizontal: nameAlignment, vertical: .top)) {
                    if isCurrent {
                        // The current level is named just above its badge.
                        Text(level.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(level.color.glowing(by: 1))
                            .lineLimit(1)
                            .fixedSize()
                            .offset(y: -18)
                            .transition(.opacity.combined(with: .offset(y: 4)))
                    }
                }
                .contentShape(.circle)
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel(level.name)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

/// Where a tapback points at its place: how far along its width, and whether it sits above the place.
struct CalloutPointer: Equatable {
    var x: CGFloat
    var pointsDown: Bool
}

/// The pills' glossy finish on a round badge.
private struct BadgeGloss: View {
    var color: Color

    var body: some View {
        ZStack {
            color
            Color.white
                .mask(LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .center))
            color.brightness(-0.2)
                .mask(LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom))
        }
    }
}

/// Where the place a tapback belongs to sits, so the tapback can float beside it.
struct TapbackAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

extension Color {
    /// The colour made brighter by a number of exposure stops, past the white of the page where the
    /// display has HDR headroom. Earlier systems keep the colour as it is.
    func glowing(by stops: Double) -> Color {
        if #available(iOS 26.0, *) {
            return exposureAdjust(stops)
        }
        return self
    }
}
