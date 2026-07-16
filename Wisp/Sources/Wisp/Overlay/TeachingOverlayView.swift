import SwiftUI

// Renders the AI's on-screen "teaching ink" — the red outlines, arrows, dots, and white-on-red
// chip labels the tutor mode paints over the user's screen. All shapes use a single saturated red
// (#FF3B30) per the design language, and chip labels ACCUMULATE into a persistent legend rather
// than replacing one another. A subtle trim-based draw-on animation is used unless Reduce Motion
// is enabled, in which case the ink appears fully-formed (a hard cut-in, as in the real demos).
struct TeachingOverlayView: View {
    // The annotations to paint. New annotations are appended; existing ones stay on screen.
    let teachingAnnotations: [TeachingAnnotation]

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        // A ZStack layered over the full overlay so each annotation is drawn at its absolute
        // coordinates. allowsHitTesting(false) guarantees the ink never intercepts real clicks.
        ZStack(alignment: .topLeading) {
            ForEach(teachingAnnotations) { annotation in
                TeachingAnnotationView(
                    annotation: annotation,
                    shouldAnimateDrawOn: !accessibilityReduceMotion
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// Draws a single annotation. Kept as its own view so each shape can own its draw-on animation
// state independently (SwiftUI drives the trim/opacity transition when the view first appears).
private struct TeachingAnnotationView: View {
    let annotation: TeachingAnnotation
    let shouldAnimateDrawOn: Bool

    // Animates from 0 → 1 when the annotation appears, driving stroke trim (for lines) and opacity.
    @State private var drawOnProgress: CGFloat = 0

    private let teachingInkColor = DS.Colors.teachRed
    private let strokeLineWidth: CGFloat = 4

    var body: some View {
        annotationShapeView
            .onAppear {
                // Reduced motion → snap straight to fully drawn; otherwise ease the ink on.
                guard shouldAnimateDrawOn else {
                    drawOnProgress = 1
                    return
                }
                withAnimation(.easeOut(duration: 0.45)) {
                    drawOnProgress = 1
                }
            }
    }

    // Chooses the right rendering for the annotation's shape. Shapes that carry a label (highlight
    // rect, target ring, hover ring) also paint an accumulating white-on-red chip next to the ink.
    @ViewBuilder
    private var annotationShapeView: some View {
        switch annotation.shape {
        case .rect(let targetRectangle):
            // A stroked outline that trims on from zero, positioned at its absolute frame. Used by
            // both [HIGHLIGHT] and legacy [DRAW:rect]; a chip rides at the rect's top-left when labelled.
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .trim(from: 0, to: drawOnProgress)
                    .stroke(teachingInkColor, style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                    .frame(width: targetRectangle.width, height: targetRectangle.height)
                    .position(x: targetRectangle.midX, y: targetRectangle.midY)

                if !annotation.label.isEmpty {
                    labelChip
                        .position(x: targetRectangle.minX, y: targetRectangle.minY - 14)
                }
            }

        case .arrow(let startPoint, let endPoint):
            ArrowShape(startPoint: startPoint, endPoint: endPoint)
                .trim(from: 0, to: drawOnProgress)
                .stroke(teachingInkColor, style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round, lineJoin: .round))

        case .curve(let startPoint, let controlPoint, let endPoint):
            // A quadratic bezier with an arrowhead at its end, trimmed on like the straight arrow.
            CurvedArrowShape(startPoint: startPoint, controlPoint: controlPoint, endPoint: endPoint)
                .trim(from: 0, to: drawOnProgress)
                .stroke(teachingInkColor, style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round, lineJoin: .round))

        case .dot(let targetPoint):
            Circle()
                .fill(teachingInkColor)
                .frame(width: 10, height: 10)
                .position(targetPoint)
                .opacity(Double(drawOnProgress))

        case .chip(let anchorPoint):
            // A white-on-red rounded chip label that fades/scales in and stays as part of the legend.
            labelChip
                .position(anchorPoint)

        case .target(let center, let radius):
            // A solid ring + center dot marking the single observable next action, with a chip label.
            ZStack {
                Circle()
                    .trim(from: 0, to: drawOnProgress)
                    .stroke(teachingInkColor, style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                Circle()
                    .fill(teachingInkColor)
                    .frame(width: 8, height: 8)
                    .position(center)
                    .opacity(Double(drawOnProgress))

                if !annotation.label.isEmpty {
                    labelChip
                        .position(x: center.x, y: center.y - radius - 14)
                }
            }

        case .hover(let center, let radius):
            // A dashed ring indicating an element to hover — lighter-weight than a target — with a chip.
            ZStack {
                Circle()
                    .trim(from: 0, to: drawOnProgress)
                    .stroke(
                        teachingInkColor,
                        style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round, dash: [6, 5])
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                if !annotation.label.isEmpty {
                    labelChip
                        .position(x: center.x, y: center.y - radius - 14)
                }
            }
        }
    }

    // The shared white-on-red chip used by chip/target/hover/highlight annotations. Fades and
    // scales in with the draw-on progress and then stays put as part of the persistent legend.
    private var labelChip: some View {
        Text(annotation.label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, DS.Spacing.small)
            .padding(.vertical, DS.Spacing.extraSmall)
            .background(
                RoundedRectangle(cornerRadius: DS.CornerRadius.chip, style: .continuous)
                    .fill(teachingInkColor)
            )
            .opacity(Double(drawOnProgress))
            .scaleEffect(0.9 + (0.1 * drawOnProgress))
            .fixedSize()
    }
}

// A curved (quadratic bezier) arrow from start to end, bending through a control point, with a
// two-line arrowhead at the end. Like ArrowShape, it's a Shape so the draw-on trim animation works.
private struct CurvedArrowShape: Shape {
    let startPoint: CGPoint
    let controlPoint: CGPoint
    let endPoint: CGPoint

    func path(in rect: CGRect) -> Path {
        var curvedPath = Path()
        curvedPath.move(to: startPoint)
        curvedPath.addQuadCurve(to: endPoint, control: controlPoint)

        // Orient the arrowhead along the curve's final tangent, which for a quadratic bezier points
        // from the control point toward the end point.
        let finalTangentAngle = atan2(endPoint.y - controlPoint.y, endPoint.x - controlPoint.x)
        let arrowheadLength: CGFloat = 12
        let arrowheadSpreadAngle: CGFloat = .pi / 7

        let leftHeadPoint = CGPoint(
            x: endPoint.x - arrowheadLength * cos(finalTangentAngle - arrowheadSpreadAngle),
            y: endPoint.y - arrowheadLength * sin(finalTangentAngle - arrowheadSpreadAngle)
        )
        let rightHeadPoint = CGPoint(
            x: endPoint.x - arrowheadLength * cos(finalTangentAngle + arrowheadSpreadAngle),
            y: endPoint.y - arrowheadLength * sin(finalTangentAngle + arrowheadSpreadAngle)
        )

        curvedPath.move(to: endPoint)
        curvedPath.addLine(to: leftHeadPoint)
        curvedPath.move(to: endPoint)
        curvedPath.addLine(to: rightHeadPoint)

        return curvedPath
    }
}

// A straight arrow from start to end, with a two-line arrowhead at the end point. Implemented as a
// Shape so it can be trimmed for the draw-on animation (the shaft draws first, then the head).
private struct ArrowShape: Shape {
    let startPoint: CGPoint
    let endPoint: CGPoint

    func path(in rect: CGRect) -> Path {
        var arrowPath = Path()

        // The main shaft of the arrow.
        arrowPath.move(to: startPoint)
        arrowPath.addLine(to: endPoint)

        // Compute the arrowhead: two short lines splaying back from the end point, oriented along
        // the shaft direction so the head always points the right way regardless of angle.
        let shaftAngle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowheadLength: CGFloat = 12
        let arrowheadSpreadAngle: CGFloat = .pi / 7

        let leftHeadPoint = CGPoint(
            x: endPoint.x - arrowheadLength * cos(shaftAngle - arrowheadSpreadAngle),
            y: endPoint.y - arrowheadLength * sin(shaftAngle - arrowheadSpreadAngle)
        )
        let rightHeadPoint = CGPoint(
            x: endPoint.x - arrowheadLength * cos(shaftAngle + arrowheadSpreadAngle),
            y: endPoint.y - arrowheadLength * sin(shaftAngle + arrowheadSpreadAngle)
        )

        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: leftHeadPoint)
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: rightHeadPoint)

        return arrowPath
    }
}
