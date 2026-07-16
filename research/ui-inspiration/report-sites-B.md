# UI research — Batch B: beui.dev, originkit.dev, ux-components.com, component.gallery

Design-system mining for Wisp (notch Dynamic-Island HUD, glowing cursor light-glyphs, dark task
cards, file-drop composer, teaching ink). All values below are copy-pasted from live
`getComputedStyle()` / stylesheet-CSSOM reads via `agent-browser`, not eyeballed from
screenshots, except where explicitly flagged "visual only." Per-site detail files (with more
values, full keyframes, and screenshots) live alongside this file:
`site-beui.md`, `site-originkit.md`, `site-uxcomponents.md`, `site-componentgallery.md`.

---

## Site 1 — beui.dev

Tailwind 4 + React 19 (framer-motion), OKLCH tokens, dark-mode-first. 9 pages investigated:
homepage/tokens, Dynamic Island, Command Palette, Morphing Modal, Button, Tooltip, Bloom Menu,
File Upload, Notification Stack.

**Dark-theme root tokens:**
```
--background: #151515
--card: #1c1c1c
--border: rgba(255,255,255,0.05)
--border-strong: rgba(255,255,255,0.10)
--accent: oklch(80% .18 195)      /* teal, but themeable: only accent hue swaps, bg/card never do */
```
No `--radius`/`--shadow`/`--duration` tokens exist — those are literal Tailwind utilities per
component (captured below).

**Dynamic Island** (`/components/blocks/dynamic-island`) — the single most relevant component on
the site for Wisp's notch HUD:
- `border-radius: 32px` **pinned across every state** — only `width`/`height` animate (spring,
  not CSS transition — literal inline px styles interpolated by JS).
  - Idle: `125.4 × 36.3px` · Call: `193 × 82px` · Music: `165 × 77px`
- Elevation: `shadow-2xl` = `0 25px 50px -12px rgba(0,0,0,.25)` (recurs on every floating surface
  sitewide: modal, command palette, toast dock).
- Content swap on state change = cross-fade via `opacity` + `filter: blur(8px)→blur(0)`,
  `transform-origin: center top` — **not a slide/wipe**.
- Matching stylesheet keyframe (reused for reveals everywhere):
  ```css
  @keyframes beui-circle-blur-reveal {
    0%   { clip-path: circle(0% at var(--beui-vt-origin, 50% 100%)); filter: blur(8px); }
    100% { clip-path: circle(150% at var(--beui-vt-origin, 50% 100%)); filter: blur(0px); }
  }
  ```
  `--beui-vt-origin` is a settable CSS var — anchor the reveal at a click/drop/cursor point.

**Command Palette:** `rounded-2xl` (16px), `bg-card` (`#1c1c1c`), `border 1px rgba(255,255,255,.05)`,
`shadow-2xl`. Selected row = shared-element highlight pill (`layoutId`), `mix-blend-exclusion`
white text, `radius 9999px`, `transition: opacity .15s cubic-bezier(.4,0,.2,1)`. `kbd` shortcut
badge: `border-radius 4px`, `bg #151515`, `border 1px rgba(255,255,255,.05)`, `10px Geist Mono`.
**Backdrop:** `backdrop-filter: blur(12px) saturate(140%)` over `bg-background/5` (≈5% black) —
light scrim, not a heavy dark overlay.

**Morphing Modal:** `rounded-3xl` (24px), `bg #151515` (one step darker than card), same
`shadow-2xl`, backdrop `blur(14px) saturate(140%)` (confirms 12–14px blur + sat(140%) + 5%-black
is the site's standard modal-backdrop recipe). Destructive row: `bg-destructive/10 → hover/15`,
full-saturation red text — quiet, non-shouty delete affordance.

**Button:** every color-ish property (`color/background-color/border-color/outline-color/
text-decoration-color/fill/stroke`) transitions independently at `150ms cubic-bezier(0.4,0,0.2,1)`
— the site's global micro-interaction default, identical on nav links, icon buttons, all variants.

**Tooltip:** `rounded-lg` (8px), `bg #151515`, `border 1px rgba(255,255,255,.05)`,
`shadow-lg = 0 10px 15px -3px rgba(0,0,0,.1), 0 4px 6px -4px rgba(0,0,0,.1)` — a visibly lighter
elevation tier than `shadow-2xl`, giving a free two-tier elevation system (chips/tooltips vs.
islands/modals).

**Bloom Menu:** button morphs into a menu via **iris/circle-reveal from center**, radially
staggered grid items. Same `beui-circle-reveal` / `beui-rect-reveal` keyframe family as the
Dynamic Island reveal.

**File Upload (closest existing pattern to Wisp's composer):** dropzone `rounded-3xl` (24px),
`border 1px dashed rgba(255,255,255,.05)` → **hover: `border-foreground/40`** (brightens to ~40%
white only on hover/drag), `active:scale-[0.99]` press (subtle, no bounce), only `border-color`
and `transform` transition (200ms) — background never changes, so the dropzone stays visually
quiet until interacted with. Outer shell one radius step up (`32px` shell → `24px` inner drop
target) — nested-radius-decreases-toward-center pattern. Progress fill: `h-1.5` (6px) track,
`rounded-full`, emerald fill.

**Notification Stack:** count badge uses a **double inset-shadow** for a glossy/domed look on a
flat-color circle: `inset 0 1px 2px rgba(0,0,0,.2)` (dark, top) + `inset 0 -1px 0 rgba(255,255,255,.16)`
(light, bottom-inverted) — cheapest way to make a flat badge/status-dot read as subtly 3D.

---

## Site 2 — originkit.dev

A **hero-effects/motion library** (canvas/WebGL particle and cursor effects), not a
shadcn-style button/toast kit — flagged honestly rather than guessed at where effects had no
extractable CSS (Electric Border, Axis Cursor, Click Effects are canvas-rendered with zero
matching `box-shadow`/`filter` in the DOM).

**Color tokens** (4-step dark elevation ramp + one accent, confirmed via Tailwind arbitrary-value
class dump, i.e. real tokens not one-off hex):
```
surface:  #151414   elevated: #242424
bg:       #1E1E1F   field:    #414143
accent:   #FA7319   accent-soft: #FF8A3D
command-palette bg: #0F0F0F (near-black, darkest surface on the site)
```

**Radius:** global `--border-radius: 8px`, but the actual chrome is deliberately flat —
command palette `border-radius: 0px`, homepage grid cards `border-radius: 0px`, walked 8
ancestor levels up from a card thumbnail and every one has `border-radius:0 / border:0 /
box-shadow:none`. 6–8px radius reserved for small chips only. **Proof that "dark UI ≠
automatically rounded"** — worth a deliberate choice for Wisp rather than a rounded-2xl default.

**Motion:** one easing curve reused at three durations:
```
cubic-bezier(0.16, 1, 0.3, 1)   /* "expo-out" — fast launch, no overshoot, gentle settle */
150ms  → hover feedback (grid-card slide)
220ms  → general UI (search-trigger hover)
420ms  → content swap (before/after image slider)
```

**Shadows:** the standout is an **inset top-edge highlight** for a glossy bevel on dark surfaces:
```css
box-shadow: 0 8px 24px rgba(0,0,0,.45), inset 0 4px 4px rgba(255,255,255,.1);
```
Full Tailwind arbitrary-shadow set also captured: `0 8px 24px rgba(0,0,0,.45)` (elevated card),
`0 12px 32px rgba(0,0,0,.45)` (modal), `0 8px 30px rgba(0,0,0,.5)` (max), `4px 0 24px rgba(0,0,0,.35)`
(directional/side-panel).

**Search/command palette** (cmdk-based): `bg #0F0F0F`, `border 1px #333`, `border-radius: 0`,
`box-shadow: none`, `backdrop-filter: none`, monospace font, `480×383px`. A flat, near-black,
no-blur, no-glow, terminal-style overlay — a strong alternative to the usual soft glassy panel if
Wisp's HUD wants an "OS-native, no-nonsense" feel.

**Shiny Pill — exact copy-pasteable text-shine sweep:**
```css
mask-image: linear-gradient(to right, transparent 30%, black 50%, transparent 70%);
mask-size: 150%; mask-repeat: repeat;
animation: shinyPillSweep 1.5s ease-in-out infinite;
@keyframes shinyPillSweep { 0% { mask-position: 200% center; } 100% { mask-position: -100% center; } }
```
A `mask-position` sweep, not background-clip gradient text — GPU-cheap. Exact fit for a
"Listening…" status label: signals liveness without a spinner.

**Draggable Sticker — 3D tilt recipe (verbatim inline styles):**
```css
position: absolute; perspective: 800px; transform-style: preserve-3d;
will-change: transform; cursor: grab;
```
Exposed tunables: Tilt 45, Strength 10, Elevation 10. Directly the recipe for Wisp's file-drop
composer: wrap each dropped-file card in a `perspective` parent, animate `rotateX/rotateY` off
drag delta, `cursor: grab → grabbing`.

**Fade-out scroll mask** (bottom-edge content fade in scrollable lists): `65px`-tall absolute
overlay, `linear-gradient(transparent, <bg-color>)`, `pointer-events: none` — cheap alternative to
`mask-image` for a scrollable task list inside the HUD (works both edges by flipping direction).

**Electric Border / cursor effects — honest non-finding:** zero CSS `filter`/`box-shadow`/`glow`
selectors sitewide (`grep`'d the full stylesheet for `glow|radial|neon` — zero matches). These are
100% canvas per-frame draws (additive-blend soft circles/particles), confirming that a real
glowing cursor light-glyph in Wisp needs either an SVG filter chain
(`feTurbulence → feDisplacementMap → feGaussianBlur`) or actual canvas/Metal rendering — not a
CSS `box-shadow` blur, which reads flatter than the real effect.

---

## Site 3 — ux-components.com

**Caveat, confirmed across ~8 fresh navigations:** the site does not stay put. Within 5–30s
(sometimes before first paint) client-side JS bounces the top-level tab through a webring:
`ux-components.com → namethatui.com (Cloudflare-gated) → transitions.dev → originkit.dev
→ (repeats)`. The one stable artifact pulled directly from ux-components.com itself is its
`/components` glossary page (categories: Action, Content, Data Display, Disclosure, Feedback,
Form, Layout, Navigation, Overlay — each entry linking to external live demos). Given the
redirect, this report extracts real values from the two domains it consistently landed on:
**transitions.dev** (rich, extractable token system) and **originkit.dev** (cross-referenced
against Site 2 above, consistent readings).

**transitions.dev design tokens** (dark theme, `html[data-theme="dark"]`):
```css
/* Motion primitives */
--duration-stagger: 40ms;   --duration-micro: 80ms;    --duration-quick: 150ms;
--duration-fast: 250ms;     --duration-medium: 350ms;  --duration-slow: 400ms;
--duration-very-slow: 500ms;
--ease-smooth-out: cubic-bezier(0.22, 1, 0.36, 1);   /* workhorse ease, used everywhere */
--ease-bounce: cubic-bezier(0.34, 1.36, 0.64, 1);
--ease-bounce-strong: cubic-bezier(0.34, 3.85, 0.64, 1);

/* Distance/scale/blur scale */
--distance-micro:4px  --distance-small:6px  --distance-base:8px  --distance-medium:12px  --distance-large:30px;
--scale-large:0.96  --scale-medium:0.97  --scale-small:0.98  --scale-tiny:0.99;   /* closed states never shrink past 0.96 */
--blur-small:2px  --blur-medium:3px  --blur-large:8px;

/* Dark surfaces */
--bg:#121212  --card-bg:#181818  --stage-bg:#131313 (darker than card)
--chip-bg: rgba(255,255,255,.07) → hover .1 → pressed .08
--material-shadow:
  0 1px 3px 0 rgba(0,0,0,.04),
  inset 0 1px 0 0 rgba(255,255,255,.04),
  inset 0 0 0 1px rgba(0,0,0,.06),
  inset 0 -1px 0 0 rgba(0,0,0,.06),
  inset 0 0 0 1px rgba(196,196,196,.08);

/* Accent */
--accent:#55cfff (cool light-blue — good glow-cursor candidate)  --accent-hover:#74d8ff
--accent-soft: rgba(85,207,255,.12)
```

**Per-component computed styles** (dark theme, live DOM; the site labels demos `p1…p27`):

| Component | Radius | Background | Notes |
|---|---|---|---|
| Task card (`.card`) | 24px | `#181818` | `--material-shadow`; only `box-shadow`/`background-color` transition |
| Notification badge (`.p1-bell`) | 40px | `#181818` | inner pip uses **sub-pixel** shadow offsets (`0.338px` etc.) — scaled-down 1px badge, literal number worth stealing for a status dot |
| Modal (`.p8-modal`) | 12px | `#181818` | reuses `--material-shadow`; **open 400ms / close 350ms** — asymmetric |
| Tooltip (`.p17-tooltip`) | 10px | `#222222` (one step lighter than card) | `opacity/transform 0.05s ease-out` — deliberately near-instant, snappier than cards/modals |
| Dropdown morph (`.p20-morph`) | 40px→animated | `#181818` | animates `width/height/border-radius` together, **never `transform:scale`** — pill button morphs into a menu surface; open 250ms/close 150ms, `cubic-bezier(.22,1,.36,1)` |
| Toast (`.p22-toast`) | 52px | `#181818` | enters from below (`translateY(+16px)`), `scale(.97→1)`, `blur(2px→0)`, 250ms, same ease — "rises in with fade, blur and scale" |
| Search input (`.p13-search`) | 48px | `#1c1c1c` | focus-ring is an **inset** white ring escalating `.055 → .07 (hover) → .15 (focus)`, never an outer glow |

**Asymmetric open/close as a house rule across the whole site**: entrances read slower than
exits — dropdown 250/150ms, panel 400/350ms, Pro card-stack spring 410/360ms. Roughly
open ≈ 1.4–1.7× close, applied globally, not per-component.

**Pro-tier spring/glow tokens** (still readable as `:root` custom properties even though the
implementations are paywalled):
```css
--pro2-open-ease: cubic-bezier(0.31, 1.84, 0.64, 1);  /* card-stack hover, genuinely bouncy overshoot-then-settle */
--pro3-glow-blur: 20px; --pro3-glow-strength: 0.7;    /* closest literal "glow token" on the site */
```

**originkit.dev cross-check** (Electric Border control-panel defaults, read off the live UI):
```
Line Color: #FFFFFF   Glow Color: #FFFFFF   Background: #000000
Speed:1  Chaos:4  Line Thickness:3.5  Radius:0  Glow Intensity:10
```
Confirms the glow is architected as an **independent layer/parameter** (separate stroke color,
glow color, glow intensity, chaos/jitter) rather than baked into one CSS shadow — the right
architecture to copy for Wisp's cursor light-glyph, whatever the render tech.

---

## Site 4 — component.gallery

A **naming/anatomy taxonomy encyclopedia** (Iain Bean; aggregates 95 real design systems —
Atlassian, Salesforce Lightning, Shopify Polaris, Material, Ant Design, shadcn/ui, etc. — across
60 flat, alphabetical component categories, 2,671 real examples, **no category grouping**). Not a
CSS-mining target — the deliverable here is canonical names + synonym sets + documented anatomy.

**Toast:** canonical `Toast` (site's synonym: Snackbar). Full synonym set across 41 linked
systems: Snackbar, Floating notification, Toaster, Sonner (shadcn's brand name), Flag (Visa's
oddball name). No written anatomy spec — inferred pattern: icon/status slot → title → description
→ optional action → dismiss (×) → auto-dismiss timer. Related-components link groups it under
Alert's family: **Alert = persistent-in-flow, Toast = transient-and-floating**.

**Badge / status dot:** canonical `Badge` (synonyms: Tag, Label, Chip). Richest synonym list on
the whole site (123 linked systems) — notably **"Status Indicator," "Status Badge," "Signal,"
"Circle badge," "Bullet Badge"** are all real names used by shipped design systems; no system
splits "status dot" into its own taxonomy — every one folds it into Badge/Tag with a
status-flavored name. Anatomy = definition itself: lives inside/adjacent to a larger component
(never standalone) + short label/count/bare-color-dot content + color/shape *is* the message.

**Popover vs. Tooltip** — the **only page on the entire site with a real hand-written anatomy
spec** (Popover):
```html
<button type="button" aria-expanded="false" aria-controls="popover" aria-haspopup="dialog">
  Expand Popover
</button>
<div id="popover" role="dialog" hidden>
  <button type="button">Close popover</button>
  <header>This is the popover title</header>
  <p>This is the popover body</p>
</div>
```
Documented parts: **Trigger** (button + `aria-expanded`/`aria-controls`/`aria-haspopup`) →
**Container** (`role=dialog`, toggled via `hidden`) → **Close control** → **Header** → **Body**.
Interaction rules: opens on click/Enter/Space; closes on Esc/close-button/outside-click; Esc
returns focus to trigger; closed content must be `inert`/`aria-hidden`, not just visually hidden.
**Popover vs. Tooltip split, the real anatomical delta:** Tooltip = hover-triggered,
non-interactive, text-only. Popover = click-triggered, can contain real controls. A toggletip is
the explicit hybrid (tooltip look, click-triggered, for touch/keyboard reachability).

**Command palette** has **no dedicated entry anywhere on the site.** Structurally it's a
**Combobox** (canonical def: "an input that behaves like a select, with a free-text filter" —
synonyms: Autocomplete, Typeahead, Picklist) whose option list renders as a **Dropdown menu**
(canonical def: "options hidden by default, shown via a button; shows actions/navigation, is
**not** a form input" — vs. Select, which is a form input). One linked resource is literally
titled "Stop Using 'Drop-down'" — a naming-hygiene note (don't call a filterable combobox a
"dropdown"; a plain dropdown has no free-text filter).

**Progress family — a clean 2×2 worth adopting wholesale:**
| | Continuous | Discrete |
|---|---|---|
| **Generic/blocking** | Progress bar (track+fill+%, "updated continuously, not in discrete steps") | Progress indicator / Stepper (step nodes: done/current/upcoming + connector line) |
| **Content-shaped** | *(n/a)* | Skeleton ("placeholder layout... usually grey boxes," non-blocking) |
| **Indeterminate/blocking-only** | Spinner ("process happening, interface not yet ready for interaction" — its own component, not a bar-with-no-%) | |

**Site's own visual details** (dark theme, computed): `--color-bg-primary:#343232`,
`--color-bg-highlight:#1f1d1d`, body font Instrument Sans 16px, nav links **20px uppercase,
letter-spacing:0.5px** (all the nav's personality, no color/weight change needed). Card border
trick: `box-shadow: rgb(139,136,133) 0 0 0 1px` — a **0-blur box-shadow ring standing in for a
`border` property**, composites more predictably with hover-added shadow layers later.

**Naming conventions Wisp should adopt:**
1. Ship a "canonical name + Also known as" line on every Wisp component doc (costs one line, kills
   "wait, is this the same as X" confusion).
2. Split HUD progress affordances by the 2×2 above — a continuous waveform/amplitude indicator is
   NOT the same component as a discrete transcribe→think→speak stepper; don't reuse one for both.
3. Name the notch's colored glow **"Status Indicator" or "Signal,"** not "dot" (too
   implementation-specific) — reserve "Badge" for an actual labeled/counted chip.
4. Enforce Popover-vs-Tooltip discipline: Wisp's file-drop composer is click-triggered and
   contains a real interactive drop target → it's a **Popover**, must follow the Esc/outside-click/
   focus-return/`inert` contract, not a Tooltip.
5. Name Wisp's quick-command surface **Combobox + Dropdown menu of actions**, documented under one
   entry tagged "Also known as: Command palette, Quick search" — no external taxonomy owns the
   compound term either.
6. Keep Wisp's own component index a **flat, alphabetical, synonym-tagged list**, not a category
   hierarchy — component.gallery has zero grouping and it scales fine for exactly this reason.

---

## Top 10 stealable patterns for Wisp (exact values)

1. **Dynamic Island morph mechanics (beui.dev):** fixed `border-radius: 32px` across every size
   state; only `width`/`height` spring-animate; inner content cross-fades via `opacity` +
   `filter: blur(8px)→blur(0)`, `transform-origin: center top` — never a slide. This is the literal
   recipe for the notch HUD's idle→expanded state transitions.

2. **Circle-reveal keyframe anchored at a CSS-variable origin (beui.dev), copy-pasteable:**
   ```css
   @keyframes beui-circle-blur-reveal {
     0%   { clip-path: circle(0% at var(--beui-vt-origin, 50% 100%)); filter: blur(8px); }
     100% { clip-path: circle(150% at var(--beui-vt-origin, 50% 100%)); filter: blur(0px); }
   }
   ```
   Set `--beui-vt-origin` to the cursor/drop coordinates — the exact mechanism for "the notch
   reveals from the light-glyph cursor point."

3. **Two-tier elevation shadow system (beui.dev):** `shadow-2xl = 0 25px 50px -12px rgba(0,0,0,.25)`
   for anything floating over the desktop (island, composer, modal); `shadow-lg = 0 10px 15px -3px
   rgba(0,0,0,.1), 0 4px 6px -4px rgba(0,0,0,.1)` for small chips/tooltips.

4. **Dark task-card shadow recipe (transitions.dev `--material-shadow`):**
   ```css
   background:#181818; border-radius:24px;
   box-shadow: 0 1px 3px 0 rgba(0,0,0,.04),
     inset 0 1px 0 0 rgba(255,255,255,.04),
     inset 0 0 0 1px rgba(0,0,0,.06),
     inset 0 -1px 0 0 rgba(0,0,0,.06),
     inset 0 0 0 1px rgba(196,196,196,.08);
   ```
   One outer soft shadow + 3 stacked inset rings (top highlight, all-around hairline, bottom
   inset) = a subtle top-lit glass bevel, directly usable unmodified.

5. **Dropdown "shape-morph" mechanic (transitions.dev):** animate `width`, `height`, and
   `border-radius` together (never `transform:scale`) so a pill button becomes a full menu
   surface — `250ms cubic-bezier(.22,1,.36,1)` open, `150ms` close, pre-scale `.97→1`. The correct
   primitive for a notch expanding into a full Dynamic Island, as an alternative/complement to
   pattern #1.

6. **Restrained modal backdrop (beui.dev, confirmed 2×):** `backdrop-filter: blur(12–14px)
   saturate(140%)` over a **5%-opacity black scrim** (`bg-background/5`) — not a heavy 50%+ dark
   overlay. Keeps desktop content legible-but-receded behind the composer.

7. **File-drop composer treatment (beui.dev):** dashed `1px rgba(255,255,255,.05)` border
   brightening to `border-foreground/40` only on hover/drag-over; `active:scale-[0.99]` press (no
   bounce); only `border-color`+`transform` transition at 200ms, background stays static — quiet
   until relevant. Pair with originkit's 3D tilt recipe for the dropped-file cards:
   `perspective: 800px` (parent) + `transform-style: preserve-3d; will-change: transform;
   cursor: grab` (card), `rotateX/rotateY` driven by drag delta.

8. **Shiny-pill text-shine sweep (originkit.dev), exact and copy-pasteable:**
   ```css
   mask-image: linear-gradient(to right, transparent 30%, black 50%, transparent 70%);
   mask-size: 150%; mask-repeat: repeat;
   animation: sweep 1.5s ease-in-out infinite;  /* mask-position: 200% center → -100% center */
   ```
   Use for a "Listening…"/"Thinking…" status label in the notch — signals liveness without a
   spinner, GPU-cheap.

9. **Glow as an independent layer, not a baked-in shadow (originkit Electric Border +
   transitions.dev Pro shimmer):** expose stroke/line color, glow color, and glow blur/intensity as
   separate tunables (`--pro3-glow-blur:20px; --pro3-glow-strength:.7` is a good starting point,
   defaults `#FFFFFF`/`#FFFFFF`/intensity `10` on originkit). For a native glowing cursor
   light-glyph, this maps to layering several blurred, low-opacity circles at decreasing radii /
   increasing opacity (an additive bloom stack) — confirmed via originkit's own canvas
   implementation, not a single CSS blur.

10. **Global micro-interaction curve + asymmetric open/close timing, adopted as a house rule:**
    `150ms cubic-bezier(0.4,0,0.2,1)` for every hover/press color change (beui.dev's global
    default across buttons/rows/icons); **entrances ~1.4–1.7× slower than exits**
    (transitions.dev: dropdown 250/150ms, panel 400/350ms, toast/modal follow the same ratio).
    Apply both as Wisp's baseline motion contract before inventing per-component timings.

**Naming bonus (component.gallery):** ship a "canonical name + Also known as" line on every Wisp
component doc; name the notch's status glow "Status Indicator/Signal" not "dot"; name the
quick-command surface "Combobox + Dropdown menu of actions (aka Command palette)"; keep the
component index a flat alphabetical list, no category buckets.
