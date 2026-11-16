import Foundation

/// Image sets: vector PDFs, one for any appearance and one for dark when given; or bitmaps at 1x, 2x and 3x.
enum ImageSets {
    static func vector(_ name: String, folder: String? = nil, light: Data, dark: Data?, rendering: String) -> CatalogSet {
        let base = name.split(separator: "/").last.map(String.init) ?? name
        var images: [(appearance: CatalogAppearance?, file: String)] = [(nil, "\(base).pdf")]
        var files = [CatalogFile(path: "\(base).pdf", data: light)]
        if let dark {
            images.append((.dark, "\(base)-dark.pdf"))
            files.append(CatalogFile(path: "\(base)-dark.pdf", data: dark))
        }
        return CatalogSet(folder: folder ?? "\(name).imageset", name: name,
                          files: [.contents(CatalogContents.imageSet(images, vector: true, rendering: rendering))] + files)
    }

    /// An image set of PNGs `points` square at 1x, 2x and 3x, each drawn at its own size: `draw` makes the PNG of a
    /// side in pixels.
    static func bitmap(_ name: String, points: Int, rendering: String, draw: (Int) -> Data) -> CatalogSet {
        let base = name.split(separator: "/").last.map(String.init) ?? name
        let images = [1, 2, 3].map { (scale: $0, file: $0 == 1 ? "\(base).png" : "\(base)@\($0)x.png") }
        let files = images.map { CatalogFile(path: $0.file, data: draw(points * $0.scale)) }
        return CatalogSet(folder: "\(name).imageset", name: name,
                          files: [.contents(CatalogContents.scaledImageSet(images, rendering: rendering))] + files)
    }
}
