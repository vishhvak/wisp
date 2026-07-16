# Sites A — component/animation libraries (persisted from agent findings)

- oxygen-ui.vercel.app: DEAD (404 deployment not found).
- bagui.vercel.app: Pro-gated shadcn blocks; only confirms the Tailwind baseline (150ms cubic-bezier(0.4,0,0.2,1)) — the floor to beat.
- animatedbuttons.colorion.co: redirects through the Cloudflare component-gallery webring; landed on:

## beUI (beui.dev, github.com/starc007/ui-components) — richest find
Named spring tokens (lib/ease.ts):
- EASE_OUT [0.16,1,0.3,1] · EASE_IN_OUT [0.77,0,0.175,1] · EASE_DRAWER [0.32,0.72,0,1]
- SPRING_PRESS {500,30,0.6} · SPRING_SWAP {460,30,0.55} · SPRING_PANEL {420,40,0.5} · SPRING_LAYOUT {360,32,0.6} · SPRING_MOUSE {200,15,0.3}

**DynamicIsland component** (reference implementation):
- Shell: spring on REAL width/height {duration:0.8, bounce:0.2}; border-radius held CONSTANT at 32 (browser clamps to half shorter side → pill↔rect morph glitch-free); transform-origin top center (unfurls under a notch).
- Content: enter spring {duration:0.8, bounce:0.35} from {opacity:0, scale:0.9, y:-8, blur:5px}; **exit 80ms flat, NO blur — sucked into the pill before the shell finishes shrinking**.
- NotificationStack: fan via y:index*8 + clipPath inset(0 index*12px round 16px); 0.32s/0.26s EASE_OUT; badge bevel inset shadows.
- Button: whileTap 0.93, whileHover 1.02, SPRING_PRESS, all sizes rounded-full.

## Originkit (originkit.dev) — cursor category
- **Fluid Trail**: glowing comet blobs trailing pointer — #66FF9C, size 7px, 30-point trail, fade-outside-radius. Recolor → Wisp flourish.
- Axis Cursor (crosshair + coord chip, dot 12px, hairline 1px); Sniper click burst (0.3s, 2px stroke); Kinetic Grid (spacing 30, radius 400, strength 4).
- One easing at 3 durations: 150/220/420ms.

## amicro.vercel.app — dark icon-morph micro-interactions
- Token: h36 / r40 / min-w 75 / 150ms (0.4,0,0.2,1). Press GROWS 1.02 (rejected for Wisp — keep shrink 0.96).
- Icon morph: two absolute icon layers crossfade inside a FIXED 16×16 box (button never resizes); alert recolor oklch(0.704 0.191 22.216).

## transitions.dev — deepest token source
- Durations 40→500ms (stagger/micro/quick/fast/medium/slow/very-slow); --ease-smooth-out [0.22,1,0.36,1] carries ~80% of patterns (independent convergence with beUI's EASE_OUT).
- Dark card: bg #181818, r24, 5-layer inset box-shadow bevel, no border.
- Toast: 52px pill, translate+scale(.97)+blur(2px), 350ms open / 250ms close, same ease (calm).
- Button→panel morph: 40×40 circle → 183×172 r20; open 350ms overshoot [0.34,1.25,0.64,1] / close 250ms smooth.
- **Anticipatory gather**: 700ms 5px squish right BEFORE a shell collapses.
- Badge diagonal entrance: position and scale on DIFFERENT eases in one entrance. Error shake: uneven decelerating keyframes.

## Adopted into Wisp DESIGN.md
- Island content exit: 80ms flat (no blur/move) — content vanishes before shell morphs.
- Island content enter: soft top-anchored unfurl (opacity + slight scale + y).
- Ease vocabulary convergence noted; anticipatory gather logged as future flourish.
