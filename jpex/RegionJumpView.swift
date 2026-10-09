import SwiftUI

/// One region's progress, for jumping to it from any region's header.
struct RegionSummary: Identifiable, Equatable {
    var id: String
    var name: String
    /// The language the name is written in, when it's a local name.
    var language: Locale.Language?
    var counted: Int
    var total: Int
    var tally: [String: Int]
    var strongest: VisitLevel

    var isComplete: Bool { total > 0 && counted >= total }
}

/// Every region as a tile with its count and mix of levels; finished regions wear a seal.
/// The tiles bounce in one after another, and tapping one glides the list to that region.
struct RegionJumpView: View {
    var regions: [RegionSummary]
    var currentID: String
    var minimumStatus: VisitLevel
    var onJump: (String) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .subheadline) private var tileWidth = 146
    @ScaledMetric(relativeTo: .title3) private var letterTileWidth = 58

    /// A list running A to Z jumps by letter, so its tiles can be small squares, several to a row.
    private var isLetters: Bool {
        regions.allSatisfy { $0.name.count <= 2 }
    }
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Jump to")
                .typeStyle(.eyebrow)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            ScrollViewReader { scroller in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: isLetters ? letterTileWidth : tileWidth), spacing: 8)], spacing: 8) {
                        ForEach(Array(regions.enumerated()), id: \.element.id) { index, region in
                            tile(for: region)
                                .id(region.id)
                                .opacity(hasAppeared ? 1 : 0)
                                .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.84)
                                .offset(y: hasAppeared || reduceMotion ? 0 : 10)
                                .animation(
                                    reduceMotion
                                        ? .easeOut(duration: 0.2)
                                        : .bouncy(duration: 0.5, extraBounce: 0.12).delay(min(Double(index) * 0.022, 0.4)),
                                    value: hasAppeared)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(2)
                }
                .scrollBounceBehavior(.basedOnSize)
                // Room for the last row to rise clear of the fade.
                .contentMargins(.bottom, 36, for: .scrollContent)
                // Rows settle whole at the top, so no tile rests cut in half under the title.
                .scrollTargetBehavior(.viewAligned)
                .mask {
                    // Tiles further down fade out at the edge rather than being sliced off.
                    LinearGradient(
                        stops: [.init(color: .black, location: 0.82), .init(color: .black.opacity(0), location: 1)],
                        startPoint: .top, endPoint: .bottom)
                }
                .onAppear { scroller.scrollTo(currentID, anchor: .top) }
            }
        }
        .padding(14)
        .frame(idealWidth: 344, maxHeight: 470)
        .onAppear { hasAppeared = true }
    }

    private func tile(for region: RegionSummary) -> some View {
        let isCurrent = region.id == currentID
        let tint = region.strongest == .never ? Color.secondary : region.strongest.color
        return Button {
            onJump(region.id)
        } label: {
            Group {
                if isLetters {
                    letterTile(for: region, tint: tint)
                } else {
                    regionTile(for: region, tint: tint)
                }
            }
            .background(isCurrent ? tint.opacity(0.16) : Color.primary.opacity(0.05), in: .rect(cornerRadius: 12))
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(tint.opacity(0.55), lineWidth: 1.5)
                }
            }
            .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel("\(region.name), \(region.counted) of \(region.total)")
        .accessibilityValue(region.isComplete ? "Complete" : "")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    /// A letter set large over its count and a slim bar of its levels.
    private func letterTile(for region: RegionSummary, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(region.name)
                .font(.title3.weight(.medium))
            Text("\(region.counted) / \(region.total)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            StatusTallyBar(tally: region.tally, total: region.total, minimumStatus: minimumStatus, showsStripes: false)
                .frame(height: 3)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            if region.isComplete {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption2)
                    .foregroundStyle(tint)
                    .padding(4)
                    .symbolEffect(.bounce, value: hasAppeared)
            }
        }
    }

    private func regionTile(for region: RegionSummary, tint: Color) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(region.name)
                        .placeName(region.language)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if region.isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.footnote)
                            .foregroundStyle(tint)
                            .symbolEffect(.bounce, value: hasAppeared)
                    }
                }
                Text("\(region.counted) / \(region.total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                StatusTallyBar(tally: region.tally, total: region.total, minimumStatus: minimumStatus, showsStripes: false)
                    .frame(height: 4)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
