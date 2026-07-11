import SwiftUI
import WildPairsCore

// MARK: - Card skin swap seam
//
// A deck restyle touches exactly three things: add a `case` here, add a matching `XyzFace`
// view (consuming CardFaceContext + the shared glyph shapes in CardView.swift), and flip
// `Theme.activeCardSkin`. Nothing else in the app knows what a card looks like.
//
// To commission a new skin from a design tool, feed it one self-contained HTML prototype in
// the docs/phase-16-design format (see 00-brief.md for the mandatory reference state and the
// hard constraints), then translate its token sheet into a new `XyzTokens` + `XyzFace`.

enum CardSkin {
    case glossPrint   // Phase 15c photoreal gloss-print deck
    case inkFoil      // Phase 16 black-glass "Ink & Foil" deck
    case soloArt      // Phase 17 pre-rendered "Solo" asset-pack art (SoloCards.xcassets)
}

/// Everything a skin needs to render one card face. Skin-independent shell concerns (playable
/// ring, selection scale, shadows, accessibility) stay in CardView and are not passed here.
struct CardFaceContext {
    let card: Card
    let size: CGSize
    let showColourName: Bool
    let showPattern: Bool
    /// A resolved wild reprints in its chosen colour; nil renders the unresolved wild.
    let wildTint: CardColour?
    let reducedMotion: Bool
    let scheme: ColorScheme

    /// The colour the face prints in — the card's own, or a resolved wild's chosen tint.
    var displayColour: CardColour? { card.colour ?? wildTint }
    var isWild: Bool { card.colour == nil }
    /// Real playing cards show both corner indices once large enough to render them legibly.
    var showSecondCorner: Bool { size.width >= 46 }
}

// MARK: - Ink & Foil tokens
//
// The design tokens for the Ink & Foil skin, lifted from
// docs/phase-16-design/05-ink-and-foil.html. Foil is a three-stop gradient per suit; the
// "glow" colour is the light index/emboss tint. Wilds foil in the full four-colour set.

enum InkFoil {
    static let stockTop = Color(hex: 0x16121E)
    static let stockBottom = Color(hex: 0x0D0A13)
    static let rim = Color.white.opacity(0.08)

    /// Three-stop foil gradient stops for a suit (light → base → light), matching the prototype.
    static func foilStops(_ colour: CardColour) -> [Color] {
        switch colour {
        case .crimson: return [Color(hex: 0xFF8A3D), Color(hex: 0xE8431F), Color(hex: 0xFF8A3D)]
        case .cobalt:  return [Color(hex: 0x4FD2F0), Color(hex: 0x1B5FD9), Color(hex: 0x4FD2F0)]
        case .jade:    return [Color(hex: 0x5ADF9B), Color(hex: 0x2F8F5B), Color(hex: 0x8FAE99)]
        case .amber:   return [Color(hex: 0xFFE08A), Color(hex: 0xC9A227), Color(hex: 0xFFE08A)]
        }
    }

    /// The light index / emboss / glow tint for a suit.
    static func glow(_ colour: CardColour) -> Color {
        switch colour {
        case .crimson: return Color(hex: 0xFF8A3D)
        case .cobalt:  return Color(hex: 0x4FD2F0)
        case .jade:    return Color(hex: 0x5ADF9B)
        case .amber:   return Color(hex: 0xFFE08A)
        }
    }

    /// A suit's foil as a diagonal linear gradient (≈120° sheen).
    static func foil(_ colour: CardColour) -> LinearGradient {
        LinearGradient(colors: foilStops(colour), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The four-colour foil used by wilds (Change Colour, Draw Four, Discard All).
    static var wildFoil: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xFF8A3D), Color(hex: 0x4FD2F0),
                                Color(hex: 0x5ADF9B), Color(hex: 0xFFE08A)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var wildConic: AngularGradient {
        AngularGradient(colors: [Color(hex: 0xFF8A3D), Color(hex: 0x4FD2F0),
                                 Color(hex: 0x5ADF9B), Color(hex: 0xFFE08A), Color(hex: 0xFF8A3D)],
                        center: .center)
    }
}
