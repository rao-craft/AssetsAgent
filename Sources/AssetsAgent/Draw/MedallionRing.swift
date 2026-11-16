//  WHAT: One ring of the medallion, from the centre out: where it starts and ends (the backing's edge is at 1), and its
//        lightness (CIE L*) along its inner and its outer edge, every 30° from the top (0°) round to the bottom (180°),
//        the left side the mirror of the right. Between two angles a tone eases along a half cosine; across the ring
//        it runs straight from the inner edge to the outer.
//  PIN:  MEASURED, NOT INVENTED. The table is the reference medallion read ring by ring at 512 pixels: its brushed dome
//        and the dark bevel round it, the polished rings and their grooves, the brushed dish, the engraved band, the
//        dish's rim, and the stone it is set in. The metal is lit from the top; the stone, a little from the right,
//        is drawn by the painter.

import Foundation

struct MedallionRing: Sendable {
    var from: Double
    var to: Double
    /// L* along the inner edge at 0°, 30°, … 180° from the top.
    var inner: [Double]
    /// L* along the outer edge at the same angles.
    var outer: [Double]

    init(_ from: Double, _ to: Double, _ inner: [Double], _ outer: [Double]? = nil) {
        self.from = from; self.to = to; self.inner = inner; self.outer = outer ?? inner
    }

    /// The rings of the reference medallion, centre out.
    static let measured: [MedallionRing] = [
        // The dome: a brushed cap, its highlight a band across the top, darkening to its foot.
        .init(0.000, 0.037, [45, 44, 41, 40, 39, 36, 36], [53, 50, 45, 39, 36, 33, 32]),
        .init(0.037, 0.068, [53, 50, 45, 39, 36, 33, 32], [68, 61, 49, 39, 32, 30, 28]),
        .init(0.068, 0.098, [68, 61, 49, 39, 32, 30, 28], [99, 80, 52, 38, 29, 28, 28]),
        .init(0.098, 0.128, [99, 80, 52, 38, 29, 28, 28], [99, 96, 54, 36, 27, 29, 32]),
        .init(0.128, 0.158, [99, 96, 54, 36, 27, 29, 32], [99, 99, 55, 35, 27, 33, 38]),
        .init(0.158, 0.188, [99, 99, 55, 35, 27, 33, 38], [99, 99, 55, 33, 27, 37, 44]),
        .init(0.188, 0.217, [99, 99, 55, 33, 27, 37, 44], [99, 95, 53, 30, 28, 40, 49]),
        .init(0.217, 0.252, [99, 95, 53, 30, 28, 40, 49], [99, 78, 48, 26, 27, 44, 57]),
        // The dome's bevel: the dark reflection band, lit again at the bottom.
        .init(0.252, 0.284, [12, 14, 16, 15, 29, 47, 64], [16, 13, 13, 8, 30, 77, 94]),
        // The polished rings: a bright ring, a dark groove, a thin bright lip, then the groove before the dish.
        .init(0.284, 0.328, [54, 47, 35, 23, 31, 65, 99]),
        .init(0.328, 0.350, [13, 11, 14, 14, 18, 49, 98]),
        .init(0.350, 0.372, [86, 56, 22, 12, 10, 6, 15]),
        .init(0.372, 0.398, [34, 31, 26, 24, 24, 29, 30]),
        .init(0.398, 0.432, [24, 25, 28, 30, 31, 58, 91], [20, 19, 20, 27, 30, 59, 99]),
        .init(0.432, 0.455, [96, 75, 40, 34, 38, 60, 99], [99, 97, 60, 49, 48, 80, 90]),
        .init(0.455, 0.477, [99, 97, 60, 49, 48, 80, 90], [99, 96, 55, 33, 40, 85, 99]),
        // The dish: brushed, a shallow bowl, bright at the top.
        .init(0.477, 0.497, [85, 67, 40, 24, 32, 68, 85]),
        .init(0.497, 0.570, [100, 97, 56, 37, 27, 23, 20], [99, 98, 61, 52, 44, 44, 46]),
        .init(0.570, 0.592, [96, 77, 46, 46, 32, 32, 46]),
        // The engraved band's ground (its strokes are the engraving's).
        .init(0.592, 0.714, [81, 66, 43, 45, 33, 29, 34], [85, 72, 46, 39, 35, 39, 34]),
        .init(0.714, 0.815, [93, 87, 57, 48, 39, 41, 39], [99, 99, 63, 45, 46, 54, 58]),
        // The dish's rim.
        .init(0.815, 0.824, [57, 55, 47, 39, 33, 28, 26]),
        // The stone: in the dish's shadow at its inner edge, then even.
        .init(0.824, 0.886, [64, 63, 59, 54, 47, 44, 40], [75, 75, 73, 70, 64, 63, 60]),
        .init(0.886, 1.000, [76, 76, 75, 72, 67, 65, 62]),
    ]
}
