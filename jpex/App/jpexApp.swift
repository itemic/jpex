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
    /// The person's saves, shared through iCloud with their other devices if they choose.
    @State private var saveStore = SaveStore()
    @State private var countingPreferences: CountingPreferences = {
        let preferences = CountingPreferences()
        preferences.mirror(through: .shared)
        return preferences
    }()

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
                // Made anew on each store, so nothing holds a save from the last one.
                .id(saveStore.generation)
                .modelContainer(saveStore.container)
                .environment(saveStore)
                .environment(countingPreferences)
                .environment(CustomWorldGroups.shared)
                .appliesMotionPreference()
        }
    }
}
