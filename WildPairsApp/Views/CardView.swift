import SwiftUI
import WildPairsCore

// A single playing card (§6 structure). Layered gradient face with depth, bespoke suit
// symbols, a large legible centre glyph + readable action name, and an optional colour-name
// label for colour-blind mode. Always shows its suit symbol so the design is colour-blind
// safe by default (§8).

struct CardView: View {
    let card: Card
    var size: CGSize = Theme.CardSize.regularHand
    var isPlayable: Bool = false
    var isSelected: Bool = false
    var showColourName: Bool = false
    var showPattern: Bool = false
    /// Only the local human's own hand should announce playability/"double tap to select" —
    /// partner's open hand and the discard pile's top card are informational, not actionable.
    var announcePlayability: Bool = false
    var reducedMotion: Bool = false

    @Environment(\.colorScheme) private var scheme

    /// Wild cards get a dark, high-contrast plum face instead of vanishing against the felt
    /// (design-system A3: "near-invisible white wild cards" was the bug being fixed here).
    private var faceColor: Color {
        card.colour?.fillColor(scheme) ?? Color(hex: 0x2A1F3D)
    }
    private var faceHighlight: Color {
        card.colour?.highlightColor(scheme) ?? Color(hex: 0x44345E)
    }
    private var inkColor: Color { .white }
    /// Real playing cards show both corner indices (neon-final.html spec: top-left + mirrored
    /// bottom-right) at any size large enough to render them legibly.
    private var showSecondCorner: Bool { size.width >= 46 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(colors: [faceHighlight, faceColor],
                                   startPoint: .top, endPoint: .bottom)
                )
            if showPattern, let colour = card.colour {
                CardPatternFill(colour: colour)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            // Large faint suit watermark behind the centre glyph.
            if let colour = card.colour {
                SuitSymbol(colour: colour, lineWidth: size.width * 0.03)
                    .frame(width: size.width * 0.62, height: size.width * 0.62)
                    .opacity(0.16)
            }
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(borderColor, lineWidth: isPlayable ? 3 : 1.5)
            // Inner light border for depth.
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                .padding(1.5)
            // Gloss highlight (neon-final.html spec: `inset 0 0 12px white15`) — a soft sheen
            // across the top half of the face, distinct from the depth border above.
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(colors: [.white.opacity(0.16), .clear],
                                   startPoint: .top, endPoint: .center)
                )
                .blendMode(.plusLighter)

            VStack {
                corner(alignment: .leading)
                Spacer()
                centre
                Spacer()
                if showSecondCorner {
                    corner(alignment: .trailing).rotationEffect(.degrees(180))
                }
            }
            .padding(size.width * 0.08)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        .scaleEffect((isSelected || isPlayable) ? 1.07 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(announcePlayability ? (isPlayable ? "Double tap to select" : "Double tap for more information") : "")
        .accessibilityAddTraits(isPlayable ? .isButton : [])
    }

    private func corner(alignment: HorizontalAlignment) -> some View {
        HStack {
            if alignment == .trailing { Spacer() }
            VStack(alignment: alignment == .leading ? .leading : .trailing, spacing: 1) {
                if let colour = card.colour {
                    SuitSymbol(colour: colour, lineWidth: size.width * 0.018)
                        .frame(width: size.width * 0.16, height: size.width * 0.16)
                }
                Text(cornerLabel)
                    .font(.system(size: max(9, size.width * 0.16), weight: .bold))
                    .minimumScaleFactor(0.7)
            }
            if alignment == .leading { Spacer() }
        }
        .foregroundStyle(inkColor)
    }

    /// Numbers keep the digit; action cards show the readable name so the card is
    /// self-explanatory without decoding an abbreviation (A3).
    private var cornerLabel: String {
        if case .number(let v) = card.type { return "\(v)" }
        return card.type.abbreviation
    }

    @ViewBuilder private var centre: some View {
        VStack(spacing: Theme.Space.s1) {
            if case .number(let v) = card.type {
                Text("\(v)").font(.system(size: size.height * 0.42, weight: .bold))
            } else {
                if let symbol = card.type.centerSymbol {
                    Image(systemName: symbol).font(.system(size: size.height * 0.26, weight: .semibold))
                }
                Text(card.type.readableName)
                    .font(.system(size: max(9, size.height * 0.1), weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            if showColourName, let colour = card.colour {
                Text(colour.displayName.uppercased())
                    .font(.caption2).fontWeight(.semibold)
                    .minimumScaleFactor(0.7)
            }
        }
        .foregroundStyle(inkColor)
    }

    private var borderColor: Color {
        if isPlayable { return Theme.Palette.accent }
        return .white.opacity(card.isWild ? 0.35 : 0.5)
    }

    /// Suit-coloured glow on playable/selected cards; falls back to a subtle resting shadow
    /// (and under Reduced Visual Effects, since glow is a pure decoration with no information).
    private var hasGlow: Bool { (isPlayable || isSelected) && !reducedMotion }
    private var shadowColor: Color { hasGlow ? faceHighlight.opacity(0.55) : .black.opacity(isSelected ? 0.45 : 0.32) }
    private var shadowRadius: CGFloat { hasGlow ? (isSelected ? 14 : 10) : (isSelected ? 10 : 4) }
    private var shadowY: CGFloat { hasGlow ? 0 : (isSelected ? 4 : 2) }

    // Follows the canonical pattern from accessibility-plan.md §2: colour + name, card
    // category, a one-sentence description for action/wild cards, then playability.
    private var accessibilityLabel: String {
        let colour = card.colour?.displayName ?? "Wild"
        let pattern = (showPattern && !card.isWild) ? ", \(card.colour?.patternName ?? "") pattern" : ""
        let playable = announcePlayability ? (isPlayable ? " Playable." : " Not playable.") : ""

        switch card.type {
        case .number(let v):
            return "\(colour) \(Self.numberWords[v] ?? "\(v)"), number card.\(pattern)\(playable)"
        default:
            let description = card.type.accessibilityDescription
            if card.isWild {
                return "\(card.type.spokenName), wild card. \(description) Plays on any colour.\(playable)"
            }
            return "\(colour) \(card.type.spokenName), action card.\(pattern) \(description)\(playable)"
        }
    }

    private static let numberWords = [
        0: "Zero", 1: "One", 2: "Two", 3: "Three", 4: "Four",
        5: "Five", 6: "Six", 7: "Seven", 8: "Eight", 9: "Nine",
    ]
}

extension CardType {
    var spokenName: String {
        switch self {
        case .number(let v): return "\(v)"
        case .skip: return "Skip"
        case .skipTwo: return "Skip Two"
        case .reverse: return "Reverse"
        case .drawTwo: return "Draw Two"
        case .drawFour: return "Draw Four"
        case .changeColour: return "Change Colour"
        case .discardAll: return "Discard All"
        case .targetedDraw: return "Targeted Draw"
        case .forcedSwap: return "Forced Swap"
        case .teamPlay: return "Team Play"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .number: return ""
        case .skip: return "Skips the next player's turn."
        case .skipTwo: return "Skips the next two players' turns."
        case .reverse: return "Reverses the direction of play."
        case .drawTwo: return "The next player draws two cards and loses their turn."
        case .drawFour: return "The next player draws four cards and loses their turn."
        case .changeColour: return "Lets you choose a new colour for all players."
        case .discardAll: return "Discard all cards of a chosen colour from your hand."
        case .targetedDraw: return "Choose a player to draw cards."
        case .forcedSwap: return "Swap your hand with any other player."
        case .teamPlay: return "Invite your partner to play next."
        }
    }
}

// A colour-blind-mode texture overlay, rendered at 30% opacity so it adds tactile
// distinction without obscuring the card content beneath (design-system.md §8).
struct CardPatternFill: View {
    let colour: CardColour

    var body: some View {
        Canvas { context, size in
            switch colour {
            case .crimson: drawDiagonalLines(context: context, size: size)
            case .cobalt: drawHorizontalLines(context: context, size: size)
            case .jade: drawVerticalLines(context: context, size: size)
            case .amber: drawDotGrid(context: context, size: size)
            }
        }
        .opacity(0.3)
        .allowsHitTesting(false)
    }

    private func drawHorizontalLines(context: GraphicsContext, size: CGSize) {
        var y: CGFloat = 0
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.white), lineWidth: 1)
            y += 4
        }
    }

    private func drawVerticalLines(context: GraphicsContext, size: CGSize) {
        var x: CGFloat = 0
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(.white), lineWidth: 1)
            x += 4
        }
    }

    private func drawDiagonalLines(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 4
        var offset: CGFloat = -size.height
        while offset < size.width {
            var path = Path()
            path.move(to: CGPoint(x: offset, y: size.height))
            path.addLine(to: CGPoint(x: offset + size.height, y: 0))
            context.stroke(path, with: .color(.white), lineWidth: 1)
            offset += spacing
        }
    }

    private func drawDotGrid(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 6
        var y: CGFloat = spacing / 2
        while y < size.height {
            var x: CGFloat = spacing / 2
            while x < size.width {
                let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                context.fill(Path(ellipseIn: rect), with: .color(.white))
                x += spacing
            }
            y += spacing
        }
    }
}

extension CardColour {
    /// Colour-blind pattern names, kept distinct per element (CLAUDE.md colour-blind table).
    var patternName: String {
        switch self {
        case .crimson: return "diagonal hatching"   // Fire
        case .cobalt: return "horizontal lines"     // Rain
        case .jade: return "vertical lines"         // Earth
        case .amber: return "dot grid"              // Wind
        }
    }
}

// A face-down card back for opponent/partner zones. Branded design: the four suit marks
// arranged around a central monogram on a deep gradient, replacing the off-brand club symbol.
struct CardBackView: View {
    var size: CGSize = Theme.CardSize.opponentBack

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(colors: [Theme.Felt.baseDarkHighlight, Theme.Felt.baseDark],
                                   startPoint: .top, endPoint: .bottom)
                )
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Theme.Palette.accent.opacity(0.5), lineWidth: 1.5)
            RoundedRectangle(cornerRadius: Theme.Radius.card - 4)
                .strokeBorder(Theme.Palette.accent.opacity(0.3), lineWidth: 1)
                .padding(size.width * 0.12)

            VStack(spacing: size.height * 0.03) {
                HStack(spacing: size.width * 0.1) {
                    SuitSymbol(colour: .crimson, lineWidth: size.width * 0.025)
                        .frame(width: size.width * 0.18, height: size.width * 0.18)
                    SuitSymbol(colour: .cobalt, lineWidth: size.width * 0.025)
                        .frame(width: size.width * 0.18, height: size.width * 0.18)
                }
                Text("WP")
                    .font(.system(size: size.width * 0.26, weight: .black, design: .rounded))
                HStack(spacing: size.width * 0.1) {
                    SuitSymbol(colour: .jade, lineWidth: size.width * 0.025)
                        .frame(width: size.width * 0.18, height: size.width * 0.18)
                    SuitSymbol(colour: .amber, lineWidth: size.width * 0.025)
                        .frame(width: size.width * 0.18, height: size.width * 0.18)
                }
            }
            .foregroundStyle(Theme.Palette.accent.opacity(0.85))
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1.5)
        .accessibilityHidden(true)
    }
}

#Preview("Neon faces") {
    let colours: [CardColour?] = [.crimson, .cobalt, .jade, .amber, nil]
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: Theme.Space.s3) {
            ForEach(Array(colours.enumerated()), id: \.offset) { _, colour in
                CardView(card: Card(type: .number(7), colour: colour), isPlayable: true)
                CardView(card: Card(type: .skip, colour: colour))
                CardView(card: Card(type: .changeColour, colour: nil))
            }
        }
        .padding()
    }
    .background(TableBackground())
    .preferredColorScheme(.dark)
}
