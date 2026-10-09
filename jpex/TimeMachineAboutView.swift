import SwiftUI

/// How Time Machine works and where its maps and flags come from.
struct TimeMachineAboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label {
                        Text("Drag along the scrubber to travel through history. Borders redraw themselves as each era arrives, and the cards beneath tell what changed. Tap a card to fly to it, or tap a place on the map to follow it through time.")
                    } icon: {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                    Label {
                        Text("Pinch or double-tap to zoom in on the map.")
                    } icon: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                } header: {
                    Text("Travelling")
                }
                Section {
                    Text("Historical borders are drawn from today’s lines, cut along old provinces where history’s borders ran through today’s countries. They are approximate, especially for small places and lands whose borders were never fixed.")
                    Text("Deep time follows published plate reconstructions, simplified so today’s coastlines can drift back to Pangaea. Real continents also grew, shrank and changed shape along the way.")
                } header: {
                    Text("About the maps")
                }
                Section {
                    NavigationLink("Historical flags") {
                        FlagCreditsView(title: "Historical Flags", resource: "HistoricalFlagCredits")
                    }
                } header: {
                    Text("Credits")
                }
            }
            .navigationTitle("Time Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
