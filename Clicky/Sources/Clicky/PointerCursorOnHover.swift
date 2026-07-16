import SwiftUI
import AppKit

// A view modifier that shows the macOS pointing-hand cursor while the pointer is over the view.
// Every interactive element in Clicky must communicate clickability on hover; centralizing the
// AppKit NSCursor bridging here means each button just writes `.pointerCursorOnHover()` instead of
// repeating the same onHover push/pop logic (which is easy to get wrong and leak a stuck cursor).
struct PointerCursorOnHover: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { isPointerInside in
            // NSCursor uses a push/pop stack. We push the pointing-hand cursor on enter and pop it
            // on exit so the arrow cursor is restored exactly once when the pointer leaves.
            if isPointerInside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    // Convenience so any interactive view can request the pointing-hand hover cursor.
    func pointerCursorOnHover() -> some View {
        modifier(PointerCursorOnHover())
    }
}
