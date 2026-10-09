import SwiftUI

/// Game Mode's board: the map coloured with how each answer went, the places outside the round
/// veiled, and the game's lights on top. Pinch and drag to look closer; in Name It, double-tap to
/// zoom, and in Find It, a tap on a place answers at once. Pops up as the game opens. Only this
/// view follows the camera.
struct GameMapStage: View {
    var navigator: MapNavigator
    var statuses: [String: VisitLevel]
    var labels: [String: MapLabel]
    var veiled: Set<String>
    /// Changes along with the round's places, so the veil can cross-fade to its new shape.
    var veilID: String
    var ringed: Set<String>
    var spotlight: GameSpotlight?
    var flash: GameFlash?
    /// Where confetti last burst from, after finding a place, and how many times it has.
    var burstLocation: CGPoint
    var bursts: Int
    var isExpanded: Bool
    /// Whether a tap answers, as in Find It, rather than waiting to see if it's a double tap.
    var tapsAnswer: Bool
    /// The panel's frame when it floats over the map, so the map keeps clear of it.
    var panelFrame: CGRect
    var accessibilityLabel: String
    var accessibilityHint: String
    var onTap: (CGPoint) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { outer in
            let safe = outer.safeAreaInsets
            GeometryReader { proxy in
                let global = proxy.frame(in: .global)
                let bounds = CGRect(origin: .zero, size: proxy.size)
                let insets = clearInsets(safe: safe, global: global)
                let camera = navigator.camera
                let geometry = MapGeometry(
                    focus: navigator.current.focus, size: proxy.size, zoom: camera.zoom, pan: camera.pan, insets: insets)
                let fitArea = geometry.fitArea
                ZStack(alignment: .topLeading) {
                    layers(camera: camera, insets: insets)
                        .frame(width: bounds.width, height: bounds.height)
                        .contentShape(Rectangle())
                        .gesture(panAndZoom(origin: global.origin, center: CGPoint(x: fitArea.midX, y: fitArea.midY)))
                        .gesture(
                            SpatialTapGesture(count: 2).onEnded { value in
                                navigator.toggleZoom(at: value.location, animation: reduceMotion ? nil : .smooth(duration: 0.5))
                            },
                            including: tapsAnswer ? .subviews : .all)
                        .onTapGesture { location in onTap(location) }
                        .allowsHitTesting(isExpanded)
                        .accessibilityElement()
                        .accessibilityLabel(accessibilityLabel)
                        .accessibilityHint(accessibilityHint)
                        .accessibilityZoomAction { action in
                            navigator.zoom(
                                by: action.direction == .zoomIn ? 2 : 0.5, animation: reduceMotion ? nil : .smooth(duration: 0.4))
                        }
                    if let flash {
                        let anchor = geometry.toScreen(flash.anchor)
                        FlashBubble(flash: flash)
                            .position(x: anchor.x, y: anchor.y - 28)
                            .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
                            .id(flash.id)
                    }
                    CelebrationBurst(trigger: bursts, colors: MapGame.confettiColors, pieceCount: 30)
                        .frame(width: 300, height: 300)
                        .position(burstLocation)
                    LinearGradient(
                        colors: [Color(uiColor: .systemBackground).opacity(0.8), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: safe.top + 20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .onChange(of: MapLayout(size: proxy.size, insets: insets), initial: true) { _, layout in
                    navigator.updateLayout(layout)
                }
            }
            .ignoresSafeArea()
        }
        // The board pops up as the game opens, and drops away as it closes.
        .scaleEffect(isExpanded || reduceMotion ? 1 : 0.86)
        .opacity(isExpanded ? 1 : 0)
    }

    /// The map, the veil and the lights, each moving with the camera.
    private func layers(camera: MapCamera, insets: EdgeInsets) -> some View {
        let map = navigator.current.map
        let focus = navigator.current.focus
        return ZStack {
            TravelMapCanvas(
                map: map, statuses: statuses, minimumStatus: MapGame.ladder.levels[0],
                zoom: camera.zoom, pan: camera.pan, insets: insets, focus: focus, revealsOnAppear: false,
                labels: isExpanded ? labels : [:]
            )
            .environment(\.visitLadder, MapGame.ladder)
            GameMapGuides(
                map: map, focus: focus, zoom: camera.zoom, pan: camera.pan, insets: insets, veiled: veiled, ringed: ringed)
                .id(veilID)
                .transition(.opacity)
            GameMapOverlay(
                map: map, focus: focus, zoom: camera.zoom, pan: camera.pan, insets: insets, spotlight: spotlight, flash: flash)
        }
        .animation(.smooth(duration: 0.45), value: insets)
        .animation(.smooth(duration: 0.5), value: veilID)
    }

    /// Room kept clear for bars, the screen's edges, and the panel, whether it floats over the
    /// foot of the map or beside it.
    private func clearInsets(safe: EdgeInsets, global: CGRect) -> EdgeInsets {
        var insets = EdgeInsets(top: safe.top + 8, leading: safe.leading + 8, bottom: safe.bottom, trailing: safe.trailing + 8)
        guard !panelFrame.isEmpty, panelFrame.intersects(global) else { return insets }
        if panelFrame.width < global.width * 0.6, panelFrame.minX > global.midX {
            insets.trailing = max(insets.trailing, global.maxX - panelFrame.minX + 8)
        } else if panelFrame.minY > global.minY {
            insets.bottom = max(insets.bottom, global.maxY - panelFrame.minY + 8)
        }
        return insets
    }

    /// Pinch and drag to move the camera, carrying any fling when you let go.
    private func panAndZoom(origin: CGPoint, center: CGPoint) -> some Gesture {
        MagnifyGesture()
            .simultaneously(with: DragGesture(minimumDistance: 6, coordinateSpace: .global))
            .onChanged { value in
                let dragStart = value.second.map { CGPoint(x: $0.startLocation.x - origin.x, y: $0.startLocation.y - origin.y) }
                navigator.moveCamera(
                    magnification: value.first?.magnification ?? 1,
                    anchor: value.first?.startLocation ?? dragStart ?? center,
                    translation: value.second?.translation ?? .zero)
            }
            .onEnded { value in
                let fling = value.second.map {
                    CGSize(
                        width: ($0.predictedEndTranslation.width - $0.translation.width) * 0.6,
                        height: ($0.predictedEndTranslation.height - $0.translation.height) * 0.6)
                } ?? .zero
                navigator.settleCamera(fling: fling, animation: reduceMotion ? nil : .smooth(duration: 0.6))
            }
    }
}

/// The name of a place tapped by mistake, with its flag, floating over it in red glass.
private struct FlashBubble: View {
    var flash: GameFlash

    var body: some View {
        HStack(spacing: 6) {
            Image(flash.flagAssetName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 22, height: 15)
                .clipShape(.rect(cornerRadius: 3))
            Text(flash.name)
                .placeName(flash.language)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassPanel(in: Capsule(), tint: LevelColor.red.color)
        .fixedSize()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
