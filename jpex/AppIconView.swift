import SwiftUI

/// Every icon the app can wear, to tap and see on the Home Screen: Japan in its colours, then
/// other countries' outlines.
struct AppIconView: View {
  @AppStorage(AppIcon.storageKey) private var selection = AppIcon.japan
  @State private var failure: String?
  /// Counts taps on icons, so the tick plays for a choice, not when the screen opens or a failed
  /// change goes back.
  @State private var taps = 0

  var body: some View {
    Form {
      Section {
        IconGrid(icons: AppIcon.japanColours, selection: selection, choose: choose)
      } header: {
        Text("Japan")
      } footer: {
        Text("都道府県 and the islands of Japan, in your choice of colour.")
      }
      Section("Other Maps") {
        IconGrid(icons: AppIcon.otherMaps, selection: selection, choose: choose)
      }
      Section {
        IconGrid(icons: AppIcon.chinesePlates, selection: selection, choose: choose)
      } header: {
        Text("Chinese Licence Plates")
      } footer: {
        Text("Each province’s one-character short name, as on its cars’ plates.")
      }
      Section {
        IconGrid(icons: AppIcon.europeanPlates, selection: selection, choose: choose)
      } header: {
        Text("European Licence Plates")
      } footer: {
        Text("The blue band that starts plates across the European Union, with each country’s code.")
      }
    }
    .headerProminence(.increased)
    .navigationTitle("App Icon")
    .navigationBarTitleDisplayMode(.inline)
    .sensoryFeedback(.selection, trigger: taps)
    .onAppear {
      // The Home Screen is the truth, in case the stored choice and it ever disagree.
      selection = AppIcon.current
    }
    .alert(
      "Couldn’t Change the Icon",
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
    withAnimation(.snappy) { selection = icon }
    Task {
      do {
        try await icon.apply()
      } catch {
        withAnimation(.snappy) { selection = previous }
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

private struct IconTile: View {
  var icon: AppIcon
  var isSelected: Bool
  var size: CGFloat

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
              .transition(.scale(scale: 0.9).combined(with: .opacity))
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
              .transition(.scale.combined(with: .opacity))
          }
        }
      Text(icon.name)
        .font(.caption.weight(isSelected ? .semibold : .regular))
        .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
  }
}
