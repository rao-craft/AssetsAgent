//  WHAT: The medallion mark: a struck-metal disc set in stone, drawn pixel by pixel. From the centre out: a brushed
//        dome and its dark bevel, polished rings and their grooves, a brushed dish shaded like a shallow bowl, a band
//        of raised swirls, the dish's rim, and the stone it is set in (`MedallionShade` says the colour at a point).
//        Clear outside the stone, or outside the dish when it is set in nothing; the drawing fills its square.
//  PIN:  THE SAME SEED, THE SAME BYTES. Every grain comes from the seed, nothing from the clock or a system random
//        source, and each pixel is worked out on its own, so the rows can be drawn in parallel and still come out the
//        same.
//  PIN:  EVERY SIZE IS DRAWN, NEVER SCALED DOWN. A size is drawn at its own pixels, once a painter, and drawn into a
//        page on whole pixels so it is never resampled.

import CoreGraphics
import Foundation

final class MedallionPainter {
    let medallion: Medallion
    private let shade: MedallionShade
    private var drawn: [Int: CGImage] = [:]

    init(_ medallion: Medallion) {
        self.medallion = medallion
        shade = MedallionShade(medallion)
    }

    /// The medallion `side` pixels square, with alpha.
    func image(side: Int) -> CGImage {
        if let image = drawn[side] { return image }
        let image = Self.draw(shade, side: side)
        drawn[side] = image
        return image
    }

    /// The medallion as a PNG, `side` pixels square.
    func png(side: Int) -> Data { Raster.png(image(side: side)) }

    /// Draws the medallion into `rect`, at `scale` pixels to the unit of `context`: the nearest whole number of pixels,
    /// centred on the rect and set on whole pixels.
    func draw(in rect: CGRect, scale: CGFloat = 1, context: CGContext) {
        let side = max(1, Int((min(rect.width, rect.height) * scale).rounded()))
        let size = CGFloat(side) / scale
        let origin = CGPoint(x: ((rect.midX - size / 2) * scale).rounded() / scale, y: ((rect.midY - size / 2) * scale).rounded() / scale)
        context.draw(image(side: side), in: CGRect(origin: origin, size: CGSize(width: size, height: size)))
    }

    /// Every pixel of a `side`-pixel square, worked out by `shade`, the rows in parallel.
    private static func draw(_ shade: MedallionShade, side: Int) -> CGImage {
        let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let rows = Rows(base: context.data!.bindMemory(to: UInt8.self, capacity: side * side * 4))
        // The buffer's first row is the top of the image.
        DispatchQueue.concurrentPerform(iterations: side) { row in
            shade.draw(row: row, side: side, into: rows.base + row * side * 4)
        }
        return context.makeImage()!
    }

    /// The bitmap's bytes, shared by the rows drawn in parallel: each row writes only its own.
    private struct Rows: @unchecked Sendable {
        let base: UnsafeMutablePointer<UInt8>
    }
}
