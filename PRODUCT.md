# Product

## Register

product

## Platform

ios

*(macOS native — SwiftUI menu-bar app; `ios` is the nearest allowed value and correctly selects the HIG rulebook. The `workspace/` HTML documentation surface is secondary and web.)*

## Users

Mac users — consumers first, not developers — who want an AI companion woven into
whatever they're already doing: writing an email, learning FL Studio, cleaning a
desktop, building something. Their context is "mid-task in someone else's app";
Wisp must never demand a context switch to its own window. Zero setup tolerance:
they will not configure API keys or read docs before first value.

## Product Purpose

Wisp is a little light that lives on your Mac: it sits beside your cursor, sees
your screen, and you talk to it. It answers out loud and draws directly on your
screen to teach; it takes background tasks and reports back on small cards; it
takes dictation that understands what app you're in. Success: the user talks to
it like a companion, not an app — daily voice sessions, teaching moments that
land, tasks delegated without opening a window.

## Positioning

The simplest interface in the world to talk to AI: no window, no chat box — a
presence that lives where your attention already is (your cursor, your notch,
your screen).

## Brand Personality

Luminous, calm, alive. A will-o'-the-wisp: a small glowing guide, not a robot
assistant. It behaves like light — it breathes, drifts, contracts to listen,
ripples to speak. Never loud, never cute-for-cute's-sake, never corporate. The
interface whispers; the capability is what shouts.

## Anti-references

- A chat window docked to the side (Copilot-style panels) — Wisp has no window.
- Terminal/developer aesthetics — no monospace-everything, no matrix glow.
- SaaS dashboard chrome — no sidebars, headers, or settings sprawl on screen.
- Mascot cuteness (animated eyes, bouncing blobs) — presence through light, not
  through a face.
- Siri/Spotlight glassmorphism as default — glass only where it earns its blur.

## Design Principles

1. **Presence over surface.** Wisp is ambient. Every pixel it claims must be
   earned; the resting state is a 7pt dot and a bare notch.
2. **Light is the language.** State is communicated by how light behaves
   (breathe, contract, orbit, radiate, glide) — one coherent physics, no
   disconnected icons.
3. **The hardware is the frame.** The notch island must read as the Mac itself
   expanding — flush black, spring morphs — never as a floating widget.
4. **Motion conveys state, nothing else.** 150–250ms; interruptible; reduced
   motion always has a distinct static form.
5. **Never steal focus.** The user's app stays frontmost through every Wisp
   interaction — panels are non-activating, clicks pass through, work happens
   in the background.

## Accessibility & Inclusion

Reduce Motion honored everywhere with distinct static state forms (already a
hard rule in the codebase). Color-state signals always pair with a second
channel (label text, shape). Voice-first product ⇒ every voice affordance has a
visible text equivalent (notch transcript, log). Contrast: white-on-charcoal
surfaces stay ≥4.5:1; muted text no dimmer than 62% white on #17161F.
