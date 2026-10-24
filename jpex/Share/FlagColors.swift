import SwiftUI
import UIKit

/// A flag's main colours, read from its picture once and kept, in the order they run across or down
/// it, so a place's name can be set in its flag's stripes: FRANCE blue, white and red across,
/// GERMANY black, red and gold down.
struct FlagColors {
    var colors: [Color]
    /// Whether the colours run from side to side, as France's do, rather than from top to bottom.
    var runsAcross: Bool

    @MainActor private static var cache: [String: FlagColors] = [:]

    /// The colours of the flag with this asset name, or nil for a picture that can't be read.
    @MainActor static func of(_ flag: String) -> FlagColors? {
        if let known = cache[flag] { return known }
        let read = read(flag)
        cache[flag] = read
        return read
    }

    /// Samples the flag small, sorts its pixels into coarse colours, and keeps the commonest few,
    /// each placed where most of it lies.
    private static func read(_ flag: String) -> FlagColors? {
        guard let image = UIImage(named: flag)?.cgImage else { return nil }
        let width = 36
        let height = 24
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }

        struct Bucket {
            var count = 0
            var red = 0, green = 0, blue = 0
            var x = 0, y = 0
        }
        var buckets: [Int: Bucket] = [:]
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                guard pixels[offset + 3] > 128 else { continue }
                let red = Int(pixels[offset]), green = Int(pixels[offset + 1]), blue = Int(pixels[offset + 2])
                // Five steps a channel: close shades of a colour fall together, distinct colours apart.
                let key = (red / 52) * 25 + (green / 52) * 5 + blue / 52
                var bucket = buckets[key, default: Bucket()]
                bucket.count += 1
                bucket.red += red
                bucket.green += green
                bucket.blue += blue
                bucket.x += x
                bucket.y += y
                buckets[key] = bucket
            }
        }
        let total = buckets.values.reduce(0) { $0 + $1.count }
        guard total > 0 else { return nil }
        // The colours that cover a good share of the flag, the most of them first, three at most.
        let main = buckets.values
            .filter { Double($0.count) / Double(total) >= 0.07 }
            .sorted { $0.count > $1.count }
            .prefix(3)
        guard !main.isEmpty else { return nil }
        let centers = main.map { (x: Double($0.x) / Double($0.count), y: Double($0.y) / Double($0.count)) }
        let spreadAcross = (centers.map(\.x).max() ?? 0) - (centers.map(\.x).min() ?? 0)
        let spreadDown = (centers.map(\.y).max() ?? 0) - (centers.map(\.y).min() ?? 0)
        let runsAcross = spreadAcross >= spreadDown
        let ordered = zip(main, centers).sorted { runsAcross ? $0.1.x < $1.1.x : $0.1.y < $1.1.y }
        let colors = ordered.map { bucket, _ in
            Color(
                red: Double(bucket.red) / Double(bucket.count) / 255,
                green: Double(bucket.green) / Double(bucket.count) / 255,
                blue: Double(bucket.blue) / Double(bucket.count) / 255)
        }
        return FlagColors(colors: colors, runsAcross: runsAcross)
    }
}
