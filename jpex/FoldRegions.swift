import SwiftUI

/// The two sides of the fold while iPhone Duo is partially folded, in a geometry proxy's space.
/// Things to look at go on the far side (the top when it sits like a laptop, the leading side when
/// it's held like a book), and things to touch on the near side.
struct FoldRegions: Equatable {
    var far: CGRect
    var near: CGRect
    /// Whether the fold runs across the screen, as when the device sits on a table.
    var isAcross: Bool

    /// Nil unless the device is partially folded through this space.
    init?(in proxy: GeometryProxy) {
        let size = proxy.size
        guard let crease = Self.crease(in: proxy), size.width > 1, size.height > 1 else { return nil }
        isAcross = crease.width >= crease.height
        if isAcross {
            far = CGRect(x: 0, y: 0, width: size.width, height: max(crease.minY, 0))
            near = CGRect(x: 0, y: crease.maxY, width: size.width, height: max(size.height - crease.maxY, 0))
        } else {
            far = CGRect(x: 0, y: 0, width: max(crease.minX, 0), height: size.height)
            near = CGRect(x: crease.maxX, y: 0, width: max(size.width - crease.maxX, 0), height: size.height)
        }
        // A fold at the very edge of this space leaves nothing to split.
        guard far.width > 120, far.height > 120, near.width > 120, near.height > 120 else { return nil }
    }

    /// The same fold in a space that has shrunk from the bottom, as when the keyboard is up: each
    /// side keeps to the room that's left.
    func fitted(to size: CGSize) -> FoldRegions {
        var regions = self
        regions.far.size.height = min(far.height, max(size.height - far.minY, 0))
        regions.near.size.height = min(near.height, max(size.height - near.minY, 0))
        return regions
    }

    /// The fold and the room to keep around it.
    private static func crease(in proxy: GeometryProxy) -> CGRect? {
        guard #available(iOS 27.1, *), let fold = proxy.reservedRegions(kind: .division).first else { return nil }
        return CGRect(
            x: fold.frame.minX - fold.margins.leading,
            y: fold.frame.minY - fold.margins.top,
            width: fold.frame.width + fold.margins.leading + fold.margins.trailing,
            height: fold.frame.height + fold.margins.top + fold.margins.bottom)
    }
}
