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
            settleCamera(fling: .zero, animation: animation)
        }
    }
}
