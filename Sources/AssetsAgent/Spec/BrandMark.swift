import Foundation

/// What the brand's mark is: letters, a glyph, a picture the project has, or a struck-metal medallion.
enum BrandMark: Sendable, Equatable {
    case monogram(String)
    case shape(AssetsShape)
    case image(Picture)
    case medallion(Medallion)
}
