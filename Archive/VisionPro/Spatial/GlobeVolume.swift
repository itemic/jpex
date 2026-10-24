#if os(visionOS)
import RealityKit
import SwiftData
import SwiftUI

/// The World as a globe in a volume of its own, floating in the room beside the lists: each country
/// in the colour of its level, as on the World map, turning slowly east as the Earth does. A pinch
/// and drag spins it; let go, and it carries on at the hand's speed until it eases back to its own
/// pace. The World's count sits beneath it, and both keep up as places change level in the lists.
struct GlobeVolume: View {
    @Environment(CountingPreferences.self) private var counting
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.physicalMetrics) private var metrics
    @Query private var saveModels: [SaveModel]
    @State private var globe = GlobeEntity()

    var body: some View {
        let snapshot = SaveModel.kept(of: saveModels)?.snapshot()
        let world = CountryCatalog.world(applying: counting.rules)
        let statuses = Dictionary(uniqueKeysWithValues: world.divisions.map { ($0.id, snapshot?.status(for: $0) ?? .never) })
        let counted = snapshot?.count(in: world.divisions, counting: counting.rules) ?? 0
        RealityView { content in
            content.add(globe)
        } update: { _ in
            globe.reducesMotion = reduceMotion
        }
        .gesture(spin)
        .task(id: statuses) {
            // Levels given one after another, as down a list, paint once they've settled.
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled, let image = GlobeTexture.image(statuses: statuses) else { return }
            await globe.paint(image)
        }
        .onChange(of: counted, initial: true) {
            globe.describe(counted: counted, of: world.divisions.count)
        }
        .ornament(attachmentAnchor: .scene(.bottomFront)) {
            SpatialMapLabel(title: world.listTitle, counted: counted, total: world.divisions.count)
        }
    }

    /// Spins the globe under a pinch and drag, or catches it with a pinch.
    private var spin: some Gesture {
        DragGesture(minimumDistance: 0)
            .targetedToAnyEntity()
            .onChanged { drag in
                globe.turn(by: Float(drag.translation.width), across: width)
            }
            .onEnded { drag in
                globe.letGo(speed: Float(drag.velocity.width), across: width)
            }
    }

    /// How wide the globe looks, in points.
    private var width: Float {
        Float(metrics.convert(CGFloat(GlobeEntity.radius * 2), from: .meters))
    }
}
#endif
