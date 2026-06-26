import SwiftUI
import UIKit
import WildPairsCore

// Design tokens from docs/design-system.md. Single source for colours, spacing, radius,
// elevation, and animation so views never hard-code visual values.

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
    }

    // MARK: Card dimensions (§6) — 2:3 ratio. Portrait-only; no landscape variants.
    enum CardSize {
        static let compactHand = CGSize(width: 60, height: 90)
        static let regularHand = CGSize(width: 80, height: 120)
        static let selected = CGSize(width: 100, height: 150)
        static let opponentBack = CGSize(width: 44, height: 66)
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
        static let accent = Color(hex: 0xD9B872) // warm gold accent over felt
        static let success = Color(hex: 0x4CAF6D)
        static let warning = Color(hex: 0xE8A23D)
        static let error = Color(hex: 0xE5564B)
        static let surface = Color(.secondarySystemBackground)
        static let background = Color(.systemBackground)
        // Table surface — the only non-system UI colour (light/dark variants).
        static let tableLight = Color(red: 0xF5/255, green: 0xF0/255, blue: 0xE8/255)
        static let tableDark = Color(red: 0x1C/255, green: 0x25/255, blue: 0x26/255)
        static let cream = Color(hex: 0xF3ECD9)
    }

    // MARK: Felt — deep teal/green table texture tokens (premium dark mood, dark-first)
    enum Felt {
        static let baseDark = Color(hex: 0x0B2C26)
        static let baseDarkHighlight = Color(hex: 0x163F35)
        static let baseLight = Color(hex: 0x1F5C4B)
        static let baseLightHighlight = Color(hex: 0x2C7A63)
        static let vignette = Color.black.opacity(0.55)
        static let gold = Palette.accent
        static let cream = Palette.cream

        static func base(_ scheme: ColorScheme) -> Color { scheme == .dark ? baseDark : baseLight }
        static func highlight(_ scheme: ColorScheme) -> Color { scheme == .dark ? baseDarkHighlight : baseLightHighlight }
    }
}

// MARK: - Button styles (§9)

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Color(hex: 0x0B2C26))
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.r2)
                    .fill(Theme.Palette.accent.opacity(configuration.isPressed ? 0.8 : 1))
            )
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

// MARK: - Bespoke suit symbols (§10) — Flame/Wave/Leaf/Sun drawn as Path shapes, no SF Symbols.

struct SuitSymbolShape: Shape {
    let colour: CardColour

    func path(in rect: CGRect) -> Path {
        switch colour {
        case .crimson: return flame(in: rect)
        case .cobalt: return wave(in: rect)
        case .jade: return leaf(in: rect)
        case .amber: return sun(in: rect)
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

    private func leaf(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        path.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h),
                      control1: CGPoint(x: rect.minX + w, y: rect.minY + h * 0.3),
                      control2: CGPoint(x: rect.minX + w, y: rect.minY + h * 0.75))
        path.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY),
                      control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.75),
                      control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.3))
        path.closeSubpath()
        // central vein
        path.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY + h * 0.92))
        return path
    }

    private func sun(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let coreRadius = min(rect.width, rect.height) * 0.26
        path.addEllipse(in: CGRect(x: center.x - coreRadius, y: center.y - coreRadius,
                                    width: coreRadius * 2, height: coreRadius * 2))
        let rayInner = coreRadius * 1.35
        let rayOuter = min(rect.width, rect.height) * 0.5
        for i in 0..<8 {
            let angle = Double(i) / 8 * 2 * .pi
            let dx = cos(angle), dy = sin(angle)
            path.move(to: CGPoint(x: center.x + dx * rayInner, y: center.y + dy * rayInner))
            path.addLine(to: CGPoint(x: center.x + dx * rayOuter, y: center.y + dy * rayOuter))
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
    /// The card face colour. Lightened ~10% in dark mode per the design system.
    func fillColor(_ scheme: ColorScheme) -> Color {
        switch (self, scheme) {
        case (.crimson, .dark): return Color(hex: 0xE74C3C)
        case (.crimson, _):     return Color(hex: 0xC0392B)
        case (.cobalt, .dark):  return Color(hex: 0x2E86C1)
        case (.cobalt, _):      return Color(hex: 0x2471A3)
        case (.jade, .dark):    return Color(hex: 0x27AE60)
        case (.jade, _):        return Color(hex: 0x1E8449)
        case (.amber, .dark):   return Color(hex: 0xF1C40F)
        case (.amber, _):       return Color(hex: 0xD4AC0D)
        }
    }

    /// Lighter variant of `fillColor` used for the top-down gradient highlight on card faces.
    func highlightColor(_ scheme: ColorScheme) -> Color {
        fillColor(scheme).opacity(0.78).blended(toward: .white, amount: 0.22)
    }

    /// SF-symbol name kept only as a VoiceOver/legacy fallback; visuals use `SuitSymbol`.
    var symbolName: String {
        switch self {
        case .crimson: return "flame.fill"
        case .cobalt:  return "water.waves"
        case .jade:    return "leaf.fill"
        case .amber:   return "sun.max.fill"
        }
    }

    /// Plain-English symbol name for VoiceOver (CLAUDE.md colour table): "Flame"/"Wave"/
    /// "Leaf"/"Sun", as opposed to `symbolName`'s SF Symbol identifier.
    var symbolDisplayName: String {
        switch self {
        case .crimson: return "Flame"
        case .cobalt:  return "Wave"
        case .jade:    return "Leaf"
        case .amber:   return "Sun"
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
