import SwiftUI

extension TravelMap {
    /// For a list of one place's own subdivisions, such as Tasmania's local government areas, its
    /// places as they lie on its country's map, for flying between the two: the camera dives into
    /// the place there and the subdivisions trace themselves in over it, as a country's do over the
    /// World. Inset copies, such as inner Sydney's, come along, already out at sea where their box
    /// will be, so each place keeps one shape as it settles into its own map. Nil for a map without a
    /// transform onto its country's.
    var placedOnParent: TravelMap? {
        guard let parentTransform else { return nil }
        let placed = regions.map { region in
            let path = region.path.applying(parentTransform)
            return MapRegion(
                id: region.id, path: path, bounds: path.boundingRect, center: region.center.applying(parentTransform))
        }
        return placed.isEmpty ? nil : TravelMap(size: size, regions: placed, frames: [])
    }
}
