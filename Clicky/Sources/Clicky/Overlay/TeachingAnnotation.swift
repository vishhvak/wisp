import Foundation
import CoreGraphics

// The kinds of teaching ink the AI can paint on the user's screen. These map to the `[DRAW:...]`
// and `[POINT:...]` tags Claude embeds inline in its responses. A single saturated red is used for
// all of them (per the tutor design language), and chip labels accumulate into a persistent legend.
enum TeachingAnnotationShape: Equatable {
    // A stroked rectangle outline highlighting a region (no fill).
    case rect(CGRect)
    // A stroked arrow from a start point to an end point.
    case arrow(from: CGPoint, to: CGPoint)
    // A small pixel-precise filled dot marking an exact point.
    case dot(CGPoint)
    // A white-on-red rounded chip label anchored at a point (the accumulating legend).
    case chip(CGPoint)
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
}
