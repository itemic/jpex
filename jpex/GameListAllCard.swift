import SwiftUI

/// List All's card: every place in play to name, in any order, like a Sporcle quiz. A thin bar
/// counts the places named, with any round's clock beside it. One field takes the names, each
/// counted the moment it's spelt out in full, and clears for the next as the place fills in on the
/// map; Return on a name that isn't one shakes it. The places named so far run beneath it, newest
/// first. Give Up shows the rest, once it's confirmed, and ends the round.
struct GameListAllCard: View {
    var game: MapGame
    var localLanguage: Bool
    /// Names a place from what's typed, returning it where it's one not named yet.
    var onTyped: (String) -> AdministrativeDivision?
    var onGiveUp: () -> Void
    /// Room beneath the card for the home indicator, where it runs to the foot of the screen.
    var bottomInset: CGFloat = 0
    @State private var query = ""
    @FocusState private var isTyping: Bool
    /// Counts names that aren't places in play, Returned, for a shake.
    @State private var misses = 0
    /// A word about what's typed, such as that it's already been named.
    @State private var note: String?
    @State private var confirmsGiveUp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text("Name every \(game.collection.placeNoun)")
                .font(.title2.weight(.light))
            HStack(spacing: 8) {
                field
                giveUpButton
            }
            // One slot, the note and the names cross-fading in it, the same height whatever's in it,
            // so the card and the map behind keep still.
            ZStack(alignment: .leading) {
                if let note {
                    Label(note, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                } else {
                    namedRow
                        .transition(.opacity)
                }
            }
            .frame(height: 34, alignment: .leading)
        }
        .padding(16)
        .padding(.bottom, bottomInset)
        .fontDesign(.rounded)
        .animation(.snappy, value: note)
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            isTyping = true
        }
        .confirmationDialog("Show the \(game.collection.divisionLabel.lowercased()) left?", isPresented: $confirmsGiveUp, titleVisibility: .visible) {
            Button("Show them", role: .destructive, action: onGiveUp)
        } message: {
            Text("The round ends, with the ones you haven’t named shown on the map.")
        }
    }

    /// How many are named, as a thin bar across the card and a count, with the round's clock.
    private var header: some View {
        let total = game.questions.count
        let named = game.named.count
        return HStack(spacing: 10) {
            ProgressBarView(percentage: Double(named) / Double(max(total, 1)), color: game.mode.color)
                .frame(height: 5)
                .accessibilityHidden(true)
            HStack(spacing: 0) {
                Text("\(named)")
                    .typeStyle(.count)
                    .contentTransition(.numericText(value: Double(named)))
                Text(" / \(total)")
                    .typeStyle(.countTotal)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(named) of \(total) named")
            if let deadline = game.deadline {
                Countdown(deadline: deadline)
                    .fixedSize()
            }
        }
        .frame(minHeight: 20)
        .animation(.snappy, value: named)
    }

    /// Where the names are typed, each one taken as soon as it's spelt out in full.
    private var field: some View {
        HStack(spacing: 6) {
            Image(systemName: "character.cursor.ibeam")
                .foregroundStyle(.secondary)
            TextField("Type a \(game.collection.placeNoun)", text: $query)
                .focused($isTyping)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onChange(of: query) { take() }
                .onSubmit {
                    // A name that isn't one in play: a shake, and the field keeps it to fix.
                    if !query.isEmpty, note == nil { misses += 1 }
                    isTyping = true
                }
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
        .overlay {
            Capsule()
                .strokeBorder(LevelColor.red.color, lineWidth: 1.5)
                .keyframeAnimator(initialValue: 0.0, trigger: misses) { content, opacity in
                    content.opacity(opacity)
                } keyframes: { _ in
                    CubicKeyframe(1, duration: 0.1)
                    CubicKeyframe(0, duration: 0.8)
                }
        }
        // With Reduce Motion, the red edge and a nod say so.
        .shake(on: misses, amplitude: 8)
    }

    /// Give Up: an eye in a soft circle, as Reveal is in the other quizzes.
    private var giveUpButton: some View {
        Button {
            confirmsGiveUp = true
        } label: {
            Image(systemName: "eye")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.primary.opacity(0.07), in: Circle())
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel("Give up")
        .accessibilityHint("Shows the \(game.collection.divisionLabel.lowercased()) you haven’t named, and ends the round.")
    }

    /// The places named so far, newest first, each with its flag where it has one of its own.
    private var namedRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                if game.named.isEmpty {
                    Text("Each one fills in on the map as you name it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(game.named.reversed()) { place in
                    let name = place.displayName(localLanguage: localLanguage)
                    HStack(spacing: 5) {
                        if game.hasOwnFlag(place) {
                            Image(place.flagAssetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 14)
                        }
                        Text(name)
                            .placeName(place.language(of: name))
                            .font(.subheadline.weight(PlaceTypesetting.weight(.light, for: place.language(of: name))))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(game.mode.color.opacity(0.16), in: Capsule())
                    // Each name pops in as it's given; with Reduce Motion, it fades in.
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .padding(.vertical, 2)
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .bouncy(duration: 0.4, extraBounce: 0.15), value: game.named.count)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(game.named.isEmpty ? "None named yet" : "Named: \(game.named.reversed().map(\.name).formatted(.list(type: .and)))")
    }

    /// Takes what's typed as soon as it names a place not named yet, clearing the field for the
    /// next; spelt out as one already named, it says so.
    private func take() {
        if onTyped(query) != nil {
            query = ""
            note = nil
        } else if let named = game.alreadyNamed(query) {
            note = "\(named.displayName(localLanguage: localLanguage)) is already named."
        } else {
            note = nil
        }
    }
}
