import SwiftUI

/// Sets local names by their own script's rules: Japanese glyph shapes for 京都府, Traditional
/// Chinese ones for 臺灣, Han characters never squeezed together, and room above and below the
/// line for scripts such as Thai and Sinhala.
enum PlaceTypesetting {
    /// The language a country's local names are written in, where it changes how they're set.
    static func language(forCode code: String) -> Locale.Language? {
        languageIdentifiers[code].map { Locale.Language(identifier: $0) }
    }

    /// Chinese, Japanese and Korean, whose characters keep their full width.
    static func isCJK(_ language: Locale.Language?) -> Bool {
        guard let code = language?.languageCode?.identifier else { return false }
        return ["ja", "zh", "ko"].contains(code)
    }

    /// Han characters look starved at the light weights the app sets Latin names in, so they
    /// step up one weight.
    static func weight(_ weight: Font.Weight, for language: Locale.Language?) -> Font.Weight {
        guard isCJK(language) else { return weight }
        switch weight {
        case .ultraLight, .thin: return .light
        case .light: return .regular
        default: return weight
        }
    }

    private static let languageIdentifiers: [String: String] = {
        var identifiers = [
            "JP": "ja", "CN": "zh-Hans", "SG": "zh-Hans", "TW": "zh-Hant", "HK": "zh-Hant", "MO": "zh-Hant",
            "KR": "ko", "KP": "ko", "TH": "th", "LA": "lo", "KH": "km", "MM": "my", "VN": "vi",
            "IN": "hi", "NP": "ne", "BD": "bn", "LK": "si", "BT": "dz", "MV": "dv", "PK": "ur", "AF": "ps", "IR": "fa",
            "GR": "el", "CY": "el", "GE": "ka", "AM": "hy", "IL": "he", "ET": "am", "ER": "ti",
            "RU": "ru", "UA": "uk", "BY": "be", "BG": "bg", "RS": "sr", "MK": "mk", "MN": "mn",
            "KZ": "kk", "KG": "ky", "TJ": "tg",
        ]
        for code in ["AE", "SA", "EG", "IQ", "JO", "KW", "LB", "LY", "MA", "OM", "QA", "SY", "TN", "YE", "BH", "DZ", "SD", "PS", "MR"] {
            identifiers[code] = "ar"
        }
        return identifiers
    }()
}

extension AdministrativeDivision {
    /// The language this place's local name is written in, where it matters for setting it.
    var localNameLanguage: Locale.Language? {
        PlaceTypesetting.language(forCode: countryID == CountryCatalog.world.id ? abbreviation : countryID)
    }

    /// The language to set one of this place's names in: its local name's language, or none
    /// for its English or formal name.
    func language(of text: String) -> Locale.Language? {
        text == localName && text != name ? localNameLanguage : nil
    }
}

extension Text {
    /// Sets a place name in its own language, keeping the tight tracking of Latin names off Han characters.
    func placeName(_ language: Locale.Language?, kerning: CGFloat = 0) -> Text {
        let text = self.kerning(PlaceTypesetting.isCJK(language) ? 0 : kerning)
        guard let language else { return text }
        return text.typesettingLanguage(language)
    }
}
