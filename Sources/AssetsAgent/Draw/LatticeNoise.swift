//  WHAT: Value noise from a seed: a random value at every point of a lattice, eased smoothly between the points. The
//        medallion's grain (the brushing of its metal, the mottling of its stone, the wobble of its engraving) is drawn
//        from it, each texture an octave of its own.
//  PIN:  THE SEED IS THE WHOLE STORY. A value is a hash of the seed, the octave and the lattice point, with no state and
//        no system random source: a seed draws the same grain at every size, on every run.

import Foundation

struct LatticeNoise: Sendable {
    let seed: UInt64

    init(seed: Int) { self.seed = UInt64(bitPattern: Int64(seed)) }

    /// A value in -1…1 at `(x, y)` in -1…1, on a lattice `cells` cells across, for octave `octave`.
    func value(_ x: Double, _ y: Double, cells: Int, octave: UInt64) -> Double {
        let u = (x + 1) / 2 * Double(cells), v = (y + 1) / 2 * Double(cells)
        let i = Int(u.rounded(.down)), j = Int(v.rounded(.down))
        let fu = Self.ease(u - Double(i)), fv = Self.ease(v - Double(j))
        let a = point(i, j, octave), b = point(i + 1, j, octave), c = point(i, j + 1, octave), d = point(i + 1, j + 1, octave)
        return (a + (b - a) * fu) * (1 - fv) + (c + (d - c) * fu) * fv
    }

    /// A value in -1…1 at `x` in -1…1, along a line `cells` cells long, for octave `octave`.
    func value(_ x: Double, cells: Int, octave: UInt64) -> Double {
        let u = (x + 1) / 2 * Double(cells)
        let i = Int(u.rounded(.down))
        let f = Self.ease(u - Double(i))
        let a = point(i, 0, octave), b = point(i + 1, 0, octave)
        return a + (b - a) * f
    }

    /// The value at lattice point `(i, j)` of `octave`, -1…1: SplitMix64's finaliser over the seed, the octave and
    /// the point.
    func point(_ i: Int, _ j: Int, _ octave: UInt64) -> Double {
        var z = seed &+ (octave &* 0x9E37_79B9_7F4A_7C15)
        z ^= UInt64(bitPattern: Int64(i)) &* 0xBF58_476D_1CE4_E5B9
        z ^= UInt64(bitPattern: Int64(j)) &* 0x94D0_49BB_1331_11EB
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        // The top 53 bits, 0 up to 2⁵³, halved into 0 up to 2 and moved down by 1.
        return Double(z >> 11) / 4_503_599_627_370_496 - 1
    }

    /// Smoothstep: eases 0…1 in and out, so the noise has no creases at the lattice lines.
    static func ease(_ t: Double) -> Double { t * t * (3 - 2 * t) }
}
