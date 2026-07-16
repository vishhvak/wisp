import AppKit
import SwiftUI

// Manages the overlay windows Wisp paints on the user's screen. There are TWO panels, owned by a
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

    // (1) The full-screen click-through panels for teaching ink + cursor glyph — ONE PER SCREEN, so
    // the glyph can follow the cursor onto any monitor. The panel covering the main screen hosts the
    // full teaching layer stack; secondary screens host a glyph-only layer. (Teaching-ink coordinates
    // live in main-screen space today; route ink per-display when [POINT:…:screenN] lands.)
    private var teachingOverlayPanels: [NSPanel] = []
    private var screenParametersObserver: Any?

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

    // Creates (once) and shows the overlay panels — one per screen — plus the cards panel.
    func show() {
        if teachingOverlayPanels.isEmpty {
            rebuildTeachingOverlayPanels()
        }
        if cardsPanel == nil {
            cardsPanel = buildCardsPanel()
        }
        for overlayPanel in teachingOverlayPanels {
            overlayPanel.orderFrontRegardless()
        }
        cardsPanel?.orderFrontRegardless()
        startTrackingGlobalMouseLocation()

        // Monitors get plugged/unplugged; rebuild the per-screen panels when the layout changes.
        if screenParametersObserver == nil {
            screenParametersObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    WispLog.log("overlay", "screen parameters changed — rebuilding overlay panels")
                    self?.rebuildTeachingOverlayPanels()
                }
            }
        }
    }

    // Hides the panels and stops mouse tracking (used for the transient-cursor fade-out).
    func hide() {
        for overlayPanel in teachingOverlayPanels {
            overlayPanel.orderOut(nil)
        }
        cardsPanel?.orderOut(nil)
        stopTrackingGlobalMouseLocation()
    }

    // MARK: - (1) Teaching overlay panels (full-screen, click-through, one per screen)

    private func rebuildTeachingOverlayPanels() {
        for oldPanel in teachingOverlayPanels {
            oldPanel.orderOut(nil)
        }
        teachingOverlayPanels.removeAll()

        let mainScreen = NSScreen.main
        for screen in NSScreen.screens {
            let isMainScreen = (screen == mainScreen)
            let panel = buildTeachingOverlayPanel(for: screen, hostsTeachingLayers: isMainScreen)
            panel.orderFrontRegardless()
            teachingOverlayPanels.append(panel)
        }
        WispLog.log("overlay", "built \(teachingOverlayPanels.count) overlay panel(s) across \(NSScreen.screens.count) screen(s)")
    }

    private func buildTeachingOverlayPanel(for screen: NSScreen, hostsTeachingLayers: Bool) -> NSPanel {
        let screenFrame = screen.frame

        let panel = NSPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Let every click fall through to the app underneath — these panels are display-only ink.
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false

        // The main screen hosts the full teaching stack (ink + pointer + glyph); secondary screens
        // host the glyph alone so the companion still rides the cursor there.
        let hostedRootView: AnyView = hostsTeachingLayers
            ? AnyView(TeachingOverlayRootView(appCoordinator: appCoordinator, screenFrame: screenFrame))
            : AnyView(GlyphOnlyOverlayRootView(appCoordinator: appCoordinator, screenFrame: screenFrame))

        let teachingHostingView = NSHostingView(rootView: hostedRootView)
        teachingHostingView.frame = NSRect(origin: .zero, size: screenFrame.size)
        teachingHostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = teachingHostingView
        panel.setFrame(screenFrame, display: true)

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

        // This panel DOES receive clicks (the card buttons need them) but never activates Wisp, so
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
    // apps, while the local monitor covers movement over Wisp's own overlay panels.
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

    // Reads the current global mouse location and publishes it in BOTH coordinate spaces the views
    // need: raw global bottom-left-origin (each per-screen overlay converts to its own space), and
    // main-screen top-left-origin (the space the teaching layers' coordinates live in).
    private func updateCursorGlyphPositionFromCurrentMouseLocation() {
        // NSEvent.mouseLocation is in global screen coordinates with a BOTTOM-left origin (AppKit).
        let mouseLocationBottomLeftOrigin = NSEvent.mouseLocation
        appCoordinator.cursorGlobalBottomLeftPoint = mouseLocationBottomLeftOrigin

        let mainScreenFrame = NSScreen.main?.frame ?? .zero
        appCoordinator.cursorGlyphPositionInOverlay = CGPoint(
            x: mouseLocationBottomLeftOrigin.x - mainScreenFrame.origin.x,
            y: mainScreenFrame.size.height - (mouseLocationBottomLeftOrigin.y - mainScreenFrame.origin.y)
        )
    }
}

// Converts a global bottom-left-origin point into a screen-local TOP-left-origin point, and says
// whether the point is on that screen at all. Shared by the per-screen glyph layers.
private func cursorPositionInScreenSpace(globalPoint: CGPoint, screenFrame: NSRect) -> CGPoint? {
    guard screenFrame.contains(globalPoint) else { return nil }
    return CGPoint(
        x: globalPoint.x - screenFrame.origin.x,
        y: screenFrame.size.height - (globalPoint.y - screenFrame.origin.y)
    )
}

// The click-through overlay content: teaching ink (bottom) and the cursor-trailing glyph (top).
// Nothing here is interactive, so the whole view disables hit-testing and the panel is click-through.
struct TeachingOverlayRootView: View {
    @ObservedObject var appCoordinator: AppCoordinator
    // The frame (global, bottom-left origin) of the screen this overlay covers — used to decide
    // whether the cursor (and so the glyph) is currently on this screen.
    let screenFrame: NSRect

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Teaching ink spans the whole overlay at absolute coordinates.
            TeachingOverlayView(teachingAnnotations: appCoordinator.teachingAnnotations)

            // The agent pointer glides (quadratic bezier) to each new annotation, ripples on
            // landing, and idle-hides — layered above the ink it announces, below the user's glyph.
            AgentPointerView(
                targetPoint: appCoordinator.agentPointerTarget,
                flightStartFallbackPoint: appCoordinator.cursorGlyphPositionInOverlay,
                pointerColor: appCoordinator.cursorGlyphColor
            )

            CursorGlyphLayer(appCoordinator: appCoordinator, screenFrame: screenFrame)
        }
        // This layer must never intercept clicks — clicks belong to the app below.
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// The overlay content for secondary screens: just the cursor-trailing glyph, so the companion
// still rides the cursor on monitors that don't host the teaching layers.
struct GlyphOnlyOverlayRootView: View {
    @ObservedObject var appCoordinator: AppCoordinator
    let screenFrame: NSRect

    var body: some View {
        ZStack(alignment: .topLeading) {
            CursorGlyphLayer(appCoordinator: appCoordinator, screenFrame: screenFrame)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// The cursor-trailing glyph, rendered only while the cursor is actually on this layer's screen,
// positioned just down-and-right of the cursor tip (matching the demos).
private struct CursorGlyphLayer: View {
    @ObservedObject var appCoordinator: AppCoordinator
    let screenFrame: NSRect

    private let cursorGlyphOffset = CGSize(width: 14, height: 16)

    var body: some View {
        if let cursorGlyphState = appCoordinator.currentCursorGlyphState,
           let cursorPositionOnThisScreen = cursorPositionInScreenSpace(
               globalPoint: appCoordinator.cursorGlobalBottomLeftPoint,
               screenFrame: screenFrame
           ) {
            CursorGlyphView(glyphState: cursorGlyphState, glyphColor: appCoordinator.cursorGlyphColor)
                .position(
                    x: cursorPositionOnThisScreen.x + cursorGlyphOffset.width,
                    y: cursorPositionOnThisScreen.y + cursorGlyphOffset.height
                )
        }
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
