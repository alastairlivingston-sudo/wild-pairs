import SwiftUI
import UIKit
import WildPairsCore

// Design tokens from docs/design-system.md. Single source for colours, spacing, radius,
// elevation, and animation so views never hard-code visual values.

// MARK: - Reduced visual effects environment

/// Mirrors `UserSettings.reducedVisualEffects` into the environment so chrome that has no
/// direct line to `AppSettings` (button styles, decorative glows) can still respect it —
/// set once at the app root, read anywhere via `@Environment(\.reducedVisualEffects)`.
private struct ReducedVisualEffectsKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var reducedVisualEffects: Bool {
        get { self[ReducedVisualEffectsKey.self] }
        set { self[ReducedVisualEffectsKey.self] = newValue }
    }
}

enum Theme {

    /// The deck look. Phase 17: the pre-rendered "Solo" asset-pack art. Flip to `.inkFoil` to
    /// roll back to the Phase 16 procedural deck, or `.glossPrint` for the Phase 15c deck.
    static let activeCardSkin: CardSkin = .soloArt

    // MARK: Spacing (§4)
    enum Space {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 24
        static let s6: CGFloat = 32
        static let s8: CGFloat = 48
    }

    // MARK: Corner radius (§5)
    enum Radius {
        static let r1: CGFloat = 4
        static let r2: CGFloat = 8
        static let r3: CGFloat = 12
        static let r4: CGFloat = 16
        /// Card face corner radius (neon-final.html spec: 14, up from the general r3=12).
        static let card: CGFloat = 14
    }

    // MARK: Card dimensions (§6) — 2:3 ratio. iPhone is portrait-only; iPad adds landscape
    // (Phase 15) and uses the larger `pad*` tokens so the wide canvas actually fills.
    enum CardSize {
        static let compactHand = CGSize(width: 60, height: 90)
        static let regularHand = CGSize(width: 80, height: 120)
        static let selected = CGSize(width: 100, height: 150)
        /// iPad hand cards — bigger than `selected` so the hand reads as the protagonist on
        /// a 1024pt+ canvas instead of a phone hand marooned in felt.
        static let padHand = CGSize(width: 116, height: 174)
        static let padHandLarge = CGSize(width: 136, height: 204)
        /// iPad table-centre discard (draw back derives at 0.85×).
        static let padTableFocus = CGSize(width: 112, height: 168)
        /// iPad partner open-hand cards.
        static let padPartnerHand = CGSize(width: 66, height: 99)
        static let opponentBack = CGSize(width: 44, height: 66)
        /// Partner's open hand row — a glanceable strip, smaller than `compactHand` but large
        /// enough that the partner's card faces (numbers/symbols) are actually readable, which
        /// is the whole point of an open partner hand. (Was 30×45, too small to read.)
        static let partnerHand = CGSize(width: 38, height: 57)
        /// Table-centre draw pile back — smaller than the discard so the discard reads as the
        /// focal point (spec: discard 50px, draw-back 32px, ratio preserved here).
        static let tableDraw = CGSize(width: 38, height: 57)
        /// iPhone table-centre discard — the stage of the table (Phase 12b): larger than a
        /// hand card so the centre claims the mid-band instead of leaving dead felt.
        static let tableFocus = CGSize(width: 96, height: 144)
    }

    // MARK: Game-table composition
    // Project-aware tokens for the table redesign. These live in the existing Theme namespace
    // rather than introducing a parallel design-token type that could drift or collide.
    enum Table {
        static let edgeHUDHeight: CGFloat = 56
        static let compactEdgeHUDHeight: CGFloat = 50
        static let moveTimerWidth: CGFloat = 96
        static let compactMoveTimerWidth: CGFloat = 68
        static let moveTimerHeight: CGFloat = 42
        /// Physical separation between the face-down draw deck and the played-card pile.
        /// 24pt keeps the two hit targets visually distinct at iPhone size while preserving the
        /// existing centre-row fit; constrained layouts may reduce to Space.s4, never below 16pt.
        static let drawDiscardGap: CGFloat = Space.s5
        /// Resting direction orbit: always legible, always subordinate to the cards.
        static let directionOrbitRestOpacity: Double = 0.42
        /// Brief Reverse impact. The orbit may become dominant for less than a second, then settles.
        static let directionOrbitEventOpacity: Double = 0.78
        /// Compatibility alias for call sites that have not yet migrated.
        static let directionOrbitOpacity: Double = directionOrbitRestOpacity
        /// Width of the non-colour white bracket stroke used to identify the active seat.
        static let activeSeatBracketWidth: CGFloat = 2
        /// Maximum number of physical backs shown in an opponent fan. The count badge remains exact.
        static let visibleOpponentBacks = 5
    }

    // MARK: Elevation (§11) — one elevation level per element, never stacked.
    enum Elevation {
        struct Spec { let color: Color; let radius: CGFloat; let x: CGFloat; let y: CGFloat }
        static let flat = Spec(color: .clear, radius: 0, x: 0, y: 0)
        static let resting = Spec(color: .black.opacity(0.28), radius: 4, x: 0, y: 2)
        static let active = Spec(color: .black.opacity(0.38), radius: 10, x: 0, y: 4)
        static let floating = Spec(color: .black.opacity(0.45), radius: 18, x: 0, y: 6)
    }

    // MARK: Animation (§12)
    enum Motion {
        static let cardPlay = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let fast = Animation.easeOut(duration: 0.15)
        static let moderate = Animation.easeInOut(duration: 0.5)
        static let deal = Animation.easeInOut(duration: 0.6)
        static let playArc = Animation.spring(response: 0.35, dampingFraction: 0.75)
        static let draw = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let turnPass = Animation.easeInOut(duration: 0.3)
        static let celebration = Animation.spring(response: 0.6, dampingFraction: 0.65)
        static let cardSettle = Animation.spring(response: 0.24, dampingFraction: 0.74)
        static let reverseImpact = Animation.spring(response: 0.42, dampingFraction: 0.68)
        static let soloShout = Animation.spring(response: 0.34, dampingFraction: 0.62)
        static let roundScore = Animation.spring(response: 0.56, dampingFraction: 0.78)
        static let micro = Animation.easeOut(duration: 0.1)
        /// Per-card stagger delay used when dealing a hand; multiply by card index.
        static let dealStagger: Double = 0.06
        /// Played-card travel completes before the real discard settles into view.
        static let cardFlightDuration: Double = 0.46
        /// Penalty-draw cards should read as a sequence, not a simultaneous blur.
        static let drawFlightStagger: Double = 0.09
        static let drawFlightDuration: Double = 0.42
        /// Presentation-only hold times for one-shot table feedback. Rules and timers never depend
        /// on these values; centralising them keeps event rhythm consistent across phone and pad.
        static let seatCueDisplayDuration: TimeInterval = 1.10
        static let caughtPenaltyDisplayDuration: TimeInterval = 1.55
        static let soloShoutDisplayDuration: TimeInterval = 1.00
        static let actionConfirmationDisplayDuration: TimeInterval = 1.00
    }

    // MARK: UI colours (§7) + Felt palette (premium dark felt table surface)
    enum Palette {
        static let accent = Color(hex: 0x36E0C8) // neon teal accent
        static let onAccent = Color(hex: 0x04130F) // text/icon on accent
        static let teamA = Color(hex: 0x16E08A) // jade
        static let teamB = Color(hex: 0xFF2E63) // crimson
        static let success = Color(hex: 0x4CAF6D)
        static let warning = Color(hex: 0xE8A23D)
        static let error = Color(hex: 0xE5564B)
        static let surface = Color(.secondarySystemBackground)
        static let background = Color(.systemBackground)
        // Table surface — the only non-system UI colour (light/dark variants).
        static let tableLight = Color(red: 0xF5/255, green: 0xF0/255, blue: 0xE8/255)
        static let tableDark = Color(red: 0x1C/255, green: 0x25/255, blue: 0x26/255)
        static let cream = Color(hex: 0xEEF0FF) // neon ink
    }

    // MARK: Felt — neon field tokens (premium dark mood, dark-first)
    enum Felt {
        static let baseDark = Color(hex: 0x0D0820)
        static let baseDarkHighlight = Color(hex: 0x1A1242)
        static let baseLight = Color(hex: 0x0D0820)
        static let baseLightHighlight = Color(hex: 0x1A1242)
        static let vignette = Color.black.opacity(0.6)
        static let gold = Palette.accent
        static let cream = Palette.cream

        static func base(_ scheme: ColorScheme) -> Color { scheme == .dark ? baseDark : baseLight }
        static func highlight(_ scheme: ColorScheme) -> Color { scheme == .dark ? baseDarkHighlight : baseLightHighlight }
    }

    // MARK: Element scene palettes (Phase 12 Elemental Live, design-plan.md §2.1) — the table
    // scene re-tints to the active colour; menus and wild resolution use `neutral`.
    enum Element {
        struct ScenePalette: Equatable {
            let base: Color
            let auroraA: Color
            let auroraB: Color
            let glow: Color
        }

        static let neutral = ScenePalette(base: Felt.baseDark,
                                          auroraA: Palette.accent,
                                          auroraB: Color(hex: 0x7A5CFF),
                                          glow: Palette.accent)

        static func scene(for colour: CardColour?) -> ScenePalette {
            switch colour {
            case .crimson: return ScenePalette(base: Color(hex: 0x1F0A06), auroraA: Color(hex: 0xFF5A3C),
                                               auroraB: Color(hex: 0xFF8A5B), glow: Color(hex: 0xFF8A5B))
            case .cobalt:  return ScenePalette(base: Color(hex: 0x050F22), auroraA: Color(hex: 0x2F8BFF),
                                               auroraB: Color(hex: 0x4FD2F0), glow: Color(hex: 0x4FD2F0))
            case .jade:    return ScenePalette(base: Color(hex: 0x06190F), auroraA: Color(hex: 0x16E89A),
                                               auroraB: Color(hex: 0x3CFFB4), glow: Color(hex: 0x5EFFBF))
            case .amber:   return ScenePalette(base: Color(hex: 0x1C1405), auroraA: Color(hex: 0xFFC83D),
                                               auroraB: Color(hex: 0xFFE08A), glow: Color(hex: 0xFFD34D))
            case nil:      return neutral
            }
        }
    }
}

// MARK: - Glass surface (design-plan.md §2.2) — the single chrome recipe: material base,
// dark wash, top-lit rim, optional element tint. Reduced Visual Effects swaps the material
// for a flat dark fill so no blur or transparency remains.

struct GlassSurface: ViewModifier {
    let shape: AnyShape
    var tint: Color? = nil
    @Environment(\.reducedVisualEffects) private var reducedVisualEffects

    func body(content: Content) -> some View {
        content
            .background {
                if reducedVisualEffects {
                    shape.fill(Color.black.opacity(0.45))
                } else {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(Color.black.opacity(0.25))
                    }
                }
            }
            .overlay {
                shape.stroke(
                    LinearGradient(
                        colors: [(tint ?? .white).opacity(tint == nil ? 0.26 : 0.5),
                                 (tint ?? .white).opacity(tint == nil ? 0.06 : 0.16)],
                        startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
            }
            .shadow(color: Theme.Elevation.resting.color, radius: Theme.Elevation.resting.radius,
                    x: Theme.Elevation.resting.x, y: Theme.Elevation.resting.y)
    }
}

extension View {
    func wpGlass(cornerRadius: CGFloat = Theme.Radius.r4, tint: Color? = nil) -> some View {
        modifier(GlassSurface(shape: AnyShape(RoundedRectangle(cornerRadius: cornerRadius)), tint: tint))
    }
    func wpGlassCapsule(tint: Color? = nil) -> some View {
        modifier(GlassSurface(shape: AnyShape(Capsule()), tint: tint))
    }
    func wpGlassCircle(tint: Color? = nil) -> some View {
        modifier(GlassSurface(shape: AnyShape(Circle()), tint: tint))
    }
}

// MARK: - Button styles (§9)

struct PrimaryButtonStyle: ButtonStyle {
    var glow: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.reducedVisualEffects) private var reducedVisualEffects

    func makeBody(configuration: Configuration) -> some View {
        let glowEnabled = glow && !reduceMotion && !reducedVisualEffects
        configuration.label
            .font(.body.weight(.semibold))
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Theme.Palette.onAccent)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.r2)
                    .fill(Theme.Palette.accent.opacity(configuration.isPressed ? 0.8 : 1))
            )
            .shadow(color: glowEnabled ? Theme.Palette.accent.opacity(0.5) : .clear, radius: 14)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Theme.Palette.accent)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.r2)
                    .strokeBorder(Theme.Palette.accent, lineWidth: 1.5)
                    .opacity(configuration.isPressed ? 0.6 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .frame(minHeight: 44)
            .foregroundStyle(Theme.Palette.accent.opacity(configuration.isPressed ? 0.6 : 1))
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.r2)
                    .fill(Theme.Palette.error.opacity(configuration.isPressed ? 0.8 : 1))
            )
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var wpPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
extension ButtonStyle where Self == SecondaryButtonStyle {
    static var wpSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
extension ButtonStyle where Self == GhostButtonStyle {
    static var wpGhost: GhostButtonStyle { GhostButtonStyle() }
}
extension ButtonStyle where Self == DestructiveButtonStyle {
    static var wpDestructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

/// Glass menu button (design-plan.md §3.2) — replaces the outline secondary style on menu
/// screens so secondary actions sit on the same chrome recipe as the rest of the HUD.
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Theme.Palette.cream)
            .wpGlass(cornerRadius: Theme.Radius.r2)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var wpGlassButton: GlassButtonStyle { GlassButtonStyle() }
}

/// Press-scale for the elemental colour-picker tiles (Phase 11 B) — same press feedback
/// language as the pill buttons, applied to a square swatch instead.
struct ElementTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(Theme.Motion.micro, value: configuration.isPressed)
    }
}

// MARK: - Neon segmented control (Phase 10) — uppercase tracked label, surface track,
// equal-width teal-filled pill on the selected option. Replaces `Form`/`Picker` on the
// New Game screen.

struct NeonSegmented<T: Hashable>: View {
    let title: String
    let options: [(value: T, label: String)]
    @Binding var selection: T
    var blurb: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text(title.uppercased())
                .font(.caption2).fontWeight(.bold).tracking(1)
                .foregroundStyle(.secondary)
            HStack(spacing: Theme.Space.s1) {
                ForEach(options, id: \.value) { option in
                    let isSelected = option.value == selection
                    Button { selection = option.value } label: {
                        Text(option.label)
                            .font(.caption).fontWeight(.bold)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Space.s2)
                            .foregroundStyle(isSelected ? Theme.Palette.onAccent : Theme.Palette.cream.opacity(0.65))
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.r2)
                                    .fill(isSelected ? Theme.Palette.accent : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(Theme.Space.s1)
            .wpGlass(cornerRadius: Theme.Radius.r3)
            if let blurb {
                Text(blurb).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Bespoke suit symbols (§10) — Flame/Wave/Leaf/Sun drawn as Path shapes, no SF Symbols.

struct SuitSymbolShape: Shape {
    let colour: CardColour

    func path(in rect: CGRect) -> Path {
        switch colour {
        case .crimson: return flame(in: rect)      // Lava
        case .cobalt: return wave(in: rect)         // Sky
        case .jade: return crystal(in: rect)        // Grass
        case .amber: return swirl(in: rect)         // Sun
        }
    }

    private func flame(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.62),
                      control1: CGPoint(x: rect.minX + w * 0.95, y: rect.minY + h * 0.2),
                      control2: CGPoint(x: rect.minX + w * 0.95, y: rect.minY + h * 0.45))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h),
                      control1: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.85),
                      control2: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + h))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.62),
                      control1: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h),
                      control2: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.85))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY),
                      control1: CGPoint(x: rect.minX + w * 0.05, y: rect.minY + h * 0.45),
                      control2: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + h * 0.18))
        path.closeSubpath()
        // inner flame curl
        path.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.42))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 0.78),
                      control1: CGPoint(x: rect.minX + w * 0.68, y: rect.minY + h * 0.55),
                      control2: CGPoint(x: rect.minX + w * 0.66, y: rect.minY + h * 0.68))
        return path
    }

    private func wave(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let midY = rect.minY + h * 0.42
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: midY),
                      control1: CGPoint(x: rect.minX + w * 0.15, y: midY - h * 0.28),
                      control2: CGPoint(x: rect.minX + w * 0.35, y: midY + h * 0.28))
        path.addCurve(to: CGPoint(x: rect.minX + w, y: midY),
                      control1: CGPoint(x: rect.minX + w * 0.65, y: midY - h * 0.28),
                      control2: CGPoint(x: rect.minX + w * 0.85, y: midY + h * 0.28))
        let lowY = rect.minY + h * 0.74
        path.move(to: CGPoint(x: rect.minX, y: lowY))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: lowY),
                      control1: CGPoint(x: rect.minX + w * 0.15, y: lowY - h * 0.2),
                      control2: CGPoint(x: rect.minX + w * 0.35, y: lowY + h * 0.2))
        path.addCurve(to: CGPoint(x: rect.minX + w, y: lowY),
                      control1: CGPoint(x: rect.minX + w * 0.65, y: lowY - h * 0.2),
                      control2: CGPoint(x: rect.minX + w * 0.85, y: lowY + h * 0.2))
        return path
    }

    /// Grass: a faceted crystal/mountain — a hexagonal gem outline with internal facet lines.
    private func crystal(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let top = CGPoint(x: rect.minX + w * 0.5, y: rect.minY)
        let upperLeft = CGPoint(x: rect.minX, y: rect.minY + h * 0.36)
        let upperRight = CGPoint(x: rect.minX + w, y: rect.minY + h * 0.36)
        let lowerLeft = CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.7)
        let lowerRight = CGPoint(x: rect.minX + w * 0.78, y: rect.minY + h * 0.7)
        let bottom = CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h)
        path.move(to: top)
        path.addLine(to: upperRight)
        path.addLine(to: lowerRight)
        path.addLine(to: bottom)
        path.addLine(to: lowerLeft)
        path.addLine(to: upperLeft)
        path.closeSubpath()
        // facet lines
        path.move(to: top); path.addLine(to: bottom)
        path.move(to: upperLeft); path.addLine(to: lowerRight)
        path.move(to: upperRight); path.addLine(to: lowerLeft)
        return path
    }

    /// Sun: a gust/swirl — three concentric arcs sweeping outward, like a breeze curling.
    private func swirl(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) * 0.46
        for i in 0..<3 {
            let radius = maxRadius * (0.45 + 0.28 * Double(i))
            let startAngle = Angle(degrees: -130 + Double(i) * 12)
            let endAngle = Angle(degrees: 110 - Double(i) * 18)
            path.addArc(center: center, radius: radius, startAngle: startAngle,
                        endAngle: endAngle, clockwise: false)
        }
        return path
    }
}

/// Convenience view wrapping `SuitSymbolShape` with stroke styling matching SF Symbol "regular" weight.
struct SuitSymbol: View {
    let colour: CardColour
    var lineWidth: CGFloat = 1.6

    var body: some View {
        SuitSymbolShape(colour: colour)
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - Game colour → SwiftUI Color (§7, light/dark adjusted)

extension CardColour {
    /// The card face base colour — elemental retheme (Lava/Sky/Grass/Sun display names, Phase 11 D):
    /// red→orange, deep-blue→cyan, green→stone, gold→grey, all scheme-independent (dark-first).
    func fillColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .crimson: return Color(hex: 0xE8431F)  // Lava: red-orange
        case .cobalt:  return Color(hex: 0x1B5FD9)  // Sky: deep blue
        case .jade:    return Color(hex: 0x2F8F5B)  // Grass: green-stone
        case .amber:   return Color(hex: 0xC9A227)  // Sun: gold-grey
        }
    }

    /// Brighter top-of-gradient stop for the card face, explicit neon highlight (not a white blend).
    func highlightColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .crimson: return Color(hex: 0xFF8A3D)  // Lava: orange
        case .cobalt:  return Color(hex: 0x4FD2F0)  // Sky: cyan
        case .jade:    return Color(hex: 0x8FAE99)  // Grass: stone grey-green
        case .amber:   return Color(hex: 0xD8C77E)  // Sun: pale gold-grey
        }
    }

    /// SF-symbol name kept only as a VoiceOver/legacy fallback; visuals use `SuitSymbol`.
    var symbolName: String {
        switch self {
        case .crimson: return "flame.fill"
        case .cobalt:  return "water.waves"
        case .jade:    return "mountain.2.fill"
        case .amber:   return "wind"
        }
    }

    /// Plain-English symbol name for VoiceOver (elemental retheme, Phase 11 D): "Flame"/"Wave"/
    /// "Crystal"/"Gust", as opposed to `symbolName`'s SF Symbol identifier.
    var symbolDisplayName: String {
        switch self {
        case .crimson: return "Flame"
        case .cobalt:  return "Wave"
        case .jade:    return "Crystal"
        case .amber:   return "Gust"
        }
    }
}

// MARK: - Color helpers

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Blends this colour toward another by `amount` (0 = self, 1 = target), in sRGB space.
    /// Used for gradient highlights on card faces without introducing new asset colours.
    func blended(toward target: Color, amount: Double) -> Color {
        let a = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let b = UIColor(target).cgColor.components ?? [1, 1, 1, 1]
        func component(_ i: Int) -> Double {
            let av = a.count > i ? Double(a[i]) : Double(a[0])
            let bv = b.count > i ? Double(b[i]) : Double(b[0])
            return av + (bv - av) * amount
        }
        if a.count >= 3 {
            return Color(red: component(0), green: component(1), blue: component(2))
        }
        return self
    }
}

// MARK: - Card type display helpers (UI copy)

extension CardType {
    /// Short corner abbreviation shown on a card (e.g. "SKIP", "D2", "WILD").
    var abbreviation: String {
        switch self {
        case .number(let v): return "\(v)"
        case .skip:          return "SKIP"
        case .skipTwo:       return "SK2"
        case .reverse:       return "REV"
        case .drawTwo:       return "D2"
        case .drawFour:      return "D4"
        case .drawEight:     return "D8"
        case .changeColour:  return "WILD"
        case .discardAll:    return "ALL"
        case .discardColour: return "BURST"
        case .targetedDraw:  return "TD"
        case .forcedSwap:    return "SWAP"
        case .teamPlay:      return "TEAM"
        }
    }

}
