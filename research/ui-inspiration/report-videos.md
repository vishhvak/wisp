# Motion video decodes (persisted from agent findings)

## 1. Island drip loader (rsStats_, expo+reanimated+skia)
3-act metaball mechanic:
1. Bottom-center of the black pill island bulges into a nub (~0.8s in)
2. Neck extrusion ~250ms: nub elongates, teardrop bulb at tip, continuous curvature (one membrane, no seams)
3. Pinch-off in 1–2 frames (instant): droplet separates cleanly; island snaps flush back immediately
4. **The freed droplet BECOMES the spinner** (28–32px, rotating arc, linear ~1s/rotation, holds ~9s) — same object, not a cut
5. Retract at end is sub-300ms.
Character: asymmetric squash/stretch (island anchored, only the bottom extrudes); three time signatures stitched (slow stretch → instant pinch → long linear spin) sell the physicality. Implementation: metaball (two blended circles, one pinned to island base, one following target), not keyframes.
**Wisp**: session start = wisp-dot drips out of the notch toward the ACTUAL cursor position, pinches off, becomes the glyph. Listening = stop short of pinch-off, hold the straining tether. Session end = reverse extrusion pulls the glyph home. One shared metaball primitive parameterized by anchor→target distance.

## 2. Liquid glass without the glass (mikkmartin)
Two rounded cards + a Gap slider; when gap crosses ≤0, touching edges fuse into a smooth concave saddle — mercury-drop merge. ZERO refraction/specular/lighting — the entire liquid read is pure topology (continuous curvature + concave pinch at the seam). Classic gooey: blur both shapes → sharp alpha threshold (blur+contrast, SVG feGaussianBlur+feColorMatrix, or Skia metaball).
**Wisp**: confirms cheap implementation (blur+threshold or bezier approximation — no glass shader); extends the primitive to island↔card fusion and glyph merging.

## 3. tabular-nums (jakubkrehel)
Proportional digits make an auto-width pill wobble on every increment; tabular digits hold it stable. **Wisp**: `.monospacedDigit()` on every live number (timers, counts) — audit item.

## 4. "todrawn" pen landing (Aurelien_Gz)
One persistent 3D pencil actor performs each feature; caption card slides in AFTER the stroke finishes and literally describes what was just performed; entry sides alternate; final CTA = pencil swaps cap color blue→red and writes "your turn". Rough sketch **snaps** to precise shape in 1–2 frames (not animated straightening) = the "AI did the work" tell.
**Wisp**: onboarding = the glyph performs (drip, glow, ink) with the caption following; color-swap for state CTAs; rough→precise snap when visualizing voice → structured result.
