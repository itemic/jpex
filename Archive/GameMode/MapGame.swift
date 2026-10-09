import SwiftUI

/// A round of Game Mode, and the choices for the next. In Name It a place lights up on the map and
/// you pick its name from four; in Find It you're given a name and tap the place, with three tries
/// before it's shown to you. Right first time scores most, a run of right answers adds a bonus,
/// and a hint halves what an answer is worth. Each way of playing keeps its own best score.
@MainActor
@Observable
final class MapGame: Identifiable {
    /// Tries at each place in Find It before it's shown.
    nonisolated static let tries = 3

    let collection: Country
    let map: TravelMap
    /// Every place on the map that can come up, in list order.
    let places: [AdministrativeDivision]
    /// The place each region on the map stands for: its own outline, or for a territory that
    /// doesn't count as a country, the country it belongs to.
    let regionPlaces: [String: AdministrativeDivision]
    /// The regions standing for each place, by place ID.
    let placeRegions: [String: [String]]
    /// The main body of each place on the map, for the camera to frame, by place ID.
    let frames: [String: CGRect]
    private let centers: [String: CGPoint]
    private let defaults: UserDefaults

    var mode: MapGameMode {
        didSet { defaults.set(mode.rawValue, forKey: Key.mode) }
    }
    var length: MapGameLength {
        didSet { defaults.set(length.rawValue, forKey: Key.length) }
    }
    /// The group of places to play, such as Kantō or Europe. Nil plays every place.
    var scopeID: String?

    private(set) var phase = Phase.lobby
    private(set) var questions: [Question] = []
    private(set) var index = 0
    /// How each place asked about this round went, by place ID.
    private(set) var outcomes: [String: Outcome] = [:]
    private(set) var score = 0
    /// Answers in a row right first time.
    private(set) var streak = 0
    private(set) var bestStreak = 0
    /// In Find It, the places tapped by mistake for this question.
    private(set) var wrongGuesses: [AdministrativeDivision] = []
    /// In Name It, the name chosen for this question.
    private(set) var chosen: AdministrativeDivision?
    /// In Name It, the names a hint took away.
    private(set) var eliminated: Set<String> = []
    private(set) var isHinted = false
    /// What the last answer scored, to float up from the score.
    private(set) var award: Award?
    private(set) var startDate: Date?
    private(set) var endDate: Date?
    /// The best score before this round finished, to tell a new best.
    private(set) var previousBest: Int?
    /// Best scores, by collection, mode, places and length.
    private var bests: [String: Int]

    init(collection: Country, map: TravelMap, regionOwners: [String: String] = [:], defaults: UserDefaults = .standard) {
        self.collection = collection
        self.map = map
        self.defaults = defaults
        let regions = Dictionary(map.regions.map { ($0.id, $0) }) { first, _ in first }
        let divisions = Dictionary(collection.divisions.map { ($0.id, $0) }) { first, _ in first }
        var regionPlaces: [String: AdministrativeDivision] = [:]
        var placeRegions: [String: [String]] = [:]
        for place in collection.divisions where regions[place.id] != nil {
            regionPlaces[place.id] = place
            placeRegions[place.id, default: []].append(place.id)
        }
        // Territories that don't count as countries are drawn, and answered, as their country.
        for (regionID, ownerID) in regionOwners.sorted(by: { $0.key < $1.key })
        where regions[regionID] != nil && regionPlaces[regionID] == nil {
            guard let owner = divisions[ownerID] else { continue }
            regionPlaces[regionID] = owner
            placeRegions[ownerID, default: []].append(regionID)
        }
        var frames: [String: CGRect] = [:]
        var centers: [String: CGPoint] = [:]
        for (placeID, regionIDs) in placeRegions {
            if let own = regions[placeID] {
                frames[placeID] = own.coreBounds
                centers[placeID] = own.center
            } else {
                let frame = regionIDs.compactMap { regions[$0]?.coreBounds }.reduce(CGRect.null) { $0.union($1) }
                frames[placeID] = frame
                centers[placeID] = CGPoint(x: frame.midX, y: frame.midY)
            }
        }
        self.regionPlaces = regionPlaces
        self.placeRegions = placeRegions
        self.frames = frames
        self.centers = centers
        places = collection.divisions.filter { placeRegions[$0.id] != nil }
        mode = defaults.string(forKey: Key.mode).flatMap(MapGameMode.init(rawValue:)) ?? .nameIt
        length = defaults.string(forKey: Key.length).flatMap(MapGameLength.init(rawValue:)) ?? .ten
        bests = defaults.dictionary(forKey: Key.bests) as? [String: Int] ?? [:]
    }

    // MARK: Choices

    /// The groups to choose between, such as the regions of Japan, when there's more than one.
    var scopes: [DivisionGroup] {
        let groups = collection.groups.filter { group in group.divisions.contains { placeRegions[$0.id] != nil } }
        return groups.count > 1 ? groups : []
    }

    var scope: DivisionGroup? {
        scopeID.flatMap { id in collection.groups.first { $0.id == id } }
    }

    /// The places a round draws from.
    var scopedPlaces: [AdministrativeDivision] {
        guard let scopeID else { return places }
        return places.filter { $0.groupID == scopeID }
    }

    /// How many places a round asks about with the current choices.
    var questionCount: Int {
        length.count(from: scopedPlaces.count)
    }

    func best(for mode: MapGameMode) -> Int? {
        bests[bestKey(for: mode)]
    }

    // MARK: The board

    /// The board's colours: each region at the level for how its place went, the rest at never been.
    var statuses: [String: VisitLevel] {
        regionPlaces.mapValues { place in outcomes[place.id].map(Self.level(for:)) ?? .never }
    }

    /// Regions of places outside the round, veiled on the board.
    var veiledRegionIDs: Set<String> {
        guard let scopeID else { return [] }
        return Set(regionPlaces.filter { $0.value.groupID != scopeID }.keys)
    }

    /// Regions of the round's places, which answer taps.
    var scopedRegionIDs: Set<String> {
        guard let scopeID else { return Set(regionPlaces.keys) }
        return Set(regionPlaces.filter { $0.value.groupID == scopeID }.keys)
    }

    /// Regions of the round's places still to be answered.
    var openRegionIDs: Set<String> {
        scopedRegionIDs.filter { id in regionPlaces[id].map { outcomes[$0.id] == nil } ?? false }
    }

    /// The area the round's places cover, for the camera to frame; nil for the whole map.
    var scopeFrame: CGRect? {
        guard scopeID != nil else { return nil }
        let frame = scopedPlaces.compactMap { frames[$0.id] }.reduce(CGRect.null) { $0.union($1) }
        return frame.isNull ? nil : frame
    }

    // MARK: The round

    enum Phase {
        /// Choosing how to play.
        case lobby
        /// Waiting for an answer.
        case asking
        /// Showing how the answer went.
        case answered
        /// The round is over.
        case finished
    }

    struct Question: Identifiable, Equatable {
        var place: AdministrativeDivision
        /// In Name It, the place and up to three others to choose between, shuffled.
        var choices: [AdministrativeDivision]
        var id: String { place.id }
    }

    enum Outcome: Equatable {
        /// Named or found, on this try.
        case right(tries: Int)
        case missed

        var isRightFirstTime: Bool { self == .right(tries: 1) }
    }

    /// What an answer scored.
    struct Award: Equatable {
        var id = UUID()
        var points: Int
    }

    /// How a tap on the map went in Find It.
    enum Guess {
        case right
        /// Wrong, with tries to spare.
        case wrong
        /// A place already tapped by mistake, which costs no try.
        case again
        /// Wrong, and out of tries.
        case missed
        /// There was no question waiting for a tap.
        case ignored
    }

    var current: Question? {
        guard phase == .asking || phase == .answered, questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    var isLastQuestion: Bool {
        index + 1 >= questions.count
    }

    var triesLeft: Int {
        max(Self.tries - wrongGuesses.count, 0)
    }

    var canHint: Bool {
        guard phase == .asking, !isHinted, let current else { return false }
        return mode == .findIt || current.choices.count > 2
    }

    /// Starts a round with the current choices: the places shuffled and, in Name It, names to
    /// choose between for each.
    func start() {
        let pool = scopedPlaces
        questions = pool.shuffled().prefix(length.count(from: pool.count)).map { place in
            Question(place: place, choices: mode == .nameIt ? choices(for: place, among: pool) : [])
        }
        index = 0
        outcomes = [:]
        score = 0
        streak = 0
        bestStreak = 0
        previousBest = nil
        clearAnswer()
        startDate = .now
        endDate = nil
        phase = questions.isEmpty ? .lobby : .asking
    }

    /// Answers Name It with one of the names.
    func choose(_ choice: AdministrativeDivision) {
        guard phase == .asking, mode == .nameIt, let current, !eliminated.contains(choice.id) else { return }
        chosen = choice
        settle(current, as: choice.id == current.place.id ? .right(tries: 1) : .missed)
    }

    /// Answers Find It with a place tapped on the map.
    @discardableResult
    func guess(_ place: AdministrativeDivision) -> Guess {
        guard phase == .asking, mode == .findIt, let current else { return .ignored }
        if place.id == current.place.id {
            settle(current, as: .right(tries: wrongGuesses.count + 1))
            return .right
        }
        guard !wrongGuesses.contains(place) else { return .again }
        wrongGuesses.append(place)
        guard wrongGuesses.count >= Self.tries else { return .wrong }
        settle(current, as: .missed)
        return .missed
    }

    /// In Name It, takes away all but one of the wrong names; in Find It, the camera shows the
    /// neighbourhood. Either way, the answer is worth half.
    func useHint() {
        guard canHint, let current else { return }
        isHinted = true
        if mode == .nameIt {
            let wrong = current.choices.filter { $0.id != current.place.id }.shuffled()
            eliminated = Set(wrong.dropFirst().map(\.id))
        }
    }

    /// Gives up on this place, to be shown where it is.
    func reveal() {
        guard phase == .asking, let current else { return }
        settle(current, as: .missed)
    }

    /// On to the next place, or to the results after the last.
    func advance() {
        guard phase == .answered else { return }
        guard index + 1 < questions.count else {
            finish()
            return
        }
        index += 1
        clearAnswer()
        phase = .asking
    }

    func returnToLobby() {
        phase = .lobby
        questions = []
        outcomes = [:]
        clearAnswer()
    }

    private func settle(_ question: Question, as outcome: Outcome) {
        outcomes[question.place.id] = outcome
        if outcome.isRightFirstTime {
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }
        if case .right(let tries) = outcome {
            let points = Self.points(tries: tries, streak: streak, hinted: isHinted)
            score += points
            award = Award(points: points)
        }
        phase = .answered
    }

    private func finish() {
        endDate = .now
        award = nil
        let key = bestKey(for: mode)
        previousBest = bests[key]
        if score > (previousBest ?? -1) {
            bests[key] = score
            defaults.set(bests, forKey: Key.bests)
        }
        phase = .finished
    }

    private func clearAnswer() {
        wrongGuesses = []
        chosen = nil
        eliminated = []
        isHinted = false
        award = nil
    }

    /// The place and three others to choose between: two of its near neighbours, which make it a
    /// real question, and one from further away. Shuffled.
    private func choices(for place: AdministrativeDivision, among pool: [AdministrativeDivision]) -> [AdministrativeDivision] {
        var others = pool.filter { $0.id != place.id }
        if others.count < 3 {
            // A small group borrows names from the rest of the map.
            others += places.filter { $0.id != place.id && !others.contains($0) }
        }
        let origin = centers[place.id] ?? .zero
        func distance(to other: AdministrativeDivision) -> CGFloat {
            guard let center = centers[other.id] else { return .greatestFiniteMagnitude }
            return hypot(center.x - origin.x, center.y - origin.y)
        }
        let nearestFirst = others.sorted { distance(to: $0) < distance(to: $1) }
        var picked = Array(nearestFirst.prefix(6).shuffled().prefix(2))
        if let far = nearestFirst.dropFirst(6).randomElement() { picked.append(far) }
        for other in nearestFirst where picked.count < 3 && !picked.contains(other) {
            picked.append(other)
        }
        return ([place] + picked).shuffled()
    }

    /// Each way of playing keeps its own best: the collection, the mode, the places and how many.
    private func bestKey(for mode: MapGameMode) -> String {
        let count = questionCount
        let length = count == scopedPlaces.count ? "all" : "\(count)"
        return [collection.id, mode.rawValue, scopeID ?? "all", length].joined(separator: "|")
    }

    private enum Key {
        static let mode = "gameMode"
        static let length = "gameLength"
        static let bests = "gameBests"
    }

    // MARK: Results

    var rightCount: Int {
        outcomes.values.filter(\.isRightFirstTime).count
    }

    /// Found on a second or third try.
    var closeCount: Int {
        outcomes.values.filter { if case .right(let tries) = $0 { tries > 1 } else { false } }.count
    }

    var missedCount: Int {
        outcomes.values.filter { $0 == .missed }.count
    }

    var missedPlaces: [AdministrativeDivision] {
        questions.map(\.place).filter { outcomes[$0.id] == .missed }
    }

    /// One star for half right, two for most, and three for every one right first time.
    /// A second or third try counts as half.
    var stars: Int {
        guard !questions.isEmpty else { return 0 }
        let share = (Double(rightCount) + 0.5 * Double(closeCount)) / Double(questions.count)
        return share >= 1 ? 3 : share >= 0.8 ? 2 : share >= 0.5 ? 1 : 0
    }

    var isNewBest: Bool {
        phase == .finished && score > 0 && score > (previousBest ?? 0)
    }

    var elapsed: TimeInterval? {
        guard let startDate else { return nil }
        return (endDate ?? .now).timeIntervalSince(startDate)
    }

    /// 100 points right first time, plus 10 for each right answer before it in the run, up to 50
    /// more; 50 and 25 on a second and third try. A hint halves them.
    nonisolated static func points(tries: Int, streak: Int, hinted: Bool) -> Int {
        let points = switch tries {
        case ...1: 100 + 10 * min(max(streak - 1, 0), 5)
        case 2: 50
        default: 25
        }
        return hinted ? points / 2 : points
    }
}

extension MapGame {
    /// Levels for how answers went, so the board colours them the way maps colour places you've
    /// been, with the same flood and ripple as each one lands: green for right first time, yellow
    /// and orange for found on a later try, red for missed. Right answers wear candy stripes.
    nonisolated static let ladder = VisitLadder(levels: [missed, right, secondTry, thirdTry])

    nonisolated static func level(for outcome: Outcome) -> VisitLevel {
        switch outcome {
        case .right(tries: 1): right
        case .right(tries: 2): secondTry
        case .right: thirdTry
        case .missed: missed
        }
    }

    /// The sweets confetti is cut from.
    nonisolated static let confettiColors: [Color] = [LevelColor.lightBlue, .pink, .green, .yellow, .orange].map(\.color)

    private nonisolated static let missed = VisitLevel(id: "game.missed", name: "Missed", tint: .red, symbolName: "xmark")
    private nonisolated static let right = VisitLevel(id: "game.right", name: "Right", tint: .green, symbolName: "checkmark")
    private nonisolated static let secondTry = VisitLevel(
        id: "game.second", name: "Second try", tint: .yellow, symbolName: "2.circle")
    private nonisolated static let thirdTry = VisitLevel(
        id: "game.third", name: "Third try", tint: .orange, symbolName: "3.circle")
}
