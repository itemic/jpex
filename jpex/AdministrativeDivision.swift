import Foundation

/// A country subdivision with a permanent identifier independent of display order.
struct AdministrativeDivision: Identifiable, Hashable, Sendable {
    let id: String
    let countryID: String
    var name: String
    var localName: String?
    var abbreviation: String
    var groupID: String
    var flagAssetName: String
    var flagNote: String?

    /// The zero-based position used by the original Japan-only store.
    /// Only Japan entries have this value; new countries never use array positions.
    var legacyJapanIndex: Int?

    /// A one-character short name, such as 京 for Beijing, as on China's licence plates.
    var shortName: String? = nil

    func displayName(localLanguage: Bool) -> String {
        localLanguage ? (localName ?? name) : name
    }

    /// The name in the other language, only when the place has a distinct local name.
    func alternateName(localLanguage: Bool) -> String? {
        guard let localName, localName != name else { return nil }
        return localLanguage ? name : localName
    }
}
