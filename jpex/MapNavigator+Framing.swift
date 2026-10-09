import SwiftUI

extension MapNavigator {
    /// Glides the camera to show part of the map with room around it, `margin` times its size on
    /// every side, kept within how far the map can zoom and pan.
    func frame(_ rect: CGRect, margin: CGFloat, animation: Animation?) {
        withAnimation(animation) {
            camera = geometry.camera(fitting: rect.insetBy(dx: -rect.width * margin, dy: -rect.height * margin))
            settleCamera(fling: .zero, animation: animation)
        }
    }

    /// Comes closer or pulls back around the middle of the view: a factor of 2 comes twice as close.
    func zoom(by factor: CGFloat, animation: Animation?) {
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
    /// quietly hops a whole lap back towards the middle, which looks just the same.
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
            // Pulling back past the whole map comes back around the middle of the view.
            let base = CGPoint(x: (area.midX - camera.pan.width) / camera.zoom, y: (area.midY - camera.pan.height) / camera.zoom)
            let pan = CGSize(width: area.midX - base.x * zoom + fling.width, height: area.midY - base.y * zoom + fling.height)
            let unpanned = MapGeometry(focus: current.focus, size: layout.size, zoom: zoom, pan: .zero, insets: layout.insets)
            let content = current.focus.applying(unpanned.transform)
            func clamp(_ value: CGFloat, start: CGFloat, length: CGFloat, middle: CGFloat) -> CGFloat {
                min(max(value, middle - (start + length)), middle - start)
            }
            camera = MapCamera(
                zoom: zoom,
                pan: CGSize(
                    width: period == nil ? clamp(pan.width, start: content.minX, length: content.width, middle: area.midX) : pan.width,
                    height: clamp(pan.height, start: content.minY, length: content.height, middle: area.midY)))
        }
    }
}
