import SwiftUI

/// The collection's map at the top of its list. Tap a place to find it in the list; tap it again
/// once it's found, or tap the sea, and the map grows out of the card to fill the screen.
/// The list's total can sit over it as a badge, in whichever corner it hides the least of the map.
struct MapCard: View {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    var minimumStatus: VisitLevel
    var counted: Int
    var horizontalSafeArea: EdgeInsets
    /// While the full-screen map stands in for the card, the card steps aside.
    var isHidden = false
    /// A place to outline, such as the one being given a level in the list.
    var selection: String? = nil
    /// A fixed height, as when pinned above the list and shrinking while it scrolls. The map stays
    /// centred and fitted within it. Otherwise the card takes the map's own shape.
    var height: CGFloat? = nil
    /// The list's total, shown small over the map.
    var badge: TravelTotalView? = nil
    /// Places to zoom in close to, such as those in view in the list. Empty shows the whole map.
    var focus: [String] = []
    /// The flight over from the list before, when this list has just taken its place.
    var journey: MapJourney? = nil
    /// Reports where the map is drawn, in global coordinates, for the full-screen map to grow out of.
    var onFrameChange: (CGRect) -> Void = { _ in }
    /// Counts each pull of the list past its top: the World spins round once, and other maps bounce.
    var nudges = 0
    /// A place tapped on the map. Without it, any tap opens the map.
    /// The floating Map button's action: straight to the full map, even while a tap on the card
    /// would grow it first. Nil does what a tap on the card does.
    var onOpenMap: (() -> Void)? = nil
    var onSelect: ((String) -> Void)? = nil
    var onOpen: () -> Void
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @AppStorage(DayNight.storageKey) private var showsDayNight = false
    @State private var spinner = WorldSpinner()
    @State private var selections = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether the map stays at the top of its list instead of scrolling away, set in Settings.
    static let pinnedKey = "mapPinnedToTop"

    static let maximumHeight: CGFloat = 260

    /// Whether this is the whole World, which turns under a sideways drag. A group of countries
    /// zoomed in on, such as the EU, stays put.
    private var isWholeWorld: Bool {
        map.focusOverride == nil && TravelMap.showsWorld(places: statuses.keys)
    }

    private var aspectRatio: CGFloat {
        Self.aspectRatio(of: map, places: statuses.keys)
    }

    private static func aspectRatio(of map: TravelMap, places: some Collection<String>) -> CGFloat {
        let focus = map.focusRect(including: places)
        guard focus.height > 0 else { return 1.6 }
        return max(focus.width / focus.height, 0.8)
    }

    /// Where the map sits within the card: all of it at a fixed height, or fitted to its own shape and centred.
    private func canvasRect(in size: CGSize) -> CGRect {
        guard height == nil else { return CGRect(origin: .zero, size: size) }
        let width = min(size.width, size.height * aspectRatio)
        let fitted = CGSize(width: width, height: width / aspectRatio)
        return CGRect(
            x: (size.width - fitted.width) / 2, y: (size.height - fitted.height) / 2,
            width: fitted.width, height: fitted.height)
    }

    /// The corner whose badge-sized patch covers the least land, preferring the bottom leading
    /// corner, then the top ones. The bottom trailing corner is the Map button's. Land is sampled at a few points in each patch.
    private func clearestCorner(in size: CGSize) -> Alignment {
        let patch = CGSize(width: min(110, size.width), height: min(44, size.height))
        let geometry = MapGeometry(focus: map.focusRect(including: statuses.keys), size: size, zoom: 1, pan: .zero)
        func covered(_ corner: Alignment) -> Int {
            let x = corner.horizontal == .leading ? 0 : size.width - patch.width
            let y = corner.vertical == .top ? 0 : size.height - patch.height
            var count = 0
            for column in 0..<6 {
                for row in 0..<3 {
                    let point = geometry.toMap(CGPoint(
                        x: x + patch.width * (CGFloat(column) + 0.5) / 6, y: y + patch.height * (CGFloat(row) + 0.5) / 3))
                    if map.regions.contains(where: { $0.bounds.contains(point) && $0.path.contains(point, eoFill: true) }) {
                        count += 1
                    }
                }
            }
            return count
        }
        // The bottom trailing corner holds the Map button.
        let corners: [Alignment] = [.bottomLeading, .topTrailing, .topLeading]
        let counts = corners.map(covered)
        return counts.indices.min { counts[$0] < counts[$1] }.map { corners[$0] } ?? .bottomLeading
    }

    /// A place tapped goes to whoever finds it in the list; the sea, or a card that only opens, opens the map.
    private func tap(_ placeID: String?) {
        spinner.touch()
        guard let placeID, let onSelect else {
            onOpen()
            return
        }
        selections += 1
        onSelect(placeID)
    }

    /// The map's height at its own shape for a card of this width, not counting the space below it.
    static func naturalHeight(of map: TravelMap, places: some Collection<String>, width: CGFloat) -> CGFloat {
        min(max(width - 32, 1) / aspectRatio(of: map, places: places), maximumHeight)
    }

    private var canvas: some View {
        MapJourneyView(journey: journey, minimumStatus: minimumStatus) {
            // A globe drifting on its own needs far fewer frames than one turned by a finger.
            TimelineView(.animation(minimumInterval: spinner.isOnlyDrifting ? 1.0 / 24 : nil, paused: !spinner.isTurning)) { timeline in
                ZoomingMapCanvas(
                    map: (isWholeWorld ? spinner.turnedWorld(projection, at: timeline.date) : nil) ?? map, statuses: statuses,
                    minimumStatus: minimumStatus, selection: selection, focus: focus, onTap: tap)
            }
        }
        // The sea fills the card, so it takes the card's rounded corners.
        .clipShape(.rect(cornerRadius: 18, style: .continuous))
        .environment(\.showsDayNight, showsDayNight)
    }

    var body: some View {
        Group {
            if let height {
                canvas
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrameChange($0) }
            } else {
                canvas
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrameChange($0) }
                    .frame(maxWidth: .infinity, maxHeight: Self.maximumHeight)
            }
        }
        .opacity(isHidden ? 0 : 1)
        // Around a map narrower than the card, a tap opens the map too.
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map, \(counted) of \(statuses.count)")
        .accessibilityHint("Opens the map.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onOpen)
        .sensoryFeedback(.selection, trigger: selections)
        // Over the card rather than in it, so the badge stays put while the map moves under it.
        // Taps pass through it to the map.
        .overlay {
            GeometryReader { proxy in
                let canvas = canvasRect(in: proxy.size)
                let corner = clearestCorner(in: canvas.size)
                if let badge {
                    badge
                        .padding(8)
                        .transition(.scale(scale: 0.6, anchor: corner.unitPoint).combined(with: .opacity))
                        .frame(width: canvas.width, height: canvas.height, alignment: corner)
                        .position(x: canvas.midX, y: canvas.midY)
                }
            }
            .opacity(isHidden ? 0 : 1)
            .allowsHitTesting(false)
            .animation(.snappy(duration: 0.3), value: badge == nil)
        }
        // The way to the full map floats in the bottom trailing corner, across from the count.
        .overlay {
            GeometryReader { proxy in
                let canvas = canvasRect(in: proxy.size)
                Button("Map", systemImage: "map") { (onOpenMap ?? onOpen)() }
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .glassPanel(in: Circle(), interactive: true)
                    .contentShape(Circle())
                    .buttonStyle(PillButtonStyle())
                    .padding(8)
                    .frame(width: canvas.width, height: canvas.height, alignment: .bottomTrailing)
                    .position(x: canvas.midX, y: canvas.midY)
                    .accessibilityLabel("Open Map")
            }
            .opacity(isHidden ? 0 : 1)
            .allowsHitTesting(!isHidden)
        }
        .turnsWorld(spinner, center: $center, isEnabled: isWholeWorld)
        // Left alone, a globe drifts slowly east, the way the Earth turns.
        // Never while zoomed in on places, as when the pinned map shows the rows in view: drifting
        // would carry them out from under the camera.
        .driftsWorld(spinner, center: center, isEnabled: isWholeWorld && projection == .globe && !isHidden && focus.isEmpty)
        // A place changing level, the full map taking the card's place, or another list's map
        // coming in, all stop the World turning on its own.
        .onChange(of: statuses) { spinner.touch() }
        .onChange(of: isHidden) { _, isHidden in
            if isHidden { spinner.reset() }
        }
        .onChange(of: isWholeWorld) { spinner.reset() }
        .keyframeAnimator(initialValue: 1.0, trigger: nudges) { card, scale in
            card.scaleEffect(scale, anchor: .top)
        } keyframes: { _ in
            // The World spins instead, and nothing moves with Reduce Motion on.
            SpringKeyframe(isWholeWorld || reduceMotion ? 1 : 1.035, duration: 0.16, spring: .snappy)
            SpringKeyframe(1.0, duration: 0.5, spring: .bouncy(extraBounce: 0.25))
        }
        .onChange(of: nudges) {
            guard isWholeWorld, !reduceMotion else { return }
            spinner.spinAround(from: center)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: nudges)
        .padding(.horizontal)
        .padding(.leading, horizontalSafeArea.leading)
        .padding(.trailing, horizontalSafeArea.trailing)
        .padding(.bottom, 8)
    }
}

/// A small map that, when one of its places changes level, glides in close to it still in its old
/// colour, lets the new colour flood in, then pulls back out to the whole map.
struct ZoomingMapCanvas: View {
    var map: TravelMap
    var statuses: [String: VisitLevel]
    var minimumStatus: VisitLevel
    var insets = EdgeInsets()
    var selection: String?
    /// Places to settle in close to, rather than showing the whole map.
    var focus: [String] = []
    /// A tap on the map, with the place under it, if any. Without it, taps go to the views around.
    var onTap: ((String?) -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var camera = MapCamera()
    /// The levels still shown while the camera flies in, before the change lands.
    @State private var heldStatuses: [String: VisitLevel]?
    @State private var focusedID: String?
    @State private var size: CGSize = .zero
    @State private var visit = 0

    var body: some View {
        TravelMapCanvas(
            map: map, statuses: heldStatuses ?? statuses, minimumStatus: minimumStatus,
            zoom: camera.zoom, pan: camera.pan, insets: insets, focus: map.focusRect(including: statuses.keys),
            selection: selection ?? focusedID
        )
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .modifier(PlaceTapping(isEnabled: onTap != nil) { location in
            // Found where the camera is now, zoomed in close or out on the whole map.
            let geometry = MapGeometry(
                focus: map.focusRect(including: statuses.keys), size: size, zoom: camera.zoom, pan: camera.pan,
                insets: insets)
            onTap?(map.place(at: location, geometry: geometry, among: Set(statuses.keys))?.id)
        })
        .onChange(of: statuses) { old, new in
            let changed = new.keys.filter { old[$0]?.id != new[$0]?.id }
            guard changed.count == 1, let id = changed.first else { return }
            focus(on: id, before: old)
        }
        .onChange(of: focus) {
            visit += 1
            heldStatuses = nil
            focusedID = nil
            withAnimation(.smooth(duration: 0.7)) { camera = restingCamera }
        }
    }

    /// Where the camera settles: on the focused places, or out on the whole map.
    private var restingCamera: MapCamera {
        let regions = focus.compactMap { map.region(id: $0) }
        guard size != .zero, let first = regions.first else { return MapCamera() }
        let bounds = regions.dropFirst().reduce(first.coreBounds) { $0.union($1.coreBounds) }
        let reach = max(bounds.width, bounds.height)
        let geometry = MapGeometry(
            focus: map.focusRect(including: statuses.keys), size: size, zoom: 1, pan: .zero, insets: insets)
        let target = geometry.camera(fitting: bounds.insetBy(dx: -reach * 0.2, dy: -reach * 0.2))
        guard target.zoom > 1 else { return MapCamera() }
        guard target.zoom > 6 else { return target }
        return geometry.camera(centering: CGPoint(x: bounds.midX, y: bounds.midY), zoom: 6)
    }

    private func focus(on id: String, before old: [String: VisitLevel]) {
        visit += 1
        let current = visit
        guard !reduceMotion, size != .zero, let region = map.region(id: id) else {
            heldStatuses = nil
            return
        }
        let geometry = MapGeometry(
            focus: map.focusRect(including: statuses.keys), size: size, zoom: 1, pan: .zero, insets: insets)
        let core = region.coreBounds
        let reach = max(core.width, core.height)
        var target = geometry.camera(fitting: core.insetBy(dx: -reach * 1.3, dy: -reach * 1.3))
        if target.zoom > 6 {
            target = geometry.camera(centering: CGPoint(x: core.midX, y: core.midY), zoom: 6)
        }
        focusedID = id
        // A place already large on the map is simply outlined while it changes.
        guard target.zoom > 1.25 else {
            heldStatuses = nil
            release(after: 1.4, visit: current)
            return
        }
        heldStatuses = old
        withAnimation(.smooth(duration: 0.65)) { camera = target }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            guard current == visit else { return }
            heldStatuses = nil
            try? await Task.sleep(for: .seconds(1.3))
            guard current == visit else { return }
            withAnimation(.smooth(duration: 0.8)) { camera = restingCamera }
            release(after: 0.8, visit: current)
        }
    }

    private func release(after delay: Double, visit current: Int) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            if current == visit { focusedID = nil }
        }
    }
}

/// Taps on a map, at their point on it, when something wants them.
private struct PlaceTapping: ViewModifier {
    var isEnabled: Bool
    var action: (CGPoint) -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
        } else {
            content
        }
    }
}

private extension Alignment {
    /// The matching point, for scaling toward a corner.
    var unitPoint: UnitPoint {
        UnitPoint(
            x: horizontal == .leading ? 0 : horizontal == .trailing ? 1 : 0.5,
            y: vertical == .top ? 0 : vertical == .bottom ? 1 : 0.5)
    }
}
