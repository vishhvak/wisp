# DESIGN.md — the Wisp design system

The visual and motion system for Wisp's two surfaces: the **native macOS app**
(notch island, cursor glyphs, task cards, composer, teaching ink) and the
**HTML workspace**. Strategy lives in [PRODUCT.md](PRODUCT.md); the
reverse-engineering evidence behind these choices lives in
[research/DESIGN.md](research/DESIGN.md). This file is the contract every
surface follows.

Scene sentence: *a Mac user at night, mid-task in someone else's app, with a
small warm point of light keeping them company at the edge of attention.*
Dark-first is forced: Wisp's surfaces live against the black notch and float
over other apps — light chrome would read as a sticker; darkness reads as
hardware.

---

## 1. Color

OKLCH is canonical; hex is the Swift rendering value. The palette is four hue
families with jobs, on violet-tinted near-blacks. Restrained strategy: the
accent appears only as state, glow, and action — never decoration.

### Neutrals (the night)

| Token | OKLCH | Hex | Job |
|---|---|---|---|
| `island` | `oklch(0 0 0)` | `#000000` | The notch island ONLY — pure black, flush with the cutout. Never used elsewhere. |
| `surface` | `oklch(0.206 0.018 289.8)` | `#17161F` | Cards, composer, HUD panels. Violet-biased near-black (hue ≈ brand). |
| `surfaceWash` | white / 0.03 | — | Header washes inside dark surfaces. |
| `hairline` | white / 0.08 | — | 1px inner borders on dark surfaces (the one sanctioned border). |
| `pillFill` | white / 0.10 | — | Resting fill of action pills. |
| `pillFillHover` | white / 0.16 | — | Hover fill of action pills. |
| `textPrimary` | white | — | Primary copy on dark. |
| `textSecondary` | white / 0.62 | — | Secondary copy. Floor — never dimmer for running text. |
| `textLabel` | white / 0.42 | — | Section micro-labels only (3–14 chars, never sentences). |

### State families (hue = meaning)

| Family | Token | OKLCH | Hex | Job |
|---|---|---|---|---|
| Violet (brand/night) | `brand` | `oklch(0.597 0.226 286.5)` | `#7C5CFC` | Brand mark, workspace accent. |
| Blue (live) | `listening` | `oklch(0.617 0.189 265)` | `#4C7CF5` | Glyph default, listening/running state, live activity. |
| Blue (live) | `toast` | `oklch(0.574 0.202 262)` | `#2F6FED` | Completion toast fill. |
| Red (ink) | `teachInk` | `oklch(0.654 0.232 28.7)` | `#FF3B30` | AI teaching ink — the ONLY color that draws on the user's screen content. |
| Red (ink) | `askCoral` | `oklch(0.696 0.142 27.5)` | `#E8776B` | User "tell me about this" stroke (same hue family as ink, softer). |
| Green (confirm) | `done` | `oklch(0.730 0.194 147.4)` | `#34C759` | Done pills, success dots. |
| Green (confirm) | `buildMint` | `oklch(0.755 0.150 160.1)` | `#3ECC8E` | User "build this" stroke. |
| Amber (attention) | `amber` | `oklch(0.754 0.135 75.8)` | `#E0A23D` | Composer send button, queued state, permission warnings. |

Rules:
- A state color never appears at full saturation on an inactive element.
- Every color signal pairs with a second channel (label, shape, position).
- Contrast floors: white on `surface` = 15.9:1 ✓; `textSecondary` on `surface`
  ≈ 8:1 ✓; never dim running text below 0.62 alpha. Amber/green/blue fills get
  near-black glyphs (`black/0.8`), not white.
- Glow = the element's own color as layered shadows (two stacked, tighter one
  stronger: `α .85 r3` + `α .4 r6`) — never a generic white or black glow on
  light elements. Black shadows are reserved for *surfaces* (cards, island).

## 2. Typography

One family: **SF Pro** (system). HUD/island/glyph-adjacent text uses the
**rounded** design (`.rounded`) — softness matches the light language; cards
and workspace body use the default cut. No display fonts anywhere (product
register).

Fixed scale, ratio ≈1.2, rem-equivalent pt on native:

| Step | pt | Weight | Use |
|---|---|---|---|
| `micro` | 10 | semibold, +0.10em tracking, UPPERCASE | Section labels ("SUGGESTED NEXT") |
| `caption` | 11 | medium | Card metadata, timestamps |
| `label` | 12 | semibold | Pills, state labels, menu rows |
| `body` | 13 | medium | Card sentences, notch transcript, composer input |
| `title` | 15 | bold | Panel headers ("Wisp") |

- Live-updating numbers **always** get `.monospacedDigit()` (SwiftUI) /
  `font-variant-numeric: tabular-nums` (workspace). No exceptions — a
  wobbling pill next to deliberate liquid motion reads as broken.
- Card titles render UPPERCASE via presentation (small-caps style), stored in
  natural case.
- Workspace: line-height 1.6 body / 1.15 headings, `text-wrap: balance` on
  headings, body measure ≤ 68ch (already in place).

## 3. Surfaces

### Radius — concentric rule

`outerRadius = innerRadius + gap`, always. Nested same-radius is the #1 tell.

| Token | Value | Use |
|---|---|---|
| `chip` | 6 | Teaching chip labels |
| `field` | 10 | Composer input field-shape, drop-zone dash rect (12 − 2pt inset ≈ 10) |
| `toast` | 14 | Completion toast |
| `card` | 18 | Task cards (pills inside are capsules — exempt as full-round) |
| `islandCompact` | 13 | Island bottom corners, compact |
| `islandExpanded` | 22–24 | Island bottom corners, expanded/composer (deeper as it grows) |
| `pill` | capsule | All action pills, state pills |

Cards top out at 18 — nothing rectangular ever exceeds 24 (over-rounding ban).

### Elevation — shadows, not borders

- Dark surfaces: `hairline` (white/0.08) inner stroke + ONE soft black shadow
  (`black/0.35, r9, y3`). Never a wide shadow + border pair on small elements.
- The island while hidden has **zero** shadow (it must vanish into the notch);
  shadow fades in with presentation, keyed to state.
- Light-emitting elements (dot, glyphs, spark) use color-matched glow stacks,
  see Color rules. The glow IS the elevation for light elements.

### Materials — the Liquid Glass discipline

Translucency and glow belong to the **floating control layer only** (island,
pills, buttons, the glyph); **content is always opaque and full-contrast**
(transcript text, card bodies, workspace panes). The moment frost spreads onto
content, premium becomes generic glassmorphism. When translucency is used,
prefer the platform primitive (`NSVisualEffectView` material + vibrancy) over
hand-rolled blur+opacity. Blur otherwise appears only inside the gooey-blend
metaball pass (The Drip).

### Naming (spec surfaces by their real names)

Notch HUD = **Panel** (NSPanel, `.nonactivatingPanel`, floating — the
Spotlight-surface pattern). Status text = **Pill** (capsule, short status —
never "badge" [counts] or "chip" [removable tokens]). **Toast** = role=status,
corner-stacked, and its dismiss timer pauses while hovered.

## 4. Motion

Product register discipline: motion conveys state — 150–250ms for
interactions; 500ms is reserved for the island's shape morphs; nothing else is
choreographed. All motion interruptible; Reduce Motion always renders a
distinct static form (never just "no animation").

### Tokens (SwiftUI-native)

| Token | Value | Derived from | Use |
|---|---|---|---|
| `Motion.exitFast` | `.easeIn(duration: 0.15)` | copy-swap exits | Anything leaving (exits are faster + softer than enters) |
| `Motion.enter` | `.easeOut(duration: 0.20)` | product register | Standard state/feedback enters |
| `Motion.swap` | `.easeInOut(duration: 0.24)` | content-swap recipe | Crossfading content inside a morphing container (incoming delayed 0.08s behind outgoing) |
| `Motion.islandMorph` | `.spring(duration: 0.5, bounce: 0.16)` | island shape-morph | Island width/height/radius morphs — geometry ONLY, one spring for all three |
| `Motion.snappy` | `.spring(response: 0.30, dampingFraction: 0.9)` | magnet spring {320,34,0.7} | Pointer flights ≤ short hops, pill layout shifts |
| `Motion.pressDown` | `.easeOut(duration: 0.10)` | — | Scale to 0.96 on press |
| `Motion.pressUp` | `.spring(response: 0.30, dampingFraction: 0.65)` | — | Release back to 1.0 |
| `Motion.shake` | `.spring(response: 0.24, dampingFraction: 0.17)` | error spring {700,9} | Invalid input: offset 6pt → 0 |
| `Motion.breathe` | `.easeInOut(1.6).repeatForever` | idle dot | Idle luminosity cycle |
| `Motion.glide` | `.easeInOut(duration: 0.55)` | bezier pointer | Agent pointer bezier flights |

### Rules

1. **One gooey primitive.** All liquid moments (island drip, future
   island↔card fusion) share a single metaball-blend implementation
   parameterized by anchor→target distance. The read is topology (continuous
   curvature, concave pinch) — no refraction, no glass shader.
2. **Morph-then-content.** Container geometry animates on `islandMorph`;
   content crossfades on `swap` with incoming delayed 0.08s. Never animate
   text properties with the geometry spring. Inside the ISLAND specifically:
   content exits in ~80ms flat (no blur, no travel — "sucked into the pill"
   before the shell morphs) and enters as a soft top-anchored unfurl
   (opacity + slight scale + small downward settle) — the reference-island
   asymmetry.
3. **Enter ≠ exit.** Exits are shorter (0.15s), ease-in, scale toward 0.96 +
   slight blur; enters are 0.20s ease-out. Never symmetric — entrances run
   ~1.4× slower than exits (a rule independently observed across the studied
   motion systems).
4. **Press feedback** on every interactive element: scale 0.96 (exactly — no
   deeper), `pressDown`/`pressUp` pair.
5. **No layout-property animation** where a transform can do it (SwiftUI:
   prefer `scaleEffect`/`offset` over frame animation except the island morph,
   which is the deliberate exception).
6. **Stagger** only within one revealed list: 40ms base + 30ms/item.

### Signature moves (the brand in motion)

- **The Drip** (session start): the wisp-dot extrudes from the island's bottom
  edge — ~250ms neck stretch toward the cursor → 1–2 frame pinch-off → the
  freed droplet IS the cursor glyph. Session end reverses it. (Listening keeps
  an unbroken tether: strain without separation.)
- **Breathe / Contract / Orbit / Radiate**: idle dot breathes (1.6s); a ring
  contracts inward to listen; a spark orbits to think; ripples radiate to
  speak. One physics: light absorbing, circling, emitting. (Planned glow
  upgrade: true bloom — multi-radius blur composited back — with a subtle
  warm/cool chromatic split that leans toward the cursor, replacing flat
  shadow glow. The brand mark's north star: a four-point starburst in a soft
  radial halo.)
- **Bezier glide + ring-ripple + idle-hide (1.5s)**: the agent pointer's
  motion contract for teaching.
- **Accumulating legend**: teaching chips never replace, they stack.

## 5. Components (anatomy contracts)

- **Island**: pure black, flush to the cutout; hidden = exactly notch-shaped,
  zero shadow. Presentations: hidden → compact (glyph ear left, label ear
  right, +4pt lip) → expanded (text hangs BELOW the notch line) → dropTarget
  (dashed `field` rect + ghost label) → composer (file chips 48pt/r11, input,
  paperclip, amber send circle 26pt with black/0.8 arrow). Bottom radius
  deepens 10→13→22–24 with growth.
- **Cursor companion**: 7pt idle dot (breathing glow) → 20pt state glyphs
  (contract/orbit/radiate) sharing the same core dot. Color =
  user-configurable glyph color, default `listening`.
- **Task card**: 320pt max, `card` radius, `surface` + hairline + one shadow.
  Anatomy: micro-label title + state pill → body sentence → SUGGESTED NEXT
  pills → FOLLOW UP Text/Voice pills. Newest on top, top-right. Pills:
  capsule, `pillFill`, hover `pillFillHover` + pointer cursor, press 0.96,
  ≥40pt hit area (pad hit shape beyond visual).
- **Toast**: `toast` blue fill, white text, tail toward menu bar, enters
  `enter`, auto-dismisses 4s, exits `exitFast`.
- **Teaching ink**: `teachInk` red only; stroked shapes 4–6pt + pixel dots +
  white-on-red chips (r6) that accumulate; draw-on via trim ~0.4s; user
  strokes are translucent marker (coral=ask, mint=build) that fade on release.
- **Menu panel**: 300pt, gesture cheat-sheet, live permission rows
  (green check / amber warning + deep link), log row. Rows ≥40pt hit.

## 6. Workspace (HTML) addendum

The workspace follows the same tokens (violet-tinted darks, state hues,
capsule chips) with web specifics already in place: OKLCH-expressible palette,
`prefers-color-scheme` + manual toggle, SF/system stack, tabular-nums on data,
reduced-motion media queries. Charts/data obey dataviz palette rules. No
side-stripe borders, no gradient text, no eyebrow-per-section.

## 7. Bans (project-specific, on top of impeccable's)

- Nothing but the island may be pure black; nothing but teaching ink may draw
  over the user's content.
- No second glow color on one element (glow = element's own hue).
- No modal windows, ever — Wisp has no windows to be modal in.
- No animation without a reduced-motion static counterpart.
- No same-radius nesting; no radius > 24 on rectangles; no border+wide-shadow
  pairs; no `transition: all` (workspace) / animating whole-view `.animation`
  without a `value:` (SwiftUI).
