import SwiftUI

/// One line of text that never cuts off. When it fits, it's simply the text, taking only the room
/// it needs. When it's too long for its space, it fades out at the edge and, every so often and
/// straight away when `trigger` changes, glides across to show its end, pauses, then glides back.
/// With Reduce Motion on it stays still and ends in an ellipsis instead.
struct ScrollingText<Content: View>: View {
  var trigger: Int = 0
  @ViewBuilder var content: Content
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    if reduceMotion {
      content.lineLimit(1)
    } else {
      ViewThatFits(in: .horizontal) {
        content.lineLimit(1)
        Marquee(trigger: trigger, content: content)
      }
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

/// The text in a window of whatever width it's given, gliding to its end and back.
private struct Marquee<Content: View>: View {
  var trigger: Int
  var content: Content
  @State private var fullWidth = 0.0
  @State private var boxWidth = 0.0
  @State private var offset = 0.0

  private var overflow: Double { max(fullWidth - boxWidth, 0) }

  var body: some View {
    content
      .lineLimit(1)
      .fixedSize()
      .onGeometryChange(for: Double.self) { $0.size.width } action: { fullWidth = $0 }
      .offset(x: offset)
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
      // Every so often, and straight away when tapped, the text glides across to show its end,
      // pauses, and glides back. Each waits a little differently, so several take turns.
      .task(id: trigger) {
        var now = trigger > 0
        while !Task.isCancelled {
          if !now { try? await Task.sleep(for: .seconds(3.5 + Double.random(in: 0...2))) }
          now = false
          guard !Task.isCancelled else { return }
          guard overflow > 0.5 else { continue }
          let travel = overflow + 4
          let duration = max(0.6, travel / 45)
          withAnimation(.easeInOut(duration: duration)) { offset = -travel }
          try? await Task.sleep(for: .seconds(duration + 1.1))
          withAnimation(.easeInOut(duration: duration * 0.7)) { offset = 0 }
          try? await Task.sleep(for: .seconds(duration * 0.7))
        }
      }
  }
}
