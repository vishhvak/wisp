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

    // Chooses the right rendering for the annotation's shape.
    @ViewBuilder
    private var annotationShapeView: some View {
        switch annotation.shape {
        case .rect(let targetRectangle):
            // A stroked outline that trims on from zero, positioned at its absolute frame.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .trim(from: 0, to: drawOnProgress)
                .stroke(teachingInkColor, style: StrokeStyle(lineWidth: strokeLineWidth, lineCap: .round))
                .frame(width: targetRectangle.width, height: targetRectangle.height)
                .position(x: targetRectangle.midX, y: targetRectangle.midY)

        case .arrow(let startPoint, let endPoint):
            ArrowShape(startPoint: startPoint, endPoint: endPoint)
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
            Text(annotation.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, DS.Spacing.small)
                .padding(.vertical, DS.Spacing.extraSmall)
                .background(
                    RoundedRectangle(cornerRadius: DS.CornerRadius.chip, style: .continuous)
                        .fill(teachingInkColor)
                )
                .position(anchorPoint)
                .opacity(Double(drawOnProgress))
                .scaleEffect(0.9 + (0.1 * drawOnProgress))
        }
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
