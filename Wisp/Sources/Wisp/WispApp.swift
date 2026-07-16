import SwiftUI
import AppKit
import AVFoundation
import Speech

// The application entry point. Wisp is a menu-bar-only companion: no dock icon, no main window.
// It uses SwiftUI's MenuBarExtra for the menu-bar presence and an AppKit app delegate to set the
// activation policy to .accessory (which is what removes the dock icon).
@main
struct WispApp: App {
    // Bridge in an AppKit delegate so we can set NSApp.setActivationPolicy(.accessory) at launch and
    // own the AppCoordinator's lifecycle. SwiftUI's App type alone can't set the accessory policy.
    @NSApplicationDelegateAdaptor(CompanionAppDelegate.self) private var companionAppDelegate

    var body: some Scene {
        // The menu-bar item. Its icon reflects the current companion state, and clicking it opens
        // the companion panel (rendered as the MenuBarExtra's content).
        MenuBarExtra {
            CompanionMenuContent(appCoordinator: companionAppDelegate.appCoordinator)
        } label: {
            // The label shows the state icon plus the state text label ("Always on", etc.), matching
            // the demo's menu-bar text status that swaps with state.
            MenuBarLabel(appCoordinator: companionAppDelegate.appCoordinator)
        }
        // `.window` gives us a real panel we control the content of, rather than a system menu.
        .menuBarExtraStyle(.window)
    }
}

// The AppKit delegate: sets the accessory activation policy (no dock icon) and starts the
// coordinator once the app has finished launching. Marked @MainActor because it constructs and owns
// the @MainActor AppCoordinator (the delegate's callbacks all run on the main thread anyway).
@MainActor
final class CompanionAppDelegate: NSObject, NSApplicationDelegate {
    // The single coordinator instance for the whole app. Created here so both the delegate and the
    // SwiftUI scene share exactly one.
    let appCoordinator = AppCoordinator()

    // Held for the app's lifetime: an accessory app with no windows is a prime App Nap candidate,
    // and a napped Wisp (or its napped Python child) turns push-to-talk into a 5–10s wait. The
    // latency-critical assertion keeps the voice pipeline wake-ready.
    private var appNapPreventionActivity: NSObjectProtocol?

    // True when Wisp is running from a real .app bundle (vs a bare `swift run` binary). Several
    // TCC-gated APIs (Speech Recognition especially) hard-abort the process when requested from an
    // unbundled binary, so permission REQUESTS are gated on this.
    static var isRunningFromAppBundle: Bool {
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // .accessory = menu-bar/background app with NO dock icon and no default main menu window.
        NSApp.setActivationPolicy(.accessory)

        appNapPreventionActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "Wisp voice pipeline must stay wake-ready for push-to-talk"
        )

        // NOTE deliberately NOT requesting Speech Recognition here. For a bare terminal-launched
        // binary, TCC ABORTS the process on that request (__TCC_CRASHING_DUE_TO_PRIVACY_VIOLATION__)
        // instead of failing politely — it demands a real .app bundle for this permission class.
        // Speech auth is only requested when running bundled (scripts/make-app.sh); Parakeet (the
        // primary, local STT) needs no speech permission at all.
        WispLog.log(
            "voice",
            "Speech Recognition status at launch: \(SFSpeechRecognizer.authorizationStatus().rawValue) (3=authorized); bundled: \(Self.isRunningFromAppBundle)"
        )

        // Bring up the overlay and start listening for hotkeys.
        appCoordinator.start()
    }
}

// The menu-bar label: the state icon + state text. Observes the coordinator so it re-renders as the
// companion state changes.
struct MenuBarLabel: View {
    @ObservedObject var appCoordinator: AppCoordinator

    var body: some View {
        // A horizontal label pairing the state SF Symbol with the state's text ("Always on", etc.).
        HStack(spacing: 4) {
            Image(systemName: appCoordinator.menuBarIconSystemName)
            Text(appCoordinator.currentDisplayLabel)
        }
    }
}

// The content of the companion panel that drops down from the menu-bar item. A compact dark panel
// showing the current state, the push-to-talk instructions, the cursor-color note, and a quit
// button. This maps to the old CompanionPanelView, scoped down for the clean rebuild.
struct CompanionMenuContent: View {
    @ObservedObject var appCoordinator: AppCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.medium) {
            // Header: brand mark + current state label.
            HStack(spacing: DS.Spacing.small) {
                Image(systemName: "cursorarrow.rays")
                    .foregroundColor(DS.Colors.brand)
                Text("Wisp")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(appCoordinator.currentDisplayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.Colors.secondaryText)
            }

            Divider()

            // The invocation-gesture cheat sheet.
            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                gestureRow(gesture: "Hold ⌃ control + ⌥ option", description: "Talk to Wisp")
                gestureRow(gesture: "Hold fn + control", description: "Dictate into any field")
                gestureRow(gesture: "Double-tap Control", description: "Text mode")
                gestureRow(gesture: "Triple-tap Control", description: "Always-on mode")
            }

            Divider()

            // Live permission diagnostics — the difference between "nothing works lol" and knowing
            // exactly which grant is missing. Each ungranted row is a button into the right pane.
            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                permissionRow(
                    name: "Accessibility",
                    isGranted: AXIsProcessTrusted(),
                    settingsPane: "Privacy_Accessibility",
                    note: "hotkeys"
                )
                permissionRow(
                    name: "Microphone",
                    isGranted: AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
                    settingsPane: "Privacy_Microphone",
                    note: "voice"
                )
                permissionRow(
                    name: "Speech Recognition",
                    isGranted: SFSpeechRecognizer.authorizationStatus() == .authorized,
                    settingsPane: "Privacy_SpeechRecognition",
                    note: "fallback STT"
                )
                permissionRow(
                    name: "Screen Recording",
                    isGranted: CGPreflightScreenCaptureAccess(),
                    settingsPane: "Privacy_ScreenCapture",
                    note: "screen context"
                )
            }

            // One-click access to the log file every subsystem writes to.
            Button {
                NSWorkspace.shared.open(WispLog.logFileURL)
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Open Log")
                    Spacer()
                    Text("~/Library/Logs/Wisp.log")
                        .font(.system(size: 10))
                        .foregroundColor(DS.Colors.secondaryText)
                }
                .foregroundColor(DS.Colors.primaryText)
            }
            .buttonStyle(.plain)
            .pointerCursorOnHover()

            Divider()

            // A quit button. Every interactive control shows the pointing-hand cursor on hover.
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Wisp")
                }
                .foregroundColor(DS.Colors.primaryText)
            }
            .buttonStyle(.plain)
            .pointerCursorOnHover()
        }
        .padding(DS.Spacing.large)
        .frame(width: 300)
    }

    // One permission row: a green check when granted; a tappable amber warning that deep-links into
    // the matching System Settings pane when not. Speech Recognition is special: if it has never
    // been REQUESTED, opening the pane shows an empty list — so fire the authorization request
    // first (which registers Wisp there and shows the system prompt), then open the pane.
    private func permissionRow(name: String, isGranted: Bool, settingsPane: String, note: String) -> some View {
        Button {
            guard !isGranted else { return }
            if settingsPane == "Privacy_SpeechRecognition",
               SFSpeechRecognizer.authorizationStatus() == .notDetermined {
                // Requesting speech auth from an UNBUNDLED binary makes TCC abort the whole app —
                // only fire the request when running as Wisp.app (scripts/make-app.sh).
                if CompanionAppDelegate.isRunningFromAppBundle {
                    SFSpeechRecognizer.requestAuthorization { grantedStatus in
                        WispLog.log("voice", "Speech Recognition authorization via menu: \(grantedStatus.rawValue) (3=authorized)")
                    }
                } else {
                    WispLog.log("voice", "speech auth request skipped — run as Wisp.app (scripts/make-app.sh) to enable the Apple Speech fallback; Parakeet needs no speech permission")
                }
                return
            }
            guard let paneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(settingsPane)") else { return }
            NSWorkspace.shared.open(paneURL)
        } label: {
            HStack(spacing: DS.Spacing.small) {
                Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isGranted ? Color(DS.Colors.doneGreen) : Color(DS.Colors.amber))
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.Colors.primaryText)
                Spacer()
                Text(isGranted ? note : "grant →")
                    .font(.system(size: 11))
                    .foregroundColor(DS.Colors.secondaryText)
            }
        }
        .buttonStyle(.plain)
        .pointerCursorOnHover()
    }

    // One row in the gesture cheat sheet: the key combo on the left, what it does on the right.
    private func gestureRow(gesture: String, description: String) -> some View {
        HStack(alignment: .top) {
            Text(gesture)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DS.Colors.primaryText)
            Spacer()
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(DS.Colors.secondaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}
