import Foundation

// The lifecycle state of a single background agent task, surfaced as the colored status pill in
// the top-right task card (green "Done", blue "Running", red "Error").
enum AgentTaskState: Equatable {
    case running
    case done
    case error

    // The short label rendered inside the status pill.
    var pillLabel: String {
        switch self {
        case .running:
            return "Running"
        case .done:
            return "Done"
        case .error:
            return "Error"
        }
    }
}

// One background agent task. This is the model behind the workhorse "task card" component:
// a small-caps title, a status pill, a plain-English result sentence, and follow-up suggestions.
struct AgentTask: Identifiable, Equatable {
    // Stable identity so SwiftUI can diff the card stack as tasks are added / updated.
    let id: UUID

    // The bold small-caps title shown in the card header (e.g. "SET DINNER REMINDER").
    var title: String

    // Current lifecycle state, driving the status pill color + label.
    var state: AgentTaskState

    // One plain-language sentence describing the result (shown once the task completes), e.g.
    // "Your reminder is set for Friday at 9:00 PM to get dinner with Sharif at Pakwan."
    var resultSentence: String

    // Zero or more "SUGGESTED NEXT" action labels, rendered as tappable capsule pills.
    var suggestedNext: [String]

    init(
        id: UUID = UUID(),
        title: String,
        state: AgentTaskState,
        resultSentence: String = "",
        suggestedNext: [String] = []
    ) {
        self.id = id
        self.title = title
        self.state = state
        self.resultSentence = resultSentence
        self.suggestedNext = suggestedNext
    }
}
