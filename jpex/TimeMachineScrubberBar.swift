import SwiftUI

/// The scrubber at the foot of Time Machine, set up for the time on show: history's eras with the
/// way into deep time past their start, or deep time's millions of years in the colours of their
/// periods, with the way back to history past the present.
struct TimeMachineScrubberBar: View {
    var model: TimeMachineModel

    var body: some View {
        TimeScrubber(
            track: track,
            value: Binding(get: { model.trackValue }, set: { model.trackValue = $0 }),
            leadingPull: model.leadingPull,
            trailingPull: model.trailingPull,
            bubble: bubble,
            accessibilityValue: accessibilityValue,
            onScrubbingChange: { model.isScrubbing = $0 },
            onPull: { model.pull($0, by: $1) },
            onRelease: { model.release() },
            onTap: { model.travel(toTrackValue: $0) },
            onAdjust: { model.step(by: $0) })
        .accessibilityActions {
            if model.mode == .history {
                Button("Travel to deep time") { model.travelToDeepTime() }
            } else {
                Button("Return to recorded history") { model.returnToHistory() }
            }
        }
        .disabled(model.atlas == nil)
        .animation(.smooth(duration: 0.5), value: model.presentedMode)
    }

    private var track: ScrubberTrack {
        guard let atlas = model.atlas else { return ScrubberTrack(id: "loading", ticks: []) }
        switch model.presentedMode {
        case .history:
            let count = max(atlas.eras.count - 1, 1)
            return ScrubberTrack(
                id: "history",
                ticks: atlas.eras.enumerated().map { index, era in
                    ScrubberTrack.Tick(position: Double(index) / Double(count), label: era.isToday ? "Now" : String(era.year))
                },
                leadingPull: ScrubberTrack.PullHint(
                    systemImage: "fossil.shell.fill", color: Color(red: 1, green: 0.75, blue: 0.4),
                    hints: ["Keep going…", "Further back…", "Before history…", "Hold on…"]),
                trailingPull: ScrubberTrack.PullHint(
                    systemImage: "sparkles", color: TimeScrubber.glow, hints: ["The future isn’t written yet"]))
        case .deepTime:
            let maxMa = model.maxMa
            return ScrubberTrack(
                id: "deepTime",
                ticks: stride(from: 0.0, through: maxMa, by: 10).map { ma in
                    let isMajor = Int(ma) % 50 == 0
                    return ScrubberTrack.Tick(position: 1 - ma / maxMa,
                                              label: isMajor ? (ma == 0 ? "Now" : "\(Int(ma))") : nil, isMajor: isMajor)
                },
                bands: (atlas.deepTime?.periods ?? []).map {
                    ScrubberTrack.Band(from: 1 - min($0.start, maxMa) / maxMa, to: 1 - $0.end / maxMa, color: $0.color)
                },
                leadingPull: ScrubberTrack.PullHint(
                    systemImage: "hourglass", color: Color(red: 0.85, green: 0.75, blue: 0.6),
                    hints: ["Before Pangaea, the trail goes cold"]),
                trailingPull: ScrubberTrack.PullHint(
                    systemImage: "scroll.fill", color: TimeScrubber.glow,
                    hints: ["Keep going…", "Back to history…", "Almost there…"]))
        }
    }

    private func bubble(_ value: Double) -> (title: String, detail: String) {
        switch model.presentedMode {
        case .history:
            let era = model.currentEra
            let isToday = era?.isToday == true && model.position > Double(model.eraCount - 1) - 0.05
            return (isToday ? "Today" : String(model.displayYear), era?.title ?? "")
        case .deepTime:
            return (model.ma < 0.5 ? "Now" : "\(Int(model.ma.rounded())) million years ago", model.currentPeriod?.name ?? "")
        }
    }

    private var accessibilityValue: String {
        switch model.presentedMode {
        case .history:
            guard let era = model.currentEra else { return "" }
            return "\(era.isToday ? "Today" : String(era.year)), \(era.title)"
        case .deepTime:
            return "\(model.ma < 0.5 ? "Now" : DeepTimeEventCard.spokenAge(model.ma)), \(model.currentPeriod?.name ?? "")"
        }
    }
}
