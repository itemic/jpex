import Foundation

/// A group of collections in the sidebar and country menu, such as Europe.
struct CollectionSection: Identifiable {
    /// No title for the pinned collections at the top.
    var title: String?
    var countries: [Country]
    var id: String { title ?? "Pinned" }

    /// The title of the section of groups of countries, such as the EU, which can be folded away.
    static let worldGroupsTitle = "World Groups"
}
