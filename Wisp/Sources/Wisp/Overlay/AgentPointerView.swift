import SwiftUI

// The agent pointer: a small triangle that GLIDES along a quadratic bezier arc to each new teaching
// target, fires a ring-ripple when it lands, and hides itself after ~1.5 seconds of inactivity.
// This implements the shipped app's observed cursor motion contract ("bezier-glide triangle
// pointer, ring-ripple on landing, idle-hide ~1.5s") for Wisp's teaching mode: whenever Claude
// paints a new annotation, the pointer flies to it, drawing the user's eye to the right spot just
// before the ink appears there.

// One flight of the pointer: the arc it travels from wherever it currently is to the new target.
private struct PointerFlight: Equatable {
    var startPoint: CGPoint
    var controlPoint: CGPoint
    var endPoint: CGPoint
    // Monotonic counter so consecutive flights to nearby points still register as distinct flights.
    var flightNumber: Int
}

struct AgentPointerView: View {
    // The point the pointer should fly to (the anchor of the newest teaching annotation), or nil
    // when there is no active teaching target.
    let targetPoint: CGPoint?

    // Where a flight starts when the pointer is not already on screen — the user's cursor position,
    // so the pointer visibly departs from where the user is looking (matching the original
    // companion's fly-out-from-cursor behavior).
    let flightStartFallbackPoint: CGPoint

    let pointerColor: Color

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    // The flight currently being flown (or just landed). nil until the first target arrives.
    @State private var currentFlight: PointerFlight?

    // Progress along the current flight's bezier, 0 → 1. Animated; the position modifier below is
    // Animatable so SwiftUI interpolates the pointer smoothly along the curve, not in a straight line.
    @State private var flightProgress: CGFloat = 0

    // Whether the landing ripple is currently showing (keyed by flight number so each landing
    // replays it exactly once).
    @State private var isRippleVisible = false

    // The pointer fades out after this long with no new target (the shipped "idle-hide ~1.5s").
    private static let idleHideDelaySeconds: Double = 1.5
    @State private var pointerOpacity: Double = 0
    @State private var idleHideTask: Task<Void, Never>?

    private static let flightDurationSeconds: Double = 0.55
    private let pointerDimension: CGFloat = 14

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let currentFlight {
                // The landing ripple renders at the flight's destination, underneath the pointer.
                if isRippleVisible {
                    LandingRippleView(rippleColor: pointerColor, isAnimated: !accessibilityReduceMotion)
                        .position(currentFlight.endPoint)
                }

                AgentPointerTriangle()
                    .fill(pointerColor)
                    .frame(width: pointerDimension, height: pointerDimension)
                    .shadow(color: pointerColor.opacity(0.5), radius: 3)
                    .modifier(
                        QuadraticBezierPositionModifier(
                            flightProgress: flightProgress,
                            startPoint: currentFlight.startPoint,
                            controlPoint: currentFlight.controlPoint,
                            endPoint: currentFlight.endPoint
                        )
                    )
                    .opacity(pointerOpacity)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: targetPoint) { _, newTargetPoint in
            guard let newTargetPoint else {
                hidePointerNow()
                return
            }
            beginFlight(to: newTargetPoint)
        }
    }

    // MARK: - Flight lifecycle

    private func beginFlight(to destinationPoint: CGPoint) {
        idleHideTask?.cancel()
        isRippleVisible = false

        // Depart from wherever the pointer currently is; if it's hidden/never flown, depart from
        // the user's cursor so the motion starts where their attention already is.
        // ponytail: an interrupted mid-flight pointer restarts from its previous DESTINATION, not its
        // exact interpolated position — acceptable, flights are 0.55s; track live position if it jars.
        let departurePoint = currentFlight?.endPoint ?? flightStartFallbackPoint

        let newFlight = PointerFlight(
            startPoint: departurePoint,
            controlPoint: Self.arcControlPoint(from: departurePoint, to: destinationPoint),
            endPoint: destinationPoint,
            flightNumber: (currentFlight?.flightNumber ?? 0) + 1
        )
        currentFlight = newFlight
        pointerOpacity = 1

        if accessibilityReduceMotion {
            // Reduce Motion: appear at the destination directly; the (non-animated) ripple still
            // marks the landing so the state change is communicated without the glide.
            flightProgress = 1
            handleLanding()
            return
        }

        // Restart the animatable progress from the departure end of the new curve, then animate to
        // the destination. The completion fires the ripple + arms the idle-hide.
        flightProgress = 0
        withAnimation(.easeInOut(duration: Self.flightDurationSeconds)) {
            flightProgress = 1
        } completion: {
            handleLanding()
        }
    }

    private func handleLanding() {
        isRippleVisible = true
        armIdleHide()
    }

    private func armIdleHide() {
        idleHideTask?.cancel()
        idleHideTask = Task {
            let idleHideNanoseconds = UInt64(Self.idleHideDelaySeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: idleHideNanoseconds)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                pointerOpacity = 0
            }
            isRippleVisible = false
        }
    }

    private func hidePointerNow() {
        idleHideTask?.cancel()
        isRippleVisible = false
        pointerOpacity = 0
    }

    // Computes the control point that gives the flight its characteristic upward arc: the midpoint
    // of the segment, lifted perpendicular to it. The lift scales with distance (a quarter of it,
    // clamped) so short hops arc gently and long flights arc visibly, never absurdly.
    private static func arcControlPoint(from startPoint: CGPoint, to endPoint: CGPoint) -> CGPoint {
        let midpointX = (startPoint.x + endPoint.x) / 2
        let midpointY = (startPoint.y + endPoint.y) / 2

        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        let flightDistance = sqrt(deltaX * deltaX + deltaY * deltaY)
        guard flightDistance > 1 else { return CGPoint(x: midpointX, y: midpointY) }

        let arcLift = min(max(flightDistance * 0.25, 32), 160)

        // Perpendicular (rotated -90°) unit vector; the sign biases the arc UPWARD on screen
        // (negative y in this top-left-origin space) for left-to-right flights, matching the
        // graceful over-the-top glide seen in the original companion.
        let perpendicularX = deltaY / flightDistance
        let perpendicularY = -deltaX / flightDistance
        let upwardBias: CGFloat = perpendicularY <= 0 ? 1 : -1

        return CGPoint(
            x: midpointX + perpendicularX * arcLift * upwardBias,
            y: midpointY + perpendicularY * arcLift * upwardBias
        )
    }
}

// MARK: - Bezier position (Animatable)

// Positions its content along a quadratic bezier at `flightProgress` ∈ [0, 1]. Conforming to
// Animatable is what makes SwiftUI interpolate the PROGRESS value frame-by-frame — each frame
// re-evaluates the curve, so the content truly travels the arc instead of lerping point-to-point.
private struct QuadraticBezierPositionModifier: ViewModifier, Animatable {
    var flightProgress: CGFloat
    let startPoint: CGPoint
    let controlPoint: CGPoint
    let endPoint: CGPoint

    var animatableData: CGFloat {
        get { flightProgress }
        set { flightProgress = newValue }
    }

    func body(content: Content) -> some View {
        content.position(quadraticBezierPoint(at: flightProgress))
    }

    // Standard quadratic bezier: P(t) = (1-t)²·P0 + 2(1-t)t·C + t²·P1
    private func quadraticBezierPoint(at t: CGFloat) -> CGPoint {
        let clampedT = min(max(t, 0), 1)
        let oneMinusT = 1 - clampedT
        let x = oneMinusT * oneMinusT * startPoint.x
            + 2 * oneMinusT * clampedT * controlPoint.x
            + clampedT * clampedT * endPoint.x
        let y = oneMinusT * oneMinusT * startPoint.y
            + 2 * oneMinusT * clampedT * controlPoint.y
            + clampedT * clampedT * endPoint.y
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Landing ripple

// A single expanding, fading ring fired once when the pointer lands — the "I'm here" beat that
// draws the eye to the destination. With Reduce Motion it renders as a brief static ring instead.
private struct LandingRippleView: View {
    let rippleColor: Color
    let isAnimated: Bool

    @State private var isExpanded = false

    var body: some View {
        Circle()
            .stroke(rippleColor.opacity(isExpanded ? 0 : 0.7), lineWidth: 2)
            .frame(width: 40, height: 40)
            .scaleEffect(isExpanded ? 1.7 : 0.3)
            .onAppear {
                guard isAnimated else { return }
                withAnimation(.easeOut(duration: 0.6)) {
                    isExpanded = true
                }
            }
    }
}

// MARK: - Pointer triangle

// The pointer's arrowhead: apex up-left (the "pointing" corner), matching a cursor's hot corner,
// with a slightly swept-back base so it reads as an arrow rather than a play button.
private struct AgentPointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var trianglePath = Path()
        trianglePath.move(to: CGPoint(x: rect.minX, y: rect.minY))
        trianglePath.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + rect.height * 0.12))
        trianglePath.addLine(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY))
        trianglePath.closeSubpath()
        return trianglePath
    }
}
