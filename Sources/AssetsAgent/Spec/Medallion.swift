import Foundation

/// The struck-metal medallion a call draws as its mark: the metal it is struck in, what it is set in, what its
/// engraved band carries, and the seed of its grain (the same seed draws the same pixels).
struct Medallion: Sendable, Equatable {
    var metal: MedallionMetal = .silver
    var backing: MedallionBacking = .stone
    var motif: MedallionMotif = .swirls
    var seed: Int = 0
}
