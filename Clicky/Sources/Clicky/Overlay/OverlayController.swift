import AppKit
import SwiftUI

// Manages the full-screen transparent overlay window that hosts everything Clicky paints directly
// onto the user's screen: the cursor-trailing glyph, the AI teaching ink, the top-right task-card
// stack, and the completion toast.
//
// WHY a borderless non-activating NSPanel (and not a SwiftUI Window): the overlay must float above
// all other apps, span every Space, never steal focus from whatever the user is doing, and let all
// mouse clicks pass straight through to the app underneath. Those behaviors are AppKit window-level
// concerns that SwiftUI's window types don't expose, so we build the panel in AppKit and bridge the
// SwiftUI content in via NSHostingView.
@MainActor
final class OverlayController {
    // The coordinator supplies the observable state (companion state, tasks, annotations, toast,
    // cursor position) that the hosted SwiftUI view renders.
    private unowned let appCoordinator: AppCoordinator

    private var overlayPanel: NSPanel?

    // Global mouse-move monitors so the cursor glyph can trail the real OS cursor.
    private var globalMouseMoveMonitor: Any?
    private var localMouseMoveMonitor: Any?

    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }

    // Creates (once) and shows the overlay panel over the main screen.
    func show() {
        if overlayPanel == nil {
            overlayPanel = buildOverlayPanel()
        }
        overlayPanel?.orderFrontRegardless()
        startTrackingGlobalMouseLocation()
    }

    // Hides the overlay panel and stops mouse tracking (used for the transient-cursor fade-out).
    func hide() {
        overlayPanel?.orderOut(nil)
        stopTrackingGlobalMouseLocation()
    }

    // MARK: - Panel construction

    private func buildOverlayPanel() -> NSPanel {
        // Cover the main screen. (Multi-monitor teaching ink is routed per-display by mapping global
        // coordinates; the panel itself sits on the main screen where the menu bar lives.)
        let mainScreenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let panel = NSPanel(
            contentRect: mainScreenFrame,
            // Borderless + nonactivating: no title bar, and showing it never activates Clicky.
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Transparent, shadowless, floating above normal windows.
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating

        // Join all Spaces and stay visible in full-screen apps, so the companion is always present.
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Let every click fall through to the app underneath — the overlay is display-only.
        panel.ignoresMouseEvents = true

        // Never become key/main so focus stays with the user's foreground app.
        panel.hidesOnDeactivate = false

        // Bridge the SwiftUI content in. The root view observes the coordinator for live updates.
        let overlayHostingView = NSHostingView(rootView: OverlayRootView(appCoordinator: appCoordinator))
        overlayHostingView.frame = NSRect(origin: .zero, size: mainScreenFrame.size)
        // A clear hosting view so only the painted SwiftUI elements are visible.
        overlayHostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = overlayHostingView

        return panel
    }

    // MARK: - Cursor tracking

    // Installs global + local mouse-move monitors and seeds an initial cursor position so the glyph
    // can ride next to the OS cursor. WHY both monitors: the global monitor sees movement over other
    // apps, while the local monitor covers movement over Clicky's own (click-through) overlay.
    private func startTrackingGlobalMouseLocation() {
        updateCursorGlyphPositionFromCurrentMouseLocation()

        globalMouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] _ in
            self?.updateCursorGlyphPositionFromCurrentMouseLocation()
        }
        localMouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] localEvent in
            self?.updateCursorGlyphPositionFromCurrentMouseLocation()
            return localEvent
        }
    }

    private func stopTrackingGlobalMouseLocation() {
        if let globalMouseMoveMonitor {
            NSEvent.removeMonitor(globalMouseMoveMonitor)
        }
        if let localMouseMoveMonitor {
            NSEvent.removeMonitor(localMouseMoveMonitor)
        }
        globalMouseMoveMonitor = nil
        localMouseMoveMonitor = nil
    }

    // Reads the current global mouse location and converts it into the overlay's top-left-origin
    // coordinate space so the SwiftUI glyph can be positioned with `.position`.
    private func updateCursorGlyphPositionFromCurrentMouseLocation() {
        guard let overlayPanel else { return }
        let panelFrame = overlayPanel.frame

        // NSEvent.mouseLocation is in global screen coordinates with a BOTTOM-left origin (AppKit).
        let mouseLocationBottomLeftOrigin = NSEvent.mouseLocation

        // Convert to the hosting view's TOP-left origin space, relative to the panel's frame.
        let cursorXInOverlay = mouseLocationBottomLeftOrigin.x - panelFrame.origin.x
        let cursorYInOverlay = panelFrame.size.height - (mouseLocationBottomLeftOrigin.y - panelFrame.origin.y)

        appCoordinator.cursorGlyphPositionInOverlay = CGPoint(x: cursorXInOverlay, y: cursorYInOverlay)
    }
}

// The SwiftUI content painted into the overlay panel. It layers (bottom → top): the teaching ink,
// the task-card stack, the completion toast, and the cursor-trailing glyph. Everything observes the
// coordinator so state changes re-render live.
struct OverlayRootView: View {
    @ObservedObject var appCoordinator: AppCoordinator

    // A small offset so the glyph rides just down-and-right of the actual cursor tip (matching the
    // demos), rather than sitting directly on top of the arrow.
    private let cursorGlyphOffset = CGSize(width: 14, height: 16)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Teaching ink spans the whole overlay at absolute coordinates.
            TeachingOverlayView(teachingAnnotations: appCoordinator.teachingAnnotations)

            // The top-right task-card stack.
            TaskCardStackView(
                agentTasks: appCoordinator.agentTasks,
                onSuggestedNextTapped: { agentTask, suggestedActionLabel in
                    appCoordinator.handleSuggestedNextAction(for: agentTask, actionLabel: suggestedActionLabel)
                },
                onTextFollowUpTapped: { agentTask in
                    appCoordinator.handleTextFollowUp(for: agentTask)
                },
                onVoiceFollowUpTapped: { agentTask in
                    appCoordinator.handleVoiceFollowUp(for: agentTask)
                }
            )

            // The completion toast, anchored near the top-right toward the menu bar icon.
            if let activeToastMessage = appCoordinator.activeToastMessage {
                CompletionToastView(message: activeToastMessage) {
                    appCoordinator.dismissCompletionToast()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, DS.Spacing.small)
                .padding(.trailing, DS.Spacing.extraLarge)
            }

            // The cursor-trailing glyph, positioned at the tracked cursor location (plus offset).
            if let cursorGlyphState = appCoordinator.currentCursorGlyphState {
                CursorGlyphView(glyphState: cursorGlyphState, glyphColor: appCoordinator.cursorGlyphColor)
                    .position(
                        x: appCoordinator.cursorGlyphPositionInOverlay.x + cursorGlyphOffset.width,
                        y: appCoordinator.cursorGlyphPositionInOverlay.y + cursorGlyphOffset.height
                    )
            }
        }
        // The overlay content itself must never intercept clicks — clicks belong to the app below.
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
