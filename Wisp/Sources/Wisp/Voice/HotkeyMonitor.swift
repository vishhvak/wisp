import AppKit
import CoreGraphics

// The distinct invocation gestures Wisp recognizes, matching the verified gesture set:
//   • hold ctrl+option        → push-to-talk (ask/agent voice)
//   • hold fn+control         → dictation
//   • double-tap Control      → text mode
//   • triple-tap Control      → always-on mode
enum HotkeyEvent: Equatable {
    case pushToTalkPressed
    case pushToTalkReleased
    case dictationPressed
    case dictationReleased
    case controlDoubleTapped   // text mode
    case controlTripleTapped   // always-on mode
}

// Monitors system-wide modifier-key activity to detect Wisp's invocation gestures.
//
// WHY a listen-only CGEvent tap (kCGEventTapOptionListenOnly): modifier-only shortcuts like
// "hold ctrl+option" are detected far more reliably through a low-level event tap than through an
// AppKit global monitor, and listen-only means we observe events without consuming/altering them —
// Wisp never swallows the user's keystrokes. This DOES require the Accessibility permission; if
// the tap cannot be created (permission not yet granted), we degrade gracefully to an NSEvent
// global monitor so the app still functions, just slightly less reliably.
final class HotkeyMonitor {
    // The closure invoked on the main thread whenever a gesture is recognized.
    var onHotkeyEvent: ((HotkeyEvent) -> Void)?

    // The active CGEvent tap (nil when we fell back to the NSEvent monitor path).
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // The fallback AppKit monitor token, used only when the CGEvent tap can't be created.
    private var fallbackGlobalMonitor: Any?

    // Tracks the currently-held combos so we only emit one "pressed" and one "released" per hold.
    private var isPushToTalkComboHeld = false
    private var isDictationComboHeld = false

    // State for detecting rapid double / triple taps of the Control key alone.
    private var recentControlTapTimestamps: [TimeInterval] = []
    private var wasControlKeyDownOnLastFlagsChange = false
    // Two taps within this window count as a multi-tap sequence.
    private let multiTapWindowSeconds: TimeInterval = 0.4

    func start() {
        // Attempt the preferred low-level tap first; fall back if it can't be installed.
        if installCGEventTap() {
            return
        }
        installFallbackGlobalMonitor()
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil

        if let fallbackGlobalMonitor {
            NSEvent.removeMonitor(fallbackGlobalMonitor)
        }
        fallbackGlobalMonitor = nil
    }

    // MARK: - Preferred path: listen-only CGEvent tap

    private func installCGEventTap() -> Bool {
        // We only care about flagsChanged (modifier keys) and keyDown (to see the Control taps).
        let eventMaskToObserve = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)

        // The C callback can't capture Swift context, so we pass `self` through the userInfo pointer
        // and trampoline back into an instance method.
        let opaqueSelfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let createdEventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,   // observe only — never modify or swallow the user's input
            eventsOfInterest: CGEventMask(eventMaskToObserve),
            callback: { _, _, cgEvent, userInfoPointer in
                // Trampoline: recover `self` and forward the event, then pass it through unchanged.
                if let userInfoPointer {
                    let hotkeyMonitor = Unmanaged<HotkeyMonitor>.fromOpaque(userInfoPointer).takeUnretainedValue()
                    hotkeyMonitor.handleTappedEvent(cgEvent)
                }
                return Unmanaged.passUnretained(cgEvent)
            },
            userInfo: opaqueSelfPointer
        ) else {
            // Most commonly this means Accessibility permission has not been granted yet.
            return false
        }

        let createdRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, createdEventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), createdRunLoopSource, .commonModes)
        CGEvent.tapEnable(tap: createdEventTap, enable: true)

        self.eventTap = createdEventTap
        self.runLoopSource = createdRunLoopSource
        return true
    }

    // Processes a single tapped event, updating combo state and emitting gestures.
    private func handleTappedEvent(_ cgEvent: CGEvent) {
        let currentFlags = cgEvent.flags
        evaluateModifierCombos(currentFlags: currentFlags)
        evaluateControlMultiTaps(currentFlags: currentFlags)
    }

    // MARK: - Fallback path: AppKit global monitor

    private func installFallbackGlobalMonitor() {
        // A global monitor observes events destined for other apps. It's less reliable for pure
        // modifier holds than the CGEvent tap, but keeps basic functionality without Accessibility.
        fallbackGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] nsEvent in
            guard let self else { return }
            let cgFlags = CGEventFlags(rawValue: UInt64(nsEvent.modifierFlags.rawValue))
            self.evaluateModifierCombos(currentFlags: cgFlags)
            self.evaluateControlMultiTaps(currentFlags: cgFlags)
        }
    }

    // MARK: - Gesture recognition (shared by both paths)

    // Detects the two hold-combos (ctrl+option → PTT, fn+control → dictation) as press/release pairs.
    private func evaluateModifierCombos(currentFlags: CGEventFlags) {
        let isControlHeld = currentFlags.contains(.maskControl)
        let isOptionHeld = currentFlags.contains(.maskAlternate)
        let isFunctionHeld = currentFlags.contains(.maskSecondaryFn)

        // Push-to-talk = control + option (and NOT the fn key, to keep it distinct from dictation).
        let isPushToTalkComboActive = isControlHeld && isOptionHeld && !isFunctionHeld
        if isPushToTalkComboActive && !isPushToTalkComboHeld {
            isPushToTalkComboHeld = true
            emit(.pushToTalkPressed)
        } else if !isPushToTalkComboActive && isPushToTalkComboHeld {
            isPushToTalkComboHeld = false
            emit(.pushToTalkReleased)
        }

        // Dictation = fn + control.
        let isDictationComboActive = isFunctionHeld && isControlHeld
        if isDictationComboActive && !isDictationComboHeld {
            isDictationComboHeld = true
            emit(.dictationPressed)
        } else if !isDictationComboActive && isDictationComboHeld {
            isDictationComboHeld = false
            emit(.dictationReleased)
        }
    }

    // Detects double / triple taps of Control alone (no other modifier), within a short window.
    private func evaluateControlMultiTaps(currentFlags: CGEventFlags) {
        let isControlHeld = currentFlags.contains(.maskControl)
        let isAnyOtherModifierHeld =
            currentFlags.contains(.maskAlternate) ||
            currentFlags.contains(.maskShift) ||
            currentFlags.contains(.maskCommand) ||
            currentFlags.contains(.maskSecondaryFn)

        // We count a "tap" on the transition from Control-up to Control-down, with no other modifier.
        let isControlPressTransition = isControlHeld && !wasControlKeyDownOnLastFlagsChange
        wasControlKeyDownOnLastFlagsChange = isControlHeld

        guard isControlPressTransition && !isAnyOtherModifierHeld else {
            return
        }

        let nowTimestamp = Date().timeIntervalSince1970
        // Drop any taps older than the multi-tap window so stale taps don't accumulate.
        recentControlTapTimestamps = recentControlTapTimestamps.filter { nowTimestamp - $0 <= multiTapWindowSeconds }
        recentControlTapTimestamps.append(nowTimestamp)

        if recentControlTapTimestamps.count == 3 {
            recentControlTapTimestamps.removeAll()
            emit(.controlTripleTapped)
        } else if recentControlTapTimestamps.count == 2 {
            // We emit the double-tap immediately; if a third tap lands within the window it will be
            // treated as the start of a new sequence. This keeps double-tap responsive.
            emit(.controlDoubleTapped)
        }
    }

    // Delivers a recognized gesture on the main thread.
    private func emit(_ hotkeyEvent: HotkeyEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.onHotkeyEvent?(hotkeyEvent)
        }
    }
}
