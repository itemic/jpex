//
//  jpexApp.swift
//  jpex
//
//  Created by Terran Kroft on 26/1/2024.
//

import SwiftUI
import MapKit
import SwiftData

@main
struct jpexApp: App {
    @State private var countingPreferences = CountingPreferences()

    init() {
        ScreenTitleStyle.apply()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(countingPreferences)
                .appliesMotionPreference()
        }
        .modelContainer(for: [SaveModel.self])
    }
}
