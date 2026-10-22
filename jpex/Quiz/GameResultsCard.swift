import SwiftUI

/// The end of a round: how many you knew first time, counting up, a pill for each way the answers
/// went, how long it took, and the places worth another look: one tapped lights up on the map, and
/// beneath them, shows what was asked about it, such as its code or its capital. Then the ways on:
/// Back to the quizzes, Review to play only the places worth another look again, and Replay to
/// play the whole round again. Once the count has run up, the number pops with a soft tap and
/// throws confetti out across the whole screen, every round, however it went: it marks finishing,
/// never the score. Reduce Motion leaves all of it out.
struct GameResultsCard: View {
    var game: MapGame
    var localLanguage: Bool
    /// The place from the round being looked at again on the map.
    var reviewID: String?
    /// Looks at a place again on the map.
    var onLookAgain: (AdministrativeDivision) -> Void
    /// Plays the places worth another look again.
    var onReview: () -> Void
    /// Plays the whole round again.
    var onReplay: () -> Void
    var onBack: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownCount = 0.0
    /// Counts the times the count has finished running up, for the number's pop, tap and confetti.
    @State private var finishes = 0
    /// Where the number is on screen, for the confetti to fly from, clear of the glass around the card.
    @State private var numberFrame = ScreenFrame()
    /// Whether answers run on, out of sight, before and after the row of them.
    @State private var answersHidden = (before: false, after: false)

    /// The card's padding, which the row of answers reaches back out through to its edges.
    private static let inset: CGFloat = 16
    private static let confettiColors: [Color] = [LevelColor.lightBlue, .pink, .green, .yellow, .orange].map(\.color)

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
                .trackingScreenFrame(numberFrame)
                .pop(on: finishes)
                // List All has no first or second time: a place is named, or it isn’t.
                Text(game.mode == .listAll ? "named" : "right first time")
                    .font(.subheadline.weight(.regular))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(game.rightCount) of \(game.questions.count) \(game.mode == .listAll ? "named" : "right first time")")
            tally
            if !game.placesToReview.isEmpty {
                review
            }
            buttons
        }
        .padding(Self.inset)
        .fontDesign(.rounded)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: finishes)
        .task {
            guard !reduceMotion else {
                shownCount = Double(game.rightCount)
                return
            }
            // A moment for the card to land, then the count runs up, and the round's done.
            try? await Task.sleep(for: .seconds(0.25))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.9)) {
                shownCount = Double(game.rightCount)
            } completion: {
                finishes += 1
                // The confetti breaks out over the whole screen, as a finished region's does in the
                // list, rather than stopping at the glass's edge on its way up.
                if let origin = numberFrame.center {
                    ToastCenter.shared.burst(from: origin, colors: Self.confettiColors, pieceCount: 48, power: 1)
                }
            }
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
            Text("Answers")
                .typeStyle(.eyebrow)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(game.placesToReview) { place in
                        let name = place.displayName(localLanguage: localLanguage)
                        let isReviewed = reviewID == place.id
                        Button {
                            onLookAgain(place)
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
            // The row runs out to the card's edges, starting in line with the card's other
            // contents, and answers that run on past either end fade away there rather than being
            // cut through at the card's padding.
            .contentMargins(.horizontal, Self.inset, for: .scrollContent)
            .onScrollGeometryChange(for: [Bool].self) { geometry in
                let after = geometry.contentSize.width - geometry.contentOffset.x - geometry.containerSize.width
                return [geometry.contentOffset.x + geometry.contentInsets.leading > 1, after > 1]
            } action: { _, edges in
                answersHidden = (edges[0], edges[1])
            }
            .mask {
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [.black.opacity(answersHidden.before ? 0 : 1), .black], startPoint: .leading, endPoint: .trailing)
                        .frame(width: Self.inset + 8)
                    Color.black
                    LinearGradient(
                        colors: [.black, .black.opacity(answersHidden.after ? 0 : 1)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: Self.inset + 8)
                }
            }
            .padding(.horizontal, -Self.inset)
            if let reviewID, let place = game.place(id: reviewID) {
                // One place gives way to the next in one slot, so the card never holds both at once.
                ZStack(alignment: .topLeading) {
                    ReviewedAnswer(game: game, place: place, localLanguage: localLanguage)
                        .id(place.id)
                        .transition(.slotSwap(reduceMotion: reduceMotion))
                }
                .transition(.slotSwap(reduceMotion: reduceMotion))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.swap(reduceMotion: reduceMotion), value: reviewID)
    }

    /// Back to the quizzes, Review for the places worth another look, where there are any, and
    /// Replay for the whole round.
    private var buttons: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Label("Back", systemImage: "chevron.backward")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .foregroundStyle(.primary)
                    .background(.fill.tertiary, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(PillButtonStyle())
            .accessibilityHint("Back to every quiz.")
            if !game.placesToReview.isEmpty {
                Button(action: onReview) {
                    Label("Review", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(CandyButtonStyle(color: game.mode.color, pattern: .dots))
                .accessibilityHint("Replays the \(game.placesToReview.count) you missed.")
            }
            Button(action: onReplay) {
                Label("Replay", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(CandyButtonStyle(color: game.mode.color, pattern: .candyStripes))
            .keyboardShortcut(.defaultAction)
            .accessibilityHint("Plays the whole round again.")
        }
        .font(.headline.weight(.medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

/// A place looked at again from the results, with what the round asked about it beside its name:
/// its code as it's met in the world, its capitals, its flag, its shape, whether it's in the
/// group, or the country it's in. Where the round asked only where it is, the map says it all, and
/// it's just the name.
private struct ReviewedAnswer: View {
    var game: MapGame
    var place: AdministrativeDivision
    var localLanguage: Bool

    var body: some View {
        let name = place.displayName(localLanguage: localLanguage)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                ScrollingText {
                    Text(name)
                        .typeStyle(.compactPlaceName, language: place.language(of: name))
                        .fontDesign(.default)
                }
                if let note {
                    ScrollingText {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
            answer
        }
        .padding(12)
        .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// A line beneath the name: its capitals, whether it's in the group, or its country.
    private var note: String? {
        switch game.mode {
        case .capitals, .whoseCapital:
            let capitals = (game.capitals[place.id] ?? []).map(\.name)
            guard !capitals.isEmpty else { return nil }
            return capitals.count == 1 ? "Capital: \(capitals[0])" : "Capitals: \(capitals.formatted(.list(type: .and)))"
        case .member:
            let group = game.groupNameInSentence ?? game.collection.name
            return game.isMember(place) ? "In \(group)" : "Not in \(group)"
        case .everything:
            return game.countryName(of: place).map { "In \($0)" }
        default:
            return nil
        }
    }

    /// The picture of what was asked about it, at the end of the row.
    @ViewBuilder
    private var answer: some View {
        switch game.mode {
        case .code, .pickCode:
            if let code = game.code(of: place) {
                CodeBadge(code: code, kind: game.shownCodeKind, size: 22)
                    .fixedSize()
            }
        case .flags, .pickFlag:
            Image(place.flagAssetName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 60, maxHeight: 40)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                .accessibilityHidden(true)
        case .outline, .pickOutline:
            if let path = game.outline(of: place) {
                ZStack {
                    OutlineShape(unit: path)
                        .fill(LinearGradient(colors: [game.mode.color.opacity(0.7), game.mode.color], startPoint: .top, endPoint: .bottom))
                    OutlineShape(unit: path)
                        .stroke(.white, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            }
        default:
            Image(place.flagAssetName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 40, maxHeight: 28)
                .accessibilityHidden(true)
        }
    }
}
