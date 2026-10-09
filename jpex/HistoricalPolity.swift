/// A state, empire or people that held land in one of Time Machine's eras, such as the British
/// Empire, or a country as it is today.
struct HistoricalPolity: Identifiable, Sendable {
    var id: String
    var name: String
    /// The flag it flew then, from the asset catalogue, or nil where there's none to show.
    var flagAssetName: String?
    /// A named colour, or the code of the country whose colour it takes, so a power keeps one
    /// colour from era to era.
    var colorKey: String
    var kind: PolityKind
}

/// How a polity is drawn.
enum PolityKind: String, Sendable {
    /// A country or a state: a full border all round.
    case state
    /// An empire with its colonies: one colour, the colonies divided by fine dashed lines.
    case empire
    /// Land with no state the map can honestly draw, such as much of inner Africa in 1815: soft
    /// earth, with no borders inside it.
    case indigenous
    /// Land no one had claimed, such as Antarctica before 1908.
    case unclaimed
    /// Land held by one power and claimed by another, drawn hatched.
    case contested
}
