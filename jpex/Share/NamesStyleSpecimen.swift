import SwiftUI
import UIKit

/// A names style's name set in the style itself, as a font menu shows each font in its own type: for
/// choosing between them beneath the share screen's card.
struct NamesStyleSpecimen: View {
    var style: MapShareContent.NamesStyle

    var body: some View {
        Group {
            switch style {
            case .block:
                Text(style.name.uppercased())
                    .font(.system(size: 16, weight: .heavy).width(.condensed))
            case .editorial:
                Text(style.name)
                    .font(EditorialNames.font(size: 18))
            case .outline:
                OutlinedWord(text: style.name.uppercased(), font: OutlineNames.uiFont(size: 11.5))
            case .pills:
                Text(style.name.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(CandyGloss.lettering(on: Self.sky))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background { CandyGloss(color: Self.sky, pattern: nil) }
                    .clipShape(Capsule())
            case .spiral:
                HStack(spacing: 6) {
                    SpiralMark()
                        .stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                        .frame(width: 15, height: 15)
                    Text(style.name)
                }
            case .checklist:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.square.fill")
                    Text(style.name)
                        .font(ChecklistNames.font(size: 15))
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(style.name)
    }

    /// The app's own sky blue, as on the back of the card.
    private static let sky = Color(red: 0.16, green: 0.62, blue: 0.9)
}

/// A word drawn only in outline, in the colour of the text around it.
private struct OutlinedWord: View {
    var text: String
    var font: UIFont

    var body: some View {
        let line = GlyphLine(text, font: font)
        Canvas { context, _ in
            context.stroke(line.path(at: CGPoint(x: 1, y: line.ascent + 1)).normalized(eoFill: false), with: .foreground, lineWidth: 1)
        }
        .frame(width: line.width + 2, height: line.ascent + line.descent + 2)
    }
}

/// A small spiral, winding two and a half times round into its middle.
private struct SpiralMark: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()
        for step in 0...90 {
            let progress = CGFloat(step) / 90
            let angle = progress * 5 * .pi
            let radius = outer * (1 - progress * 0.88)
            let point = CGPoint(x: center.x + radius * sin(angle), y: center.y - radius * cos(angle))
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}
