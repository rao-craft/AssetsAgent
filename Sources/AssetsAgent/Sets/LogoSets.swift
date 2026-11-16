//  WHAT: The logo sets: `Logo` (the badge), `LogoMark` (the mark alone, a template that takes the tint of where it
//        sits), `Wordmark` (the name) and `Lockup` (badge and name), every one a vector PDF in light and dark but the
//        template, which has no colour of its own.
//  PIN:  COLOUR LOGOS RENDER AS DRAWN. Their sets say `original`, so a toolbar or a tab bar never flattens them
//        into its tint.
//  PIN:  A MEDALLION IS WRITTEN WHERE THE MARK GOES. `Logo`, `LogoMark` and `LaunchLogo` are then the medallion
//        itself, PNGs at 1x, 2x and 3x each drawn at its size, rendered as drawn; `LogoMark` is 128 points, so a view
//        that shows the mark at 100 points never scales it up.

import Foundation

enum LogoSets {
    static func make(_ painter: LogoPainter) throws -> [CatalogSet] {
        if let medallion = painter.art.medallion {
            return [
                ImageSets.bitmap("Logo", points: 128, rendering: "original") { medallion.png(side: $0) },
                ImageSets.bitmap("LogoMark", points: 128, rendering: "original") { medallion.png(side: $0) },
                try wordmark(painter),
                try lockup(painter),
            ]
        }
        return [
            ImageSets.vector("Logo", light: painter.badge(.light, outline: .circle, side: 128), dark: painter.badge(.dark, outline: .circle, side: 128), rendering: "original"),
            ImageSets.vector("LogoMark", light: painter.mark(side: 64), dark: nil, rendering: "template"),
            try wordmark(painter),
            try lockup(painter),
        ]
    }

    /// `LaunchLogo`: the icon's rounded square, light and dark, at the size a launch screen shows it; or the medallion.
    static func launch(_ painter: LogoPainter) -> CatalogSet {
        if let medallion = painter.art.medallion {
            return ImageSets.bitmap("LaunchLogo", points: 120, rendering: "original") { medallion.png(side: $0) }
        }
        return ImageSets.vector("LaunchLogo", light: painter.badge(.light, outline: .squircle, side: 120), dark: painter.badge(.dark, outline: .squircle, side: 120), rendering: "original")
    }

    private static func wordmark(_ painter: LogoPainter) throws -> CatalogSet {
        ImageSets.vector("Wordmark", light: try painter.wordmark(.light, capHeight: 28), dark: try painter.wordmark(.dark, capHeight: 28), rendering: "original")
    }

    private static func lockup(_ painter: LogoPainter) throws -> CatalogSet {
        ImageSets.vector("Lockup", light: try painter.lockup(.light, height: 56), dark: try painter.lockup(.dark, height: 56), rendering: "original")
    }
}
