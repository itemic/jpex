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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SaveModel.self, PrefectureSave.self])
    }
    
    
}

