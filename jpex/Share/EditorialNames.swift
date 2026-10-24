import SwiftUI
import UIKit

/// The names layout's editorial style: every place been to as one sentence in a fashion magazine's
/// italic, "Hokkaido, Aomori, Iwate & Miyagi", its lines centred. Each name takes its colours, the
/// commas and ampersand stay quiet in the card's grey, and a name never breaks across two lines.
struct EditorialNames: View {
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring

    /// The space between names, and how far apart lines sit, per point of type: close, as a headline's.
    private static let gap: CGFloat = 0.26
    private static let pitch: CGFloat = 1.1
    /// The type's own line, per point.
    private static let lineHeight = uiFont(size: 100).lineHeight / 100

    /// A piece of the sentence the lines break between: a name, with the comma after it or the
    /// ampersand before it.
    private struct Phrase: Identifiable {
        var word: ShareWord
        var before = ""
        var after = ""

        var id: String { word.id }
        var whole: String { before + word.name + after }
    }

    var body: some View {
        GeometryReader { proxy in
            let phrases = phrases
            let flow = NameFlow.fit(
                widths: NameFlow.widths(of: phrases.map(\.whole), font: Self.uiFont), in: proxy.size,
                gap: Self.gap, lineHeight: Self.lineHeight, pitch: Self.pitch, largest: 84)
            NameLines(
                spacing: flow.size * Self.gap, lineSpacing: flow.size * (Self.pitch - Self.lineHeight), justifies: false
            ) {
                ForEach(phrases) { phrase in
                    text(phrase)
                        .font(Self.font(size: flow.size))
                        .fixedSize()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    /// The names as a list in a sentence: commas between, and an ampersand before the last; or for
    /// Chinese, Japanese and Korean names, their own list comma between every one.
    private var phrases: [Phrase] {
        let isCJK = PlaceTypesetting.isCJK(language)
        return words.enumerated().map { index, word in
            var phrase = Phrase(word: word)
            let isLast = index == words.count - 1
            if isCJK {
                if !isLast { phrase.after = "、" }
            } else if isLast, words.count > 1 {
                phrase.before = "& "
            } else if index < words.count - 2 {
                phrase.after = ","
            }
            return phrase
        }
    }

    private func text(_ phrase: Phrase) -> Text {
        let quiet = palette.secondaryText
        let name = Text(phrase.word.name)
            .placeName(language)
            .foregroundStyle(palette.wordFill(phrase.word, colouring: colouring))
        return Text("\(Text(phrase.before).foregroundStyle(quiet))\(name)\(Text(phrase.after).foregroundStyle(quiet))")
    }

    /// Didot's italic, as on a fashion magazine's cover; the system's serif italic should it be missing.
    static func font(size: CGFloat) -> Font {
        hasDidot ? .custom("Didot-Italic", fixedSize: size) : .system(size: size, design: .serif).italic()
    }

    private static func uiFont(size: CGFloat) -> UIFont {
        if let didot = UIFont(name: "Didot-Italic", size: size) { return didot }
        let font = UIFont.systemFont(ofSize: size)
        guard let descriptor = font.fontDescriptor.withDesign(.serif)?.withSymbolicTraits(.traitItalic) else { return font }
        return UIFont(descriptor: descriptor, size: size)
    }

    private static let hasDidot = UIFont(name: "Didot-Italic", size: 12) != nil
}
