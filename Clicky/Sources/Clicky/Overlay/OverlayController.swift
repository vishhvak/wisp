import AppKit
import SwiftUI

// Manages the overlay windows Clicky paints on the user's screen. There are TWO panels, owned by a
// single controller, because they have fundamentally different mouse-event needs:
//
//   1. `teachingOverlayPanel` — a full-screen, CLICK-THROUGH panel hosting the teaching ink and the
//      cursor-trailing glyph. It must let every click fall through to the app underneath, so
//      `ignoresMouseEvents = true`.
//
//   2. `cardsPanel` — a small panel anchored top-right, sized to fit its content, hosting the task
//      cards and completion toast. These have real buttons, so it must RECEIVE clicks
//      (`ignoresMouseEvents = false`). It is sized tightly to its content so only the card area (not
//      the whole screen) intercepts clicks.
//
// Both panels are `.nonactivatingPanel` so showing them never steals focus from the user's app.
@MainActor
final class OverlayController {
    // The coordinator supplies the observable state (companion state, tasks, annotations, toast,
    // cursor position) that the hosted SwiftUI views render.
    private unowned let appCoordinator: AppCoordinator

    // (1) The full-screen click-through panel for teaching ink + cursor glyph.
    private var teachingOverlayPanel: NSPanel?

    // (2) The small, content-sized, clickable panel for task cards + toast.
    private var cardsPanel: NSPanel?
    // Hosting controller for the cards panel, using preferred-content-size sizing so the panel can
    // shrink/grow to exactly fit its cards, keeping click-blocking confined to the card area.
    private var cardsHostingController: NSHostingController<CardsPanelRootView>?
    // Observes the cards content size so we can resize + re-anchor the cards panel top-right.
    private var cardsContentSizeObservation: NSKeyValueObservation?

    // Global + local mouse-move monitors so the cursor glyph can trail the real OS cursor.
    private var globalMouseMoveMonitor: Any?
    private var localMouseMoveMonitor: Any?

    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }

    // Creates (once) and shows both overlay panels over the main screen.
    func show() {
        if teachingOverlayPanel == nil {
            teachingOverlayPanel = buildTeachingOverlayPanel()
        }
        if cardsPanel == nil {
            cardsPanel = buildCardsPanel()
        }
        teachingOverlayPanel?.orderFrontRegardless()
        cardsPanel?.orderFrontRegardless()
        startTrackingGlobalMouseLocation()
    }

    // Hides both panels and stops mouse tracking (used for the transient-cursor fade-out).
    func hide() {
        teachingOverlayPanel?.orderOut(nil)
        cardsPanel?.orderOut(nil)
        stopTrackingGlobalMouseLocation()
    }

    // MARK: - (1) Teaching overlay panel (full-screen, click-through)

    private func buildTeachingOverlayPanel() -> NSPanel {
        // Cover the main screen. (Multi-monitor teaching ink is routed per-display by mapping global
        // coordinates; the panel itself sits on the main screen where the menu bar lives.)
        let mainScreenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let panel = NSPanel(
            contentRect: mainScreenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Let every click fall through to the app underneath — this panel is display-only ink.
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false

        let teachingHostingView = NSHostingView(rootView: TeachingOverlayRootView(appCoordinator: appCoordinator))
        teachingHostingView.frame = NSRect(origin: .zero, size: mainScreenFrame.size)
        teachingHostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = teachingHostingView

        return panel
    }

    // MARK: - (2) Cards panel (small, content-sized, clickable)

    private func buildCardsPanel() -> NSPanel {
        let panel = NSPanel(
            // Start with a small placeholder rect; the real size comes from the content below.
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // This panel DOES receive clicks (the card buttons need them) but never activates Clicky, so
        // the user's foreground app keeps focus while they click a card action.
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false

        // Use an NSHostingController with preferred-content-size sizing so the hosting view reports
        // its ideal size, which we mirror onto the panel frame. This keeps the click-blocking region
        // tight to the actual cards instead of spanning the screen.
        let hostingController = NSHostingController(rootView: CardsPanelRootView(appCoordinator: appCoordinator))
        hostingController.sizingOptions = [.preferredContentSize]
        panel.contentViewController = hostingController
        self.cardsHostingController = hostingController

        // Whenever the content's preferred size changes (a card added/removed, toast shown/hidden),
        // resize the panel to fit and re-anchor it to the screen's top-right corner.
        cardsContentSizeObservation = hostingController.observe(\.preferredContentSize, options: [.new, .initial]) { [weak self] _, _ in
            Task { @MainActor in
                self?.resizeAndAnchorCardsPanelTopRight()
            }
        }

        return panel
    }

    // Resizes the cards panel to its content's preferred size and pins its top-right corner just
    // below the menu bar on the right edge of the main screen.
    private func resizeAndAnchorCardsPanelTopRight() {
        guard let cardsPanel, let cardsHostingController else { return }

        let preferredContentSize = cardsHostingController.preferredContentSize
        // Guard against a zero size (no cards + no toast) — nothing to place.
        guard preferredContentSize.width > 1, preferredContentSize.height > 1 else { return }

        let mainScreen = NSScreen.main ?? NSScreen.screens.first
        let fullScreenFrame = mainScreen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        // visibleFrame excludes the menu bar, so its top edge is where cards should hang from.
        let visibleScreenFrame = mainScreen?.visibleFrame ?? fullScreenFrame

        let horizontalMargin: CGFloat = 16
        let topMargin: CGFloat = 8

        // Panel origin is bottom-left. Pin the right edge and put the TOP edge just under the menu bar.
        let panelOriginX = fullScreenFrame.maxX - preferredContentSize.width - horizontalMargin
        let panelOriginY = visibleScreenFrame.maxY - preferredContentSize.height - topMargin

        cardsPanel.setFrame(
            NSRect(x: panelOriginX, y: panelOriginY, width: preferredContentSize.width, height: preferredContentSize.height),
            display: true
        )
    }

    // MARK: - Cursor tracking

    // Installs global + local mouse-move monitors and seeds an initial cursor position so the glyph
    // can ride next to the OS cursor. WHY both monitors: the global monitor sees movement over other
    // apps, while the local monitor covers movement over Clicky's own overlay panels.
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

    // Reads the current global mouse location and converts it into the teaching overlay's
    // top-left-origin coordinate space so the SwiftUI glyph can be positioned with `.position`.
    private func updateCursorGlyphPositionFromCurrentMouseLocation() {
        guard let teachingOverlayPanel else { return }
        let panelFrame = teachingOverlayPanel.frame

        // NSEvent.mouseLocation is in global screen coordinates with a BOTTOM-left origin (AppKit).
        let mouseLocationBottomLeftOrigin = NSEvent.mouseLocation

        // Convert to the hosting view's TOP-left origin space, relative to the panel's frame.
        let cursorXInOverlay = mouseLocationBottomLeftOrigin.x - panelFrame.origin.x
        let cursorYInOverlay = panelFrame.size.height - (mouseLocationBottomLeftOrigin.y - panelFrame.origin.y)

        appCoordinator.cursorGlyphPositionInOverlay = CGPoint(x: cursorXInOverlay, y: cursorYInOverlay)
    }
}

// The click-through overlay content: teaching ink (bottom) and the cursor-trailing glyph (top).
// Nothing here is interactive, so the whole view disables hit-testing and the panel is click-through.
struct TeachingOverlayRootView: View {
    @ObservedObject var appCoordinator: AppCoordinator

    // A small offset so the glyph rides just down-and-right of the actual cursor tip (matching the
    // demos), rather than sitting directly on top of the arrow.
    private let cursorGlyphOffset = CGSize(width: 14, height: 16)

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Teaching ink spans the whole overlay at absolute coordinates.
            TeachingOverlayView(teachingAnnotations: appCoordinator.teachingAnnotations)

            // The cursor-trailing glyph, positioned at the tracked cursor location (plus offset).
            if let cursorGlyphState = appCoordinator.currentCursorGlyphState {
                CursorGlyphView(glyphState: cursorGlyphState, glyphColor: appCoordinator.cursorGlyphColor)
                    .position(
                        x: appCoordinator.cursorGlyphPositionInOverlay.x + cursorGlyphOffset.width,
                        y: appCoordinator.cursorGlyphPositionInOverlay.y + cursorGlyphOffset.height
                    )
            }
        }
        // This layer must never intercept clicks — clicks belong to the app below.
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// The clickable cards-panel content: the completion toast (top) and the task-card stack beneath it.
// This is hosted in the small top-right panel that DOES receive clicks, so buttons work here. The
// view is content-sized (no infinity frames) so the hosting controller reports a tight preferred size.
struct CardsPanelRootView: View {
    @ObservedObject var appCoordinator: AppCoordinator

    var body: some View {
        VStack(alignment: .trailing, spacing: DS.Spacing.medium) {
            // The completion toast, when present, sits above the cards (it fires first in the demo).
            if let activeToastMessage = appCoordinator.activeToastMessage {
                CompletionToastView(message: activeToastMessage) {
                    appCoordinator.dismissCompletionToast()
                }
            }

            // The task-card stack (newest on top), each card with working buttons.
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
        }
        // Pad around the content and size the view to exactly its content so the hosting controller's
        // preferredContentSize is tight (only the card area blocks clicks).
        .padding(DS.Spacing.medium)
        .fixedSize()
    }
}
