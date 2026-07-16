// swift-tools-version: 5.9
// The Wisp menu-bar companion app is a SwiftPM executable so it can be built and
// iterated purely with `swift build` (no Xcode project, no xcodebuild — which would
// invalidate the app's TCC permissions on every rebuild).

import PackageDescription

let package = Package(
    name: "Wisp",
    // ScreenCaptureKit's SCScreenshotManager and MenuBarExtra both require macOS 14+.
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        // A single executable target with NO external dependencies. Everything Wisp
        // needs (SwiftUI, AppKit, ScreenCaptureKit, AVFoundation, Speech) ships with the OS.
        .executableTarget(
            name: "Wisp",
            path: "Sources/Wisp"
        )
    ]
)
