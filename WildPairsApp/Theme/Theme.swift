import SwiftUI
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

    // MARK: Card dimensions (§6) — 2:3 ratio
    enum CardSize {
        static let compactHand = CGSize(width: 60, height: 90)
        static let regularHand = CGSize(width: 80, height: 120)
        static let selected = CGSize(width: 100, height: 150)
        static let opponentBack = CGSize(width: 44, height: 66)
        /// Smaller variants used when the table must fit a short landscape height
        /// (iPhone landscape, and any device where width vastly exceeds height).
        static let landscapeHand = CGSize(width: 50, height: 75)
        static let landscapeBack = CGSize(width: 30, height: 45)
    }

    // MARK: UI colours (§7)
    enum Palette {
        static let accent = Color.indigo
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let surface = Color(.secondarySystemBackground)
        static let background = Color(.systemBackground)
        // Table surface — the only non-system UI colour (light/dark variants).
        static let tableLight = Color(red: 0xF5/255, green: 0xF0/255, blue: 0xE8/255)
        static let tableDark = Color(red: 0x1C/255, green: 0x25/255, blue: 0x26/255)
    }

    // MARK: Animation (§12)
    enum Motion {
        static let cardPlay = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let fast = Animation.easeOut(duration: 0.15)
        static let moderate = Animation.easeInOut(duration: 0.5)
        static let deal = Animation.easeInOut(duration: 0.6)
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

    /// SF-symbol-free emblem drawn as a Shape elsewhere; this is the abbreviation label.
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

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
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
