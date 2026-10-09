import SwiftUI

/// Kept as a lightweight entry point for callers of the original home screen.
struct HomeView: View {
    @State private var countingPreferences = CountingPreferences()

    var body: some View {
        ContentView()
            .environment(countingPreferences)
    }
}
