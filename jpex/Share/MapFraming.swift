import CoreGraphics

/// How a shared picture frames its map: all of it, just around the places the person has been,
/// just around those newly been to, or however they've pinched and dragged it, as a camera frames
/// a photo.
enum MapFraming: Equatable {
    case whole
    case travels
    case new
    case custom(CGRect)

    /// The part of the map this framing shows, in the map's own units, from the frames around the
    /// whole map, around the travels and around the newest places, worked out once.
    func focus(whole: CGRect, travels: CGRect?, new: CGRect?) -> CGRect {
        switch self {
        case .whole: whole
        case .travels: travels ?? whole
        case .new: new ?? travels ?? whole
        case .custom(let rect): rect
        }
    }

    /// The whole map, as the list shows it: the World, a country with its insets, or a group of
    /// countries on the World.
    static func wholeFocus(of map: TravelMap) -> CGRect {
        map.focusRect(including: [String]())
    }

    /// Around the main body of every place the person has been, or nil where that's no smaller than
    /// the whole map, such as travels spread across most of the World, or the World as a globe.
    static func travelsFocus(of map: TravelMap, statuses: [String: VisitLevel]) -> CGRect? {
        let visited = Set(statuses.filter { $0.value.id != VisitLevel.never.id }.keys)
        guard !visited.isEmpty, !map.isSphere else { return nil }
        let whole = wholeFocus(of: map)
        let around: CGRect
        if map.outline != nil {
            guard let members = map.focus(onMembers: visited) else { return nil }
            around = members
        } else {
            let bounds = map.regions.filter { visited.contains($0.id) }.map(\.coreBounds)
            guard var union = bounds.first else { return nil }
            for other in bounds.dropFirst() { union = union.union(other) }
            let margin = max(union.width, union.height) * 0.1
            around = union.insetBy(dx: -margin, dy: -margin)
        }
        // Never closer than a fifth of the whole map across, so one small place isn't blown up
        // past recognising, with the land around it in view.
        let least = max(whole.width, whole.height) * 0.2
        let framed = around.insetBy(
            dx: -max(0, least - around.width) / 2, dy: -max(0, least - around.height) / 2)
        guard framed.width < whole.width * 0.9 || framed.height < whole.height * 0.9 else { return nil }
        return framed
    }

    /// A pinched and dragged frame kept within reach of the map: no closer than a twenty-fifth of the
    /// whole map across, no further out than a little more than all of it, and centred on the map.
    static func clamped(_ rect: CGRect, within whole: CGRect) -> CGRect {
        let width = min(max(rect.width, whole.width / 25), whole.width * 1.3)
        let height = rect.height * (width / max(rect.width, 0.0001))
        let center = CGPoint(
            x: min(max(rect.midX, whole.minX), whole.maxX),
            y: min(max(rect.midY, whole.minY), whole.maxY))
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }
}
