import SwiftUI
import AppKit

// The application entry point. Clicky is a menu-bar-only companion: no dock icon, no main window.
// It uses SwiftUI's MenuBarExtra for the menu-bar presence and an AppKit app delegate to set the
// activation policy to .accessory (which is what removes the dock icon).
@main
struct ClickyApp: App {
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // .accessory = menu-bar/background app with NO dock icon and no default main menu window.
        NSApp.setActivationPolicy(.accessory)

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
                Text("Clicky")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(appCoordinator.currentDisplayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.Colors.secondaryText)
            }

            Divider()

            // The invocation-gesture cheat sheet.
            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                gestureRow(gesture: "Hold ⌃ control + ⌥ option", description: "Talk to Clicky")
                gestureRow(gesture: "Hold fn + control", description: "Dictate into any field")
                gestureRow(gesture: "Double-tap Control", description: "Text mode")
                gestureRow(gesture: "Triple-tap Control", description: "Always-on mode")
            }

            Divider()

            // A quit button. Every interactive control shows the pointing-hand cursor on hover.
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Clicky")
                }
                .foregroundColor(DS.Colors.primaryText)
            }
            .buttonStyle(.plain)
            .pointerCursorOnHover()
        }
        .padding(DS.Spacing.large)
        .frame(width: 300)
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
