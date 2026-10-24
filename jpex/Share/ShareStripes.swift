import SwiftUI

/// How the striped design's stripes run, as in Aether's Deco: their colours in order, how wide each
/// one is, and the angle they cross the card at.
struct ShareStripes: Equatable, Sendable {
    var colors: [Color]
    /// Degrees from upright, turning clockwise.
    var angle: Double
    /// Each stripe's width, in points on the card.
    var width: Double

    static let colorsKey = "shareStripeColors"
    static let angleKey = "shareStripeAngle"
    static let widthKey = "shareStripeWidth"
    static let defaultAngle = 35.0
    static let defaultWidth = 26.0
    static let angles: ClosedRange<Double> = 0...180
    static let widths: ClosedRange<Double> = 6...90
    static let fewest = 2
    static let most = 8

    /// A set of colours to start from, as Deco offers.
    struct Preset: Identifiable {
        var name: String
        var colors: [Color]
        var id: String { name }
    }

    /// The person's own levels' colours first, then sets made to look good together.
    static func presets(levels: [Color]) -> [Preset] {
        [Preset(name: "Levels", colors: levels)] + fixedPresets
    }

    private static let fixedPresets: [Preset] = [
        Preset(name: "Sunset", colors: [0xFF5E62, 0xFF9966, 0xFFD36E, 0xFFF1C1].map(color(hex:))),
        Preset(name: "Ocean", colors: [0x0B3D91, 0x1E6FD9, 0x4FC3F7, 0xB3E5FC].map(color(hex:))),
        Preset(name: "Retro", colors: [0x61BB46, 0xFDB827, 0xF5821F, 0xE03A3E, 0x963D97, 0x009DDC].map(color(hex:))),
        Preset(name: "Sorbet", colors: [0xFFB3C7, 0xFFE5A3, 0xB8F2C9, 0xA7DBFF, 0xD6C2FF].map(color(hex:))),
        Preset(name: "Ink", colors: [0x16161A, 0xF4F1EA].map(color(hex:))),
        Preset(name: "Matcha", colors: [0x3E6B3A, 0x9CC283, 0xEFF5DF].map(color(hex:))),
    ]

    static let defaultColors = fixedPresets[0].colors

    /// Stripes picked at random, for shuffling the card: one of the sets, or colours chosen to go
    /// together, neighbours on the colour wheel or across it, at a random angle and width.
    static func random(levels: [Color]) -> ShareStripes {
        let colors: [Color]
        if Bool.random() {
            colors = presets(levels: levels).randomElement()?.colors ?? defaultColors
        } else {
            let hue = Double.random(in: 0..<1)
            // Close neighbours, a third of the way round, or opposite.
            let step = [0.05, 0.09, 0.33, 0.5].randomElement() ?? 0.09
            colors = (0..<Int.random(in: 2...5)).map { index in
                Color(
                    hue: (hue + step * Double(index)).truncatingRemainder(dividingBy: 1),
                    saturation: Double.random(in: 0.45...0.9), brightness: Double.random(in: 0.65...0.98))
            }
        }
        return ShareStripes(
            colors: colors, angle: [0, 15, 30, 45, 60, 90, 120, 135, 150, 165].randomElement() ?? defaultAngle,
            width: Double(Int.random(in: 10...60)))
    }

    /// Colours as they're kept: six-digit codes such as FF5E62, separated by commas.
    static func encode(_ colors: [Color]) -> String {
        colors.map { color in
            let resolved = color.resolve(in: EnvironmentValues())
            func byte(_ component: Float) -> Int { Int((max(0, min(1, component)) * 255).rounded()) }
            return String(format: "%02X%02X%02X", byte(resolved.red), byte(resolved.green), byte(resolved.blue))
        }
        .joined(separator: ",")
    }

    /// One colour as it's kept, such as FF5E62.
    static func code(of color: Color) -> String {
        encode([color])
    }

    /// One colour from its code, or nil where the code isn't one.
    static func color(code: String) -> Color? {
        UInt32(code, radix: 16).map(color(hex:))
    }

    static func decode(_ code: String) -> [Color] {
        let colors = code.split(separator: ",").compactMap { UInt32($0, radix: 16) }.map(color(hex:))
        return colors.count >= fewest ? Array(colors.prefix(most)) : defaultColors
    }

    private static func color(hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}

/// Bands of colour across the card, each colour in turn, at the stripes' width and angle.
struct StripesPattern: View {
    var stripes: ShareStripes

    var body: some View {
        Canvas { context, size in
            let colors = stripes.colors.isEmpty ? [Color.gray] : stripes.colors
            // Long enough, turned any way, to reach every corner.
            let reach = hypot(size.width, size.height)
            let width = max(stripes.width, 2)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(stripes.angle))
            var index = 0
            var x = -reach / 2
            while x < reach / 2 {
                // A hair wider than the step, so no seam shows between neighbours.
                context.fill(
                    Path(CGRect(x: x, y: -reach / 2, width: width + 0.6, height: reach)),
                    with: .color(colors[index % colors.count]))
                x += width
                index += 1
            }
        }
        .allowsHitTesting(false)
    }
}
