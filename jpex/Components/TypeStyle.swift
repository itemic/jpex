import SwiftUI
import UIKit

/// The app's type scale, so every screen sets text the same way:
///
/// - Places and big numbers are the heroes. Names are large and light, and counts thinner still,
///   so they feel airy and let the flags behind them show through.
/// - Structure, such as screen titles and region headers, is medium, so it anchors without shouting.
/// - Small labels, such as eyebrows and counts, are semibold or medium, so they stay crisp at
///   caption sizes. They're in sentence case: capitals are kept for the level pills, so they stand out.
///
/// Every size scales with Dynamic Type from its base, and local names keep their script's rules.
struct TypeStyle: Equatable {
    /// The size at the default text size.
    var size: CGFloat
    /// The text style whose Dynamic Type scaling the size follows.
    var textStyle: Font.TextStyle
    var weight: Font.Weight
    /// Space added between letters. Negative tightens large Latin names; Han characters ignore it.
    var spacing: CGFloat = 0
    /// Set in capitals, tracked open so they don't crowd.
    var isCapitals = false
    /// Figures of equal width, so counts don't jostle as they change.
    var hasTabularFigures = false
}

extension TypeStyle {
    /// The running total's count, such as the 12 in 12 / 47.
    static let heroCount = TypeStyle(size: 64, textStyle: .largeTitle, weight: .thin, spacing: -1.5, hasTabularFigures: true)
    /// What the running total is out of, set beside it.
    static let heroTotal = TypeStyle(size: 26, textStyle: .title, weight: .light)
    /// A count heading a panel, smaller than the hero so the map stays in charge.
    static let panelCount = TypeStyle(size: 40, textStyle: .largeTitle, weight: .light, spacing: -0.8)
    /// What a panel's count is out of.
    static let panelTotal = TypeStyle(size: 20, textStyle: .title3, weight: .light)

    /// A place's name in its row, card or sheet.
    static let placeName = TypeStyle(size: 32, textStyle: .title, weight: .light, spacing: -0.5)
    /// A place's name in a compact row, or a collection's name in the sidebar.
    static let compactPlaceName = TypeStyle(size: 22, textStyle: .title2, weight: .light, spacing: -0.4)
    /// A place's name in an extra compact row, the smallest. At body size, light would read thin, so it's regular.
    static let extraCompactPlaceName = TypeStyle(size: 17, textStyle: .body, weight: .regular, spacing: -0.3)
    /// The line beneath a name: its name in the other language, or its formal name.
    static let placeSubtitle = TypeStyle(size: 18, textStyle: .body, weight: .regular, spacing: -0.3)
    static let compactPlaceSubtitle = TypeStyle(size: 15, textStyle: .subheadline, weight: .regular, spacing: -0.2)
    static let extraCompactPlaceSubtitle = TypeStyle(size: 13, textStyle: .footnote, weight: .regular, spacing: -0.1)

    /// A region's name, heading its part of a list.
    static let sectionTitle = TypeStyle(size: 24, textStyle: .title2, weight: .medium, spacing: 0.3)
    static let compactSectionTitle = TypeStyle(size: 19, textStyle: .title3, weight: .medium, spacing: 0.3)
    static let extraCompactSectionTitle = TypeStyle(size: 16, textStyle: .callout, weight: .semibold, spacing: 0.2)

    /// A quiet label above a panel or a card, such as "Jump to".
    static let eyebrow = TypeStyle(size: 13, textStyle: .footnote, weight: .semibold)
    /// The smallest label, tucked tight above a place's name, such as its region or continent.
    static let smallEyebrow = TypeStyle(size: 13, textStyle: .footnote, weight: .medium)

    /// A small count, such as the 3 in 3 / 12.
    static let count = TypeStyle(size: 15, textStyle: .subheadline, weight: .semibold, hasTabularFigures: true)
    /// What a small count is out of, quieter than the count.
    static let countTotal = TypeStyle(size: 15, textStyle: .subheadline, weight: .regular, hasTabularFigures: true)
}

extension View {
    /// Sets text in one of the app's type styles. Pass a local name's language so it's set by
    /// its own script's rules: Japanese glyphs for 京都府, no squeezing for Han characters.
    func typeStyle(_ style: TypeStyle, language: Locale.Language? = nil) -> some View {
        modifier(TypeStyleModifier(style: style, language: language))
    }
}

private struct TypeStyleModifier: ViewModifier {
    var style: TypeStyle
    var language: Locale.Language?
    @ScaledMetric private var size: CGFloat

    init(style: TypeStyle, language: Locale.Language?) {
        self.style = style
        self.language = language
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        let spacing = PlaceTypesetting.isCJK(language) ? 0 : style.spacing
        let font = Font.system(size: size, weight: PlaceTypesetting.weight(style.weight, for: language))
        content
            .font(style.hasTabularFigures ? font.monospacedDigit() : font)
            // Capitals take tracking, which keeps letters apart; names take kerning, which keeps ligatures.
            .tracking(style.isCapitals ? spacing : 0)
            .kerning(style.isCapitals ? 0 : spacing)
            .textCase(style.isCapitals ? .uppercase : nil)
            .typesettingLanguage(language ?? Locale.Language(identifier: "en"), isEnabled: language != nil)
    }
}

/// Screen titles in the type scale's medium rather than the system's bold, so the light names
/// and thin counts below them lead the eye.
enum ScreenTitleStyle {
    @MainActor static func apply() {
        let large = UIFontMetrics(forTextStyle: .largeTitle)
            .scaledFont(for: .systemFont(ofSize: 34, weight: .medium))
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: large]
    }
}
