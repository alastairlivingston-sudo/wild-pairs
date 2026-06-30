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
    /// Real playing cards show both corner indices (top-left + mirrored bottom-right) at any
    /// size large enough to render them legibly; smaller cards show just the top-left index.
    private var showSecondCorner: Bool { size.width >= 46 }

    var body: some View {
        ZStack {
            // 1. Coloured card face (wilds get a deep plum so they don't vanish against felt).
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(colors: [faceHighlight, faceColor],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            if showPattern, let colour = card.colour {
                CardPatternFill(colour: colour)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            // 2. Inset hairline frame — the classic playing-card border that makes the deck
            // read as a real set of cards rather than flat coloured tiles.
            RoundedRectangle(cornerRadius: max(2, Theme.Radius.card - size.width * 0.05))
                .strokeBorder(.white.opacity(0.55), lineWidth: max(1, size.width * 0.022))
                .padding(size.width * 0.07)

            cornerIndices
            centrePanel

            // 3. Outer crisp edge + playable ring (accent when the card is legal to play).
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(borderColor, lineWidth: isPlayable ? 3 : 1.5)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        .scaleEffect((isSelected || isPlayable) ? 1.07 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(announcePlayability ? (isPlayable ? "Double tap to select" : "Double tap for more information") : "")
        .accessibilityAddTraits(isPlayable ? .isButton : [])
    }

    // MARK: Card face elements

    private var badgeSize: CGFloat { size.width * 0.56 }

    /// Rank/abbreviation + bespoke suit mark in the top-left and (mirrored) bottom-right
    /// corners — the classic card index. The smallest cards show only the top-left index.
    private var cornerIndices: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) { cornerIndex; Spacer(minLength: 0) }
            Spacer(minLength: 0)
            if showSecondCorner {
                HStack(spacing: 0) { Spacer(minLength: 0); cornerIndex.rotationEffect(.degrees(180)) }
            }
        }
        .padding(size.width * 0.09)
        .foregroundStyle(.white)
    }

    private var cornerIndex: some View {
        VStack(spacing: size.height * 0.005) {
            Text(cornerLabel)
                .font(.system(size: max(8, size.width * 0.17), weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.6).lineLimit(1)
            if let colour = card.colour {
                SuitSymbol(colour: colour, lineWidth: max(1, size.width * 0.022))
                    .frame(width: size.width * 0.13, height: size.width * 0.13)
            }
        }
        .fixedSize()
    }

    private var cornerLabel: String {
        if case .number(let v) = card.type { return "\(v)" }
        return card.type.abbreviation
    }

    /// The focal centre: a white badge (the "face" of the card) holding the big number or the
    /// action glyph, with the action/colour name beneath it on larger cards.
    private var centrePanel: some View {
        VStack(spacing: size.height * 0.035) {
            ZStack {
                RoundedRectangle(cornerRadius: badgeSize * 0.26)
                    .fill(.white)
                    .frame(width: badgeSize, height: badgeSize)
                    .shadow(color: .black.opacity(0.22), radius: size.width * 0.03, y: 1)
                // Wild cards ring the badge with all four colours to signal "plays on anything".
                if card.isWild {
                    RoundedRectangle(cornerRadius: badgeSize * 0.26)
                        .strokeBorder(wildRing, lineWidth: max(1.5, size.width * 0.03))
                        .frame(width: badgeSize, height: badgeSize)
                }
                centreGlyph
            }
            if let caption = centreCaption {
                Text(caption)
                    .font(.system(size: max(8, size.height * 0.08), weight: .bold))
                    .minimumScaleFactor(0.6).lineLimit(1)
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder private var centreGlyph: some View {
        if case .number(let v) = card.type {
            Text("\(v)")
                .font(.system(size: badgeSize * 0.66, weight: .heavy, design: .rounded))
                .foregroundStyle(glyphInk)
        } else if let symbol = card.type.centerSymbol {
            Image(systemName: symbol)
                .font(.system(size: badgeSize * 0.5, weight: .bold))
                .foregroundStyle(glyphInk)
        }
    }

    /// Action cards caption their name; in colour-blind mode every card captions its colour.
    /// Hidden on the smallest cards (partner strip) where it would be unreadable.
    private var centreCaption: String? {
        guard size.width >= 56 else { return nil }
        if showColourName, let colour = card.colour { return colour.displayName.uppercased() }
        if case .number = card.type { return nil }
        return card.type.readableName
    }

    /// Glyph ink: a deepened variant of the card colour so it stays legible on the white badge
    /// (Wind's pale gold especially needs darkening); wild uses a deep plum.
    private var glyphInk: Color {
        guard let colour = card.colour else { return Color(hex: 0x3C2A63) }
        switch colour {
        case .crimson: return Color(hex: 0xC0392B)
        case .cobalt:  return Color(hex: 0x1B5FD9)
        case .jade:    return Color(hex: 0x1E7A48)
        case .amber:   return Color(hex: 0x8A6A12)
        }
    }

    private var wildRing: AngularGradient {
        AngularGradient(colors: [Color(hex: 0xE8431F), Color(hex: 0x1B5FD9),
                                 Color(hex: 0x2F8F5B), Color(hex: 0xC9A227), Color(hex: 0xE8431F)],
                        center: .center)
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

    /// Below this width the four-suit grid renders as illegible specks (the old 38pt draw-pile
    /// chip). Compact backs show a single bold "WP" monogram so the deck reads cleanly.
    private var isCompact: Bool { size.width < 56 }

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
                if !isCompact {
                    HStack(spacing: size.width * 0.1) {
                        SuitSymbol(colour: .crimson, lineWidth: size.width * 0.025)
                            .frame(width: size.width * 0.18, height: size.width * 0.18)
                        SuitSymbol(colour: .cobalt, lineWidth: size.width * 0.025)
                            .frame(width: size.width * 0.18, height: size.width * 0.18)
                    }
                }
                Text("WP")
                    .font(.system(size: size.width * (isCompact ? 0.4 : 0.26), weight: .black, design: .rounded))
                if !isCompact {
                    HStack(spacing: size.width * 0.1) {
                        SuitSymbol(colour: .jade, lineWidth: size.width * 0.025)
                            .frame(width: size.width * 0.18, height: size.width * 0.18)
                        SuitSymbol(colour: .amber, lineWidth: size.width * 0.025)
                            .frame(width: size.width * 0.18, height: size.width * 0.18)
                    }
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
