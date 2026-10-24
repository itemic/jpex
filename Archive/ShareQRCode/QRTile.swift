// Shelved 23 Oct 2026: the App Store QR code that sat on the share card's pass, beside "Scan to
// download". The user found it hard to read at the pass's size and asked to remove it for now.
//
// To restore it:
// - Put `modules` back in `AppStoreLink` (it needs `import CoreImage.CIFilterBuiltins`), with the
//   link it encodes, removed along with the share screen's App Store link on 23 Oct 2026:
//   `static let url = URL(string: "https://apps.apple.com/app/id6504094652")!`
// - Put `QRTile` back in MapShareCard.swift.
// - On the pass, after the Spacer, show the small-caps "Scan to\ndownload" note and
//   `QRTile(modules: AppStoreLink.modules, ink: palette.code, tint: palette.accent,
//   paper: palette.codePaper, size: Self.tileSize, cornerRadius: tileRadius)` when `content.showsLink`.
// This file isn't in any target.

import CoreImage.CIFilterBuiltins
import SwiftUI

extension AppStoreLink {
    /// The link as a QR code's squares, row by row from the top, true where a square is dark,
    /// without the margin round it, for the card to draw in its own style.
    static let modules: [[Bool]] = {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let image = CIContext().createCGImage(output, from: output.extent)
        else { return [] }
        // One byte to each square, the first row of bytes the code's top row.
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 255, count: width * height)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return [] }
        let rows = (0..<height).map { y in (0..<width).map { x in pixels[y * width + x] < 128 } }
        // The generator leaves a margin of light squares; the card gives the code its own.
        let filled = rows.indices.filter { rows[$0].contains(true) }
        let columns = (0..<width).filter { x in rows.contains { $0[x] } }
        guard let top = filled.first, let bottom = filled.last, let left = columns.first, let right = columns.last
        else { return [] }
        return rows[top...bottom].map { Array($0[left...right]) }
    }()
}

/// The App Store's code drawn to match the app's icon at the other end of the pass: the same size
/// and corners, on paper with a breath of the card's colour. Its squares are round dots, shading
/// from the card's colour, deepened, in one corner to its ink in the other, and its three corner
/// marks are eyes: a rounded square round a round pupil. The marks stay whole and every dot dark on
/// light, so cameras read it as readily as a plain code.
private struct QRTile: View {
    var modules: [[Bool]]
    var ink: Color
    /// The card's colour, which the code shades from.
    var tint: Color
    var paper: Color
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Canvas { context, canvasSize in
            let count = modules.count
            guard count > 7 else { return }
            let inset = canvasSize.width * 0.09
            let cell = (canvasSize.width - inset * 2) / CGFloat(count)
            func square(_ x: Int, _ y: Int, span: Int = 1) -> CGRect {
                CGRect(
                    x: inset + CGFloat(x) * cell, y: inset + CGFloat(y) * cell,
                    width: cell * CGFloat(span), height: cell * CGFloat(span))
            }
            let marks = [(0, 0), (count - 7, 0), (0, count - 7)]
            func isMark(_ x: Int, _ y: Int) -> Bool {
                marks.contains { x >= $0.0 && x < $0.0 + 7 && y >= $0.1 && y < $0.1 + 7 }
            }
            // The whole code as one shape, filled even-odd, so each eye's inner square opens a hole
            // in its outer one and the pupil fills the hole's middle again.
            var code = Path()
            for (y, row) in modules.enumerated() {
                for (x, isDark) in row.enumerated() where isDark && !isMark(x, y) {
                    code.addEllipse(in: square(x, y).insetBy(dx: cell * 0.07, dy: cell * 0.07))
                }
            }
            for (x, y) in marks {
                let eye = square(x, y, span: 7)
                code.addRoundedRect(in: eye, cornerSize: CGSize(width: cell * 2.3, height: cell * 2.3))
                code.addRoundedRect(in: eye.insetBy(dx: cell, dy: cell), cornerSize: CGSize(width: cell * 1.4, height: cell * 1.4))
                code.addEllipse(in: square(x + 2, y + 2, span: 3))
            }
            context.fill(
                code,
                with: .linearGradient(
                    Gradient(colors: [ShareCardPalette.deepened(tint, toAtMost: 0.15), ink]),
                    startPoint: .zero, endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)),
                style: FillStyle(eoFill: true))
        }
        .frame(width: size, height: size)
        .background(
            LinearGradient(colors: [paper, paper.mix(with: tint, by: 0.08)], startPoint: .top, endPoint: .bottom),
            in: shape)
        .overlay { shape.strokeBorder(ink.opacity(0.1), lineWidth: 0.5) }
        .accessibilityHidden(true)
    }
}
