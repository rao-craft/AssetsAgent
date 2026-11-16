//  WHAT: CIE L*a*b* under D65, the space the medallion's tones were measured in: L* from 0 (black) to 100 (white),
//        a* from green to red, b* from blue to yellow. Into sRGB to paint a tone, out of it to read a hex a call gives.
//  PIN:  THE MEASURE'S OWN CONVERSION. The matrices and the white point are the ones the parity of the medallion with
//        its reference is measured with, so a tone measured off the reference is the tone drawn.

import Foundation

enum CIELab {
    /// The D65 white point, as XYZ.
    static let white = (x: 0.95047, y: 1.0, z: 1.08883)

    /// The tone as sRGB channels, 0…1 each, clipped where it falls outside sRGB.
    static func rgb(l: Double, a: Double, b: Double) -> (red: Double, green: Double, blue: Double) {
        let fy = (l + 16) / 116, fx = fy + a / 500, fz = max(0, fy - b / 200)
        func cubed(_ t: Double) -> Double { t > 0.2068966 ? t * t * t : (t - 16.0 / 116) / 7.787 }
        let x = cubed(fx) * white.x, y = cubed(fy) * white.y, z = cubed(fz) * white.z
        func encoded(_ c: Double) -> Double {
            let v = c > 0.0031308 ? 1.055 * pow(c, 1 / 2.4) - 0.055 : 12.92 * c
            return min(1, max(0, v))
        }
        return (encoded(3.2404813432 * x - 1.5371515163 * y - 0.4985363262 * z),
                encoded(-0.96925495 * x + 1.8759900015 * y + 0.0415559266 * z),
                encoded(0.0556466391 * x - 0.2040413384 * y + 1.0573110696 * z))
    }

    /// The colour's tone.
    static func lab(_ color: SRGBColor) -> (l: Double, a: Double, b: Double) {
        func linear(_ c: Double) -> Double { c > 0.04045 ? pow((c + 0.055) / 1.055, 2.4) : c / 12.92 }
        let r = linear(color.r), g = linear(color.g), b = linear(color.b)
        let x = (0.412453 * r + 0.357580 * g + 0.180423 * b) / white.x
        let y = (0.212671 * r + 0.715160 * g + 0.072169 * b) / white.y
        let z = (0.019334 * r + 0.119193 * g + 0.950227 * b) / white.z
        func f(_ t: Double) -> Double { t > 0.008856 ? cbrt(t) : 7.787 * t + 16.0 / 116 }
        return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)))
    }
}
