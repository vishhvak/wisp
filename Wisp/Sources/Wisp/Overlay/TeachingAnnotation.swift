import Foundation
import CoreGraphics

// The kinds of teaching ink the AI can paint on the user's screen. These map to the shipped app's
// pointing vocabulary — `[TARGET:x,y,r]`, `[HOVER:x,y,r]`, `[HIGHLIGHT:x,y,w,h]`, `[SHAPE:arrow]`,
// `[SHAPE:curve]`, plus legacy `[POINT]`/`[DRAW]` tags Claude embeds inline in its responses. A
// single saturated red is used for all of them (per the tutor design language), and chip labels
// accumulate into a persistent legend.
enum TeachingAnnotationShape: Equatable {
    // A stroked rectangle outline highlighting a region (no fill). Used by [HIGHLIGHT] and [DRAW:rect].
    case rect(CGRect)
    // A stroked arrow from a start point to an end point. Used by [SHAPE:arrow] and [DRAW:arrow].
    case arrow(from: CGPoint, to: CGPoint)
    // A quadratic bezier curve with an arrowhead at its end. Used by [SHAPE:curve].
    case curve(from: CGPoint, control: CGPoint, to: CGPoint)
    // A small pixel-precise filled dot marking an exact point. Used by [DRAW:dot].
    case dot(CGPoint)
    // A white-on-red rounded chip label anchored at a point (the accumulating legend). Used by [POINT].
    case chip(CGPoint)
    // A solid ring + center dot marking the single observable next action to take. Used by [TARGET].
    case target(center: CGPoint, radius: CGFloat)
    // A dashed ring indicating an element to hover (a lighter-weight pointer than target). Used by [HOVER].
    case hover(center: CGPoint, radius: CGFloat)
}

// One piece of teaching ink to render in the overlay. `label` is the optional text shown by a chip
// (and used as an accessibility description for the other shapes). Coordinates are in the overlay's
// top-left-origin coordinate space (already mapped from screen coordinates by the caller).
struct TeachingAnnotation: Identifiable, Equatable {
    let id: UUID
    var shape: TeachingAnnotationShape
    var label: String

    // Which display this annotation belongs to (parsed from the `screenN` field of a tag), so the
    // overlay can route it to the correct monitor. Defaults to the main display (index 0).
    var displayIndex: Int

    init(
        id: UUID = UUID(),
        shape: TeachingAnnotationShape,
        label: String = "",
        displayIndex: Int = 0
    ) {
        self.id = id
        self.shape = shape
        self.label = label
        self.displayIndex = displayIndex
    }

    // The single point that best represents "where this annotation is" — the destination the agent
    // pointer glides to just before the ink appears. Arrows and curves anchor at their TIP (that's
    // what they're pointing at); rects at their center.
    var anchorPoint: CGPoint {
        switch shape {
        case .rect(let rectangle):
            return CGPoint(x: rectangle.midX, y: rectangle.midY)
        case .arrow(_, let tipPoint):
            return tipPoint
        case .curve(_, _, let tipPoint):
            return tipPoint
        case .dot(let point), .chip(let point):
            return point
        case .target(let centerPoint, _), .hover(let centerPoint, _):
            return centerPoint
        }
    }
}
