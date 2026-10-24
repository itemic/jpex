import SwiftUI

/// The names layout: every place been to, each named once and all at one size, so none looks more
/// important than another, set in the style the person chooses: a justified block, a magazine's
/// sentence, a poster's outlines, candy pills, a spiral or a typed checklist.
struct ShareNames: View {
    var style: MapShareContent.NamesStyle
    var words: [ShareWord]
    var language: Locale.Language?
    var palette: ShareCardPalette
    var colouring: MapShareContent.Colouring

    var body: some View {
        switch style {
        case .block:
            BlockNames(words: words, language: language, palette: palette, colouring: colouring)
        case .editorial:
            EditorialNames(words: words, language: language, palette: palette, colouring: colouring)
        case .outline:
            OutlineNames(words: words, language: language, palette: palette, colouring: colouring)
        case .pills:
            PillNames(words: words, language: language, palette: palette, colouring: colouring)
        case .spiral:
            SpiralNames(words: words, language: language, palette: palette, colouring: colouring)
        case .checklist:
            ChecklistNames(words: words, language: language, palette: palette, colouring: colouring)
        }
    }
}
