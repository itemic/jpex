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
                
            }
            .navigationTitle("Settings")
        }
    }
    
    
}

#Preview {
    SettingsView(resetToggle: .constant(false))
}
