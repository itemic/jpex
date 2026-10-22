import SwiftUI

/// The quick level picker, pointing at the place you tapped on the map: the kind of place it is in
/// small capitals, its name beside its flag with the level it's at beneath, a badge for every
/// level, and a way into its own map when it has one.
struct MapCallout: View {
    var division: AdministrativeDivision
    var groupName: String?
    var status: VisitLevel
    /// Ways into its own subdivisions, one for each level they're listed at.
    var collections: [CollectionSummary] = []
    var localLanguage: Bool
    /// Where the point sits along the card's width, in points.
    var pointerX: CGFloat
    var pointsDown: Bool
    var hasPointer: Bool
    /// The most room the card may take, past which what's beneath its badges scrolls.
    var maxHeight: CGFloat? = nil
    var onStatusChange: (VisitLevel) -> Void
    var onOpenCollection: (String) -> Void
    /// What the World's layers say about it, such as the side of the road it drives on.
    var facts: [MapFact] = []
    /// Where it's offered, outside the Atlas, opens the place's card in the Atlas.
    var onOpenAtlas: (() -> Void)? = nil

    var body: some View {
        LevelTapback(
            status: status, place: division, localLanguage: localLanguage, collections: collections,
            // One of the States is a State.
            eyebrow: groupName.map(Country.memberName(ofGroup:)),
            pointer: hasPointer ? CalloutPointer(x: pointerX, pointsDown: pointsDown) : nil,
            maxHeight: maxHeight,
            facts: facts, onSelect: onStatusChange, onOpenCollection: onOpenCollection, onOpenAtlas: onOpenAtlas)
    }
}

/// A rounded card with a small point toward the place it describes.
struct CalloutShape: Shape {
    static let pointerHeight: CGFloat = 10

    var pointerX: CGFloat
    var pointsDown: Bool
    var hasPointer = true
    var cornerRadius: CGFloat = 26

    var animatableData: CGFloat {
        get { pointerX }
        set { pointerX = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let height = hasPointer ? Self.pointerHeight : 0
        let body = CGRect(
            x: rect.minX, y: rect.minY + (pointsDown ? 0 : height),
            width: rect.width, height: rect.height - height)
        let card = Path(roundedRect: body, cornerRadius: cornerRadius, style: .continuous)
        guard hasPointer else { return card }
        let x = min(max(rect.minX + pointerX, rect.minX + cornerRadius + 10), rect.maxX - cornerRadius - 10)
        let base = pointsDown ? body.maxY - 1 : body.minY + 1
        let tip = pointsDown ? rect.maxY : rect.minY
        var pointer = Path()
        pointer.move(to: CGPoint(x: x - 12, y: base))
        pointer.addLine(to: CGPoint(x: x - 2.5, y: tip + (pointsDown ? -1.5 : 1.5)))
        pointer.addQuadCurve(to: CGPoint(x: x + 2.5, y: tip + (pointsDown ? -1.5 : 1.5)), control: CGPoint(x: x, y: tip))
        pointer.addLine(to: CGPoint(x: x + 12, y: base))
        pointer.closeSubpath()
        return card.union(pointer)
    }
}
