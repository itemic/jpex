import SwiftUI

/// What the seas are called. Each sea known by more than one name has a card for each, the name
/// the IHO's sea areas give it first, as Countries chooses the continent of a country spanning two.
/// The other names wear the flag of who uses them.
struct SeasSettingsView: View {
  @Environment(CountingPreferences.self) private var counting

  var body: some View {
    Form {
      Section {
        WorldCountRow(count: CountryCatalog.seas.divisions.count, noun: "seas and oceans", tint: .blue)
      } footer: {
        Text(
          "Seas follow the International Hydrographic Organization’s limits of oceans and seas, with the Caspian and the Dead Sea as inland seas."
        )
      }
      namesSection
    }
    .navigationTitle("Seas")
    .navigationBarTitleDisplayMode(.inline)
  }

  /// A line of cards for each sea with more than one name.
  private var namesSection: some View {
    Section {
      VStack(alignment: .leading, spacing: 14) {
        BoardHeader(
          title: "Sea names", subtitle: Text("Choose what to call a sea known by more than one name"),
          systemImage: "character.bubble.fill", tint: .blue, trigger: counting.rules.seaNames
        ) {
          EmptyView()
        }
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          ForEach(CountryCatalog.seasWithOtherNames, id: \.id) { sea in
            let choice = counting.rules.seaNames[sea.id] ?? sea.names[0]
            GridRow {
              ForEach(sea.names, id: \.self) { name in
                ToggleCard(title: name, subtitle: nil, tint: .blue, isOn: choice == name, isCompact: true) {
                  if let flag = Self.flag(of: name, in: sea.id) {
                    FlagMark(assetName: flag, isOn: choice == name)
                  } else {
                    SymbolMark(systemImage: "globe", tint: .blue, isOn: choice == name)
                  }
                } action: {
                  withAnimation(.bouncy) {
                    counting.rules.seaNames[sea.id] = name == sea.names[0] ? nil : name
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

  /// The flag of who uses a sea's other name, such as South Korea's for the East Sea. None for the
  /// IHO's own name, which shows a globe.
  private static func flag(of name: String, in seaID: String) -> String? {
    switch (seaID, name) {
    case (_, "Arabian Gulf"): "group_flag_gulf_cooperation"
    case (_, "Gulf of America"): "world_flag_us"
    case (_, "West Philippine Sea"): "world_flag_ph"
    case ("SEAS-south-china-sea", "East Sea"): "world_flag_vn"
    case (_, "East Sea"), (_, "West Sea"): "world_flag_kr"
    default: nil
    }
  }
}
