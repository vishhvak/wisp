import AppKit
import SwiftUI

// Owns the notch "island" HUD — Wisp's primary state surface, per the shipped app's RE
// (`NotchAgentSurface` / `notch_collapsed` / `notch_expanded`).
//
// The trick that makes it read as a Dynamic Island rather than "a pill near the notch": the island
// is PURE BLACK and rendered flush with the physical notch cutout, so when it grows, the hardware
// itself appears to expand. To let that growth spring smoothly, the panel is NOT resized to fit
// content (AppKit frame changes can't interpolate with SwiftUI springs) — instead the panel is a
// fixed, generously-sized, transparent canvas centered on the notch, and the island morphs freely
// inside it with SwiftUI animation.
@MainActor
final class NotchHUDController {
    private unowned let appCoordinator: AppCoordinator

    private var notchPanel: NSPanel?

    // The fixed canvas the island animates within. Wide enough for the expanded island, tall enough
    // for the below-notch text area; everything outside the island stays fully transparent.
    private static let canvasSize = NSSize(width: 640, height: 200)

    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }

    func show() {
        if notchPanel == nil {
            notchPanel = buildNotchPanel()
        }
        notchPanel?.orderFrontRegardless()
    }

    func hide() {
        notchPanel?.orderOut(nil)
    }

    // MARK: - Panel construction

    private func buildNotchPanel() -> NSPanel {
        let anchorScreen = notchedOrFallbackScreen()
        let notchMetrics = Self.measureNotch(on: anchorScreen)

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // Above the menu bar (.statusBar) so the island's ears can sit OVER the menu-bar strip
        // beside the notch, exactly like the hardware growing outward.
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Display-only: never intercept clicks, never steal focus.
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false

        let hostingView = NSHostingView(
            rootView: NotchHUDView(
                appCoordinator: appCoordinator,
                notchWidth: notchMetrics.width,
                notchHeight: notchMetrics.height
            )
        )
        hostingView.frame = NSRect(origin: .zero, size: Self.canvasSize)
        panel.contentView = hostingView

        // Center the fixed canvas on the notch, top edge flush with the display's top edge.
        let screenFrame = anchorScreen.frame
        panel.setFrame(
            NSRect(
                x: screenFrame.midX - Self.canvasSize.width / 2,
                y: screenFrame.maxY - Self.canvasSize.height,
                width: Self.canvasSize.width,
                height: Self.canvasSize.height
            ),
            display: true
        )

        return panel
    }

    // MARK: - Notch geometry

    // The physical notch's size on this screen. Width comes from the gap between the auxiliary
    // top-left/right areas (the usable menu-bar strips beside the notch); height from the top
    // safe-area inset. On displays without a notch both are nil/0 → we return width 0 and a
    // menu-bar-ish height, and the view renders a floating top-center pill instead of an island.
    static func measureNotch(on screen: NSScreen) -> (width: CGFloat, height: CGFloat) {
        let safeAreaTopInset = screen.safeAreaInsets.top

        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea,
           safeAreaTopInset > 0 {
            let notchWidth = screen.frame.width - leftArea.width - rightArea.width
            return (width: max(notchWidth, 0), height: safeAreaTopInset)
        }

        // No notch: height approximates the menu bar so the fallback pill hangs naturally below it.
        return (width: 0, height: 30)
    }

    private func notchedOrFallbackScreen() -> NSScreen {
        if let notchedScreen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return notchedScreen
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
}
