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
        // The World's outlines, read and parsed away from the main thread while the first screen
        // draws, so the World's map is ready, or nearly, when its list first asks for it.
        Task.detached(priority: .userInitiated) {
            _ = Geography.world
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(countingPreferences)
                .environment(CustomWorldGroups.shared)
                .appliesMotionPreference()
        }
        .modelContainer(for: [SaveModel.self])
    }
}
