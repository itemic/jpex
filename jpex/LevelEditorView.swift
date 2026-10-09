import SwiftUI

/// A level's name, colour and symbol. Changes to an existing level save as you make them,
/// keeping the saved name if the new one is empty or taken. A new level is added with Add.
struct LevelEditorView: View {
  /// The level as saved, or nil while adding a new one.
  private var saved: VisitLevel?
  /// Names already in use, compared without regard to case.
  private var takenNames: [String]
  private var onSave: (VisitLevel) -> Void
  @State private var draft: VisitLevel
  @FocusState private var isNameFocused: Bool
  @Environment(\.dismiss) private var dismiss
  @Environment(\.visitLadder) private var ladder
  @ScaledMetric(relativeTo: .body) private var swatchSize = 38

  private static let maximumNameLength = 24

  init(level: VisitLevel, takenNames: [String], onSave: @escaping (VisitLevel) -> Void) {
    saved = level
    self.takenNames = takenNames
    self.onSave = onSave
    _draft = State(initialValue: level)
  }

  /// Starts a new level in a colour and symbol no other level uses yet.
  init(newLevelFor ladder: VisitLadder, onAdd: @escaping (VisitLevel) -> Void) {
    saved = nil
    takenNames = ladder.allLevels.map(\.name)
    onSave = onAdd
    let tint = LevelColor.choices.first { tint in !ladder.levels.contains { $0.tint == tint } } ?? .blue
    let symbol = Self.symbols.first { symbol in !ladder.levels.contains { $0.symbolName == symbol.name } }
    _draft = State(initialValue: VisitLevel(
      id: UUID().uuidString, name: "", tint: tint, symbolName: symbol?.name ?? "mappin"
    ))
  }

  private var trimmedName: String {
    draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var isTaken: Bool {
    takenNames.contains { $0.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }
  }

  private var isNameValid: Bool {
    !trimmedName.isEmpty && !isTaken
  }

  private var nameMessage: String? {
    if isTaken { return "Another level is already called “\(trimmedName)”." }
    if trimmedName.isEmpty, let saved { return "Enter a name, or this level stays “\(saved.name)”." }
    return nil
  }

  /// The pill as places will show it.
  private var preview: VisitLevel {
    var level = draft
    if !isNameValid { level.name = saved?.name ?? "New Level" }
    return level
  }

  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: swatchSize + 6), spacing: 6)]
  }

  var body: some View {
    Form {
      Section {
        VStack(spacing: 18) {
          VisitPillLabel(status: preview)
            .dynamicTypeSize(.xxxLarge ... .accessibility3)
            .accessibilityHidden(true)
          TextField("Level Name", text: $draft.name)
            .font(.title3.weight(.semibold))
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .focused($isNameFocused)
            .onSubmit(commit)
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(.fill.tertiary, in: .rect(cornerRadius: 12))
        }
        .padding(.vertical, 8)
      } footer: {
        if let nameMessage {
          Text(nameMessage)
        }
      }
      Section("Colour") {
        LazyVGrid(columns: columns, spacing: 6) {
          ForEach(LevelColor.choices) { tint in
            colourButton(tint)
          }
        }
        .padding(.vertical, 4)
      }
      Section("Symbol") {
        LazyVGrid(columns: columns, spacing: 6) {
          ForEach(Self.symbols) { symbol in
            symbolButton(symbol)
          }
        }
        .padding(.vertical, 4)
      }
      Section {
        LazyVGrid(columns: patternColumns, spacing: 8) {
          patternButton(nil)
          ForEach(LevelPatternStyle.allCases) { style in
            patternButton(style)
          }
        }
        .padding(.vertical, 4)
      } header: {
        Text("Pattern")
      } footer: {
        Text("Shown over the colour when Level Patterns is on, so levels differ by more than colour. Automatic gives each level its own.")
      }
    }
    .navigationTitle(saved == nil ? "New Level" : "Edit Level")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if saved == nil {
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            var level = draft
            level.name = trimmedName
            onSave(level)
            dismiss()
          }
          .disabled(!isNameValid)
        }
      }
    }
    .onChange(of: draft.name) {
      if draft.name.count > Self.maximumNameLength {
        draft.name = String(draft.name.prefix(Self.maximumNameLength))
      }
    }
    .onChange(of: draft.tint) { commit() }
    .onChange(of: draft.symbolName) { commit() }
    .onChange(of: draft.pattern) { commit() }
    .onChange(of: isNameFocused) {
      if !isNameFocused { commit() }
    }
    .onAppear {
      if saved == nil { isNameFocused = true }
    }
    .onDisappear(perform: commit)
    .sensoryFeedback(.selection, trigger: draft.tint)
    .sensoryFeedback(.selection, trigger: draft.symbolName)
    .sensoryFeedback(.selection, trigger: draft.pattern)
  }

  private var patternColumns: [GridItem] {
    [GridItem(.adaptive(minimum: swatchSize * 1.7), spacing: 8)]
  }

  /// The pattern Automatic picks: the one for this level's place on the ladder.
  private var automaticPattern: LevelPatternStyle? {
    let rank = ladder.levels.firstIndex { $0.id == draft.id }.map { $0 + 1 } ?? ladder.levels.count + 1
    return LevelPatternStyle(rank: rank)
  }

  /// A swatch of the level's colour wearing a pattern. Nil stands for Automatic.
  private func patternButton(_ style: LevelPatternStyle?) -> some View {
    let isSelected = draft.pattern == style
    let shown = style ?? automaticPattern
    let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
    return Button {
      withAnimation(.snappy) { draft.pattern = style }
    } label: {
      VStack(spacing: 4) {
        ZStack {
          shape.fill(draft.color.gradient)
          if let shown {
            LevelPattern(style: shown, color: .white.opacity(0.45), cell: 9, symbol: draft.symbolName)
              .clipShape(shape)
          }
          if style == nil {
            Image(systemName: "wand.and.sparkles")
              .font(.body.weight(.semibold))
              .foregroundStyle(.white)
              .shadow(color: .black.opacity(0.25), radius: 2)
          }
        }
        .frame(height: swatchSize)
        .overlay {
          if isSelected {
            shape.inset(by: -3).strokeBorder(.secondary, lineWidth: 2.5)
          }
        }
        .scaleEffect(isSelected ? 1 : 0.92)
        ScrollingName(text: style?.name ?? "Automatic")
          .font(.caption2)
          .foregroundStyle(isSelected ? .primary : .secondary)
      }
      .padding(.vertical, 2)
      .frame(maxWidth: .infinity, minHeight: 44)
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(style?.name ?? "Automatic")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private func colourButton(_ tint: LevelColor) -> some View {
    let isSelected = draft.tint == tint
    return Button {
      draft.tint = tint
    } label: {
      Circle()
        .fill(tint.color.gradient)
        .padding(5)
        .overlay {
          if isSelected {
            Circle().strokeBorder(.secondary, lineWidth: 2.5)
          }
        }
        .frame(width: swatchSize, height: swatchSize)
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tint.name)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private func symbolButton(_ symbol: SymbolChoice) -> some View {
    let isSelected = draft.symbolName == symbol.name
    return Button {
      draft.symbolName = symbol.name
    } label: {
      Image(systemName: symbol.name)
        .font(.body.weight(.semibold))
        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
        .frame(width: swatchSize, height: swatchSize)
        .background(isSelected ? AnyShapeStyle(draft.color.gradient) : AnyShapeStyle(.fill.tertiary), in: .circle)
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(symbol.label)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  /// Saves an existing level, keeping its saved name while the typed one can't be used.
  private func commit() {
    guard let saved else { return }
    var level = draft
    level.name = isNameValid ? trimmedName : saved.name
    if level != saved { onSave(level) }
  }

  /// The default levels' symbols first, then ways of getting around, things to do, and reasons to go.
  private static let symbols = [
    SymbolChoice(name: "arrow.right", label: "Passing through"),
    SymbolChoice(name: "figure.walk", label: "Walking"),
    SymbolChoice(name: "mappin", label: "Pin"),
    SymbolChoice(name: "moon", label: "Night"),
    SymbolChoice(name: "house.fill", label: "Home"),
    SymbolChoice(name: "car.fill", label: "Car"),
    SymbolChoice(name: "bus.fill", label: "Bus"),
    SymbolChoice(name: "tram.fill", label: "Tram"),
    SymbolChoice(name: "train.side.front.car", label: "Train"),
    SymbolChoice(name: "airplane", label: "Plane"),
    SymbolChoice(name: "ferry.fill", label: "Ferry"),
    SymbolChoice(name: "sailboat.fill", label: "Sailing"),
    SymbolChoice(name: "bicycle", label: "Cycling"),
    SymbolChoice(name: "figure.hiking", label: "Hiking"),
    SymbolChoice(name: "tent.fill", label: "Camping"),
    SymbolChoice(name: "bed.double.fill", label: "Bed"),
    SymbolChoice(name: "fork.knife", label: "Food"),
    SymbolChoice(name: "cup.and.saucer.fill", label: "Café"),
    SymbolChoice(name: "camera.fill", label: "Camera"),
    SymbolChoice(name: "binoculars.fill", label: "Sightseeing"),
    SymbolChoice(name: "mountain.2.fill", label: "Mountains"),
    SymbolChoice(name: "beach.umbrella.fill", label: "Beach"),
    SymbolChoice(name: "building.2.fill", label: "City"),
    SymbolChoice(name: "briefcase.fill", label: "Work"),
    SymbolChoice(name: "graduationcap.fill", label: "Study"),
    SymbolChoice(name: "suitcase.rolling.fill", label: "Luggage"),
    SymbolChoice(name: "ticket.fill", label: "Ticket"),
    SymbolChoice(name: "flag.fill", label: "Flag"),
    SymbolChoice(name: "star.fill", label: "Star"),
    SymbolChoice(name: "heart.fill", label: "Heart"),
  ]
}

/// A symbol a level can use, with a name for VoiceOver.
private struct SymbolChoice: Identifiable {
  var name: String
  var label: String
  var id: String { name }
}
