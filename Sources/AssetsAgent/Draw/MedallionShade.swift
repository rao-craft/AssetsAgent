//  WHAT: The medallion at one point: its coverage, and its colour there. The rings give a lightness by angle and
//        radius; the metal adds its brushing (fine vertical streaks) and the engraving its relief; the stone adds its
//        light from the top right and its mottling. The metal's ramp, or the stone's, then turns that lightness into a
//        colour.
//  PIN:  LIGHTNESS FIRST, COLOUR LAST. Every layer adds up L*; only the ramp knows the metal, so gold and bronze are
//        silver's light in another tone, and a backing colour is the measured stone's light in that colour.
//  PIN:  NOTHING FINER THAN A PIXEL. A ring's edges blend over one pixel, and a texture octave or the engraving's
//        relief fades out where its detail would fall under a pixel or two, so a small drawing is the large one seen
//        from further off, not its noise.
//  PIN:  NO SHARED COUNT IN THE LOOP. Rows are drawn in parallel; the tables are read through buffer pointers taken
//        once a row, so no pixel retains or releases an array the other rows are reading.

import Foundation

struct MedallionShade: Sendable {
    /// Where the metal ends and the stone begins.
    static let dish = 0.824
    /// The engraved band, and the width its relief fades in over at each edge.
    static let band = (from: 0.575, to: 0.722, fade: 0.012)
    /// The stone's slant of light (L* from its middle to its right edge), and the mean lightness it was measured at.
    static let slant = 5.0, stoneMean = 70.6
    /// The strength of the metal's brushing.
    static let streak = 1.6
    /// A ring in the table: its start, its end, its seven inner tones and its seven outer ones.
    static let stride = 16

    /// The rings, centre out, `stride` numbers each.
    let rings: [Double]
    let noise: LatticeNoise
    /// The engraving, unless the band is plain.
    let engraving: Engraving?
    let metal: ToneRamp
    /// The stone's ramp, unless the medallion is set in nothing.
    let stone: ToneRamp?

    init(_ medallion: Medallion) {
        noise = LatticeNoise(seed: medallion.seed)
        engraving = medallion.motif == .swirls ? Engraving(noise: noise) : nil
        // The metal: silver's lightness bent so its middle tone is the metal's, tinted most in the middle tones and
        // least in the highlights and the deepest shadows.
        let middle = medallion.metal.middle
        let bend = min(2, max(0.5, log(min(99, max(1, middle.l)) / 100) / log(0.55)))
        metal = ToneRamp { lightness in
            let l = 100 * pow(lightness / 100, bend)
            let tint = min(1, max(0, 1 - ((l - 45) / 60) * ((l - 45) / 60)))
            return (l, middle.a * tint, middle.b * tint)
        }
        var rings = MedallionRing.measured
        switch medallion.backing {
        case .stone:
            stone = ToneRamp { ($0, 0.45, 0) }
        case .color(let color):
            let tone = CIELab.lab(color)
            stone = ToneRamp { ($0 + tone.l - Self.stoneMean, tone.a, tone.b) }
        case .clear:
            stone = nil
            rings = rings.filter { $0.to <= Self.dish }
        }
        self.rings = rings.flatMap { [$0.from, $0.to] + $0.inner + $0.outer }
    }

    /// The radius at the image's edge: the backing's, or the dish's when there is none.
    var edge: Double { stone == nil ? Self.dish : 1 }

    /// Draws row `row` (0 at the top) of a `side`-pixel square into `bytes`, premultiplied RGBA from the row's first
    /// pixel.
    func draw(row: Int, side: Int, into bytes: UnsafeMutablePointer<UInt8>) {
        rings.withUnsafeBufferPointer { rings in
            metal.levels.withUnsafeBufferPointer { metal in
                (stone?.levels ?? []).withUnsafeBufferPointer { stone in
                    let unit = 2 / Double(side), pixel = unit * edge
                    let y = (1 - (Double(row) + 0.5) * unit) * edge
                    for column in 0..<side {
                        let x = ((Double(column) + 0.5) * unit - 1) * edge
                        let color = self.color(x, y, pixel: pixel, rings: rings, metal: metal, stone: stone)
                        let alpha = UInt8((color.alpha * 255).rounded())
                        let offset = column * 4
                        bytes[offset] = min(alpha, UInt8((color.red * 255).rounded()))
                        bytes[offset + 1] = min(alpha, UInt8((color.green * 255).rounded()))
                        bytes[offset + 2] = min(alpha, UInt8((color.blue * 255).rounded()))
                        bytes[offset + 3] = alpha
                    }
                }
            }
        }
    }

    /// The colour at `(x, y)` (the backing's edge at radius 1, y up), premultiplied by its coverage, for a pixel
    /// `pixel` units wide: each channel 0…1. `stone` is empty when there is no backing.
    private func color(_ x: Double, _ y: Double, pixel: Double, rings: UnsafeBufferPointer<Double>, metal: UnsafeBufferPointer<Double>,
                       stone: UnsafeBufferPointer<Double>) -> (red: Double, green: Double, blue: Double, alpha: Double) {
        let r = (x * x + y * y).squareRoot()
        let alpha = min(1, max(0, ((stone.isEmpty ? Self.dish : 1) - r) / pixel + 0.5))
        guard alpha > 0 else { return (0, 0, 0, 0) }

        // The rings: the tone between the two measured angles either side, each ring blended into the next over a pixel.
        let position = atan2(abs(x), y) / (.pi / 6)
        let step = min(5, max(0, Int(position)))
        let ease = (1 - cos(.pi * (position - Double(step)))) / 2
        let count = rings.count / Self.stride
        var lightness = 0.0
        for index in 0..<count {
            let base = index * Self.stride
            let from = rings[base], to = rings[base + 1]
            guard r >= from - pixel, r < to + pixel else { continue }
            let across = min(1, max(0, (r - from) / (to - from)))
            let inner = rings[base + 2 + step] + (rings[base + 3 + step] - rings[base + 2 + step]) * ease
            let outer = rings[base + 9 + step] + (rings[base + 10 + step] - rings[base + 9 + step]) * ease
            let rise = index == 0 ? 1 : min(1, max(0, (r - from) / pixel + 0.5))
            let fall = index == count - 1 ? 1 : min(1, max(0, (to - r) / pixel + 0.5))
            lightness += (inner + (outer - inner) * across) * rise * fall
        }

        // How much of an octave `cells` across the backing still shows at this pixel's size.
        func shows(_ cells: Int) -> Double { Engraving.smooth(0.75, 2, 2 / Double(cells) / pixel) }

        // The metal: its brushing, then the engraving in its band.
        let onStone = stone.isEmpty ? 0 : min(1, max(0, (r - Self.dish) / pixel + 0.5))
        var metalLight = lightness, stoneLight = lightness
        if onStone < 1 {
            func streaks(_ weight: Double, _ cells: Int, _ octave: UInt64) -> Double { weight * shows(cells) * noise.value(x, cells: cells, octave: octave) }
            let brushing = streaks(1, 50, 10) + streaks(0.8, 100, 11) + streaks(0.6, 200, 12) + streaks(0.9, 400, 13)
            metalLight += Self.streak * brushing * (0.6 + 0.4 * noise.value(y, cells: 6, octave: 20))
            if let engraving, r > Self.band.from, r < Self.band.to {
                let fade = min(1, (r - Self.band.from) / Self.band.fade) * min(1, (Self.band.to - r) / Self.band.fade)
                // The strokes fade out where one would be under three pixels wide.
                let detail = Engraving.smooth(2, 4, Engraving.spacing / pixel)
                if fade * detail > 0 { metalLight += fade * detail * engraving.lightness(x, y) }
            }
        }
        // The stone: its light from the top right, and its mottling, coarse to fine, the finest its grain.
        if onStone > 0 {
            func mottle(_ amplitude: Double, _ cells: Int, _ octave: UInt64) -> Double { amplitude * shows(cells) * noise.value(x, y, cells: cells, octave: octave) }
            stoneLight += Self.slant * x / max(r, 1e-6)
            stoneLight += mottle(4, 10, 1) + mottle(3, 20, 2) + mottle(1.4, 40, 3) + mottle(0.6, 80, 4) + mottle(2, 256, 5)
        }

        var color = ToneRamp.color(metalLight, in: metal)
        if onStone > 0 {
            let ground = ToneRamp.color(stoneLight, in: stone)
            color = (color.red + (ground.red - color.red) * onStone, color.green + (ground.green - color.green) * onStone,
                     color.blue + (ground.blue - color.blue) * onStone)
        }
        return (color.red * alpha, color.green * alpha, color.blue * alpha, alpha)
    }
}
