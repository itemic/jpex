import SwiftUI
import UIKit

/// The names layout's pills: every place been to on a pill of its own, the pills flowing in centred
/// lines. By levels, each is its level's glossy candy, as the app's level pills are; by flags, a
/// clear pill with the flag at its start; plain, a pill of the card's ink. Every pill is the same
/// height, its name the same size.
struct PillNames: View {
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring

    /// The room round a name inside its pill, across and down, and the space between pills, per
    /// point of type.
    private static let inset = CGSize(width: 0.75, height: 0.4)
    private static let spacing: CGFloat = 0.42
    /// A flag's width beside a name, and the space after it, per point of type.
    private static let flagWidth: CGFloat = 1.5
    private static let flagGap: CGFloat = 0.4
    /// A pill's height, per point.
    private static let pillHeight = uiFont(size: 100).lineHeight / 100 + inset.height * 2

    var body: some View {
        GeometryReader { proxy in
            let extra = Self.inset.width * 2 + (colouring == .flags ? Self.flagWidth + Self.flagGap : 0)
            let flow = NameFlow.fit(
                widths: NameFlow.widths(of: words.map { $0.name.uppercased() }, font: Self.uiFont).map { $0 + extra },
                in: proxy.size, gap: Self.spacing, lineHeight: Self.pillHeight,
                pitch: Self.pillHeight + Self.spacing, largest: 30)
            NameLines(spacing: flow.size * Self.spacing, lineSpacing: flow.size * Self.spacing, justifies: false) {
                ForEach(words) { word in
                    pill(word, size: flow.size)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func pill(_ word: ShareWord, size: CGFloat) -> some View {
        HStack(spacing: size * Self.flagGap) {
            if colouring == .flags {
                FlagThumbnail(name: word.flag, size: CGSize(width: size * Self.flagWidth, height: size))
                    .frame(width: size * Self.flagWidth, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            }
            Text(word.name.uppercased())
                .placeName(language)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(lettering(for: word))
                .fixedSize()
        }
        .padding(.horizontal, size * Self.inset.width)
        .padding(.vertical, size * Self.inset.height)
        .background { face(of: word) }
        .clipShape(Capsule())
        .shadow(color: .black.opacity(word.isVisited ? 0.2 : 0), radius: size * 0.1, y: size * 0.06)
    }

    /// The pill itself: its level's candy, a clear pill with a fine edge, or the card's ink or the
    /// colour chosen for it; and for somewhere not yet been to, only an outline.
    @ViewBuilder private func face(of word: ShareWord) -> some View {
        if !word.isVisited {
            Capsule().strokeBorder(palette.secondaryText.opacity(0.5), lineWidth: 1)
        } else {
            switch colouring {
            case .levels:
                CandyGloss(color: word.level.color, pattern: nil)
            case .smart:
                CandyGloss(color: word.smart ?? palette.accent, pattern: nil)
            case .flags:
                ZStack {
                    palette.colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.06)
                    Capsule().strokeBorder(palette.text.opacity(0.22), lineWidth: 1)
                }
            case .plain:
                palette.plainOverride ?? palette.text
            }
        }
    }

    private func lettering(for word: ShareWord) -> AnyShapeStyle {
        guard word.isVisited else { return AnyShapeStyle(palette.secondaryText) }
        switch colouring {
        case .levels:
            return AnyShapeStyle(CandyGloss.lettering(on: word.level.color))
        case .smart:
            return AnyShapeStyle(CandyGloss.lettering(on: word.smart ?? palette.accent))
        case .flags:
            return AnyShapeStyle(palette.text)
        case .plain:
            // Light on a dark pill and dark on a light one: on the card's ink, its paper.
            guard let chosen = palette.plainOverride else {
                return AnyShapeStyle(palette.colorScheme == .dark ? Color(white: 0.1) : .white)
            }
            return AnyShapeStyle(ShareCardPalette.luminance(of: chosen) > 0.45 ? Color(white: 0.1) : .white)
        }
    }

    private static func uiFont(size: CGFloat) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: .bold)
        guard let descriptor = font.fontDescriptor.withDesign(.rounded) else { return font }
        return UIFont(descriptor: descriptor, size: size)
    }
}
