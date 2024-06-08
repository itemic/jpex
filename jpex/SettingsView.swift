//
//  SettingsView.swift
//  jpex
//
//  Created by Terran Kroft on 7/6/2024.
//

import SwiftUI


struct SettingsView: View {
    @Environment(\.modelContext) var modelContext
    @Binding var resetToggle: Bool
    @AppStorage("localLanguage") var localLanguage: Bool = false
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Image(systemName: "character.textbox.ja")
                    Toggle("Japanese", isOn: $localLanguage)
                }
                Section {
                    Button("Reset", role: .destructive) {
                        do {
                            try modelContext.delete(model: SaveModel.self)
                            resetToggle.toggle()
                        } catch {
                            // nada
                        }
                    }
                    
                }
                Section {
                    Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                }
                
                Section {
                    Link("Dice Simulator", destination: URL(string: "https://apps.apple.com/au/app/dice-simulator/id6464281632")!)
                    Link("Live Rail for HSR (Taiwan)", destination: URL(string: "https://apps.apple.com/au/app/live-rail-for-hsr/id1550589269")!)
                    Link("Percent Grade Calculator", destination: URL(string: "https://apps.apple.com/au/app/percent-grade-calculator/id1672967259")!)
                } header: {
                    Text("Download my other apps :)")
                }
                
            }
            .navigationTitle("Settings")
        }
    }
    
    
}

#Preview {
    SettingsView(resetToggle: .constant(false))
}
