# rare-ui — motion audit (persisted from agent findings)

8 registry components (Motion/Framer + Tailwind v4). Full deep-dive values below; original repo cloned at ui-inspo/rare-ui.

## Stealable for Wisp (exact values)
1. **Island shape-morph spring**: `{spring, bounce:0.16, duration:0.5}` on width/height/borderRadius TOGETHER; pre-measure both end states (never animate to "auto").
2. **Content-swap-inside-morph**: crossfade `{duration:0.24, ease:[0.65,0,0.35,1]}` + `blur(4px)→0`, label swap `{duration:0.22, ease:[0.22,1,0.36,1]}`, nested inside the shape spring; stagger incoming ~0.08s behind outgoing.
3. **Glow orb shader** (ChatGPT-voice style): 3-octave fBm, amp 0.6 halving, freq ×2, time×0.22, bands smoothstep(0.28,0.52)/(0.58,0.88). Reduced motion: freeze time AND skip the frame loop.
4. **Cursor-magnet**: transform distance [-40,0,40]→[base,active,base] clamped → spring `{320, 34, 0.7}`. Drive the same spring from state changes too.
5. **Validation shake**: spring `{stiffness:700, damping:9}`, jump 6px → settle 0.
6. **Check morph**: stroke-draw pathLength 0→1, 0.2s easeOut, delay 0.05; pen→check via flubber path morph, icon spring `{200,28}`.
7. **Dark card tokens**: bg `oklch(0.1822 0 0)`, border `white/0.08`, header wash `white/0.03`, hover wash `white/0.08`; radius scale base 0.375rem (sm −4, md −2, xl +4).
8. **Copy/success timing**: exit 0.15s easeIn scale→0.6 blur→3px; enter 0.14s delay 0.08 + scale spring `{520,17}`; auto-reset 1500–1800ms.
9. **Squircle-stretch hover**: one spring `{300,22}`, +18px scaleX growth, ∓9px neighbor slide (transform-only, no reflow).
10. **Reduced-motion discipline**: every component branches — zero/jump or skip the loop entirely.

## Component notes
- **ScrollProgress** = the Dynamic-Island pattern: pill↔squircle morph (collapsed radius = height/2, open 26px), ring fill spring `{120,30,0.3}` on SVG pathLength, list stagger `0.04 + i*0.03`, shared-layoutId active pill, 700ms scroll-lock after click.
- **FluidOrb**: WebGL fBm glow, DPR clamped ≤2.
- **ProximitySidebar**: per-kind dash base/bump (title 40/70 … body 24/50), transformOrigin flips by dock side, idle fakes pointer at nearest section, resets after 80ms.
- **DurationPicker**: gap spring `{200,28,1}` (8px), width `{250,31}`, sway ±3px via gap velocity `{200,24}`, error `{700,9}`, figma-squircle live-measured segments.
- **FolderComponent**: card fan, shared `{120,13}` spring staggered 0/0.05/0.1 (back leads, front lags), flap rotateX −15/−45/−55° perspective 800, blur(6px) flap, theme-reactive SVG feColorMatrix inner shadows.
- **CodeBlock**: full Prism theme derived from ONE accent hex (lightness clamped per role, one ramp function flipped for light/dark).
- **BounceSidebar**: active dot arcs between items — `arc({strength: min(0.8, 14/distance)})`, 0.25s easeOut, dot device-pixel-snapped.
- **GooeyNavbar**: layout spring `{300,30}`; 4-layer icon morph `{250,24}` + pop `{320,15}`, sparkles stagger 0.1/0.18 opposing rotations.
- **HeroCta**: adjacent-pill stretch, GROW 18px, SIDE_SHIFT 9px, spring `{300,22}`.
- **CopyButton**: universal swap timing (see #8).
- **family-drawer** (orphan): content-aware duration `clamp(|Δheight|/500, 0.15, 0.27)` — bigger jumps, longer fades.

Gap: no toast/drop-zone component; FolderComponent nearest analog.
