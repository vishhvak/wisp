# iconiqui.com (Iconiq UI) — inline findings

"Cut the noise. Ship the calm." — shadcn/ui + Motion design system with an MCP install flow.

Most relevant: it ships an **AI-native component vocabulary** that maps 1:1 onto Wisp surfaces:
- **Thinking Indicator** — status dot with `@keyframes status-blink`: 0%/100% {opacity:1, scale:1} → 50% {opacity:0.28, scale:0.82}. (Validates Wisp's idle-dot breathe: 0.55→1.0 opacity, 0.85→1.0 scale — nearly identical proportions; ours is slower/calmer at 1.6s which fits the wisp brand.)
- **Reasoning Steps** — collapsible "Reasoning 10s" accordion (radix accordion-down/up keyframes) — pattern for a future "what did the agent do" disclosure on task cards.
- **Streaming Text**, **Message**, **AI Input** (with voice-input button + model selector "Fable, High") — confirms the emerging standard anatomy for AI inputs: options button · model select · voice · send, exactly the composer row order Wisp uses (attach · input · paperclip · send).
- **Favicon Badge**, **Logo Carousel** — not relevant.

Takeaway for DESIGN.md: no changes required — independent validation of (a) the breathe/status-blink proportions, (b) the composer anatomy, (c) calm-first motion posture. Adopt "Reasoning Steps" disclosure as a future task-card enhancement.
