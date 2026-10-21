import SwiftUI

/// A country tapped on the welcome's globe, in a bar of glass like a row of the World's list: its
/// flag and name, then a glossy badge for every level, popping in and dancing in a wave until one
/// is picked. Picking one lights the country up in its level's colour; picking it again does nothing
/// more than pop. With Reduce Motion, the badges fade in and hold still.
struct WelcomePlaceBar: View {
    var place: AdministrativeDivision
    var status: VisitLevel
    var localLanguage: Bool
    var onSelect: (VisitLevel) -> Void
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Off with Reduce Motion, in Low Power Mode and while the app isn't in front.
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    @ScaledMetric(relativeTo: .body) private var badgeSize = 42
    @State private var hasAppeared = false
    /// Counts taps on each level's badge, by level, so only the badge tapped bounces.
    @State private var picks: [String: Int] = [:]

    /// The badges dance until a level is picked.
    private var isDancing: Bool {
        status == .never && allowsAmbientMotion && hasAppeared
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            // The badges hug their width, and scroll only when a long ladder won't fit.
            ViewThatFits(in: .horizontal) {
                badges
                ScrollView(.horizontal) { badges }
                    .scrollIndicators(.hidden)
            }
        }
        .padding(16)
        .glassPanel(in: shape, tint: status == .never ? nil : status.color, interactive: true)
        .background {
            // A halo behind the glass, which the glass takes up as if lit from within.
            shape
                .fill(glow)
                .padding(-3)
                .blur(radius: 18)
                .opacity(0.5)
                .accessibilityHidden(true)
        }
        .overlay {
            shape
                .stroke(glow.opacity(0.9), lineWidth: 1.2)
                .padding(0.6)
                .allowsHitTesting(false)
        }
        .animation(Motion.recolour, value: status)
        .task {
            // A beat for the bar to rise before the badges pop in.
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 120))
            hasAppeared = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Level for \(place.name)")
    }

    private var shape: some Shape {
        .rect(cornerRadius: badgeSize / 2 + 16, style: .continuous)
    }

    /// The bar's glow: its level's colour, or white before the country has one.
    private var glow: Color {
        (status == .never ? Color.white : status.color).glowing(by: 1.5)
    }

    /// The flag, in colour once the country has a level, beside its names, as the list sets them.
    private var header: some View {
        HStack(spacing: 12) {
            Image(place.flagAssetName)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 6))
                .grayscale(status == .never ? 1 : 0)
                .frame(width: 54, height: 36)
                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: -2) {
                let name = place.displayName(localLanguage: localLanguage)
                ScrollingText {
                    Text(name)
                        .typeStyle(.placeName, language: place.language(of: name))
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

    /// A badge for every level, popping in one after another, then hopping and swaying in a wave
    /// that runs along the row, until one is picked.
    private var badges: some View {
        let levels = ladder.allLevels
        return TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isDancing)) { timeline in
            let seconds = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 6) {
                ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                    let phase = seconds * 2 * .pi / 1.5 - Double(index) * 0.7
                    let hop = isDancing ? max(sin(phase), 0) : 0
                    let sway = isDancing ? sin(phase) : 0
                    badge(for: level)
                        .scaleEffect(1 + 0.08 * hop, anchor: .bottom)
                        .rotationEffect(.degrees(7 * sway))
                        .offset(y: -9 * hop)
                        .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.2)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(
                            reduceMotion ? .easeOut(duration: 0.2) : .bouncy(duration: 0.5, extraBounce: 0.25).delay(Double(index) * 0.06),
                            value: hasAppeared)
                }
            }
            // Settling down smoothly once a level is picked, rather than freezing mid-hop.
            .animation(.bouncy(duration: 0.5), value: isDancing)
        }
        // Room above for the badges to hop into.
        .padding(.top, 10)
    }

    private func badge(for level: VisitLevel) -> some View {
        let isCurrent = level.id == status.id && status != .never
        return Button {
            picks[level.id, default: 0] += 1
            onSelect(level)
        } label: {
            Image(systemName: level.symbolName)
                .font(.system(size: badgeSize * 0.4, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 0.5, y: 0.5)
                .symbolEffect(.bounce, value: reduceMotion ? 0 : picks[level.id, default: 0])
                .frame(width: badgeSize, height: badgeSize)
                .background { BadgeGloss(color: level.color) }
                .clipShape(.circle)
                .padding(3)
                .overlay {
                    Circle().strokeBorder(isCurrent ? level.color.glowing(by: 1) : .clear, lineWidth: 2.5)
                }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(level.name)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}
