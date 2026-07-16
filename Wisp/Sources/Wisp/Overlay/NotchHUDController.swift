import AppKit
import SwiftUI

// Owns the notch-anchored HUD panel — a small, non-activating, display-only panel that hangs from
// the top-center of the built-in display, directly under the camera notch. On displays WITHOUT a
// notch it falls back to plain top-center. Per the app-bundle RE, the notch HUD is the shipped app's
// primary state surface (`NotchRootView` / `notch_collapsed` / `notch_expanded`), with the cursor
// glyph and task cards as satellites.
@MainActor
final class NotchHUDController {
    private unowned let appCoordinator: AppCoordinator

    private var notchPanel: NSPanel?
    // Hosting controller with preferred-content-size sizing so the panel tracks the HUD's collapsed
    // vs expanded size and can be re-centered under the notch as it grows/shrinks.
    private var notchHostingController: NSHostingController<NotchHUDView>?
    private var notchContentSizeObservation: NSKeyValueObservation?

    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }

    // Creates (once) and shows the notch HUD panel on the notched (or main) display.
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
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // Above the menu bar so it visually hangs from the notch (the menu bar sits at .mainMenu level).
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // The HUD is display-only — never intercept clicks, never steal focus.
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false

        let hostingController = NSHostingController(rootView: NotchHUDView(appCoordinator: appCoordinator))
        hostingController.sizingOptions = [.preferredContentSize]
        panel.contentViewController = hostingController
        self.notchHostingController = hostingController

        // Re-center + re-anchor under the notch whenever the HUD's size changes (collapse ⇄ expand).
        notchContentSizeObservation = hostingController.observe(\.preferredContentSize, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor in
                self?.resizeAndAnchorNotchPanel()
            }
        }

        return panel
    }

    // Resizes the panel to the HUD's content size and centers it horizontally under the notch, with
    // its top edge flush to the very top of the display so it appears to hang from the notch.
    private func resizeAndAnchorNotchPanel() {
        guard let notchPanel, let notchHostingController else { return }

        let preferredContentSize = notchHostingController.preferredContentSize
        guard preferredContentSize.width > 1, preferredContentSize.height > 1 else { return }

        let anchorScreen = notchedOrFallbackScreen()
        let anchorScreenFrame = anchorScreen.frame

        // Center horizontally; pin the TOP edge to the display's top (origin is bottom-left, so the
        // panel's origin.y = top - height).
        let panelOriginX = anchorScreenFrame.midX - (preferredContentSize.width / 2)
        let panelOriginY = anchorScreenFrame.maxY - preferredContentSize.height

        notchPanel.setFrame(
            NSRect(x: panelOriginX, y: panelOriginY, width: preferredContentSize.width, height: preferredContentSize.height),
            display: true
        )
    }

    // Finds the built-in notched display (the one with a non-zero top safe-area inset), or falls back
    // to the main screen (top-center) on Macs / setups without a notch.
    private func notchedOrFallbackScreen() -> NSScreen {
        // A notch reserves space at the top of the screen, surfaced as safeAreaInsets.top > 0.
        if let notchedScreen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return notchedScreen
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
}
