import SwiftUI

/// Every list to open, by continent, with the World first and the person's pinned lists after it.
/// Search finds a list by name in either language, folded sections included, and any place in
/// any list, which opens its list with the place in view.
struct CountrySidebarView: View {
    var sections: [CollectionSection]
    @Binding var selectedCountryID: String
    var saveModel: SaveModel?
    var rules: CountingRules
    /// Opens the list a place found by search is in, with the place brought into view.
    var onOpenPlace: (_ placeID: String, _ collectionID: String) -> Void = { _, _ in }
    /// Opens the editor for a group of countries of the person's own: a new one, one of theirs, or a copy.
    var onEditGroup: (GroupEditorTarget) -> Void = { _ in }
    /// Asks to delete one of the person's groups.
    var onDeleteGroup: (CustomWorldGroup) -> Void = { _ in }
    /// Opens a list with its full map in the Atlas, its places' cards to swipe through.
    var onOpenAtlas: (String) -> Void = { _ in }
    @Environment(\.visitLadder) private var ladder
    @Environment(CustomWorldGroups.self) private var customGroups
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The titles of the sections folded away, one per line. Groups of countries start folded.
    @AppStorage("sidebarCollapsedSections") private var collapsedSections = CollectionSection.worldGroupsTitle
    /// The IDs of the lists pinned under the World, one per line, in the order they were pinned.
    @AppStorage("sidebarPinnedLists") private var pinnedLists = "JP"
    /// Groups of countries kept out of the sidebar, chosen in Settings or from a group's menu.
    @AppStorage(HiddenWorldGroups.storageKey) private var hiddenGroups = HiddenWorldGroups()
    /// Whether the hidden groups show for now, at the end of World Groups.
    @State private var showsHiddenGroups = false
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

    /// Places matching the search, leaving out countries whose own list is already found, such as
    /// Japan, so each shows once, as the list.
    private func placeResults(besides lists: [Country]) -> [PlaceSearch.Result] {
        let listIDs = Set(lists.map(\.id))
        return PlaceSearch.results(for: searchText, in: CountryCatalog.countries(applying: rules)).filter { result in
            !(result.collection.id == CountryCatalog.world.id && listIDs.contains(result.place.abbreviation))
        }
    }

    var body: some View {
        let snapshot = saveModel?.snapshot()
        let isSearching = !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        // Each worked out once per pass.
        let results = isSearching ? searchResults : []
        let places = isSearching ? placeResults(besides: results) : []
        ScrollViewReader { scroller in
            List(selection: Binding<String?>(get: { selectedCountryID }, set: { if let value = $0 { selectedCountryID = value } })) {
                if isSearching {
                    if !results.isEmpty {
                        Section {
                            rows(for: results, snapshot: snapshot)
                        } header: {
                            Text("^[\(results.count) list](inflect: true)")
                        }
                    }
                    if !places.isEmpty {
                        Section {
                            ForEach(places) { result in
                                Button {
                                    onOpenPlace(result.place.id, result.collection.id)
                                } label: {
                                    PlaceSearchRow(result: result, status: snapshot?.status(for: result.place) ?? .never, query: searchText)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text("^[\(places.count) place](inflect: true)")
                        }
                    }
                } else {
                    ForEach(sections) { section in
                        if let title = section.title {
                            let lists = sidebarLists(in: section)
                            // Every titled section folds away under its header, and stays as it was left.
                            Section(isExpanded: isExpanded(title)) {
                                rows(for: lists.shown, snapshot: snapshot)
                                // Groups hidden from the sidebar wait at the end, faded while they show.
                                if !lists.hidden.isEmpty {
                                    if showsHiddenGroups {
                                        rows(for: lists.hidden, snapshot: snapshot)
                                            .opacity(0.55)
                                    }
                                    ShowHiddenRow(count: lists.hidden.count, isShowing: showsHiddenGroups) {
                                        withAnimation(.smooth) { showsHiddenGroups.toggle() }
                                    }
                                }
                                // Groups of countries end with a way to make one of your own.
                                if title == CollectionSection.worldGroupsTitle {
                                    NewGroupRow { onEditGroup(.new) }
                                }
                            } header: {
                                SectionHeader(
                                    title: title, lists: showsHiddenGroups ? section.countries : lists.shown,
                                    snapshot: snapshot, rules: rules)
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
            .searchable(text: $searchText, placement: .sidebar, prompt: "Search lists and places")
            .overlay {
                // Fades in and out as the search finds nothing or something again, rather than
                // blinking, without the list's own rows being animated along with it.
                let findsNothing = isSearching && results.isEmpty && places.isEmpty
                ZStack {
                    if findsNothing {
                        ContentUnavailableView.search(text: searchText)
                            .transition(.opacity)
                    }
                }
                .animation(Motion.leave, value: findsNothing)
            }
            .animation(.smooth, value: pinnedLists)
            .sensoryFeedback(.selection, trigger: selectedCountryID)
            .sensoryFeedback(.impact(weight: .light), trigger: pinnedLists)
            // The open list is always in sight: when the sidebar appears, and when a list is opened
            // from elsewhere, such as a country tapped on the World map.
            .onAppear { scroller.scrollTo(rowID(selectedCountryID), anchor: .center) }
            .onChange(of: selectedCountryID) { _, id in
                // With Reduce Motion the row is simply there, rather than gliding into view.
                withAnimation(Motion.travelling(Motion.glide, reduceMotion: reduceMotion)) { scroller.scrollTo(rowID(id)) }
            }
            // A group just made opens in its list, so its section unfolds to show it.
            .onChange(of: customGroups.groups.count) { old, new in
                if new > old { isExpanded(CollectionSection.worldGroupsTitle).wrappedValue = true }
            }
        }
    }

    /// A section's lists, split into those it shows and the groups of countries hidden from it.
    private func sidebarLists(in section: CollectionSection) -> (shown: [Country], hidden: [Country]) {
        guard section.title == CollectionSection.worldGroupsTitle else { return (section.countries, []) }
        return hiddenGroups.split(section.countries)
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
            let ownGroup = customGroups.group(collectionID: country.id)
            NavigationLink(value: country.id) {
                CountrySidebarRow(
                    country: country,
                    emblem: customGroups.emblem(for: country),
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
                // Any list with a map can open straight into the Atlas, its places' cards to browse.
                OpenInAtlasItem(collectionID: country.id) { onOpenAtlas(country.id) }
                if canPin {
                    Button(pinned ? "Unpin" : "Pin", systemImage: pinned ? "pin.slash" : "pin") {
                        togglePin(country.id)
                    }
                }
                // Any group can be kept out of the sidebar, still there at the end under Show Hidden.
                if country.isGroupOfCountries {
                    let isHidden = hiddenGroups.isHidden(country.id)
                    Button(isHidden ? "Unhide" : "Hide", systemImage: isHidden ? "eye" : "eye.slash") {
                        withAnimation(.smooth) { hiddenGroups.setHidden(!isHidden, for: country.id) }
                    }
                }
                // A group of the person's own can be changed; any group can start a new one.
                if let ownGroup {
                    Button("Edit group", systemImage: "pencil") { onEditGroup(.edit(ownGroup.id)) }
                }
                if country.isGroupOfCountries {
                    Button("Duplicate", systemImage: "plus.square.on.square") { onEditGroup(.copy(of: country.id)) }
                }
                if let ownGroup {
                    Button("Delete group", systemImage: "trash", role: .destructive) { onDeleteGroup(ownGroup) }
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
            .swipeActions(edge: .trailing) {
                if let ownGroup {
                    // Asks first, so not a destructive role, which would take the row away at once.
                    Button("Delete", systemImage: "trash") { onDeleteGroup(ownGroup) }
                        .tint(.red)
                }
            }
        }
    }
}

/// A place found by search: its flag, its name and where it is, with its level.
private struct PlaceSearchRow: View {
    var result: PlaceSearch.Result
    var status: VisitLevel
    /// What was typed, to set in bold where it matches the name.
    var query: String
    @ScaledMetric(relativeTo: .body) private var badgeHeight = 17

    var body: some View {
        HStack(spacing: 10) {
            FlagThumbnail(name: result.place.flagAssetName, size: CGSize(width: badgeHeight * 1.5, height: badgeHeight))
                .frame(width: badgeHeight * 1.5, height: badgeHeight)
                .clipShape(.rect(cornerRadius: 3))
                .overlay {
                    RoundedRectangle(cornerRadius: 3).strokeBorder(.quaternary, lineWidth: 0.5)
                }
                .grayscale(status == .never ? 1 : 0)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                // Long names and addresses glide to their end and back, never cut short, with
                // what was typed in bold, as in Learn's search.
                ScrollingText {
                    Text(LearnSearch.emphasised(result.place.name, matching: query))
                }
                ScrollingText {
                    Text(result.locationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 8)
            VisitPillLabel(status: status, isSmall: true)
                .fixedSize()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(result.place.name), \(result.locationName)")
        .accessibilityValue(status.name)
        .accessibilityHint("Opens it in its list.")
        .accessibilityAddTraits(.isButton)
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
            ScrollingName(text: title)
            Spacer(minLength: 8)
            Text("\(started)/\(lists.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(started)))
                .fixedSize()
                .layoutPriority(1)
        }
        .animation(Motion.count, value: started)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(started) of \(lists.count) lists started")
    }
}

/// One list in the sidebar, on a single line: its flag, its name and how many of its places count,
/// with a hairline of its levels beneath. A list that's complete wears a seal in its strongest colour.
private struct CountrySidebarRow: View {
    var country: Country
    /// The badge of a group of countries, the World's or the person's own, in place of a flag.
    var emblem: GroupEmblem?
    var counted: Int
    var strongestStatus: VisitLevel
    var tally: [String: Int]
    var minimumStatus: VisitLevel
    /// The list open now.
    var isSelected = false
    @Environment(\.visitLadder) private var ladder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                        .strokeBorder(.quaternary, lineWidth: country.flagAssetName == nil && emblem?.flag == nil ? 0 : 0.5)
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
                            // Springs in the moment the last place counts; with Reduce Motion, fades in.
                            .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.symbolEffect(.appear.byLayer)))
                    }
                    // Always whole: the name gives way to it, never the other way round. It pops as
                    // a place comes to count, never as one stops counting, as after an undo.
                    Text("\(counted)/\(total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(counted)))
                        .fixedSize()
                        .layoutPriority(1)
                        .pop(onRiseOf: counted)
                }
                StatusTallyBar(tally: tally, total: total, minimumStatus: minimumStatus, showsStripes: false)
                    .frame(height: 2.5)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(country.name)
        .accessibilityValue("\(counted) of \(total). \(StatusTallyBar.breakdown(of: tally, in: ladder))")
        .animation(Motion.count, value: counted)
        .animation(Motion.recolour, value: strongestStatus)
    }

    @ViewBuilder private var badge: some View {
        if let flag = country.flagAssetName {
            // Scaled down once to the badge's size, rather than the whole flag decoded for each row.
            FlagThumbnail(name: flag, size: CGSize(width: badgeHeight * 1.5, height: badgeHeight))
        } else if let emblem {
            WorldGroupBadge(emblem: emblem)
        } else {
            TurningGlobe()
                .foregroundStyle(strongestStatus == .never ? AnyShapeStyle(.secondary) : AnyShapeStyle(strongestStatus.color))
        }
    }
}

/// The last row among the World Groups, to make a group of your own: a dashed tile with a plus
/// where a badge would be.
private struct NewGroupRow: View {
    var action: () -> Void
    @ScaledMetric(relativeTo: .body) private var badgeHeight = 17

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [2.5, 2]))
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(width: badgeHeight * 1.5, height: badgeHeight)
                    .accessibilityHidden(true)
                ScrollingName(text: "New group")
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Makes a group of countries of your own.")
    }
}

/// The row after the World Groups while some are hidden, just above New Group: Show Hidden brings
/// them in, faded, above it, and Hide Hidden puts them away again.
private struct ShowHiddenRow: View {
    var count: Int
    var isShowing: Bool
    var action: () -> Void
    @ScaledMetric(relativeTo: .body) private var badgeHeight = 17

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isShowing ? "eye.slash" : "eye")
                    .font(.system(size: 13, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: badgeHeight * 1.5, height: badgeHeight)
                    .accessibilityHidden(true)
                ScrollingName(text: isShowing ? "Hide hidden" : "Show hidden")
                Spacer(minLength: 0)
                Text(count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .contentTransition(.numericText(value: Double(count)))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isShowing)
        .accessibilityValue("^[\(count) group](inflect: true) hidden")
    }
}

/// The World's badge: a globe that now and then turns to show another side of the Earth,
/// starting from the side the World map is centred on.
private struct TurningGlobe: View {
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
    @State private var turns = 0

    /// Faces of the Earth from west to east, so each turn follows the Earth's spin.
    private static let faces = MapCenter.allCases.sorted { $0.eastwardOrder < $1.eastwardOrder }

    var body: some View {
        let start = Self.faces.firstIndex(of: center) ?? 0
        let face = Self.faces[(start + turns) % Self.faces.count]
        Image(systemName: face.globeSymbolName)
            .font(.system(size: 15))
            .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer)))
            // Turns now and then only while decoration may move: not in Low Power Mode, with Reduce
            // Motion, or while the app isn't in front.
            .task(id: allowsAmbientMotion) {
                guard allowsAmbientMotion else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(.random(in: 6...11)))
                    guard !Task.isCancelled else { return }
                    withAnimation(.smooth) { turns += 1 }
                }
            }
            .onChange(of: center) { turns = 0 }
    }
}

/// "Open in Atlas" in a sidebar row's menu, for a list with a map to open it on. Its own view, so
/// whether there's a map is only looked up, and the map decoded, once the menu is shown, rather
/// than for every row in the sidebar.
private struct OpenInAtlasItem: View {
    var collectionID: String
    var action: () -> Void

    var body: some View {
        if TravelMap.named(collectionID) != nil {
            Button("Open in Atlas", systemImage: "book.fill", action: action)
        }
    }
}
