import SwiftUI

// An ephemeral iMessage-blue toast bubble that fires when a task completes, BEFORE (and alongside)
// the persistent task card. It has a small tail pointing up toward the menu-bar icon, mirrors the
// task's result sentence, and auto-dismisses after roughly four seconds.
struct CompletionToastView: View {
    // The plain-English message to show (usually the same copy as the task card body).
    let message: String

    // Called when the toast has finished its auto-dismiss delay so the host can remove it.
    var onAutoDismiss: () -> Void = {}

    // How long the toast stays on screen before auto-dismissing.
    private let autoDismissDelaySeconds: Double = 4.0

    private let toastMaximumWidth: CGFloat = 280

    var body: some View {
        VStack(spacing: 0) {
            // The small upward tail that visually connects the toast to the menu-bar icon above it.
            UpwardTailShape()
                .fill(DS.Colors.toastBlue)
                .frame(width: 16, height: 7)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DS.Spacing.large)
                .padding(.vertical, DS.Spacing.medium)
                .frame(maxWidth: toastMaximumWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DS.CornerRadius.toast, style: .continuous)
                        .fill(DS.Colors.toastBlue)
                )
        }
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 4)
        .task {
            // Schedule the auto-dismiss. Using an async sleep keeps this cancellable if the toast
            // view is removed early (SwiftUI cancels the `.task` when the view disappears).
            try? await Task.sleep(nanoseconds: UInt64(autoDismissDelaySeconds * 1_000_000_000))
            onAutoDismiss()
        }
    }
}

// The little triangular tail at the top of the toast, apex pointing up toward the menu bar.
private struct UpwardTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var tailPath = Path()
        tailPath.move(to: CGPoint(x: rect.midX, y: rect.minY))   // apex, top-center
        tailPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // bottom-right
        tailPath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // bottom-left
        tailPath.closeSubpath()
        return tailPath
    }
}
