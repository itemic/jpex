import SwiftUI

/// A level, said briefly with the place's flag and the level's pill:
/// - "Canada set to STAYED", with a way to undo it;
/// - "Japan VISITED" once every place in a list has reached a level, with a burst of confetti;
/// - "Benin ~~VISITED~~ → NEVER BEEN" when a change is undone or redone.
struct LevelToastView: View {
    var toast: LevelToast
    @State private var bursts = 0

    var body: some View {
        HStack(spacing: 10) {
            if let flag = toast.flagAssetName {
                Image(flag)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 20)
                    .clipShape(.rect(cornerRadius: 3))
                    .overlay { RoundedRectangle(cornerRadius: 3).strokeBorder(.quaternary, lineWidth: 0.5) }
                    .accessibilityHidden(true)
            }
            content
        }
        .padding(.leading, toast.flagAssetName == nil ? 16 : 10)
        .padding(.trailing, toast.onUndo == nil ? 12 : 8)
        .padding(.vertical, 8)
        .glassPanel(in: Capsule(), tint: toast.level.color, interactive: true)
        .overlay {
            if toast.kind == .completed {
                // A finished list's confetti bursts from the toast itself, wherever the list is.
                CelebrationBurst(trigger: bursts, colors: toast.ladder.levels.map(\.color), pieceCount: 48)
                    .frame(width: 320, height: 320)
            }
        }
        .onAppear {
            if toast.kind == .completed { bursts += 1 }
        }
        .environment(\.visitLadder, toast.ladder)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder private var content: some View {
        switch toast.kind {
        case .raised:
            // The place leads; the words around it step back.
            ScrollingText {
                Text("\(Text(toast.placeName).fontWeight(.semibold)) \(Text("set to").foregroundStyle(.secondary))")
                    .font(.subheadline)
            }
            .accessibilityHidden(true)
            pill(toast.level)
            if let onUndo = toast.onUndo {
                Button("Undo", action: onUndo)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.primary.opacity(0.08), in: Capsule())
                    .contentShape(Capsule())
                    .buttonStyle(PillButtonStyle())
            }
        case .completed:
            name
            pill(toast.level)
        case .changed(let from):
            name
            StruckPill(level: from)
                .accessibilityHidden(true)
            Image(systemName: "arrow.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            pill(toast.level)
        }
    }

    private var name: some View {
        ScrollingText {
            Text(toast.placeName)
                .font(.subheadline.weight(.semibold))
        }
        .accessibilityHidden(true)
    }

    private func pill(_ level: VisitLevel) -> some View {
        VisitPillLabel(status: level)
            .pop(on: toast.id)
            .fixedSize()
            .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        switch toast.kind {
        case .raised: "\(toast.placeName) set to \(toast.level.name)"
        case .completed: "\(toast.placeName), every place \(toast.level.name)"
        case .changed(let from): "\(toast.placeName), \(from.name) to \(toast.level.name)"
        }
    }
}

/// The level a place had before an undo: its pill, faded, with a line drawn through it.
private struct StruckPill: View {
    var level: VisitLevel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isStruck = false

    var body: some View {
        VisitPillLabel(status: level)
            .fixedSize()
            .saturation(0.4)
            .opacity(0.6)
            .overlay {
                GeometryReader { proxy in
                    Path { line in
                        line.move(to: CGPoint(x: -2, y: proxy.size.height / 2))
                        line.addLine(to: CGPoint(x: proxy.size.width + 2, y: proxy.size.height / 2))
                    }
                    .trim(from: 0, to: isStruck ? 1 : 0)
                    .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3).delay(0.2)) { isStruck = true }
            }
    }
}

/// Drops in from the top, sharpening from a blur, and lifts away the same way. With Reduce Motion
/// on, it simply fades.
struct ToastTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        ToastMotion(content: content, isIdentity: phase.isIdentity)
    }
}

private struct ToastMotion<Content: View>: View {
    var content: Content
    var isIdentity: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let moves = !reduceMotion && !isIdentity
        content
            .offset(y: moves ? -48 : 0)
            .scaleEffect(moves ? 0.82 : 1, anchor: .top)
            .blur(radius: moves ? 10 : 0)
            .opacity(isIdentity ? 1 : 0)
    }
}

extension AnyTransition {
    static var toast: AnyTransition { AnyTransition(ToastTransition()) }
}
