# Sites C — inspo galleries (persisted from agent findings)

## namethatui.com — correct names + anatomy
- Notch HUD = **Panel (Floating Window/HUD)**: NSPanel + .floating + .nonactivatingPanel + hudWindow — literally "suits Spotlight-like surfaces". (Wisp already builds exactly this.)
- Glass = **NSVisualEffectView Material + vibrancy** — the correct primitive, not hand-rolled blur+opacity.
- **Liquid Glass** (Apple, macOS Tahoe): glass RESERVED for the floating control layer (bars, buttons, sliders); content stays opaque and full-contrast. Frosted-on-content = generic Glassmorphism = reads cheap. Also: lensing with bright edge highlights, adaptive re-tinting, capsule shapes with concentric radii.
- Status text = **Pill** (capsule short status) — not badge (count), chip (removable token), or tag (category).
- Toast: role=status, viewport corner stacking, timer pauses on hover/focus.
- No "command palette" as its own taxonomy entry; anatomy = command input + groups + active row + shortcuts.

## arlan.me/vault — mechanics with real code
- **Chromatic glow**: true bloom (multi-radius gaussian blur composited back) + warm/cool RGB-offset copies drifting apart at edges → rainbow fringe; leans toward cursor on hover. → Upgrade path for Wisp's glyph glow.
- **Dia gradient**: tall blurred rainbow SVG rects melted together at the bottom edge, scaling up from flat on load ("rises from the floor") → ambient glow bar for workspace footer.
- **The typer**: per-letter state sweep (solid pill → highlight → outline → text), adjacent same-state letters merge into one bar → candidate for teaching-text reveals.
- **Color-depth buttons**: gradient body + inset bevel shadows + hover brighter layer + top highlight bar = glass/metal feel with zero images.
- **Ghosty reveal**: images bleed in via tall feathered gradient mask sliding on mask-position.

## recent.design / bestdesignsonx.com
- North-star mark reference: glowing 4-point starburst centered in a soft radial blue halo on dark — "a little light" literalized.
- Floating pill composer (attach + / field / mic / blue voice circle) — matches Wisp's composer anatomy.
- Dark command-menu card + floating bottom control panel — HUD proportions references.
- Dot-matrix loaders; sparse-particle idle textures; Aave dark-card spacing reference.

## Access gotcha
namethatui.com = Cloudflare Turnstile; headless hangs forever; --headed passes on FIRST load only — then drive in-app search, never re-open.

## Synthesis for Wisp
1. Spec surfaces by their real names (Panel/HUD, Pill, Toast) — inherit correct behavior.
2. **Glass discipline**: translucency/glow = control layer only; transcript/cards/workspace content opaque.
3. Glyph = bloom + chromatic split toward cursor (not flat shadow glow); mark = starburst in halo.
4. Workspace identity: Dia-style rising glow bar at an edge, content untouched.
5. Teaching-text reveal: the typer's pill-state sweep. Loading: dot-matrix.
