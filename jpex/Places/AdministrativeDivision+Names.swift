import Foundation

extension AdministrativeDivision {
    /// The formal name of a place in the World, such as People's Republic of China.
    /// Nil for subdivisions, and for places whose formal name is their short name.
    var formalName: String? {
        guard countryID == CountryCatalog.world.id else { return nil }
        return CountryCatalog.formalNames[abbreviation]
    }

    /// The line beneath a place's name: its name in the other language where it has a distinct
    /// local one, otherwise its formal name.
    func subtitle(localLanguage: Bool) -> String? {
        alternateName(localLanguage: localLanguage) ?? formalName
    }
}
