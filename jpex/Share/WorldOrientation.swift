import SwiftUI

/// Which way the World is turned on a shared picture, as two fingers turn it: the longitude at the
/// map's middle, and on the globe, how far it's tipped towards the north. Only maps drawn from the
/// World's own outlines turn, such as the World, the Seas, and a group of countries on the globe.
struct WorldOrientation: Equatable {
    /// Degrees east at the middle of the map.
    var longitude: Double
    /// Degrees towards the north the globe is tipped, from -90, looking up at the South Pole, to 90,
    /// looking down on the North Pole. Flat maps don't tip.
    var tilt: Double

    /// How the list's map is turned as it is, or nil where it can't turn, such as a country's map,
    /// or a group of countries framed close up on a flat World.
    init?(of map: TravelMap) {
        guard map.projection != nil, map.focusOverride == nil, let longitude = map.centerLongitude else { return nil }
        self.longitude = longitude
        tilt = MapProjection.globeTilt * 180 / .pi
    }

    /// Turned by two fingers moving across the map, a distance in the map's own units: on the globe
    /// the land under them follows them round and up or down; on a flat map, the map's whole width
    /// is a full turn, sideways only.
    func moved(by distance: CGSize, on map: TravelMap) -> WorldOrientation {
        var moved = self
        if map.isSphere {
            // The globe is a map unit across from its middle to its edge.
            moved.longitude -= distance.width * 180 / .pi
            moved.tilt = min(max(tilt + distance.height * 180 / .pi, -90), 90)
        } else {
            let width = map.outline?.boundingRect.width ?? map.size.width
            guard width > 0 else { return self }
            moved.longitude -= distance.width / width * 360
        }
        moved.longitude = remainder(moved.longitude, 360)
        return moved
    }

    /// The list's map turned this way, from lighter outlines while it moves, so it keeps up with the
    /// fingers, and in full detail at rest.
    @MainActor func map(of collectionID: String, projection: MapProjection, isMoving: Bool) -> TravelMap? {
        let geography = collectionID == CountryCatalog.seas.id ? Geography.subdivisions(of: collectionID) : Geography.world
        guard let geography else { return nil }
        if projection == .globe {
            return geography.globe(centerLongitude: longitude, tilt: tilt, isMoving: isMoving)
        }
        return isMoving
            ? geography.turningMap(projection, centerLongitude: longitude)
            : geography.map(projection, centerLongitude: longitude)
    }
}
