import SwiftUI

/// Learn's search: every place in play, listed by region with the one shown ticked, and a search
/// field that finds places by anything their cards show, such as a capital, a calling code or a
/// currency. Rows come and go as you type, the part that matched in bold; where a place is found by
/// something other than its name, its row says what, such as +81 beside Japan, labelled Phone. The
/// best match is lit as the one Return picks. Picking a place closes the sheet and brings its card round.
struct LearnSearchSheet: View {
    var deck: LearnDeck
    var localLanguage: Bool
    var onPick: (LearnSearch.Result) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Built once as the sheet opens, rather than each time the screen behind it changes.
    @State private var search: LearnSearch?
    @State private var query = ""
    @State private var isSearching = false

    private var isQuerying: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether rows keep room for a flag: where any place has one of its own.
    private var showsFlags: Bool {
        deck.showsFlags
    }

    var body: some View {
        let results = isQuerying ? search?.results(for: query) ?? [] : []
        NavigationStack {
            ScrollViewReader { scroller in
                List {
                    if isQuerying {
                        if !results.isEmpty {
                            Section {
                                rows(for: results, topID: results.first?.id)
                            } header: {
                                Text("^[\(results.count) place](inflect: true)")
                                    .contentTransition(.numericText(value: Double(results.count)))
                            }
                        }
                    } else {
                        ForEach(search?.regions ?? []) { region in
                            Section {
                                rows(for: region.places, topID: nil)
                            } header: {
                                if let name = region.name { ScrollingName(text: name) }
                            }
                        }
                    }
                }
                // Rows slide in and out as the search narrows and widens, rather than jumping, or
                // with Reduce Motion ease there in a moment.
                .animation(Motion.moving(.snappy(duration: 0.3), reduceMotion: reduceMotion), value: results.map(\.id))
                .animation(.smooth(duration: 0.3), value: isQuerying)
                .scrollDismissesKeyboard(.immediately)
                .overlay {
                    if isQuerying, results.isEmpty, search != nil {
                        ContentUnavailableView.search(text: query)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .animation(.smooth(duration: 0.25), value: isQuerying && results.isEmpty)
                .onChange(of: search == nil) {
                    // The place shown, in the middle of the list as it opens, once its rows are in.
                    guard let id = deck.current?.id else { return }
                    Task { scroller.scrollTo(id, anchor: .center) }
                }
            }
            .navigationTitle("Find a place")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, isPresented: $isSearching, prompt: "Name, capital or code")
            // Return takes the best match.
            .onSubmit(of: .search) {
                if let first = results.first { pick(first) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Escape closes it, as it does any sheet.
                    Button("Close", systemImage: "xmark") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
        .tint(MapGame.learnColor)
        .onAppear {
            search = LearnSearch(deck: deck, localLanguage: localLanguage)
            isSearching = true
        }
    }

    private func rows(for results: [LearnSearch.Result], topID: String?) -> some View {
        ForEach(results) { result in
            Button {
                pick(result)
            } label: {
                LearnSearchRow(
                    result: result, query: isQuerying ? query : "", localLanguage: localLanguage,
                    flag: deck.flag(of: result.place), showsFlags: showsFlags,
                    region: deck.regionName(of: result.place, localLanguage: localLanguage),
                    isShown: result.place.id == deck.current?.id)
                    .foregroundStyle(.primary)
            }
            // The best match, lit softly as Spotlight lights its top hit.
            .listRowBackground(result.id == topID ? MapGame.learnColor.opacity(0.12) : nil)
            .accessibilityHint(result.id == topID ? "Shows it in the Atlas. Return also chooses it." : "Shows it in the Atlas.")
        }
    }

    private func pick(_ result: LearnSearch.Result) {
        onPick(result)
        dismiss()
    }
}

/// A place in Learn's search: its flag, its name, and beneath, its region, or the other name it
/// was found by; at the end, the capital or code it was found by, labelled with its kind. Whatever
/// the search matched is in bold.
private struct LearnSearchRow: View {
    var result: LearnSearch.Result
    /// The search, for the part to set in bold; empty when listing every place.
    var query: String
    var localLanguage: Bool
    var flag: String?
    var showsFlags: Bool
    var region: String?
    /// Whether it's the place Learn is showing.
    var isShown: Bool
    @ScaledMetric(relativeTo: .body) private var flagHeight = 17
    /// The widest the capital or code at the row's end grows before it glides, so a long one, such
    /// as Sri Jayawardenepura Kotte, leaves the name its room on a narrow sheet.
    @ScaledMetric(relativeTo: .body) private var detailMaxWidth = 160
    /// The capital or code's own width, unclipped, measured so it takes no more than it needs.
    @State private var detailWidth: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let place = result.place
        let name = place.displayName(localLanguage: localLanguage)
        HStack(spacing: 10) {
            if showsFlags {
                Group {
                    if let flag {
                        FlagThumbnail(name: flag, size: CGSize(width: flagHeight * 1.5, height: flagHeight))
                            .clipShape(.rect(cornerRadius: 3))
                            .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(.quaternary, lineWidth: 0.5) }
                    }
                }
                .frame(width: flagHeight * 1.5, height: flagHeight)
                .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 1) {
                // Long names glide to their end and back, never cut short.
                ScrollingText {
                    Text(emphasised(name, if: result.match == .name))
                        .placeName(place.language(of: name))
                }
                if let subtitle {
                    ScrollingText {
                        Text(emphasised(subtitle, if: result.match != .name && !result.match.isCode))
                            .placeName(place.language(of: subtitle))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                // At the largest text sizes there's no room beside the name, so it goes beneath.
                if let detail, typeSize.isAccessibilitySize {
                    detailView(detail, alignment: .leading)
                        .padding(.top, 2)
                }
            }
            // The name keeps its room first; the detail beside it takes only what's left.
            .layoutPriority(1)
            Spacer(minLength: 8)
            if let detail, !typeSize.isAccessibilitySize {
                detailView(detail, alignment: .trailing)
                    .frame(width: min(detailWidth, detailMaxWidth), alignment: .trailing)
                    // Measured at its own width, whatever room the row gives it.
                    .background {
                        detailView(detail, alignment: .trailing, glides: false)
                            .fixedSize()
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { detailWidth = ceil($0) }
                    }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.85, anchor: .trailing)))
            }
            if isShown {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([name, subtitle].compactMap { $0 }.joined(separator: ", "))
        .accessibilityValue(detail.map { "\($0.label) \($0.spokenValue)" } ?? "")
        .accessibilityAddTraits(isShown ? .isSelected : [])
    }

    /// The capital or code the place was found by, with its kind beneath, each gliding if it runs
    /// past the room it's given. `glides` false sets it plainly, for measuring its own width.
    @ViewBuilder private func detailView(_ detail: Detail, alignment: HorizontalAlignment, glides: Bool = true) -> some View {
        let value = Text(LearnSearch.emphasised(detail.value, matching: query, isCode: result.match.isCode))
            .monospacedDigit()
            .typesettingLanguage(Locale.Language(identifier: "zh-Hans"), isEnabled: detail.isChinese)
        let label = Label(detail.label, systemImage: detail.symbol)
            .font(.caption)
            .foregroundStyle(.secondary)
            .labelStyle(DetailLabelStyle(tint: detail.tint))
        VStack(alignment: alignment, spacing: 1) {
            if glides {
                ScrollingText { value }
                ScrollingText { label }
            } else {
                value.lineLimit(1)
                label.lineLimit(1)
            }
        }
    }

    /// Text with what the search matched in bold, where this is what it matched.
    private func emphasised(_ text: String, if isMatch: Bool) -> AttributedString {
        isMatch ? LearnSearch.emphasised(text, matching: query) : AttributedString(text)
    }

    /// Beneath the name: the other name it was found by, or else its region.
    private var subtitle: String? {
        if case .otherName(let other) = result.match { return other }
        return region
    }

    /// At the end of the row: the capital or code it was found by.
    private var detail: Detail? {
        switch result.match {
        case .capital(let city):
            Detail(value: city, spokenValue: city, label: "Capital", symbol: "building.columns", tint: MapGame.learnColor)
        case .code(let kind, let code):
            Detail(
                value: kind.listed(code), spokenValue: CodeBadge.spoken(code), label: kind.learnName,
                symbol: kind.symbolName, tint: kind.tint, isChinese: kind == .shortName)
        case .name, .otherName, .region:
            nil
        }
    }

    private struct Detail {
        var value: String
        var spokenValue: String
        var label: String
        var symbol: String
        var tint: Color
        var isChinese = false
    }
}

/// A detail's kind, its symbol in the kind's own colour before its name.
private struct DetailLabelStyle: LabelStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .foregroundStyle(tint)
            configuration.title
        }
    }
}
