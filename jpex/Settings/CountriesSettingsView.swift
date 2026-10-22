import SwiftUI

/// What World counts as a country, as boards of places to tap in and out. Every place lights up
/// when it counts, the total at the top rolls with each change, and a whole board can be
/// switched at once, its places lighting up one after another.
struct CountriesSettingsView: View {
  @Environment(CountingPreferences.self) private var counting
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @ScaledMetric(relativeTo: .subheadline) private var cardWidth = 150
  /// The board just switched as a whole, so its places light up in a cascade rather than at once.
  @State private var cascading: String?
  @State private var isNamingPreset = false
  @State private var presetName = ""
  /// The person's own unsaved mix from earlier on this screen, so they can try a standard or a
  /// preset and still switch back to it.
  @State private var unsavedMix: CountingRules?

  var body: some View {
    let count = CountryCatalog.world(applying: counting.rules).divisions.count
    Form {
      Section {
        WorldCountRow(count: count)
      }
      countBySection
      statesSection
      unitedKingdomSection
      board(
        "outside", title: "States outside the UN", groups: [.observers, .partlyRecognised, .taiwan, .associatedStates, .deFactoStates],
        systemImage: "flag.2.crossed.fill", tint: .purple)
      board(
        "special", title: "Special administrative regions", groups: [.specialRegions],
        systemImage: "building.2.fill", tint: .red)
      board("territories", title: "Territories", groups: [.territories], systemImage: "flag.fill", tint: .orange)
      board(
        "remote", title: "Antarctica & remote islands", groups: [.remotePlaces], systemImage: "snowflake", tint: .cyan)
      continentsSection
    }
    .navigationTitle("Countries")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: cascading) {
      guard cascading != nil else { return }
      try? await Task.sleep(for: .seconds(1))
      cascading = nil
    }
    .onChange(of: counting.rules) { mix, _ in
      if isUnsaved(mix) { unsavedMix = mix }
    }
    .alert("Save preset", isPresented: $isNamingPreset) {
      TextField("Name", text: $presetName)
      Button("Save") {
        let name = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation(.snappy) { counting.savePreset(named: name) }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Save these choices to use again.")
    }
  }

  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: cardWidth), spacing: 8)]
  }

  // MARK: Count by

  /// The standards and the person's own presets, with a card to save the current mix.
  private var countBySection: some View {
    let standard = counting.rules.standard
    let preset = counting.matchingPreset
    let current = standard?.name ?? preset?.name ?? "Custom"
    return Section {
      VStack(alignment: .leading, spacing: 12) {
        BoardHeader(
          title: "Count by", subtitle: ScrollingText { Text(current).contentTransition(.interpolate) },
          systemImage: "slider.horizontal.3", tint: .teal, trigger: current
        ) {
          if standard == nil && preset == nil {
            Button("Save") {
              presetName = ""
              isNamingPreset = true
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(.teal)
            .transition(.arrive(reduceMotion: reduceMotion))
            .accessibilityLabel("Save as preset")
          }
        }
        .animation(.snappy, value: standard == nil && preset == nil)
        LazyVGrid(columns: columns, spacing: 8) {
          ForEach(CountingStandard.allCases) { choice in
            let applied = choice.applied(to: counting.rules)
            ToggleCard(
              title: choice.name, subtitle: "\(CountryCatalog.world(applying: applied).divisions.count) countries",
              tint: .teal, isOn: choice == standard
            ) {
              SymbolMark(systemImage: choice.symbolName, tint: .teal, isOn: choice == standard)
            } action: {
              apply(applied)
            }
            .accessibilityHint(choice.detail)
          }
          ForEach(counting.presets) { saved in
            let applied = saved.applied(to: counting.rules)
            ToggleCard(
              title: saved.name, subtitle: "\(CountryCatalog.world(applying: applied).divisions.count) countries",
              tint: .teal, isOn: saved.id == preset?.id
            ) {
              SymbolMark(systemImage: "star.fill", tint: .teal, isOn: saved.id == preset?.id)
            } action: {
              apply(applied)
            }
            .contextMenu {
              Button("Delete preset", systemImage: "trash", role: .destructive) {
                withAnimation(.snappy) { counting.presets.removeAll { $0.id == saved.id } }
              }
            }
            .transition(reduceMotion ? .opacity : .scale(scale: 0.8).combined(with: .opacity))
          }
          // The current mix when it isn't one of the above, always in its place so the page holds
          // still. Faded until it's saved; tap it to save it, or to go back to it after trying
          // another way of counting.
          let isCustom = standard == nil && preset == nil
          let earlier = isCustom ? nil : earlierMix
          ToggleCard(
            title: "Custom",
            subtitle: (isCustom ? counting.rules : earlier).map {
              "\(CountryCatalog.world(applying: $0).divisions.count) countries"
            } ?? "Your own choices",
            tint: .teal, isOn: isCustom
          ) {
            SymbolMark(systemImage: "slider.horizontal.3", tint: .teal, isOn: isCustom)
          } action: {
            if let earlier {
              apply(earlier)
            } else {
              presetName = ""
              isNamingPreset = true
            }
          }
          .opacity(0.55)
          .disabled(!isCustom && earlier == nil)
          .accessibilityHint(
            isCustom ? "Saves these choices as a preset." : earlier == nil ? "" : "Goes back to your unsaved choices.")
        }
      }
      .padding(.vertical, 6)
    }
  }

  private func apply(_ rules: CountingRules) {
    cascading = "all"
    withAnimation(.snappy) { counting.rules = rules }
  }

  /// Whether a mix is the person's own: neither a standard nor one of their presets.
  private func isUnsaved(_ rules: CountingRules) -> Bool {
    rules.standard == nil && !counting.presets.contains { $0.applied(to: rules) == rules }
  }

  /// The unsaved mix to switch back to, at the level counted from now, unless it's since been
  /// saved as a preset.
  private var earlierMix: CountingRules? {
    guard var mix = unsavedMix else { return nil }
    mix.minimumLevelID = counting.rules.minimumLevelID
    return isUnsaved(mix) ? mix : nil
  }

  // MARK: United Kingdom

  private var unitedKingdomSection: some View {
    let isSplit = counting.rules.splitsUnitedKingdom
    let union = CountryCatalog.world.divisions.first { $0.abbreviation == "GB" }
    return Section {
      VStack(alignment: .leading, spacing: 12) {
        BoardHeader(
          title: "United Kingdom", subtitle: Text(isSplit ? "Counted as four countries" : "Counted as one country"),
          systemImage: "crown.fill", tint: .indigo, trigger: isSplit
        ) {
          EmptyView()
        }
        // One card per line, so each has room for its whole description.
        VStack(spacing: 8) {
          ToggleCard(title: "One country", subtitle: "United Kingdom", tint: .indigo, isOn: !isSplit) {
            if let union { FlagMark(assetName: union.flagAssetName, isOn: !isSplit) }
          } action: {
            setSplit(false)
          }
          ToggleCard(
            title: "Four countries", subtitle: "England, Scotland, Wales, Northern Ireland", tint: .indigo, isOn: isSplit
          ) {
            // The four flags in a little square, the size of one flag.
            let nations = CountryCatalog.unitedKingdom.divisions
            Grid(horizontalSpacing: 1.5, verticalSpacing: 1.5) {
              ForEach(0..<2, id: \.self) { row in
                GridRow {
                  ForEach(nations.dropFirst(row * 2).prefix(2)) { nation in
                    Image(nation.flagAssetName)
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                      .frame(width: 14, height: 9)
                      .clipShape(.rect(cornerRadius: 1.5))
                  }
                }
              }
            }
            .frame(width: 30, height: 20)
            .saturation(isSplit ? 1 : 0.15)
            .opacity(isSplit ? 1 : 0.6)
          } action: {
            setSplit(true)
          }
        }
      }
      .padding(.vertical, 6)
    }
  }

  /// The way into showing or hiding the countries World always counts, such as UN members, with
  /// how many are hidden.
  private var statesSection: some View {
    let hidden = counting.rules.hiddenStates.count
    return Section {
      NavigationLink {
        StatesVisibilityView()
      } label: {
        SettingsLabel(
          "Show/hide states", systemImage: "eye.slash.fill", fill: Color.gray.gradient, trigger: hidden
        ) {
          Text(hidden == 0 ? "All shown" : hidden == 1 ? "1 hidden" : "\(hidden) hidden")
            .contentTransition(.numericText(value: Double(hidden)))
        }
      }
    }
  }

  private func setSplit(_ isSplit: Bool) {
    withAnimation(.bouncy) { counting.rules.splitsUnitedKingdom = isSplit }
  }

  // MARK: Places

  /// A set of places as cards, under a heading with how many count and a button for all or none.
  private func board(
    _ id: String, title: LocalizedStringKey, groups: [OptionalPlaceGroup], systemImage: String, tint: Color
  ) -> some View {
    let places = groups.flatMap { CountryCatalog.places(in: $0) }
    let included = places.count { counting.rules.includesWorldPlace(code: $0.abbreviation) }
    let isCascading = cascading == id || cascading == "all"
    let all = included == places.count
    return Section {
      VStack(alignment: .leading, spacing: 12) {
        BoardHeader(
          title: title,
          subtitle: Text("\(included) of \(places.count) counted")
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(included))),
          systemImage: systemImage, tint: tint, trigger: included
        ) {
          Button(all ? "None" : "All") {
            cascading = id
            withAnimation(.snappy) {
              for group in groups { counting.rules.setIncludes(group, !all) }
            }
          }
          .font(.subheadline.weight(.semibold))
          .buttonStyle(.bordered)
          .buttonBorderShape(.capsule)
          .tint(tint)
          .accessibilityLabel(all ? "Count none of \(Text(title))" : "Count all of \(Text(title))")
        }
        LazyVGrid(columns: columns, spacing: 8) {
          ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
            let isOn = counting.rules.includesWorldPlace(code: place.abbreviation)
            ToggleCard(
              title: place.name, subtitle: Self.owner(of: place), tint: tint, isOn: isOn,
              delay: isCascading ? min(Double(index) * 0.018, 0.6) : 0
            ) {
              FlagMark(assetName: place.flagAssetName, isOn: isOn)
            } action: {
              // Tapped by hand, it answers at once, even mid-cascade.
              cascading = nil
              withAnimation(.snappy) { counting.rules.setIncludes(code: place.abbreviation, !isOn) }
            }
            .accessibilityLabel(Self.ownerName(of: place).map { "\(place.name), \($0)" } ?? place.name)
            .accessibilityValue(isOn ? "Counted" : "Not counted")
          }
        }
      }
      .padding(.vertical, 6)
    }
  }

  /// A short code for the country a place belongs to, left out for Taiwan, Hong Kong and Macau,
  /// whose relationship with China is the very question these cards decide, and likewise for
  /// Northern Cyprus and Cyprus.
  private static func owner(of place: AdministrativeDivision) -> String? {
    switch CountryCatalog.optionalPlaceGroup(code: place.abbreviation) {
    case .taiwan, .specialRegions, .deFactoStates: nil
    default: CountryCatalog.sovereignShortCode(of: place.abbreviation)
    }
  }

  /// The owner in full, for VoiceOver.
  private static func ownerName(of place: AdministrativeDivision) -> String? {
    owner(of: place) == nil ? nil : CountryCatalog.sovereignName(of: place.abbreviation)
  }

  // MARK: Continents

  /// Countries that span two continents, each with a card for either continent.
  private var continentsSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 14) {
        BoardHeader(
          title: "Continents", subtitle: Text("Choose which continent a transcontinental country belongs to"),
          systemImage: "globe.europe.africa.fill", tint: .blue, trigger: counting.rules.continentChoices
        ) {
          EmptyView()
        }
        // A line per country: its flag and name, then a card for each continent.
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          ForEach(CountryCatalog.transcontinentalPlaces, id: \.code) { place in
            if let country = CountryCatalog.world.divisions.first(where: { $0.abbreviation == place.code }) {
              let choice = counting.rules.continentChoices[place.code] ?? place.continents[0]
              GridRow {
                HStack(spacing: 8) {
                  FlagMark(assetName: country.flagAssetName, isOn: true)
                    .frame(width: 24, height: 16)
                  ScrollingName(text: country.name)
                    .font(.subheadline.weight(.semibold))
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                ForEach(place.continents, id: \.self) { continent in
                  let tint = Self.color(of: continent)
                  ToggleCard(
                    title: Self.name(of: continent), subtitle: nil, tint: tint, isOn: choice == continent,
                    isCompact: true
                  ) {
                    SymbolMark(systemImage: Self.globe(of: continent), tint: tint, isOn: choice == continent)
                  } action: {
                    withAnimation(.bouncy) {
                      counting.rules.continentChoices[place.code] = continent == place.continents[0] ? nil : continent
                    }
                  }
                }
              }
            }
          }
        }
      }
      .padding(.vertical, 6)
    }
  }

  private static func name(of continent: String) -> String {
    CountryCatalog.world.groups.first { $0.id == "WORLD-\(continent)" }?.name ?? continent.capitalized
  }

  static func color(of continent: String) -> Color {
    switch continent {
    case "europe": .blue
    case "asia": .red
    case "africa": .orange
    case "oceania": .teal
    default: .green
    }
  }

  static func globe(of continent: String) -> String {
    switch continent {
    case "europe", "africa": "globe.europe.africa.fill"
    case "asia": "globe.central.south.asia.fill"
    case "oceania": "globe.asia.australia.fill"
    default: "globe.americas.fill"
    }
  }
}

/// A section's heading inside its card: an icon tile, a title with a line beneath, and room
/// for a button at the end.
struct BoardHeader<Subtitle: View, Trailing: View>: View {
  var title: LocalizedStringKey
  var subtitle: Subtitle
  var systemImage: String
  var tint: Color
  var trigger: AnyHashable
  @ViewBuilder var trailing: Trailing

  var body: some View {
    HStack(spacing: 12) {
      SettingsIcon(systemImage: systemImage, fill: AnyShapeStyle(tint.gradient), trigger: trigger)
      VStack(alignment: .leading, spacing: 2) {
        // On one line, a long heading, as Special administrative regions, gliding to show the rest.
        ScrollingText {
          Text(title)
            .font(.headline)
        }
        .accessibilityAddTraits(.isHeader)
        subtitle
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 8)
      trailing
    }
  }
}

/// A small card that lights up in its board's colour while it's on and greys out while it's off,
/// with a mark such as a flag at the front and a tick at the end. Every card keeps room for two
/// lines so cards in a row stay the same height; a title without a subtitle sits in the middle.
struct ToggleCard<Leading: View>: View {
  var title: String
  var subtitle: String?
  var tint: Color
  var isOn: Bool
  /// How long to wait before lighting up, so a whole board lights up one card after another.
  var delay: Double = 0
  /// A slimmer card for one-word choices: no tick, and only one line's height.
  var isCompact = false
  /// Counts each time what the card stands for is made or changed elsewhere, such as a group
  /// saved in its editor, for the card to pop as its page comes back.
  var arrivals = 0
  @ViewBuilder var leading: Leading
  var action: () -> Void
  @State private var pops = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @ScaledMetric(relativeTo: .subheadline) private var textHeight = 36

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
    Button {
      pops += 1
      action()
    } label: {
      HStack(spacing: 10) {
        leading
          .scaleEffect(isOn && !reduceMotion ? 1.06 : 1)
        VStack(alignment: .leading, spacing: 1) {
          ScrollingName(text: title, trigger: pops)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isOn ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
          if let subtitle {
            ScrollingName(text: subtitle, trigger: pops)
              .font(.caption.weight(.medium))
              .foregroundStyle(.secondary)
          }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: isCompact ? nil : textHeight, alignment: .leading)
        if !isCompact {
          Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
            .font(.body)
            .foregroundStyle(isOn ? AnyShapeStyle(tint) : AnyShapeStyle(.quaternary))
            .contentTransition(.symbolEffect(.replace))
        }
      }
      .padding(.horizontal, isCompact ? 8 : 10)
      .padding(.vertical, 9)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isOn ? AnyShapeStyle(tint.opacity(0.14)) : AnyShapeStyle(.fill.quaternary), in: shape)
      .overlay {
        shape.strokeBorder(isOn ? AnyShapeStyle(tint.opacity(0.6)) : AnyShapeStyle(.clear), lineWidth: 1.5)
      }
      .animation(
        reduceMotion ? .easeInOut(duration: 0.2) : .bouncy(duration: 0.4, extraBounce: 0.12).delay(delay), value: isOn)
      .pop(on: pops + arrivals)
      .contentShape(shape)
    }
    .buttonStyle(PillButtonStyle())
    .sensoryFeedback(.selection, trigger: pops)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
    .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
  }
}

/// A flag at the front of a card, greyed out while the card is off.
struct FlagMark: View {
  var assetName: String
  var isOn: Bool

  var body: some View {
    Image(assetName)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .frame(width: 30, height: 20)
      .clipShape(.rect(cornerRadius: 3.5))
      .overlay { RoundedRectangle(cornerRadius: 3.5).strokeBorder(.quaternary, lineWidth: 0.5) }
      .saturation(isOn ? 1 : 0.15)
      .opacity(isOn ? 1 : 0.6)
  }
}

/// A symbol at the front of a card, in the card's colour while it's on, bouncing as the card
/// lights up but not as it goes out.
struct SymbolMark: View {
  var systemImage: String
  var tint: Color
  var isOn: Bool

  var body: some View {
    Image(systemName: systemImage)
      .font(.body.weight(.semibold))
      .foregroundStyle(isOn ? AnyShapeStyle(tint) : AnyShapeStyle(.secondary))
      .bouncesWhenLit(isOn)
      .frame(width: 30, height: 20)
  }
}

