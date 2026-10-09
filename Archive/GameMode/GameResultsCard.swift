import SwiftUI

/// The end of a round: stars popping in one after another, the score counting up to its total, a
/// new best called out, a pill for each way the answers went, the places missed to look at again
/// on the map, and a way to play again.
struct GameResultsCard: View {
    var game: MapGame
    var localLanguage: Bool
    /// The place from the round being looked at again on the map.
    var reviewID: String?
    var onReview: (AdministrativeDivision) -> Void
    var onPlayAgain: () -> Void
    var onChangeGame: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownStars = 0
    @State private var shownScore = 0.0
    @State private var bursts = 0
    @State private var shines = 0

    var body: some View {
        VStack(spacing: 16) {
            stars
            VStack(spacing: 0) {
                Text(headline)
                    .font(.title2.weight(.bold))
                RollingNumber(value: shownScore)
                    .font(.system(size: 56, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(game.mode.color.gradient)
                    .overlay {
                        // A good round ends in confetti.
                        CelebrationBurst(trigger: bursts, colors: MapGame.confettiColors, pieceCount: 70)
                            .frame(width: 420, height: 420)
                    }
                    .accessibilityLabel("\(game.score) points")
                best
            }
            tally
            if !game.missedPlaces.isEmpty {
                missed
            }
            buttons
        }
        .padding(18)
        .fontDesign(.rounded)
        .sensoryFeedback(.impact(weight: .medium), trigger: shownStars)
        .task { await celebrate() }
    }

    private var headline: String {
        switch game.stars {
        case 3: "Perfect!"
        case 2: "Brilliant!"
        case 1: "Nice work!"
        default: "Keep exploring!"
        }
    }

    /// Three stars, the middle one raised, each popping in as it's earned.
    private var stars: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                let isEarned = index < shownStars
                Image(systemName: isEarned ? "star.fill" : "star")
                    .font(.system(size: index == 1 ? 46 : 38, weight: .bold))
                    .foregroundStyle(isEarned ? AnyShapeStyle(LevelColor.yellow.color.gradient) : AnyShapeStyle(.quaternary))
                    .shadow(color: LevelColor.orange.color.opacity(isEarned ? 0.5 : 0), radius: 6, y: 2)
                    .scaleEffect(isEarned ? 1 : 0.85)
                    .rotationEffect(.degrees(isEarned ? 0 : -14))
                    .offset(y: index == 1 ? -8 : 0)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("^[\(game.stars) star](inflect: true) of 3"))
    }

    /// A new best gets a glossy badge with a shine across it; otherwise, the best to beat.
    @ViewBuilder
    private var best: some View {
        if game.isNewBest {
            Label("New Best", systemImage: "trophy.fill")
                .textCase(.uppercase)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(CandyGloss.lettering(on: LevelColor.pink.color))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background { CandyGloss(color: LevelColor.pink.color, pattern: .candyStripes) }
                .overlay(alignment: .leading) { ShineSweep(width: 150, trigger: shines) }
                .clipShape(Capsule())
                .pop(on: shines)
                .padding(.top, 4)
        } else if let previousBest = game.previousBest {
            Label("Best \(previousBest.formatted())", systemImage: "trophy.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    /// A pill for each way the answers went, coloured and textured as they are on the board.
    private var tally: some View {
        let counts = Dictionary(grouping: game.outcomes.values) { MapGame.level(for: $0).id }.mapValues(\.count)
        let shown = [MapGame.Outcome.right(tries: 1), .right(tries: 2), .right(tries: 3), .missed]
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
            HStack(spacing: 16) {
                Label {
                    Text("Best run \(game.bestStreak)")
                } icon: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(LevelColor.orange.color.gradient)
                }
                if let elapsed = game.elapsed {
                    Label(Duration.seconds(elapsed).formatted(.time(pattern: .minuteSecond)), systemImage: "stopwatch")
                        .accessibilityLabel(Duration.seconds(elapsed).formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
                }
            }
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
    }

    /// The places missed this round. Tap one to see it on the map.
    private var missed: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HAVE ANOTHER LOOK")
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(game.missedPlaces) { place in
                        let name = place.displayName(localLanguage: localLanguage)
                        let isReviewed = reviewID == place.id
                        Button {
                            onReview(place)
                        } label: {
                            HStack(spacing: 6) {
                                Image(place.flagAssetName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 16)
                                    .clipShape(.rect(cornerRadius: 3))
                                Text(name)
                                    .placeName(place.language(of: name))
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                isReviewed ? AnyShapeStyle(LevelColor.red.color.opacity(0.22)) : AnyShapeStyle(.primary.opacity(0.06)),
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
                Label("Games", systemImage: "square.grid.2x2.fill")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CandyButtonStyle(color: .secondary, isLit: false))
            Button(action: onPlayAgain) {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CandyButtonStyle(color: LevelColor.green.color, pattern: .candyStripes))
            .keyboardShortcut(.defaultAction)
        }
        .font(.headline)
    }

    /// Stars pop in one at a time, then the score counts up, and a good round ends in confetti.
    private func celebrate() async {
        guard !reduceMotion else {
            shownStars = game.stars
            shownScore = Double(game.score)
            return
        }
        try? await Task.sleep(for: .seconds(0.35))
        for star in 0..<game.stars {
            withAnimation(.bouncy(duration: 0.45, extraBounce: 0.25)) { shownStars = star + 1 }
            try? await Task.sleep(for: .seconds(0.3))
        }
        withAnimation(.easeOut(duration: 1.1)) { shownScore = Double(game.score) }
        try? await Task.sleep(for: .seconds(0.9))
        if game.stars >= 2 || game.isNewBest { bursts += 1 }
        if game.isNewBest { shines += 1 }
    }
}
