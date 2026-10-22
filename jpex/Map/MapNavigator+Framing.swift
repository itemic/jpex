import SwiftUI

extension MapNavigator {
    /// Glides the camera to show part of the map with room around it, `margin` times its size on
    /// every side, kept within how far the map can zoom and pan.
    /// On a World that runs on round, it goes the short way, to the copy of the part nearest the
    /// view, shifted round a frame before the glide sets off so the two never fold into one sweep
    /// the wrong way. With `panOver`, a part far off is flown to by way of an overview (see
    /// `glide(to:…)`); the quiz's board leaves it off, as it times its question to a single glide.
    /// It animates by itself with `animation`, so callers needn't wrap it. `alongside` changes what
    /// belongs with the arrival, such as a callout opening, on the last leg, as `focus(on:…)` does.
    func frame(
        _ rect: CGRect, margin: CGFloat, animation: Animation?, panOver: Bool = false,
        alongside: (@MainActor () -> Void)? = nil
    ) {
        let generation = beginGlide()
        cancelGesture()
        normaliseRotation()
        let shifted = bringRound(toward: rect)
        let target = settled(geometry.camera(fitting: rect.insetBy(dx: -rect.width * margin, dy: -rect.height * margin)))
        afterLapShift(shifted, animated: animation != nil) {
            self.performGlide(
                to: target, animation: animation, panOver: panOver, generation: generation, alongside: alongside)
        }
    }

    /// Glides the camera across, at the zoom it has, to put part of the map in the middle of the
    /// view, as when the Atlas steps to a neighbour already well in view: the map pans over to it
    /// rather than standing still, without coming closer or pulling back. Goes the short way round
    /// a World that runs on round, as `frame` does.
    /// Somewhere far off at a close zoom, it pulls out a little on the way, as `frame` does.
    func centre(on rect: CGRect, animation: Animation?) {
        let generation = beginGlide()
        cancelGesture()
        normaliseRotation()
        let shifted = bringRound(toward: rect)
        let target = settled(geometry.camera(centering: CGPoint(x: rect.midX, y: rect.midY), zoom: camera.zoom))
        afterLapShift(shifted, animated: animation != nil) {
            self.performGlide(to: target, animation: animation, panOver: true, generation: generation)
        }
    }

    /// Whether the Atlas can simply pan to part of the map at the zoom it has, rather than zoom:
    /// brought to the middle, it would be neither a speck, under 6% of the view on average across
    /// its two sides, nor spill well past it, more than 1.2 times the view along either side; and
    /// the camera can actually bring it near the middle. At the whole map, which never pans, the
    /// Atlas always comes in closer instead.
    func keepsZoom(showing rect: CGRect) -> Bool {
        guard !rect.isNull, !rect.isInfinite, camera.zoom > 1.05 else { return false }
        let near = nearestCopy(of: rect)
        let target = settled(geometry.camera(centering: CGPoint(x: near.midX, y: near.midY), zoom: camera.zoom))
        let landed = geometry(for: target)
        let area = landed.fitArea
        guard area.width > 0, area.height > 0 else { return false }
        let onScreen = near.applying(landed.transform)
        let across = onScreen.width / area.width
        let down = onScreen.height / area.height
        guard (across * down).squareRoot() >= 0.06, max(across, down) <= 1.2 else { return false }
        return area.insetBy(dx: area.width * 0.2, dy: area.height * 0.2)
            .contains(CGPoint(x: onScreen.midX, y: onScreen.midY))
    }

    /// Comes closer or pulls back around the middle of the view: a factor of 2 comes twice as close.
    func zoom(by factor: CGFloat, animation: Animation?) {
        cancelGlide()
        let area = geometry.fitArea
        withAnimation(animation) {
            moveCamera(magnification: factor, anchor: CGPoint(x: area.midX, y: area.midY), translation: .zero)
            settleLoosely(fling: .zero, animation: animation)
        }
    }

    /// The camera that fills the view with the map, cropping its sides rather than leaving empty
    /// bands above and below it, so places are as big as they can be at a glance.
    var fillingCamera: MapCamera {
        let focus = current.focus
        let fitted = MapGeometry(focus: focus, size: layout.size, zoom: 1, pan: .zero, insets: layout.insets)
        let area = fitted.fitArea
        guard focus.width > 0, focus.height > 0, fitted.fitScale > 0 else { return MapCamera() }
        let fill = max(area.width / focus.width, area.height / focus.height) / fitted.fitScale
        return fitted.camera(centering: CGPoint(x: focus.midX, y: focus.midY), zoom: min(max(fill, 1), 3))
    }

    /// Lets go of a pinch or drag without snapping the map back into the frame: it can be dragged
    /// up and down until its edge reaches the middle of the view, at any zoom from the whole map in.
    /// A map that wraps around, `wrapping` map units wide, slides sideways without end: the camera
    /// quietly hops a whole lap back towards the middle, which looks just the same. Only the quiz's
    /// board settles this way, and it always faces north, so its laps run straight across the screen.
    func settleLoosely(fling: CGSize, wrapping period: CGFloat? = nil, animation: Animation?) {
        cancelGesture()
        let area = geometry.fitArea
        if let period {
            let lap = period * geometry.fitScale * camera.zoom
            let unpanned = MapGeometry(focus: current.focus, size: layout.size, zoom: camera.zoom, pan: .zero, insets: layout.insets)
            let middle = current.focus.applying(unpanned.transform).midX
            let laps = ((middle + camera.pan.width - area.midX) / lap).rounded()
            if laps != 0, lap > 0 {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { camera.pan.width -= laps * lap }
            }
        }
        withAnimation(animation) {
            let zoom = min(max(camera.zoom, 1), maximumZoom)
            let rotation = camera.rotation
            // Pulling back past the whole map comes back around the middle of the view.
            let middle = CGPoint(x: area.midX, y: area.midY)
            let pan = geometry.camera(
                placing: geometry.toMap(middle), at: CGPoint(x: middle.x + fling.width, y: middle.y + fling.height),
                zoom: zoom, rotation: rotation
            ).pan
            let unpanned = MapGeometry(
                focus: current.focus, size: layout.size, zoom: zoom, pan: .zero, insets: layout.insets, rotation: rotation)
            let content = current.focus.applying(unpanned.transform)
            func clamp(_ value: CGFloat, start: CGFloat, length: CGFloat, middle: CGFloat) -> CGFloat {
                min(max(value, middle - (start + length)), middle - start)
            }
            camera = MapCamera(
                zoom: zoom,
                pan: CGSize(
                    width: period == nil ? clamp(pan.width, start: content.minX, length: content.width, middle: area.midX) : pan.width,
                    height: clamp(pan.height, start: content.minY, length: content.height, middle: area.midY)),
                rotation: rotation)
        }
    }
}
