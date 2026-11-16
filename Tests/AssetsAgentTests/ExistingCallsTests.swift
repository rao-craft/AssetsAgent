import CryptoKit
import Foundation
import XCTest
@testable import AssetsAgent

/// What every kind of call made before the medallion writes, pinned: each file by its SHA-256, and the answer's sets,
/// notes and first path. A PDF's creation dates and document ID are masked, the only bytes CoreGraphics changes from
/// one run to the next. A change that adds a mark or a field proves here that it moved nothing an existing call
/// writes. `ASSETS_WRITE_GOLDEN=1` records the digests again: only on the commit before a change, when a new macOS
/// moves the bytes, never to make a change pass.
final class ExistingCallsTests: XCTestCase {
    /// Where the digests are kept: beside the test target, so the package declares no resource.
    static let golden = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Golden/existing-calls.json")

    /// A call of every kind: each mark (letters, every glyph, a picture of each format, a whole icon), every set,
    /// every platform, another catalog, and a later call that only adds colours.
    static func calls() -> [(name: String, run: (URL) throws -> AssetsResult)] {
        var calls: [(name: String, run: (URL) throws -> AssetsResult)] = [
            ("recipes", { try Fixture.write(try Fixture.recipes(in: $0)) }),
            ("plain", { try Fixture.write(.init(directory: $0.path)) }),
            ("letters", { try Fixture.write(.init(into: "App/Resources", name: "Recipe Box", letters: "RBX", background: ["#1D3557", "#457B9D", "#A8DADC"],
                                                  foreground: "#F1FAEE", font: "Futura", wordmark: "Recipe Box Co", sets: [.icon, .logos, .launch],
                                                  platforms: [.ios, .macos, .watchos, .visionos], directory: $0.path)) }),
            ("paper", { try Fixture.write(.init(name: "Paper", background: ["#F8F1E5", "#EADBC8"], sets: [.icon, .accent, .empty], platforms: [.macos],
                                                directory: $0.path)) }),
            ("mark-spark", { try Fixture.write(.init(name: "Hearth", mark: .spark, background: ["#FF7A50", "#B8361A"], foreground: "#E4572E",
                                                     sets: [.icon, .logos], directory: $0.path)) }),
            ("image-mark", { folder in
                let clear = Raster.image(width: 300, height: 200, opaque: false) {
                    $0.setFillColor(SRGBColor.white.cgColor); $0.fillEllipse(in: CGRect(x: 50, y: 20, width: 200, height: 160))
                }
                try Raster.png(clear).write(to: folder.appendingPathComponent("mark.png"))
                return try Fixture.write(.init(name: "Bowl", mark: .image, image: "mark.png", background: ["#5C3D2E"], directory: folder.path))
            }),
            ("image-whole", { folder in
                let solid = Raster.image(width: 512, height: 512, opaque: true) {
                    $0.setFillColor(SRGBColor(hex: "#6A2FC8")!.cgColor); $0.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
                    $0.setFillColor(SRGBColor(hex: "#F7B23B")!.cgColor); $0.fillEllipse(in: CGRect(x: 128, y: 128, width: 256, height: 256))
                }
                try Raster.png(solid).write(to: folder.appendingPathComponent("whole.png"))
                return try Fixture.write(.init(name: "Bowl", image: "whole.png", sets: [.icon, .logos, .launch, .placeholders, .empty],
                                               platforms: [.ios, .macos, .watchos, .visionos], directory: folder.path))
            }),
            ("image-svg", { folder in
                let svg = ##"<svg xmlns="http://www.w3.org/2000/svg" width="100" height="80"><path d="M10 70 L50 10 L90 70 Z" fill="#000"/></svg>"##
                try Data(svg.utf8).write(to: folder.appendingPathComponent("mark.svg"))
                return try Fixture.write(.init(name: "Peak", image: "mark.svg", background: ["#2F855A"], sets: [.icon, .logos], directory: folder.path))
            }),
            ("image-pdf", { folder in
                let page = VectorPage.pdf(width: 80, height: 100) { context in
                    context.setFillColor(SRGBColor.black.cgColor)
                    context.fillEllipse(in: CGRect(x: 10, y: 10, width: 60, height: 80))
                }
                try page.write(to: folder.appendingPathComponent("mark.pdf"))
                return try Fixture.write(.init(name: "Seed", image: "mark.pdf", background: ["#4A90F2", "#1D47B0"], sets: [.icon, .logos], directory: folder.path))
            }),
            ("later-palette", { folder in
                _ = try Fixture.write(.init(name: "Simmer", palette: ["ember: #E4572E/#FF7A50"], directory: folder.path))
                return try Fixture.write(.init(name: "Simmer", palette: ["colors/background: #FFFDF9/#141110", "colors/foreground: #231C17/#F5EEE7"],
                                               directory: folder.path))
            }),
        ]
        for shape in AssetsShape.allCases {
            calls.append(("shape-\(shape.rawValue)", { try Fixture.write(.init(name: "Shape", shape: shape, sets: [.icon, .logos, .launch], directory: $0.path)) }))
        }
        return calls
    }

    func testEveryExistingCallWritesTheSameBytes() throws {
        var found: [String: [String: Any]] = [:]
        for call in Self.calls() {
            let folder = try Fixture.folder()
            found[call.name] = try Self.record(try call.run(folder), in: folder)
        }
        if ProcessInfo.processInfo.environment["ASSETS_WRITE_GOLDEN"] == "1" {
            try FileManager.default.createDirectory(at: Self.golden.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: ["calls": found], options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            try (String(decoding: data, as: UTF8.self) + "\n").write(to: Self.golden, atomically: true, encoding: .utf8)
        }
        let pinned = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: Self.golden)) as? [String: Any])["calls"] as? [String: [String: Any]]
        let calls = try XCTUnwrap(pinned, "\(Self.golden.path) holds the calls")
        XCTAssertEqual(Set(found.keys), Set(calls.keys), "the calls pinned are the calls made")
        for (name, record) in found.sorted(by: { $0.key < $1.key }) {
            guard let expected = calls[name] else { continue }
            let files = record["files"] as? [String: String] ?? [:], pinnedFiles = expected["files"] as? [String: String] ?? [:]
            XCTAssertEqual(Set(files.keys), Set(pinnedFiles.keys), "\(name) writes the same files")
            let moved = files.keys.filter { pinnedFiles[$0] != nil && pinnedFiles[$0] != files[$0] }.sorted()
            XCTAssertEqual(moved, [], "\(name) writes the same bytes")
            XCTAssertEqual(record["sets"] as? [String], expected["sets"] as? [String], "\(name) answers the same sets")
            XCTAssertEqual(record["notes"] as? [String], expected["notes"] as? [String], "\(name) answers the same notes")
            XCTAssertEqual(record["path"] as? String, expected["path"] as? String, "\(name) answers the same first file")
        }
    }

    /// A result as the pin keeps it: its files by their digests and its answer, every path relative to the project.
    static func record(_ result: AssetsResult, in folder: URL) throws -> [String: Any] {
        let base = folder.path + "/"
        func relative(_ path: String) -> String { path.hasPrefix(base) ? String(path.dropFirst(base.count)) : path }
        var files: [String: String] = [:]
        for path in result.paths { files[relative(path)] = digest(try Data(contentsOf: URL(fileURLWithPath: path)), pdf: path.hasSuffix(".pdf")) }
        return ["files": files, "sets": result.sets, "notes": result.notes.map { $0.replacingOccurrences(of: base, with: "") },
                "path": result.path.map(relative) ?? ""]
    }

    /// The SHA-256 of `data` in hex; for a PDF, of its bytes with the creation dates and the document ID masked.
    static func digest(_ data: Data, pdf: Bool) -> String {
        var bytes = data
        if pdf, var text = String(data: data, encoding: .isoLatin1) {
            for pattern in [#"/CreationDate \(D:[^)]*\)"#, #"/ModDate \(D:[^)]*\)"#, #"/ID \[ <[0-9a-fA-F]+>\s*<[0-9a-fA-F]+> \]"#] {
                text = text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            bytes = text.data(using: .isoLatin1) ?? data
        }
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
}
