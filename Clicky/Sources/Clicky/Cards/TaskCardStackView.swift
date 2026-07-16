import SwiftUI

// Stacks the active task cards in the top-right corner of the overlay, newest card on top. This is
// the visual home of concurrent agent tasks: each running/finished task gets its own card, and new
// ones slide in above the older ones. Rendered inside the full-screen overlay panel.
struct TaskCardStackView: View {
    // The tasks to show, in creation order (oldest first). We reverse for display so the newest is
    // rendered at the top of the stack.
    let agentTasks: [AgentTask]

    // Forwarded per-task action callbacks (identified by task id so the host knows which card acted).
    var onSuggestedNextTapped: (AgentTask, String) -> Void = { _, _ in }
    var onTextFollowUpTapped: (AgentTask) -> Void = { _ in }
    var onVoiceFollowUpTapped: (AgentTask) -> Void = { _ in }

    var body: some View {
        // A tight, content-sized stack (trailing-aligned) — the panel that hosts it does the actual
        // top-right screen anchoring now, so this view no longer stretches to fill the screen.
        VStack(alignment: .trailing, spacing: DS.Spacing.medium) {
            // newest-on-top: reverse creation order so the most recent task card sits at the top.
            ForEach(agentTasks.reversed()) { agentTask in
                TaskCardView(
                    agentTask: agentTask,
                    onSuggestedNextTapped: { suggestedActionLabel in
                        onSuggestedNextTapped(agentTask, suggestedActionLabel)
                    },
                    onTextFollowUpTapped: {
                        onTextFollowUpTapped(agentTask)
                    },
                    onVoiceFollowUpTapped: {
                        onVoiceFollowUpTapped(agentTask)
                    }
                )
                // Cards enter from the top-trailing corner and fade, matching the demo's quick slide.
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: agentTasks)
    }
}
