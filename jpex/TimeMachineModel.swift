import SwiftUI

/// Where Time Machine is in time and what it's showing: a position through history's eras, or in
/// deep time, how many millions of years ago; how far the person has pulled past either end; and
/// the travel between history and deep time.
@Observable
@MainActor
final class TimeMachineModel {
    enum Mode {
        case history, deepTime
    }

    private(set) var atlas: TimeMachineAtlas?
    private(set) var geometry: HistoryMapGeometry?
    private(set) var mesh: GlobeMesh?
    /// The world's land in white, for the stacked maps behind the one in front.
    private(set) var silhouette: Image?
    private(set) var loadFailed = false
    @ObservationIgnored let blends = EraBlendCache()
    @ObservationIgnored let names = MapNameCache()

    /// Which time the controls work in. It changes as travel begins and ends.
    private(set) var mode: Mode = .history
    /// Which time the header, cards and scrubber show. It changes halfway through travel, as the
    /// map turns into the globe or back, so the screen changes with it.
    private(set) var presentedMode: Mode = .history
    /// Through history's eras: 0 at the first, one more for each era after, fractions between.
    var position: Double = 0 {
        didSet {
            let era = min(max(Int(position.rounded()), 0), max(eraCount - 1, 0))
            guard era != eraIndex else { return }
            eraIndex = era
            if !isQuiet { eraTicks += 1 }
        }
    }
    /// The era nearest the knob.
    private(set) var eraIndex = 0
    /// In deep time, millions of years ago.
    var ma: Double = 0 {
        didSet { noticeDeepTime(from: oldValue, to: ma) }
    }
    /// From the flat map, at 0, to the globe of deep time, at 1.
    private(set) var morph: Double = 0
    /// How far the person has pulled past the start or end of the track, from 0 to 1.
    private(set) var leadingPull: Double = 0
    private(set) var trailingPull: Double = 0
    /// Stars streaking past while travelling far.
    var travelWarp: Double = 0
    var camera = HistoryCamera.whole
    /// The map card's size, for flying the camera to an event's places.
    @ObservationIgnored var mapSize: CGSize = .zero
    /// The unit tapped on the map, whose place in each era is shown as the person scrubs.
    var selectedUnit: Int?
    /// The event card in the middle of the row, whose places glow on the map.
    var focusedEventID: String?
    var spin = GlobeSpin()
    var isScrubbing = false {
        didSet {
            if isScrubbing { pullGeneration += 1 }
        }
    }
    /// Counters that move on each step, for haptics.
    private(set) var eraTicks = 0
    private(set) var pullTicks = 0
    private(set) var arrivals = 0
    private(set) var periodTicks = 0
    private(set) var eventTicks = 0
    private(set) var strikes = 0
    private(set) var isTravelling = false
    /// Whether the person has found deep time before, so the way there stays open.
    private(set) var hasFoundDeepTime = UserDefaults.standard.bool(forKey: TimeMachineModel.deepTimeKey)

    @ObservationIgnored private var pullGeneration = 0
    /// Set while the app moves the position itself, so only the person's own moves tick.
    @ObservationIgnored private var isQuiet = false

    static let deepTimeKey = "timeMachineFoundDeepTime"

    /// The app's Reduce Motion setting, which turns travel into a quick fade.
    private var reducesMotion: Bool { UserDefaults.standard.bool(forKey: MotionPreference.storageKey) }

    /// How the map turns into the globe and back: a slow curl, or with Reduce Motion, a fade.
    private func morphAnimation(duration: Double) -> Animation {
        reducesMotion ? .easeInOut(duration: 0.35) : .smooth(duration: duration)
    }

    // MARK: Loading

    func load() async {
        guard atlas == nil else { return }
        let projection = HistoryMapGeometry.preferredProjection
        let loaded = await Task.detached(priority: .userInitiated) { () -> (TimeMachineAtlas, HistoryMapGeometry, GlobeMesh, CGImage?)? in
            guard let atlas = TimeMachineAtlas.load() else { return nil }
            let geometry = HistoryMapGeometry(atlas: atlas, projection: projection)
            return (atlas, geometry, GlobeMesh(atlas: atlas), TimeStack.silhouette(of: geometry))
        }.value
        guard let (atlas, geometry, mesh, silhouette) = loaded, !atlas.eras.isEmpty else {
            loadFailed = true
            return
        }
        self.atlas = atlas
        self.geometry = geometry
        self.mesh = mesh
        self.silhouette = silhouette.map { Image(decorative: $0, scale: 2) }
        quietly { position = Double(atlas.eras.count - 1) }
    }

    private func quietly(_ change: () -> Void) {
        isQuiet = true
        change()
        isQuiet = false
    }

    // MARK: History

    var eraCount: Int { atlas?.eras.count ?? 0 }

    var currentEra: HistoricalEra? {
        guard let atlas, atlas.eras.indices.contains(eraIndex) else { return nil }
        return atlas.eras[eraIndex]
    }

    /// The year shown while scrubbing, counting through the years between eras like an odometer.
    var displayYear: Int {
        guard let atlas, !atlas.eras.isEmpty else { return 0 }
        let clamped = min(max(position, 0), Double(atlas.eras.count - 1))
        let from = Int(clamped.rounded(.down))
        let to = min(from + 1, atlas.eras.count - 1)
        let fraction = clamped - Double(from)
        let years = Double(atlas.eras[from].year) + Double(atlas.eras[to].year - atlas.eras[from].year) * fraction
        return Int(years.rounded())
    }

    /// The scrubber's place along its track, for either mode. Ignored while travelling.
    var trackValue: Double {
        get {
            switch presentedMode {
            case .history: eraCount > 1 ? position / Double(eraCount - 1) : 1
            case .deepTime: 1 - ma / maxMa
            }
        }
        set {
            guard !isTravelling else { return }
            let value = newValue.clamped01
            switch mode {
            case .history: position = value * Double(max(eraCount - 1, 0))
            case .deepTime: ma = (1 - value) * maxMa
            }
        }
    }

    var maxMa: Double { atlas?.deepTime?.maxMa ?? 250 }

    /// Jumps to an era or a moment in deep time, gliding through everything between, with a tick
    /// for each era passed on the way.
    func travel(toTrackValue value: Double) {
        guard !isTravelling else { return }
        switch mode {
        case .history:
            let era = (value.clamped01 * Double(max(eraCount - 1, 0))).rounded()
            let crossed = Int(abs(era - position.rounded()))
            let duration = 0.35 + 0.12 * Double(min(crossed, 8))
            withAnimation(.smooth(duration: duration)) { position = era }
            if crossed > 1 {
                Task {
                    for _ in 1..<crossed {
                        try? await Task.sleep(for: .seconds(duration * 0.8 / Double(crossed)))
                        eraTicks += 1
                    }
                }
            }
        case .deepTime:
            fly(toMa: (1 - value.clamped01) * maxMa)
        }
    }

    /// Glides deep time to a moment, such as an event's.
    func fly(toMa target: Double) {
        guard mode == .deepTime, !isTravelling else { return }
        withAnimation(.smooth(duration: 1.1)) { ma = min(max(target, 0), maxMa) }
    }

    /// Steps one era or ten million years along, for VoiceOver and the keyboard.
    func step(by direction: Int) {
        guard !isTravelling else { return }
        switch mode {
        case .history:
            let era = min(max(eraIndex + direction, 0), max(eraCount - 1, 0))
            withAnimation(.smooth(duration: 0.45)) { position = Double(era) }
        case .deepTime:
            withAnimation(.smooth(duration: 0.6)) { ma = min(max((ma / 10).rounded() * 10 - Double(direction) * 10, 0), maxMa) }
        }
    }

    /// Let go of the scrubber: history settles onto the nearest era, and pulls ease off unless
    /// the person comes back for more.
    func release() {
        if mode == .history, !isTravelling {
            withAnimation(.snappy(duration: 0.4)) { position = position.rounded() }
        }
        let generation = pullGeneration
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            guard generation == pullGeneration, !isScrubbing else { return }
            withAnimation(.smooth(duration: 0.7)) {
                leadingPull = 0
                trailingPull = 0
            }
        }
    }

    // MARK: Pulling past the ends

    /// Pulling on past an end, by a fraction of the way to breaking through; negative as the
    /// finger comes back. Past history's beginning, keep going and the way to deep time opens;
    /// past the present in deep time, back to history. The other ends only give a little.
    func pull(_ edge: ScrubberEdge, by amount: Double) {
        guard !isTravelling else { return }
        let before = edge == .leading ? leadingPull : trailingPull
        let opens = (mode == .history && edge == .leading) || (mode == .deepTime && edge == .trailing)
        // An end that leads nowhere gives a little, then holds.
        let after = opens ? max(before + amount, 0) : min(max(before + amount * 0.5, 0), 0.3)
        if edge == .leading { leadingPull = after } else { trailingPull = after }
        if Int(after * 12) != Int(before * 12) { pullTicks += 1 }
        guard opens, after >= 1 else { return }
        if mode == .history {
            travelToDeepTime()
        } else {
            returnToHistory()
        }
    }

    /// The map curls into a globe and the stars streak past, into deep time.
    func travelToDeepTime() {
        guard mode == .history, !isTravelling, atlas?.deepTime != nil else { return }
        isTravelling = true
        hasFoundDeepTime = true
        UserDefaults.standard.set(true, forKey: Self.deepTimeKey)
        arrivals += 1
        selectedUnit = nil
        focusedEventID = nil
        isScrubbing = false
        quietly {
            withAnimation(.smooth(duration: 0.5)) {
                leadingPull = 0
                trailingPull = 0
                camera = .whole
            }
            position = 0
        }
        mode = .deepTime
        quietly { ma = 0 }
        spin = GlobeSpin(longitude: 15, latitude: 12, velocity: 0, since: .now)
        warpPulse()
        Task {
            // The globe arrives flat, exactly over the map, before curling up.
            try? await Task.sleep(for: .milliseconds(40))
            withAnimation(morphAnimation(duration: 1.5)) {
                morph = 1
            } completion: {
                self.isTravelling = false
                AccessibilityNotification.Announcement("Deep time").post()
            }
            try? await Task.sleep(for: .seconds(reducesMotion ? 0.1 : 0.6))
            withAnimation(.smooth(duration: 0.5)) { presentedMode = .deepTime }
        }
    }

    /// Back from deep time: the continents settle where they are today and the globe unrolls
    /// into today's map.
    func returnToHistory() {
        guard mode == .deepTime, !isTravelling else { return }
        isTravelling = true
        arrivals += 1
        isScrubbing = false
        let settle = ma > 1 ? min(0.4 + ma / 250, 1.2) : 0
        withAnimation(.smooth(duration: 0.4)) {
            leadingPull = 0
            trailingPull = 0
        }
        quietly {
            withAnimation(.smooth(duration: settle)) { ma = 0 }
        }
        Task {
            try? await Task.sleep(for: .seconds(settle))
            quietly { position = Double(max(eraCount - 1, 0)) }
            warpPulse()
            withAnimation(morphAnimation(duration: 1.3)) {
                morph = 0
            } completion: {
                self.mode = .history
                self.isTravelling = false
                AccessibilityNotification.Announcement("Recorded history, today").post()
            }
            try? await Task.sleep(for: .seconds(reducesMotion ? 0.1 : 0.5))
            withAnimation(.smooth(duration: 0.5)) { presentedMode = .history }
        }
    }

    /// Stars streaking past and settling, as when Time Machine opens or travels far.
    func warpPulse() {
        guard !reducesMotion else { return }
        withAnimation(.easeIn(duration: 0.35)) { travelWarp = 1 } completion: {
            withAnimation(.smooth(duration: 1.4)) { self.travelWarp = 0 }
        }
    }

    /// The stars' streaking: a little as the person pulls past history's start, fully while travelling.
    var warp: Double {
        max(travelWarp, mode == .history ? leadingPull * 0.45 : trailingPull * 0.45)
    }

    // MARK: Deep time

    /// A tick for each period and moment the scrub passes, and the asteroid's thud.
    private func noticeDeepTime(from old: Double, to new: Double) {
        guard mode == .deepTime, !isQuiet, let deepTime = atlas?.deepTime else { return }
        if deepTime.period(at: old)?.id != deepTime.period(at: new)?.id { periodTicks += 1 }
        for event in deepTime.events where (old < event.ma) != (new < event.ma) {
            if event.kind == .impact { strikes += 1 } else { eventTicks += 1 }
        }
    }

    var currentPeriod: DeepTime.Period? {
        atlas?.deepTime?.period(at: ma)
    }

    // MARK: Map

    /// Flies the flat map in on a set of units, or back out to the whole world.
    func frame(units: [Int], in size: CGSize) {
        guard let geometry, !units.isEmpty, size.width > 0 else { return }
        var rect = CGRect.null
        for unit in units { rect = rect.union(geometry.unitBounds[unit]) }
        let fit = geometry.transform(in: size, camera: .whole).a
        guard fit > 0, !rect.isNull, rect.width > 0, rect.height > 0 else { return }
        let scale = min(max(min(size.width * 0.6 / (rect.width * fit), size.height * 0.6 / (rect.height * fit)), 1), 6)
        let k = fit * scale
        let offset = CGSize(width: -k * (rect.midX - geometry.bounds.midX), height: -k * (rect.midY - geometry.bounds.midY))
        withAnimation(.smooth(duration: 0.8)) {
            camera = HistoryCamera(scale: scale, offset: clamped(offset, scale: scale, size: size))
        }
    }

    /// Keeps the map from being pushed off its card: it can move as far as it runs past each
    /// edge, and a little more.
    func clamped(_ offset: CGSize, scale: CGFloat, size: CGSize) -> CGSize {
        guard let geometry else { return offset }
        let k = geometry.transform(in: size, camera: HistoryCamera(scale: scale)).a
        let limitX = max(geometry.bounds.width * k - size.width, 0) / 2 + size.width * 0.05
        let limitY = max(geometry.bounds.height * k - size.height, 0) / 2 + size.height * 0.05
        return CGSize(width: min(max(offset.width, -limitX), limitX), height: min(max(offset.height, -limitY), limitY))
    }

    /// Whether the map runs past its card, so it can be dragged about.
    func mapOverflows(in size: CGSize) -> Bool {
        guard let geometry, size.width > 0 else { return false }
        let k = geometry.transform(in: size, camera: camera).a
        return geometry.bounds.width * k > size.width + 1 || geometry.bounds.height * k > size.height + 1
    }

    #if DEBUG
    /// Sets how far history's start has been pulled, for screenshots.
    func debugPull(_ amount: Double) {
        quietly { position = 0 }
        pull(.leading, by: amount)
    }
    #endif
}
