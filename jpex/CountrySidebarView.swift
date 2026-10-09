import SwiftUI

/// Every list to open, by continent, with the World first and the person's pinned lists after it.
/// Search finds a list by name in either language, folded sections included.
struct CountrySidebarView: View {
    var sections: [CollectionSection]
    @Binding var selectedCountryID: String
    var saveModel: SaveModel?
    var rules: CountingRules
    @Environment(\.visitLadder) private var ladder
    /// The titles of the sections folded away, one per line. Groups of countries start folded.
    @AppStorage("sidebarCollapsedSections") private var collapsedSections = CollectionSection.worldGroupsTitle
    /// The IDs of the lists pinned under the World, one per line, in the order they were pinned.
    @AppStorage("sidebarPinnedLists") private var pinnedLists = "JP"
    @State private var searchText = ""

    private static let pinnedTitle = "Pinned"

    private var pinnedIDs: [String] {
        pinnedLists.split(separator: "\n").map(String.init)
    }

    /// Every list once, in sidebar order.
    private var allLists: [Country] {
        var seen: Set<String> = []
        return sections.flatMap(\.countries).filter { seen.insert($0.id).inserted }
    }

    private var pinned: [Country] {
        let lists = allLists
        return pinnedIDs.compactMap { id in lists.first { $0.id == id } }
    }

    private var searchResults: [Country] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return allLists.filter { $0.name.localizedStandardContains(query) || $0.localName.localizedStandardContains(query) }
    }

    var body: some View {
        let snapshot = saveModel?.snapshot()
        let isSearching = !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        ScrollViewReader { scroller in
            List(selection: Binding<String?>(get: { selectedCountryID }, set: { if let value = $0 { selectedCountryID = value } })) {
                if isSearching {
                    let results = searchResults
                    Section {
                        rows(for: results, snapshot: snapshot)
                    } header: {
                        if !results.isEmpty {
                            Text("^[\(results.count) list](inflect: true)")
                        }
                    }
                } else {
                    ForEach(sections) { section in
                        if let title = section.title {
                            // Every titled section folds away under its header, and stays as it was left.
                            Section(isExpanded: isExpanded(title)) {
                                rows(for: section.countries, snapshot: snapshot)
                            } header: {
                                SectionHeader(title: title, lists: section.countries, snapshot: snapshot, rules: rules)
                            }
                        } else {
                            Section {
                                rows(for: section.countries, snapshot: snapshot)
                            }
                            // The person's own lists, kept within reach just under the World.
                            if !pinned.isEmpty {
                                Section(isExpanded: isExpanded(Self.pinnedTitle)) {
                                    rows(for: pinned, snapshot: snapshot, inPinned: true)
                                } header: {
                                    SectionHeader(title: Self.pinnedTitle, lists: pinned, snapshot: snapshot, rules: rules)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $searchText, placement: .sidebar, prompt: "Find a country")
            .overlay {
                if isSearching, searchResults.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .animation(.smooth, value: pinnedLists)
            .sensoryFeedback(.selection, trigger: selectedCountryID)
            .sensoryFeedback(.impact(weight: .light), trigger: pinnedLists)
            // The open list is always in sight: when the sidebar appears, and when a list is opened
            // from elsewhere, such as a country tapped on the World map.
            .onAppear { scroller.scrollTo(rowID(selectedCountryID), anchor: .center) }
            .onChange(of: selectedCountryID) { _, id in
                withAnimation(.smooth) { scroller.scrollTo(rowID(id)) }
            }
        }
    }

    private func isPinned(_ id: String) -> Bool {
        pinnedIDs.contains(id)
    }

    private func togglePin(_ id: String) {
        var ids = pinnedIDs.filter { $0 != id }
        if !isPinned(id) { ids.append(id) }
        pinnedLists = ids.joined(separator: "\n")
    }

    /// Where a list sits in its own section, for scrolling to, rather than its copy among the pinned.
    private func rowID(_ id: String) -> String {
        "list-\(id)"
    }

    private func isExpanded(_ title: String) -> Binding<Bool> {
        Binding {
            !collapsedSections.split(separator: "\n").contains { $0 == title }
        } set: { isExpanded in
            var titles = collapsedSections.split(separator: "\n").map(String.init).filter { $0 != title }
            if !isExpanded { titles.append(title) }
            withAnimation(.smooth) { collapsedSections = titles.joined(separator: "\n") }
        }
    }

    private func rows(for lists: [Country], snapshot: TravelSnapshot?, inPinned: Bool = false) -> some View {
        ForEach(lists) { country in
            let canPin = country.id != CountryCatalog.world.id
            let pinned = isPinned(country.id)
            NavigationLink(value: country.id) {
                CountrySidebarRow(
                    country: country,
                    counted: snapshot?.count(in: country.divisions, counting: rules) ?? 0,
                    strongestStatus: snapshot?.strongestStatus(in: country.divisions) ?? .never,
                    tally: snapshot?.tally(of: country.divisions) ?? [:],
                    minimumStatus: rules.minimumLevel(in: ladder),
                    isSelected: country.id == selectedCountryID
                )
            }
            .tag(country.id)
            .id(inPinned ? "pinned-\(country.id)" : rowID(country.id))
            .contextMenu {
                if canPin {
                    Button(pinned ? "Unpin" : "Pin", systemImage: pinned ? "pin.slash" : "pin") {
                        togglePin(country.id)
                    }
                }
            }
            .swipeActions(edge: .leading) {
                if canPin {
                    Button(pinned ? "Unpin" : "Pin", systemImage: pinned ? "pin.slash.fill" : "pin.fill") {
                        togglePin(country.id)
                    }
                    .tint(.orange)
                }
            }
        }
    }
}

/// A section's title, with how many of its lists have been started, any place in them counted.
private struct SectionHeader: View {
    var title: String
    var lists: [Country]
    var snapshot: TravelSnapshot?
    var rules: CountingRules

    var body: some View {
        let started = lists.count { (snapshot?.count(in: $0.divisions, counting: rules) ?? 0) > 0 }
        HStack(alignment: .center, spacing: 6) {
            Text(title)
            Spacer(minLength: 8)
            Text("\(started)/\(lists.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(started)))
        }
        .animation(.snappy, value: started)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(started) of \(lists.count) lists started")
    }
}

/// One list in the sidebar, on a single line: its flag, its name and how many of its places count,
/// with a hairline of its levels beneath. A list that's complete wears a seal in its strongest colour.
private struct CountrySidebarRow: View {
    var country: Country
    var counted: Int
    var strongestStatus: VisitLevel
    var tally: [String: Int]
    var minimumStatus: VisitLevel
    /// The list open now.
    var isSelected = false
    @Environment(\.visitLadder) private var ladder
    @ScaledMetric(relativeTo: .body) private var badgeHeight = 17

    private var total: Int { country.divisions.count }
    private var isComplete: Bool { total > 0 && counted == total }

    var body: some View {
        HStack(spacing: 10) {
            badge
                .frame(width: badgeHeight * 1.5, height: badgeHeight)
                .clipShape(.rect(cornerRadius: 3))
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(.quaternary, lineWidth: country.flagAssetName == nil ? 0 : 0.5)
                }
                .grayscale(strongestStatus == .never ? 1 : 0)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    // A long name, such as Saint Vincent and the Grenadines, glides across now and
                    // then to show its end, as in Countries settings, rather than being cut short.
                    ScrollingName(text: country.name, trigger: 0)
                    if isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(strongestStatus.color)
                            // Springs in the moment the last place counts.
                            .transition(.symbolEffect(.appear.byLayer))
                    }
                    Text("\(counted)/\(total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(counted)))
                        .pop(on: counted)
                }
                StatusTallyBar(tally: tally, total: total, minimumStatus: minimumStatus, showsStripes: false)
                    .frame(height: 2.5)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(country.name)
        .accessibilityValue("\(counted) of \(total). \(StatusTallyBar.breakdown(of: tally, in: ladder))")
        .animation(.snappy, value: counted)
        .animation(.smooth(duration: 0.6), value: strongestStatus)
    }

    @ViewBuilder private var badge: some View {
        if let flag = country.flagAssetName {
            Image(flag)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let group = country.worldGroup {
            WorldGroupBadge(group: group)
        } else {
            TurningGlobe()
                .foregroundStyle(strongestStatus == .never ? AnyShapeStyle(.secondary) : AnyShapeStyle(strongestStatus.color))
        }
    }
}

/// The World's badge: a globe that now and then turns to show another side of the Earth,
/// starting from the side the World map is centred on.
private struct TurningGlobe: View {
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turns = 0

    /// Faces of the Earth from west to east, so each turn follows the Earth's spin.
    private static let faces = MapCenter.allCases.sorted { $0.eastwardOrder < $1.eastwardOrder }

    var body: some View {
        let start = Self.faces.firstIndex(of: center) ?? 0
        let face = Self.faces[(start + turns) % Self.faces.count]
        Image(systemName: face.globeSymbolName)
            .font(.system(size: 15))
            .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer)))
            .task(id: reduceMotion) {
                guard !reduceMotion else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(.random(in: 6...11)))
                    guard !Task.isCancelled else { return }
                    withAnimation(.smooth) { turns += 1 }
                }
            }
            .onChange(of: center) { turns = 0 }
    }
}
