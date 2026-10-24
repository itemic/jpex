/// The share screen's tools, as a photo editor's: each brings up its own choices beneath the card.
enum ShareTool: String, CaseIterable, Identifiable {
    /// The map, the names, the word map or the count, and for the names, their type.
    case layout
    /// The card's design, and its colour or stripes.
    case design
    /// What colours the places: their levels, their flags, or the card's one colour.
    case colouring
    /// Square, tall or wide.
    case shape
    /// The foil, the flags pinned on the map, and the date.
    case extras

    var id: Self { self }

    var name: String {
        switch self {
        case .layout: "Layout"
        case .design: "Design"
        case .colouring: "Colour"
        case .shape: "Shape"
        case .extras: "Extras"
        }
    }

    var symbolName: String {
        switch self {
        case .layout: "rectangle.3.group"
        case .design: "paintpalette"
        case .colouring: "swatchpalette"
        case .shape: "aspectratio"
        case .extras: "sparkles"
        }
    }
}
