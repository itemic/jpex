import SwiftUI

struct SettingsView: View {
  /// Nil until the store is ready; levels can be edited once it is.
  var saveModel: SaveModel?
  @AppStorage("localLanguage") private var localLanguage = false
  @AppStorage(MapCard.pinnedKey) private var keepsMapAtTop = false
  @AppStorage(ListOrder.showsMapKey) private var showsMap = true
  @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
  @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
  @Environment(CountingPreferences.self) private var counting
  @AppStorage(LevelPattern.storageKey) private var showsPatterns = true
  @AppStorage(AppIcon.storageKey) private var appIcon = AppIcon.japan
  @AppStorage(MotionPreference.storageKey) private var reducesMotion = false
  @Environment(\.systemReducesMotion) private var systemReducesMotion
  @Environment(\.visitLadder) private var ladder
  @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
  @Environment(\.dismiss) private var dismiss
  @State private var isConfirmingReset = false
  /// Counts choices made here, so this picker's tick plays once, apart from the list's own.
  @State private var countFromPicks = 0
  @State private var resets = 0

  /// The level totals count from, kept by ID so it follows renames.
  private var minimumLevel: Binding<VisitLevel> {
    Binding(
      get: { counting.rules.minimumLevel(in: ladder) },
      set: { level in
        guard level.id != counting.rules.minimumLevelID else { return }
        counting.rules.minimumLevelID = level.id
        countFromPicks += 1
      }
    )
  }

  var body: some View {
    @Bindable var counting = counting
    let minimum = counting.rules.minimumLevel(in: ladder)
    let worldCount = CountryCatalog.world(applying: counting.rules).divisions.count
    NavigationStack {
      Form {
        Section {
          Toggle(isOn: $localLanguage.animation(.smooth)) {
            SettingsLabel(
              "Local names first", systemImage: "character.book.closed.fill", fill: Color.indigo.gradient,
              trigger: localLanguage)
          }
          Toggle(isOn: $showsMap.animation(.smooth)) {
            SettingsLabel("Show Map", systemImage: showsMap ? "eye.fill" : "eye.slash.fill", fill: Color.mint.gradient, trigger: showsMap)
          }
          Toggle(isOn: $keepsMapAtTop.animation(.smooth)) {
            SettingsLabel("Pin map to top", systemImage: "pin.fill", fill: Color.orange.gradient, trigger: keepsMapAtTop)
          }
          .disabled(!showsMap)
        } header: {
          Text("Lists")
        }

        Section {
          // A fixed frame, so changing the projection reshapes the map without moving the page.
          // The map runs past the card's margins to the screen's edges, with the page around it.
          Color.clear
            .aspectRatio(1.9, contentMode: .fit)
            .overlay {
              WorldMapPreview(saveModel: saveModel, projection: projection, center: $center, isActive: showsMap)
                .containerRelativeFrame(.horizontal)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .disabled(!showsMap)
            .opacity(showsMap ? 1 : 0.4)
            .animation(.smooth, value: showsMap)
            .accessibilityHidden(true)
        } header: {
          Text("World Map")
        }

        Section {
          // Without the map in lists, there's nothing for these to change, so they wait faded.
          Group {
            ProjectionChooser(selection: $projection, center: center)
              .listRowInsets(EdgeInsets())
            Picker(selection: $center) {
              ForEach(MapCenter.allCases) { center in
                Label(center.name, systemImage: center.globeSymbolName).tag(center)
              }
            } label: {
              SettingsLabel("Center", systemImage: center.globeSymbolName, fill: Color.blue.gradient, trigger: center)
            }
          }
          .disabled(!showsMap)
          .opacity(showsMap ? 1 : 0.4)
          .animation(.smooth, value: showsMap)
        } footer: {
          if !showsMap {
            Text("Enable “Show Map” settings to customize the map view")
          }
        }

        Section {
          if let saveModel {
            NavigationLink {
              LevelsView(saveModel: saveModel)
            } label: {
              LabeledContent {
                LevelSwatches(levels: ladder.levels)
              } label: {
                SettingsLabel(
                  "Levels", systemImage: "stairs",
                  fill: LinearGradient(
                    colors: ladder.levels.map(\.color), startPoint: .topLeading, endPoint: .bottomTrailing))
              }
            }
          }
          LabeledContent {
            Menu {
              Picker("Count from", selection: minimumLevel.animation(.snappy)) {
                ForEach(ladder.levels) { level in
                  Label(level.name, systemImage: level.symbolName).tag(level)
                }
              }
            } label: {
              VisitPillLabel(status: minimum, suffix: "+")
                .pop(on: minimum.id)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Count from")
            .accessibilityValue(minimum.name)
          } label: {
            SettingsLabel(
              "Count from",
              systemImage: minimum.symbolName, fill: minimum.color.gradient, trigger: minimum.id)
          }
          .sensoryFeedback(.selection, trigger: countFromPicks)
          Toggle(isOn: differentiateWithoutColor ? .constant(true) : $showsPatterns.animation(.smooth)) {
            SettingsLabel(
              "Pattern", subtitle: "Distinguish levels with patterns",
              systemImage: "circle.hexagongrid.fill", fill: Color.purple.gradient, trigger: showsPatterns)
          }
          .disabled(differentiateWithoutColor)
        } header: {
          Text("Levels")
        } footer: {
          if differentiateWithoutColor {
            Text("Patterns stay on while Differentiate Without Colour is on.")
          }
        }

        Section {
          NavigationLink {
            CountriesSettingsView()
          } label: {
            LabeledContent {
              Text(worldCount, format: .number)
                .font(.title3.weight(.light))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(worldCount)))
            } label: {
              SettingsLabel("Countries", systemImage: "globe.desk.fill", fill: Color.teal.gradient)
            }
          }
          .animation(.snappy, value: worldCount)
        } header: {
          Text("Regions of the World")
        }

        Section {
          Toggle(isOn: $reducesMotion.animation(.smooth)) {
            SettingsLabel(
              "Reduce Motion", systemImage: "figure.walk.motion", fill: Color.blue.gradient, trigger: reducesMotion)
          }
        } header: {
          Text("Motion")
        } footer: {
          if systemReducesMotion && !reducesMotion {
            Text("System Reduce Motion is on, but this setting overrides it.")
          }
        }

        if AppIcon.isSupported {
          Section {
            NavigationLink {
              AppIconView()
            } label: {
              LabeledContent {
                Image(appIcon.previewImageName)
                  .resizable()
                  .frame(width: 30, height: 30)
                  .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                  .accessibilityHidden(true)
              } label: {
                SettingsLabel("App Icon", systemImage: "paintpalette.fill", fill: Color.cyan.gradient, trigger: appIcon)
              }
            }
          }
        }

        Section {
          NavigationLink {
            PrivacyPolicyView()
          } label: {
            SettingsLabel("Privacy Policy", systemImage: "hand.raised.fill", fill: Color.blue.gradient)
          }
          NavigationLink {
            AcknowledgementsView()
          } label: {
            SettingsLabel("Acknowledgements", systemImage: "heart.fill", fill: Color.pink.gradient)
          }
        }

        if let saveModel {
          Section {
            Button(role: .destructive) {
              isConfirmingReset = true
            } label: {
              SettingsLabel(
                "Reset",
                systemImage: "arrow.counterclockwise", fill: Color.red.gradient, trigger: resets)
            }
            .tint(.red)
            .confirmationDialog("Reset", isPresented: $isConfirmingReset, titleVisibility: .hidden) {
              Button("Reset All Places", role: .destructive) {
                saveModel.resetPlaces()
                resets += 1
              }
              Button("Reset Places and Levels", role: .destructive) {
                saveModel.resetEverything()
                resets += 1
              }
            } message: {
              Text("Every place in every country goes back to never been. This can’t be undone.")
            }
          }
          // A soft thud: the places go quiet, which is nothing to celebrate.
          .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: resets)
        }
      }
      .headerProminence(.increased)
      .navigationTitle("Settings")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", systemImage: "xmark") { dismiss() }
            .labelStyle(.iconOnly)
        }
      }
    }
  }
}

/// A setting's name, with an optional line beneath it, beside its icon tile.
struct SettingsLabel<Detail: View>: View {
  var title: LocalizedStringKey
  var systemImage: String
  var fill: AnyShapeStyle
  var trigger: AnyHashable
  @ViewBuilder var detail: Detail

  init(
    _ title: LocalizedStringKey, systemImage: String, fill: some ShapeStyle, trigger: AnyHashable = 0,
    @ViewBuilder detail: () -> Detail
  ) {
    self.title = title
    self.systemImage = systemImage
    self.fill = AnyShapeStyle(fill)
    self.trigger = trigger
    self.detail = detail()
  }

  var body: some View {
    Label {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        detail
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    } icon: {
      SettingsIcon(systemImage: systemImage, fill: fill, trigger: trigger)
    }
  }
}

extension SettingsLabel where Detail == Text? {
  init(
    _ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, systemImage: String,
    fill: some ShapeStyle, trigger: AnyHashable = 0
  ) {
    self.init(title, systemImage: systemImage, fill: fill, trigger: trigger) {
      subtitle.map { Text($0) }
    }
  }
}

/// A white symbol on a small rounded tile of colour, as in the Settings app. The symbol bounces
/// whenever `trigger` changes, and morphs when it is swapped for another.
struct SettingsIcon: View {
  var systemImage: String
  var fill: AnyShapeStyle
  var trigger: AnyHashable
  @ScaledMetric(relativeTo: .body) private var size = 29
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let tile = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
    Image(systemName: systemImage)
      .font(.system(size: size * 0.5, weight: .semibold))
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.15), radius: 0.5, y: 0.5)
      .contentTransition(.symbolEffect(.replace))
      .symbolEffect(.bounce, value: reduceMotion ? nil : trigger)
      .frame(width: size, height: size)
      .background {
        tile
          .fill(fill)
          .overlay {
            // A soft sheen from the top, like light across glass.
            tile.fill(LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center))
          }
      }
      .accessibilityHidden(true)
  }
}

/// The person's levels as overlapping dots of colour, lowest first.
private struct LevelSwatches: View {
  var levels: [VisitLevel]
  @ScaledMetric(relativeTo: .body) private var size = 16

  var body: some View {
    HStack(spacing: -size * 0.3) {
      ForEach(levels) { level in
        Circle()
          .fill(level.color.gradient)
          .frame(width: size, height: size)
          .overlay {
            Circle().strokeBorder(Color(uiColor: .secondarySystemGroupedBackground), lineWidth: 2)
          }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("^[\(levels.count) level](inflect: true)"))
  }
}

/// How many countries World lists under the rules in its section, in the app's big light
/// numerals. Each change floats up beside the count, so a switch's effect is plain to see.
struct WorldCountRow: View {
  var count: Int
  @ScaledMetric(relativeTo: .largeTitle) private var countSize = 52
  @State private var change: CountChange?

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(count, format: .number)
        .font(.system(size: countSize, weight: .thin))
        .kerning(-1.5)
        .monospacedDigit()
        .contentTransition(.numericText(value: Double(count)))
      Text("countries in World")
        .font(.title3.weight(.light))
        .foregroundStyle(.secondary)
      if let change {
        Text(change.delta, format: .number.sign(strategy: .always()))
          .font(.subheadline.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(change.delta > 0 ? Color.green : Color.orange)
          .id(change.id)
          .transition(
            .asymmetric(
              insertion: .move(edge: .bottom).combined(with: .opacity),
              removal: .opacity.combined(with: .offset(y: -10))))
      }
      Spacer(minLength: 0)
    }
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .animation(.snappy, value: count)
    .onChange(of: count) { old, new in
      withAnimation(.snappy) { change = CountChange(delta: new - old) }
    }
    .task(id: change) {
      guard change != nil else { return }
      try? await Task.sleep(for: .seconds(1.6))
      withAnimation(.smooth) { change = nil }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("World lists \(count) countries")
  }

  private struct CountChange: Equatable {
    var delta: Int
    var id = UUID()
  }
}

/// Every projection as a little world in its own shape, to tap rather than pick from a list.
/// The chosen one lifts in the accent of the map and its name firms up.
private struct ProjectionChooser: View {
  @Binding var selection: MapProjection
  var center: MapCenter
  @State private var thumbnails: [MapProjection: ProjectionThumbnail] = [:]
  @State private var pops: [MapProjection: Int] = [:]
  @ScaledMetric(relativeTo: .caption) private var tileWidth = 112

  var body: some View {
    // One row that scrolls sideways under the map, which stays put above it.
    ScrollViewReader { scroller in
      ScrollView(.horizontal) {
        LazyHStack(spacing: 8) {
          ForEach(MapProjection.allCases) { projection in
            tile(for: projection)
              .frame(width: tileWidth)
              .id(projection)
          }
        }
        .scrollTargetLayout()
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.viewAligned)
      .onAppear { scroller.scrollTo(selection, anchor: .center) }
      .onChange(of: selection) { _, projection in
        withAnimation(.smooth) { scroller.scrollTo(projection, anchor: .center) }
      }
    }
    .sensoryFeedback(.selection, trigger: selection)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Projection")
    .task(id: center) {
      let center = center
      thumbnails = await Task.detached(priority: .userInitiated) {
        var thumbnails: [MapProjection: ProjectionThumbnail] = [:]
        guard let world = Geography.world else { return thumbnails }
        for projection in MapProjection.allCases {
          thumbnails[projection] = ProjectionThumbnail(map: world.map(projection, center: center))
        }
        return thumbnails
      }.value
    }
  }

  private func tile(for projection: MapProjection) -> some View {
    let isSelected = projection == selection
    let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
    return Button {
      pops[projection, default: 0] += 1
      withAnimation(.smooth) { selection = projection }
    } label: {
      VStack(spacing: 6) {
        Group {
          if let thumbnail = thumbnails[projection] {
            ProjectionThumbnailView(thumbnail: thumbnail, isSelected: isSelected)
              .transition(.opacity)
          } else {
            Color.clear
          }
        }
        .aspectRatio(1.7, contentMode: .fit)
        .pop(on: pops[projection, default: 0])
        ScrollingName(text: projection.name)
          .font(.caption.weight(isSelected ? .semibold : .regular))
          .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
      }
      .padding(8)
      .background(isSelected ? AnyShapeStyle(Color.blue.opacity(0.12)) : AnyShapeStyle(.fill.quaternary), in: shape)
      .overlay {
        if isSelected {
          shape.strokeBorder(Color.blue.opacity(0.55), lineWidth: 1.5)
        }
      }
      .scaleEffect(isSelected ? 1 : 0.97)
      .contentShape(shape)
    }
    .buttonStyle(PillButtonStyle())
    .animation(.snappy, value: isSelected)
    .accessibilityLabel(projection.name)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

/// A projection's outline, grid and land, worked out once and drawn small.
private struct ProjectionThumbnail: Sendable {
  var size: CGSize
  /// The area the map covers, which the thumbnail fills.
  var bounds: CGRect
  var outline: Path?
  var graticule: Path?
  var land: Path

  init(map: TravelMap) {
    size = map.size
    outline = map.outline
    graticule = map.graticule
    var land = Path()
    for region in map.regions { land.addPath(region.path) }
    self.land = land
    bounds = map.outline?.boundingRect ?? land.boundingRect
  }
}

private struct ProjectionThumbnailView: View {
  var thumbnail: ProjectionThumbnail
  var isSelected: Bool

  var body: some View {
    let ocean = isSelected ? Color.blue.opacity(0.22) : Color.secondary.opacity(0.12)
    let land = isSelected ? Color.blue.opacity(0.75) : Color.secondary.opacity(0.55)
    let line = isSelected ? Color.blue.opacity(0.35) : Color.secondary.opacity(0.25)
    Canvas { context, size in
      let bounds = thumbnail.bounds
      guard bounds.width > 0, bounds.height > 0 else { return }
      let fit = min(size.width / bounds.width, size.height / bounds.height)
      context.translateBy(
        x: (size.width - bounds.width * fit) / 2 - bounds.minX * fit,
        y: (size.height - bounds.height * fit) / 2 - bounds.minY * fit)
      context.scaleBy(x: fit, y: fit)
      if let outline = thumbnail.outline {
        context.fill(outline, with: .color(ocean))
      }
      if let graticule = thumbnail.graticule {
        context.stroke(graticule, with: .color(line), lineWidth: 0.5 / fit)
      }
      context.fill(thumbnail.land, with: .color(land))
      if let outline = thumbnail.outline {
        context.stroke(outline, with: .color(line), lineWidth: 1 / fit)
      }
    }
    .accessibilityHidden(true)
  }
}
