import SwiftUI

// The SwiftUI content of the notch-anchored HUD. It renders in one of two states, driven entirely by
// the coordinator:
//   • COLLAPSED — a slim charcoal pill showing the current state label ("Always on" / "Listening" /
//     "Thinking" / "Speaking") next to a tiny state glyph.
//   • EXPANDED — a wider charcoal panel that additionally shows a line of live text: the partial
//     transcript while listening, or the last response line while responding (which then
//     auto-dismisses, collapsing the HUD back to the pill).
// Both use rounded-BOTTOM corners (square top) so the HUD reads as hanging down from the menu
// bar / camera notch.
struct NotchHUDView: View {
    @ObservedObject var appCoordinator: AppCoordinator

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private let notchCharcoal = DS.Colors.cardCharcoal
    // Corner radius applied to the bottom corners only, so the HUD hangs from the top edge.
    private let bottomCornerRadius: CGFloat = 14

    var body: some View {
        Group {
            if let expandedText = appCoordinator.notchExpandedText, !expandedText.isEmpty {
                expandedContent(expandedText)
            } else {
                collapsedPill
            }
        }
        // Size to content so the hosting panel can be anchored tightly under the notch.
        .fixedSize()
        // Animate expand/collapse unless the user prefers reduced motion.
        .animation(
            accessibilityReduceMotion ? nil : .easeInOut(duration: 0.2),
            value: appCoordinator.notchExpandedText
        )
    }

    // MARK: - Collapsed pill

    private var collapsedPill: some View {
        HStack(spacing: DS.Spacing.small) {
            notchStateGlyph
            Text(appCoordinator.currentDisplayLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DS.Colors.primaryText)
        }
        .padding(.horizontal, DS.Spacing.medium)
        .padding(.vertical, DS.Spacing.small)
        .background(notchBackground)
    }

    // MARK: - Expanded content

    private func expandedContent(_ expandedText: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.extraSmall) {
            // Header row: the same glyph + state label as the collapsed pill.
            HStack(spacing: DS.Spacing.small) {
                notchStateGlyph
                Text(appCoordinator.currentDisplayLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DS.Colors.secondaryText)
            }

            // The live line: partial transcript (listening) or last response line (responding).
            Text(expandedText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DS.Colors.primaryText)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: 360, alignment: .leading)
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.medium)
        .background(notchBackground)
    }

    // MARK: - Shared pieces

    // A charcoal background with rounded bottom corners (square top) so the HUD hangs from the notch.
    private var notchBackground: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: bottomCornerRadius,
            bottomTrailingRadius: bottomCornerRadius,
            topTrailingRadius: 0,
            style: .continuous
        )
        .fill(notchCharcoal)
        .shadow(color: Color.black.opacity(0.30), radius: 10, y: 4)
    }

    // A tiny glyph reflecting the current state. When there's a cursor glyph state (listening /
    // processing / responding) we reuse the animated cursor glyph; while idle we show a small filled
    // dot in the configured cursor color to signal "ambiently on".
    @ViewBuilder
    private var notchStateGlyph: some View {
        if let cursorGlyphState = appCoordinator.currentCursorGlyphState {
            CursorGlyphView(glyphState: cursorGlyphState, glyphColor: appCoordinator.cursorGlyphColor)
                .frame(width: 12, height: 12)
        } else {
            Circle()
                .fill(appCoordinator.cursorGlyphColor)
                .frame(width: 7, height: 7)
        }
    }
}
