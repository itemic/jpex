import Foundation

struct DivisionGroup: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var localName: String?
    var divisions: [AdministrativeDivision]

    func displayName(localLanguage: Bool) -> String {
        localLanguage ? (localName ?? name) : name
    }
}
