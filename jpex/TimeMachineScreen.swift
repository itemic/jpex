import SwiftUI

/// Time Machine: the world map floating in space on the front of a stack of earlier maps, with a
/// scrubber through history beneath it. Scrubbing back redraws the borders era by era, colours
/// flowing from power to power, with cards on what changed. Scrub past the first era and keep
/// pulling, and the map curls into a globe as the stars streak past, into deep time, where the
/// continents drift back to Pangaea.
struct TimeMachineScreen: View {
    var onClose: () -> Void
    @State private var model = TimeMachineModel()
    /// Whether the screen has flown in, and whether its map has, once loaded.
    @State private var appeared = false
    @State private var mapArrived = false
    @State private var showingAbout = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        GeometryReader { proxy in
            let isShort = verticalSizeClass == .compact || proxy.size.height < 500
            let isWide = isShort || (proxy.size.width > 640 && proxy.size.width > proxy.size.height * 1.1)
            ZStack {
                TimeMachineBackdrop(model: model)
                    .opacity(appeared ? 1 : 0)
                if isWide {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            topBar
                            if !isShort { header(isCompact: false) }
                            TimeMachineStage(model: model, isShown: appeared && mapArrived)
                                .overlay(alignment: .topLeading) {
                                    if isShort {
                                        header(isCompact: true)
                                            .allowsHitTesting(false)
                                    }
                                }
                            scrubber(isShort: isShort)
                        }
                        TimeMachineEvents(model: model, isColumn: true)
                            .frame(width: isShort ? 280 : 320)
                            .padding(.top, isShort ? 56 : 70)
                            .opacity(appeared ? 1 : 0)
                    }
                } else {
                    VStack(spacing: 0) {
                        topBar
                        header(isCompact: false)
                        TimeMachineStage(model: model, isShown: appeared && mapArrived)
                        TimeMachineEvents(model: model, isColumn: false)
                            .opacity(appeared ? 1 : 0)
                        scrubber(isShort: false)
                    }
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAbout) {
            TimeMachineAboutView()
                .preferredColorScheme(.dark)
        }
        .task {
            // Stars streak past while the maps load, then the map flies in as they settle.
            if !reduceMotion {
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { model.travelWarp = 1 }
            }
            withAnimation(.smooth(duration: 0.8)) { appeared = true }
            await model.load()
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 250))
            withAnimation(.smooth(duration: 0.9)) { mapArrived = true }
            withAnimation(.smooth(duration: 1.6)) { model.travelWarp = 0 }
            #if DEBUG
            applyDebugLaunchArguments()
            #endif
        }
        .sensoryFeedback(.selection, trigger: model.eraTicks)
        .sensoryFeedback(.selection, trigger: model.periodTicks)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: model.eventTicks)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1), trigger: model.strikes)
        .sensoryFeedback(trigger: model.pullTicks) { _, _ in
            .impact(weight: .light, intensity: 0.35 + 0.65 * max(model.leadingPull, model.trailingPull).clamped01)
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: model.arrivals)
        .onChange(of: model.eraIndex) {
            model.focusedEventID = model.currentEra?.events.first?.id
        }
        .onChange(of: model.atlas != nil) {
            model.focusedEventID = model.currentEra?.events.first?.id
        }
    }

    private func close() {
        withAnimation(.smooth(duration: 0.45)) {
            appeared = false
            mapArrived = false
        } completion: {
            onClose()
        }
    }

    #if DEBUG
    /// Launch arguments that set where Time Machine starts, for screenshots:
    /// -TimeMachineDebugPosition 2.5, -TimeMachineDebugMa 200, -TimeMachineDebugUnit FR,
    /// -TimeMachineDebugPull 0.6.
    private func applyDebugLaunchArguments() {
        let defaults = UserDefaults.standard
        if let position = defaults.string(forKey: "TimeMachineDebugPosition").flatMap(Double.init) {
            model.position = position
        }
        if let ma = defaults.string(forKey: "TimeMachineDebugMa").flatMap(Double.init) {
            model.travelToDeepTime()
            Task {
                try? await Task.sleep(for: .seconds(1.8))
                model.fly(toMa: ma)
            }
        }
        if let pull = defaults.string(forKey: "TimeMachineDebugPull").flatMap(Double.init) {
            model.debugPull(pull)
        }
        if let id = defaults.string(forKey: "TimeMachineDebugUnit"), let atlas = model.atlas {
            model.selectedUnit = atlas.units.firstIndex { $0.id == id || $0.country == id }
        }
    }
    #endif

    // MARK: Parts

    private var topBar: some View {
        HStack(spacing: 10) {
            Button("Close", systemImage: "xmark", action: close)
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .glassPanel(in: Circle(), interactive: true)
                .keyboardShortcut(.cancelAction)
            Spacer()
            if model.presentedMode == .deepTime {
                Button("Recorded history", systemImage: "scroll.fill") {
                    model.returnToHistory()
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(height: 44)
                .glassPanel(in: Capsule(), interactive: true)
                .disabled(model.isTravelling)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else if model.hasFoundDeepTime {
                Button("Deep time", systemImage: "fossil.shell.fill") {
                    model.travelToDeepTime()
                }
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .glassPanel(in: Circle(), interactive: true)
                .disabled(model.isTravelling || model.atlas == nil)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
            Button("About Time Machine", systemImage: "info") { showingAbout = true }
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .glassPanel(in: Circle(), interactive: true)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .animation(.smooth, value: model.presentedMode)
        .animation(.smooth, value: model.hasFoundDeepTime)
        .opacity(appeared ? 1 : 0)
    }

    private func header(isCompact: Bool) -> some View {
        TimeMachineHeader(model: model, isCompact: isCompact)
            .padding(.horizontal, 22)
            .padding(.top, isCompact ? 2 : 6)
            .offset(y: appeared || reduceMotion ? 0 : -20)
            .opacity(appeared ? 1 : 0)
    }

    private func scrubber(isShort: Bool) -> some View {
        TimeMachineScrubberBar(model: model)
            .padding(.horizontal, 16)
            .padding(.top, isShort ? 36 : 50)
            .padding(.bottom, isShort ? 6 : 12)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 30)
    }
}

/// The space behind everything, streaking as Time Machine travels, warming toward deep time.
private struct TimeMachineBackdrop: View {
    var model: TimeMachineModel

    var body: some View {
        SpaceBackdrop(warp: model.warp, deepTime: model.morph)
    }
}
