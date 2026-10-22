import SwiftUI

/// What World maps show besides the person's travels: lines and shapes drawn over the map, such
/// as the Equator and the tropics, chosen from a list's eye menu or the full map's layer chooser,
/// and, in the Atlas only, the countries coloured by something about them, such as the side of the
/// road they drive on. Only World maps know where on Earth they are, so only they show layers, and
/// maps that don't ask for them, such as the quiz's, keep to the person's travels.
struct WorldLayers: Equatable {
    var colouring = MapColouring.travels
    var showsLatitudes = false
    var showsAntipodes = false
    /// A key brought forward from the Atlas's legend, such as plug type G, by ID.
    var highlight: String?

    static let latitudesKey = "mapShowsLatitudes"
    static let antipodesKey = "mapShowsAntipodes"

    /// Whether the countries wear something other than the person's levels.
    var coloursCountries: Bool { colouring != .travels }

    /// The ISO 3166 code of the place a region of the World map stands for, such as JP for Japan,
    /// HK for Hong Kong and GB for each of the United Kingdom's countries. Nil for a region that
    /// isn't one of the World's places, such as a subdivision drawn over it.
    static func code(ofRegion id: String) -> String? {
        if id.hasPrefix("WORLD-") { return String(id.dropFirst(6)) }
        if let code = sharedCodes[id] { return code }
        return unitedKingdom.contains(id) ? "GB" : nil
    }

    /// The United Kingdom's four countries, drawn apart on the World map.
    private static let unitedKingdom: Set<String> = ["GB-ENG", "GB-NIR", "GB-SCT", "GB-WLS"]

    /// Places listed in a country's own list as well as the World, such as Hong Kong, by their shared ID.
    private static let sharedCodes = Dictionary(
        CountryCatalog.sharedPlaceIDs.map { code, id in (id, code) }) { first, _ in first }
}

extension EnvironmentValues {
    /// The layers World maps show, as the person chose them. Maps that don't set it show only travels.
    @Entry var worldLayers = WorldLayers()
}

extension View {
    /// Shows the World maps inside, in the person's own levels, with the lines and shapes they
    /// chose drawn over them.
    func showsWorldLayers() -> some View {
        modifier(ChosenWorldLayers())
    }
}

/// Reads the layers chosen from where they're kept and hands them to the maps inside.
private struct ChosenWorldLayers: ViewModifier {
    @AppStorage(WorldLayers.latitudesKey) private var showsLatitudes = false
    @AppStorage(WorldLayers.antipodesKey) private var showsAntipodes = false

    func body(content: Content) -> some View {
        content.environment(\.worldLayers, WorldLayers(showsLatitudes: showsLatitudes, showsAntipodes: showsAntipodes))
    }
}
