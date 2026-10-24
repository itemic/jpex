import SwiftUI
import UIKit

/// The colours and type of one of the share card's designs. They're fixed, whatever the device's own
/// appearance, since the card is a picture that other people see.
struct ShareCardPalette {
    /// The appearance the card's own controls take on, such as the level pills' shadows.
    var colorScheme: ColorScheme
    /// The card's paper, from top to bottom. On the flag design it's a shade laid over the flag.
    var background: [Color]
    /// What's laid on the paper, beneath or over it.
    var pattern: Pattern
    /// The sea inside a whole World's edge, and its lines of latitude and longitude.
    var sea: Color
    var graticule: Color
    /// Places in the list not yet been to, and places around it outside the list.
    var land: Color
    var outsideLand: Color
    var border: Color
    /// A line round each place been to, so its colour stands clear of a colourful card.
    var visitedOutline: Color?
    /// The fine line round the card, as round a trading card.
    var frame: Color
    var text: Color
    var secondaryText: Color
    /// The pass torn along the foot, with the app's name on it.
    var pass: Color
    var perforation: Color
    /// The App Store code's dots, and the tile they sit on, always dark on light so cameras read it.
    /// The code is shelved for now, in Archive/ShareQRCode, ready to come back.
    var code: Color
    var codePaper: Color
    /// The share button's colour.
    var accent: Color
    /// Whether places been to glow, as they do on a dark card.
    var glows: Bool
    /// Whether the words cast a soft shadow, to stand clear of a busy card such as stripes.
    var textShadow = false
    /// The colour the person has chosen for places coloured plainly, in place of the design's own.
    var plainOverride: Color? = nil
    var fontDesign: Font.Design
    /// An Instagram story's background, top and bottom, around the card as a sticker.
    var storyTop: Color
    var storyBottom: Color
    /// Lively colours that suit the design, for colouring the places smartly, each place its own.
    var smart: [Color] = []

    enum Pattern {
        case plain
        /// Stars across the sky, a few of them sparkling.
        case stars
        /// A candy shine across the top, as on the app's pills.
        case gloss
        /// A tartan of the card's colour, as on a League Card.
        case plaid
        /// The place's own flag beneath the shade, or a patchwork of the places' flags.
        case flag
        /// Bands of the person's colours beneath the shade, at their width and angle.
        case stripes
    }

    /// A place's name in the typographic designs, faint for somewhere not yet been to. By levels,
    /// its level's colour, matching the key, deepened only where a pale level such as yellow needs it
    /// to read on a light card. By flags, its flag's stripes, crisp rather than blended, leaving out
    /// any too close to the paper to read, such as white on a white card. Plain, the colour chosen
    /// for it, or the card's ink.
    @MainActor func wordFill(_ word: ShareWord, colouring: MapShareContent.Colouring) -> AnyShapeStyle {
        let (colors, runsAcross) = wordColors(word, colouring: colouring)
        guard colors.count > 1 else { return AnyShapeStyle(colors.first ?? text) }
        return AnyShapeStyle(LinearGradient(
            stops: Self.stripes(of: colors), startPoint: runsAcross ? .leading : .top,
            endPoint: runsAcross ? .trailing : .bottom))
    }

    /// A name's colours as `wordFill(_:colouring:)` sets them, for drawing it in a canvas across the
    /// rectangle it's drawn in.
    @MainActor func wordShading(
        _ word: ShareWord, colouring: MapShareContent.Colouring, in rect: CGRect
    ) -> GraphicsContext.Shading {
        let (colors, runsAcross) = wordColors(word, colouring: colouring)
        guard colors.count > 1 else { return .color(colors.first ?? text) }
        return .linearGradient(
            Gradient(stops: Self.stripes(of: colors)),
            startPoint: runsAcross ? CGPoint(x: rect.minX, y: rect.midY) : CGPoint(x: rect.midX, y: rect.minY),
            endPoint: runsAcross ? CGPoint(x: rect.maxX, y: rect.midY) : CGPoint(x: rect.midX, y: rect.maxY))
    }

    /// The colours a name is set in, as `wordFill(_:colouring:)` describes: one, or a flag's
    /// stripes, in order, running across the name or down it as the flag's own do.
    @MainActor func wordColors(
        _ word: ShareWord, colouring: MapShareContent.Colouring
    ) -> (colors: [Color], runsAcross: Bool) {
        guard word.isVisited else { return ([secondaryText.opacity(0.6)], true) }
        switch colouring {
        case .levels:
            return ([readable(word.level.color)], true)
        case .plain:
            return ([plainOverride ?? text], true)
        case .smart:
            return ([readable(word.smart ?? accent)], true)
        case .flags:
            guard let flag = FlagColors.of(word.flag) else { return ([text], true) }
            let readable = flag.colors.filter(standsOut)
            return (readable.isEmpty ? [text] : readable, flag.runsAcross)
        }
    }

    /// A colour kept as it is, as the levels' key shows it, but on a light card deepened as far as it
    /// must be to read, as a pale yellow is. On a dark card it's kept as it is, the halo round busy
    /// paper keeping it clear.
    private func readable(_ color: Color) -> Color {
        colorScheme == .light ? Self.deepened(color, toAtMost: 0.36) : color
    }

    /// Colours as stripes of equal width with hard edges, rather than blending into one another.
    static func stripes(of colors: [Color]) -> [Gradient.Stop] {
        let step = 1 / Double(max(colors.count, 1))
        return colors.enumerated().flatMap { index, color in
            [
                Gradient.Stop(color: color, location: Double(index) * step),
                Gradient.Stop(color: color, location: Double(index + 1) * step),
            ]
        }
    }

    /// The colour the places been to take on the map when it's plain: the person's own, or something
    /// that stands clear of the land on every design.
    var plainFill: Color {
        if let plainOverride { return plainOverride }
        return switch pattern {
        case .plain: accent
        case .stars, .flag: Color(red: 1, green: 0.84, blue: 0.38)
        case .gloss, .plaid, .stripes: Color(white: 0.12)
        }
    }

    /// A soft glow round the names on a busy card, such as plaid or stripes, dark round light names
    /// and light round dark ones, so they read over the pattern without anything covering it; nil on
    /// calm paper, which needs none.
    var halo: Color? {
        guard textShadow else { return nil }
        return colorScheme == .dark ? .black.opacity(0.6) : .white.opacity(0.85)
    }

    /// Whether a colour stands clear enough of the card's paper to set a name in.
    func standsOut(_ color: Color) -> Bool {
        let luminance = Self.luminance(of: color)
        let paper = colorScheme == .light ? 0.85 : 0.03
        return (max(luminance, paper) + 0.05) / (min(luminance, paper) + 0.05) >= 1.7
    }

    /// How light a colour looks, from 0 for black to 1 for white.
    static func luminance(of color: Color) -> Double {
        let resolved = color.resolve(in: EnvironmentValues())
        return Double(0.2126 * resolved.linearRed + 0.7152 * resolved.linearGreen + 0.0722 * resolved.linearBlue)
    }

    /// A colour darkened only as far as it must be to look no lighter than a limit: a pale colour
    /// such as yellow turns a deep ochre, while one already deep, such as rust, stays as it is.
    static func deepened(_ color: Color, toAtMost limit: Double) -> Color {
        var color = color
        for _ in 0..<12 where luminance(of: color) > limit {
            color = color.mix(with: .black, by: 0.15)
        }
        return color
    }

    static let paper = ShareCardPalette(
        colorScheme: .light,
        background: [Color(white: 1), Color(red: 0.945, green: 0.945, blue: 0.96)],
        pattern: .plain,
        sea: Color(red: 0.925, green: 0.925, blue: 0.945),
        graticule: .black.opacity(0.05),
        land: Color(red: 0.85, green: 0.85, blue: 0.87),
        outsideLand: Color(red: 0.9, green: 0.9, blue: 0.915),
        border: .white,
        visitedOutline: nil,
        frame: .black.opacity(0.09),
        text: Color(red: 0.11, green: 0.11, blue: 0.12),
        secondaryText: Color(red: 0.54, green: 0.54, blue: 0.56),
        pass: .white,
        perforation: .black.opacity(0.14),
        code: Color(red: 0.11, green: 0.11, blue: 0.12),
        codePaper: Color(red: 0.95, green: 0.95, blue: 0.965),
        accent: Color(red: 0.16, green: 0.62, blue: 0.9),
        glows: false,
        fontDesign: .default,
        storyTop: Color(red: 0.96, green: 0.96, blue: 0.97),
        storyBottom: Color(red: 0.82, green: 0.82, blue: 0.86),
        // Bright candy on white.
        smart: [
            Color(red: 0.94, green: 0.33, blue: 0.38), Color(red: 0.13, green: 0.58, blue: 0.92),
            Color(red: 0.24, green: 0.66, blue: 0.33), Color(red: 0.55, green: 0.33, blue: 0.88),
            Color(red: 0.97, green: 0.52, blue: 0.12), Color(red: 0.93, green: 0.33, blue: 0.62),
            Color(red: 0.05, green: 0.6, blue: 0.62), Color(red: 0.88, green: 0.68, blue: 0.1),
        ])

    static let night = ShareCardPalette(
        colorScheme: .dark,
        background: [Color(red: 0.09, green: 0.2, blue: 0.42), Color(red: 0.02, green: 0.05, blue: 0.13)],
        pattern: .stars,
        sea: Color(red: 0.07, green: 0.17, blue: 0.36).opacity(0.6),
        graticule: .white.opacity(0.07),
        // Slate land in the dark, so the places been to glow out of it.
        land: Color(red: 0.36, green: 0.45, blue: 0.62),
        outsideLand: Color(red: 0.36, green: 0.45, blue: 0.62).opacity(0.45),
        border: Color(red: 0.05, green: 0.12, blue: 0.27),
        visitedOutline: nil,
        frame: Color(red: 0.6, green: 0.82, blue: 1).opacity(0.35),
        text: .white,
        secondaryText: .white.opacity(0.62),
        pass: Color(red: 0.03, green: 0.07, blue: 0.17),
        perforation: .white.opacity(0.22),
        code: Color(red: 0.03, green: 0.07, blue: 0.17),
        codePaper: Color(red: 0.95, green: 0.96, blue: 1),
        accent: Color(red: 0.25, green: 0.5, blue: 1),
        glows: true,
        fontDesign: .default,
        storyTop: Color(red: 0.09, green: 0.2, blue: 0.42),
        storyBottom: Color(red: 0.01, green: 0.03, blue: 0.09),
        smart: neon)

    static let atlas = ShareCardPalette(
        colorScheme: .light,
        background: [Color(red: 0.96, green: 0.92, blue: 0.83), Color(red: 0.91, green: 0.85, blue: 0.72)],
        pattern: .plain,
        sea: Color(red: 0.83, green: 0.88, blue: 0.85),
        graticule: Color(red: 0.55, green: 0.42, blue: 0.24).opacity(0.18),
        land: Color(red: 0.91, green: 0.86, blue: 0.72),
        outsideLand: Color(red: 0.94, green: 0.9, blue: 0.8),
        border: Color(red: 0.72, green: 0.6, blue: 0.42),
        visitedOutline: nil,
        frame: Color(red: 0.55, green: 0.42, blue: 0.24).opacity(0.7),
        text: Color(red: 0.23, green: 0.16, blue: 0.09),
        secondaryText: Color(red: 0.55, green: 0.42, blue: 0.24),
        pass: Color(red: 0.97, green: 0.94, blue: 0.87),
        perforation: Color(red: 0.55, green: 0.42, blue: 0.24).opacity(0.4),
        code: Color(red: 0.23, green: 0.16, blue: 0.09),
        codePaper: Color(red: 1, green: 0.98, blue: 0.94),
        accent: Color(red: 0.63, green: 0.32, blue: 0.18),
        glows: false,
        fontDesign: .serif,
        storyTop: Color(red: 0.95, green: 0.9, blue: 0.8),
        storyBottom: Color(red: 0.8, green: 0.72, blue: 0.56),
        // An old atlas's inks.
        smart: [
            Color(red: 0.72, green: 0.3, blue: 0.18), Color(red: 0.25, green: 0.38, blue: 0.62),
            Color(red: 0.8, green: 0.58, blue: 0.16), Color(red: 0.18, green: 0.48, blue: 0.5),
            Color(red: 0.52, green: 0.24, blue: 0.42), Color(red: 0.45, green: 0.52, blue: 0.2),
        ])

    /// Glossy as the app's candy, in one colour, with rounded type.
    static func candy(_ tint: ShareTint) -> ShareCardPalette {
        let color = tint.color
        let ink = tint.prefersDarkText ? Color(red: 0.24, green: 0.16, blue: 0.02) : .white
        return ShareCardPalette(
            colorScheme: tint.prefersDarkText ? .light : .dark,
            background: [color.mix(with: .white, by: 0.18), color.mix(with: .black, by: 0.18)],
            pattern: .gloss,
            sea: .white.opacity(0.12),
            graticule: .white.opacity(0.14),
            land: .white.opacity(0.82),
            outsideLand: .white.opacity(0.45),
            border: color.mix(with: .black, by: 0.3).opacity(0.55),
            visitedOutline: .white,
            frame: .white.opacity(0.55),
            text: ink,
            secondaryText: ink.opacity(0.78),
            pass: Self.passColor(on: tint, darkenedBy: 0.32),
            perforation: tint.prefersDarkText ? ink.opacity(0.3) : .white.opacity(0.45),
            code: color.mix(with: .black, by: 0.55),
            codePaper: .white,
            accent: Self.buttonColor(for: tint),
            glows: false,
            textShadow: true,
            fontDesign: .rounded,
            storyTop: color.mix(with: .white, by: 0.3),
            storyBottom: color.mix(with: .black, by: 0.35),
            smart: Self.smart(around: tint))
    }

    /// The pass on a card of one colour: a deeper shade of it, for light words; or for dark words, as
    /// on yellow, a pale one, so they stay as clear on the pass as on the card.
    private static func passColor(on tint: ShareTint, darkenedBy amount: Double) -> Color {
        tint.prefersDarkText ? tint.color.mix(with: .white, by: 0.62) : tint.color.mix(with: .black, by: amount)
    }

    /// The share button on a card of one colour: the colour itself; or for one dark words suit, as
    /// yellow, a deeper honey, so the button's white lettering reads.
    private static func buttonColor(for tint: ShareTint) -> Color {
        tint.prefersDarkText ? deepened(tint.color.mix(with: .orange, by: 0.35), toAtMost: 0.3) : tint.color
    }

    /// Neon on a dark card.
    private static let neon = [
        Color(red: 1, green: 0.42, blue: 0.72), Color(red: 0.35, green: 0.9, blue: 1),
        Color(red: 0.72, green: 1, blue: 0.38), Color(red: 0.72, green: 0.55, blue: 1),
        Color(red: 1, green: 0.78, blue: 0.32), Color(red: 0.42, green: 1, blue: 0.78),
        Color(red: 1, green: 0.55, blue: 0.48),
    ]

    /// Colours round the colour wheel from a card's own, its opposite first: bright and light on a
    /// card dark words don't suit, deep on one they do, such as yellow.
    private static func smart(around tint: ShareTint) -> [Color] {
        var hue: CGFloat = 0
        UIColor(tint.color).getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        return [0.5, 0.33, 0.67, 0.42, 0.58, 0.17, 0.83].map { turn in
            let turned = (hue + turn).truncatingRemainder(dividingBy: 1)
            return tint.prefersDarkText
                ? Color(hue: turned, saturation: 0.85, brightness: 0.55)
                : Color(hue: turned, saturation: 0.5, brightness: 1)
        }
    }

    /// A tartan of one colour, as a League Card's plaid.
    static func plaid(_ tint: ShareTint) -> ShareCardPalette {
        let color = tint.color
        let ink = tint.prefersDarkText ? Color(red: 0.24, green: 0.16, blue: 0.02) : .white
        return ShareCardPalette(
            colorScheme: tint.prefersDarkText ? .light : .dark,
            background: [color.mix(with: .white, by: 0.08), color.mix(with: .black, by: 0.12)],
            pattern: .plaid,
            sea: .white.opacity(0.14),
            graticule: .white.opacity(0.16),
            land: .white.opacity(0.95),
            outsideLand: .white.opacity(0.62),
            border: color.mix(with: .black, by: 0.35).opacity(0.6),
            visitedOutline: .white,
            frame: .white.opacity(0.6),
            text: ink,
            secondaryText: ink.opacity(0.82),
            pass: Self.passColor(on: tint, darkenedBy: 0.4),
            perforation: tint.prefersDarkText ? ink.opacity(0.3) : .white.opacity(0.45),
            code: color.mix(with: .black, by: 0.55),
            codePaper: .white,
            accent: Self.buttonColor(for: tint),
            glows: false,
            textShadow: true,
            fontDesign: .default,
            storyTop: color.mix(with: .white, by: 0.2),
            storyBottom: color.mix(with: .black, by: 0.4),
            smart: Self.smart(around: tint))
    }

    /// Stripes of the person's colours, as in Deco, beneath a light shade; the land a white sticker
    /// over them and the words shadowed to stand clear.
    static func stripes(_ stripes: ShareStripes) -> ShareCardPalette {
        let first = stripes.colors.first ?? .gray
        let last = stripes.colors.last ?? .gray
        return ShareCardPalette(
            colorScheme: .dark,
            background: [.black.opacity(0.1), .black.opacity(0.24)],
            pattern: .stripes,
            sea: .white.opacity(0.22),
            graticule: .white.opacity(0.2),
            land: .white.opacity(0.94),
            outsideLand: .white.opacity(0.6),
            border: .black.opacity(0.16),
            visitedOutline: .white,
            frame: .white.opacity(0.7),
            text: .white,
            secondaryText: .white.opacity(0.9),
            pass: Color(white: 0.08).opacity(0.9),
            perforation: .white.opacity(0.35),
            code: Color(white: 0.08),
            codePaper: .white,
            // Deep enough for the share button's white lettering, should the first stripe be pale.
            accent: deepened(first, toAtMost: 0.3),
            glows: false,
            textShadow: true,
            fontDesign: .default,
            storyTop: first,
            storyBottom: last,
            // The person's own stripes, lightened to stand out over them.
            smart: stripes.colors.map { $0.mix(with: .white, by: 0.35) })
    }

    /// The place's flag beneath a shade, the land pale over it and the places been to glowing.
    static let flag = ShareCardPalette(
        colorScheme: .dark,
        background: [.black.opacity(0.5), .black.opacity(0.68)],
        pattern: .flag,
        // The World's shape and its land solid enough that the flags beneath don't show through it.
        sea: .black.opacity(0.4),
        graticule: .white.opacity(0.12),
        land: .white.opacity(0.9),
        outsideLand: .white.opacity(0.55),
        border: .black.opacity(0.3),
        visitedOutline: .white,
        frame: .white.opacity(0.5),
        text: .white,
        secondaryText: .white.opacity(0.8),
        pass: Color(white: 0.07).opacity(0.94),
        perforation: .white.opacity(0.35),
        code: Color(white: 0.07),
        codePaper: .white,
        accent: Color(red: 0.3, green: 0.3, blue: 0.36),
        glows: true,
        textShadow: true,
        fontDesign: .default,
        storyTop: Color(white: 0.2),
        storyBottom: Color(white: 0.04),
        smart: neon)
}
