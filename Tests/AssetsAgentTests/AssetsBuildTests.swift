import Foundation
import XCTest
@testable import AssetsAgent

/// The catalog built as an app builds it: a recipe app's every asset written into a two-platform app project,
/// built with xcodebuild for macOS and the iOS Simulator with no warning from the asset catalog, and the Mac app run
/// to say what it finds in its own bundle; and the Seer call's medallion and `SeerMark` view, built in Swift 5 and 6.
/// Gated (`ASSETS_BUILD=1`): the builds take a few minutes.
final class AssetsBuildTests: XCTestCase {
    func testTheCatalogBuildsIntoAnAppForMacOSAndIOS() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ASSETS_BUILD"] == "1", "set ASSETS_BUILD=1 to build the output in an app")
        let folder = try Fixture.folder()
        try AppProject.write(name: "Simmer", into: folder)
        let result = try AssetsAgent.write(try Fixture.recipes(in: folder), note: { _ in }, yield: { _ in })
        XCTAssertFalse(result.notes.contains { $0.contains("APPICON") }, "the project names its icon: \(result.notes)")
        XCTAssertFalse(result.notes.contains { $0.contains("UIImageName") }, "and its launch logo: \(result.notes)")
        let derived = folder.appendingPathComponent("DerivedData")

        let mac = try Self.xcodebuild(["-project", "Simmer.xcodeproj", "-scheme", "Simmer-macOS", "-destination", "platform=macOS",
                                       "-derivedDataPath", derived.path, "CODE_SIGNING_ALLOWED=NO", "build"], in: folder)
        XCTAssertEqual(mac.status, 0, mac.log.suffix(4_000).description)
        let ios = try Self.xcodebuild(["-project", "Simmer.xcodeproj", "-scheme", "Simmer-iOS", "-destination", "generic/platform=iOS Simulator",
                                       "-derivedDataPath", derived.path, "CODE_SIGNING_ALLOWED=NO", "build"], in: folder)
        XCTAssertEqual(ios.status, 0, ios.log.suffix(4_000).description)
        for log in [mac.log, ios.log] {
            let warnings = log.split(separator: "\n").filter { $0.contains("warning:") && ($0.contains("xcassets") || $0.contains("asset") || $0.contains("Asset")) }
            XCTAssertEqual(warnings, [], "the asset catalog builds without a warning")
        }

        // The iOS app: its icon and its launch screen as the Info.plist says them.
        let iosApp = derived.appendingPathComponent("Build/Products/Debug-iphonesimulator/Simmer.app")
        let iosInfo = try XCTUnwrap(NSDictionary(contentsOf: iosApp.appendingPathComponent("Info.plist")) as? [String: Any])
        XCTAssertNotNil(iosInfo["CFBundleIcons"], "the app icon is in the Info.plist")
        XCTAssertEqual((iosInfo["UILaunchScreen"] as? [String: Any])?["UIImageName"] as? String, "LaunchLogo")
        XCTAssertTrue(FileManager.default.fileExists(atPath: iosApp.appendingPathComponent("Assets.car").path))

        // The Mac app, run: what it finds in its own bundle.
        let macApp = derived.appendingPathComponent("Build/Products/Debug/Simmer.app")
        XCTAssertTrue(FileManager.default.fileExists(atPath: macApp.appendingPathComponent("Contents/Resources/AppIcon.icns").path))
        let run = try Self.run(macApp.appendingPathComponent("Contents/MacOS/Simmer"), ["--check-assets"])
        XCTAssertEqual(run.status, 0, run.log)
        let line = try XCTUnwrap(run.log.split(separator: "\n").last { $0.hasPrefix("{") }, run.log)
        let found = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: String])
        XCTAssertEqual(found, [
            "AccentColor": "#E8590C", "herb.dark": "#7BC98A", "Logo": "128x128", "LogoMark": "\(found["LogoMark"] ?? "")",
            "Wordmark": "\(found["Wordmark"] ?? "")", "Lockup": "\(found["Lockup"] ?? "")", "LaunchLogo": "120x120",
            "Placeholder/Avatar": "128x128", "Empty/Error": "160x160", "whisk": "symbol",
            "pantry": #"{"shelves": ["grains", "spices"]}"#, "icon": "AppIcon",
        ])
        for name in ["LogoMark", "Wordmark", "Lockup"] { XCTAssertNotEqual(found[name], "missing", name) }
    }

    /// The Seer call as the kits build it: the medallion and its `SeerMark` view in a two-platform app whose screen
    /// shows `SeerMark()` at 100 and 96 points, built with xcodebuild for macOS and for `generic/platform=iOS Simulator`
    /// in Swift 5 and in Swift 6 (iOS 26 and macOS 26), with no warning from the catalog or the view; then the Mac app
    /// run to say what it finds in its own bundle. No simulator is booted.
    func testTheSeerMarkViewBuildsInSwift5And6ForMacOSAndIOS() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ASSETS_BUILD"] == "1", "set ASSETS_BUILD=1 to build the output in an app")
        let folder = try Fixture.folder()
        try AppProject.write(name: "Seer", into: folder, view: AppProject.markView)
        let result = try AssetsAgent.write(try Fixture.example("seer", in: folder), note: { _ in }, yield: { _ in })
        let view = folder.appendingPathComponent("Shared/Design/SeerMark.swift")
        XCTAssertEqual(result.paths.last, view.path, "the answer names the view")
        XCTAssertFalse(result.notes.contains { $0.contains("actool warns") }, "actool compiled the medallion without a warning: \(result.notes)")
        let derived = folder.appendingPathComponent("DerivedData")

        for swift in ["5.0", "6.0"] {
            let settings = ["SWIFT_VERSION=\(swift)", "IPHONEOS_DEPLOYMENT_TARGET=26.0", "MACOSX_DEPLOYMENT_TARGET=26.0", "CODE_SIGNING_ALLOWED=NO", "build"]
            let mac = try Self.xcodebuild(["-project", "Seer.xcodeproj", "-scheme", "Seer-macOS", "-destination", "platform=macOS",
                                           "-derivedDataPath", derived.path] + settings, in: folder)
            XCTAssertEqual(mac.status, 0, "macOS, Swift \(swift): " + mac.log.suffix(4_000))
            let ios = try Self.xcodebuild(["-project", "Seer.xcodeproj", "-scheme", "Seer-iOS", "-destination", "generic/platform=iOS Simulator",
                                           "-derivedDataPath", derived.path] + settings, in: folder)
            XCTAssertEqual(ios.status, 0, "iOS Simulator, Swift \(swift): " + ios.log.suffix(4_000))
            for log in [mac.log, ios.log] {
                XCTAssertTrue(log.contains("-swift-version \(swift.prefix(1))"), "compiled in Swift \(swift)")
                let warnings = log.split(separator: "\n").filter { $0.contains("warning:") && ($0.contains("SeerMark") || $0.contains("BrandView") || $0.contains("xcassets") || $0.contains("Asset")) }
                XCTAssertEqual(warnings, [], "Swift \(swift): the view and the catalog build without a warning")
            }
        }

        // The Mac app, run: the medallion is in its bundle, the mark at 128 points.
        let macApp = derived.appendingPathComponent("Build/Products/Debug/Seer.app")
        XCTAssertTrue(FileManager.default.fileExists(atPath: macApp.appendingPathComponent("Contents/Resources/AppIcon.icns").path))
        let run = try Self.run(macApp.appendingPathComponent("Contents/MacOS/Seer"), ["--check-assets"])
        XCTAssertEqual(run.status, 0, run.log)
        let line = try XCTUnwrap(run.log.split(separator: "\n").last { $0.hasPrefix("{") }, run.log)
        let found = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: String])
        for (name, value) in ["LogoMark": "128x128", "Logo": "128x128", "LaunchLogo": "120x120", "AccentColor": "#AE9060", "icon": "AppIcon"] {
            XCTAssertEqual(found[name], value, name)
        }
    }

    static func xcodebuild(_ arguments: [String], in folder: URL) throws -> (status: Int32, log: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["xcodebuild"] + arguments
        process.currentDirectoryURL = folder
        return try collect(process)
    }

    static func run(_ executable: URL, _ arguments: [String]) throws -> (status: Int32, log: String) {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        return try collect(process)
    }

    private static func collect(_ process: Process) throws -> (status: Int32, log: String) {
        let out = Pipe()
        process.standardOutput = out
        process.standardError = out
        process.standardInput = FileHandle.nullDevice
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
