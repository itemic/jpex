import SwiftUI

/// The card for the place in question. Its head shows how far through the round you are, your run
/// of right answers and your score. Name It deals four candy names to choose from; Find It sets the
/// place's name large beside its flag, with a heart for each try left. Hints sit at its foot, and
/// once you've answered, the way on.
struct GameQuestionCard: View {
    var game: MapGame
    var localLanguage: Bool
    var onChoose: (AdministrativeDivision) -> Void
    var onHint: () -> Void
    var onReveal: () -> Void
    var onNext: () -> Void
    @ScaledMetric(relativeTo: .title) private var nameSize = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GameScoreboard(game: game)
            if let question = game.current {
                switch game.mode {
                case .nameIt: nameIt(question)
                case .findIt: findIt(question)
                }
                actions
            }
        }
        .padding(18)
        .fontDesign(.rounded)
        .animation(.bouncy(duration: 0.4), value: game.phase)
    }

    private func nameIt(_ question: MapGame.Question) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let outcome = game.outcomes[question.place.id] {
                    verdict(for: outcome, of: question)
                } else {
                    Text("Which \(game.collection.placeNoun) is this?")
                }
            }
            .font(.title3.weight(.bold))
            .transition(.push(from: .bottom).combined(with: .opacity))
            ChoiceGrid(game: game, question: question, localLanguage: localLanguage, onChoose: onChoose)
                .id(question.id)
        }
    }

    private func findIt(_ question: MapGame.Question) -> some View {
        let place = question.place
        let name = place.displayName(localLanguage: localLanguage)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        if let outcome = game.outcomes[place.id] {
                            verdict(for: outcome, of: question)
                                .font(.subheadline.weight(.heavy))
                        } else {
                            Text("FIND")
                                .font(.caption.weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .transition(.push(from: .bottom).combined(with: .opacity))
                    .padding(.bottom, 2)
                    Text(name)
                        .placeName(place.language(of: name), kerning: -0.6)
                        .font(.system(size: nameSize, weight: PlaceTypesetting.weight(.light, for: place.language(of: name))))
                        .fontDesign(.default)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle = place.subtitle(localLanguage: localLanguage) {
                        Text(subtitle)
                            .placeName(place.language(of: subtitle))
                            .font(.callout)
                            .fontDesign(.default)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                Image(place.flagAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 40)
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(.primary.opacity(0.12), lineWidth: 0.5) }
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .accessibilityHidden(true)
            }
            HStack(spacing: 12) {
                TriesLeft(count: game.triesLeft)
                if game.isHinted, game.scopeID == nil,
                   let group = game.collection.groups.first(where: { $0.id == place.groupID }) {
                    Label("Somewhere in \(group.displayName(localLanguage: localLanguage))", systemImage: "lightbulb.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .transition(.scale(scale: 0.8, anchor: .leading).combined(with: .opacity))
                }
            }
        }
        .id(question.id)
        .transition(.push(from: .trailing))
    }

    /// How the answer went, in the colour it shows on the board.
    private func verdict(for outcome: MapGame.Outcome, of question: MapGame.Question) -> some View {
        let text: String = switch outcome {
        case .right(tries: 1): Self.cheers[game.index % Self.cheers.count]
        case .right: "Found it!"
        case .missed where game.mode == .nameIt: "It’s \(question.place.displayName(localLanguage: localLanguage))"
        case .missed: "Here it is"
        }
        return Label(text, systemImage: outcome == .missed ? "xmark.circle.fill" : "checkmark.circle.fill")
            .foregroundStyle(MapGame.level(for: outcome).color)
    }

    private static let cheers = ["Nailed it!", "Spot on!", "You got it!", "Brilliant!", "Yes!", "Perfect!"]

    /// Hints while the question waits, then the way on.
    private var actions: some View {
        HStack(spacing: 10) {
            if game.phase == .asking {
                Button(action: onHint) {
                    Label(game.mode == .nameIt ? "50:50" : "Hint", systemImage: "lightbulb.fill")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                }
                .buttonStyle(CandyButtonStyle(color: LevelColor.yellow.color, isLit: false))
                .disabled(!game.canHint)
                .accessibilityLabel(game.mode == .nameIt ? "Fifty-fifty" : "Hint")
                .accessibilityHint(
                    game.mode == .nameIt
                        ? "Takes away two wrong names, for half the points."
                        : "Shows the neighbourhood, for half the points.")
                if game.mode == .findIt {
                    Button(action: onReveal) {
                        Label("Show Me", systemImage: "eye.fill")
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(CandyButtonStyle(color: .secondary, isLit: false))
                    .accessibilityHint("Gives up on this one and shows where it is.")
                }
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                Button(action: onNext) {
                    HStack(spacing: 6) {
                        Text(game.isLastQuestion ? "Results" : "Next")
                        Image(systemName: game.isLastQuestion ? "flag.pattern.checkered" : "arrow.right")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .buttonStyle(CandyButtonStyle(color: game.mode.color, pattern: .candyStripes))
                .keyboardShortcut(.defaultAction)
                .transition(.scale(scale: 0.6, anchor: .trailing).combined(with: .opacity))
            }
        }
        .font(.subheadline.weight(.bold))
    }
}

/// How far through the round, the run of right answers, and the score, with each answer's points
/// floating up from it.
private struct GameScoreboard: View {
    var game: MapGame

    var body: some View {
        let total = game.questions.count
        let number = min(game.index + 1, total)
        HStack(spacing: 10) {
            ProgressBarView(percentage: Double(game.outcomes.count) / Double(max(total, 1)), color: game.mode.color)
                .frame(height: 10)
            Text("\(number) / \(total)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(number)))
            if game.streak >= 2 {
                Label("\(game.streak)", systemImage: "flame.fill")
                    .font(.subheadline.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(LevelColor.orange.color.gradient)
                    .contentTransition(.numericText(value: Double(game.streak)))
                    .symbolEffect(.bounce, value: game.streak)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(game.score, format: .number)
                .font(.headline.weight(.heavy))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(game.score)))
                .overlay(alignment: .top) {
                    if let award = game.award {
                        AwardFloat(points: award.points)
                            .id(award.id)
                    }
                }
        }
        .animation(.bouncy, value: game.streak)
        .animation(.snappy, value: game.score)
        .animation(.snappy, value: number)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Place \(number) of \(total)")
        .accessibilityValue(game.streak >= 2 ? "\(game.score) points, \(game.streak) in a row" : "\(game.score) points")
    }
}

/// "+120", popping up from the score and floating away.
private struct AwardFloat: View {
    var points: Int
    @State private var isShown = false

    var body: some View {
        Text("+\(points)")
            .font(.subheadline.weight(.heavy))
            .monospacedDigit()
            .foregroundStyle(LevelColor.green.color)
            .fixedSize()
            .keyframeAnimator(initialValue: AwardFrame(), trigger: isShown) { content, frame in
                content
                    .scaleEffect(frame.scale)
                    .offset(y: frame.rise)
                    .opacity(frame.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.rise) {
                    CubicKeyframe(-34, duration: 1)
                }
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.2, duration: 0.2, spring: .snappy)
                    SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0.1)
                    LinearKeyframe(1, duration: 0.5)
                    LinearKeyframe(0, duration: 0.4)
                }
            }
            .onAppear { isShown = true }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct AwardFrame {
    var rise = 0.0
    var scale = 0.5
    var opacity = 0.0
}

/// Name It's names to choose from, dealt in one after another with a bounce. Once you've chosen,
/// the right name lights up green, a wrong choice turns red and shakes, and the rest step back.
private struct ChoiceGrid: View {
    var game: MapGame
    var question: MapGame.Question
    var localLanguage: Bool
    var onChoose: (AdministrativeDivision) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDealt = false

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 10), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(question.choices.enumerated()), id: \.element.id) { index, place in
                choice(place, number: index + 1)
                    .scaleEffect(isDealt || reduceMotion ? 1 : 0.4)
                    .opacity(isDealt ? 1 : 0)
                    .animation(.bouncy(duration: 0.5, extraBounce: 0.2).delay(Double(index) * 0.06), value: isDealt)
            }
        }
        .onAppear { isDealt = true }
    }

    private func choice(_ place: AdministrativeDivision, number: Int) -> some View {
        let state = state(of: place)
        let name = place.displayName(localLanguage: localLanguage)
        return Button {
            onChoose(place)
        } label: {
            HStack(spacing: 6) {
                if state == .right {
                    Image(systemName: "checkmark")
                        .fontWeight(.black)
                        .transition(.scale.combined(with: .opacity))
                } else if state == .wrong {
                    Image(systemName: "xmark")
                        .fontWeight(.black)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(name)
                    .placeName(place.language(of: name))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(CandyButtonStyle(
            color: color(for: state), pattern: pattern(for: state),
            shape: RoundedRectangle(cornerRadius: 18, style: .continuous), isLit: state != .passed))
        .disabled(state == .eliminated)
        .keyframeAnimator(initialValue: 0.0, trigger: state == .wrong) { content, offset in
            content.offset(x: reduceMotion ? 0 : offset)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-10, duration: 0.06)
                CubicKeyframe(9, duration: 0.08)
                CubicKeyframe(-6, duration: 0.08)
                CubicKeyframe(4, duration: 0.07)
                CubicKeyframe(0, duration: 0.07)
            }
        }
        .overlay {
            // Choosing right throws confetti from the name.
            CelebrationBurst(
                trigger: state == .right && game.chosen?.id == place.id ? 1 : 0, colors: MapGame.confettiColors,
                pieceCount: 30)
                .frame(width: 280, height: 280)
        }
        .animation(.snappy, value: state)
        .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: [])
        .accessibilityLabel(name)
        .accessibilityValue(accessibilityValue(for: state))
    }

    private func state(of place: AdministrativeDivision) -> ChoiceState {
        if game.eliminated.contains(place.id) { return .eliminated }
        guard game.phase == .answered else { return .open }
        if place.id == question.place.id { return .right }
        return place.id == game.chosen?.id ? .wrong : .passed
    }

    private func color(for state: ChoiceState) -> Color {
        switch state {
        case .right: MapGame.level(for: .right(tries: 1)).color
        case .wrong: MapGame.level(for: .missed).color
        case .open, .eliminated, .passed: game.mode.color
        }
    }

    /// The texture the answer wears on the board, or candy stripes while it waits.
    private func pattern(for state: ChoiceState) -> LevelPatternStyle? {
        switch state {
        case .right: LevelPatternStyle(rank: MapGame.ladder.rank(of: MapGame.level(for: .right(tries: 1))))
        case .wrong: LevelPatternStyle(rank: MapGame.ladder.rank(of: MapGame.level(for: .missed)))
        case .open, .eliminated, .passed: .candyStripes
        }
    }

    private func accessibilityValue(for state: ChoiceState) -> String {
        switch state {
        case .right: game.chosen?.id == question.place.id ? "Right" : "The right answer"
        case .wrong: "Wrong"
        case .eliminated: "Taken away"
        case .open, .passed: ""
        }
    }
}

private enum ChoiceState {
    /// Waiting to be chosen.
    case open
    /// Taken away by a hint.
    case eliminated
    /// The right answer, once the question is answered.
    case right
    /// Chosen, and wrong.
    case wrong
    /// Neither chosen nor right.
    case passed
}

/// A heart for each try left in Find It. A miss empties one with a shake.
private struct TriesLeft: View {
    var count: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<MapGame.tries, id: \.self) { index in
                let isFull = index < count
                Image(systemName: isFull ? "heart.fill" : "heart")
                    .foregroundStyle(isFull ? AnyShapeStyle(LevelColor.pink.color.gradient) : AnyShapeStyle(.tertiary))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .font(.subheadline.weight(.bold))
        .keyframeAnimator(initialValue: 0.0, trigger: count) { content, offset in
            content.offset(x: reduceMotion ? 0 : offset)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-6, duration: 0.06)
                CubicKeyframe(5, duration: 0.08)
                CubicKeyframe(-3, duration: 0.08)
                CubicKeyframe(0, duration: 0.07)
            }
        }
        .animation(.snappy, value: count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("^[\(count) try](inflect: true) left"))
    }
}
