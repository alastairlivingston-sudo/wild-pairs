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

    // MARK: Card dimensions (§6) — 2:3 ratio. Portrait-only; no landscape variants.
    enum CardSize {
        static let compactHand = CGSize(width: 60, height: 90)
        static let regularHand = CGSize(width: 80, height: 120)
        static let selected = CGSize(width: 100, height: 150)
        static let opponentBack = CGSize(width: 44, height: 66)
        /// Partner's open hand row — a glanceable strip, smaller than `compactHand` but large
        /// enough that the partner's card faces (numbers/symbols) are actually readable, which
        /// is the whole point of an open partner hand. (Was 30×45, too small to read.)
        static let partnerHand = CGSize(width: 38, height: 57)
        /// Table-centre draw pile back — smaller than the discard so the discard reads as the
        /// focal point (spec: discard 50px, draw-back 32px, ratio preserved here).
        static let tableDraw = CGSize(width: 38, height: 57)
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
        static let micro = Animation.easeOut(duration: 0.1)
        /// Per-card stagger delay used when dealing a hand; multiply by card index.
        static let dealStagger: Double = 0.06
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
            .background(RoundedRectangle(cornerRadius: Theme.Radius.r3).fill(Theme.Palette.surface.opacity(0.4)))
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
        case .crimson: return flame(in: rect)      // Fire
        case .cobalt: return wave(in: rect)         // Rain
        case .jade: return crystal(in: rect)        // Earth
        case .amber: return swirl(in: rect)         // Wind
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

    /// Earth: a faceted crystal/mountain — a hexagonal gem outline with internal facet lines.
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

    /// Wind: a gust/swirl — three concentric arcs sweeping outward, like a breeze curling.
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
    /// The card face base colour — elemental retheme (Fire/Rain/Earth/Wind, Phase 11 D):
    /// red→orange, deep-blue→cyan, green→stone, gold→grey, all scheme-independent (dark-first).
    func fillColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .crimson: return Color(hex: 0xE8431F)  // Fire: red-orange
        case .cobalt:  return Color(hex: 0x1B5FD9)  // Rain: deep blue
        case .jade:    return Color(hex: 0x2F8F5B)  // Earth: green-stone
        case .amber:   return Color(hex: 0xC9A227)  // Wind: gold-grey
        }
    }

    /// Brighter top-of-gradient stop for the card face, explicit neon highlight (not a white blend).
    func highlightColor(_ scheme: ColorScheme) -> Color {
        switch self {
        case .crimson: return Color(hex: 0xFF8A3D)  // Fire: orange
        case .cobalt:  return Color(hex: 0x4FD2F0)  // Rain: cyan
        case .jade:    return Color(hex: 0x8FAE99)  // Earth: stone grey-green
        case .amber:   return Color(hex: 0xD8C77E)  // Wind: pale gold-grey
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
        case .changeColour:  return "WILD"
        case .discardAll:    return "ALL"
        case .targetedDraw:  return "TD"
        case .forcedSwap:    return "SWAP"
        case .teamPlay:      return "TEAM"
        }
    }

    /// Short, human-readable name shown on action cards instead of the cryptic abbreviation
    /// (Phase 9 A3: "Draw +2" not "D2").
    var readableName: String {
        switch self {
        case .number(let v): return "\(v)"
        case .skip:          return "Skip"
        case .skipTwo:       return "Skip 2"
        case .reverse:       return "Reverse"
        case .drawTwo:       return "Draw +2"
        case .drawFour:      return "Draw +4"
        case .changeColour:  return "Wild"
        case .discardAll:    return "Discard All"
        case .targetedDraw:  return "Target"
        case .forcedSwap:    return "Swap"
        case .teamPlay:      return "Team"
        }
    }

    /// Centre glyph (SF Symbol) for action cards; numbers render the digit instead.
    var centerSymbol: String? {
        switch self {
        case .number:        return nil
        case .skip:          return "nosign"
        case .skipTwo:       return "nosign"
        case .reverse:       return "arrow.2.squarepath"
        case .drawTwo:       return "plus.rectangle.on.rectangle"
        case .drawFour:      return "plus.square.on.square"
        case .changeColour:  return "paintpalette.fill"
        case .discardAll:    return "trash.fill"
        case .targetedDraw:  return "scope"
        case .forcedSwap:    return "arrow.left.arrow.right"
        case .teamPlay:      return "person.2.fill"
        }
    }
}
