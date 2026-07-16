import AppKit
import Combine
import SwiftUI

// A borderless panel that CAN become key. Borderless windows refuse key status by default, but the
// notch composer hosts a focused text field — this is the Spotlight pattern: .nonactivatingPanel
// (typing never activates/deactivates the app behind) + canBecomeKey (the field still gets focus).
private final class KeyableNotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

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

    // Global/local monitors that watch mouse-drags approaching the notch (the island opens as the
    // drag NEARS it, before the drop) and mouse-ups that end an abandoned drag.
    private var dragProximityMonitors: [Any] = []
    private var interactivityObservation: AnyCancellable?

    // The fixed canvas the island animates within. Wide enough for the expanded island, tall enough
    // for the below-notch text area; everything outside the island stays fully transparent.
    private static let canvasSize = NSSize(width: 640, height: 200)

    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }

    func show() {
        if notchPanel == nil {
            notchPanel = buildNotchPanel()
            startDragProximityMonitoring()
            startInteractivityObservation()
        }
        notchPanel?.orderFrontRegardless()
    }

    func hide() {
        notchPanel?.orderOut(nil)
        stopDragProximityMonitoring()
        interactivityObservation = nil
    }

    // MARK: - Panel construction

    private func buildNotchPanel() -> NSPanel {
        let anchorScreen = notchedOrFallbackScreen()
        let notchMetrics = Self.measureNotch(on: anchorScreen)

        let panel = KeyableNotchPanel(
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

    // MARK: - Drag proximity + interactivity

    // The island must be click-through in its passive states (it overlays the menu-bar strip), but
    // interactive while it's a drop target or composer. We can't leave the panel interactive all the
    // time — its transparent canvas would swallow menu-bar clicks — so interactivity follows state.
    private func startInteractivityObservation() {
        interactivityObservation = appCoordinator.$isFileDropTargeted
            .combineLatest(appCoordinator.$composerFileURLs)
            .receive(on: RunLoop.main)
            .sink { [weak self] isDropTargeted, composerFiles in
                guard let self, let notchPanel = self.notchPanel else { return }
                let shouldBeInteractive = isDropTargeted || !composerFiles.isEmpty
                notchPanel.ignoresMouseEvents = !shouldBeInteractive

                // The composer hosts a focused text field: give the panel key status WITHOUT
                // activating Wisp (nonactivating panel), so typing lands in the field while the
                // user's app stays frontmost.
                if !composerFiles.isEmpty {
                    notchPanel.makeKey()
                }
            }
    }

    // Watches drags globally: while the mouse is dragged with a button down into the hot zone
    // around the notch, the island opens into its drop target (matching the demo, where the island
    // expands as the drag APPROACHES, before anything is dropped). A mouse-up outside the zone
    // abandons the gesture (the shipped app logs exactly this as `notch_file_drag_abandoned`).
    // ponytail: a plain mouse-drag into the zone (no files) also opens the target briefly — the
    // window server won't tell a click-through panel what's being dragged; harmless, it closes on
    // mouse-up with nothing attached.
    private func startDragProximityMonitoring() {
        let handleDragMovement: (NSPoint) -> Void = { [weak self] mouseLocation in
            guard let self else { return }
            let isInsideHotZone = self.notchHotZone().contains(mouseLocation)
            if isInsideHotZone != self.appCoordinator.isFileDropTargeted {
                self.appCoordinator.isFileDropTargeted = isInsideHotZone
            }
        }
        let handleDragEnd: () -> Void = { [weak self] in
            guard let self else { return }
            // If the drop landed on the island, attachComposerFiles already cleared this flag and
            // populated the composer; an end outside just closes the target.
            if self.appCoordinator.isFileDropTargeted {
                self.appCoordinator.isFileDropTargeted = false
            }
        }

        let globalDragMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged],
            handler: { _ in handleDragMovement(NSEvent.mouseLocation) }
        )
        if let globalDragMonitor {
            dragProximityMonitors.append(globalDragMonitor)
        }
        let globalUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseUp],
            handler: { _ in handleDragEnd() }
        )
        if let globalUpMonitor {
            dragProximityMonitors.append(globalUpMonitor)
        }
        // Local variants so drags over Wisp's own (interactive) panels behave identically.
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { localEvent in
            if localEvent.type == .leftMouseDragged {
                handleDragMovement(NSEvent.mouseLocation)
            } else {
                handleDragEnd()
            }
            return localEvent
        }
        if let localMonitor {
            dragProximityMonitors.append(localMonitor)
        }
    }

    private func stopDragProximityMonitoring() {
        for monitor in dragProximityMonitors {
            NSEvent.removeMonitor(monitor)
        }
        dragProximityMonitors.removeAll()
    }

    // The screen region (global bottom-left-origin coordinates) that counts as "dragging at the
    // notch": a band centered on the notch, a bit wider than the open drop target, reaching ~90pt
    // down from the top edge so the gesture feels forgiving.
    private func notchHotZone() -> NSRect {
        let anchorScreen = notchedOrFallbackScreen()
        let screenFrame = anchorScreen.frame
        let hotZoneWidth: CGFloat = 560
        let hotZoneHeight: CGFloat = 90
        return NSRect(
            x: screenFrame.midX - hotZoneWidth / 2,
            y: screenFrame.maxY - hotZoneHeight,
            width: hotZoneWidth,
            height: hotZoneHeight
        )
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
