import SwiftUI

struct AcknowledgementsView: View {
  var body: some View {
    List {
      Section {
        Link(destination: JapanEx.homepage) {
          VStack(alignment: .leading, spacing: 4) {
            Label("JapanEx by Zhung", systemImage: "globe.asia.australia.fill")
              .font(.headline)
            Text("This app began as a take on JapanEx, which maps the prefectures you’ve been to. Japan’s list can open your prefectures in it, with your levels shown as its own.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
      } header: {
        Text("Inspired by")
      }
      Section {
        ForEach(FlagCreditSource.all) { source in
          NavigationLink(source.title) {
            FlagCreditsView(title: source.title, resource: source.resource)
          }
        }
      } header: {
        Text("Maps and Flags")
      }
    }
    .navigationTitle("Acknowledgements")
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct FlagCreditSource: Identifiable {
  var title: String
  var resource: String
  var id: String { resource }

  static let all = [
    FlagCreditSource(title: "Maps", resource: "MapCredits"),
    FlagCreditSource(title: "World", resource: "WorldFlagCredits"),
    FlagCreditSource(title: "Albania", resource: "AlbaniaFlagCredits"),
    FlagCreditSource(title: "Argentina", resource: "ArgentinaFlagCredits"),
    FlagCreditSource(title: "Armenia", resource: "ArmeniaFlagCredits"),
    FlagCreditSource(title: "Australia", resource: "AustraliaFlagCredits"),
    FlagCreditSource(title: "Austria", resource: "AustriaFlagCredits"),
    FlagCreditSource(title: "Belarus", resource: "BelarusFlagCredits"),
    FlagCreditSource(title: "Belgium", resource: "BelgiumFlagCredits"),
    FlagCreditSource(title: "Bolivia", resource: "BoliviaFlagCredits"),
    FlagCreditSource(title: "Bosnia and Herzegovina", resource: "BosniaFlagCredits"),
    FlagCreditSource(title: "Brazil", resource: "BrazilFlagCredits"),
    FlagCreditSource(title: "Canada", resource: "CanadaFlagCredits"),
    FlagCreditSource(title: "Chile", resource: "ChileFlagCredits"),
    FlagCreditSource(title: "China", resource: "ChinaFlagCredits"),
    FlagCreditSource(title: "Colombia", resource: "ColombiaFlagCredits"),
    FlagCreditSource(title: "Costa Rica", resource: "CostaRicaFlagCredits"),
    FlagCreditSource(title: "Croatia", resource: "CroatiaFlagCredits"),
    FlagCreditSource(title: "Czechia", resource: "CzechiaFlagCredits"),
    FlagCreditSource(title: "Ecuador", resource: "EcuadorFlagCredits"),
    FlagCreditSource(title: "Egypt", resource: "EgyptFlagCredits"),
    FlagCreditSource(title: "El Salvador", resource: "ElSalvadorFlagCredits"),
    FlagCreditSource(title: "Estonia", resource: "EstoniaFlagCredits"),
    FlagCreditSource(title: "Finland", resource: "FinlandFlagCredits"),
    FlagCreditSource(title: "France", resource: "FranceFlagCredits"),
    FlagCreditSource(title: "Germany", resource: "GermanyFlagCredits"),
    FlagCreditSource(title: "Guatemala", resource: "GuatemalaFlagCredits"),
    FlagCreditSource(title: "Hungary", resource: "HungaryFlagCredits"),
    FlagCreditSource(title: "Indonesia", resource: "IndonesiaFlagCredits"),
    FlagCreditSource(title: "Iraq", resource: "IraqFlagCredits"),
    FlagCreditSource(title: "Ireland", resource: "IrelandFlagCredits"),
    FlagCreditSource(title: "Italy", resource: "ItalyFlagCredits"),
    FlagCreditSource(title: "Kazakhstan", resource: "KazakhstanFlagCredits"),
    FlagCreditSource(title: "Kenya", resource: "KenyaFlagCredits"),
    FlagCreditSource(title: "Kyrgyzstan", resource: "KyrgyzstanFlagCredits"),
    FlagCreditSource(title: "Latvia", resource: "LatviaFlagCredits"),
    FlagCreditSource(title: "Lithuania", resource: "LithuaniaFlagCredits"),
    FlagCreditSource(title: "Malaysia", resource: "MalaysiaFlagCredits"),
    FlagCreditSource(title: "Malta", resource: "MaltaFlagCredits"),
    FlagCreditSource(title: "Mexico", resource: "MexicoFlagCredits"),
    FlagCreditSource(title: "Mongolia", resource: "MongoliaFlagCredits"),
    FlagCreditSource(title: "Montenegro", resource: "MontenegroFlagCredits"),
    FlagCreditSource(title: "Netherlands", resource: "NetherlandsFlagCredits"),
    FlagCreditSource(title: "New Zealand", resource: "NewZealandFlagCredits"),
    FlagCreditSource(title: "Nigeria", resource: "NigeriaFlagCredits"),
    FlagCreditSource(title: "Norway", resource: "NorwayFlagCredits"),
    FlagCreditSource(title: "Panama", resource: "PanamaFlagCredits"),
    FlagCreditSource(title: "Papua New Guinea", resource: "PapuaNewGuineaFlagCredits"),
    FlagCreditSource(title: "Paraguay", resource: "ParaguayFlagCredits"),
    FlagCreditSource(title: "Peru", resource: "PeruFlagCredits"),
    FlagCreditSource(title: "Philippines", resource: "PhilippinesFlagCredits"),
    FlagCreditSource(title: "Poland", resource: "PolandFlagCredits"),
    FlagCreditSource(title: "Portugal", resource: "PortugalFlagCredits"),
    FlagCreditSource(title: "Romania", resource: "RomaniaFlagCredits"),
    FlagCreditSource(title: "Russia", resource: "RussiaFlagCredits"),
    FlagCreditSource(title: "Serbia", resource: "SerbiaFlagCredits"),
    FlagCreditSource(title: "Slovakia", resource: "SlovakiaFlagCredits"),
    FlagCreditSource(title: "South Korea", resource: "SouthKoreaFlagCredits"),
    FlagCreditSource(title: "Spain", resource: "SpainFlagCredits"),
    FlagCreditSource(title: "Sri Lanka", resource: "SriLankaFlagCredits"),
    FlagCreditSource(title: "Sweden", resource: "SwedenFlagCredits"),
    FlagCreditSource(title: "Switzerland", resource: "SwitzerlandFlagCredits"),
    FlagCreditSource(title: "Taiwan", resource: "TaiwanFlagCredits"),
    FlagCreditSource(title: "Thailand", resource: "ThailandFlagCredits"),
    FlagCreditSource(title: "Ukraine", resource: "UkraineFlagCredits"),
    FlagCreditSource(title: "United Arab Emirates", resource: "UAEFlagCredits"),
    FlagCreditSource(title: "United Kingdom", resource: "UKFlagCredits"),
    FlagCreditSource(title: "United States", resource: "USFlagCredits"),
    FlagCreditSource(title: "Uruguay", resource: "UruguayFlagCredits"),
    FlagCreditSource(title: "Uzbekistan", resource: "UzbekistanFlagCredits"),
    FlagCreditSource(title: "Venezuela", resource: "VenezuelaFlagCredits"),
  ]
}
