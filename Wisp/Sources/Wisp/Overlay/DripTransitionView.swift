import SwiftUI

// The Drip — Wisp's signature session-start move (DESIGN.md §4). When a listening session begins,
// light condenses at the notch's bottom lip, extrudes into a droplet that travels to the user's
// cursor, pinches off, and BECOMES the cursor glyph. One continuous liquid read, decomposed from
// the researched island-drip mechanic:
//
//   1. bulge   — an anchor blob swells at the notch lip
//   2. extrude — a droplet leaves it, connected by a gooey neck (metaball blend)
//   3. pinch   — the neck thins past the blend threshold and snaps (emergent, not keyframed)
//   4. arrive  — the droplet lands on the cursor; the real glyph takes over seamlessly
//
// The liquid read is pure topology — a blur + alpha-threshold metaball pass (no refraction, no
// glass). Canvas filters do this natively: threshold(0.5) over blur(10) re-solidifies the blurred
// union of two circles into one continuous-curvature membrane that necks and pinches on its own.
struct DripFlight: Equatable {
    // Where the drip hangs from (the notch's bottom-center, in overlay top-left coordinates).
    var anchorPoint: CGPoint
    // Where the droplet lands (the cursor position at session start).
    var targetPoint: CGPoint
    // Monotonic id so repeated flights re-render distinctly.
    var flightNumber: Int
    var startDate: Date
}

struct DripTransitionView: View {
    let dripFlight: DripFlight
    let dripColor: Color
    // Called once the droplet has arrived (progress 1) so the coordinator can clear the flight
    // and let the standing cursor glyph take over.
    var onArrival: () -> Void = {}

    static let flightDurationSeconds: Double = 0.55

    @State private var didReportArrival = false

    var body: some View {
        TimelineView(.animation) { timelineContext in
            let rawProgress = min(
                1,
                timelineContext.date.timeIntervalSince(dripFlight.startDate) / Self.flightDurationSeconds
            )
            let easedProgress = Self.easeInOutCubic(rawProgress)

            Canvas { canvasContext, _ in
                // Metaball pass: threshold re-solidifies the blur — order matters (threshold is
                // added first so it applies to the blurred layer beneath it).
                canvasContext.addFilter(.alphaThreshold(min: 0.5, color: Self.resolvedColor(dripColor)))
                canvasContext.addFilter(.blur(radius: 10))

                canvasContext.drawLayer { liquidLayer in
                    // The anchor blob: swells quickly at the start (light condensing at the lip),
                    // then drains away as the droplet takes its mass.
                    let anchorSwell = min(1, rawProgress * 4)             // fully swollen by t=0.25
                    let anchorRadius = (10 * anchorSwell) * (1 - easedProgress * 0.85)
                    if anchorRadius > 0.5 {
                        liquidLayer.fill(
                            Circle().path(in: Self.squareRect(center: dripFlight.anchorPoint, radius: anchorRadius)),
                            with: .color(.white)
                        )
                    }

                    // The droplet: born small at the anchor, grows to glyph mass as it travels a
                    // gently-arced bezier to the cursor. While it's near the anchor the blur pass
                    // fuses them (the neck); as separation grows the neck thins and snaps.
                    let dropletRadius = 4 + 5 * easedProgress
                    let dropletCenter = Self.quadraticBezierPoint(
                        at: easedProgress,
                        from: dripFlight.anchorPoint,
                        control: Self.arcControlPoint(from: dripFlight.anchorPoint, to: dripFlight.targetPoint),
                        to: dripFlight.targetPoint
                    )
                    liquidLayer.fill(
                        Circle().path(in: Self.squareRect(center: dropletCenter, radius: dropletRadius)),
                        with: .color(.white)
                    )
                }
            }
            .allowsHitTesting(false)
            .onChange(of: rawProgress >= 1) { _, hasArrived in
                if hasArrived && !didReportArrival {
                    didReportArrival = true
                    onArrival()
                }
            }
        }
    }

    // MARK: - Geometry helpers

    private static func squareRect(center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    private static func quadraticBezierPoint(at t: Double, from start: CGPoint, control: CGPoint, to end: CGPoint) -> CGPoint {
        let clampedT = CGFloat(min(max(t, 0), 1))
        let oneMinusT = 1 - clampedT
        return CGPoint(
            x: oneMinusT * oneMinusT * start.x + 2 * oneMinusT * clampedT * control.x + clampedT * clampedT * end.x,
            y: oneMinusT * oneMinusT * start.y + 2 * oneMinusT * clampedT * control.y + clampedT * clampedT * end.y
        )
    }

    // A gentle arc — mostly vertical fall out of the notch, bowing slightly toward the target,
    // so the drip reads as gravity + intent rather than a straight-line tween.
    private static func arcControlPoint(from anchor: CGPoint, to target: CGPoint) -> CGPoint {
        CGPoint(
            x: anchor.x + (target.x - anchor.x) * 0.25,
            y: anchor.y + (target.y - anchor.y) * 0.6 + 24
        )
    }

    // Canvas's alphaThreshold color parameter needs a concrete Color; passing the token through
    // keeps the drip in the glyph's own hue (light stays its own color — DESIGN.md glow rule).
    private static func resolvedColor(_ color: Color) -> Color { color }

    private static func easeInOutCubic(_ t: Double) -> Double {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}
