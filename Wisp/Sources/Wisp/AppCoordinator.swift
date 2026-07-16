import SwiftUI
import Combine

// The four-state voice/companion state machine, plus an agent-running state for background work.
// These names match the internal state names leaked in the app's own debug console
// (idle / listening / processing / responding), which we deliberately preserve.
enum CompanionState: Equatable {
    case idle
    case listening
    case processing
    case responding
    case agentRunning
}

// The central coordinator. It owns the voice engine, the overlay window, and the task-card store,
// and it holds all the observable state the overlay + menu bar render from. Everything UI-facing is
// @MainActor because it drives SwiftUI.
@MainActor
final class AppCoordinator: ObservableObject {

    // MARK: - Published state

    // The current companion state, driving the menu-bar label, icon, and cursor glyph.
    @Published private(set) var companionState: CompanionState = .idle

    // The active background agent tasks shown as cards in the overlay's top-right stack.
    @Published private(set) var agentTasks: [AgentTask] = []

    // The AI teaching ink currently painted on screen (accumulates through a lesson).
    @Published private(set) var teachingAnnotations: [TeachingAnnotation] = []

    // Where the agent pointer should currently glide to: the anchor of the newest teaching
    // annotation. nil hides the pointer (no active teaching target).
    @Published private(set) var agentPointerTarget: CGPoint?

    // The currently-visible completion toast message, if any.
    @Published private(set) var activeToastMessage: String?

    // The tracked cursor position, in the MAIN screen overlay's top-left-origin space (used by the
    // teaching layers whose coordinates live in that space).
    @Published var cursorGlyphPositionInOverlay: CGPoint = .zero

    // The tracked cursor position in GLOBAL bottom-left-origin screen coordinates. Each per-screen
    // overlay converts this into its own space, so the glyph follows the cursor across monitors.
    @Published var cursorGlobalBottomLeftPoint: CGPoint = .zero

    // The most recent (partial or final) transcript, useful for debugging / a future caption UI.
    @Published private(set) var latestTranscript: String = ""

    // The last spoken response line, shown in the notch HUD while responding.
    @Published private(set) var latestResponseLine: String = ""

    // The text currently shown in the EXPANDED notch HUD, or nil when the HUD should be COLLAPSED.
    // While listening this holds the live partial transcript; while responding it holds the last
    // response line (which then auto-dismisses). nil → the notch shows only its slim collapsed pill.
    @Published private(set) var notchExpandedText: String?

    // How long the notch keeps a response line expanded before collapsing back to the pill. Mirrors
    // the shipped app's `_notchTextResponseAutoDismissDurationSeconds`.
    static let notchTextResponseAutoDismissDurationSeconds: Double = 4.0

    // MARK: - Notch file-drag composer state (verified frame-by-frame from the drag-files demo)

    // True while a file drag is hovering near/over the notch — the island opens into a dashed
    // "Drop files here to attach" target.
    @Published var isFileDropTargeted: Bool = false

    // The files attached to the notch composer. Non-empty → the island presents the composer
    // (file-type chips + an "ask Wisp…" input + amber send button).
    @Published var composerFileURLs: [URL] = []

    // The composer's draft text, bound to its text field.
    @Published var composerDraftText: String = ""

    // Cancellable auto-dismiss for the expanded notch response text.
    private var notchAutoDismissTask: Task<Void, Never>?

    // MARK: - Owned collaborators

    // The voice engine (hotkeys + transcription + TTS). Created lazily so we can pass `self`.
    private(set) lazy var voiceEngine = VoiceEngine(appCoordinator: self)

    // The overlay window controller. Also created lazily so it can hold a reference back to `self`.
    private(set) lazy var overlayController = OverlayController(appCoordinator: self)

    // The notch-anchored HUD controller (top-center pill under the camera notch, or top-center on
    // displays without one). Created lazily so it can hold a reference back to `self`.
    private(set) lazy var notchHUDController = NotchHUDController(appCoordinator: self)

    // The store of agent tasks. Kept as a small dedicated type so task mutations live in one place.
    let taskCardStore = TaskCardStore()

    // The Claude client used for ask/guide responses.
    private let claudeClient = ClaudeClient()

    // The screen-capture utility used to attach screenshots to Claude requests.
    private let screenCapture = ScreenCapture()

    private var storeObservationCancellable: AnyCancellable?

    // MARK: - Presentation maps

    // The user-facing text label for each state, shown in the menu bar. Note this is a presentation
    // map over the state machine — e.g. idle presents as "Always on" (the always-listening idle).
    static let displayLabelForState: [CompanionState: String] = [
        .idle: "Always on",
        .listening: "Listening",
        .processing: "Thinking",
        .responding: "Speaking",
        .agentRunning: "Working"
    ]

    // The text label for the current state, for the menu bar.
    var currentDisplayLabel: String {
        Self.displayLabelForState[companionState] ?? "Always on"
    }

    // The cursor glyph state for the current companion state, or nil when nothing should ride the
    // cursor (idle / agent-running produce no glyph).
    var currentCursorGlyphState: CursorGlyphState? {
        switch companionState {
        case .listening:
            return .listening
        case .processing:
            return .processing
        case .responding:
            return .responding
        case .idle, .agentRunning:
            return nil
        }
    }

    // The configured cursor glyph color (blue by default, user-configurable).
    var cursorGlyphColor: Color {
        WispConfig.cursorGlyphColor
    }

    // The SF Symbol name for the menu-bar icon, reflecting state so the icon fills/highlights on
    // activity (per the demo, the menu-bar mark visibly changes with voice/agent moments).
    var menuBarIconSystemName: String {
        switch companionState {
        case .idle:
            return "cursorarrow.rays"
        case .listening:
            return "waveform"
        case .processing:
            return "circle.dotted"
        case .responding:
            return "speaker.wave.2.fill"
        case .agentRunning:
            return "gearshape.2.fill"
        }
    }

    // MARK: - Lifecycle

    // Starts the app's runtime: brings up the overlay and starts listening for hotkeys.
    func start() {
        // Mirror the task store's tasks into our published array so the overlay re-renders on change.
        storeObservationCancellable = taskCardStore.$tasks
            .receive(on: RunLoop.main)
            .assign(to: \.agentTasks, on: self)

        overlayController.show()
        notchHUDController.show()
        voiceEngine.start()
    }

    // MARK: - State transitions

    func transition(to newState: CompanionState) {
        guard companionState != newState else { return }
        WispLog.log("state", "\(companionState) → \(newState)")
        companionState = newState
    }

    // MARK: - Transcript handling (called by VoiceEngine)

    func handlePartialTranscript(_ partialText: String) {
        latestTranscript = partialText
        // While listening, keep the notch HUD expanded showing the live partial transcript. Cancel
        // any pending response auto-dismiss so a new utterance immediately takes over the notch.
        notchAutoDismissTask?.cancel()
        notchExpandedText = partialText
    }

    // A finalized utterance — hand it to Claude and stream the response back (voice + teaching ink).
    func handleFinalTranscript(_ finalText: String) {
        latestTranscript = finalText
        Task {
            await respondWithScreenContext(finalText)
        }
    }

    // Captures the screen, then runs the shared respond pipeline with those screenshots attached.
    private func respondWithScreenContext(_ userRequestText: String) async {
        transition(to: .processing)

        // Attach a screenshot of every display so Claude can reason about what the user sees.
        let displayCaptures = await screenCapture.captureAllDisplays()
        let imageAttachments: [ChatImageAttachment] = displayCaptures.compactMap { displayCapture in
            guard let pngData = screenCapture.encodeToPNG(displayCapture.capturedImage) else { return nil }
            return ChatImageAttachment(base64EncodedImage: pngData.base64EncodedString(), mediaType: "image/png")
        }

        await respondToUserRequest(userRequestText, imageAttachments: imageAttachments)
    }

    // The shared respond pipeline: asks Claude with the given attachments, streams the answer to
    // TTS, and paints any teaching ink.
    private func respondToUserRequest(_ userRequestText: String, imageAttachments: [ChatImageAttachment]) async {
        transition(to: .processing)

        var accumulatedSpokenText = ""
        do {
            let responseStream = claudeClient.streamResponse(
                userMessageText: userRequestText,
                imageAttachments: imageAttachments
            )
            for try await streamEvent in responseStream {
                switch streamEvent {
                case .textDelta(let textDelta):
                    accumulatedSpokenText += textDelta
                case .teachingAnnotation(let annotation):
                    // Fly the agent pointer to the new annotation FIRST (it draws the eye), then
                    // accumulate the ink so it builds up into a persistent legend.
                    agentPointerTarget = annotation.anchorPoint
                    teachingAnnotations.append(annotation)
                }
            }
        } catch {
            // On any streaming failure, fall back to whatever text we accumulated (possibly empty).
        }

        // Speak the response. The responding state drives the cursor triangle glyph during TTS, and
        // the notch HUD expands to show the first line of the response (auto-dismissing after ~4s).
        transition(to: .responding)
        let firstResponseLine = firstLine(of: accumulatedSpokenText)
        latestResponseLine = firstResponseLine
        showNotchResponseLine(firstResponseLine)
        await voiceEngine.speak(accumulatedSpokenText)

        // Return to the always-on idle state once speech finishes.
        transition(to: .idle)
    }

    // Shows a response line in the expanded notch HUD, then auto-collapses it after the shipped
    // auto-dismiss duration so the notch returns to its slim "Always on" pill.
    private func showNotchResponseLine(_ responseLine: String) {
        guard !responseLine.isEmpty else { return }
        notchExpandedText = responseLine
        notchAutoDismissTask?.cancel()
        notchAutoDismissTask = Task { [weak self] in
            let autoDismissNanoseconds = UInt64(Self.notchTextResponseAutoDismissDurationSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: autoDismissNanoseconds)
            guard !Task.isCancelled else { return }
            self?.notchExpandedText = nil
        }
    }

    // Returns the first non-empty line of a block of text (the notch shows a single line).
    private func firstLine(of text: String) -> String {
        text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? text.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Notch composer (drag files onto the notch → attach → ask)

    // Files dropped onto the island's drop target. Ends the drop-target presentation and opens the
    // composer with the attached files.
    func attachComposerFiles(_ fileURLs: [URL]) {
        isFileDropTargeted = false
        composerFileURLs.append(contentsOf: fileURLs)
    }

    func cancelComposer() {
        isFileDropTargeted = false
        composerFileURLs.removeAll()
        composerDraftText = ""
    }

    // Sends the composer's draft + attachments through the normal respond pipeline. Image files ride
    // along as real Claude image blocks; other file types are named (with paths) in the message so
    // the model knows what it was handed.
    // ponytail: non-image files are referenced by name/path only — inline their text content when a
    // file-reading pipeline lands.
    func submitComposer() {
        let draftText = composerDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachedFileURLs = composerFileURLs
        guard !draftText.isEmpty || !attachedFileURLs.isEmpty else { return }
        cancelComposer()

        Task {
            let imageFileExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp"]
            var imageAttachments: [ChatImageAttachment] = []
            var nonImageFileNames: [String] = []

            for fileURL in attachedFileURLs {
                let fileExtension = fileURL.pathExtension.lowercased()
                if imageFileExtensions.contains(fileExtension),
                   let imageData = try? Data(contentsOf: fileURL) {
                    let mediaType = fileExtension == "png" ? "image/png" : "image/\(fileExtension == "jpg" ? "jpeg" : fileExtension)"
                    imageAttachments.append(
                        ChatImageAttachment(base64EncodedImage: imageData.base64EncodedString(), mediaType: mediaType)
                    )
                } else {
                    nonImageFileNames.append(fileURL.lastPathComponent)
                }
            }

            var messageText = draftText.isEmpty ? "Tell me about the attached files." : draftText
            if !nonImageFileNames.isEmpty {
                messageText += "\n\n(Attached files: \(nonImageFileNames.joined(separator: ", ")))"
            }

            await respondToUserRequest(messageText, imageAttachments: imageAttachments)
        }
    }

    // MARK: - Teaching ink

    // Clears all accumulated teaching ink (e.g. when a lesson ends) and dismisses the pointer.
    func clearTeachingAnnotations() {
        teachingAnnotations.removeAll()
        agentPointerTarget = nil
    }

    // MARK: - Task cards + toast

    // Adds a new agent task card and (per the demo) fires a completion toast when it finishes.
    func presentCompletedTask(title: String, resultSentence: String, suggestedNext: [String]) {
        let completedTask = AgentTask(
            title: title,
            state: .done,
            resultSentence: resultSentence,
            suggestedNext: suggestedNext
        )
        taskCardStore.upsert(completedTask)
        showCompletionToast(resultSentence)
    }

    func showCompletionToast(_ message: String) {
        activeToastMessage = message
    }

    func dismissCompletionToast() {
        activeToastMessage = nil
    }

    // MARK: - Card action handlers (wired from the overlay)

    func handleSuggestedNextAction(for agentTask: AgentTask, actionLabel: String) {
        // A real implementation would route this to the agent runtime; for the scaffold we simply
        // treat the suggested action as a new spoken-style request so the pipeline is exercised.
        handleFinalTranscript(actionLabel)
    }

    func handleTextFollowUp(for agentTask: AgentTask) {
        // Text follow-up would open a small text input bound to this task's thread.
        transition(to: .idle)
    }

    func handleVoiceFollowUp(for agentTask: AgentTask) {
        // Voice follow-up re-opens listening on this task's thread.
        transition(to: .listening)
        voiceEngine.beginListeningSession()
    }
}

// A small store owning the list of agent tasks. Isolated so all task mutations (add / update state)
// live in one place; the coordinator mirrors its `tasks` into its published array.
@MainActor
final class TaskCardStore: ObservableObject {
    @Published private(set) var tasks: [AgentTask] = []

    // Inserts a new task or updates an existing one (matched by id), preserving creation order.
    func upsert(_ task: AgentTask) {
        if let existingIndex = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[existingIndex] = task
        } else {
            tasks.append(task)
        }
    }

    // Updates just the state (and optional result) of an existing task, e.g. running → done.
    func updateState(taskID: UUID, to newState: AgentTaskState, resultSentence: String? = nil) {
        guard let existingIndex = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[existingIndex].state = newState
        if let resultSentence {
            tasks[existingIndex].resultSentence = resultSentence
        }
    }

    func remove(taskID: UUID) {
        tasks.removeAll { $0.id == taskID }
    }
}

// Wraps the voice pipeline: hotkey gestures, transcription (Parakeet sidecar with Apple fallback),
// and TTS playback. It translates raw hotkey gestures into companion-state transitions + listening
// sessions on the coordinator.
@MainActor
final class VoiceEngine {
    private unowned let appCoordinator: AppCoordinator

    private let hotkeyMonitor = HotkeyMonitor()
    private let textToSpeechPlayer = TTSPlayer()

    // The active transcription provider for the current listening session (nil when not listening).
    private var activeTranscriptionProvider: TranscriptionProvider?
    private var activeListeningTask: Task<Void, Never>?

    // True once the current listening session has produced a FINAL transcript (which hands off to
    // the respond pipeline). Used on release: if no final ever arrived, we must return to idle
    // ourselves or the UI sticks on "Listening" forever.
    private var didReceiveFinalTranscriptThisSession = false

    init(appCoordinator: AppCoordinator) {
        self.appCoordinator = appCoordinator
    }

    // Begins monitoring hotkeys and wires each gesture to the appropriate behavior.
    func start() {
        hotkeyMonitor.onHotkeyEvent = { [weak self] hotkeyEvent in
            self?.handleHotkeyEvent(hotkeyEvent)
        }
        hotkeyMonitor.start()
    }

    func stop() {
        hotkeyMonitor.stop()
        endListeningSession()
    }

    // Speaks text via the Worker-proxied TTS, returning once playback starts.
    func speak(_ text: String) async {
        await textToSpeechPlayer.speak(text)
    }

    private func handleHotkeyEvent(_ hotkeyEvent: HotkeyEvent) {
        WispLog.log("hotkeys", "gesture: \(hotkeyEvent)")
        switch hotkeyEvent {
        case .pushToTalkPressed, .dictationPressed:
            appCoordinator.transition(to: .listening)
            beginListeningSession()
        case .pushToTalkReleased, .dictationReleased:
            endListeningSession()
            // If the session never produced a final transcript (no speech, no permissions, no
            // provider), nothing else will move the state machine — return to idle here or the UI
            // sticks on "Listening" forever. A short grace period lets an in-flight final land.
            if !didReceiveFinalTranscriptThisSession {
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard let self else { return }
                    if !self.didReceiveFinalTranscriptThisSession,
                       self.appCoordinator.companionState == .listening {
                        WispLog.log("voice", "release with no final transcript — returning to idle")
                        self.appCoordinator.transition(to: .idle)
                    }
                }
            }
        case .controlDoubleTapped:
            // Text mode — a future text-entry surface; for now just return to idle.
            appCoordinator.transition(to: .idle)
        case .controlTripleTapped:
            // Always-on mode — remain idle/listening ambiently.
            appCoordinator.transition(to: .idle)
        }
    }

    // Starts a transcription session, forwarding partial/final transcripts to the coordinator.
    // Resolves the Parakeet sidecar first, falling back to Apple Speech if it fails to launch.
    func beginListeningSession() {
        // Don't start a second overlapping session.
        guard activeListeningTask == nil else { return }
        didReceiveFinalTranscriptThisSession = false

        let resolvedProvider = resolveTranscriptionProvider()
        activeTranscriptionProvider = resolvedProvider
        WispLog.log("voice", "listening session started (provider: \(type(of: resolvedProvider)))")

        activeListeningTask = Task { [weak self] in
            guard let self else { return }
            var receivedAnyUpdate = false
            for await transcriptUpdate in resolvedProvider.startTranscribing() {
                receivedAnyUpdate = true
                switch transcriptUpdate {
                case .partial(let partialText):
                    self.appCoordinator.handlePartialTranscript(partialText)
                case .final(let finalText):
                    WispLog.log("voice", "final transcript: \"\(finalText.prefix(120))\"")
                    self.didReceiveFinalTranscriptThisSession = true
                    self.appCoordinator.handleFinalTranscript(finalText)
                }
            }
            // The provider's stream finished (utterance ended or provider stopped).
            WispLog.log("voice", "listening session ended (receivedAnyUpdate: \(receivedAnyUpdate))")
            self.activeListeningTask = nil
        }
    }

    func endListeningSession() {
        activeTranscriptionProvider?.stopTranscribing()
        activeTranscriptionProvider = nil
        activeListeningTask?.cancel()
        activeListeningTask = nil
    }

    // Chooses a transcription provider: the local Parakeet sidecar when its script + python3 are
    // actually present, otherwise Apple Speech. (An earlier version consulted a flag the sidecar
    // only sets AFTER a failed launch, so the fallback never engaged — check upfront instead.)
    private func resolveTranscriptionProvider() -> TranscriptionProvider {
        if ParakeetSidecarProvider.isSidecarRunnable() {
            return ParakeetSidecarProvider()
        }
        WispLog.log("voice", "Parakeet sidecar not runnable (script/python3 missing) — using Apple Speech")
        return AppleSpeechProvider()
    }
}
