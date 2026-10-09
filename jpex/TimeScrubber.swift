import SwiftUI

/// Time Machine's control: a glass track marked with moments in time and a glowing knob. Dragging
/// anywhere along it moves the knob by as much as the finger moves, like turning a dial, so it
/// can be nudged precisely; a tap on a mark jumps there. While dragging, the marks near the knob
/// swell like the Dock and a bubble above names the moment.
///
/// Dragging on past either end doesn't stop dead: the knob strains against the end and the pull
/// is reported, so the screen can respond — keep pulling and something gives. Coming back eases
/// the pull off before the knob moves again.
struct TimeScrubber: View {
    var track: ScrubberTrack
    /// Where the knob is, from 0 at the leading end to 1 at the trailing end.
    @Binding var value: Double
    /// How far each end has been pulled past, from 0 to 1, for the knob to strain and the hint to show.
    var leadingPull: Double
    var trailingPull: Double
    /// The bubble's name for a point along the track: a title and a quieter detail.
    var bubble: (Double) -> (title: String, detail: String)
    var accessibilityValue: String
    var onScrubbingChange: (Bool) -> Void
    /// How far past an end the knob has been pulled, as a fraction of the way to breaking
    /// through, or a negative fraction as it comes back.
    var onPull: (ScrubberEdge, Double) -> Void
    /// A drag let go, or a tap at a point along the track.
    var onRelease: () -> Void
    var onTap: (Double) -> Void
    var onAdjust: (Int) -> Void

    @State private var width: CGFloat = 0
    @State private var lastX: CGFloat?
    @State private var travelled: CGFloat = 0
    @State private var isScrubbing = false
    /// Whether a finger is down, which SwiftUI clears even when a drag is cancelled rather than ended.
    @GestureState private var isTouching = false
    @State private var bubbleSize: CGSize = .zero

    static let knob: CGFloat = 26
    static let height: CGFloat = 52
    private static let inset: CGFloat = knob / 2 + 10
    private static let bubbleLift: CGFloat = 40
    static let glow = Color(red: 0.55, green: 0.85, blue: 1)

    private var usableWidth: CGFloat { max(width - Self.inset * 2, 1) }

    /// How far past an end it takes to break through: most of another stroke along the track.
    private var pullDistance: CGFloat { max(usableWidth * 0.8, 200) }

    private func x(at position: Double) -> CGFloat {
        Self.inset + usableWidth * CGFloat(min(max(position, 0), 1))
    }

    /// The knob strains past an end as it's pulled, less and less the further it goes.
    private var knobX: CGFloat {
        let strain = 14 * CGFloat(1 - exp(-3 * leadingPull)) - 14 * CGFloat(1 - exp(-3 * trailingPull))
        return x(at: value) - strain
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.04))
            Group {
                bands
                marks
            }
            .id(track.id)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            knob
        }
        .frame(height: Self.height)
        .glassPanel(in: Capsule())
        .overlay(alignment: .topLeading) { bubbleOverlay }
        .overlay(alignment: .topLeading) { pullBadge(edge: .leading, pull: leadingPull, hint: track.leadingPull) }
        .overlay(alignment: .topLeading) { pullBadge(edge: .trailing, pull: trailingPull, hint: track.trailingPull) }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .contentShape(Capsule())
        .gesture(drag)
        .onChange(of: isTouching) { _, touching in
            // A drag cancelled part way, as when travel begins under the finger, ends here.
            if !touching { finishDrag() }
        }
        .focusable()
        .onKeyPress(.leftArrow) {
            onAdjust(-1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            onAdjust(1)
            return .handled
        }
        .accessibilityElement()
        .accessibilityLabel("Time")
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onAdjust(1)
            case .decrement: onAdjust(-1)
            @unknown default: break
            }
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { _, touching, _ in touching = true }
            .onChanged { gesture in
                let x = gesture.location.x
                defer { lastX = x }
                guard let lastX else {
                    travelled = 0
                    return
                }
                var dx = x - lastX
                travelled += abs(dx)
                guard travelled > 3 else { return }
                if !isScrubbing {
                    isScrubbing = true
                    onScrubbingChange(true)
                }
                // Coming back from a pulled end eases the pull off first.
                if leadingPull > 0, dx > 0 {
                    let spent = min(dx, CGFloat(leadingPull) * pullDistance)
                    onPull(.leading, -Double(spent / pullDistance))
                    dx -= spent
                } else if trailingPull > 0, dx < 0 {
                    let spent = min(-dx, CGFloat(trailingPull) * pullDistance)
                    onPull(.trailing, -Double(spent / pullDistance))
                    dx += spent
                }
                guard dx != 0 else { return }
                let next = value + Double(dx / usableWidth)
                if next < 0 {
                    if value > 0 { value = 0 }
                    onPull(.leading, -next * Double(usableWidth / pullDistance))
                } else if next > 1 {
                    if value < 1 { value = 1 }
                    onPull(.trailing, (next - 1) * Double(usableWidth / pullDistance))
                } else {
                    value = next
                }
            }
            .onEnded { gesture in
                let wasScrubbing = isScrubbing
                finishDrag()
                if !wasScrubbing {
                    onTap(Double((gesture.location.x - Self.inset) / usableWidth))
                }
            }
    }

    /// Clears the drag, whether it ended or was cancelled, once.
    private func finishDrag() {
        lastX = nil
        guard isScrubbing else { return }
        isScrubbing = false
        onScrubbingChange(false)
        onRelease()
    }

    // MARK: Parts

    /// Coloured spans along the foot of the track, such as the geological periods.
    private var bands: some View {
        Canvas { context, size in
            for band in track.bands {
                let start = x(at: min(band.from, band.to))
                let end = x(at: max(band.from, band.to))
                let rect = CGRect(x: start, y: size.height - 9, width: max(end - start - 1, 1), height: 3)
                context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(band.color.opacity(0.85)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The marks, swelling toward the knob while it's dragged, with their labels beneath.
    private var marks: some View {
        Canvas { context, size in
            let knob = knobX
            var lastLabelEnd = -CGFloat.infinity
            for tick in track.ticks.sorted(by: { $0.position < $1.position }) {
                let x = x(at: tick.position)
                let distance = (x - knob) / 34
                let swell = isScrubbing ? 1 + 1.1 * exp(-distance * distance) : 1
                let base: CGFloat = tick.isMajor ? 12 : 7
                let height = base * swell
                let near = abs(x - knob) < 6
                let rect = CGRect(x: x - 1, y: 15 - height / 2, width: 2, height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: 1),
                             with: .color(.white.opacity(near ? 0.95 : tick.isMajor ? 0.5 : 0.28)))
                guard let label = tick.label else { continue }
                let text = context.resolve(Text(label)
                    .font(.system(size: 9.5, weight: near ? .bold : .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white.opacity(near ? 0.95 : 0.55)))
                let measured = text.measure(in: CGSize(width: 80, height: 20))
                let left = x - measured.width / 2
                guard left > lastLabelEnd + 4, left > 2, left + measured.width < size.width - 2 else { continue }
                lastLabelEnd = left + measured.width
                context.draw(text, in: CGRect(x: left, y: 30, width: measured.width, height: measured.height))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var knob: some View {
        Circle()
            .fill(.white)
            .overlay {
                Circle().fill(RadialGradient(colors: [.white, Self.glow.opacity(0.7)], center: .topLeading, startRadius: 0, endRadius: Self.knob))
            }
            .frame(width: Self.knob, height: Self.knob)
            .shadow(color: Self.glow.opacity(0.9), radius: isScrubbing ? 12 : 6)
            .scaleEffect(x: 1 - 0.18 * (leadingPull + trailingPull).clamped01, y: 1 + 0.08 * (leadingPull + trailingPull).clamped01)
            .scaleEffect(isScrubbing ? 1.18 : 1)
            .offset(x: knobX - Self.knob / 2, y: -5)
            .animation(.bouncy(duration: 0.3), value: isScrubbing)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    /// While dragging, the moment under the knob, floating clear above the finger — or, while an
    /// end is pulled, the hint for pulling it further.
    @ViewBuilder private var bubbleOverlay: some View {
        let pull = max(leadingPull, trailingPull)
        let hint = leadingPull > trailingPull ? track.leadingPull : track.trailingPull
        if isScrubbing || pull > 0.04 {
            Group {
                if pull > 0.04, let hint {
                    Text(hint.hint(at: pull))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .glassPanel(in: Capsule(), tint: hint.color)
                } else {
                    let content = bubble(value)
                    VStack(spacing: 1) {
                        Text(content.title)
                            .font(.system(.title3, design: .rounded).weight(.semibold).monospacedDigit())
                            .contentTransition(.numericText())
                        if !content.detail.isEmpty {
                            Text(content.detail)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassPanel(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { $0.size } action: { bubbleSize = $0 }
            .offset(x: bubbleX, y: -(bubbleSize.height + (isPulling ? 12 : Self.bubbleLift - 18)))
            .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .environment(\.colorScheme, .dark)
        }
    }

    /// Whether an end is being pulled, when the hint sits low beside the end's badge.
    private var isPulling: Bool { max(leadingPull, trailingPull) > 0.04 }

    private var bubbleX: CGFloat {
        if isPulling {
            // Beside the badge past the pulled end.
            return leadingPull > trailingPull ? 48 : max(width - bubbleSize.width - 48, 0)
        }
        guard bubbleSize.width < width else { return (width - bubbleSize.width) / 2 }
        return min(max(knobX - bubbleSize.width / 2, 0), width - bubbleSize.width)
    }

    /// A badge past an end, filling its ring as that end is pulled, with the symbol of what lies beyond.
    @ViewBuilder private func pullBadge(edge: ScrubberEdge, pull: Double, hint: ScrubberTrack.PullHint?) -> some View {
        if let hint, pull > 0.02 {
            let size: CGFloat = 40
            ZStack {
                Circle().fill(.black.opacity(0.35))
                Circle().stroke(.white.opacity(0.15), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: pull.clamped01)
                    .stroke(hint.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: hint.color, radius: 6)
                Image(systemName: hint.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(hint.color)
                    .symbolEffect(.bounce, value: Int(pull * 5))
            }
            .frame(width: size, height: size)
            .scaleEffect(0.6 + 0.4 * pull.clamped01)
            .opacity(min(pull * 4, 1))
            .offset(x: edge == .leading ? -4 : width - size + 4, y: -size - 10)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

enum ScrubberEdge {
    case leading, trailing
}

/// What a scrubber's track shows: its marks, coloured spans, and what pulling past each end leads to.
struct ScrubberTrack {
    /// Changes when the track's marks change, so the old ones fade as the new ones arrive.
    var id: String
    var ticks: [Tick]
    var bands: [Band] = []
    var leadingPull: PullHint?
    var trailingPull: PullHint?

    struct Tick {
        var position: Double
        var label: String?
        var isMajor = true
    }

    struct Band {
        var from: Double
        var to: Double
        var color: Color
    }

    /// What lies past an end: its symbol and colour, and what to say as it's pulled further.
    struct PullHint {
        var systemImage: String
        var color: Color
        /// Said in turn as the pull grows.
        var hints: [String]

        func hint(at pull: Double) -> String {
            guard !hints.isEmpty else { return "" }
            let index = min(Int(pull * Double(hints.count)), hints.count - 1)
            return hints[max(index, 0)]
        }
    }
}

extension Double {
    var clamped01: Double { Swift.min(Swift.max(self, 0), 1) }
}
