import SwiftUI

/// The card for the place in question. A striped bar across the top shows how far through the
/// round you are. How it's answered follows the options. Typed, a field takes the place's name or
/// its capital, answering by itself once it's spelt out in full and forgiving a small slip, with
/// the right spelling shown after. From a list of four, candy names or capitals are dealt to pick
/// from, with Reveal and then the way on at the foot. From a list of all, every place in play, or
/// every capital, is a grid of cards, like a Sporcle quiz: type to narrow them down. Either way a
/// wrong answer turns red or shakes, and you try again. Find gives a name to find: tap a place on
/// the map, then confirm it, so a slip of the finger doesn't count. Member? names a country and
/// asks whether it's in the group, with two candy buttons, In and Out. Once answered, how it went
/// shows with the way on beside it. A thin bar across the top counts through the round, with any
/// round's clock beside it; Reveal is a small eye beside the answer, and under a time limit for
/// each question, a ring around it drains as the time runs out.
struct GameQuestionCard: View {
    var game: MapGame
    var localLanguage: Bool
    /// Whether the card has room of its own, as on the near side of iPhone Duo's fold or under the
    /// flag in Flag, so the cards can fill it.
    var isRoomy: Bool
    /// In Find, the place tapped on the map, waiting to be confirmed.
    var selection: AdministrativeDivision?
    var onAnswer: (AdministrativeDivision) -> Void
    /// Answers with what's been typed: a place's name, or in Capital, its capital.
    var onTyped: (String) -> Void
    /// In Capital, picks a city in the place that isn't its capital.
    var onDecoy: (String) -> Void
    var onReveal: () -> Void
    var onNext: () -> Void
    /// Leaves the question for later, to come back at the end of the round.
    var onSkip: () -> Void = {}
    /// In Member?, answers in, or out.
    var onMembership: (Bool) -> Void = { _ in }
    /// Room beneath the card for the home indicator, where the card runs to the foot of the screen,
    /// so a list can scroll beneath it and still come to rest clear of it.
    var bottomInset: CGFloat = 0
    /// Room beneath a list's last row where the card floats in the glass panel, so the last name or
    /// picture comes to rest as far off the glass's foot as the cards keep from its sides, rather
    /// than all but touching it.
    var listFoot: CGFloat = 0
    @State private var query = ""
    @FocusState private var isSearching: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether the keyboard was up when the last question was answered, so it stays up for the next.
    @State private var keepsKeyboard = false
    /// Counts the typed answers that missed, or tried a name again, for the field to shake and
    /// flash its red edge at each one.
    @State private var fieldShakes = 0
    /// The width Skip and Reveal take beside the question, kept while they're away.
    @State private var revealRoom: CGFloat = 88

    /// The question's misses and retries, with the place they're for.
    private struct FieldShakes: Equatable {
        var placeID: String?
        var count: Int
    }

    private static let confettiColors: [Color] = [LevelColor.lightBlue, .pink, .green, .yellow, .orange].map(\.color)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let place = game.current {
                if game.answerMethod == .four || picture != nil && game.answerMethod != .typing {
                    // Pictures and four to pick from have no field or hint line, so Reveal sits
                    // beside the question.
                    // Reveal's room is kept once it has gone, as the question's answered, so the
                    // question never rewraps, its words sliding over one another, as it leaves.
                    HStack(alignment: .top, spacing: 8) {
                        prompt(for: place)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Color.clear
                            .frame(width: revealRoom, height: 0)
                    }
                    .overlay(alignment: .topTrailing) {
                        revealButton
                            .padding(.top, -6)
                            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                                if width > 0 { revealRoom = width }
                            }
                    }
                } else {
                    prompt(for: place)
                }
                switch game.answerMethod {
                case .four:
                    // Each question's four are dealt afresh, the last question's fading away in the
                    // same slot rather than standing above them while they go.
                    ZStack(alignment: .top) {
                        if let picture {
                            PictureChoiceGrid(game: game, picture: picture, onAnswer: onAnswer)
                                .id(place.id)
                        } else {
                            ChoiceGrid(game: game, localLanguage: localLanguage, onAnswer: onAnswer, onDecoy: onDecoy)
                                .id(place.id)
                        }
                    }
                    choiceFoot(for: place)
                case .list where picture != nil:
                    // Every flag, shape or code in play to pick from, with nothing to type: names
                    // would give it away.
                    pictureChoices(for: place, picture: picture ?? .flag)
                case .list:
                    answerSlot(for: place)
                    CardChoices(
                        game: game, query: query, localLanguage: localLanguage, bottomInset: bottomInset + listFoot, onAnswer: onAnswer)
                        .frame(maxHeight: isRoomy ? .infinity : 168)
                case .inOrOut:
                    ZStack(alignment: .top) {
                        MembershipChoices(game: game, onAnswer: onMembership)
                            .id(place.id)
                    }
                    membershipFoot(for: place)
                case .typing, .map:
                    answerSlot(for: place)
                    if game.answerMethod == .typing, game.phase == .asking, let note = game.typedNote {
                        Label(note, systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                    if game.autoFill, game.offersAutoFill(for: game.mode), game.phase == .asking {
                        SuggestionRow(game: game, query: query, localLanguage: localLanguage, onAnswer: onAnswer)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        // A list of names or pictures runs on to the card's foot, under the home indicator where
        // the card reaches the screen's; pictures' verdict keeps its own room above it.
        .padding(.bottom, game.answerMethod == .list ? 0 : 16 + bottomInset)
        .frame(maxHeight: isRoomy ? .infinity : nil, alignment: .top)
        .fontDesign(.rounded)
        // What's inside moves on the same curve as whatever moved it, so it keeps in step with the
        // glass around it: an answer settling on its spring, the next question trading places on
        // the swap; with Reduce Motion, short fades.
        .animation(
            game.phase == .answered ? Motion.moving(.snappy, reduceMotion: reduceMotion) : .swap(reduceMotion: reduceMotion),
            value: game.phase)
        .onChange(of: game.phase) {
            if game.phase == .answered { keepsKeyboard = isSearching }
        }
        .onChange(of: game.current?.id) { query = "" }
        .task(id: game.current?.id) {
            // The field comes back with the next question; the keyboard comes back with it.
            guard keepsKeyboard, game.answerMethod != .four else { return }
            try? await Task.sleep(for: .milliseconds(120))
            isSearching = true
        }
        .onChange(of: game.misses) {
            if game.answerMethod == .typing, game.misses > 0 { query = "" }
        }
        // Only a miss or a retry on this question shakes the field: not its count falling back to
        // nothing as the next comes up, nor a skipped one coming back with its misses.
        .onChange(of: FieldShakes(placeID: game.current?.id, count: game.shakes)) { old, new in
            if new.placeID == old.placeID, new.count > old.count { fieldShakes += 1 }
        }
    }

    /// What the answers show, where they're pictures: flags, shapes or codes, identifying a place's.
    private var picture: ChoicePicture? {
        switch game.mode {
        case .pickFlag: .flag
        case .pickOutline: .outline
        case .pickCode: .code
        default: nil
        }
    }

    /// How far through the round: a thin bar across the card, the count quietly at its end, and
    /// under a time limit for the round, the time left beside it.
    private var header: some View {
        let total = game.questions.count
        let number = min(game.index + 1, total)
        return HStack(spacing: 10) {
            ProgressBarView(percentage: Double(game.outcomes.count) / Double(max(total, 1)), color: game.mode.color)
                .frame(height: 5)
                .accessibilityHidden(true)
            HStack(spacing: 0) {
                Text("\(number)")
                    .typeStyle(.count)
                    .contentTransition(.numericText(value: Double(number)))
                Text(" / \(total)")
                    .typeStyle(.countTotal)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Place \(number) of \(total)")
            if let deadline = game.deadline {
                Countdown(deadline: deadline)
                    .fixedSize()
            }
        }
        .frame(minHeight: 20)
    }

    /// Reveal, beside the answer while the question waits: an eye in a soft circle, with a ring
    /// around it draining under a time limit for each question.
    @ViewBuilder
    private var revealButton: some View {
        // Each pops in as the question comes up and fades as it's answered; with Reduce Motion, they
        // only fade.
        if game.phase == .asking {
            HStack(spacing: 2) {
                if game.canSkip {
                    SkipButton(action: onSkip)
                        .transition(.arrive(reduceMotion: reduceMotion))
                }
                RevealButton(
                    deadline: game.questionDeadline, total: TimeInterval(game.questionSeconds ?? 0), action: onReveal)
            }
            .transition(.arrive(reduceMotion: reduceMotion))
        }
    }

    @ViewBuilder
    private func prompt(for place: AdministrativeDivision) -> some View {
        switch game.mode {
        case .nameIt, .dot, .everything:
            Text("Where is this?")
                .font(.title2.weight(.light))
        case .flags:
            Text("Whose flag is this?")
                .font(.title2.weight(.light))
        case .outline:
            Text("Which \(game.collection.placeNoun) is this?")
                .font(.title2.weight(.light))
        case .code:
            codePrompt(for: place)
        case .whoseCapital:
            capitalPrompt(for: place)
        case .listAll:
            // List All asks about every place at once, on a card of its own.
            EmptyView()
        case .findIt, .capitals, .member, .pickFlag, .pickOutline, .pickCode:
            let name = place.displayName(localLanguage: localLanguage)
            // One slot for the place going and the place coming, so the card never holds both at once.
            ZStack(alignment: .topLeading) {
                namedPrompt(for: place, name: name)
                    .id(place.id)
                    .transition(.slotSwap(reduceMotion: reduceMotion))
            }
        }
    }

    /// The place named large, with what's asked about it above, its formal name beneath where it
    /// has one, and its flag beside it where that doesn't give the answer away.
    private func namedPrompt(for place: AdministrativeDivision, name: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                // Each on one line, a long one, as Saint Vincent and the Grenadines, gliding to show
                // the rest, never wrapping or shrunk.
                ScrollingText {
                    Text(eyebrow)
                        .typeStyle(.eyebrow)
                        .foregroundStyle(.secondary)
                }
                // Member?'s eyebrow only names the group; VoiceOver hears the question itself,
                // which names the country, so the name beneath isn't read again.
                .accessibilityLabel(game.mode == .member ? "Is \(name) in \(groupInSentence)?" : eyebrow)
                ScrollingText {
                    Text(name)
                        .typeStyle(.placeName, language: place.language(of: name))
                        .fontDesign(.default)
                }
                .accessibilityHidden(game.mode == .member)
                if let subtitle = place.subtitle(localLanguage: localLanguage) {
                    // A long formal name glides to its end now and then rather than being cut short.
                    ScrollingText {
                        Text(subtitle)
                            .typeStyle(.compactPlaceSubtitle, language: place.language(of: subtitle))
                            .fontDesign(.default)
                            .foregroundStyle(.secondary)
                    }
                }
                if let note = capitalsNote(for: place) {
                    Label(note, systemImage: "building.columns.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(game.mode.color)
                        .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
            // Identifying its flag, the flag would give it away.
            if game.mode != .pickFlag {
                Image(place.flagAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 54, maxHeight: 36)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Whose capital?'s question: the capital, large, and where it's one of several, its part in
    /// governing, such as Pretoria's executive. Each capital gives way to the next in one slot.
    private func capitalPrompt(for place: AdministrativeDivision) -> some View {
        let capital = game.capitals[place.id]?.first
        return ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ScrollingText {
                    Text("Capital of which \(game.collection.placeNoun)?")
                        .typeStyle(.eyebrow)
                        .foregroundStyle(.secondary)
                }
                ScrollingText {
                    Text(capital?.name ?? "")
                        .typeStyle(.placeName)
                        .fontDesign(.default)
                }
                if let role = capital?.role {
                    ScrollingText {
                        Text(role.prefix(1).uppercased() + role.dropFirst())
                            .typeStyle(.compactPlaceSubtitle)
                            .fontDesign(.default)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .id(place.id)
            .transition(.slotSwap(reduceMotion: reduceMotion))
            .accessibilityElement(children: .combine)
        }
    }

    /// What's asked about the place named: to find it, its flag, its capital, or whether it's in
    /// the group, such as "G20 membership".
    private var eyebrow: String {
        switch game.mode {
        case .findIt: "Find"
        case .pickFlag: "Flag of"
        case .pickOutline: "Outline of"
        case .pickCode: game.shownCodeKind.placeQuestion
        case .member: "\(game.countryGroup?.name ?? game.collection.name) membership"
        default: "What’s the capital of"
        }
    }

    /// The group as it sits in a sentence, such as "the G20" or "NATO".
    private var groupInSentence: String {
        game.groupNameInSentence ?? game.collection.name
    }

    /// Member?: how it went, with the way on, in the room the hint took while the question waited,
    /// so the card keeps its height. The two share one slot, cross-fading as they trade places.
    private func membershipFoot(for place: AdministrativeDivision) -> some View {
        ZStack(alignment: .leading) {
            if let outcome = game.outcomes[place.id] {
                verdictRow(for: place, outcome: outcome)
                    .transition(.opacity)
            } else {
                // Only Reveal while it waits; the question above says what to do.
                revealButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
            }
        }
        .frame(minHeight: 44)
        .transition(.opacity)
    }

    /// Code's question: what kind of code it is, the code itself large in a candy tag, and where
    /// several places share it, how many.
    private func codePrompt(for place: AdministrativeDivision) -> some View {
        let kind = game.shownCodeKind
        let sharing = game.answerPlaces.count
        let code = game.code(of: place) ?? ""
        // Each code gives way to the next in one slot, so the card never holds both at once.
        return ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Text(kind.question(isSeveral: code.contains(PlaceCodes.separator)))
                    .typeStyle(.eyebrow)
                    .foregroundStyle(.secondary)
                HStack(alignment: .center, spacing: 12) {
                    CodeBadge(code: code, kind: kind)
                    if sharing > 1, game.answerMethod != .typing {
                        Text(game.answerMethod == .list ? sharing == 2 ? "Choose either of the 2 places" : "Choose any of the \(sharing) places" : "\(sharing) places use this code")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .id(place.id)
            .transition(.slotSwap(reduceMotion: reduceMotion))
            .accessibilityElement(children: .combine)
        }
    }

    /// In Capital, where a place has several capitals and any of them is offered, such as
    /// "Choose any of the 3 capitals". Four dealt only ever offer one of them.
    private func capitalsNote(for place: AdministrativeDivision) -> String? {
        let count = game.capitals[place.id]?.count ?? 0
        guard game.mode == .capitals, count > 1, game.answerMethod != .four, game.outcomes[place.id] == nil else { return nil }
        let verb = game.answerMethod == .typing ? "Type" : "Choose"
        return count == 2 ? "\(verb) either of the 2 capitals" : "\(verb) any of the \(count) capitals"
    }

    /// While the question waits, the field to type in or to narrow the list, or in Find, Confirm;
    /// then the answer, with the way on. Typed answers keep their field, hidden under the answer and
    /// still taking the keyboard, so Return goes on to the next question. Whatever's there shares
    /// one slot with what comes next, so the two cross-fade rather than stand one above the other.
    @ViewBuilder
    private func answerSlot(for place: AdministrativeDivision) -> some View {
        let outcome = game.outcomes[place.id]
        ZStack(alignment: .leading) {
            if game.answerMethod == .typing {
                ZStack {
                    HStack(spacing: 8) {
                        typedField
                        revealButton
                    }
                    .opacity(outcome == nil ? 1 : 0)
                    .allowsHitTesting(outcome == nil)
                    .accessibilityHidden(outcome != nil)
                    if let outcome {
                        verdictRow(for: place, outcome: outcome)
                            .transition(.opacity)
                    }
                }
            } else if let outcome {
                verdictRow(for: place, outcome: outcome)
            } else {
                switch game.answerMethod {
                case .list:
                    HStack(spacing: 8) {
                        searchField
                        revealButton
                    }
                case .map:
                    HStack(spacing: 8) {
                        Button {
                            if let selection { onAnswer(selection) }
                        } label: {
                            ScrollingText {
                                Label(selection == nil ? "Tap a place on the map" : "Confirm", systemImage: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                        }
                        .buttonStyle(CandyButtonStyle(color: game.mode.color, pattern: .candyStripes, isLit: selection != nil))
                        .disabled(selection == nil)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityHint("Answers with the place chosen on the map.")
                        revealButton
                    }
                case .typing, .four, .inOrOut:
                    EmptyView()
                }
            }
        }
        .frame(minHeight: 44)
        .transition(.opacity)
    }

    /// The room a grid of pictures and its verdict share where the card keeps to its own height, as
    /// it floats over the foot of the map: what the grid, the gap and the foot beneath it always had
    /// between them, so the map's share of the screen is just as it was.
    private static let pictureRoom: CGFloat = 272

    /// Every flag, shape or code in play to pick from. While the question waits, the grid runs right
    /// down to the card's foot, with no band of empty glass held beneath it, and fades away softly
    /// wherever it carries on out of sight. Once it's answered, the grid gives up its foot to how it
    /// went and the way on, the two sharing one height, so the card never changes height.
    private func pictureChoices(for place: AdministrativeDivision, picture: ChoicePicture) -> some View {
        let outcome = game.outcomes[place.id]
        return VStack(spacing: 12) {
            PictureCardChoices(
                game: game, picture: picture, bottomInset: outcome == nil ? bottomInset + listFoot : 0, onAnswer: onAnswer)
                .frame(maxHeight: .infinity)
            if let outcome {
                verdictRow(for: place, outcome: outcome)
                    .frame(minHeight: 44)
                    .padding(.bottom, 16 + bottomInset)
                    .transition(.opacity)
            }
        }
        .frame(maxHeight: isRoomy ? .infinity : Self.pictureRoom)
    }

    /// Four to pick from: once answered, how it went, with the way on, in room kept for it while
    /// the question waits, so the card never changes height.
    private func choiceFoot(for place: AdministrativeDivision) -> some View {
        ZStack {
            // A fixed height, not all there is: left to fill the room it's offered, the clear
            // stand-in stretched the card up over the whole map.
            Color.clear
                .frame(height: 44)
            if let outcome = game.outcomes[place.id] {
                verdictRow(for: place, outcome: outcome)
                    .transition(.opacity)
            }
        }
        .frame(minHeight: 44)
        .accessibilityHidden(game.outcomes[place.id] == nil)
    }

    /// How the answer went, in the colour it went on the board, with the way on beside it. A typed
    /// answer let through with a typo shows how it's spelt.
    private func verdictRow(for place: AdministrativeDivision, outcome: MapGame.Outcome) -> some View {
        let name = place.displayName(localLanguage: localLanguage)
        // Capitals are named in English; a place's own name in its own script's way.
        let language = game.mode == .capitals ? nil : place.language(of: name)
        return HStack(spacing: 10) {
            Label {
                // Each line stays one line, gliding to its end where it's too long, as names do
                // elsewhere, rather than wrapping onto a second.
                VStack(alignment: .leading, spacing: 1) {
                    ScrollingText {
                        verdictText(for: outcome, name: name)
                            .typeStyle(.compactPlaceName, language: language)
                            .fontDesign(.default)
                    }
                    // The tick says it's right on screen; VoiceOver says so in words.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        isPlainlyRight(outcome) ? Text("Correct, \(verdict(for: outcome, name: name))")
                            : isSilentlyShown(outcome) ? Text("Shown, \(name)") : verdictText(for: outcome, name: name))
                    if let correction = game.correction {
                        // Taken as right; the spelling, as it is, simply shown.
                        ScrollingText {
                            Text("Spelt “\(correction)”")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if game.mode == .capitals, let roles = capitalRoles(of: place) {
                        // Where a place shares its capital's role, what each one does, in the same order.
                        ScrollingText {
                            Text(roles)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } icon: {
                Image(systemName: verdictSymbol(for: place, outcome: outcome))
                    .font(.title3)
                    .foregroundStyle(MapGame.level(for: outcome).color)
                    .accessibilityHidden(true)
                    .overlay {
                        // Right first time throws confetti from the tick, as four to pick from throw it
                        // from the name picked; Reduce Motion leaves it out.
                        if game.answerMethod != .four {
                            CelebrationBurst(
                                trigger: outcome == .right(tries: 1) ? 1 : 0, colors: Self.confettiColors, pieceCount: 24,
                                burstsOnAppear: true)
                                .frame(width: 220, height: 220)
                        }
                    }
            }
            Spacer(minLength: 0)
            NextButton(isLast: game.isLastQuestion, color: game.mode.color, action: onNext)
        }
    }

    private func verdictSymbol(for place: AdministrativeDivision, outcome: MapGame.Outcome) -> String {
        if game.ranOutOfTime(place) { return "timer" }
        if game.mode == .member, outcome == .shown, game.memberGuess != nil { return "xmark.circle.fill" }
        return outcome == .shown ? "eye.circle.fill" : "checkmark.circle.fill"
    }

    /// How the answer went: right, the answer alone beside its tick; a shown answer's own words;
    /// or when time ran out, "Time’s up, it’s Spain". Member? says how the answer went, then
    /// whether the country's in, such as "Correct, Spain isn’t in the G20".
    private func verdictText(for outcome: MapGame.Outcome, name: String) -> Text {
        let answer = verdict(for: outcome, name: name)
        let timedOut = game.current.map(game.ranOutOfTime) ?? false
        // Find names the place on the card already, so its verdict doesn't say it again; an answer
        // shown is simply its eye, the map lighting it up, with nothing to read beside it.
        if game.mode == .findIt {
            return Text(timedOut ? "Time’s up" : outcome == .shown ? "" : "Correct")
        }
        if timedOut {
            let shown = game.mode == .member ? answer : "it’s \(verdict(for: .right(tries: 1), name: name))"
            return Text("Time’s up, ") + Text(shown).foregroundStyle(.secondary)
        }
        if game.mode == .member, outcome == .shown, game.memberGuess != nil {
            return Text("No, ") + Text(answer).foregroundStyle(.secondary)
        }
        if game.mode == .member, case .right = outcome {
            return Text("Correct, ") + Text(answer).foregroundStyle(.secondary)
        }
        return Text(answer)
    }

    /// Whether the answer was shown in Find, where the verdict is its eye alone; VoiceOver still
    /// says it was shown.
    private func isSilentlyShown(_ outcome: MapGame.Outcome) -> Bool {
        game.mode == .findIt && outcome == .shown && !(game.current.map(game.ranOutOfTime) ?? false)
    }

    /// Whether the verdict is a right answer named beside its tick, with no word to say it's right.
    private func isPlainlyRight(_ outcome: MapGame.Outcome) -> Bool {
        guard case .right = outcome, game.mode != .findIt, game.mode != .member else { return false }
        return !(game.current.map(game.ranOutOfTime) ?? false)
    }

    /// How the answer went: the name, in Capital every one of the place's capitals, in Code every
    /// place that shares the code, and in Member? whether the country's in the group, such as
    /// "Spain isn’t in the G20".
    private func verdict(for outcome: MapGame.Outcome, name: String) -> String {
        // Identifying a place's code, the code, as several codes are listed.
        if game.mode == .pickCode, let place = game.current, let code = game.code(of: place) {
            let codes = code.components(separatedBy: PlaceCodes.separator).joined(separator: ", ")
            return outcome == .shown ? "It’s \(codes)" : codes
        }
        if game.mode == .member, let place = game.current {
            return game.isMember(place) ? "\(name) is in \(groupInSentence)" : "\(name) isn’t in \(groupInSentence)"
        }
        if game.mode == .capitals, let place = game.current {
            return (game.capitals[place.id] ?? []).map(\.name).joined(separator: ", ")
        }
        let sharing = game.answerPlaces.map { $0.displayName(localLanguage: localLanguage) }
        if game.mode == .code, sharing.count > 1 {
            return sharing.count <= 3
                ? sharing.joined(separator: ", ")
                : sharing.prefix(2).joined(separator: ", ") + " and \(sharing.count - 2) more"
        }
        return switch outcome {
        case .right: name
        case .shown: "It’s \(name)"
        }
    }

    /// Where the answer is typed: a place's name, or in Capital, its capital. Spelt out in full it
    /// answers by itself; Return checks it, letting a small slip through. A wrong one shakes and
    /// clears for another go.
    private var typedField: some View {
        let isCapital = game.mode == .capitals
        let isCode = game.mode == .pickCode
        let prompt = isCapital ? "Type the capital"
            : isCode ? "Type the code"
            : game.mode == .whoseCapital ? "Type the \(game.collection.placeNoun)" : "Type its name"
        return HStack(spacing: 6) {
            Image(systemName: isCapital ? "building.columns" : isCode ? "barcode" : "character.cursor.ibeam")
                .foregroundStyle(.secondary)
            TextField(prompt, text: $query)
                .focused($isSearching)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(game.phase == .answered ? .next : .done)
                .onSubmit {
                    // Once it's answered, Return goes on to the next question.
                    if game.phase == .answered {
                        onNext()
                    } else {
                        onTyped(query)
                    }
                    isSearching = true
                }
                .onChange(of: query) {
                    if game.phase == .asking, game.isExactAnswer(query) { onTyped(query) }
                }
                // A slip taken as right: the field shows the name spelt as it is.
                .onChange(of: game.correction) { _, correction in
                    if let correction { query = correction }
                }
            Button("Check", systemImage: "return") {
                onTyped(query)
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(query.isEmpty ? AnyShapeStyle(.tertiary) : AnyShapeStyle(game.mode.color))
            .buttonStyle(.plain)
            .disabled(query.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.primary.opacity(0.07), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(LevelColor.red.color, lineWidth: 1.5)
                .keyframeAnimator(initialValue: 0.0, trigger: fieldShakes) { content, opacity in
                    content.opacity(opacity)
                } keyframes: { _ in
                    CubicKeyframe(1, duration: 0.1)
                    CubicKeyframe(0, duration: 0.8)
                }
        }
        // With Reduce Motion, the red edge and a nod say so.
        .shake(on: fieldShakes, amplitude: 8)
    }

    /// The parts several capitals play, such as "executive, legislative, judicial", or nil when there's one.
    private func capitalRoles(of place: AdministrativeDivision) -> String? {
        let capitals = game.capitals[place.id] ?? []
        guard capitals.count > 1 else { return nil }
        return capitals.map { $0.role ?? "capital" }.joined(separator: ", ")
    }

    /// Narrows the list of cards as you type.
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(game.mode == .capitals ? "Type a capital" : "Type a name", text: $query)
                .focused($isSearching)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit(submit)
                .onChange(of: query) { answerIfRight() }
            if !query.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") { query = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.tertiary)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.primary.opacity(0.07), in: Capsule())
    }

    /// Typing the right name in full answers as soon as it's complete, as in a Sporcle quiz.
    private func answerIfRight() {
        guard let place = game.current, game.phase == .asking else { return }
        let typed = CardChoices.folded(query)
        let entries = CardChoices.entries(in: game, localLanguage: localLanguage)
        guard entries.contains(where: { $0.places.contains(place) && $0.searchNames.contains(typed) }) else { return }
        onAnswer(place)
    }

    /// Return answers with the only card left, or one typed out in full.
    private func submit() {
        let entries = CardChoices.matches(in: CardChoices.entries(in: game, localLanguage: localLanguage), for: query)
        let typed = CardChoices.folded(query)
        if let entry = entries.first(where: { $0.searchNames.contains(typed) }) ?? (entries.count == 1 ? entries.first : nil) {
            onAnswer(entry.answer(in: game))
        }
        isSearching = true
    }
}

/// Auto-fill's names beneath the field, as you type: the ten nearest what's typed, best first, as
/// cards like a list's, in one line that scrolls sideways out to the card's edges. Each carries
/// its flag where that doesn't give the answer away, and in Everything, its country's, which tells
/// apart places sharing a name, such as the two Limburgs. A tap answers with it, as picking it
/// from a list would. The line comes in with the first letter typed and goes once there's nothing
/// close to it.
private struct SuggestionRow: View {
    var game: MapGame
    var query: String
    var localLanguage: Bool
    var onAnswer: (AdministrativeDivision) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let suggestions = game.suggestions(for: query)
        VStack(spacing: 0) {
            if !suggestions.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(suggestions) { suggestion in
                            let state = ChoiceState(of: suggestion.place, in: game)
                            ChoiceCard(entry: entry(for: suggestion), state: state) {
                                onAnswer(suggestion.place)
                            }
                            .frame(minWidth: 110, maxWidth: 220)
                            .allowsHitTesting(state == .open)
                        }
                    }
                    // Room for a lit card's glow and shake, which the scroll view would cut off.
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .padding(.horizontal, -16)
                .padding(.vertical, -8)
                // It slides down into place; with Reduce Motion, it only fades.
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.smooth(duration: 0.25), value: suggestions.isEmpty)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Suggestions")
    }

    /// A suggestion as a list's card shows it.
    private func entry(for suggestion: MapGame.Suggestion) -> ChoiceEntry {
        let place = suggestion.place
        let flag = game.mode == .everything
            ? game.countryFlagAssetName(of: place)
            : [.nameIt, .outline, .dot, .whoseCapital].contains(game.mode) ? place.flagAssetName : nil
        return ChoiceEntry(
            id: suggestion.id, name: suggestion.name, language: place.language(of: suggestion.name), flagAssetName: flag,
            places: [place], searchNames: [])
    }
}

/// The time left in a round against the clock, beside the count, such as 2:41, warming to orange
/// and then red over its last ten seconds.
struct Countdown: View {
    var deadline: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(deadline.timeIntervalSince(context.date), 0).rounded(.up)
            let isEnding = remaining <= 10
            Label {
                Text(Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond)))
                    .typeStyle(.count)
                    // Digits change in place, crisp, rather than rolling past one another every second.
                    .contentTransition(.identity)
            } icon: {
                Image(systemName: "timer")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isEnding ? (remaining <= 5 ? LevelColor.red.color : LevelColor.orange.color) : .secondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time left")
            .accessibilityValue(Duration.seconds(remaining).formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
        }
    }
}

/// Skip: an arrow on in a soft circle, beside Reveal, a full 44 points to tap. The question goes to
/// the end of the round, to come back to with whatever time it had left.
private struct SkipButton: View {
    var action: () -> Void
    @ScaledMetric(relativeTo: .body) private var side = 36

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.primary.opacity(0.07))
                Image(systemName: "forward.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: side, height: side)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel("Skip")
        .accessibilityHint("Leaves it for later. It comes back at the end, with the time it had left.")
    }
}

/// Reveal: an eye in a soft circle, a full 44 points to tap. Under a time limit for each question,
/// a ring around it drains as the time runs out, warming to orange over the last three seconds.
private struct RevealButton: View {
    /// When this question's time runs out, under a time limit for each question.
    var deadline: Date?
    var total: TimeInterval
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var side = 36

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.primary.opacity(0.07))
                Image(systemName: "eye")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                if let deadline, total > 0 {
                    TimelineView(.periodic(from: .now, by: reduceMotion ? 1 : 1 / 30)) { context in
                        let remaining = max(deadline.timeIntervalSince(context.date), 0)
                        let isEnding = remaining <= 3
                        Circle()
                            .trim(from: 0, to: remaining / total)
                            .stroke(
                                isEnding ? AnyShapeStyle(LevelColor.orange.color) : AnyShapeStyle(.secondary),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(1.25)
                    }
                }
            }
            .frame(width: side, height: side)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel("Reveal")
        .accessibilityHint("Shows the answer.")
        .accessibilityValue(timeLeft)
    }

    /// The time left, for VoiceOver, where there's a limit.
    private var timeLeft: String {
        guard let deadline else { return "" }
        // Held full while the camera flies there, never more than the limit itself.
        let seconds = Int(min(max(deadline.timeIntervalSinceNow, 0), total).rounded(.up))
        return seconds == 1 ? "1 second left" : "\(seconds) seconds left"
    }
}

/// Member?'s two answers, In and Out, as big candy buttons side by side, bouncing in. Once
/// answered, the one picked lights up in the colour it went, with its mark, and the other steps
/// back; where time ran out, the answer lights up as shown.
private struct MembershipChoices: View {
    var game: MapGame
    var onAnswer: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDealt = false
    @ScaledMetric(relativeTo: .title3) private var height = 64

    var body: some View {
        HStack(spacing: 10) {
            button(isIn: true, index: 0)
            button(isIn: false, index: 1)
        }
        .onAppear { isDealt = true }
    }

    private func button(isIn: Bool, index: Int) -> some View {
        let outcome = game.current.flatMap { game.outcomes[$0.id] }
        let isPicked = game.memberGuess == isIn
        let isAnswer = game.current.map { game.isMember($0) == isIn } ?? false
        // Lit while waiting; once answered, the pick, or where nothing was picked, the answer.
        let isLit = outcome == nil || isPicked || (game.memberGuess == nil && isAnswer)
        let color = outcome.map { MapGame.level(for: $0).color } ?? game.mode.color
        let mark: String? = outcome == nil ? nil : isPicked ? (isAnswer ? "checkmark" : "xmark") : (isLit ? "eye" : nil)
        return Button {
            onAnswer(isIn)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: mark ?? (isIn ? "checkmark.circle" : "xmark.circle"))
                    .fontWeight(.semibold)
                    .contentTransition(.symbolEffect(.replace))
                Text(isIn ? "In" : "Out")
            }
            .font(.title3.weight(.medium))
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(CandyButtonStyle(
            color: color, pattern: .candyStripes, shape: RoundedRectangle(cornerRadius: 18, style: .continuous), isLit: isLit))
        .allowsHitTesting(game.phase == .asking)
        .scaleEffect(isDealt || reduceMotion ? 1 : 0.4)
        .opacity(isDealt ? (isLit ? 1 : 0.6) : 0)
        .animation(.bouncy(duration: 0.5, extraBounce: 0.2).delay(Double(index) * 0.06), value: isDealt)
        // Picked wrongly, it shakes, once; with Reduce Motion, it nods.
        .shake(onRiseOf: isPicked && !isAnswer ? 1 : 0, amplitude: 10)
        .animation(ChoiceState.lighting(reduceMotion: reduceMotion), value: outcome)
        .keyboardShortcut(KeyEquivalent(isIn ? "1" : "2"), modifiers: [])
        .accessibilityLabel(isIn ? "In" : "Out")
        .accessibilityHint(isIn ? "It’s a member." : "It isn’t a member.")
        .accessibilityValue(outcome == nil ? "" : isPicked ? (isAnswer ? "Correct" : "Wrong") : isLit ? "The answer" : "")
    }
}

/// Next, or Results after the last question: candy, in the mode's colour, bouncing in as it
/// appears; Return presses it from a hardware keyboard.
private struct NextButton: View {
    var isLast: Bool
    var color: Color
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(isLast ? "Results" : "Next")
                Image(systemName: isLast ? "flag.pattern.checkered" : "arrow.right")
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .buttonStyle(CandyButtonStyle(color: color, pattern: .candyStripes))
        .keyboardShortcut(.defaultAction)
        .scaleEffect(isShown || reduceMotion ? 1 : 0.6)
        .opacity(isShown ? 1 : 0)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .bouncy(duration: 0.45, extraBounce: 0.25)) { isShown = true }
        }
    }
}

/// A code dressed as it's met in the world: an ISO code in a thin printed oval, like the language
/// marks in instruction manuals; a domain in a browser's address bar; a calling code or an area
/// code as dialled, beside a phone's green call button; a car's sign on the white oval sticker with
/// its heavy black rim; an Olympic code lit up on a scoreboard; a Chinese place's short name in
/// white on its plates' blue, and a Polish or Czech plate's letter after the EU's blue band; an
/// aircraft's prefix painted on a white tail fin, the rest of the registration left blank; an
/// airport's prefix on a departures board; a currency's code in the corner of a banknote; and a
/// postcode's first digit written into the boxes on an envelope. Crisp in light and dark, and read
/// out by VoiceOver letter by letter. `size` is the scale it's drawn at: large in a question,
/// smaller in Learn, where it stands in for a flag a place doesn't have.
struct CodeBadge: View {
    var code: String
    var kind: MapGame.CodeKind
    var size: CGFloat = 34
    /// Whether it's pared down to the code itself where there's more around it, as a domain's
    /// address is, for a small badge that needs to read at a glance.
    var isCompact = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let size = size * dynamicTypeSize.scale
        Group {
            switch kind {
            case .iso:
                Text(code)
                    .font(.system(size: size * 0.9, weight: .medium))
                    .tracking(size * 0.06)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, size * 0.62)
                    .padding(.vertical, size * 0.2)
                    .overlay { Ellipse().strokeBorder(.primary, lineWidth: max(size * 0.035, 1)) }
            case .domain:
                HStack(spacing: size * 0.22) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.36))
                        .foregroundStyle(.secondary)
                    (Text(isCompact ? "" : "www.example").foregroundStyle(Color(uiColor: .tertiaryLabel))
                        + Text(code).foregroundStyle(Color(uiColor: .label)))
                        .font(.system(size: size * 0.7, weight: .regular, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, size * 0.4)
                .padding(.vertical, size * 0.26)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: size * 0.4, style: .continuous))
            case .phone:
                HStack(spacing: size * 0.36) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(.white)
                        .frame(width: size * 1.2, height: size * 1.2)
                        .background(LevelColor.green.color.gradient, in: Circle())
                    Text(code)
                        .font(.system(size: size * 1.05, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            case .car:
                Text(code)
                    .font(.system(size: size * 0.95, weight: .heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, size * 0.7)
                    .padding(.vertical, size * 0.24)
                    .background(Ellipse().fill(.white))
                    .overlay { Ellipse().strokeBorder(.black, lineWidth: max(size * 0.1, 2)) }
                    .shadow(color: .black.opacity(0.18), radius: size * 0.08, y: size * 0.04)
            case .olympic:
                HStack(spacing: size * 0.24) {
                    Image(systemName: "medal.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(LevelColor.yellow.color.gradient)
                    Text(code)
                        .font(.system(size: size * 0.82, weight: .bold, design: .monospaced))
                        .tracking(size * 0.08)
                        .foregroundStyle(LevelColor.yellow.color)
                }
                .padding(.horizontal, size * 0.36)
                .padding(.vertical, size * 0.2)
                .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                }
            case .plate:
                // A Polish or Czech plate's letter: black on white, after the blue band of the EU.
                HStack(spacing: size * 0.22) {
                    Color(red: 0, green: 0.2, blue: 0.6)
                        .frame(width: size * 0.42)
                        .overlay(alignment: .top) {
                            Image(systemName: "star.circle")
                                .font(.system(size: size * 0.3))
                                .foregroundStyle(Color(red: 1, green: 0.8, blue: 0))
                                .padding(.top, size * 0.1)
                        }
                    Text(code)
                        .font(.system(size: size * 0.95, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.trailing, size * 0.36)
                }
                .padding(.vertical, size * 0.06)
                .fixedSize()
                .background(.white, in: RoundedRectangle(cornerRadius: size * 0.12, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: size * 0.12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                        .strokeBorder(.black, lineWidth: max(size * 0.05, 1))
                }
                .shadow(color: .black.opacity(0.15), radius: size * 0.08, y: size * 0.04)
            case .number:
                // The number a place goes by, as on a form: a small "No." and the number.
                HStack(alignment: .firstTextBaseline, spacing: size * 0.12) {
                    Text("No.")
                        .font(.system(size: size * 0.42, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(code)
                        .font(.system(size: size * 1.05, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, size * 0.4)
                .padding(.vertical, size * 0.12)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .strokeBorder(.primary.opacity(0.5), lineWidth: max(size * 0.03, 1))
                }
            case .shortName:
                // A Chinese place's short name as its number plates carry it: white on their blue.
                Text(code)
                    .font(.system(size: size * 0.95, weight: .semibold))
                    .typesettingLanguage(Locale.Language(identifier: "zh-Hans"))
                    .foregroundStyle(.white)
                    .padding(.horizontal, size * 0.32)
                    .padding(.vertical, size * 0.14)
                    .background(Color(red: 0.05, green: 0.25, blue: 0.7), in: RoundedRectangle(cornerRadius: size * 0.14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
                            .strokeBorder(.white, lineWidth: max(size * 0.04, 1))
                            .padding(size * 0.07)
                    }
            case .aircraft:
                // N runs straight on into its numbers; every other mark is followed by a dash. A
                // place with several marks shows them all, as a list, with nothing after.
                let isSeveral = code.contains(PlaceCodes.separator)
                let joiner = code.contains("-") || code == "N" ? "" : "-"
                (Text(code).foregroundStyle(Color.black)
                    + Text(isSeveral ? "" : joiner + "···").foregroundStyle(Color.black.opacity(0.25)))
                    .font(.system(size: size * 0.9, weight: .bold))
                    .tracking(size * 0.04)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.leading, size * 0.8)
                    .padding(.trailing, size * 0.45)
                    .padding(.vertical, size * 0.24)
                    .background(TailFin(sweep: size * 0.55).fill(.white))
                    .overlay { TailFin(sweep: size * 0.55).stroke(.black.opacity(0.18), lineWidth: 1) }
                    .shadow(color: .black.opacity(0.18), radius: size * 0.1, y: size * 0.05)
            case .airport:
                DeparturesBoard(prefixes: code.components(separatedBy: PlaceCodes.separator), size: size)
            case .currency:
                BanknoteCorner(code: code, size: size)
            case .postcode:
                PostcodeBoxes(digits: code, size: size)
            case .timeZone:
                WorldClockTag(zone: code, size: size)
            case .fifa:
                // The UK's four teams on one line where there's room, otherwise two to a line.
                let teams = code.components(separatedBy: PlaceCodes.separator)
                ViewThatFits(in: .horizontal) {
                    PitchTag(teams: teams, size: size)
                    PitchTag(teams: teams, size: size, perLine: 2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spoken(code))
    }

    /// Read out letter by letter, so DE isn't read as a word; several codes, one after another.
    static func spoken(_ code: String) -> String {
        code.components(separatedBy: PlaceCodes.separator).map { single in
            single.map { $0 == "." ? "dot" : $0 == "+" ? "plus" : $0 == "-" ? "dash" : $0 == "−" ? "minus" : $0 == "±" ? "plus or minus" : String($0) }
                .joined(separator: " ")
        }
        .joined(separator: ", ")
    }
}

/// An aircraft's tail fin seen from the side: its leading edge swept back, its top cut square and
/// its trailing edge nearly upright.
private struct TailFin: Shape {
    /// How far the leading edge sweeps back across the top.
    var sweep: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + sweep, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - sweep * 0.15, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// An airport's prefix on a departures board: dark split-flap tiles in any light, after a small
/// plane taking off in the board's amber. One prefix lights its letters and leaves the rest of the
/// four-letter code as dim dots, "RJ··" for Japan; several stand alone, up to four to a line, as a
/// board lists its flights, the tiles a little smaller where there are more than three.
private struct DeparturesBoard: View {
    var prefixes: [String]
    var size: CGFloat

    /// The warm white of a flap's letters.
    private static let lettering = Color(red: 1, green: 0.97, blue: 0.9)
    /// The amber of the board's sign.
    private static let amber = Color(red: 1, green: 0.75, blue: 0.2)

    var body: some View {
        let lines = Self.lines(of: prefixes)
        let tile = size * (prefixes.count <= 3 ? 1 : lines.count <= 2 ? 0.8 : 0.68)
        HStack(spacing: size * 0.24) {
            Image(systemName: "airplane.departure")
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(Self.amber)
            // Several prefixes stand well apart, so each reads as a code of its own.
            VStack(alignment: .leading, spacing: tile * 0.3) {
                ForEach(lines.indices, id: \.self) { line in
                    HStack(spacing: tile * 0.6) {
                        ForEach(lines[line], id: \.self) { prefix in
                            let letters = Self.letters(of: prefix, filledOut: prefixes.count == 1)
                            HStack(spacing: tile * 0.06) {
                                ForEach(letters.indices, id: \.self) { index in
                                    flap(letters[index], size: tile)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, size * 0.3)
        .padding(.vertical, size * 0.2)
        .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
        .fixedSize()
    }

    /// One split-flap tile, its top half a shade lighter than its bottom, the split between them
    /// running through its letter too; with no letter, a dim dot.
    private func flap(_ letter: Character?, size: CGFloat) -> some View {
        let corner = size * 0.1
        let split = max(size * 0.035, 1)
        return ZStack {
            VStack(spacing: split) {
                UnevenRoundedRectangle(topLeadingRadius: corner, topTrailingRadius: corner, style: .continuous)
                    .fill(Color(white: 0.25))
                UnevenRoundedRectangle(bottomLeadingRadius: corner, bottomTrailingRadius: corner, style: .continuous)
                    .fill(Color(white: 0.2))
            }
            if let letter {
                Text(String(letter))
                    .font(.system(size: size * 0.66, weight: .bold).width(.condensed))
                    .foregroundStyle(Self.lettering)
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .frame(height: split)
            } else {
                Text("·")
                    .font(.system(size: size * 0.66, weight: .bold))
                    .foregroundStyle(Self.lettering.opacity(0.3))
            }
        }
        .frame(width: size * 0.62, height: size * 0.9)
    }

    /// The prefixes a few to a line: one line for up to four, otherwise as evenly as they'll go.
    private static func lines(of prefixes: [String]) -> [[String]] {
        let count = max((prefixes.count + 3) / 4, 1)
        var lines: [[String]] = []
        var rest = prefixes[...]
        for line in 0..<count {
            let take = (rest.count + count - line - 1) / (count - line)
            lines.append(Array(rest.prefix(take)))
            rest = rest.dropFirst(take)
        }
        return lines
    }

    /// A prefix's letters, and where it stands alone, nils for the dots filling it out to an
    /// airport code's four.
    private static func letters(of prefix: String, filledOut: Bool) -> [Character?] {
        let letters: [Character?] = prefix.map { $0 }
        return filledOut ? letters + Array(repeating: nil, count: max(4 - letters.count, 0)) : letters
    }
}

/// A currency's code as it's printed in the corner of a banknote: engraved in a fine frame on pale
/// green paper, beside a rosette of rings like the one around a note's value, the same in any light.
private struct BanknoteCorner: View {
    var code: String
    var size: CGFloat

    /// The paper, a shade deeper towards one corner.
    private static let paper = [Color(red: 0.91, green: 0.95, blue: 0.88), Color(red: 0.8, green: 0.89, blue: 0.79)]
    private static let ink = Color(red: 0.09, green: 0.33, blue: 0.24)

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
        HStack(spacing: size * 0.22) {
            rosette
            Text(code)
                .font(.system(size: size * 0.8, weight: .semibold, design: .serif))
                .tracking(size * 0.06)
                .foregroundStyle(Self.ink)
        }
        .padding(.leading, size * 0.26)
        .padding(.trailing, size * 0.36)
        .padding(.vertical, size * 0.16)
        .background(LinearGradient(colors: Self.paper, startPoint: .topLeading, endPoint: .bottomTrailing), in: shape)
        .overlay {
            // The printed frame, a little inside the paper's edge.
            RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                .strokeBorder(Self.ink.opacity(0.45), lineWidth: max(size * 0.025, 0.75))
                .padding(size * 0.08)
        }
        .overlay { shape.strokeBorder(Self.ink.opacity(0.2), lineWidth: 0.5) }
        .fixedSize()
        .shadow(color: .black.opacity(0.15), radius: size * 0.08, y: size * 0.04)
    }

    /// Rings within rings, the middle one dashed, around a soft spot of ink.
    private var rosette: some View {
        ZStack {
            Circle()
                .strokeBorder(Self.ink.opacity(0.6), lineWidth: max(size * 0.03, 0.75))
            Circle()
                .strokeBorder(
                    Self.ink.opacity(0.4),
                    style: StrokeStyle(lineWidth: max(size * 0.025, 0.75), dash: [size * 0.05, size * 0.035]))
                .padding(size * 0.07)
            Circle()
                .fill(Self.ink.opacity(0.25))
                .padding(size * 0.16)
        }
        .frame(width: size * 0.62, height: size * 0.62)
    }
}

/// A time zone as a world clock shows it: a small clock face, its hands at ten past ten as clocks
/// are pictured, beside the zone's offset from UTC, such as UTC+9, on a night-blue
/// tile the same in any light.
private struct WorldClockTag: View {
    var zone: String
    var size: CGFloat

    private static let night = Color(red: 0.09, green: 0.12, blue: 0.24)

    var body: some View {
        HStack(spacing: size * 0.26) {
            ZStack {
                Circle()
                    .fill(.white)
                Circle()
                    .strokeBorder(Color(white: 0.75), lineWidth: max(size * 0.03, 0.75))
                ForEach(0..<12, id: \.self) { hour in
                    Capsule()
                        .fill(Color(white: 0.55))
                        .frame(width: max(size * 0.025, 0.5), height: size * (hour % 3 == 0 ? 0.1 : 0.06))
                        .offset(y: -size * 0.27)
                        .rotationEffect(.degrees(Double(hour) * 30))
                }
                Capsule()
                    .fill(Self.night)
                    .frame(width: max(size * 0.05, 1), height: size * 0.18)
                    .offset(y: -size * 0.09)
                    .rotationEffect(.degrees(-60))
                Capsule()
                    .fill(Self.night)
                    .frame(width: max(size * 0.04, 1), height: size * 0.26)
                    .offset(y: -size * 0.13)
                    .rotationEffect(.degrees(60))
                Circle()
                    .fill(LevelColor.orange.color)
                    .frame(width: size * 0.08, height: size * 0.08)
            }
            .frame(width: size * 0.72, height: size * 0.72)
            Text(zone)
                .font(.system(size: size * 0.72, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.leading, size * 0.24)
        .padding(.trailing, size * 0.38)
        .padding(.vertical, size * 0.2)
        .background(Self.night.gradient, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .fixedSize()
    }
}

/// A postcode's first digit written into the first of the four boxes printed for it on Australian
/// envelopes, in Australia Post's red, the other three left to fill, a dim dot in each.
private struct PostcodeBoxes: View {
    var digits: String
    var size: CGFloat

    /// Australia Post's red, lifted a little to read on dark.
    private static let red = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1)
            : UIColor(red: 0.86, green: 0.1, blue: 0.16, alpha: 1)
    })

    var body: some View {
        let written = Array(digits)
        HStack(spacing: size * 0.12) {
            ForEach(0..<4, id: \.self) { index in
                let digit = written.indices.contains(index) ? String(written[index]) : nil
                Text(digit ?? "·")
                    .font(.system(size: size * 0.82, weight: .regular, design: .rounded))
                    .foregroundStyle(digit == nil ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
                    .frame(width: size * 0.8, height: size * 1.1)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
                            .strokeBorder(Self.red.opacity(digit == nil ? 0.45 : 1), lineWidth: max(size * 0.05, 1.25))
                    }
            }
        }
        .fixedSize()
    }
}

/// A team's code on a patch of pitch: white on grass mown in stripes, inside a white touchline,
/// after a ball on the centre spot with the halfway line and centre circle around it. The United
/// Kingdom's four teams stand side by side, a little smaller, or two to a line where there isn't
/// room. The same in any light.
private struct PitchTag: View {
    var teams: [String]
    var size: CGFloat
    /// The most teams to a line.
    var perLine = Int.max

    /// The grass, and the lighter stripes it's mown in.
    private static let grass = Color(red: 0.11, green: 0.49, blue: 0.24)
    private static let mown = Color(red: 0.15, green: 0.56, blue: 0.28)

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
        let line = max(size * 0.03, 1)
        let touchline = size * 0.08
        let leading = size * 0.26
        let circle = size * 0.9
        HStack(spacing: size * 0.2) {
            Image(systemName: "soccerball")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: circle)
            VStack(alignment: .leading, spacing: size * 0.06) {
                ForEach(stride(from: 0, to: teams.count, by: max(perLine, 1)).map { $0 }, id: \.self) { first in
                    HStack(spacing: size * 0.24) {
                        ForEach(teams[first..<min(first + max(perLine, 1), teams.count)], id: \.self) { team in
                            Text(team)
                                .font(.system(size: size * (teams.count > 1 ? 0.6 : 0.78), weight: .heavy, design: .rounded))
                                .tracking(size * 0.05)
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        .padding(.leading, leading)
        .padding(.trailing, size * 0.4)
        .padding(.vertical, size * 0.22)
        .background {
            Canvas { context, area in
                context.fill(Path(CGRect(origin: .zero, size: area)), with: .color(Self.grass))
                let band = size * 0.42
                var x: CGFloat = band
                while x < area.width {
                    context.fill(Path(CGRect(x: x, y: 0, width: band, height: area.height)), with: .color(Self.mown))
                    x += band * 2
                }
                // The halfway line and the centre circle, around the ball on its spot.
                let centre = CGPoint(x: leading + circle / 2, y: area.height / 2)
                var markings = Path()
                markings.move(to: CGPoint(x: centre.x, y: touchline))
                markings.addLine(to: CGPoint(x: centre.x, y: area.height - touchline))
                markings.addEllipse(in: CGRect(x: centre.x - circle / 2, y: centre.y - circle / 2, width: circle, height: circle))
                context.stroke(markings, with: .color(.white.opacity(0.5)), lineWidth: line)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
                .strokeBorder(.white.opacity(0.75), lineWidth: line)
                .padding(touchline)
        }
        .clipShape(shape)
        .fixedSize()
        .shadow(color: .black.opacity(0.18), radius: size * 0.08, y: size * 0.04)
    }
}

private extension DynamicTypeSize {
    /// Roughly how much larger than the default text is set, for sizing drawn badges along with it.
    var scale: CGFloat {
        switch self {
        case .xSmall: 0.85
        case .small: 0.9
        case .medium: 0.95
        case .large: 1
        case .xLarge: 1.1
        case .xxLarge: 1.2
        case .xxxLarge: 1.3
        default: 1.45
        }
    }
}

/// Where a name to choose stands: waiting to be chosen, chosen wrongly, the answer once it's been
/// given, or passed over. Both ways of choosing wear it the same way, in the board's colours and
/// textures for how answers went, with a mark beside the name so it reads without colour too.
enum ChoiceState: Equatable {
    case open
    case wrong
    case answer(MapGame.Outcome)
    case passed

    @MainActor
    init(of place: AdministrativeDivision, in game: MapGame) {
        self.init(of: [place], in: game)
    }

    /// Where a card standing for several places stands, such as a capital two places share.
    @MainActor
    init(of places: [AdministrativeDivision], in game: MapGame) {
        if places.contains(where: game.wrongGuesses.contains) {
            self = .wrong
        } else if game.phase != .answered {
            self = .open
        } else if let current = game.current, places.contains(where: game.isAnswer), let outcome = game.outcomes[current.id] {
            self = .answer(outcome)
        } else {
            self = .passed
        }
    }

    /// Where a city offered as a tempting mistake stands: wrong once picked, and stepping back once
    /// the question's answered.
    @MainActor
    init(decoy city: String, in game: MapGame) {
        if game.wrongDecoys.contains(city) {
            self = .wrong
        } else {
            self = game.phase == .answered ? .passed : .open
        }
    }

    /// Whether it's lit up in candy: chosen wrongly, or the answer.
    var isLit: Bool {
        switch self {
        case .wrong, .answer: true
        case .open, .passed: false
        }
    }

    var isAnswer: Bool {
        if case .answer = self { true } else { false }
    }

    /// How a choice lights up as it's answered, in the colour it went or red when it's chosen
    /// wrongly: a lively spring, or with Reduce Motion, a short fade. Names, pictures, In and Out
    /// and a list's cards all light on it, so the moment feels the same however a round's answered.
    static func lighting(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .bouncy(duration: 0.4, extraBounce: 0.12)
    }

    /// Its colour: red when chosen wrongly, and the answer in the colour it went on the board.
    func color(open: Color) -> Color {
        switch self {
        case .open, .passed: open
        case .wrong: MapGame.level(for: .shown).color
        case .answer(let outcome): MapGame.level(for: outcome).color
        }
    }

    /// Its texture, as the board wears it for how the answer went.
    func pattern(open: LevelPatternStyle?) -> LevelPatternStyle? {
        switch self {
        case .open, .passed: open
        case .wrong: MapGame.ladder.patternStyle(of: MapGame.level(for: .shown))
        case .answer(let outcome): MapGame.ladder.patternStyle(of: MapGame.level(for: outcome))
        }
    }

    /// The mark beside the name: a cross when wrong, and the answer's own, such as a tick.
    var symbolName: String? {
        switch self {
        case .wrong: "xmark"
        case .answer(let outcome): MapGame.level(for: outcome).symbolName
        case .open, .passed: nil
        }
    }

    var accessibilityValue: String {
        switch self {
        case .wrong: "Wrong"
        case .answer(.shown): "The answer"
        case .answer: "Correct"
        case .open, .passed: ""
        }
    }
}

/// Four to pick from, dealt in one after another with a bounce, as the game first had them:
/// candy buttons two to a row, each row as tall as its tallest name, with number keys to pick
/// them. A wrong pick turns red and shakes, and you try again; the answer lights up in the colour
/// it went, throwing confetti when it's right first time, and the rest step back. In Capital
/// they're capitals, and each one out of play owns up to whose it is.
private struct ChoiceGrid: View {
    var game: MapGame
    var localLanguage: Bool
    var onAnswer: (AdministrativeDivision) -> Void
    var onDecoy: (String) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDealt = false
    /// Every button's height: room for a name and the line beneath saying whose it is, so every
    /// button stands the same.
    @ScaledMetric(relativeTo: .title3) private var height = 74

    private static let confettiColors: [Color] = [LevelColor.lightBlue, .pink, .green, .yellow, .orange].map(\.color)

    var body: some View {
        let dealt = game.dealt
        let columns = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(Array(stride(from: 0, to: dealt.count, by: columns)), id: \.self) { first in
                GridRow {
                    ForEach(first..<min(first + columns, dealt.count), id: \.self) { index in
                        choice(dealt[index], number: index + 1)
                            .scaleEffect(isDealt || reduceMotion ? 1 : 0.4)
                            .opacity(isDealt ? 1 : 0)
                            .animation(.bouncy(duration: 0.5, extraBounce: 0.2).delay(Double(index) * 0.06), value: isDealt)
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { isDealt = true }
    }

    private func choice(_ choice: MapGame.Choice, number: Int) -> some View {
        let place = choice.place
        let state = choice.decoy.map { ChoiceState(decoy: $0, in: game) } ?? ChoiceState(of: place, in: game)
        let isCapital = game.mode == .capitals
        let name = place.displayName(localLanguage: localLanguage)
        let label = choice.decoy ?? (isCapital ? game.capitalName(of: place) ?? name : name)
        // Once a capital is out of play, it says whose it is; a city that isn't one says where it is.
        // In Whose capital?, each place out of play shows its own capital; in Everything, each place
        // its country, to tell apart places sharing a name, such as the two Limburgs.
        let owner: String? = if isCapital, state != .open {
            choice.decoy == nil ? name : "City in \(name)"
        } else if game.mode == .whoseCapital, state != .open {
            game.capitalName(of: place)
        } else {
            game.countryName(of: place)
        }
        return Button {
            if let city = choice.decoy {
                onDecoy(city)
            } else {
                onAnswer(place)
            }
        } label: {
            VStack(spacing: 1) {
                HStack(spacing: 6) {
                    if let symbol = state.symbolName {
                        Image(systemName: symbol)
                            .fontWeight(.semibold)
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    }
                    // On one line, a long name gliding to show the rest, never wrapped or shrunk.
                    ScrollingText {
                        Text(label)
                            .placeName(isCapital ? nil : place.language(of: label))
                            .fontWeight(PlaceTypesetting.weight(.regular, for: isCapital ? nil : place.language(of: label)))
                            .strikethrough(state == .wrong)
                    }
                }
                .font(.title3)
                if let owner {
                    ScrollingText {
                        Text(owner)
                            .placeName(choice.decoy == nil ? place.language(of: owner) : nil)
                            .font(.caption.weight(.medium))
                    }
                    .opacity(0.9)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(CandyButtonStyle(
            color: state.color(open: game.mode.color), pattern: state.pattern(open: .candyStripes),
            shape: RoundedRectangle(cornerRadius: 18, style: .continuous), isLit: state != .passed))
        .allowsHitTesting(state == .open && game.phase == .asking)
        // Picked wrongly, it shakes, once; with Reduce Motion, it nods.
        .shake(onRiseOf: state == .wrong ? 1 : 0, amplitude: 10)
        .overlay {
            // Right first time throws confetti from the name.
            CelebrationBurst(trigger: state == .answer(.right(tries: 1)) ? 1 : 0, colors: Self.confettiColors, pieceCount: 30)
                .frame(width: 280, height: 280)
        }
        .animation(ChoiceState.lighting(reduceMotion: reduceMotion), value: state)
        .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: [])
        .accessibilityLabel(owner.map { "\(label), \($0)" } ?? label)
        .accessibilityValue(state.accessibilityValue)
    }
}

/// A card to pick in a list: a place's name, or in Capital a capital city's, with the places it
/// stands for. Two places sharing a capital's name share its card.
private struct ChoiceEntry: Identifiable {
    var id: String
    var name: String
    var language: Locale.Language?
    var flagAssetName: String?
    var places: [AdministrativeDivision]
    /// Every name it answers to, as typed, without case or accents.
    var searchNames: Set<String>

    /// The place picking it answers with: the one in question, if it stands for it.
    @MainActor
    func answer(in game: MapGame) -> AdministrativeDivision {
        places.first { $0.id == game.current?.id } ?? places[0]
    }
}

/// Every place still in play as a grid of cards to tap, like the boards in Countries settings, or
/// in Capital every one of their capitals, narrowed by what's been typed and fading out at an edge
/// only where it carries on. It keeps what matters in view by itself: back to the top for each new
/// question, to the first match as you type, to a wrong pick, and to the answer once it's given.
/// Flags go with the names where they don't give the answer away: not in Flag, nor in Capital,
/// where the flag beside the place asked about would match one.
private struct CardChoices: View {
    var game: MapGame
    var query: String
    var localLanguage: Bool
    /// Room beneath the last card for the home indicator, where the list runs to the foot of the screen.
    var bottomInset: CGFloat = 0
    var onAnswer: (AdministrativeDivision) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The narrowest a card can be, so names have room, growing with the text.
    @ScaledMetric(relativeTo: .subheadline) private var cardWidth = 150

    var body: some View {
        let matches = Self.matches(in: Self.entries(in: game, localLanguage: localLanguage), for: query)
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 0)
                    .id(Self.topID)
                if matches.isEmpty {
                    Text(game.mode == .capitals ? "No capital called “\(query)”" : "No \(game.collection.placeNoun) called “\(query)”")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 8)], spacing: 8) {
                    ForEach(matches) { entry in
                        let state = ChoiceState(of: entry.places, in: game)
                        ChoiceCard(entry: entry, state: state) {
                            onAnswer(entry.answer(in: game))
                        }
                        .allowsHitTesting(game.phase == .asking && state == .open)
                        .opacity(game.phase == .answered && !state.isAnswer ? 0.5 : 1)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // The card grids' own scrolling chrome: room for a lit card's glow and pop, and a soft
            // edge only where the list carries on out of sight.
            .cardGridScrolling(bottomInset: bottomInset)
            // The cards close up as they narrow, springing, or with Reduce Motion, easing quickly.
            .animation(Motion.moving(.snappy, reduceMotion: reduceMotion), value: matches.map(\.id))
            .onChange(of: game.phase) {
                // A shown answer may be out of sight further down.
                guard game.phase == .answered, let place = game.current,
                      let entry = matches.first(where: { $0.places.contains(place) }) else { return }
                withAnimation(scrolling) { proxy.scrollTo(entry.id, anchor: .center) }
            }
            .onChange(of: game.current?.id) {
                withAnimation(scrolling) { proxy.scrollTo(Self.topID, anchor: .top) }
            }
            .onChange(of: query) {
                guard let first = matches.first else { return }
                withAnimation(scrolling) { proxy.scrollTo(first.id, anchor: .top) }
            }
            .onChange(of: game.wrongGuesses.count) {
                // Just enough to bring a wrong pick wholly into view.
                guard let wrong = game.wrongGuesses.last,
                      let entry = matches.first(where: { $0.places.contains(wrong) }) else { return }
                withAnimation(scrolling) { proxy.scrollTo(entry.id) }
            }
        }
    }

    /// The cards for the places still in play, in alphabetical order: their names, or in Capital,
    /// every one of their capitals.
    @MainActor
    static func entries(in game: MapGame, localLanguage: Bool) -> [ChoiceEntry] {
        let entries: [ChoiceEntry]
        if game.mode == .capitals {
            var byName: [String: ChoiceEntry] = [:]
            for place in game.options {
                for capital in game.capitals[place.id] ?? [] {
                    let key = CapitalCities.normalized(capital.name)
                    if byName[key] == nil {
                        byName[key] = ChoiceEntry(
                            id: "capital-\(key)", name: capital.name, language: nil, flagAssetName: nil, places: [],
                            searchNames: Set(capital.names.map(folded)))
                    }
                    byName[key]?.places.append(place)
                }
            }
            entries = Array(byName.values)
        } else {
            entries = game.options.map { place in
                let name = place.displayName(localLanguage: localLanguage)
                return ChoiceEntry(
                    id: place.id, name: name, language: place.language(of: name),
                    flagAssetName: game.mode == .everything
                        ? game.countryFlagAssetName(of: place)
                        : [.nameIt, .outline, .dot, .whoseCapital].contains(game.mode) ? place.flagAssetName : nil,
                    places: [place],
                    searchNames: Set([place.name, place.localName].compactMap { $0 }.map(folded)))
            }
        }
        return entries.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static let topID = "top"

    /// How the list glides to what matters; with Reduce Motion, it simply goes there.
    private var scrolling: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.4)
    }

    /// Cards with a name that holds what's been typed.
    static func matches(in entries: [ChoiceEntry], for query: String) -> [ChoiceEntry] {
        let typed = folded(query)
        guard !typed.isEmpty else { return entries }
        return entries.filter { entry in entry.searchNames.contains { $0.contains(typed) } }
    }

    /// A name as it'd be typed: without case or accents.
    static func folded(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespaces).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}

/// A name to choose from a list of all, as a card like the boards in Countries settings: the
/// place's flag, where it doesn't give the answer away, and its name, gliding across to show the
/// rest when it's too long to fit. Chosen wrongly, it turns to red candy, struck through, with a
/// shake; the answer lights up in the colour it went.
private struct ChoiceCard: View {
    var entry: ChoiceEntry
    var state: ChoiceState
    var onChoose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pops = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let color = state.color(open: .secondary)
        Button {
            pops += 1
            onChoose()
        } label: {
            HStack(spacing: 10) {
                if let flag = entry.flagAssetName {
                    // The whole flag, at its own proportions, in a box of its own.
                    Image(flag)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 22)
                        .accessibilityHidden(true)
                }
                // Whole when it fits; a long name glides to its end now and then, never cut short.
                ScrollingText(trigger: pops) {
                    Text(entry.name)
                        .placeName(entry.language)
                        .strikethrough(state == .wrong)
                }
                .font(.callout.weight(PlaceTypesetting.weight(.light, for: entry.language)))
                .frame(maxWidth: .infinity, alignment: .leading)
                if let symbol = state.symbolName {
                    Image(systemName: symbol)
                        .font(.subheadline.weight(.semibold))
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(state.isLit ? AnyShapeStyle(CandyGloss.lettering(on: color)) : AnyShapeStyle(.primary))
            .background {
                if state.isLit {
                    CandyGloss(color: color, pattern: state.pattern(open: nil))
                } else {
                    shape.fill(.fill.quaternary)
                }
            }
            .clipShape(shape)
            .shadow(color: color.opacity(state.isLit ? 0.35 : 0), radius: 6, y: 3)
            .pop(on: pops)
            .contentShape(shape)
        }
        .buttonStyle(PillButtonStyle())
        // Picked wrongly, it shakes, once: not again as it's set right for the next question, the
        // cards staying on from one question to the next. With Reduce Motion, it nods.
        .shake(onRiseOf: state == .wrong ? 1 : 0, amplitude: 8)
        .animation(ChoiceState.lighting(reduceMotion: reduceMotion), value: state)
        .accessibilityLabel(entry.name)
        .accessibilityValue(state.accessibilityValue)
    }
}

