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
        // A file drag is hovering at the notch — dashed "Drop files here to attach" target.
        case dropTarget
        // Files were dropped — file chips + "ask Wisp…" input + amber send (from the drag demo).
        case composer
    }

    private var presentation: IslandPresentation {
        // The composer interactions outrank the passive state displays.
        if !appCoordinator.composerFileURLs.isEmpty {
            return .composer
        }
        if appCoordinator.isFileDropTargeted {
            return .dropTarget
        }
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
                switch presentation {
                case .expanded:
                    if let expandedText = appCoordinator.notchExpandedText {
                        belowNotchTextArea(expandedText)
                    }
                case .dropTarget:
                    dropTargetArea
                case .composer:
                    composerArea
                case .hidden, .compact:
                    EmptyView()
                }
            }
            .background(islandShape)
            .fixedSize()
            // The whole island is a drop destination, so a drag released anywhere on it attaches.
            .dropDestination(for: URL.self) { droppedFileURLs, _ in
                guard !droppedFileURLs.isEmpty else { return false }
                appCoordinator.attachComposerFiles(droppedFileURLs)
                return true
            } isTargeted: { isDragHovering in
                // Backs up the controller's proximity monitor with exact over-the-island hovering.
                if isDragHovering {
                    appCoordinator.isFileDropTargeted = true
                }
            }
        }
    }

    // The row at notch height: leading ear + a spacer exactly as wide as the sensor housing + the
    // trailing ear. While hidden both ears are empty, so the shape collapses to the notch itself.
    // Ears only render in the compact/expanded state displays; in the drop-target and composer
    // presentations the island's top band is bare black (verified in the drag-demo frames) and the
    // content lives entirely below the notch line.
    private var showsEars: Bool {
        presentation == .compact || presentation == .expanded
    }

    private var earsRow: some View {
        HStack(spacing: 0) {
            // Leading ear: the live state glyph.
            if showsEars {
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
            if showsEars {
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

    // MARK: - Drop target (drag hovering at the notch)

    // The dashed "Drop files here to attach" zone, matching the demo frames: a dashed rounded
    // rectangle with a ghost label, hanging below the notch inside the grown island.
    private var dropTargetArea: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 14, weight: .medium))
            Text("Drop files here to attach")
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundColor(DS.Colors.secondaryText)
        .frame(width: 420, height: 56)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    DS.Colors.secondaryText.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Composer (files dropped — chips + input + send)

    @FocusState private var isComposerFieldFocused: Bool

    private var composerArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            // The attached-file chips row: rounded-square thumbnails with a per-type icon.
            HStack(spacing: 10) {
                ForEach(appCoordinator.composerFileURLs, id: \.self) { attachedFileURL in
                    composerFileChip(for: attachedFileURL)
                }
            }

            // Input row: "ask Wisp…" field, paperclip, and the amber circular send button — the
            // exact anatomy in the drag-demo frames (caret-focused field, 📎, gold ↑ button).
            HStack(spacing: 10) {
                TextField("ask Wisp…", text: $appCoordinator.composerDraftText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DS.Colors.primaryText)
                    .focused($isComposerFieldFocused)
                    .frame(width: 320)
                    .onSubmit {
                        appCoordinator.submitComposer()
                    }

                Image(systemName: "paperclip")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.Colors.secondaryText)

                Button {
                    appCoordinator.submitComposer()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.8))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(DS.Colors.amber))
                }
                .buttonStyle(.plain)
                .pointerCursorOnHover()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 14)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .onAppear {
            // The panel just became key (controller side); direct focus into the field so the user
            // can type immediately after dropping.
            isComposerFieldFocused = true
        }
        .onExitCommand {
            // Escape abandons the composer, collapsing the island back into the notch.
            appCoordinator.cancelComposer()
        }
    }

    // A rounded-square chip for one attached file, its icon chosen by file type (the demo shows
    // per-type document thumbnails: web doc, sheet doc, image doc).
    private func composerFileChip(for fileURL: URL) -> some View {
        VStack(spacing: 2) {
            Image(systemName: chipIconSystemName(for: fileURL.pathExtension.lowercased()))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(DS.Colors.primaryText)
        }
        .frame(width: 48, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
        .help(fileURL.lastPathComponent)
    }

    private func chipIconSystemName(for fileExtension: String) -> String {
        switch fileExtension {
        case "png", "jpg", "jpeg", "gif", "webp", "heic":
            return "photo"
        case "svg":
            return "curlybraces.square"
        case "mp4", "mov":
            return "film"
        case "mp3", "wav", "m4a":
            return "waveform"
        case "srt", "txt", "md":
            return "doc.text"
        case "pdf":
            return "doc.richtext"
        default:
            return "doc"
        }
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
        case .dropTarget, .composer: return 24
        }
    }
}
