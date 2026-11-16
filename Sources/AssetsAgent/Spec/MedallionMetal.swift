import Foundation

/// The metal a medallion is struck in: silver (the default), bronze, gold, or a base colour given as hex. Each is the
/// tone the metal shows half lit; its highlights and shadows are the silver medallion's, in that tone.
enum MedallionMetal: Sendable, Equatable {
    case silver, bronze, gold
    case base(SRGBColor)

    /// `silver`, `bronze`, `gold` (in any case) or a hex colour.
    static func read(_ text: String) throws -> MedallionMetal {
        let word = text.trimmingCharacters(in: .whitespaces)
        switch word.lowercased() {
        case "silver": return .silver
        case "bronze": return .bronze
        case "gold": return .gold
        default:
            if let color = SRGBColor(hex: word) { return .base(color.with(alpha: 1)) }
            throw LineRefusal("metal `\(text)` is not silver, bronze, gold or a hex colour like #8C8A85")
        }
    }

    /// The tone half lit, in CIE L*a*b*: silver's was measured off the reference medallion.
    var middle: (l: Double, a: Double, b: Double) {
        switch self {
        case .silver: return (55, 0.9, 4)
        case .bronze: return (48, 14, 30)
        case .gold: return (62, 6, 42)
        case .base(let color): return CIELab.lab(color)
        }
    }
}
