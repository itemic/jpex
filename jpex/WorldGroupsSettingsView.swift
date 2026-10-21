import SwiftUI

/// Which groups of countries the sidebar shows, as boards of cards to tap in and out, like
/// Countries: the person's own groups first, with a card to make another, then the World's, by
/// where they reach. A card lights up while its group shows, the total at the top rolls with each
/// change, and a whole board can be shown or hidden at once, its cards lighting up one after
/// another. A hidden group is still there, its list and quiz as ever: Show Hidden at the end of
/// World Groups in the sidebar brings it back into view.
struct WorldGroupsSettingsView: View {
    /// For the places the person has been, which a group can take in at once; nil until the store is ready.
    var saveModel: SaveModel?
    @Environment(CustomWorldGroups.self) private var customGroups
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.visitLadder) private var ladder
    @AppStorage(HiddenWorldGroups.storageKey) private var hidden = HiddenWorldGroups()
    @ScaledMetric(relativeTo: .subheadline) private var cardWidth = 150
    /// The board just shown or hidden as a whole, so its cards light up in a cascade rather than at once.
    @State private var cascading: String?
    /// One of the person's groups being made or changed.
    @State private var draft: CustomGroupDraft?
    /// The group just saved in the editor, by its list's ID, for its card to pop once the sheet
    /// has gone.
    @State private var saved: String?
    /// How many times each group has come back from the editor saved, by its list's ID, so a new
    /// or changed group's card lands visibly rather than simply being there.
    @State private var arrivals: [String: Int] = [:]
    /// One of the person's groups waiting for them to confirm it should go.
    @State private var pendingDeletion: CustomWorldGroup?

    var body: some View {
        let yours = ownCards
        let shown = (yours + WorldGroupReach.allCases.flatMap(\.cards)).count { !hidden.isHidden($0.id) }
        Form {
            Section {
                WorldCountRow(count: shown, noun: shown == 1 ? "group" : "groups", tint: .indigo)
            }
            board("yours", title: "Your groups", cards: yours, systemImage: "star.fill", tint: .pink, makesNew: true)
            ForEach(WorldGroupReach.allCases) { reach in
                board(reach.rawValue, title: reach.title, cards: reach.cards, systemImage: reach.symbolName, tint: reach.tint)
            }
        }
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: cascading) {
            guard cascading != nil else { return }
            try? await Task.sleep(for: .seconds(1))
            cascading = nil
        }
        .sheet(item: $draft, onDismiss: landSavedGroup) { draft in
            CustomGroupEditor(
                draft: draft, rules: counting.rules,
                snapshot: saveModel?.snapshot() ?? TravelSnapshot(stored: [:], legacyJapan: [], ladder: ladder)
            ) { group in
                withAnimation(.snappy) { customGroups.save(group) }
                saved = group.collectionID
            }
        }
        .confirmationDialog(
            "Delete “\(pendingDeletion?.name ?? "")”?",
            isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
            titleVisibility: .visible
        ) {
            if let group = pendingDeletion {
                Button("Delete group", role: .destructive) {
                    withAnimation(.snappy) { customGroups.delete(group.id) }
                }
            }
        } message: {
            Text("Its countries keep their levels.")
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: cardWidth), spacing: 8)]
    }

    /// The person's own groups, A to Z, as the sidebar lists them.
    private var ownCards: [GroupCard] {
        customGroups.groups
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { group in
                GroupCard(
                    id: group.collectionID, name: group.name,
                    subtitle: group.memberIDs.count == 1 ? "1 country" : "\(group.memberIDs.count) countries",
                    emblem: group.emblem)
            }
    }

    /// A board of groups as cards, under a heading with how many show and a button for all or
    /// none. The person's own board starts with a card to make another.
    private func board(
        _ id: String, title: LocalizedStringKey, cards: [GroupCard], systemImage: String, tint: Color,
        makesNew: Bool = false
    ) -> some View {
        let shown = cards.count { !hidden.isHidden($0.id) }
        let isAllShown = shown == cards.count
        let isCascading = cascading == id
        return Section {
            VStack(alignment: .leading, spacing: 12) {
                BoardHeader(
                    title: title,
                    subtitle: Text(cards.isEmpty ? "None yet" : "\(shown) of \(cards.count) shown")
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(shown))),
                    systemImage: systemImage, tint: tint, trigger: shown
                ) {
                    if !cards.isEmpty {
                        Button(isAllShown ? "None" : "All") {
                            setShown(!isAllShown, for: cards, board: id)
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(tint)
                        .accessibilityLabel(isAllShown ? "Hide all of \(Text(title))" : "Show all of \(Text(title))")
                    }
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    if makesNew {
                        NewGroupCard {
                            draft = customGroups.draft(for: .new)
                        }
                    }
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        let isShown = !hidden.isHidden(card.id)
                        ToggleCard(
                            title: card.name, subtitle: card.subtitle, tint: tint, isOn: isShown,
                            delay: isCascading ? min(Double(index) * 0.018, 0.6) : 0,
                            arrivals: arrivals[card.id, default: 0]
                        ) {
                            GroupMark(emblem: card.emblem, isOn: isShown)
                        } action: {
                            // Tapped by hand, it answers at once, even mid-cascade.
                            cascading = nil
                            withAnimation(.snappy) { hidden.setHidden(isShown, for: card.id) }
                        }
                        .accessibilityValue(isShown ? "Shown" : "Hidden")
                        .contextMenu {
                            if let group = customGroups.group(collectionID: card.id) {
                                Button("Edit group", systemImage: "pencil") { draft = customGroups.draft(for: .edit(group.id)) }
                                Button("Duplicate", systemImage: "plus.square.on.square") {
                                    draft = customGroups.draft(for: .copy(of: card.id))
                                }
                                Button("Delete group", systemImage: "trash", role: .destructive) { pendingDeletion = group }
                            } else {
                                Button("Duplicate", systemImage: "plus.square.on.square") {
                                    draft = customGroups.draft(for: .copy(of: card.id))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    /// Pops the card of the group just saved, now the sheet has gone and it can be seen.
    private func landSavedGroup() {
        if let saved { arrivals[saved, default: 0] += 1 }
        saved = nil
    }

    /// Shows or hides a whole board, its cards lighting up one after another.
    private func setShown(_ isShown: Bool, for cards: [GroupCard], board: String) {
        cascading = board
        var updated = hidden
        for card in cards { updated.setHidden(!isShown, for: card.id) }
        withAnimation(.snappy) { hidden = updated }
    }
}

/// A group as a card on a board: its badge, its name and a line about it.
private struct GroupCard: Identifiable {
    /// Its list's ID.
    var id: String
    var name: String
    var subtitle: String
    var emblem: GroupEmblem
}

/// The World's groups by where they reach, a board each.
private enum WorldGroupReach: String, CaseIterable, Identifiable {
    case worldwide, europe, regional

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .worldwide: "Worldwide"
        case .europe: "Europe"
        case .regional: "Africa, Asia & the Americas"
        }
    }

    var symbolName: String {
        switch self {
        case .worldwide: "globe"
        case .europe: "star.circle.fill"
        case .regional: "map.fill"
        }
    }

    var tint: Color {
        switch self {
        case .worldwide: .blue
        case .europe: .indigo
        case .regional: .green
        }
    }

    var groups: [WorldGroup] {
        switch self {
        case .worldwide: [.unitedNations, .g7, .g20, .oecd, .brics, .opec, .commonwealth]
        case .europe: [.europeanUnion, .schengen, .eurozone, .nato, .efta, .nordic, .baltic, .benelux]
        case .regional: [.asean, .africanUnion, .arabLeague, .gulfCooperation, .mercosur, .caricom]
        }
    }

    var cards: [GroupCard] {
        groups.map { group in
            let members = WorldGroup.collections.first { $0.id == group.collectionID }?.divisions.count ?? 0
            return GroupCard(
                id: group.collectionID, name: group.name, subtitle: members == 1 ? "1 country" : "\(members) countries",
                emblem: group.emblem)
        }
    }
}

/// A group's badge at the front of its card, greyed out while the group is hidden.
private struct GroupMark: View {
    var emblem: GroupEmblem
    var isOn: Bool

    var body: some View {
        WorldGroupBadge(emblem: emblem)
            .frame(width: 30, height: 20)
            .clipShape(.rect(cornerRadius: 3.5))
            .overlay { RoundedRectangle(cornerRadius: 3.5).strokeBorder(.quaternary, lineWidth: 0.5) }
            .saturation(isOn ? 1 : 0.15)
            .opacity(isOn ? 1 : 0.6)
    }
}

/// The first card among the person's own groups: a dashed outline with a plus, to make another.
private struct NewGroupCard: View {
    var action: () -> Void
    @State private var pops = 0
    @ScaledMetric(relativeTo: .subheadline) private var textHeight = 36

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        Button {
            pops += 1
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .frame(width: 30, height: 20)
                VStack(alignment: .leading, spacing: 1) {
                    ScrollingText {
                        Text("New group")
                            .font(.subheadline.weight(.semibold))
                    }
                    ScrollingText {
                        Text("Make your own")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: textHeight, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay { shape.strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) }
            .pop(on: pops)
            .contentShape(shape)
        }
        .buttonStyle(PillButtonStyle())
        .sensoryFeedback(.selection, trigger: pops)
        .accessibilityLabel("New group")
        .accessibilityHint("Makes a group of countries of your own.")
    }
}
