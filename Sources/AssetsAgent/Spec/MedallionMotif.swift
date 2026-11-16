import Foundation

/// What a medallion's engraved band carries: raised swirls (the default) or nothing, the band brushed like the dish.
enum MedallionMotif: String, Sendable, Equatable, CaseIterable {
    case swirls, plain

    /// `swirls` or `plain`, in any case.
    static func read(_ text: String) throws -> MedallionMotif {
        if let motif = MedallionMotif(rawValue: text.trimmingCharacters(in: .whitespaces).lowercased()) { return motif }
        throw LineRefusal("motif `\(text)` is not swirls or plain")
    }
}
