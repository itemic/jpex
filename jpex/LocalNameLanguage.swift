import Foundation

extension Country {
    /// The language its places' own names are written in, named in English, to set beside English
    /// where names can be shown either way: such as Japanese, Dutch and French for Belgium, or for
    /// the World and its groups, whose countries each have their own, Native.
    var localNamesLanguage: String {
        if id == CountryCatalog.world.id || isGroupOfCountries { return "Native" }
        let english = Locale(identifier: "en")
        let names = (Self.localNameLanguages[countryListID] ?? []).compactMap { english.localizedString(forLanguageCode: $0) }
        return names.isEmpty ? "Local" : names.formatted(.list(type: .and))
    }

    /// The languages of each country's places' own names, by the country's code, the main one first.
    private static let localNameLanguages: [String: [String]] = [
        "AL": ["sq"], "AM": ["hy"], "AR": ["es"], "AT": ["de"], "BA": ["bs"], "BD": ["bn"], "BE": ["nl", "fr"],
        "BG": ["bg"], "BH": ["ar"], "BO": ["es"], "BR": ["pt"], "BT": ["dz"], "BY": ["be"], "CA": ["fr"],
        "CH": ["de", "fr", "it"], "CL": ["es"], "CN": ["zh"], "CO": ["es"], "CR": ["es"], "CU": ["es"], "CZ": ["cs"],
        "DE": ["de"], "DK": ["da"], "DO": ["es"], "DZ": ["ar"], "EC": ["es"], "EE": ["et"], "EG": ["ar"], "ES": ["es"],
        "FI": ["fi"], "FJ": ["fj"], "FR": ["fr"], "GR": ["el"], "GT": ["es"], "HN": ["es"], "HR": ["hr"], "HU": ["hu"],
        "ID": ["id"], "IE": ["ga"], "IN": ["hi"], "IQ": ["ar"], "IR": ["fa"], "IS": ["is"], "IT": ["it"], "JO": ["ar"],
        "JP": ["ja"], "KE": ["sw"], "KG": ["ky"], "KH": ["km"], "KR": ["ko"], "KW": ["ar"], "KZ": ["kk"], "LA": ["lo"],
        "LK": ["si"], "LT": ["lt"], "LU": ["lb"], "LV": ["lv"], "ME": ["cnr"], "MN": ["mn"], "MT": ["mt"], "MX": ["es"],
        "MY": ["ms"], "NL": ["nl"], "NO": ["no"], "NP": ["ne"], "NZ": ["mi"], "OM": ["ar"], "PA": ["es"], "PE": ["es"],
        "PG": ["tpi"], "PH": ["fil"], "PL": ["pl"], "PT": ["pt"], "PY": ["es"], "QA": ["ar"], "RO": ["ro"], "RS": ["sr"],
        "RU": ["ru"], "RW": ["rw"], "SA": ["ar"], "SE": ["sv"], "SK": ["sk"], "SN": ["fr"], "SV": ["es"], "TH": ["th"],
        "TN": ["ar"], "TR": ["tr"], "TW": ["zh"], "TZ": ["sw"], "UA": ["uk"], "UY": ["es"], "UZ": ["uz"], "VE": ["es"],
        "AE": ["ar"],
    ]
}
