import SwiftUI

/// Makes or changes a group of countries of the person's own. Its badge and name sit at the top,
/// the badge choosing the group's colour and symbol. Beneath them, a pill for each level the
/// person has been to, with how many places are at it, puts every one of those places in at once,
/// and All puts in everywhere that counts; lit once they're all in, another tap takes them out.
/// Then every country, under its continent, is a card to tap in or out, like the quiz's list of
/// all to choose from, narrowed by typing. Cards going in light up calmly in the group's colour,
/// one after another when a pill or a continent's All puts in many.
struct CustomGroupEditor: View {
    var onSave: (CustomWorldGroup) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft: CustomGroupDraft
    /// The group as it was when the editor opened, to tell whether anything has changed.
    private let original: CustomGroupDraft
    private let rules: CountingRules
    private let choices: GroupPlaceChoices
    @State private var query = ""
    /// Whether only the countries in the group are shown, to look it over.
    @State private var showsChosenOnly = false
    @State private var isConfirmingDiscard = false
    /// The cards a pill or a continent's button just put in or took out, lighting up in turn.
    @State private var cascade = Cascade()
    /// Counts countries put in by typing their name and pressing Return, for a tap.
    @State private var typedAdditions = 0
    @FocusState private var focus: Field?
    /// The narrowest a card can be, so names have room, growing with the text.
    @ScaledMetric(relativeTo: .subheadline) private var cardWidth = 150

    private enum Field {
        case name, search
    }

    init(
        draft: CustomGroupDraft, rules: CountingRules, snapshot: TravelSnapshot,
        onSave: @escaping (CustomWorldGroup) -> Void
    ) {
        _draft = State(initialValue: draft)
        original = draft
        self.rules = rules
        choices = GroupPlaceChoices(rules: rules, snapshot: snapshot, members: draft.memberIDs)
        self.onSave = onSave
    }

    private var hasChanges: Bool {
        draft != original
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    beenPills
                    searchRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                cards
            }
            .fontDesign(.rounded)
            .navigationTitle(draft.isNew ? "New group" : "Edit group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        // Once anything's changed, a swipe down doesn't throw it away; Cancel asks first.
        .interactiveDismissDisabled(hasChanges)
        .sensoryFeedback(.impact(weight: .medium), trigger: cascade.token)
        .sensoryFeedback(.impact(weight: .light), trigger: typedAdditions)
        .task(id: cascade.token) {
            guard !cascade.order.isEmpty else { return }
            try? await Task.sleep(for: .seconds(1.1))
            cascade.order = [:]
        }
        .task {
            // A new group starts with its name, the keyboard up for it.
            guard draft.isNew, draft.name.isEmpty else { return }
            try? await Task.sleep(for: .milliseconds(450))
            focus = .name
        }
    }

    // MARK: Name and look

    /// The group's badge, which opens its design, beside its name and how many countries are in it.
    private var header: some View {
        HStack(spacing: 14) {
            NavigationLink {
                GroupEmblemPicker(design: $draft.design, tint: draft.tint.color)
            } label: {
                EmblemTile(emblem: draft.emblem)
            }
            .buttonStyle(PillButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { focus = nil })
            .accessibilityLabel("Badge")
            .accessibilityHint("Designs the group's badge: its pattern, colours and symbol.")
            VStack(alignment: .leading, spacing: 2) {
                TextField("Group name", text: $draft.name)
                    .typeStyle(.compactPlaceName)
                    .fontDesign(.default)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($focus, equals: .name)
                    .onSubmit { focus = nil }
                Text("^[\(draft.memberIDs.count) country](inflect: true)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText(value: Double(draft.memberIDs.count)))
                    .animation(Motion.count, value: draft.memberIDs.count)
            }
        }
    }

    // MARK: Where they've been

    /// All, then a pill for each level with places at it, lowest first, each putting every one of
    /// them in. Only once the person has been somewhere.
    @ViewBuilder
    private var beenPills: some View {
        let been = choices.placesBeen(rules: rules, ladder: ladder)
        let levels = ladder.levels
            .map { LevelChoice(level: $0, places: choices.places(at: $0)) }
            .filter { !$0.places.isEmpty }
        if !levels.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Places you’ve been")
                    .typeStyle(.eyebrow)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        if !been.isEmpty {
                            LevelPill(
                                level: everywhere, count: been.count, isOn: draft.containsAll(been),
                                spokenName: "Everywhere you’ve been"
                            ) {
                                toggleAll(been)
                            }
                        }
                        ForEach(levels) { choice in
                            LevelPill(
                                level: choice.level, count: choice.places.count, isOn: draft.containsAll(choice.places),
                                spokenName: choice.level.name
                            ) {
                                toggleAll(choice.places)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -16)
            }
        }
    }

    /// All, as a pill in the group's own colour, for everywhere the person has been that counts.
    private var everywhere: VisitLevel {
        VisitLevel(id: "group.everywhere", name: "All", tint: draft.tint, symbolName: "checkmark")
    }

    // MARK: Finding countries

    /// Narrows the cards as you type, beside a switch to see only the countries chosen.
    private var searchRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Type a name", text: $query)
                    .focused($focus, equals: .search)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(addTypedCountry)
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
            chosenOnlyToggle
        }
    }

    /// How many are in the group, as a capsule that shows only them while it's on, lit calmly in
    /// a wash of the group's colour inside a ring of it, as chosen cards are. It pops as its count
    /// rolls whenever a pill or a continent's button puts many in or takes them out, or a country
    /// goes in by typing, as their cards are often out of sight.
    private var chosenOnlyToggle: some View {
        let count = draft.memberIDs.count
        let color = draft.tint.color
        return Toggle(isOn: $showsChosenOnly.animation(.snappy)) {
            HStack(spacing: 5) {
                Image(systemName: showsChosenOnly ? "checkmark.circle.fill" : "checkmark.circle")
                    .contentTransition(.symbolEffect(.replace))
                Text(count, format: .number)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(count)))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            .foregroundStyle(showsChosenOnly ? AnyShapeStyle(color) : AnyShapeStyle(.secondary))
            .background(showsChosenOnly ? AnyShapeStyle(color.opacity(0.14)) : AnyShapeStyle(.primary.opacity(0.07)), in: Capsule())
            .overlay {
                Capsule().strokeBorder(showsChosenOnly ? AnyShapeStyle(color.opacity(0.6)) : AnyShapeStyle(.clear), lineWidth: 1.5)
            }
            .contentShape(Capsule())
            .animation(Motion.count, value: count)
            .pop(on: typedAdditions + cascade.token)
        }
        .toggleStyle(.button)
        .buttonStyle(PillButtonStyle())
        .sensoryFeedback(.selection, trigger: showsChosenOnly)
        .accessibilityLabel("Show chosen only")
        .accessibilityValue("\(count) chosen")
    }

    // MARK: Cards

    /// Every country to choose from as cards under their continents, fading out at the top and
    /// foot only where the list carries on beyond.
    private var cards: some View {
        let continents = choices.continents(matching: query, within: showsChosenOnly ? draft.memberIDs : nil)
        let shownIDs = continents.flatMap { $0.divisions.map(\.id) }
        return ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 0)
                    .id(Self.topID)
                // The message and the cards share the top, so as typing narrows everything away,
                // or back, the one fades over the other rather than shoving it down.
                ZStack(alignment: .topLeading) {
                    if continents.isEmpty {
                        Text(emptyMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                            .transition(.opacity)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 8)], spacing: 8) {
                        ForEach(continents) { continent in
                            Section {
                                ForEach(continent.divisions) { place in
                                    card(for: place)
                                }
                            } header: {
                                continentHeader(continent)
                            }
                        }
                    }
                }
            }
            // The card grids' own chrome: soft edges at the top and foot only where more countries
            // carry on, room at the sides for a card's pop, and room at the foot clear of the
            // sheet's edge.
            .cardGridScrolling(bottomInset: 16)
            // The chrome bleeds 12 out past the scroll view's sides and keeps the cards 12 in from
            // there, so they sit wherever its holder's edges are. Held 16 in, they line up with the
            // header and search above, with 12 of that left for a card's pop.
            .padding(.horizontal, 16)
            .scrollDismissesKeyboard(.interactively)
            .animation(.snappy, value: shownIDs)
            .onChange(of: query) {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.4)) { proxy.scrollTo(Self.topID, anchor: .top) }
            }
            .onChange(of: showsChosenOnly) {
                proxy.scrollTo(Self.topID, anchor: .top)
            }
        }
    }

    private static let topID = "top"

    private var emptyMessage: String {
        GroupPlaceChoices.folded(query).isEmpty ? "No countries chosen yet" : "No country called “\(query)”"
    }

    /// A country as a card like those in the quiz's list of all: its flag, with a dot in the colour
    /// of the level the person has reached there, and its name. In the group, it lights up calmly in
    /// the group's colour with a tick, one after another when many go in at once.
    private func card(for place: AdministrativeDivision) -> some View {
        let level = choices.level(of: place)
        let hasBeen = level.id != VisitLevel.never.id
        let isChosen = draft.contains(place)
        return PlaceChoiceCard(
            name: place.name, flagAssetName: place.flagAssetName, tint: draft.tint.color,
            levelColor: hasBeen ? level.color : nil, isSelected: isChosen,
            spokenDetail: hasBeen ? level.name : nil,
            spokenHint: isChosen ? "Takes it out of the group." : "Puts it in the group.",
            selectionDelay: cascade.delay(for: place.id), showsCheckmark: true
        ) {
            // Tapped by hand, it answers at once, even mid-cascade.
            cascade.order[place.id] = nil
            draft.toggle(place)
        }
        .id(place.id)
    }

    /// A continent's name, how many of its countries are in, and a button for all of those shown or none.
    private func continentHeader(_ shown: DivisionGroup) -> some View {
        let all = choices.continents.first { $0.id == shown.id }?.divisions ?? shown.divisions
        let chosen = all.count { draft.contains($0) }
        let isAllIn = draft.containsAll(shown.divisions)
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            ScrollingText {
                Text(shown.name)
                    .font(.headline)
            }
            .accessibilityAddTraits(.isHeader)
            Text("\(chosen) of \(all.count)")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(chosen)))
                .accessibilityLabel("\(chosen) of \(all.count) chosen")
            Spacer(minLength: 8)
            Button(isAllIn ? "None" : "All") {
                toggleAll(shown.divisions)
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(draft.tint.color)
            .accessibilityLabel(isAllIn ? "Take out \(shown.name)" : "Put in all of \(shown.name)")
        }
        .padding(.top, 14)
        .padding(.bottom, 2)
        .animation(Motion.count, value: chosen)
    }

    // MARK: Actions

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") {
                if hasChanges {
                    isConfirmingDiscard = true
                } else {
                    dismiss()
                }
            }
            .keyboardShortcut(.cancelAction)
            .confirmationDialog("Discard your changes?", isPresented: $isConfirmingDiscard, titleVisibility: .hidden) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Done", systemImage: "checkmark") {
                onSave(draft.group)
                dismiss()
            }
            .tint(draft.tint.color)
            .disabled(!draft.canSave)
        }
    }

    /// Puts many in or takes them out at once, their cards lighting up one after another.
    private func toggleAll(_ places: [AdministrativeDivision]) {
        let changed = draft.toggleAll(places)
        guard !changed.isEmpty else { return }
        cascade = Cascade(
            order: Dictionary(changed.enumerated().map { ($1.id, $0) }) { first, _ in first },
            token: cascade.token + 1)
    }

    /// Return puts in the country typed out in full, or the only one left, and clears the field
    /// for the next.
    private func addTypedCountry() {
        let typed = GroupPlaceChoices.folded(query)
        guard !typed.isEmpty else { return }
        let matches = choices.continents(matching: query, within: showsChosenOnly ? draft.memberIDs : nil)
            .flatMap(\.divisions)
        guard let place = matches.first(where: { GroupPlaceChoices.folded($0.name) == typed })
            ?? (matches.count == 1 ? matches.first : nil)
        else { return }
        if !draft.contains(place) {
            draft.toggle(place)
            typedAdditions += 1
        }
        query = ""
        focus = .search
    }
}

/// What the group editor opens on.
enum GroupEditorTarget: Hashable {
    /// A new group, starting empty.
    case new
    /// One of the person's groups, to change.
    case edit(UUID)
    /// A new group starting from another's members, such as the EU's, by its list's ID.
    case copy(of: String)
}

/// A level the person has places at, and those places.
private struct LevelChoice: Identifiable {
    var level: VisitLevel
    var places: [AdministrativeDivision]

    var id: String { level.id }
}

/// The cards just put in or taken out together, by the order they light up in, and a count of
/// such changes.
private struct Cascade: Equatable {
    var order: [String: Int] = [:]
    var token = 0

    /// How long a card waits before lighting up, so a whole level lights up one card after another.
    func delay(for id: String) -> Double {
        order[id].map { min(Double($0) * 0.018, 0.6) } ?? 0
    }
}

/// The group's badge, large: its symbol on a tile in its colour, with a small brush at its corner
/// saying it can be changed.
private struct EmblemTile: View {
    var emblem: GroupEmblem
    @ScaledMetric(relativeTo: .title) private var height = 46

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: height * 0.16, style: .continuous)
        WorldGroupBadge(emblem: emblem, symbolScale: 0.5)
            .frame(width: height * 1.5, height: height)
            .clipShape(shape)
            .overlay { shape.strokeBorder(.primary.opacity(0.1), lineWidth: 0.5) }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "paintbrush.pointed.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(emblem.color)
                    .frame(width: 22, height: 22)
                    .background(.background, in: Circle())
                    .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    .offset(x: 6, y: 6)
            }
            .animation(.snappy, value: emblem)
    }
}

/// A level among the places the person has been, with how many are at it. A tap puts every one
/// of them in the group, lighting the pill up once they're all in; another takes them all out.
private struct LevelPill: View {
    var level: VisitLevel
    var count: Int
    var isOn: Bool
    /// What it puts in, for VoiceOver, such as Visited.
    var spokenName: String
    var action: () -> Void
    @State private var pops = 0

    var body: some View {
        Button {
            pops += 1
            action()
        } label: {
            VisitPillLabel(status: level, suffix: " \(count)", isLit: isOn)
                .pop(on: pops)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel(spokenName)
        .accessibilityValue("^[\(count) place](inflect: true)")
        .accessibilityHint(isOn ? "Takes them all out of the group." : "Puts them all in the group.")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
