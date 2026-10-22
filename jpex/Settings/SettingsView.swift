import SwiftUI

struct SettingsView: View {
  /// Nil until the store is ready; levels can be edited once it is.
  var saveModel: SaveModel?
  /// Shows the welcome again, once Settings has closed.
  var onShowWelcome: () -> Void = {}
  @AppStorage(ListOrder.showsMapKey) private var showsMap = true
  @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
  @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
  @Environment(CountingPreferences.self) private var counting
  @Environment(CustomWorldGroups.self) private var customGroups
  @AppStorage(HiddenWorldGroups.storageKey) private var hiddenGroups = HiddenWorldGroups()
  @AppStorage(LevelPattern.storageKey) private var showsPatterns = true
  @AppStorage(AppIcon.storageKey) private var appIcon = AppIcon.japan
  @AppStorage(MotionPreference.storageKey) private var reducesMotion = false
  @AppStorage(CloudSync.choiceKey) private var syncsWithICloud = false
  @Environment(\.systemReducesMotion) private var systemReducesMotion
  @Environment(\.visitLadder) private var ladder
  @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
  @Environment(\.dismiss) private var dismiss
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @State private var isConfirmingReset = false
  /// Asks once more before Reset Everything, saying all that goes with it.
  @State private var isConfirmingResetEverything = false
  /// Counts choices made here, so this picker's tick plays once, apart from the list's own.
  @State private var countFromPicks = 0
  @State private var resets = 0

  /// How many groups of countries the sidebar shows, the World's and the person's own.
  private var shownGroupCount: Int {
    (WorldGroup.allCases.map(\.collectionID) + customGroups.groups.map(\.collectionID))
      .count { !hiddenGroups.isHidden($0) }
  }

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
        // Local names and showing the map are in each list's View menu, so they're set there.
        Section {
          // A fixed frame, so changing the projection reshapes the map without moving the page.
          // The map runs past the card's margins to the screen's edges, with the page around it.
          // On a phone on its side, no taller than a postcard, so it doesn't fill the screen; the
          // map still runs edge to edge, fitted within that height. Upright and on iPad, it keeps
          // its own shape.
          Color.clear
            .aspectRatio(1.9, contentMode: .fit)
            .frame(maxHeight: verticalSizeClass == .compact ? 240 : nil)
            .frame(maxWidth: .infinity)
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
          Text("World map")
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
              SettingsLabel("Map centre", systemImage: center.globeSymbolName, fill: Color.blue.gradient, trigger: center)
            }
          }
          .disabled(!showsMap)
          .opacity(showsMap ? 1 : 0.4)
          .animation(.smooth, value: showsMap)
        } footer: {
          if !showsMap {
            Text("Turn on Map in a list’s View menu to change how it looks.")
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
              "Distinguish without colour",
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
          NavigationLink {
            WorldGroupsSettingsView(saveModel: saveModel)
          } label: {
            LabeledContent {
              Text(shownGroupCount, format: .number)
                .font(.title3.weight(.light))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(shownGroupCount)))
            } label: {
              SettingsLabel("Groups", systemImage: "rectangle.3.group.fill", fill: Color.indigo.gradient)
            }
          }
          .animation(.snappy, value: shownGroupCount)
          NavigationLink {
            SeasSettingsView()
          } label: {
            LabeledContent {
              Text(CountryCatalog.seas.divisions.count, format: .number)
                .font(.title3.weight(.light))
                .monospacedDigit()
            } label: {
              SettingsLabel("Seas", systemImage: "water.waves", fill: Color.blue.gradient)
            }
          }
        } header: {
          Text("Regions of the world")
        }

        Section {
          Toggle(isOn: $reducesMotion.animation(.smooth)) {
            SettingsLabel(
              "Reduce motion", systemImage: "figure.walk.motion", fill: Color.blue.gradient, trigger: reducesMotion)
          }
        } header: {
          Text("Motion")
        } footer: {
          if systemReducesMotion && !reducesMotion {
            Text("System Reduce Motion is on, but this setting overrides it.")
          }
        }

        Section {
          Toggle(isOn: $syncsWithICloud.animation(.smooth)) {
            SettingsLabel("iCloud sync", systemImage: "icloud.fill", fill: Color.blue.gradient, trigger: syncsWithICloud)
          }
        } header: {
          Text("iCloud")
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
                SettingsLabel("App icon", systemImage: "paintpalette.fill", fill: Color.cyan.gradient, trigger: appIcon)
              }
            }
          }
        }

        Section {
          Button {
            onShowWelcome()
            dismiss()
          } label: {
            SettingsLabel("Replay welcome screen", systemImage: "play.fill", fill: Color.green.gradient)
          }
          .foregroundStyle(.primary)
          // The policy lives on the website, so it can change without an update to the app.
          Link(destination: URL(string: "https://www.terrankroft.com/prefectures/privacy/")!) {
            LabeledContent {
              Image(systemName: "arrow.up.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
            } label: {
              SettingsLabel("Privacy policy", systemImage: "hand.raised.fill", fill: Color.blue.gradient)
            }
          }
          .foregroundStyle(.primary)
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
              Button("Reset all places", role: .destructive) {
                saveModel.resetPlaces()
                resets += 1
              }
              Button("Reset places and levels", role: .destructive) {
                saveModel.resetEverything()
                resets += 1
              }
              // The most that can go, so it asks again, saying exactly what.
              Button("Reset everything", role: .destructive) {
                isConfirmingResetEverything = true
              }
            } message: {
              Text("This will reset everything and can’t be undone.")
            }
            .alert("Reset everything?", isPresented: $isConfirmingResetEverything) {
              Button("Reset everything", role: .destructive) {
                AppReset.resetEverything(saveModel: saveModel, counting: counting, groups: customGroups)
                resets += 1
              }
              Button("Cancel", role: .cancel) {}
            } message: {
              Text("Everything will be reset. Are you sure you want to proceed?")
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
            .keyboardShortcut(.cancelAction)
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
        ScrollingText { Text(title) }
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

/// A page's total, in the manner of webOS on the Palm Pre: straight on the page and centred, as the
/// Pre's clock sat above its gesture light. The number is a glossy, striped bubble in the page's
/// colour (see `BubblyNumber`), and "in total" sits beside it in Seravek Light, the nearest iOS has
/// to Palm's Prelude, pressed into the page with a letterpress highlight. Beneath them sits the
/// Pre's gesture light, a pearl set in a groove. Each change floats up beside the count in a glossy
/// pill, green as it rises and orange as it falls, and sends a streak of that colour along the
/// light: forwards as it rises and back as it falls, as the Pre's light followed a swipe. Changes
/// made while the pill shows add to it, rolling in place. With Reduce Motion the pill fades in and
/// out where it stands and the light only brightens.
struct WorldCountRow: View {
  var count: Int
  /// What's counted, for VoiceOver, such as "countries"; the page itself says only "in total".
  var noun = "countries"
  /// Beside the count.
  var caption = "in total"
  /// The number's colour, the same as the page's icon in Settings.
  var tint: Color = .teal
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @State private var change: CountChange?
  /// Counts each change, for the gesture light to pulse.
  @State private var pulses = 0
  /// Whether the last change was a rise, for its pulse's colour and way.
  @State private var rose = true

  var body: some View {
    // Pressed into the page: a highlight just below the type on light pages, a shade just above
    // it on dark ones.
    let press: (color: Color, y: CGFloat) = colorScheme == .dark ? (.black.opacity(0.7), -1) : (.white, 1)
    VStack(spacing: 14) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        BubblyNumber(count: count, tint: tint)
        Text(caption)
          .font(.custom("Seravek-Light", size: 23, relativeTo: .title3))
          .tracking(0.3)
          .foregroundStyle(.secondary)
          .shadow(color: press.color, radius: 0, y: press.y)
          // One slot beside the caption, outside the centred pair so it doesn't push them over,
          // and a change made just as the last floats away takes its place.
          .overlay(alignment: .trailing) {
            ZStack(alignment: .leading) {
              if let change {
                ChangePill(delta: change.delta)
                  .id(change.id)
                  .transition(
                    reduceMotion
                      ? .opacity
                      : .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity.combined(with: .offset(y: -10))))
              }
            }
            .fixedSize()
            .alignmentGuide(.trailing) { $0[.leading] - 10 }
          }
      }
      .lineLimit(1)
      GestureLight(pulses: pulses, tint: rose ? .green : .orange, forward: rose)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    // Straight on the page, rather than in a well of its own like the rows beneath it.
    .listRowBackground(Color.clear)
    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
    .animation(Motion.count, value: count)
    .onChange(of: count) { old, new in
      rose = new > old
      pulses += 1
      // A few switches in a row read as their sum, the change already showing rolling to it, and
      // its time starting over; switches that cancel out leave nothing to show.
      let delta = (change?.delta ?? 0) + new - old
      withAnimation(Motion.count) {
        if delta == 0 {
          change = nil
        } else if var current = change {
          current.delta = delta
          change = current
        } else {
          change = CountChange(delta: delta)
        }
      }
    }
    .task(id: change) {
      guard change != nil else { return }
      try? await Task.sleep(for: .seconds(1.6))
      // A newer change has started its time over, so this one leaves it be.
      guard !Task.isCancelled else { return }
      withAnimation(.smooth) { change = nil }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(count) \(noun) \(caption)")
  }

  private struct CountChange: Equatable {
    var delta: Int
    var id = UUID()
  }
}

/// A count as a glossy bubble: heavy rounded figures in a colour that deepens towards their foot,
/// striped across with fine lines that thicken as they go down, glossed across their top half, lit
/// along every upper edge and shaded along every lower one, and standing a little proud of the page
/// on a darker edge of their own. It rolls to each new count as the plain figures would.
private struct BubblyNumber: View {
  var count: Int
  var tint: Color
  @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 84

  var body: some View {
    // How far the rims and the raised edge reach, in step with the figures' size.
    let depth = size * 0.033
    figures
      .foregroundStyle(
        LinearGradient(
          colors: [tint.mix(with: .white, by: 0.15), tint, tint.mix(with: .black, by: 0.2)],
          startPoint: .top, endPoint: .bottom))
      .overlay {
        ZStack {
          BubbleStripes(pitch: depth * 2.2, headThickness: depth * 0.22, footThickness: depth * 1.45)
            .fill(.white.opacity(0.3))
          // The gloss, bright at the top and ending in a clean edge halfway down.
          LinearGradient(
            stops: [
              .init(color: .white.opacity(0.45), location: 0), .init(color: .white.opacity(0.14), location: 0.42),
              .init(color: .clear, location: 0.46),
            ],
            startPoint: .top, endPoint: .bottom)
          // A highlight along every upper edge, where the figures would catch the light…
          Color.white.opacity(0.85)
            .mask { rim(offset: depth * 0.75) }
          // …and a shade along every lower one.
          Color.black.opacity(0.25)
            .mask { rim(offset: -depth * 0.75) }
        }
        .mask { figures }
      }
      // Standing proud of the page.
      .shadow(color: tint.mix(with: .black, by: 0.5).opacity(0.85), radius: 0, y: depth)
      .shadow(color: tint.opacity(0.25), radius: depth * 2.6, y: depth * 2)
  }

  private var figures: some View {
    Text(count, format: .number)
      .font(.system(size: size, weight: .heavy, design: .rounded))
      .kerning(-1)
      .contentTransition(.numericText(value: Double(count)))
  }

  /// The edge of the figures left uncovered by a copy of them moved down by `offset`, or up for a
  /// negative one: their upper edges, or their lower ones.
  private func rim(offset: CGFloat) -> some View {
    ZStack {
      figures
      figures
        .offset(y: offset)
        .blendMode(.destinationOut)
    }
    .compositingGroup()
  }
}

/// Lines across a space, thin at its head and thickening towards its foot.
private struct BubbleStripes: Shape {
  /// From one line to the next.
  var pitch: CGFloat
  var headThickness: CGFloat
  var footThickness: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    guard pitch > 0 else { return path }
    var y = rect.minY
    while y < rect.maxY {
      let along = (y - rect.minY) / max(rect.height, 1)
      let thickness = headThickness + (footThickness - headThickness) * along
      path.addRect(CGRect(x: rect.minX, y: y + (pitch - thickness) / 2, width: rect.width, height: thickness))
      y += pitch
    }
    return path
  }
}

/// A change to the count in a glossy pill, as webOS badged its counts: green as it rises and orange
/// as it falls, its top half catching the light.
private struct ChangePill: View {
  var delta: Int

  var body: some View {
    let tint = delta > 0 ? Color.green : Color.orange
    // A true minus sign as it falls, the width of the plus as it rises.
    Text(delta > 0 ? "+\(delta)" : "\u{2212}\(-delta)")
      .font(.custom("Seravek-Medium", size: 15, relativeTo: .subheadline))
      .monospacedDigit()
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.25), radius: 0, y: -0.5)
      .contentTransition(.numericText(value: Double(delta)))
      .padding(.horizontal, 9)
      .padding(.vertical, 3)
      .background {
        Capsule()
          .fill(LinearGradient(colors: [tint.mix(with: .white, by: 0.2), tint], startPoint: .top, endPoint: .bottom))
          // The gloss: bright across the top half, ending in a clean edge.
          .overlay {
            Capsule()
              .fill(
                LinearGradient(
                  stops: [
                    .init(color: .white.opacity(0.55), location: 0), .init(color: .white.opacity(0.15), location: 0.48),
                    .init(color: .clear, location: 0.5),
                  ],
                  startPoint: .top, endPoint: .bottom))
              .padding(1)
          }
          .overlay { Capsule().strokeBorder(tint.mix(with: .black, by: 0.2).opacity(0.5), lineWidth: 0.5) }
          .shadow(color: tint.opacity(0.35), radius: 3, y: 1)
      }
  }
}

/// The Palm Pre's gesture light: a pearl in a slim, pointed groove pressed into the page beneath the count,
/// glowing softly at its middle, which sends a streak of light along it each time `pulses`
/// changes, forwards or back as the Pre's light followed a swipe. With Reduce Motion the light only
/// brightens where it rests.
private struct GestureLight: View {
  var pulses: Int
  var tint: Color
  /// Whether the streak runs forwards, from the leading end, or back from the trailing one.
  var forward: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.colorScheme) private var colorScheme
  @ScaledMetric(relativeTo: .largeTitle) private var length: CGFloat = 180
  /// Follows `pulses`, gliding from one count to the next, so a streak is the fraction of the way
  /// between them: nothing at rest, running along and fading as it goes.
  @State private var travelled = 0.0

  var body: some View {
    let isDark = colorScheme == .dark
    // A sliver, fullest at its middle and drawn to a point at each end, as the Pre's light was.
    Ellipse()
      // The groove, its upper edge in shade.
      .fill(Color.primary.opacity(isDark ? 0.16 : 0.11).shadow(.inner(color: .black.opacity(isDark ? 0.6 : 0.28), radius: 1, y: 1)))
      // The pearl, glowing softly at its middle as the Pre's light rests.
      .overlay {
        Ellipse()
          .fill(
            LinearGradient(
              stops: [
                .init(color: .white.opacity(0), location: 0.15), .init(color: .white.opacity(isDark ? 0.45 : 1), location: 0.5),
                .init(color: .white.opacity(0), location: 0.85),
              ],
              startPoint: .leading, endPoint: .trailing))
          .padding(.vertical, 2)
          .padding(.horizontal, 8)
      }
      .frame(height: 8)
      // The groove's lower lip catching the light.
      .background {
        Ellipse()
          .fill(.white.opacity(isDark ? 0.07 : 1))
          .offset(y: 1)
      }
      .modifier(LightStreak(travelled: travelled, tint: tint, forward: forward, runs: !reduceMotion))
      .frame(maxWidth: length)
      .onAppear { travelled = Double(pulses) }
      .onChange(of: pulses) { _, pulses in
        withAnimation(reduceMotion ? .easeOut(duration: 0.6) : .easeInOut(duration: 0.9)) { travelled = Double(pulses) }
      }
      .accessibilityHidden(true)
  }
}

/// The gesture light's streak, drawn from how far `travelled` is between two whole numbers: in at
/// one end of the groove and out at the other as it goes, brightest midway, with a glow spilling
/// on to the page around it; gone once it arrives.
private struct LightStreak: ViewModifier, Animatable {
  var travelled: Double
  var tint: Color
  var forward: Bool
  /// Whether the streak runs along, or with Reduce Motion only brightens where it rests.
  var runs: Bool

  var animatableData: Double {
    get { travelled }
    set { travelled = newValue }
  }

  func body(content: Content) -> some View {
    let progress = travelled - travelled.rounded(.down)
    let glow = progress > 0 ? sin(progress * .pi) : 0
    content.overlay {
      GeometryReader { proxy in
        let width = proxy.size.width
        let streak = runs ? width * 0.5 : width
        let along = forward ? progress : 1 - progress
        let centre = runs ? along * width : width / 2
        let core = LinearGradient(
          stops: [
            .init(color: tint.opacity(0), location: 0), .init(color: tint, location: 0.3),
            .init(color: tint.mix(with: .white, by: 0.45), location: 0.5), .init(color: tint, location: 0.7),
            .init(color: tint.opacity(0), location: 1),
          ],
          startPoint: .leading, endPoint: .trailing)
        ZStack {
          // The glow, spilling out of the groove on to the page.
          Capsule()
            .fill(core)
            .frame(width: streak, height: 14)
            .blur(radius: 7)
            .opacity(glow * 0.75)
            .position(x: centre, y: proxy.size.height / 2)
          // The light itself, kept to the groove.
          Capsule()
            .fill(core)
            .frame(width: streak, height: proxy.size.height)
            .position(x: centre, y: proxy.size.height / 2)
            .opacity(glow)
            .mask(Ellipse())
        }
      }
    }
  }
}

/// Every projection as a little world in its own shape, to tap rather than pick from a list.
/// The chosen one lifts in the accent of the map and its name firms up.
private struct ProjectionChooser: View {
  @Binding var selection: MapProjection
  var center: MapCenter
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        // With Reduce Motion the chosen world is simply in the middle, rather than gliding there.
        withAnimation(Motion.travelling(.smooth, reduceMotion: reduceMotion)) {
          scroller.scrollTo(projection, anchor: .center)
        }
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
      .scaleEffect(isSelected || reduceMotion ? 1 : 0.97)
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
    // A drawing can't ease from one colour to another, so the world in grey and the same world in
    // blue cross-fade with the tile around them.
    ZStack {
      world(chosen: false)
        .opacity(isSelected ? 0 : 1)
      world(chosen: true)
        .opacity(isSelected ? 1 : 0)
    }
    .accessibilityHidden(true)
  }

  private func world(chosen: Bool) -> some View {
    let ocean = chosen ? Color.blue.opacity(0.22) : Color.secondary.opacity(0.12)
    let land = chosen ? Color.blue.opacity(0.75) : Color.secondary.opacity(0.55)
    let line = chosen ? Color.blue.opacity(0.35) : Color.secondary.opacity(0.25)
    return Canvas { context, size in
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
  }
}
