import CoreGraphics
import Foundation
import XCTest
@testable import AssetsAgent

/// The medallion, measured: clear outside its backing, its layers where the reference has them and lit from the top,
/// the same bytes for the same seed, each metal, backing and motif, written where the mark goes and on the icon, and
/// every value it cannot honour refused in a sentence.
final class MedallionTests: XCTestCase {
    /// The tone at (x, y), y from the top, of `image`, and its coverage.
    private func tone(_ image: CGImage, _ x: Int, _ y: Int) -> (l: Double, a: Double, b: Double, alpha: Double) {
        let color = Pixels.color(Pixels.rgba(image), width: image.width, x, y)
        let lab = CIELab.lab(color)
        return (lab.l, lab.a, lab.b, color.alpha)
    }

    /// The pixel at radius `radius` of a `side`-pixel drawing, `degrees` clockwise from the top.
    private func at(_ radius: Double, _ degrees: Double, side: Int) -> (Int, Int) {
        let angle = degrees * .pi / 180, half = Double(side) / 2
        return (Int(half + radius * half * sin(angle)), Int(half - radius * half * cos(angle)))
    }

    func testTheMedallionIsClearOutsideItsBackingAndLitFromTheTop() throws {
        let side = 256
        let image = MedallionPainter(Medallion()).image(side: side)
        XCTAssertEqual([image.width, image.height], [side, side])
        XCTAssertEqual(tone(image, 2, 2).alpha, 0, "clear outside the backing")
        XCTAssertEqual(tone(image, side / 2, side / 2).alpha, 1)
        func l(_ radius: Double, _ degrees: Double) -> Double { let p = at(radius, degrees, side: side); return tone(image, p.0, p.1).l }
        let stone = at(0.95, 0, side: side)
        XCTAssertEqual(tone(image, stone.0, stone.1).l, 72, accuracy: 12, "a light stone grey")
        XCTAssertLessThan(abs(tone(image, stone.0, stone.1).b), 3, "and a neutral one")
        XCTAssertGreaterThan(l(0.15, 0), 85, "the dome's highlight runs across its top")
        XCTAssertLessThan(l(0.15, 180), 45, "and its foot is dark")
        XCTAssertLessThan(l(0.27, 0), 25, "a dark reflection band round the dome")
        XCTAssertGreaterThan(l(0.53, 0), 85, "the dish is lit at the top")
        XCTAssertLessThan(l(0.53, 180), 45, "and in shadow at the bottom")
    }

    func testTheSameSeedDrawsTheSameBytesAndAnotherSeedAnotherGrain() {
        let first = MedallionPainter(Medallion(seed: 7)).png(side: 128)
        XCTAssertEqual(first, MedallionPainter(Medallion(seed: 7)).png(side: 128), "byte for byte")
        XCTAssertNotEqual(first, MedallionPainter(Medallion(seed: 8)).png(side: 128))
        XCTAssertEqual(MedallionPainter(Medallion(seed: 7)).image(side: 128).width, 128)
    }

    func testEachMetalBackingAndMotif() throws {
        let side = 256
        func dish(_ medallion: Medallion) -> (l: Double, a: Double, b: Double, alpha: Double) {
            let p = at(0.53, 90, side: side)
            return tone(MedallionPainter(medallion).image(side: side), p.0, p.1)
        }
        XCTAssertLessThan(dish(Medallion()).b, 6, "silver is nearly grey")
        XCTAssertGreaterThan(dish(Medallion(metal: .gold)).b, 20, "gold is yellow")
        XCTAssertGreaterThan(dish(Medallion(metal: .bronze)).a, 8, "bronze is red-brown")
        XCTAssertLessThan(dish(Medallion(metal: .base(SRGBColor(hex: "#2E7D8C")!))).b, -5, "a base colour gives its hue")

        // A stone of another colour, and none: the dish is then the image's edge.
        let blue = MedallionPainter(Medallion(backing: .color(SRGBColor(hex: "#3A5F8A")!))).image(side: side)
        let stone = at(0.95, 0, side: side)
        XCTAssertLessThan(tone(blue, stone.0, stone.1).b, -10, "the stone takes the backing's colour")
        let clear = MedallionPainter(Medallion(backing: .clear)).image(side: side)
        XCTAssertEqual(tone(clear, 2, 2).alpha, 0)
        let rim = at(0.97, 0, side: side)
        XCTAssertEqual(tone(clear, rim.0, rim.1).alpha, 1, "the dish reaches the edge")
        let outside = at(1.02, 45, side: side)
        XCTAssertEqual(tone(clear, outside.0, outside.1).alpha, 0, "and nothing is drawn past it")

        // The swirls are relief: round the band, the lightness steps from stroke to groove; a plain band only drifts.
        func roughness(_ medallion: Medallion) -> Double {
            let image = MedallionPainter(medallion).image(side: 512)
            let pixels = Pixels.rgba(image)
            let tones = stride(from: 0.0, to: 360, by: 0.5).map { degrees -> Double in
                let p = at(0.65, degrees, side: 512)
                return CIELab.lab(Pixels.color(pixels, width: 512, p.0, p.1)).l
            }
            return zip(tones, tones.dropFirst()).map { abs($1 - $0) }.reduce(0, +) / Double(tones.count - 1)
        }
        XCTAssertGreaterThan(roughness(Medallion()), 2 * roughness(Medallion(motif: .plain)))
    }

    /// The medallion's values are read whatever the mark, and name the mark when it is left out.
    func testTheMedallionsValuesAreReadAndNameTheMark() throws {
        let folder = try Fixture.folder().path
        XCTAssertEqual(try AssetsPlan.make(.init(name: "Seer", metal: "GOLD", directory: folder)).brand.mark, .medallion(Medallion(metal: .gold)),
                       "a metal alone is a medallion")
        let given = try AssetsPlan.make(.init(name: "Seer", mark: .medallion, metal: "#8C8A85", backing: "none", motif: "plain", seed: 42, directory: folder))
        XCTAssertEqual(given.brand.mark, .medallion(Medallion(metal: .base(SRGBColor(hex: "#8C8A85")!), backing: .clear, motif: .plain, seed: 42)))
        XCTAssertEqual(try AssetsPlan.make(.init(name: "Seer", mark: .medallion, directory: folder)).brand.mark, .medallion(Medallion()))
        XCTAssertEqual(try AssetsPlan.make(.init(name: "Seer", directory: folder)).brand.mark, .monogram("S"), "no medallion unless asked")
    }

    func testEveryValueItCannotHonourIsRefusedAndNothingIsWritten() throws {
        let folder = try Fixture.folder()
        let input = AssetsAgent.Input(name: "Seer", mark: .medallion, metal: "platinum", backing: "stone", motif: "dots", seed: -1,
                                      view: "seer mark", viewInto: "Shared/Design/SeerMark.swift", directory: folder.path)
        XCTAssertThrowsError(try Fixture.write(input)) { error in
            guard case .refused(let reasons)? = error as? AssetsError else { return XCTFail("\(error)") }
            for reason in ["metal `platinum` is not silver, bronze, gold or a hex colour", "backing `stone` is not a hex colour like #ADADAD or none",
                           "motif `dots` is not swirls or plain", "seed -1 is negative", "view `seer mark` is not a Swift type name",
                           "viewInto `Shared/Design/SeerMark.swift` names a file"] {
                XCTAssertTrue(reasons.contains { $0.contains(reason) }, "says \(reason): \(reasons)")
            }
            XCTAssertEqual(reasons.count, 6, "\(reasons)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Shared").path), "nothing written")
        XCTAssertThrowsError(try Fixture.write(.init(name: "Seer", mark: .monogram, metal: "gold", seed: 3, directory: folder.path))) {
            XCTAssertTrue("\($0)".contains("`metal` and `seed` draw the medallion, and the mark is monogram: give mark medallion, or leave them out"), "\($0)")
        }
        XCTAssertThrowsError(try Fixture.write(.init(name: "Seer", mark: .spark, motif: "plain", directory: folder.path))) {
            XCTAssertTrue("\($0)".contains("`motif` draws the medallion, and the mark is shape"), "\($0)")
        }
        XCTAssertThrowsError(try Fixture.write(.init(name: "Seer", view: "Image", directory: folder.path))) {
            XCTAssertTrue("\($0)".contains("view `Image` is a name its own file or the app needs"), "\($0)")
        }
        XCTAssertThrowsError(try Fixture.write(.init(name: "Seer", viewInto: "Shared/Design", directory: folder.path))) {
            XCTAssertTrue("\($0)".contains("viewInto places the mark's view and `view` names none"), "\($0)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Shared").path), "still nothing written")
    }

    func testTheMedallionIsWrittenWhereTheMarkGoes() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(.init(name: "Seer", mark: .medallion, sets: [.logos, .launch], directory: folder.path))
        XCTAssertEqual(result.sets, ["Logo", "LogoMark", "Wordmark", "Lockup", "LaunchLogo"])
        let catalog = folder.appendingPathComponent("Shared/Assets.xcassets")
        let painter = MedallionPainter(Medallion())
        for (name, points) in [("Logo", 128), ("LogoMark", 128), ("LaunchLogo", 120)] {
            let set = catalog.appendingPathComponent("\(name).imageset")
            let contents = try String(contentsOf: set.appendingPathComponent("Contents.json"), encoding: .utf8)
            XCTAssertEqual(contents, CatalogContents.scaledImageSet([(1, "\(name).png"), (2, "\(name)@2x.png"), (3, "\(name)@3x.png")], rendering: "original").text,
                           "\(name) is a bitmap at each scale, rendered as drawn")
            for scale in 1...3 {
                let file = set.appendingPathComponent(scale == 1 ? "\(name).png" : "\(name)@\(scale)x.png")
                XCTAssertEqual(try Data(contentsOf: file), painter.png(side: points * scale), "\(file.lastPathComponent) is the medallion drawn at its size")
            }
        }
        let mark = try Pixels.image(catalog.appendingPathComponent("LogoMark.imageset/LogoMark@3x.png").path)
        XCTAssertEqual([mark.width, mark.height], [384, 384], "the mark at 100 points is never scaled up")
        XCTAssertEqual(tone(mark, 0, 0).alpha, 0, "clear outside the backing")
        for name in ["Wordmark", "Lockup"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: catalog.appendingPathComponent("\(name).imageset/\(name).pdf").path), "\(name) stays a vector PDF")
        }
    }

    func testTheIconSetsTheMedallionOnTheBrandsGround() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(.init(name: "Seer", mark: .medallion, background: ["#2A2622", "#4A4038"], sets: [.icon], platforms: [.ios, .macos],
                                             directory: folder.path))
        XCTAssertFalse(result.notes.contains { $0.contains("contrast") }, "no ink is measured on a medallion: \(result.notes)")
        let icons = Dictionary(uniqueKeysWithValues: result.paths.filter { $0.hasSuffix(".png") }.map { (URL(fileURLWithPath: $0).lastPathComponent, $0) })
        let icon = try Pixels.image(try XCTUnwrap(icons["icon-ios.png"]))
        XCTAssertLessThan(Pixels.color(Pixels.rgba(icon), width: 1024, 20, 20).luminance, 0.05, "the brand's dark ground")
        // The medallion fills 76% of the icon, set on whole pixels: its middle is the painter's own pixel.
        let medallion = MedallionPainter(Medallion()).image(side: 778)
        let found = Pixels.color(Pixels.rgba(icon), width: 1024, 512, 512), drawn = Pixels.color(Pixels.rgba(medallion), width: 778, 389, 389)
        XCTAssertEqual([found.red, found.green, found.blue], [drawn.red, drawn.green, drawn.blue])
        XCTAssertGreaterThan(tone(icon, 512, 512 - Int(0.53 * 389)).l, 80, "its dish lit at the top")
        // At 16 pixels the medallion still stands off its ground: its middle against the ground at the shape's left edge.
        let small = Pixels.rgba(try Pixels.image(try XCTUnwrap(icons["icon-mac-16.png"])))
        XCTAssertGreaterThan(Pixels.color(small, width: 16, 8, 8).luminance, 3 * Pixels.color(small, width: 16, 1, 8).luminance)
    }

    func testTheViewIsOneSwiftFileTheAnswerNames() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(.init(name: "Seer", mark: .medallion, sets: [.icon, .logos], platforms: [.ios], view: "SeerMark", directory: folder.path))
        let file = folder.appendingPathComponent("Shared/Design/SeerMark.swift")
        XCTAssertEqual(result.paths.last, file.path, "the answer names the view's file")
        XCTAssertEqual(result.sets, ["AppIcon", "Logo", "LogoMark", "Wordmark", "Lockup"], "a view is no set")
        let text = try String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(text, MarkView.source(name: "SeerMark"))
        for part in ["import SwiftUI", "struct SeerMark: View", #"Image("LogoMark")"#, ".resizable()", ".scaledToFit()", ".accessibilityHidden(true)"] {
            XCTAssertTrue(text.contains(part), part)
        }
        for absent in ["shadow", "rotation", "frame(", "#Preview"] { XCTAssertFalse(text.contains(absent), absent) }

        let other = try Fixture.write(.init(name: "Seer", sets: [.accent], view: "AppMark", viewInto: "App/Views/", directory: folder.path))
        XCTAssertEqual(other.paths.last, folder.appendingPathComponent("App/Views/AppMark.swift").path, "in the folder viewInto names")
        XCTAssertFalse(other.notes.contains { $0.contains("no LogoMark") }, "the catalog has its LogoMark: \(other.notes)")

        // A later call with only the view writes the view and draws nothing again.
        let later = try Fixture.write(.init(view: "SeerBadge", directory: folder.path))
        XCTAssertEqual(later.paths, [folder.appendingPathComponent("Shared/Design/SeerBadge.swift").path])
        XCTAssertEqual(later.path, later.paths.first)
        XCTAssertEqual(later.sets, [])
        XCTAssertTrue(later.notes.contains { $0.contains("were kept") }, "\(later.notes)")

        let bare = try Fixture.folder()
        let alone = try Fixture.write(.init(name: "Seer", sets: [.accent], view: "SeerMark", directory: bare.path))
        XCTAssertTrue(alone.notes.contains("SeerMark draws Image(\"LogoMark\") and the catalog has no LogoMark: add logos to sets"), "\(alone.notes)")
    }

    /// `Schema/examples/seer.json`: the original's silver medallion on Seer's warm dark ground, its mark as `SeerMark`.
    func testTheSeerCallDrawsTheMedallionAndItsView() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(try Fixture.example("seer", in: folder))
        XCTAssertEqual(result.sets, ["AppIcon", "AccentColor", "Logo", "LogoMark", "Wordmark", "Lockup", "LaunchLogo", "Placeholder/Avatar",
                                     "Placeholder/Avatar1", "Placeholder/Avatar2", "Placeholder/Avatar3", "Placeholder/Avatar4",
                                     "Empty/Inbox", "Empty/Search", "Empty/Offline", "Empty/Error"])
        XCTAssertEqual(result.paths.last, folder.appendingPathComponent("Shared/Design/SeerMark.swift").path)
        let catalog = folder.appendingPathComponent("Shared/Assets.xcassets")
        XCTAssertEqual(try Data(contentsOf: catalog.appendingPathComponent("LogoMark.imageset/LogoMark@3x.png")),
                       MedallionPainter(Medallion(seed: 7)).png(side: 384), "the silver medallion of seed 7")
        XCTAssertTrue(try String(contentsOf: catalog.appendingPathComponent("AccentColor.colorset/Contents.json"), encoding: .utf8).contains("0xAE"))
        let mark = try Data(contentsOf: catalog.appendingPathComponent("LogoMark.imageset/LogoMark@3x.png"))
        _ = try Fixture.write(try Fixture.example("seer", in: folder))
        XCTAssertEqual(try Data(contentsOf: catalog.appendingPathComponent("LogoMark.imageset/LogoMark@3x.png")), mark, "the same call, the same bytes")
    }
}
