import Foundation

/// Japan's prefectures as JapanEx by Zhung reads them, so a person can see their levels on its map.
/// JapanEx scores places from 0 for never been to 5 for lived: the original levels. Other levels
/// show as whichever of those the person chooses, or a match, through `JapanExMapping`.
enum JapanEx {
    static let homepage = URL(string: "https://zhung.com.tw/japanex/")!

    /// The order JapanEx reads prefectures in, by their original index, from Hokkaido at 0 to Okinawa at 46.
    private static let order = [
        15, 13, 7, 11, 12, 21, 25, 29, 30,
        34, 33, 31, 22, 23, 27, 16, 18, 26, 37, 38, 35, 10,
        8, 32, 43, 39, 41, 36, 17, 46, 44, 42, 40,
        45, 28, 24, 9, 19, 20, 6, 14, 3, 5, 2, 4, 1, 0,
    ]

    /// Whether these are the original five levels, in their original order, which JapanEx shows
    /// as they are. Other levels need a mapping.
    static func usesOriginalLevels(_ ladder: VisitLadder) -> Bool {
        ladder.levels.map(\.id) == VisitLadder.standard.levels.map(\.id)
    }

    /// The code JapanEx reads: one digit for each prefecture, in its own order.
    static func code(for snapshot: TravelSnapshot, mapping: JapanExMapping) -> String {
        var scores = Array(repeating: 0, count: order.count)
        for division in CountryCatalog.japan.divisions {
            guard let index = division.legacyJapanIndex, scores.indices.contains(index) else { continue }
            scores[index] = mapping.japanExLevel(for: snapshot.status(for: division), in: snapshot.ladder).score
        }
        return order.map { String(scores[$0]) }.joined()
    }

    /// The link that opens JapanEx with every prefecture at its level.
    static func link(for snapshot: TravelSnapshot, mapping: JapanExMapping) -> URL {
        URL(string: homepage.absoluteString + "#" + code(for: snapshot, mapping: mapping)) ?? homepage
    }
}
