import SwiftUI

/// Every country World always counts, such as the UN's members, by continent, to show or hide. A
/// country hidden is left out of World's list, its totals and its groups, which say how many of
/// their members are hidden, and can't be tapped on the map. The cards carry no flags, so the page
/// reads as a quiet list of names; a whole continent can be shown or hidden at once, its cards
/// lighting up one after another.
struct StatesVisibilityView: View {
    @Environment(CountingPreferences.self) private var counting
    @ScaledMetric(relativeTo: .subheadline) private var cardWidth = 150
    @State private var query = ""
    /// The continent just switched as a whole, so its cards light up in a cascade.
    @State private var cascading: String?

    var body: some View {
        let continents = continents
        let all = continents.flatMap(\.divisions)
        let shown = all.count { !counting.rules.hiddenStates.contains($0.abbreviation) }
        Form {
            if query.isEmpty {
                Section {
                    WorldCountRow(count: shown, noun: "states", caption: "shown")
                }
            }
            ForEach(continents) { continent in
                board(continent)
            }
            if continents.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .navigationTitle("Show/hide states")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search states")
        .task(id: cascading) {
            guard cascading != nil else { return }
            try? await Task.sleep(for: .seconds(1))
            cascading = nil
        }
    }

    /// The countries World always counts, under the continents the person puts them in, the United
    /// Kingdom as one whichever way it's counted, narrowed to those matching the search.
    private var continents: [DivisionGroup] {
        var everyState = counting.rules
        everyState.hiddenStates = []
        everyState.splitsUnitedKingdom = false
        return CountryCatalog.world(applying: everyState).groups.compactMap { group in
            var group = group
            group.divisions = group.divisions.filter { place in
                CountryCatalog.optionalPlaceGroup(code: place.abbreviation) == nil
                    && (query.isEmpty || place.name.localizedStandardContains(query))
            }
            return group.divisions.isEmpty ? nil : group
        }
    }

    /// A continent's states as cards, under a heading with how many show and a button for all or none.
    private func board(_ continent: DivisionGroup) -> some View {
        let key = String(continent.id.dropFirst("WORLD-".count))
        let tint = CountriesSettingsView.color(of: key)
        let codes = continent.divisions.map(\.abbreviation)
        let hidden = counting.rules.hiddenStates
        let shown = codes.count { !hidden.contains($0) }
        let showsAll = shown == codes.count
        let isCascading = cascading == continent.id
        return Section {
            VStack(alignment: .leading, spacing: 12) {
                BoardHeader(
                    title: LocalizedStringKey(continent.name),
                    subtitle: Text("\(shown) of \(codes.count) shown")
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(shown))),
                    systemImage: CountriesSettingsView.globe(of: key), tint: tint, trigger: shown
                ) {
                    Button(showsAll ? "None" : "All") {
                        cascading = continent.id
                        withAnimation(.snappy) {
                            if showsAll {
                                counting.rules.hiddenStates.formUnion(codes)
                            } else {
                                counting.rules.hiddenStates.subtract(codes)
                            }
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(tint)
                    .accessibilityLabel(showsAll ? "Hide all of \(continent.name)" : "Show all of \(continent.name)")
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 8)], spacing: 8) {
                    ForEach(Array(continent.divisions.enumerated()), id: \.element.id) { index, place in
                        let isShown = !hidden.contains(place.abbreviation)
                        ToggleCard(
                            title: place.name, tint: tint, isOn: isShown,
                            delay: isCascading ? min(Double(index) * 0.018, 0.6) : 0
                        ) {
                            EmptyView()
                        } action: {
                            // Tapped by hand, it answers at once, even mid-cascade.
                            cascading = nil
                            withAnimation(.snappy) {
                                if isShown {
                                    counting.rules.hiddenStates.insert(place.abbreviation)
                                } else {
                                    counting.rules.hiddenStates.remove(place.abbreviation)
                                }
                            }
                        }
                        .accessibilityValue(isShown ? "Shown" : "Hidden")
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}
