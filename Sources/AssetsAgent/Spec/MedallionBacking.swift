import Foundation

/// What a medallion is set in: the light stone grey measured off the reference (the default), a stone of a colour
/// given as hex, or nothing (`none`), the dish then the image's edge and everything outside it clear.
enum MedallionBacking: Sendable, Equatable {
    case stone
    case color(SRGBColor)
    case clear

    /// A hex colour, or `none`.
    static func read(_ text: String) throws -> MedallionBacking {
        let word = text.trimmingCharacters(in: .whitespaces)
        if word.lowercased() == "none" { return .clear }
        if let color = SRGBColor(hex: word) { return .color(color.with(alpha: 1)) }
        throw LineRefusal("backing `\(text)` is not a hex colour like #ADADAD or none")
    }
}
