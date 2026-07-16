import SwiftUI

// The three visual states the cursor-trailing glyph can render. This is intentionally a smaller
// enum than the full CompanionState, because only these three states produce a glyph: while idle
// the layer shows the plain wisp dot, and agent work is surfaced by cards, not the cursor.
enum CursorGlyphState: Equatable {
    case listening
    case processing
    case responding
}

// The cursor companion's state glyphs, designed as ONE light language so every state is visibly
// the same little wisp doing something different (the idle dot never "disappears", it changes
// behavior):
//
//   • LISTENING  — a ring of light repeatedly CONTRACTS into the dot: the wisp drawing your words
//     in. (Replaces the generic equalizer bars.)
//   • PROCESSING — a small spark ORBITS the dot: a thought circling.
//   • RESPONDING — ripples RADIATE outward from the dot: the wisp speaking. (Replaces the static
//     triangle, which read as a dead play button.)
//
// All motion is calm and small (~20pt), glow comes from color-matched shadows, and Reduce Motion
// swaps each animation for a distinct static form so state stays readable.
struct CursorGlyphView: View {
    let glyphState: CursorGlyphState
    let glyphColor: Color
    // The glyph canvas size. Default suits the cursor overlay; the notch ear passes a smaller one.
    var glyphDimension: CGFloat = 20

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        ZStack {
            // The wisp itself — the constant core across idle and every state.
            WispCoreDot(dotColor: glyphColor, coreDiameter: glyphDimension * 0.34)

            switch glyphState {
            case .listening:
                ContractingRingGlyph(
                    ringColor: glyphColor,
                    canvasDimension: glyphDimension,
                    isAnimating: !accessibilityReduceMotion
                )
            case .processing:
                OrbitingSparkGlyph(
                    sparkColor: glyphColor,
                    canvasDimension: glyphDimension,
                    isAnimating: !accessibilityReduceMotion
                )
            case .responding:
                RadiatingRipplesGlyph(
                    rippleColor: glyphColor,
                    canvasDimension: glyphDimension,
                    isAnimating: !accessibilityReduceMotion
                )
            }
        }
        .frame(width: glyphDimension, height: glyphDimension)
    }
}

// MARK: - The core dot (shared)

// The glowing point of light at the center of every state. Slightly smaller than the idle dot so
// the surrounding state motion reads as the emphasis.
private struct WispCoreDot: View {
    let dotColor: Color
    let coreDiameter: CGFloat

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: coreDiameter, height: coreDiameter)
            .shadow(color: dotColor.opacity(0.85), radius: 3)
            .shadow(color: dotColor.opacity(0.4), radius: 6)
    }
}

// MARK: - Listening: a ring contracting into the dot

private struct ContractingRingGlyph: View {
    let ringColor: Color
    let canvasDimension: CGFloat
    let isAnimating: Bool

    // 0 → full size, 1 → contracted onto the dot; runs 0 → 1 and restarts (no autoreverse), so the
    // ring always falls INWARD — light being drawn in.
    @State private var contractionProgress: CGFloat = 0

    var body: some View {
        Circle()
            .stroke(ringColor.opacity(0.25 + 0.55 * contractionProgress), lineWidth: 1.5)
            .frame(width: canvasDimension, height: canvasDimension)
            .scaleEffect(isAnimating ? (1.0 - 0.62 * contractionProgress) : 1.0)
            .onAppear {
                guard isAnimating else { return }
                withAnimation(.easeIn(duration: 1.0).repeatForever(autoreverses: false)) {
                    contractionProgress = 1
                }
            }
    }
}

// MARK: - Processing: a spark orbiting the dot

private struct OrbitingSparkGlyph: View {
    let sparkColor: Color
    let canvasDimension: CGFloat
    let isAnimating: Bool

    @State private var orbitAngleDegrees: Double = 0

    var body: some View {
        // The spark sits at the top of its orbit; rotating the container carries it around the dot.
        Circle()
            .fill(sparkColor)
            .frame(width: canvasDimension * 0.18, height: canvasDimension * 0.18)
            .shadow(color: sparkColor.opacity(0.8), radius: 2)
            .offset(y: -canvasDimension * 0.38)
            .rotationEffect(.degrees(isAnimating ? orbitAngleDegrees : 45))
            .onAppear {
                guard isAnimating else { return }
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    orbitAngleDegrees = 360
                }
            }
    }
}

// MARK: - Responding: ripples radiating from the dot

private struct RadiatingRipplesGlyph: View {
    let rippleColor: Color
    let canvasDimension: CGFloat
    let isAnimating: Bool

    var body: some View {
        if isAnimating {
            ZStack {
                // Two ripples, half a cycle apart, so one is always mid-flight.
                SingleRadiatingRipple(rippleColor: rippleColor, canvasDimension: canvasDimension, startDelay: 0)
                SingleRadiatingRipple(rippleColor: rippleColor, canvasDimension: canvasDimension, startDelay: 0.55)
            }
        } else {
            // Reduce Motion: two static concentric rings still read as "emitting".
            ZStack {
                Circle().stroke(rippleColor.opacity(0.55), lineWidth: 1.5)
                    .frame(width: canvasDimension * 0.6, height: canvasDimension * 0.6)
                Circle().stroke(rippleColor.opacity(0.3), lineWidth: 1.5)
                    .frame(width: canvasDimension, height: canvasDimension)
            }
        }
    }
}

private struct SingleRadiatingRipple: View {
    let rippleColor: Color
    let canvasDimension: CGFloat
    let startDelay: Double

    @State private var expansionProgress: CGFloat = 0

    var body: some View {
        Circle()
            .stroke(rippleColor.opacity(Double(1 - expansionProgress) * 0.7), lineWidth: 1.5)
            .frame(width: canvasDimension, height: canvasDimension)
            .scaleEffect(0.3 + 0.8 * expansionProgress)
            .onAppear {
                withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false).delay(startDelay)) {
                    expansionProgress = 1
                }
            }
    }
}
