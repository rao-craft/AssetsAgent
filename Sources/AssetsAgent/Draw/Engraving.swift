//  WHAT: The medallion's engraved band: strokes raised from the dish that swirl round four eyes on the diagonals, each
//        eye turning the other way from its neighbours, so the band reads as S-curls with a fan of strokes between
//        each pair. A stroke is a flat-topped ridge one `spacing` from the next; its sides are lit from the top like
//        the rest of the metal, the upper edge catching the light and the lower falling into shadow, so it reads as
//        relief and not as lines.
//  PIN:  ONE STROKE A TURN. Each eye's strokes are the rings round it, stretched along the band, plus a spiral that
//        climbs one stroke a turn, so the rings close into one strand without a seam where the turn starts again.

import Foundation

struct Engraving: Sendable {
    let noise: LatticeNoise

    /// The distance of the eyes from the centre.
    static let eyeRadius = 0.598
    /// One stroke and its groove.
    static let spacing = 0.045
    /// How much longer the swirls run round the band than across it.
    static let aspect = 1.25
    /// The share of a stroke's width its rise (and its fall) takes; the rest is its flat top.
    static let rise = 0.40
    /// How far a stroke wobbles off its course, the hand of the engraver.
    static let wobble = 0.006
    /// How steep a stroke's sides stand.
    static let relief = 0.0072
    /// The light's direction (from the top, towards the viewer), and how much a lit or shaded side moves L*.
    static let light = (x: 0.0, y: 0.6, z: 0.8)
    static let gain = 120.0, specular = 30.0, groove = 10.0
    /// The eyes sit on the diagonals, 45°, 135°, 225° and 315° from the top: the sine and cosine of eye `index`'s
    /// angle, and the way it turns (each the other way from its neighbours).
    static func eye(_ index: Int) -> (sin: Double, cos: Double, hand: Double) {
        let half = 0.5.squareRoot()
        return (index < 2 ? half : -half, index == 0 || index == 3 ? half : -half, index % 2 == 0 ? 1 : -1)
    }

    /// The lightness the band adds at `(x, y)`: its strokes' sides lit or shaded, their tops catching the light, their
    /// grooves darker.
    func lightness(_ x: Double, _ y: Double) -> Double {
        // The nearest eye, by the distance stretched along the band, in the eye's own frame: `t` along the band, `r` out.
        var nearest = Double.infinity, along = 0.0, out = 0.0, which = 0
        for index in 0..<4 {
            let eye = Self.eye(index)
            let dx = x - Self.eyeRadius * eye.sin, dy = y - Self.eyeRadius * eye.cos
            let t = dx * eye.cos - dy * eye.sin, r = dx * eye.sin + dy * eye.cos
            let distance = ((t / Self.aspect) * (t / Self.aspect) + r * r).squareRoot()
            if distance < nearest { nearest = distance; along = t; out = r; which = index }
        }
        let eye = Self.eye(which)
        // The course: the stretched distance plus one stroke a turn round the eye, and its slope in the eye's frame.
        let safe = max(nearest, 1e-6)
        var slopeT = along / (Self.aspect * Self.aspect) / safe, slopeR = out / safe
        let turn = eye.hand * Self.spacing / (2 * .pi)
        let around = max(along * along + out * out, 1e-9)
        slopeT += turn * -out / around
        slopeR += turn * along / around
        let slopeX = slopeT * eye.cos + slopeR * eye.sin, slopeY = -slopeT * eye.sin + slopeR * eye.cos
        let course = nearest + turn * atan2(along, -out) + Self.wobble * noise.value(x, y, cells: 12, octave: 30)
        // The stroke across its width: up its rise, along its top, down its fall to the groove.
        let phase = course / Self.spacing - (course / Self.spacing).rounded(.down)
        let up = Self.smooth(0, Self.rise, phase), down = Self.smooth(1, 1 - Self.rise, phase)
        let steep = Self.slope(0, Self.rise, phase) * down + up * Self.slope(1, 1 - Self.rise, phase)
        // The eye itself is a boss, not a point: the strokes ease out round it.
        let boss = Self.smooth(0.35 * Self.spacing, 1.1 * Self.spacing, nearest)
        let height = 1 - boss * (1 - up * down)
        let rate = boss * steep / Self.spacing
        let nx = -Self.relief * rate * slopeX, ny = -Self.relief * rate * slopeY
        let shade = (nx * Self.light.x + ny * Self.light.y + Self.light.z) / (nx * nx + ny * ny + 1).squareRoot() - Self.light.z
        let lit = max(shade, 0)
        return Self.gain * shade + Self.specular * 4 * lit * lit - Self.groove * (1 - height) + Self.groove * 0.45
    }

    /// Smoothstep from `edge0` to `edge1` (either way round).
    static func smooth(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let t = min(1, max(0, (value - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    /// The slope of `smooth` at `value`.
    static func slope(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let t = (value - edge0) / (edge1 - edge0)
        return t > 0 && t < 1 ? 6 * t * (1 - t) / (edge1 - edge0) : 0
    }
}
