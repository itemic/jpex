import SwiftUI

/// The middle of Time Machine: the map card on the front of the stack of earlier maps, and in deep
/// time, the globe. The map takes taps to show what a place was then, pinches and double taps to
/// zoom, and drags to pan once zoomed; the globe turns under a finger and glides when flicked.
struct TimeMachineStage: View {
    var model: TimeMachineModel
    /// Whether the screen and its map have flown in, for their entrance and exit.
    var isShown: Bool
    @State private var cardSize: CGSize = .zero
    @State private var pinchStart: HistoryCamera?
    @State private var panStart: CGSize?
    @State private var spinStart: GlobeSpin?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let card = cardFrame(in: proxy.size)
            ZStack(alignment: .topLeading) {
                if let atlas = model.atlas, let geometry = model.geometry {
                    TimeStack(eras: atlas.eras, position: model.position, cardFrame: card, silhouette: model.silhouette,
                              opacity: (1 - model.morph * 2).clamped01 * (isShown ? 1 : 0))
                    // The globe arrives, flat over the map, as travel to deep time begins, and stays
                    // until it has unrolled again on the way back.
                    if model.mode == .deepTime, let deepTime = atlas.deepTime, let mesh = model.mesh {
                        globe(atlas: atlas, geometry: geometry, deepTime: deepTime, mesh: mesh, card: card, size: proxy.size)
                    }
                    if model.mode == .history || model.isTravelling {
                        mapCard(atlas: atlas, geometry: geometry)
                            .frame(width: card.width, height: card.height)
                            .position(x: card.midX, y: card.midY)
                            .opacity((1 - model.morph * 5).clamped01)
                            .allowsHitTesting(model.mode == .history && !model.isTravelling)
                    }
                } else if model.loadFailed {
                    ContentUnavailableView("Time Machine isn’t available", systemImage: "clock.badge.exclamationmark",
                                           description: Text("Its maps couldn’t be loaded."))
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ProgressView()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
    }

    /// Where the map card sits: as large as the stage allows, a sliver of room above it for the
    /// stack of earlier maps. On a narrow screen it's taller than the world is wide for its width,
    /// and the map runs past its sides.
    private func cardFrame(in size: CGSize) -> CGRect {
        let bounds = model.geometry?.bounds ?? CGRect(x: 0, y: 0, width: 2, height: 1)
        let aspect = bounds.height > 0 ? bounds.width / bounds.height : 2
        var width = size.width - 12
        var height = min(width * HistoryMapGeometry.overflow / aspect, size.height - 44)
        if height * aspect < width {
            width = height * aspect
        }
        height = max(height, 0)
        return CGRect(x: (size.width - width) / 2, y: size.height - height - 6, width: max(width, 0), height: height)
    }

    // MARK: Globe

    private func globe(
        atlas: TimeMachineAtlas, geometry: HistoryMapGeometry, deepTime: DeepTime, mesh: GlobeMesh, card: CGRect, size: CGSize
    ) -> some View {
        DeepTimeGlobe(
            atlas: atlas, geometry: geometry, deepTime: deepTime, mesh: mesh, ma: model.ma, morph: model.morph,
            era: model.eraIndex, mapFrame: card, spin: model.spin)
        .frame(width: size.width, height: size.height)
        .scaleEffect(isShown || reduceMotion ? 1 : 0.6)
        .blur(radius: isShown || reduceMotion ? 0 : 12)
        .opacity(isShown ? 1 : 0)
        .contentShape(Rectangle())
        .gesture(globeDrag)
        .allowsHitTesting(!model.isTravelling)
        .accessibilityElement()
        .accessibilityLabel(model.ma < 0.5 ? "The Earth today" : "The Earth \(DeepTimeEventCard.spokenAge(model.ma))")
        .accessibilityValue(model.currentPeriod?.name ?? "")
    }

    /// Turning the globe by hand: it follows the finger, and glides on when flicked.
    private var globeDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if spinStart == nil {
                    let facing = model.spin.facing(at: .now, reduceMotion: reduceMotion)
                    var held = model.spin
                    held.longitude = facing.longitude
                    held.latitude = facing.latitude
                    held.isHeld = true
                    spinStart = held
                }
                guard let start = spinStart else { return }
                var spin = start
                spin.longitude = start.longitude - value.translation.width * 0.35
                spin.latitude = min(max(start.latitude + value.translation.height * 0.3, -70), 70)
                model.spin = spin
            }
            .onEnded { value in
                spinStart = nil
                var spin = model.spin
                spin.isHeld = false
                spin.velocity = reduceMotion ? 0 : -value.velocity.width * 0.35
                spin.since = .now
                model.spin = spin
            }
    }

    // MARK: Map card

    private func mapCard(atlas: TimeMachineAtlas, geometry: HistoryMapGeometry) -> some View {
        let era = model.eraIndex
        let pull = model.mode == .history ? model.leadingPull : 0
        let event = model.currentEra?.events.first { $0.id == model.focusedEventID }
        let calm = !model.isScrubbing
        return ZStack {
            HistoryMapCanvas(atlas: atlas, geometry: geometry, blends: model.blends, names: model.names,
                             position: model.position, camera: model.camera, age: pull.clamped01)
            HistoryMapOverlay(
                geometry: geometry, camera: model.camera,
                eventUnits: calm ? event.map { atlas.unitIndices(for: $0.unitIDs) } ?? [] : [],
                eventLocation: calm ? event?.location : nil,
                selectedUnits: selectedPlaceUnits(atlas: atlas, era: era))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        // The glow is a still shape behind the map, so it isn't redrawn as the map changes.
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.03, green: 0.05, blue: 0.12))
                .shadow(color: Color(red: 0.3, green: 0.6, blue: 1).opacity(0.35), radius: 24)
        }
        .overlay(alignment: .topLeading) {
            if let unit = model.selectedUnit {
                PlaceInspector(atlas: atlas, unit: unit, era: era) {
                    withAnimation(.smooth) { model.selectedUnit = nil }
                }
                .padding(6)
                .transition(.scale(scale: 0.85, anchor: .topLeading).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if model.camera.scale > 1.05 {
                Button("Show the whole world", systemImage: "arrow.down.right.and.arrow.up.left") {
                    withAnimation(.smooth(duration: 0.6)) { model.camera = .whole }
                }
                .labelStyle(.iconOnly)
                .font(.footnote.weight(.semibold))
                .frame(width: 34, height: 34)
                .glassPanel(in: Circle(), interactive: true)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .buttonStyle(.plain)
                .padding(3)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.3), value: model.camera.scale > 1.05)
        .animation(.smooth(duration: 0.3), value: model.selectedUnit)
        .onGeometryChange(for: CGSize.self) { $0.size } action: {
            cardSize = $0
            model.mapSize = $0
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { location in zoom(toggleAt: location) }
        .onTapGesture { location in select(at: location) }
        .gesture(SimultaneousGesture(magnify, pan))
        // Pulled past the first era, the map strains: trembling with each tick and sinking back.
        .offset(x: !reduceMotion && pull > 0.02 ? (model.pullTicks.isMultiple(of: 2) ? 1 : -1) * 4 * pull : 0)
        .scaleEffect(reduceMotion ? 1 : 1 - 0.08 * pull.clamped01)
        .animation(reduceMotion ? nil : .snappy(duration: 0.12), value: model.pullTicks)
        .scaleEffect(isShown || reduceMotion ? 1 : 1.35)
        .blur(radius: isShown || reduceMotion ? 0 : 18)
        .opacity(isShown ? 1 : 0)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.currentEra.map { "Map of the world, \($0.isToday ? "today" : String($0.year))" } ?? "Map")
        .accessibilityValue(model.currentEra?.summary ?? "")
        .accessibilityRotor("Places") {
            ForEach(places(atlas: atlas, era: era)) { place in
                AccessibilityRotorEntry(place.name, id: place.id) {
                    withAnimation(.smooth) { model.selectedUnit = place.unit }
                }
            }
        }
        .accessibilityZoomAction { action in
            switch action.direction {
            case .zoomIn: zoom(by: 2, at: CGPoint(x: cardSize.width / 2, y: cardSize.height / 2))
            case .zoomOut: withAnimation(.smooth(duration: 0.5)) { model.camera = .whole }
            @unknown default: break
            }
        }
    }

    /// Every unit of the place tapped, as it was in the era on show.
    private func selectedPlaceUnits(atlas: TimeMachineAtlas, era: Int) -> [Int] {
        guard let unit = model.selectedUnit, atlas.placements.indices.contains(era) else { return [] }
        let placements = atlas.placements[era]
        let chosen = placements[unit]
        return placements.indices.filter { placements[$0] == chosen }
    }

    /// One entry per place as it was in an era, such as French West Africa, for VoiceOver's rotor.
    private func places(atlas: TimeMachineAtlas, era: Int) -> [RotorPlace] {
        guard atlas.placements.indices.contains(era) else { return [] }
        var seen: Set<String> = []
        var places: [RotorPlace] = []
        for (unit, placement) in atlas.placements[era].enumerated() {
            let key = placement.polity + "|" + placement.label
            guard seen.insert(key).inserted else { continue }
            let polity = atlas.polity(placement.polity)
            let name = placement.label == polity.name ? polity.name : "\(placement.label), \(polity.name)"
            places.append(RotorPlace(id: key, unit: unit, name: name))
        }
        return places.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func select(at location: CGPoint) {
        guard let geometry = model.geometry else { return }
        let unit = geometry.unit(at: location, in: cardSize, camera: model.camera)
        withAnimation(.smooth(duration: 0.3)) {
            model.selectedUnit = unit == model.selectedUnit ? nil : unit
        }
    }

    private func zoom(toggleAt location: CGPoint) {
        guard model.camera.scale < 1.5 else {
            withAnimation(.smooth(duration: 0.5)) { model.camera = .whole }
            return
        }
        zoom(by: 3 / model.camera.scale, at: location)
    }

    /// Zooms by a factor, keeping the point under `location` where it is.
    private func zoom(by factor: CGFloat, at location: CGPoint) {
        let camera = model.camera
        let scale = min(max(camera.scale * factor, 1), 8)
        let center = CGPoint(x: cardSize.width / 2, y: cardSize.height / 2)
        let anchor = CGSize(width: location.x - center.x, height: location.y - center.y)
        let offset = CGSize(width: anchor.width - scale * (anchor.width - camera.offset.width) / camera.scale,
                            height: anchor.height - scale * (anchor.height - camera.offset.height) / camera.scale)
        withAnimation(.smooth(duration: 0.5)) {
            model.camera = HistoryCamera(scale: scale, offset: model.clamped(offset, scale: scale, size: cardSize))
        }
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? model.camera
                if pinchStart == nil { pinchStart = start }
                let scale = min(max(start.scale * value.magnification, 0.85), 8)
                let center = CGPoint(x: cardSize.width / 2, y: cardSize.height / 2)
                let anchor = CGSize(width: value.startLocation.x - center.x, height: value.startLocation.y - center.y)
                let offset = CGSize(width: anchor.width - scale * (anchor.width - start.offset.width) / start.scale,
                                    height: anchor.height - scale * (anchor.height - start.offset.height) / start.scale)
                model.camera = HistoryCamera(scale: scale, offset: offset)
            }
            .onEnded { _ in
                pinchStart = nil
                withAnimation(.smooth(duration: 0.4)) {
                    if model.camera.scale < 1.05 {
                        model.camera = .whole
                    } else {
                        model.camera.offset = model.clamped(model.camera.offset, scale: model.camera.scale, size: cardSize)
                    }
                }
            }
    }

    private var pan: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // A pinch moves the map itself; a drag carrying on after it picks up from there.
                guard pinchStart == nil else {
                    panStart = nil
                    return
                }
                guard model.mapOverflows(in: cardSize) || panStart != nil else { return }
                if panStart == nil {
                    panStart = CGSize(width: model.camera.offset.width - value.translation.width,
                                      height: model.camera.offset.height - value.translation.height)
                }
                guard let start = panStart else { return }
                model.camera.offset = CGSize(width: start.width + value.translation.width, height: start.height + value.translation.height)
            }
            .onEnded { _ in
                guard panStart != nil else { return }
                panStart = nil
                withAnimation(.smooth(duration: 0.4)) {
                    model.camera.offset = model.clamped(model.camera.offset, scale: model.camera.scale, size: cardSize)
                }
            }
    }
}

private struct RotorPlace: Identifiable {
    var id: String
    var unit: Int
    var name: String
}

/// The place tapped on the map, as it was in the era on show: its flag, what it was called and
/// who held it. It stays open while scrubbing, so a place can be followed through time.
private struct PlaceInspector: View {
    var atlas: TimeMachineAtlas
    var unit: Int
    var era: Int
    var onClose: () -> Void

    var body: some View {
        let placement = atlas.placements[era][unit]
        let polity = atlas.polity(placement.polity)
        HStack(spacing: 10) {
            HistoricalFlag(polity: polity, height: 24)
                .id(polity.id)
                .transition(.scale.combined(with: .opacity))
            VStack(alignment: .leading, spacing: 1) {
                Text(placement.label)
                    .font(.subheadline.weight(.semibold))
                if placement.label != polity.name {
                    Text(polity.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .contentTransition(.opacity)
            Button("Close", systemImage: "xmark", action: onClose)
                .labelStyle(.iconOnly)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
        }
        .padding(.leading, 10)
        .glassPanel(in: Capsule())
        .contentShape(Capsule())
        .animation(.smooth(duration: 0.3), value: placement)
        .accessibilityElement(children: .combine)
    }
}
