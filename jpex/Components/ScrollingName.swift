import SwiftUI

/// One line of text that never cuts off. When it fits, it's simply the text, taking only the room
/// it needs. When it's too long for its space, it fades out at the edge and, every so often and
/// straight away when `trigger` changes, glides across to show its end, pauses, then glides back.
/// It glides by itself twice each time it appears, so a screen left open settles and stays still;
/// in Low Power Mode or while the app isn't in front, only when `trigger` changes. Once it has
/// settled, touching and holding it a moment sets it gliding again, to read the rest; sliding the
/// finger away before letting go leaves whatever holds it, such as a card's button, untouched.
///
/// With Reduce Motion on it never moves by itself and never cuts off with an ellipsis either: it
/// rests at its start, fading at the edge, and when held or when `trigger` changes, it dissolves to
/// show its end where it stands, holds there a moment to be read, and dissolves back.
struct ScrollingText<Content: View>: View {
  var trigger: Int = 0
  @ViewBuilder var content: Content

  var body: some View {
    ViewThatFits(in: .horizontal) {
      content.lineLimit(1)
      Marquee(trigger: trigger, content: content)
    }
  }
}

/// A name in plain text that scrolls when it doesn't fit, as `ScrollingText` does.
struct ScrollingName: View {
  var text: String
  var trigger: Int = 0

  var body: some View {
    ScrollingText(trigger: trigger) { Text(text) }
  }
}

/// What sets a name gliding afresh: a tap, a touch held on it, or decoration being allowed to
/// move again.
private struct GlideRequest: Equatable {
  var trigger: Int
  var holds: Int
  var glidesByItself: Bool
}

/// The text in a window of whatever width it's given, gliding to its end and back, or with Reduce
/// Motion, dissolving to its end and back.
private struct Marquee<Content: View>: View {
  var trigger: Int
  var content: Content
  @State private var fullWidth = 0.0
  @State private var boxWidth = 0.0
  @State private var offset = 0.0
  /// How much of the text shows while it dissolves from one end to the other, with Reduce Motion.
  @State private var visibility = 1.0
  /// Counts each touch held on the text, which sets it gliding at once.
  @State private var holds = 0
  /// The tap and hold counts as last answered, so only a fresh tap or hold sets the text gliding
  /// at once, never decoration being allowed to move again. Nil until it first runs.
  @State private var asked: (trigger: Int, holds: Int)?
  @Environment(\.allowsAmbientMotion) private var allowsAmbientMotion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// How long the text takes to dissolve out or back in, with Reduce Motion.
  private static var dissolve: Double { 0.15 }
  /// How long its end stays to be read once it has dissolved there, with Reduce Motion.
  private static var reading: Double { 2 }

  private var overflow: Double { max(fullWidth - boxWidth, 0) }

  var body: some View {
    content
      .lineLimit(1)
      .fixedSize()
      .onGeometryChange(for: Double.self) { $0.size.width } action: { fullWidth = $0 }
      .offset(x: offset)
      .opacity(visibility)
      // Zero minimum, so the text's full width never widens what holds it.
      .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
      .onGeometryChange(for: Double.self) { $0.size.width } action: { boxWidth = $0 }
      .clipped()
      .mask {
        // A soft edge where the text runs on, at whichever end is hidden.
        let fade = overflow > 0 ? 14.0 : 0
        HStack(spacing: 0) {
          LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
            .frame(width: offset < 0 ? fade : 0)
          Color.black
          LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
            .frame(width: offset > -overflow + 0.5 ? fade : 0)
        }
      }
      // Held a moment, it glides at once, alongside whatever it sits in, so a button around it
      // still works as it would.
      .simultaneousGesture(
        LongPressGesture(minimumDuration: 0.3, maximumDistance: 24)
          .onEnded { _ in
            guard overflow > 0.5 else { return }
            holds += 1
          })
      // A couple of times, and straight away when tapped or held, the text glides across to show
      // its end, pauses, and glides back. Each waits a little differently, so several take turns.
      // Asked for, it shows its end just the once. Nothing glides by itself with Reduce Motion, in
      // Low Power Mode or while the app isn't in front. Back in front, a name tapped earlier takes
      // its turn with the rest rather than every one gliding at once; a name only now too long,
      // as when a tap brings a tick in beside it, glides at once.
      .task(id: GlideRequest(trigger: trigger, holds: holds, glidesByItself: allowsAmbientMotion)) {
        var now = asked.map { $0.trigger != trigger || $0.holds != holds } ?? (trigger > 0 || holds > 0)
        asked = (trigger, holds)
        var glidesLeft = now ? 1 : (allowsAmbientMotion ? 2 : 0)
        var tries = 4
        while glidesLeft > 0, tries > 0, !Task.isCancelled {
          if !now { try? await Task.sleep(for: .seconds(3.5 + Double.random(in: 0...2))) }
          now = false
          tries -= 1
          guard !Task.isCancelled else { return }
          guard overflow > 0.5 else { continue }
          glidesLeft -= 1
          let travel = overflow + 4
          if reduceMotion {
            await dissolve(to: -travel)
          } else {
            let duration = max(0.6, travel / 45)
            withAnimation(.easeInOut(duration: duration)) { offset = -travel }
            try? await Task.sleep(for: .seconds(duration + 1.1))
            withAnimation(.easeInOut(duration: duration * 0.7)) { offset = 0 }
            try? await Task.sleep(for: .seconds(duration * 0.7))
          }
        }
      }
  }

  /// With Reduce Motion, shows the text's end without anything travelling: it fades out, comes
  /// back at its end, stays a moment to be read, then fades out and back in at its start. Runs to
  /// the end even when interrupted, so the text is never left faded or partway.
  private func dissolve(to end: Double) async {
    withAnimation(.easeOut(duration: Self.dissolve)) { visibility = 0 }
    try? await Task.sleep(for: .seconds(Self.dissolve))
    jump(to: end)
    withAnimation(.easeIn(duration: Self.dissolve)) { visibility = 1 }
    try? await Task.sleep(for: .seconds(Self.dissolve + Self.reading))
    withAnimation(.easeOut(duration: Self.dissolve)) { visibility = 0 }
    try? await Task.sleep(for: .seconds(Self.dissolve))
    jump(to: 0)
    withAnimation(.easeIn(duration: Self.dissolve)) { visibility = 1 }
    try? await Task.sleep(for: .seconds(Self.dissolve))
  }

  /// Moves the text while it's faded out, at once, whatever animation is about around it.
  private func jump(to position: Double) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { offset = position }
  }
}
