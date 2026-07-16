import Foundation
import ScreenCaptureKit
import CoreGraphics
import AppKit

// One captured display: its ScreenCaptureKit display id, the captured image, and the display's
// frame in the global (multi-monitor) coordinate space. The frame lets us convert between a
// display-local coordinate (what the model reasons about per-screenshot) and a global coordinate
// (where the overlay must actually paint), and back.
struct DisplayCapture {
    let displayID: CGDirectDisplayID
    let capturedImage: CGImage
    let displayFrameInGlobalSpace: CGRect
}

// Captures screenshots of each connected display using ScreenCaptureKit's SCScreenshotManager
// (macOS 14+). WHY ScreenCaptureKit over the older CGDisplayCreateImage: it's the supported,
// non-deprecated path on modern macOS and it respects the Screen Recording permission cleanly.
final class ScreenCapture {

    // Captures every connected display and returns a DisplayCapture per screen. Requires the Screen
    // Recording permission; if it hasn't been granted, SCShareableContent throws and we return [].
    func captureAllDisplays() async -> [DisplayCapture] {
        do {
            // Ask the system for the shareable content (displays, windows, apps). We only need displays.
            let shareableContent = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )

            var displayCaptures: [DisplayCapture] = []
            for shareableDisplay in shareableContent.displays {
                if let displayCapture = await captureSingleDisplay(shareableDisplay) {
                    displayCaptures.append(displayCapture)
                }
            }
            return displayCaptures
        } catch {
            // Most commonly: Screen Recording permission not granted. Return empty; the caller can
            // proceed without a screenshot (text-only request) rather than crashing.
            return []
        }
    }

    // Captures a single SCDisplay into a DisplayCapture.
    private func captureSingleDisplay(_ shareableDisplay: SCDisplay) async -> DisplayCapture? {
        // A content filter scoped to just this one display (no window exclusions).
        let singleDisplayFilter = SCContentFilter(display: shareableDisplay, excludingWindows: [])

        let screenshotConfiguration = SCStreamConfiguration()
        screenshotConfiguration.width = shareableDisplay.width
        screenshotConfiguration.height = shareableDisplay.height

        do {
            let capturedImage = try await SCScreenshotManager.captureImage(
                contentFilter: singleDisplayFilter,
                configuration: screenshotConfiguration
            )
            return DisplayCapture(
                displayID: shareableDisplay.displayID,
                capturedImage: capturedImage,
                displayFrameInGlobalSpace: shareableDisplay.frame
            )
        } catch {
            return nil
        }
    }

    // Encodes a captured CGImage to PNG data, ready to base64-encode for a Claude image block.
    func encodeToPNG(_ image: CGImage) -> Data? {
        let bitmapRepresentation = NSBitmapImageRep(cgImage: image)
        return bitmapRepresentation.representation(using: .png, properties: [:])
    }

    // MARK: - Coordinate mapping

    // Converts a display-LOCAL point (origin at that display's top-left, as the model sees it in a
    // single screenshot) into a GLOBAL point in the multi-monitor coordinate space, using the
    // display's frame. This is how a `[POINT:x,y:label:screenN]` tag becomes an absolute screen
    // position the overlay can paint at.
    func convertDisplayLocalPointToGlobal(
        _ displayLocalPoint: CGPoint,
        displayFrameInGlobalSpace: CGRect
    ) -> CGPoint {
        return CGPoint(
            x: displayFrameInGlobalSpace.origin.x + displayLocalPoint.x,
            y: displayFrameInGlobalSpace.origin.y + displayLocalPoint.y
        )
    }

    // The inverse: converts a global point back into a display-local point relative to a display's
    // frame (useful when we know which display a global coordinate falls on).
    func convertGlobalPointToDisplayLocal(
        _ globalPoint: CGPoint,
        displayFrameInGlobalSpace: CGRect
    ) -> CGPoint {
        return CGPoint(
            x: globalPoint.x - displayFrameInGlobalSpace.origin.x,
            y: globalPoint.y - displayFrameInGlobalSpace.origin.y
        )
    }
}
