import SwiftUI

/// The end of a round: how many you knew first time, counting up, a pill for each way the answers
/// went, how long it took, the places worth another look, and a way to go again.
struct GameResultsCard: View {
    var game: MapGame
    var localLanguage: Bool
    /// The place from the round being looked at again on the map.
    var reviewID: String?
    var onReview: (AdministrativeDivision) -> Void
    var onPlayAgain: () -> Void
    var onChangeGame: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownCount = 0.0

    var body: some View {
        VStack(spacing: 14) {
            if game.isTimeUp {
                Label("Time’s up", systemImage: "timer")
                    .typeStyle(.eyebrow)
                    .foregroundStyle(LevelColor.orange.color)
            }
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    RollingNumber(value: shownCount)
                        .typeStyle(.heroCount)
                        .fontDesign(.default)
                        .foregroundStyle(game.mode.color.gradient)
                    Text("/ \(game.questions.count)")
                        .typeStyle(.heroTotal)
                        .fontDesign(.default)
                        .foregroundStyle(.secondary)
                }
                Text("right first time")
                    .font(.subheadline.weight(.regular))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(game.rightCount) of \(game.questions.count) right first time")
            tally
            if !game.placesToReview.isEmpty {
                review
            }
            buttons
        }
        .padding(16)
        .fontDesign(.rounded)
        .task {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.9)) { shownCount = Double(game.rightCount) }
        }
    }

    /// A pill for each way the answers went, coloured and textured as they are on the board, and the time.
    private var tally: some View {
        let counts = Dictionary(grouping: game.outcomes.values) { MapGame.level(for: $0).id }.mapValues(\.count)
        let shown = [MapGame.Outcome.right(tries: 1), .right(tries: 2), .shown]
            .map(MapGame.level(for:))
            .filter { counts[$0.id, default: 0] > 0 }
        return VStack(spacing: 10) {
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(shown) { level in
                    VisitPillLabel(status: level, suffix: " \(counts[level.id, default: 0])")
                        .accessibilityLabel("\(counts[level.id, default: 0]) \(level.name)")
                }
            }
            .environment(\.visitLadder, MapGame.ladder)
            if let elapsed = game.elapsed {
                Label(Duration.seconds(elapsed).formatted(.time(pattern: .minuteSecond)), systemImage: "stopwatch")
                    .font(.subheadline.weight(.regular))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Duration.seconds(elapsed).formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
            }
        }
    }

    /// The places that took more than one try, or were shown. Tap one to see it on the map.
    private var review: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Have another look")
                .typeStyle(.eyebrow)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(game.placesToReview) { place in
                        let name = place.displayName(localLanguage: localLanguage)
                        let isReviewed = reviewID == place.id
                        Button {
                            onReview(place)
                        } label: {
                            HStack(spacing: 6) {
                                Image(place.flagAssetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 18)
                                ScrollingText {
                                    Text(name)
                                        .placeName(place.language(of: name))
                                        .font(.subheadline.weight(PlaceTypesetting.weight(.light, for: place.language(of: name))))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                isReviewed ? AnyShapeStyle(game.mode.color.opacity(0.25)) : AnyShapeStyle(.primary.opacity(0.06)),
                                in: Capsule())
                            .contentShape(Capsule())
                        }
                        .buttonStyle(PillButtonStyle())
                        .accessibilityLabel(name)
                        .accessibilityHint("Shows it on the map.")
                        .accessibilityAddTraits(isReviewed ? .isSelected : [])
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button(action: onChangeGame) {
                Label("Quizzes", systemImage: "square.grid.2x2.fill")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CandyButtonStyle(color: .secondary, isLit: false))
            Button(action: onPlayAgain) {
                Label("Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CandyButtonStyle(color: game.mode.color, pattern: .candyStripes))
            .keyboardShortcut(.defaultAction)
        }
        .font(.headline.weight(.medium))
    }
}
