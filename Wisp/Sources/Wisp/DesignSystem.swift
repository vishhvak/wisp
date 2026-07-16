import SwiftUI

// The design system holds every visual token used across Wisp's surfaces (cursor
// glyph, task cards, toasts, teaching overlay). Centralizing these values here means a
// single source of truth for the "relaunch" visual language documented in research/DESIGN.md,
// and lets any view refer to a named token instead of an inline literal.
enum DS {

    // MARK: - Colors
    // Every color is defined once, from the verified hex tokens in the design spec, so that
    // "listening blue" or "teach red" always means exactly the same value everywhere it appears.
    enum Colors {
        // Brand violet used for the menu-bar icon and brand accents.
        static let brand = Color(hex: "#7C5CFC")
        // The ~12px cursor-trailing glyph's default color while listening (mid-saturation system blue).
        static let listeningBlue = Color(hex: "#4C7CF5")
        // The ephemeral completion toast's iMessage-style blue fill.
        static let toastBlue = Color(hex: "#2F6FED")
        // Status-pill green for a finished / running-successfully task ("Done").
        static let doneGreen = Color(hex: "#34C759")
        // The single saturated red used for AI teaching ink (outlines, arrows, dots, chip labels).
        static let teachRed = Color(hex: "#FF3B30")
        // Mint-green used for the "build/change this" agent-intent draw mode.
        static let buildGreen = Color(hex: "#3ECC8E")
        // Coral/salmon used for the "tell me about this" conversational draw mode.
        static let askCoral = Color(hex: "#E8776B")
        // Dark charcoal background shared by the task card and other near-black surfaces.
        static let cardCharcoal = Color(hex: "#17161F")
        // Amber accent used for secondary highlights (e.g. a queued-agent status dot).
        static let amber = Color(hex: "#E0A23D")

        // Convenience text colors so card/toast copy reads consistently.
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.62)
        // Dim, small-caps section-label color ("SUGGESTED NEXT", "FOLLOW UP").
        static let sectionLabel = Color.white.opacity(0.42)
        // The dark-gray fill used by the capsule action pills inside a card, and its hover state.
        static let pillFill = Color.white.opacity(0.10)
        static let pillFillHover = Color.white.opacity(0.16)
        // The 1px inner stroke on dark surfaces — the ONE sanctioned border in the system.
        static let hairline = Color.white.opacity(0.08)
        // Glyph/text color on saturated accent fills (amber send button, green/blue status pills).
        // White fails contrast on these mid-lightness accents; near-black passes.
        static let onAccent = Color.black.opacity(0.8)
    }

    // MARK: - Corner Radius
    // Named radii keep every rounded surface visually consistent. Concentric rule everywhere:
    // outerRadius = innerRadius + gap. Nothing rectangular exceeds 24.
    enum CornerRadius {
        static let pill: CGFloat = 999          // fully-rounded capsule pills
        static let card: CGFloat = 18           // the top-right task card
        static let toast: CGFloat = 14          // the completion toast bubble
        static let field: CGFloat = 10          // composer input / drop-zone dashed rect
        static let chip: CGFloat = 6            // white-on-red teaching chip labels
        static let islandCompact: CGFloat = 13  // island bottom corners, compact presentation
        static let islandExpanded: CGFloat = 22 // island bottom corners, expanded/composer
    }

    // MARK: - Spacing
    // A small spacing scale so padding/gaps are chosen from a fixed set rather than ad hoc.
    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Motion
    // The motion vocabulary from DESIGN.md §4. State-conveying only; 150–250ms interactions; the
    // island's 500ms shape morph is the single deliberate exception. Exits are always faster and
    // softer than enters. Values derived from the researched motion corpus (see research notes).
    enum Motion {
        // Anything leaving the screen (toasts, swapped content out).
        static let exitFast = Animation.easeIn(duration: 0.15)
        // Standard state/feedback enters.
        static let enter = Animation.easeOut(duration: 0.20)
        // Content crossfading INSIDE a morphing container (incoming delayed 0.08s behind outgoing).
        static let swap = Animation.easeInOut(duration: 0.24)
        static let swapIncomingDelaySeconds: Double = 0.08
        // Island-content exit: ~80ms flat — content is "sucked into the pill" BEFORE the shell
        // morphs, so the geometry spring never drags half-visible text around.
        static let islandContentExit = Animation.linear(duration: 0.08)
        // Island geometry morphs — width/height/radius together on ONE spring, content separate.
        static let islandMorph = Animation.spring(duration: 0.5, bounce: 0.16)
        // Short snappy movement: pill layout shifts, magnet-style follows.
        static let snappy = Animation.spring(response: 0.30, dampingFraction: 0.9)
        // Press feedback pair: quick down to 0.96, springy release back to 1.0.
        static let pressDown = Animation.easeOut(duration: 0.10)
        static let pressUp = Animation.spring(response: 0.30, dampingFraction: 0.65)
        // Invalid-input shake: offset 6pt then spring to 0 on a loose, fast spring.
        static let shake = Animation.spring(response: 0.24, dampingFraction: 0.17)
        // The idle dot's luminosity cycle.
        static let breathe = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)
        // The agent pointer's bezier flight.
        static let glide = Animation.easeInOut(duration: 0.55)
    }
}

// MARK: - Press feedback

// The system-wide press feedback for pills and buttons: scale to exactly 0.96 while pressed
// (never deeper — below 0.95 reads as exaggerated), quick ease down, springy release. Applied as
// a ButtonStyle so every interactive capsule shares identical tactile behavior.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(configuration.isPressed ? DS.Motion.pressDown : DS.Motion.pressUp, value: configuration.isPressed)
    }
}

extension Color {
    // Builds a SwiftUI Color from a hex string like "#7C5CFC" or "7C5CFC". This exists so the
    // design tokens above can be written exactly as they appear in the design spec (as hex),
    // rather than being hand-converted to fractional RGB components that are hard to verify.
    init(hex hexString: String) {
        let sanitizedHexString = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var parsedRGBValue: UInt64 = 0
        Scanner(string: sanitizedHexString).scanHexInt64(&parsedRGBValue)

        let redComponent: Double
        let greenComponent: Double
        let blueComponent: Double
        let alphaComponent: Double

        switch sanitizedHexString.count {
        case 6:
            // "RRGGBB" — fully opaque.
            redComponent = Double((parsedRGBValue & 0xFF0000) >> 16) / 255.0
            greenComponent = Double((parsedRGBValue & 0x00FF00) >> 8) / 255.0
            blueComponent = Double(parsedRGBValue & 0x0000FF) / 255.0
            alphaComponent = 1.0
        case 8:
            // "RRGGBBAA" — explicit alpha.
            redComponent = Double((parsedRGBValue & 0xFF000000) >> 24) / 255.0
            greenComponent = Double((parsedRGBValue & 0x00FF0000) >> 16) / 255.0
            blueComponent = Double((parsedRGBValue & 0x0000FF00) >> 8) / 255.0
            alphaComponent = Double(parsedRGBValue & 0x000000FF) / 255.0
        default:
            // Unrecognized length — fall back to opaque black so a typo is visible, not silent.
            redComponent = 0
            greenComponent = 0
            blueComponent = 0
            alphaComponent = 1.0
        }

        self.init(
            .sRGB,
            red: redComponent,
            green: greenComponent,
            blue: blueComponent,
            opacity: alphaComponent
        )
    }
}
