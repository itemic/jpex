import SwiftUI

/// The quiz board: the map coloured with how each answer went, the places outside the round
/// veiled, and the quiz's lights on top. Pinch and drag to look closer, past the map's edges if
/// you like; double-tap to zoom, except in Find and Learn, where a tap chooses a place. The
/// World wraps around: copies of it sit either side, so dragging sideways never reaches an edge.
/// Places twinkling in the lobby have their names float just above them, never over one another.
/// While iPhone Duo is partly folded, the map carries on under the near side, its camera keeping
/// to the far side. The World can be turned beneath the camera, so a place across its edge sits
/// whole. Pops up as the quiz opens. Only this view follows the camera.
struct GameMapStage: View {
    var navigator: MapNavigator
    /// The map to draw in place of the navigator's, such as the World turned to keep a place whole,
    /// in the same frame of reference as the navigator's, so the camera carries on as it was.
    var map: TravelMap?
    var statuses: [String: VisitLevel]
    var labels: [String: MapLabel]
    var veiled: Set<String>
    /// Changes along with the round's places, so the veil can cross-fade to its new shape.
    var veilID: String
    var ringed: Set<String>
    /// Regions of places already tried for this question in Find, faded out.
    var tried: Set<String>
    /// Regions drawn as plain land with no borders, as Dot shows the map.
    var plain: Set<String> = []
    /// The places lit up: one at a time while playing, or several twinkling at once in the lobby.
    var spotlights: [GameSpotlight]
    var flash: GameFlash?
    /// The map's width in map units when it wraps around, as a rectangular World does.
    var wrapPeriod: CGFloat?
    var isExpanded: Bool
    /// Whether a tap answers, as in Find, rather than waiting to see if it's a double tap.
    var tapsAnswer: Bool
    /// The panel's frame when it floats over the map, so the map keeps clear of it.
    var panelFrame: CGRect
    /// While iPhone Duo is partly folded, the far side of the fold, in global coordinates: the map
    /// still fills the screen, but the camera frames places within this side.
    var farSide: CGRect?
    var accessibilityLabel: String
    var accessibilityValue: String
    var accessibilityHint: String
    var onTap: (CGPoint) -> Void
    /// Called as the camera is moved by hand, with a pinch, a drag or a double tap.
    var onMove: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Each twinkle caption's size, by when its twinkle began, for keeping it on screen and clear of the others.
    @State private var captionSizes: [Date: CGSize] = [:]

    var body: some View {
        GeometryReader { outer in
            let safe = outer.safeAreaInsets
            GeometryReader { proxy in
                let global = proxy.frame(in: .global)
                let bounds = CGRect(origin: .zero, size: proxy.size)
                let insets = clearInsets(safe: safe, global: global, focus: navigator.current.focus)
                let camera = navigator.camera
                let geometry = MapGeometry(
                    focus: navigator.current.focus, size: proxy.size, zoom: camera.zoom, pan: camera.pan, insets: insets)
                let fitArea = geometry.fitArea
                // One copy of the World across the screen, at the camera's zoom.
                let lap = (wrapPeriod ?? 0) * geometry.fitScale * camera.zoom
                ZStack(alignment: .topLeading) {
                    layers(camera: camera, insets: insets, lap: lap)
                        .frame(width: bounds.width, height: bounds.height)
                        .contentShape(Rectangle())
                        .gesture(panAndZoom(origin: global.origin, center: CGPoint(x: fitArea.midX, y: fitArea.midY)))
                        // Where a tap answers, a double tap isn't waited for: Find reads two taps as an answer itself.
                        .gesture(
                            SpatialTapGesture(count: 2).onEnded { value in
                                onMove()
                                navigator.toggleZoom(at: value.location, animation: reduceMotion ? nil : .smooth(duration: 0.5))
                            },
                            including: tapsAnswer ? .subviews : .all)
                        .onTapGesture { location in onTap(location) }
                        .allowsHitTesting(isExpanded)
                        .accessibilityElement()
                        .accessibilityLabel(accessibilityLabel)
                        .accessibilityValue(accessibilityValue)
                        .accessibilityHint(accessibilityHint)
                        .accessibilityZoomAction { action in
                            onMove()
                            navigator.zoom(
                                by: action.direction == .zoomIn ? 2 : 0.5, animation: reduceMotion ? nil : .smooth(duration: 0.4))
                        }
                    ForEach(captionPlacements(geometry: geometry, fitArea: fitArea, lap: lap), id: \.start) { placement in
                        TwinkleCaption(caption: placement.caption, start: placement.start)
                            .onGeometryChange(for: CGSize.self) { $0.size } action: { captionSizes[placement.start] = $0 }
                            .position(placement.point)
                    }
                    if let flash {
                        let anchor = nearest(geometry.toScreen(flash.anchor), to: fitArea.midX, lap: lap)
                        FlashBubble(flash: flash)
                            .position(x: anchor.x, y: anchor.y - 28)
                            .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
                            .id(flash.id)
                    }
                    LinearGradient(
                        colors: [Color(uiColor: .systemBackground).opacity(0.8), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: safe.top + 20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .onChange(of: MapLayout(size: proxy.size, insets: insets), initial: true) { _, layout in
                    navigator.updateLayout(layout)
                }
                .onChange(of: spotlights.compactMap(\.start)) { _, starts in
                    captionSizes = captionSizes.filter { starts.contains($0.key) }
                }
            }
            .ignoresSafeArea()
        }
        // The board pops up as the game opens, and drops away as it closes.
        .scaleEffect(isExpanded || reduceMotion ? 1 : 0.86)
        .opacity(isExpanded ? 1 : 0)
    }

    /// The map, the veil and the lights, each moving with the camera; on a wrapping World, a copy
    /// either side too. Each copy is panned a lap further, which stays exact as the camera glides
    /// because a lap grows in step with the zoom.
    private func layers(camera: MapCamera, insets: EdgeInsets, lap: CGFloat) -> some View {
        let map = self.map ?? navigator.current.map
        let focus = navigator.current.focus
        return ZStack {
            // The middle copy comes first and paints the sea for them all.
            ForEach(lap > 0 ? [0, -1, 1] : [0], id: \.self) { copy in
                let pan = CGSize(width: camera.pan.width + CGFloat(copy) * lap, height: camera.pan.height)
                ZStack {
                    TravelMapCanvas(
                        map: map, statuses: statuses, minimumStatus: MapGame.ladder.levels[0],
                        zoom: camera.zoom, pan: pan, insets: insets, focus: focus, revealsOnAppear: false,
                        labels: isExpanded ? labels : [:], drawsBackdrop: copy == 0, wrapsAround: lap > 0, tiles: false,
                        // An answer shown, or run out of time for, blends in quietly; only one earned celebrates.
                        quietLevelIDs: [MapGame.shownLevelID]
                    )
                    .environment(\.visitLadder, MapGame.ladder)
                    GameMapGuides(
                        map: map, focus: focus, zoom: camera.zoom, pan: pan, insets: insets, veiled: veiled, ringed: ringed,
                        tried: tried, plain: plain)
                        .id(veilID)
                        .transition(.opacity)
                    GameMapOverlay(
                        map: map, focus: focus, zoom: camera.zoom, pan: pan, insets: insets,
                        spotlights: spotlights, flash: flash, labels: isExpanded ? labels : [:],
                        wrapsAround: lap > 0)
                }
            }
        }
        .animation(.smooth(duration: 0.45), value: insets)
        .animation(.smooth(duration: 0.5), value: veilID)
    }

    /// On a wrapping World, the copy of a point nearest the middle of the view.
    private func nearest(_ point: CGPoint, to middle: CGFloat, lap: CGFloat) -> CGPoint {
        guard lap > 0 else { return point }
        return CGPoint(x: point.x - ((point.x - middle) / lap).rounded() * lap, y: point.y)
    }

    /// Where each twinkling place's name floats: just above the place, or just below it where
    /// there's no room above, kept in the clear part of the view. The oldest twinkles claim their
    /// room first; a name with nowhere clear of the others to go is left out.
    private func captionPlacements(geometry: MapGeometry, fitArea: CGRect, lap: CGFloat) -> [CaptionPlacement] {
        var placements: [CaptionPlacement] = []
        let twinkles = spotlights
            .compactMap { spotlight in spotlight.caption.flatMap { caption in spotlight.start.map { (caption, $0) } } }
            .sorted { $0.1 < $1.1 }
        for (caption, start) in twinkles {
            // Before a name has been measured, a fair guess at its size.
            let size = captionSizes[start]
                ?? CGSize(width: CGFloat(caption.name.count) * 11 + (caption.flagAssetName == nil ? 0 : 31), height: 26)
            let box = caption.frame.applying(geometry.transform)
            let top = nearest(CGPoint(x: box.midX, y: box.minY), to: fitArea.midX, lap: lap)
            let above = CGPoint(x: top.x, y: top.y - 8 - size.height / 2)
            let below = CGPoint(x: top.x, y: top.y + box.height + 8 + size.height / 2)
            let candidates = above.y - size.height / 2 >= fitArea.minY + 10 ? [above, below] : [below, above]
            for candidate in candidates {
                let point = onScreen(candidate, size: size, in: fitArea)
                let rect = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height)
                guard !placements.contains(where: { $0.rect.insetBy(dx: -8, dy: -4).intersects(rect) }) else { continue }
                placements.append(CaptionPlacement(caption: caption, start: start, point: point, rect: rect))
                break
            }
        }
        return placements
    }

    /// Where to centre a twinkle caption so all of it stays in the clear part of the view, away
    /// from the bars, the screen's edges and the card.
    private func onScreen(_ point: CGPoint, size: CGSize, in area: CGRect) -> CGPoint {
        let halfWidth = size.width / 2 + 6
        let halfHeight = size.height / 2 + 10
        guard area.width > halfWidth * 2, area.height > halfHeight * 2 else { return point }
        return CGPoint(
            x: min(max(point.x, area.minX + halfWidth), area.maxX - halfWidth),
            y: min(max(point.y, area.minY + halfHeight), area.maxY - halfHeight))
    }

    /// Room kept clear for bars, the screen's edges, and the panel, whether it floats over the
    /// foot of the map or beside it; on iPhone Duo partly folded, everything but the far side.
    private func clearInsets(safe: EdgeInsets, global: CGRect, focus: CGRect) -> EdgeInsets {
        var insets = EdgeInsets(top: safe.top + 8, leading: safe.leading + 8, bottom: safe.bottom, trailing: safe.trailing + 8)
        if let farSide, farSide.intersects(global) {
            insets.top = max(insets.top, farSide.minY - global.minY + 8)
            insets.leading = max(insets.leading, farSide.minX - global.minX + 8)
            insets.bottom = max(insets.bottom, global.maxY - farSide.maxY + 8)
            insets.trailing = max(insets.trailing, global.maxX - farSide.maxX + 8)
            return insets
        }
        guard !panelFrame.isEmpty, panelFrame.intersects(global) else { return insets }
        // The map keeps to whichever side of the panel lets it be drawn largest: above it when
        // the panel spans the foot of the screen, beside it when the panel stands to one side.
        var sides: [EdgeInsets] = []
        if panelFrame.minY > global.minY + 40 {
            var above = insets
            above.bottom = max(insets.bottom, global.maxY - panelFrame.minY + 8)
            sides.append(above)
        }
        if panelFrame.minX > global.minX + 40 {
            var before = insets
            before.trailing = max(insets.trailing, global.maxX - panelFrame.minX + 8)
            sides.append(before)
        }
        if panelFrame.maxX < global.maxX - 40 {
            var after = insets
            after.leading = max(insets.leading, panelFrame.maxX - global.minX + 8)
            sides.append(after)
        }
        func scale(_ side: EdgeInsets) -> CGFloat {
            let width = global.width - side.leading - side.trailing
            let height = global.height - side.top - side.bottom
            guard width > 0, height > 0, focus.width > 0, focus.height > 0 else { return 0 }
            return min(width / focus.width, height / focus.height)
        }
        return sides.max { scale($0) < scale($1) } ?? insets
    }

    /// Pinch and drag to move the camera, carrying any fling when you let go. The map doesn't snap
    /// back to its edges, so you can drag it wherever you need it.
    private func panAndZoom(origin: CGPoint, center: CGPoint) -> some Gesture {
        MagnifyGesture()
            .simultaneously(with: DragGesture(minimumDistance: 6, coordinateSpace: .global))
            .onChanged { value in
                onMove()
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
                navigator.settleLoosely(fling: fling, wrapping: wrapPeriod, animation: reduceMotion ? nil : .smooth(duration: 0.6))
            }
    }
}

/// A twinkling place's name, and where it floats on screen.
private struct CaptionPlacement {
    var caption: GameSpotlight.Caption
    var start: Date
    var point: CGPoint
    var rect: CGRect
}

/// A twinkling place's name, floating just above it in the lobby: its flag, where it has one of
/// its own, and its name set large in rounded bold on a soft halo, so it reads over the map like a
/// label on a chart. It fades in and out with the twinkle, drifting gently upwards as it goes; with
/// Reduce Motion it only fades.
private struct TwinkleCaption: View {
    var caption: GameSpotlight.Caption
    var start: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { context in
            let progress = min(max(context.date.timeIntervalSince(start) / GameSpotlight.twinkleDuration, 0), 1)
            // The same rise and fall as the twinkle's light.
            let envelope = sin(.pi * progress)
            label
                .scaleEffect(reduceMotion ? 1 : 0.94 + 0.06 * envelope, anchor: .bottom)
                .offset(y: reduceMotion ? 0 : 7 - 14 * progress)
                .opacity(envelope)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var label: some View {
        let halo = Color(uiColor: .systemBackground)
        return HStack(spacing: 7) {
            if let flag = caption.flagAssetName {
                Image(flag)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 16)
            }
            Text(caption.name)
                .placeName(caption.language, kerning: -0.4)
                .font(.title2.weight(PlaceTypesetting.weight(.light, for: caption.language)))
                .fontDesign(.default)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        // A light name needs a firmer halo to read over land.
        .shadow(color: halo, radius: 1)
        .shadow(color: halo, radius: 2)
        .shadow(color: halo.opacity(0.9), radius: 4)
        .shadow(color: halo.opacity(0.7), radius: 12)
        .fixedSize()
    }
}

/// The name of a place tapped by mistake, with its flag, floating over it in red glass.
private struct FlashBubble: View {
    var flash: GameFlash

    var body: some View {
        HStack(spacing: 6) {
            Image(flash.flagAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 15)
            Text(flash.name)
                .placeName(flash.language)
                .font(.subheadline.weight(PlaceTypesetting.weight(.regular, for: flash.language)))
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
