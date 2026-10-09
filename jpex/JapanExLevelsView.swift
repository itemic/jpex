import SwiftUI

/// Which of JapanEx's six levels each of the person's levels shows as, for levels that differ from
/// the original five. Never been is always never; the rest are chosen here or matched.
struct JapanExLevelsView: View {
  var ladder: VisitLadder
  @AppStorage(JapanExMapping.storageKey) private var mapping = JapanExMapping()

  var body: some View {
    Form {
      Section {
        LabeledContent {
          JapanExLevelName(level: .never)
        } label: {
          VisitPillLabel(status: .never)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(VisitLevel.never.name)
        .accessibilityValue("Always \(JapanExLevel.never.name) in JapanEx")
        ForEach(ladder.levels) { level in
          Picker(selection: choice(for: level)) {
            ForEach(JapanExLevel.allCases) { option in
              Label {
                JapanExLevelName(level: option)
              } icon: {
                Image(systemName: option.originalLevel.symbolName)
              }
              .tag(option)
            }
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              VisitPillLabel(status: level)
              if mapping.choices[level.id] == nil {
                Text("Matched automatically")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(level.name)
          }
          .pickerStyle(.menu)
        }
      } header: {
        Text("Your Levels")
      } footer: {
        Text("JapanEx scores each prefecture from 0 for never been to 5 for lived. Choose the score each of your levels shows as. Levels you haven’t chosen for are matched by how far up your ladder they are.")
      }
      if mapping.hasChoices(in: ladder) {
        Section {
          Button("Match All Automatically") {
            withAnimation(.snappy) { mapping = JapanExMapping() }
          }
        }
      }
    }
    .navigationTitle("JapanEx")
    .navigationBarTitleDisplayMode(.inline)
    .sensoryFeedback(.selection, trigger: mapping)
  }

  private func choice(for level: VisitLevel) -> Binding<JapanExLevel> {
    Binding(
      get: { mapping.japanExLevel(for: level, in: ladder) },
      set: { newValue in withAnimation(.snappy) { mapping.choices[level.id] = newValue } }
    )
  }
}

/// A JapanEx level's name and score, such as Lived · 5.
private struct JapanExLevelName: View {
  var level: JapanExLevel

  var body: some View {
    Text("\(level.name) · \(level.score)")
  }
}
