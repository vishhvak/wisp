import SwiftUI

// The notch island — Wisp's Dynamic-Island-style state surface. The island is a single pure-black
// shape rendered flush with the physical notch cutout, so growing it reads as the hardware itself
// expanding. Three presentations, driven entirely by the coordinator:
//
//   • HIDDEN   — idle: the island exactly matches the notch (pure black on pure black → invisible).
//                On non-notch displays it renders nothing at all.
//   • COMPACT  — listening / thinking / speaking: "ears" grow OUTWARD beside the notch — the state
//                glyph in the left ear, the state label in the right ear — while the middle spans
//                the sensor housing, like iOS's compact Dynamic Island presentations.
//   • EXPANDED — a live text line (partial transcript while listening, the response line while
//                speaking) hangs BELOW the notch line; the island widens and drops with a spring.
//
// Every geometry change animates through one spring, so hidden → compact → expanded is a continuous
// morph of a single shape, never a swap between two views.
struct NotchHUDView: View {
    @ObservedObject var appCoordinator: AppCoordinator

    // Physical notch metrics measured by the controller. width == 0 means "no notch" — the island
    // falls back to a floating top-center pill (and hides entirely while idle).
    let notchWidth: CGFloat
    let notchHeight: CGFloat

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private enum IslandPresentation: Equatable {
        case hidden
        case compact
        case expanded
    }

    private var presentation: IslandPresentation {
        if let expandedText = appCoordinator.notchExpandedText, !expandedText.isEmpty {
            return .expanded
        }
        if appCoordinator.companionState != .idle {
            return .compact
        }
        return .hidden
    }

    // iOS's island uses a snappy-but-composed spring; this matches that feel. Reduce Motion swaps
    // the morph for an instant change (content still communicates state).
    private var islandSpring: Animation? {
        accessibilityReduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.72)
    }

    // Pure black is load-bearing: it's what makes the island visually continuous with the cutout.
    private let islandBlack = Color.black
    private let hasPhysicalNotch: Bool

    init(appCoordinator: AppCoordinator, notchWidth: CGFloat, notchHeight: CGFloat) {
        self.appCoordinator = appCoordinator
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.hasPhysicalNotch = notchWidth > 0
    }

    var body: some View {
        // The island hangs from the top-center of the fixed transparent canvas the controller built.
        VStack(spacing: 0) {
            islandBody
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(islandSpring, value: presentation)
        .animation(islandSpring, value: appCoordinator.notchExpandedText)
    }

    // MARK: - The island

    @ViewBuilder
    private var islandBody: some View {
        // On non-notch displays there is no cutout to blend into, so idle renders nothing.
        if !hasPhysicalNotch && presentation == .hidden {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                earsRow
                if presentation == .expanded, let expandedText = appCoordinator.notchExpandedText {
                    belowNotchTextArea(expandedText)
                }
            }
            .background(islandShape)
            .fixedSize()
        }
    }

    // The row at notch height: leading ear + a spacer exactly as wide as the sensor housing + the
    // trailing ear. While hidden both ears are empty, so the shape collapses to the notch itself.
    private var earsRow: some View {
        HStack(spacing: 0) {
            // Leading ear: the live state glyph.
            if presentation != .hidden {
                leadingEarContent
                    .padding(.leading, 14)
                    .padding(.trailing, 10)
                    .transition(.opacity)
            }

            // The dead zone spanning the physical notch. Content must never render here — on a
            // notched Mac this is the camera housing. Falls back to a small gap on plain displays.
            Color.clear
                .frame(width: hasPhysicalNotch ? notchWidth : 12, height: earsRowHeight)

            // Trailing ear: the state label.
            if presentation != .hidden {
                trailingEarContent
                    .padding(.leading, 10)
                    .padding(.trailing, 14)
                    .transition(.opacity)
            }
        }
        .frame(height: earsRowHeight)
    }

    // The ears row sits exactly at notch height so the island's top band IS the notch band. A couple
    // of extra points below the cutout gives the compact island its subtle "lip", like iOS.
    private var earsRowHeight: CGFloat {
        presentation == .hidden ? notchHeight : notchHeight + 4
    }

    private var leadingEarContent: some View {
        Group {
            if let cursorGlyphState = appCoordinator.currentCursorGlyphState {
                CursorGlyphView(glyphState: cursorGlyphState, glyphColor: appCoordinator.cursorGlyphColor)
            } else {
                Circle()
                    .fill(appCoordinator.cursorGlyphColor)
                    .frame(width: 7, height: 7)
            }
        }
        .frame(width: 16, height: 16)
    }

    private var trailingEarContent: some View {
        Text(appCoordinator.currentDisplayLabel)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(DS.Colors.primaryText)
            .lineLimit(1)
    }

    // The expanded island's text area, hanging BELOW the notch line so the physical cutout never
    // covers a single glyph of the transcript.
    private func belowNotchTextArea(_ expandedText: String) -> some View {
        Text(expandedText)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(DS.Colors.primaryText)
            .lineLimit(2)
            .truncationMode(.tail)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 380)
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 12)
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Shape

    // One continuous shape for every presentation: square top (flush with the display edge), rounded
    // bottom. The bottom radius deepens as the island grows — subtle when it's the bare notch,
    // pronounced when expanded — which sells the morph as one object changing, not two swapping.
    private var islandShape: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: bottomCornerRadius,
            bottomTrailingRadius: bottomCornerRadius,
            topTrailingRadius: 0,
            style: .continuous
        )
        .fill(islandBlack)
        // The shadow is what separates the black island from a light menu bar. While hidden it must
        // vanish, or it would silhouette the "invisible" island around the real notch.
        .shadow(
            color: Color.black.opacity(presentation == .hidden ? 0 : 0.35),
            radius: 9,
            y: 3
        )
    }

    private var bottomCornerRadius: CGFloat {
        switch presentation {
        case .hidden: return hasPhysicalNotch ? 10 : 0
        case .compact: return 13
        case .expanded: return 22
        }
    }
}
