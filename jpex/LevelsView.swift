import SwiftUI
import SwiftData

/// The person's levels, lowest first. Tap one to rename or restyle it, and use Edit to
/// reorder or delete. Places at a deleted level move down to the level below it.
struct LevelsView: View {
  var saveModel: SaveModel
  @Environment(\.modelContext) private var modelContext
  @Environment(CountingPreferences.self) private var counting
  @State private var pendingDeletion: VisitLevel?
  @State private var isConfirmingRestore = false
  @State private var saveError: String?
  @AppStorage(JapanExMapping.storageKey) private var japanExMapping = JapanExMapping()

  var body: some View {
    let ladder = saveModel.ladder
    let placeCounts = saveModel.snapshot().placesPerLevel()
    let canAddLevel = ladder.levels.count < VisitLadder.maximumCount
    List {
      Section {
        // Never been is always 0, below every level, and can't be edited, moved or deleted.
        LevelRow(level: .never, value: 0, pattern: nil)
          .moveDisabled(true)
          .deleteDisabled(true)
          .accessibilityHint("Always the lowest. It can’t be changed.")
        ForEach(ladder.levels) { level in
          NavigationLink {
            LevelEditorView(level: level, takenNames: takenNames(in: ladder, besides: level)) { edited in
              update(edited)
            }
          } label: {
            LevelRow(level: level, value: ladder.rank(of: level), pattern: ladder.patternStyle(of: level))
          }
          .deleteDisabled(ladder.levels.count == 1)
          .accessibilityActions {
            if level.id != ladder.levels.first?.id {
              Button("Move Up") { move(level, by: -1) }
            }
            if level.id != ladder.levels.last?.id {
              Button("Move Down") { move(level, by: 1) }
            }
          }
        }
        .onMove { source, destination in
          var reordered = saveModel.ladder
          reordered.levels.move(fromOffsets: source, toOffset: destination)
          save(reordered)
        }
        .onDelete { offsets in
          guard let index = offsets.first else { return }
          let level = ladder.levels[index]
          if placeCounts[level.id, default: 0] > 0 {
            pendingDeletion = level
          } else {
            delete(level)
          }
        }
        if canAddLevel {
          NavigationLink("Add Level…") {
            LevelEditorView(newLevelFor: ladder) { add($0) }
          }
        }
      } footer: {
        if canAddLevel {
          Text("Each tap on a place’s pill moves it up to the next level.")
        } else {
          Text("Each tap on a place’s pill moves it up to the next level. You can have up to \(VisitLadder.maximumCount) levels.")
        }
      }
      // JapanEx has the original five levels; any others show as whichever of those are chosen.
      if !JapanEx.usesOriginalLevels(ladder) {
        Section {
          NavigationLink {
            JapanExLevelsView(ladder: ladder)
          } label: {
            LabeledContent("JapanEx", value: japanExMapping.hasChoices(in: ladder) ? "Custom" : "Automatic")
          }
        } footer: {
          Text("Choose how your levels show when Japan’s prefectures open in JapanEx, which has the six original levels.")
        }
      }
      if ladder != .standard {
        Section {
          Button("Restore Default Levels") { isConfirmingRestore = true }
        }
      }
    }
    .navigationTitle("Levels")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        EditButton()
      }
    }
    .confirmationDialog(
      Text("Delete “\(pendingDeletion?.name ?? "")”?"),
      isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
      titleVisibility: .visible,
      presenting: pendingDeletion
    ) { level in
      Button("Delete Level", role: .destructive) { delete(level) }
    } message: { level in
      let destination = ladder.lower(than: level) ?? .never
      Text("^[\(placeCounts[level.id, default: 0]) place](inflect: true) at \(level.name) will move down to \(destination.name).")
    }
    .confirmationDialog("Restore the default levels?", isPresented: $isConfirmingRestore, titleVisibility: .visible) {
      Button("Restore Defaults", role: .destructive) {
        withAnimation { save(.standard) }
      }
    } message: {
      restoreMessage(for: ladder, placeCounts: placeCounts)
    }
    .alert("Couldn’t save levels", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
      Button("OK", role: .cancel) { saveError = nil }
    } message: {
      Text(saveError ?? "Please try again.")
    }
  }

  /// Every other name in use, including never been, so no two levels look alike.
  private func takenNames(in ladder: VisitLadder, besides level: VisitLevel) -> [String] {
    ladder.allLevels.filter { $0.id != level.id }.map(\.name)
  }

  private func restoreMessage(for ladder: VisitLadder, placeCounts: [String: Int]) -> Text {
    let names = VisitLadder.standard.levels.map(\.name).formatted(.list(type: .and))
    let moving = ladder.replacements(becoming: .standard).keys.reduce(0) { $0 + placeCounts[$1, default: 0] }
    if moving == 0 {
      return Text("Your levels go back to \(names), with their original names and colours.")
    }
    return Text("Your levels go back to \(names). ^[\(moving) place](inflect: true) at levels you added will move down to the nearest default level.")
  }

  private func add(_ level: VisitLevel) {
    var ladder = saveModel.ladder
    guard ladder.levels.count < VisitLadder.maximumCount, ladder.level(id: level.id) == nil else { return }
    ladder.levels.append(level)
    save(ladder)
  }

  private func update(_ level: VisitLevel) {
    var ladder = saveModel.ladder
    guard let index = ladder.levels.firstIndex(where: { $0.id == level.id }), ladder.levels[index] != level else { return }
    ladder.levels[index] = level
    save(ladder)
  }

  private func move(_ level: VisitLevel, by offset: Int) {
    var ladder = saveModel.ladder
    guard let index = ladder.levels.firstIndex(where: { $0.id == level.id }),
          ladder.levels.indices.contains(index + offset) else { return }
    ladder.levels.swapAt(index, index + offset)
    withAnimation { save(ladder) }
  }

  private func delete(_ level: VisitLevel) {
    var ladder = saveModel.ladder
    ladder.levels.removeAll { $0.id == level.id }
    withAnimation { save(ladder) }
  }

  /// Saves the levels with any places they move, restoring everything if the save fails.
  private func save(_ ladder: VisitLadder) {
    let replacements = saveModel.ladder.replacements(becoming: ladder)
    let previousLevels = saveModel.levelsData
    let previousData = saveModel.statusesData
    let previousJapan = saveModel.visitStatus
    do {
      try saveModel.setLadder(ladder)
      try modelContext.save()
      // Totals count from wherever that level's places moved, so they keep counting.
      if let replacement = replacements[counting.rules.minimumLevelID] {
        counting.rules.minimumLevelID = replacement == .never ? ladder.levels[0].id : replacement.id
      }
    } catch {
      saveModel.levelsData = previousLevels
      saveModel.statusesData = previousData
      saveModel.visitStatus = previousJapan
      saveError = error.localizedDescription
    }
  }
}

/// A level's symbol, name and value: 1 for the lowest level, counting up the ladder.
private struct LevelRow: View {
  var level: VisitLevel
  var value: Int
  var pattern: LevelPatternStyle?
  @ScaledMetric(relativeTo: .body) private var iconSize = 30
  @AppStorage(LevelPattern.storageKey) private var showsPatterns = true
  @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: level.symbolName)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .frame(width: iconSize, height: iconSize)
        .background {
          ZStack {
            Rectangle().fill(level.color.gradient)
            if let pattern, showsPatterns || differentiateWithoutColor {
              LevelPattern(style: pattern, color: .white.opacity(0.3), cell: 6, symbol: level.symbolName)
            }
          }
          .clipShape(.circle)
        }
      Text(level.name)
      Spacer(minLength: 8)
      Text(value, format: .number)
        .font(.title3.weight(.light))
        .monospacedDigit()
        .foregroundStyle(level.color)
        .frame(minWidth: iconSize)
        .contentTransition(.numericText(value: Double(value)))
    }
    .animation(.snappy, value: value)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(level.name)
    .accessibilityValue("Level \(value)")
  }
}
