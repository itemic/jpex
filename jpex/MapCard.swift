import SwiftUI

/// The collection's map at the top of its list. Tap a place to find it in the list; tap it again
/// once it's found, or tap the sea, and the map grows out of the card to fill the screen.
/// The list's total can sit over it as a badge, in whichever corner it hides the least of the map.
/// It isn't boxed in: it runs the page's whole width, its sea the page's own colour, and its land
/// fades away towards its edges, so the map reads as part of the page.
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
    /// The tallest the card grows at the map's own shape, which the list sets from the room it has:
    /// a fair share of a tall iPad page, less on a phone on its side.
    var maxHeight: CGFloat = MapCard.maximumHeight
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
    var onSelect: ((String) -> Void)? = nil
    var onOpen: () -> Void
    @AppStorage(MapProjection.storageKey) private var projection = MapProjection.standard
    @AppStorage(MapCenter.storageKey) private var center = MapCenter.standard
    @State private var spinner = WorldSpinner()
    @State private var selections = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.breaksOutOntoScreen) private var breaksOutOntoScreen
    @Environment(\.isBeneathWelcome) private var isBeneathWelcome

    static let maximumHeight: CGFloat = 260

    /// What a list's map does with a tap, said the same way on the card and on the map pinned
    /// beside the list, since both answer taps alike.
    static let findingHint = "Tap a place to find it in the list. Tap it again, or the sea, to open the map."

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

    /// Room at the page's sides, such as beneath a sidebar floating over it, that the map runs on
    /// under, like the rows, but isn't fitted into, so it's centred in the part of the page in view.
    private var mapInsets: EdgeInsets {
        EdgeInsets(top: 0, leading: horizontalSafeArea.leading, bottom: 0, trailing: horizontalSafeArea.trailing)
    }

    /// The part of the map's frame it's fitted into, which the full map grows out of and shrinks back to.
    private func fittedFrame(_ frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX + mapInsets.leading, y: frame.minY,
            width: max(frame.width - mapInsets.leading - mapInsets.trailing, 1), height: frame.height)
    }

    /// How far the badge keeps in from the page's edges, and the map's top and foot.
    private var controlInsets: EdgeInsets {
        EdgeInsets(
            top: 8, leading: 16 + horizontalSafeArea.leading, bottom: 8, trailing: 16 + horizontalSafeArea.trailing)
    }

    /// The corner of a map, drawn whole at `size` and fitted inside `insets`, whose badge-sized patch
    /// just inside them covers the least land, preferring the bottom leading corner, then the top
    /// ones, then the bottom trailing one. Land is sampled at a few points in each patch. Any map
    /// showing a badge can use it, such as the one pinned beside the fold.
    static func clearestCorner(
        of map: TravelMap, places: some Collection<String>, in size: CGSize, insets: EdgeInsets = EdgeInsets()
    ) -> Alignment {
        let patch = CGSize(width: min(110, size.width), height: min(44, size.height))
        let geometry = MapGeometry(focus: map.focusRect(including: places), size: size, zoom: 1, pan: .zero, insets: insets)
        func covered(_ corner: Alignment) -> Int {
            let x = corner.horizontal == .leading ? insets.leading : size.width - insets.trailing - patch.width
            let y = corner.vertical == .top ? insets.top : size.height - insets.bottom - patch.height
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
        let corners: [Alignment] = [.bottomLeading, .topTrailing, .topLeading, .bottomTrailing]
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

    /// The map's height at its own shape for a page of this width, not counting the space below it,
    /// and no taller than `maxHeight`.
    static func naturalHeight(
        of map: TravelMap, places: some Collection<String>, width: CGFloat, maxHeight: CGFloat = maximumHeight
    ) -> CGFloat {
        min(max(width, 1) / aspectRatio(of: map, places: places), maxHeight)
    }

    private var canvas: some View {
        MapJourneyView(journey: journey, minimumStatus: minimumStatus, insets: mapInsets) {
            // A globe drifting on its own needs far fewer frames than one turned by a finger.
            TimelineView(.animation(minimumInterval: spinner.isOnlyDrifting ? 1.0 / 24 : nil, paused: !spinner.isTurning)) { timeline in
                ZoomingMapCanvas(
                    map: (isWholeWorld ? spinner.turnedWorld(projection, at: timeline.date) : nil) ?? map, statuses: statuses,
                    minimumStatus: minimumStatus, insets: mapInsets, selection: selection, focus: focus, onTap: tap)
            }
        }
        // No card around it: the land fades away towards the edges into the page.
        .mask { EdgeFade() }
        .showsWorldLayers()
    }

    var body: some View {
        Group {
            if let height {
                canvas
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrameChange(fittedFrame($0)) }
            } else {
                // As tall as the map's own shape allows across the page, and the page's whole width,
                // the sea and its lines running on either side of the map.
                Color.clear
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: maxHeight)
                    .overlay {
                        canvas
                            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { onFrameChange(fittedFrame($0)) }
                    }
            }
        }
        .opacity(isHidden ? 0 : 1)
        // Around a map narrower than the card, a tap opens the map too.
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Map, \(counted) of \(statuses.count)")
        .accessibilityHint(onSelect == nil ? "Opens the map." : Self.findingHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default, onOpen)
        .sensoryFeedback(.selection, trigger: selections)
        // Over the card rather than in it, so the badge stays put while the map moves under it.
        // Taps pass through it to the map.
        .overlay {
            GeometryReader { proxy in
                if let badge {
                    // Sampled only while there's a badge to place.
                    let corner = Self.clearestCorner(of: map, places: statuses.keys, in: proxy.size, insets: mapInsets)
                    badge
                        .padding(controlInsets)
                        // Springs out of its corner, or with Reduce Motion, fades.
                        .transition(.arrive(reduceMotion: reduceMotion, anchor: corner.unitPoint))
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: corner)
                }
            }
            .opacity(isHidden ? 0 : 1)
            .allowsHitTesting(false)
            .animation(.snappy(duration: 0.3), value: badge == nil)
        }
        .turnsWorld(spinner, center: $center, isEnabled: isWholeWorld)
        // Left alone, a globe drifts slowly east, the way the Earth turns, but only while the list is
        // what's in front, not beneath the welcome, Settings or the quiz, where no one sees it.
        // Never while zoomed in on places, as when the pinned map shows the rows in view: drifting
        // would carry them out from under the camera.
        .driftsWorld(
            spinner, center: center,
            isEnabled: isWholeWorld && projection == .globe && !isHidden && focus.isEmpty && breaksOutOntoScreen)
        // Beneath the welcome, the World waits at its saved centre, where the welcome's own World
        // comes to rest as it lands on this one, so the two meet without a jump.
        .onChange(of: isBeneathWelcome, initial: true) { _, isBeneath in
            if isBeneath { spinner.reset() }
        }
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
        .padding(.bottom, 8)
    }
}

extension EnvironmentValues {
    /// Whether the welcome is showing over the lists, which the World card beneath waits out at its
    /// saved centre, so the welcome's World lands on it exactly.
    @Entry var isBeneathWelcome = false
}

/// The Map button in a list's toolbar. A plain tap opens the full map on the person's travels;
/// touching and holding offers its other layers, such as the Atlas, to open it on instead, so the
/// menu offers only those. VoiceOver offers each as an action too, since a long press is no way
/// to find them.
struct MapMenuButton: View {
    var layers: [MapLayer]
    /// Opens the full map, as a tap on the map's card does.
    var onOpen: () -> Void
    /// Opens the full map on one of the layers, such as the Atlas.
    var onOpenLayer: (MapLayer) -> Void

    /// What a list's Map button offers: everything the full map has on the World and on groups of
    /// countries, which share its facts and time zones, and the Atlas on any other map. The
    /// person's travels are left out, being what a plain tap opens.
    static func layers(listsCountries: Bool) -> [MapLayer] {
        (listsCountries ? MapLayer.all : MapLayer.everywhere).filter { $0 != .colouring(.travels) }
    }

    /// The action's name, read out by VoiceOver: "Open in Atlas", as a place's callout says it, and
    /// "Open time zones" and the like for the rest.
    private static func actionName(of layer: MapLayer) -> String {
        layer == .atlas ? "Open in Atlas" : "Open \(layer.name.lowercased())"
    }

    /// Says what touching and holding offers, naming time zones where they're among the layers.
    private var hint: String {
        layers.contains(.timeZones)
            ? "Opens the map. Touch and hold for the Atlas, time zones and other layers."
            : "Opens the map. Touch and hold to open it in the Atlas."
    }

    var body: some View {
        if layers.isEmpty {
            Button("Map", systemImage: "map", action: onOpen)
                .accessibilityHint("Opens the map.")
        } else {
            Menu {
                ForEach(layers) { layer in
                    Button(layer.name, systemImage: layer.symbolName) { onOpenLayer(layer) }
                }
            } label: {
                Label("Map", systemImage: "map")
            } primaryAction: {
                onOpen()
            }
            .accessibilityHint(hint)
            .accessibilityActions {
                ForEach(layers) { layer in
                    Button(Self.actionName(of: layer)) { onOpenLayer(layer) }
                }
            }
        }
    }
}

/// Where a list's map sits, chosen in the list's View menu: scrolling away with the list, held at
/// the top and shrinking to a strip as the list scrolls, or held at the top at its full size, with
/// the list scrolling beneath it.
enum MapPosition: String, CaseIterable, Identifiable {
    case scrolls
    case pinned
    case pinnedFullSize

    static let storageKey = "mapPosition"

    /// Before the map had three places to sit, pinning it was a switch. Whatever it was left at
    /// carries over: pinned stays pinned, shrinking as it always did.
    static var saved: MapPosition {
        UserDefaults.standard.bool(forKey: "mapPinnedToTop") ? .pinned : .scrolls
    }

    var id: Self { self }

    var name: String {
        switch self {
        case .scrolls: "Scroll with list"
        case .pinned: "Pin to top"
        case .pinnedFullSize: "Pin at full size"
        }
    }

    var symbolName: String {
        switch self {
        case .scrolls: "list.bullet.below.rectangle"
        case .pinned: "inset.filled.topthird.rectangle"
        case .pinnedFullSize: "inset.filled.tophalf.rectangle"
        }
    }

    /// Whether the map stays above the list instead of scrolling away with it.
    var isPinned: Bool { self != .scrolls }
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
    /// The levels the map shows: the latest, except while the camera flies in to a place that has
    /// just changed, when still the levels from before. Only ever set here, after a change has been
    /// seen, so the map never draws a new level early only to have it taken back a frame later.
    @State private var shownStatuses: [String: VisitLevel]?
    /// The latest levels, for the map to show once the camera has arrived.
    @State private var latestStatuses: [String: VisitLevel] = [:]
    @State private var isHolding = false
    @State private var focusedID: String?
    @State private var size: CGSize = .zero
    @State private var visit = 0

    /// How long the camera takes to fly in close to a small place that has just changed, before
    /// the change lands there.
    private static let approach = 0.45

    var body: some View {
        TravelMapCanvas(
            map: map, statuses: drawnStatuses, minimumStatus: minimumStatus,
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
        .onAppear {
            latestStatuses = statuses
            shownStatuses = statuses
        }
        .onChange(of: statuses) { old, new in
            latestStatuses = new
            let changed = new.keys.filter { old[$0]?.id != new[$0]?.id }
            if changed.count == 1, let id = changed.first {
                focus(on: id, before: old)
            } else if !isHolding {
                showLatest()
            }
        }
        .onChange(of: focus) {
            visit += 1
            showLatest()
            focusedID = nil
            // With Reduce Motion the camera is simply there, rather than zooming.
            withAnimation(Motion.travelling(.smooth(duration: 0.7), reduceMotion: reduceMotion)) { camera = restingCamera }
        }
    }

    /// The levels the map draws: those shown, while they're for the same places, or else the latest
    /// at once, as when the map turns to another list's places.
    private var drawnStatuses: [String: VisitLevel] {
        guard let shownStatuses, shownStatuses.count == statuses.count,
              shownStatuses.keys.allSatisfy({ statuses[$0] != nil })
        else { return statuses }
        return shownStatuses
    }

    /// Lets the map show the latest levels, ending any hold.
    private func showLatest() {
        isHolding = false
        shownStatuses = latestStatuses
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

    /// Flies in close to a place that has just changed, still in its old colour, lets the change
    /// land, then pulls back out. A place already large on the map changes on the whole map, simply
    /// outlined, the camera first pulling back out if an earlier change left it in close. Each change
    /// takes over from the one before, and every one ends with the camera back at rest, however
    /// quickly they come.
    private func focus(on id: String, before old: [String: VisitLevel]) {
        visit += 1
        let current = visit
        guard !reduceMotion, size != .zero, let region = map.region(id: id) else {
            showLatest()
            focusedID = nil
            camera = restingCamera
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
        let destination = target.zoom > 1.25 ? target : restingCamera
        let flies = destination != camera
        if flies {
            // Held back until the camera arrives, so the change lands in view. Quick, so a small
            // place's lift lands not long after a large one's, which lifts at once.
            isHolding = true
            shownStatuses = old
            withAnimation(.smooth(duration: Self.approach)) { camera = destination }
        } else {
            showLatest()
        }
        Task {
            if flies {
                // Once the camera has settled, so a place lifting off the map leaves from where it rests.
                try? await Task.sleep(for: .seconds(Self.approach))
                guard current == visit else { return }
                showLatest()
            }
            try? await Task.sleep(for: .seconds(1.3))
            guard current == visit else { return }
            if camera != restingCamera {
                withAnimation(Motion.pullBack) { camera = restingCamera }
                try? await Task.sleep(for: .seconds(0.8))
                guard current == visit else { return }
            }
            focusedID = nil
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

extension Alignment {
    /// The matching point, for scaling toward a corner.
    var unitPoint: UnitPoint {
        UnitPoint(
            x: horizontal == .leading ? 0 : horizontal == .trailing ? 1 : 0.5,
            y: vertical == .top ? 0 : vertical == .bottom ? 1 : 0.5)
    }
}
