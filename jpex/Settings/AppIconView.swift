import SwiftUI

/// Every icon the app can wear, to tap and see on the Home Screen: Japan in its colours and neon,
/// other countries' outlines and licence plates. In Dark Mode, each shows its dark version, as a
/// dark Home Screen would.
struct AppIconView: View {
  @AppStorage(AppIcon.storageKey) private var selection = AppIcon.japan
  @State private var failure: String?
  /// Counts taps on icons, so the tick plays for a choice, not when the screen opens or a failed
  /// change goes back.
  @State private var taps = 0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Form {
      Section {
        IconGrid(icons: AppIcon.japanColours, selection: selection, choose: choose)
      } header: {
        Text("Japan")
      } footer: {
        Text("Original Japan prefectures icon")
      }
      Section("Other maps") {
        IconGrid(icons: AppIcon.otherMaps, selection: selection, choose: choose)
      }
      Section("Chinese licence plates") {
        IconGrid(icons: AppIcon.chinesePlates, selection: selection, choose: choose)
      }
      Section("European licence plates") {
        IconGrid(icons: AppIcon.europeanPlates, selection: selection, choose: choose)
      }
    }
    .headerProminence(.increased)
    .navigationTitle("App icon")
    .navigationBarTitleDisplayMode(.inline)
    .sensoryFeedback(.selection, trigger: taps)
    .onAppear {
      // The Home Screen is the truth, in case the stored choice and it ever disagree.
      selection = AppIcon.current
    }
    .alert(
      "Couldn’t change the icon",
      isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(failure ?? "")
    }
  }

  private func choose(_ icon: AppIcon) {
    guard icon != selection else { return }
    let previous = selection
    taps += 1
    let hop = Motion.moving(Motion.hop, reduceMotion: reduceMotion)
    withAnimation(hop) { selection = icon }
    Task {
      do {
        try await icon.apply()
      } catch {
        withAnimation(hop) { selection = previous }
        failure = error.localizedDescription
      }
    }
  }
}

/// A section's icons in rows that fill the width, the chosen one ringed in the accent colour.
private struct IconGrid: View {
  var icons: [AppIcon]
  var selection: AppIcon
  var choose: (AppIcon) -> Void
  @ScaledMetric(relativeTo: .body) private var iconSize = 64

  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: iconSize + 12), spacing: 12, alignment: .top)], spacing: 16) {
      ForEach(icons) { icon in
        Button {
          choose(icon)
        } label: {
          IconTile(icon: icon, isSelected: icon == selection, size: iconSize)
        }
        .buttonStyle(PillButtonStyle())
        .accessibilityLabel(icon.name)
        .accessibilityAddTraits(icon == selection ? .isSelected : [])
      }
    }
    .padding(.vertical, 8)
  }
}

/// An icon with its name beneath, ringed and ticked while it's the one worn; with Reduce Motion,
/// the ring and tick fade in rather than growing.
private struct IconTile: View {
  var icon: AppIcon
  var isSelected: Bool
  var size: CGFloat
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let shape = RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
    VStack(spacing: 6) {
      Image(icon.previewImageName)
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay {
          shape.strokeBorder(.separator, lineWidth: 0.5)
        }
        .padding(4)
        .overlay {
          if isSelected {
            RoundedRectangle(cornerRadius: size * 0.225 + 4, style: .continuous)
              .strokeBorder(.tint, lineWidth: 2.5)
              .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
          }
        }
        .overlay(alignment: .bottomTrailing) {
          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .font(.title3)
              .symbolRenderingMode(.palette)
              .foregroundStyle(.white, .tint)
              .background(Circle().fill(.background).padding(2))
              .offset(x: 4, y: 4)
              .transition(.arrive(reduceMotion: reduceMotion, anchor: .bottomTrailing))
          }
        }
      ScrollingText {
        Text(icon.name)
          .font(.caption.weight(isSelected ? .semibold : .regular))
          .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
      }
    }
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
  }
}
