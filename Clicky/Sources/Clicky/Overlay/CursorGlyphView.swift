import SwiftUI

// The three visual states the cursor-trailing glyph can render. This is intentionally a smaller
// enum than the full CompanionState, because only these three states produce a glyph: while idle
// or running a background agent there is nothing riding next to the cursor.
enum CursorGlyphState: Equatable {
    // Animated vertical waveform bars — the user is speaking / Clicky is listening.
    case listening
    // A spinning arc — Clicky is thinking / processing the request.
    case processing
    // A solid right-pointing triangle — Clicky is speaking (TTS playing).
    case responding
}

// A ~12pt glyph that rides just to the right of the OS cursor and communicates Clicky's live
// state. This is THE primary ambient feedback surface in the shipped design language — not a big
// HUD. The glyph color is configurable (blue by default) and all motion respects Reduce Motion.
struct CursorGlyphView: View {
    let glyphState: CursorGlyphState
    let glyphColor: Color

    // When the user has enabled Reduce Motion we render the same shapes but hold them still, so the
    // state is still readable without any looping animation.
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    // The nominal glyph size. ~12pt matches the tiny cursor-adjacent element seen in the demos.
    private let glyphDimension: CGFloat = 12

    var body: some View {
        Group {
            switch glyphState {
            case .listening:
                WaveformBarsGlyph(barColor: glyphColor, isAnimating: !accessibilityReduceMotion)
            case .processing:
                SpinningArcGlyph(arcColor: glyphColor, isAnimating: !accessibilityReduceMotion)
            case .responding:
                RightPointingTriangleGlyph(triangleColor: glyphColor)
            }
        }
        .frame(width: glyphDimension, height: glyphDimension)
    }
}

// MARK: - Listening: animated waveform bars

// Four short vertical bars whose heights animate up and down to read as an audio level meter.
private struct WaveformBarsGlyph: View {
    let barColor: Color
    let isAnimating: Bool

    // Drives the per-bar height oscillation. Advancing this phase re-computes each bar's scale.
    @State private var animationPhase: CGFloat = 0

    // Fixed base height fractions so the four bars have a pleasant, non-uniform resting shape.
    private let baseHeightFractions: [CGFloat] = [0.5, 0.9, 0.65, 0.4]

    var body: some View {
        HStack(alignment: .center, spacing: 1.5) {
            ForEach(0..<baseHeightFractions.count, id: \.self) { barIndex in
                Capsule(style: .continuous)
                    .fill(barColor)
                    .frame(width: 2, height: heightForBar(atIndex: barIndex))
            }
        }
        .onAppear {
            guard isAnimating else { return }
            // A repeating linear animation continuously advances the phase so the bars ripple.
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }

    // Computes an animated height for a bar by offsetting a sine wave per bar index, so the bars
    // don't all pulse in unison. When not animating, the base resting height is used.
    private func heightForBar(atIndex barIndex: Int) -> CGFloat {
        let maximumBarHeight: CGFloat = 12
        let baseFraction = baseHeightFractions[barIndex]
        guard isAnimating else {
            return maximumBarHeight * baseFraction
        }
        let perBarPhaseOffset = CGFloat(barIndex) * 0.7
        let oscillation = (sin((animationPhase * .pi * 2) + perBarPhaseOffset) + 1) / 2
        // Blend the base resting fraction with the live oscillation so bars never fully collapse.
        let blendedFraction = (baseFraction * 0.4) + (oscillation * 0.6)
        return maximumBarHeight * max(0.2, blendedFraction)
    }
}

// MARK: - Processing: spinning arc

// A three-quarter circular arc that continuously rotates, reading as a lightweight loading spinner.
private struct SpinningArcGlyph: View {
    let arcColor: Color
    let isAnimating: Bool

    @State private var currentRotationDegrees: Double = 0

    var body: some View {
        Circle()
            // Trim to 75% of the circle so there's a visible gap that makes rotation legible.
            .trim(from: 0, to: 0.75)
            .stroke(arcColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .rotationEffect(.degrees(currentRotationDegrees))
            .onAppear {
                guard isAnimating else { return }
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    currentRotationDegrees = 360
                }
            }
    }
}

// MARK: - Responding: solid right-pointing triangle

// A filled right-pointing triangle (a "play"-like glyph) shown while TTS audio is playing.
private struct RightPointingTriangleGlyph: View {
    let triangleColor: Color

    var body: some View {
        RightTriangleShape()
            .fill(triangleColor)
    }
}

// The triangle geometry: apex on the right edge, flat back on the left edge.
private struct RightTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var trianglePath = Path()
        trianglePath.move(to: CGPoint(x: rect.minX, y: rect.minY))
        trianglePath.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        trianglePath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        trianglePath.closeSubpath()
        return trianglePath
    }
}
