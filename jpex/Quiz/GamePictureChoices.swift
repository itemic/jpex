import SwiftUI

/// Four pictures to pick from, for identifying a place's flag, outline or code: dealt two to a
/// row, one after another with a bounce, with number keys to pick them. A wrong one is marked in
/// red and shakes, and says whose it is; the answer lights up in the colour it went, throwing
/// confetti when it's right first time. Once it's answered, every one says whose it is.
struct PictureChoiceGrid: View {
    var game: MapGame
    var picture: ChoicePicture
    var onAnswer: (AdministrativeDivision) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDealt = false
    /// Every tile's height, with room for a large picture and a name beneath it.
    @ScaledMetric(relativeTo: .title3) private var height = 108

    private static let confettiColors: [Color] = [LevelColor.lightBlue, .pink, .green, .yellow, .orange].map(\.color)

    var body: some View {
        let dealt = game.dealt
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(Array(stride(from: 0, to: dealt.count, by: 2)), id: \.self) { first in
                GridRow {
                    ForEach(first..<min(first + 2, dealt.count), id: \.self) { index in
                        choice(dealt[index].place, number: index + 1)
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

    private func choice(_ place: AdministrativeDivision, number: Int) -> some View {
        let state = ChoiceState(of: place, in: game)
        return PictureChoiceButton(
            game: game, place: place, picture: picture, state: state, number: number,
            showsName: game.phase == .answered || state == .wrong
        ) {
            onAnswer(place)
        }
        .frame(height: height)
        .allowsHitTesting(state == .open && game.phase == .asking)
        .opacity(state == .passed ? 0.6 : 1)
        .overlay {
            // Right first time throws confetti from the picture.
            CelebrationBurst(trigger: state == .answer(.right(tries: 1)) ? 1 : 0, colors: Self.confettiColors, pieceCount: 30)
                .frame(width: 280, height: 280)
                .allowsHitTesting(false)
        }
        .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: [])
    }
}

/// Every flag, outline or code in play to pick from: a grid of them to look through and tap, the
/// places already answered this round left out, in order of their names so one seen once is easy
/// to find again. It fills whatever room it's given, right down to its holder's foot, and where it
/// carries on out of sight it fades away softly at its top or foot, as the list of names does,
/// rather than stopping at a hard edge. It keeps what matters in view by itself: back to the top
/// for each new question, and to the answer once it's given.
struct PictureCardChoices: View {
    var game: MapGame
    var picture: ChoicePicture
    /// Room beneath the last tile for the home indicator, where the grid runs to the foot of the screen.
    var bottomInset: CGFloat = 0
    var onAnswer: (AdministrativeDivision) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The narrowest a tile can be, growing with the text.
    @ScaledMetric(relativeTo: .subheadline) private var tileWidth = 84

    private static let topID = "top"

    var body: some View {
        let places = Self.choices(in: game, picture: picture)
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 0)
                    .id(Self.topID)
                // Codes, wider than flags and shapes, get wider tiles.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: picture == .code ? tileWidth * 1.6 : tileWidth), spacing: 8)], spacing: 8) {
                    ForEach(places) { place in
                        let state = ChoiceState(of: place, in: game)
                        PictureChoiceButton(game: game, place: place, picture: picture, state: state, number: nil, showsName: state.isLit) {
                            onAnswer(place)
                        }
                        .frame(height: tileWidth * (state.isLit ? 0.92 : 0.7))
                        .allowsHitTesting(game.phase == .asking && state == .open)
                        .opacity(game.phase == .answered && !state.isAnswer ? 0.5 : 1)
                        .id(place.id)
                    }
                }
            }
            // The list of names' own chrome: room all round for a lit tile's ring, its mark and its
            // shake, which the scroll view would otherwise cut off; no scroll bars, nor a bounce when
            // every tile fits; and a soft edge at the top or foot only where there's more to see.
            .cardGridScrolling(bottomInset: bottomInset)
            // The tiles close up as answered ones leave, springing, or with Reduce Motion, easing quickly.
            .animation(Motion.moving(.snappy, reduceMotion: reduceMotion), value: places.map(\.id))
            .task(id: game.phase) {
                // A shown answer may be out of sight further down. The grid gives up its foot to the
                // verdict as it's answered, so it waits a moment for its new height, then glides the
                // answer to the middle of what's left.
                guard game.phase == .answered, let place = game.current else { return }
                try? await Task.sleep(for: .milliseconds(60))
                guard !Task.isCancelled else { return }
                withAnimation(scrolling) { proxy.scrollTo(place.id, anchor: .center) }
            }
            .onChange(of: game.current?.id) {
                withAnimation(scrolling) { proxy.scrollTo(Self.topID, anchor: .top) }
            }
        }
    }

    /// What there is to pick, in order of the places' names: every place in play not answered yet,
    /// and for codes, each code once, though several places share it, as +1 is shared, the one in
    /// question standing for its own.
    @MainActor
    private static func choices(in game: MapGame, picture: ChoicePicture) -> [AdministrativeDivision] {
        let places = game.options.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        guard picture == .code else { return places }
        var seen: Set<String> = []
        let current = game.current.map { [$0] } ?? []
        return (current + places).filter { place in
            guard let code = game.code(of: place) else { return false }
            return seen.insert(code).inserted
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// How the grid glides to what matters; with Reduce Motion, it simply goes there.
    private var scrolling: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.4)
    }
}

/// What a picture to pick shows of a place.
enum ChoicePicture {
    /// Its flag, in Flag the other way round.
    case flag
    /// Its shape, in Outline the other way round.
    case outline
    /// Its code of the kind being played, in Code the other way round.
    case code
}

/// One picture to pick: a place's flag, outline or code on a soft tile. Picked wrongly, it's dimmed
/// with a red ring and shakes; the answer is ringed in the colour it went, with its mark. Where it
/// says whose it is, the name sits beneath, gliding to its end if it's long.
struct PictureChoiceButton: View {
    var game: MapGame
    var place: AdministrativeDivision
    var picture: ChoicePicture
    var state: ChoiceState
    /// The number key that picks it, where there is one.
    var number: Int?
    var showsName: Bool
    var action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let color = state.color(open: .secondary)
        Button(action: action) {
            VStack(spacing: 5) {
                pictureView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(state == .wrong ? 0.55 : 1)
                if showsName {
                    ScrollingName(text: place.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(state.isLit ? AnyShapeStyle(color) : AnyShapeStyle(.secondary))
                        .transition(.opacity)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shape.fill(state.isLit ? AnyShapeStyle(color.opacity(0.14)) : AnyShapeStyle(.fill.quaternary)))
            .overlay { shape.strokeBorder(color, lineWidth: state.isLit ? 2.5 : 0) }
            .overlay(alignment: .topTrailing) {
                if let symbol = state.symbolName {
                    Image(systemName: symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(color, in: Circle())
                        .offset(x: 6, y: -6)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                        .accessibilityHidden(true)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(PillButtonStyle())
        // Picked wrongly, it shakes, once: not again as it's set right for the next question, the
        // grid of every picture staying on from one question to the next. One of four shakes as the
        // big choices do, one of a grid as a list's cards do; with Reduce Motion, it nods.
        .shake(onRiseOf: state == .wrong ? 1 : 0, amplitude: number == nil ? 8 : 10)
        .animation(ChoiceState.lighting(reduceMotion: reduceMotion), value: state)
        .accessibilityLabel(spokenLabel)
        .accessibilityValue(state.accessibilityValue)
    }

    /// The flag, the shape in the mode's candy colour with a crisp white edge, turned where shapes
    /// come rotated, or the code dressed as it's met in the world.
    @ViewBuilder
    private var pictureView: some View {
        switch picture {
        case .flag:
            Image(place.flagAssetName)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 3))
                .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
        case .outline:
            if let path = game.outline(of: place) {
                ZStack {
                    OutlineShape(unit: path)
                        .fill(LinearGradient(colors: [game.mode.color.opacity(0.7), game.mode.color], startPoint: .top, endPoint: .bottom))
                    OutlineShape(unit: path)
                        .stroke(.white, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                }
                .rotationEffect(.degrees(game.rotations[place.id] ?? 0))
                .padding(4)
            }
        case .code:
            // As large as the tile holds: most codes at the largest, a long one smaller.
            ViewThatFits(in: .horizontal) {
                ForEach([27, 22, 18, 14] as [CGFloat], id: \.self) { size in
                    CodeBadge(code: game.code(of: place) ?? "", kind: game.shownCodeKind, size: size)
                        .fixedSize()
                }
            }
        }
    }

    /// What VoiceOver hears: a code is read out, letter by letter; a flag or a shape can't be, so
    /// it's numbered until it's named.
    private var spokenLabel: String {
        if picture == .code, let code = game.code(of: place) {
            return showsName ? "\(CodeBadge.spoken(code)), \(place.name)" : CodeBadge.spoken(code)
        }
        let kind = picture == .flag ? "Flag" : "Outline"
        if showsName { return "\(kind) of \(place.name)" }
        return number.map { "\(kind) \($0)" } ?? "A \(kind.lowercased())"
    }
}
