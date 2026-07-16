import SwiftUI

// The workhorse "task card" — a dark charcoal card, anchored top-right, that surfaces the status
// and result of a single background agent task. Layout, top to bottom:
//   • header row: SMALL-CAPS bold title + colored status pill
//   • result sentence (plain English)
//   • "SUGGESTED NEXT" label + capsule action pills
//   • "FOLLOW UP" label + Text / Voice pills
// The card doubles as the "continue this thread" surface via its follow-up pills.
struct TaskCardView: View {
    let agentTask: AgentTask

    // Callbacks the host wires up to actually perform the follow-up / suggested actions. They are
    // no-ops by default so the card can be previewed or dropped in without a coordinator.
    var onSuggestedNextTapped: (String) -> Void = { _ in }
    var onTextFollowUpTapped: () -> Void = {}
    var onVoiceFollowUpTapped: () -> Void = {}

    // A fixed, comfortable card width matching the compact top-right card in the demos.
    private let cardWidth: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.medium) {
            headerRow

            // The result sentence only reads well once there is copy to show.
            if !agentTask.resultSentence.isEmpty {
                Text(agentTask.resultSentence)
                    .font(.system(size: 13))
                    .foregroundColor(DS.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !agentTask.suggestedNext.isEmpty {
                suggestedNextSection
            }

            followUpSection
        }
        .padding(DS.Spacing.large)
        .frame(width: cardWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.CornerRadius.card, style: .continuous)
                .fill(DS.Colors.cardCharcoal)
        )
        // A soft shadow lifts the card off whatever is behind it on screen.
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 8)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center, spacing: DS.Spacing.small) {
            // Bold small-caps title. SwiftUI's `.smallCaps()` gives the leaked design's title style.
            Text(agentTask.title)
                .font(.system(size: 13, weight: .bold))
                .textCase(.uppercase)
                .kerning(0.6)
                .foregroundColor(DS.Colors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: DS.Spacing.small)

            statusPill
        }
    }

    // The colored status pill (green Done, blue Running, red Error).
    private var statusPill: some View {
        Text(agentTask.state.pillLabel)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, DS.Spacing.small)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(statusPillColor)
            )
    }

    private var statusPillColor: Color {
        switch agentTask.state {
        case .running:
            return DS.Colors.listeningBlue
        case .done:
            return DS.Colors.doneGreen
        case .error:
            return DS.Colors.teachRed
        }
    }

    // MARK: - Suggested next

    private var suggestedNextSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.small) {
            sectionLabel("SUGGESTED NEXT")

            // The suggested-next actions wrap onto multiple rows if there are several.
            FlowingPillLayout(spacing: DS.Spacing.small) {
                ForEach(agentTask.suggestedNext, id: \.self) { suggestedActionLabel in
                    CardActionPill(label: suggestedActionLabel, systemImageName: nil) {
                        onSuggestedNextTapped(suggestedActionLabel)
                    }
                }
            }
        }
    }

    // MARK: - Follow up

    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.small) {
            sectionLabel("FOLLOW UP")

            HStack(spacing: DS.Spacing.small) {
                // "Text" continues the thread by typing; "Voice" continues it by speaking.
                CardActionPill(label: "Text", systemImageName: "textformat") {
                    onTextFollowUpTapped()
                }
                CardActionPill(label: "Voice", systemImageName: "mic.fill") {
                    onVoiceFollowUpTapped()
                }
            }
        }
    }

    // A small dim caps section label, shared by both the suggested-next and follow-up sections.
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .kerning(0.8)
            .foregroundColor(DS.Colors.sectionLabel)
    }
}

// A dark capsule action pill with optional leading SF Symbol. Shows the pointing-hand cursor on
// hover and a subtle press/hover highlight so it reads as clickable.
struct CardActionPill: View {
    let label: String
    let systemImageName: String?
    let onTapped: () -> Void

    @State private var isPointerHovering = false

    var body: some View {
        Button(action: onTapped) {
            HStack(spacing: DS.Spacing.extraSmall) {
                if let systemImageName {
                    Image(systemName: systemImageName)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(DS.Colors.primaryText)
            .padding(.horizontal, DS.Spacing.medium)
            .padding(.vertical, DS.Spacing.small)
            .background(
                Capsule(style: .continuous)
                    .fill(DS.Colors.pillFill.opacity(isPointerHovering ? 0.20 : 0.10))
            )
        }
        .buttonStyle(.plain)
        .onHover { isPointerInside in
            isPointerHovering = isPointerInside
        }
        .pointerCursorOnHover()
    }
}

// A minimal flow layout that lays pills left-to-right and wraps to the next row when it runs out of
// width. SwiftUI's built-in stacks can't wrap, so this small Layout handles the "suggested next"
// pills that may not fit on one line.
struct FlowingPillLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let availableWidth = proposal.width ?? .infinity
        let arrangedRows = arrangeIntoRows(subviews: subviews, availableWidth: availableWidth)
        let totalHeight = arrangedRows.reduce(CGFloat.zero) { runningHeight, row in
            runningHeight + row.rowHeight + (runningHeight > 0 ? spacing : 0)
        }
        return CGSize(width: availableWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let arrangedRows = arrangeIntoRows(subviews: subviews, availableWidth: bounds.width)
        var currentYPosition = bounds.minY

        for row in arrangedRows {
            var currentXPosition = bounds.minX
            for placedSubviewIndex in row.subviewIndices {
                let subviewSize = subviews[placedSubviewIndex].sizeThatFits(.unspecified)
                subviews[placedSubviewIndex].place(
                    at: CGPoint(x: currentXPosition, y: currentYPosition),
                    proposal: ProposedViewSize(subviewSize)
                )
                currentXPosition += subviewSize.width + spacing
            }
            currentYPosition += row.rowHeight + spacing
        }
    }

    // Groups the subviews into rows that each fit within the available width.
    private func arrangeIntoRows(subviews: Subviews, availableWidth: CGFloat) -> [PillRow] {
        var arrangedRows: [PillRow] = []
        var currentRow = PillRow()
        var currentRowWidth: CGFloat = 0

        for subviewIndex in subviews.indices {
            let subviewSize = subviews[subviewIndex].sizeThatFits(.unspecified)
            let widthIfAdded = currentRowWidth + subviewSize.width + (currentRow.subviewIndices.isEmpty ? 0 : spacing)

            if widthIfAdded > availableWidth && !currentRow.subviewIndices.isEmpty {
                arrangedRows.append(currentRow)
                currentRow = PillRow()
                currentRowWidth = 0
            }

            currentRow.subviewIndices.append(subviewIndex)
            currentRow.rowHeight = max(currentRow.rowHeight, subviewSize.height)
            currentRowWidth += subviewSize.width + (currentRow.subviewIndices.count > 1 ? spacing : 0)
        }

        if !currentRow.subviewIndices.isEmpty {
            arrangedRows.append(currentRow)
        }
        return arrangedRows
    }

    // One row of the flow layout: which subviews it holds and how tall it is.
    private struct PillRow {
        var subviewIndices: [Int] = []
        var rowHeight: CGFloat = 0
    }
}
