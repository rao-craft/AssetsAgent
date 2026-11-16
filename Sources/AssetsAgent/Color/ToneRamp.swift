import Foundation

/// The colour of each lightness a material shows, from L* 0 to 100 in steps of a twentieth, worked out once so a
/// drawing turns every pixel's lightness into its colour by a lookup: red, green and blue (0…1) a step, in a row.
struct ToneRamp: Sendable {
    static let steps = 20
    let levels: [Double]

    /// The ramp of `tone`: the L*a*b* a lightness from 0 to 100 shows as.
    init(_ tone: (Double) -> (l: Double, a: Double, b: Double)) {
        var levels: [Double] = []
        levels.reserveCapacity((100 * Self.steps + 1) * 3)
        for index in 0...(100 * Self.steps) {
            let lab = tone(Double(index) / Double(Self.steps))
            let rgb = CIELab.rgb(l: lab.l, a: lab.a, b: lab.b)
            levels += [rgb.red, rgb.green, rgb.blue]
        }
        self.levels = levels
    }

    /// The sRGB colour of `lightness` (clipped to 0…100) in a ramp's `levels`.
    static func color(_ lightness: Double, in levels: UnsafeBufferPointer<Double>) -> (red: Double, green: Double, blue: Double) {
        let position = min(100, max(0, lightness)) * Double(steps)
        let index = min(100 * steps - 1, Int(position))
        let t = position - Double(index)
        let low = index * 3, high = low + 3
        return (levels[low] + (levels[high] - levels[low]) * t,
                levels[low + 1] + (levels[high + 1] - levels[low + 1]) * t,
                levels[low + 2] + (levels[high + 2] - levels[low + 2]) * t)
    }
}
