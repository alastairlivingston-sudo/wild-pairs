import SwiftUI
import WildPairsCore

// A single playing card, rendered to look like a photographed physical game card
// (Phase 12c): white die-cut border with a bevelled edge, saturated element-gradient face,
// a large ghost suit watermark, white screen-printed numerals with a hard offset print
// shadow, a diagonal lacquer gloss sweep, and fine print grain. Every card always shows its
// suit symbol so the design stays colour-blind safe by default (§8).

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
    /// Once a wild's colour has been chosen, the face re-prints in that colour so the
    /// required colour is unmistakable (Phase 13); nil renders the unresolved charcoal wild.
    var wildTint: CardColour? = nil

    @Environment(\.colorScheme) private var scheme

    /// The colour the face prints in — the card's own, or a resolved wild's chosen tint.
    private var displayColour: CardColour? { card.colour ?? wildTint }
    private var isWildStock: Bool { displayColour == nil }
    /// Real playing cards show both corner indices (top-left + mirrored bottom-right) at any
    /// size large enough to render them legibly; smaller cards show just the top-left index.
    private var showSecondCorner: Bool { size.width >= 46 }
    private var borderWidth: CGFloat { size.width * 0.062 }
    private var faceRadius: CGFloat { max(3, Theme.Radius.card - size.width * 0.03) }

    var body: some View {
        ZStack {
            // 1. White die-cut cardstock border, lit from the top-left.
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xE8E4DA)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.9), .black.opacity(0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: max(0.8, size.width * 0.012))

            // 2. Printed colour face.
            ZStack {
                RoundedRectangle(cornerRadius: faceRadius).fill(faceGradient)
                ghostWatermark
                if showPattern, let colour = card.colour {
                    CardPatternFill(colour: colour)
                        .clipShape(RoundedRectangle(cornerRadius: faceRadius))
                }
                faceContent
                cornerIndices
                PrintGrain()
                    .clipShape(RoundedRectangle(cornerRadius: faceRadius))
                glossSweep
                // Face-to-border press line, like ink meeting the die-cut edge.
                RoundedRectangle(cornerRadius: faceRadius)
                    .strokeBorder(.black.opacity(0.28), lineWidth: max(0.6, size.width * 0.008))
            }
            .padding(borderWidth)

            // 3. Playable ring (accent when the card is legal to play).
            if isPlayable {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Theme.Palette.accent, lineWidth: 3)
            }
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        .scaleEffect((isSelected || isPlayable) ? 1.07 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(announcePlayability ? (isPlayable ? "Double tap to select" : "Double tap for more information") : "")
        .accessibilityAddTraits(isPlayable ? .isButton : [])
    }

    // MARK: Face surface

    /// Saturated three-stop print gradient: lit top-left, rich centre, deepened bottom-right.
    private var faceGradient: LinearGradient {
        let base = displayColour?.fillColor(scheme) ?? Color(hex: 0x232030)
        let highlight = displayColour?.highlightColor(scheme) ?? Color(hex: 0x3A3550)
        return LinearGradient(
            colors: [highlight, base, base.blended(toward: .black, amount: 0.28)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Large tilted suit mark printed as a tonal watermark behind the content.
    @ViewBuilder private var ghostWatermark: some View {
        if let colour = displayColour {
            SuitSymbol(colour: colour, lineWidth: max(1.5, size.width * 0.05))
                .frame(width: size.width * 0.66, height: size.width * 0.66)
                .foregroundStyle(.white.opacity(0.14))
                .rotationEffect(.degrees(-12))
                .offset(x: size.width * 0.05, y: -size.height * 0.01)
        }
    }

    /// The lacquer finish: a soft diagonal sheen falling from the top edge. The oversized
    /// ellipse lives in an overlay of a face-filling clear container so it never contributes
    /// to layout, and the clip is the container's (face-sized) bounds — clipping the ellipse
    /// directly would clip to the ellipse's own oversized frame instead.
    private var glossSweep: some View {
        Color.clear
            .overlay(
                Ellipse()
                    .fill(
                        LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.06), .clear],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: size.width * 1.7, height: size.height * 0.85)
                    .rotationEffect(.degrees(-22))
                    .offset(x: -size.width * 0.12, y: -size.height * 0.34)
            )
            .clipShape(RoundedRectangle(cornerRadius: faceRadius))
            .allowsHitTesting(false)
    }

    // MARK: Printed content

    @ViewBuilder private var faceContent: some View {
        switch card.type {
        case .number(let value):
            printedMark {
                Text("\(value)")
                    .font(.system(size: size.width * 0.52, weight: .heavy, design: .rounded))
            }
        default:
            VStack(spacing: size.height * 0.02) {
                if isWildStock { wildMotif }
                printedMark {
                    Image(systemName: card.type.centerSymbol ?? "questionmark")
                        .font(.system(size: size.width * (isWildStock ? 0.24 : 0.34), weight: .heavy))
                }
                if let caption = centreCaption {
                    printedMark {
                        Text(caption)
                            .font(.system(size: max(7, size.height * 0.07), weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.6).lineLimit(1)
                    }
                }
            }
        }
    }

    /// White screen-print treatment: hard offset shadow (the printed drop-shadow every
    /// classic game card carries) plus a soft ambient one.
    private func printedMark<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 0, x: size.width * 0.022, y: size.width * 0.028)
            .shadow(color: .black.opacity(0.2), radius: size.width * 0.03, y: size.width * 0.02)
    }

    /// Wild motif: the four element chips set in a diamond — "plays on anything", printed
    /// in this deck's own trade dress.
    private var wildMotif: some View {
        ZStack {
            ForEach(Array(CardColour.allCases.enumerated()), id: \.offset) { index, colour in
                let angle = Double(index) * 90.0 - 90.0
                RoundedRectangle(cornerRadius: size.width * 0.045)
                    .fill(
                        LinearGradient(colors: [colour.highlightColor(scheme), colour.fillColor(scheme)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: size.width * 0.19, height: size.width * 0.19)
                    .rotationEffect(.degrees(45))
                    .overlay(
                        SuitSymbol(colour: colour, lineWidth: max(1, size.width * 0.02))
                            .frame(width: size.width * 0.1, height: size.width * 0.1)
                            .foregroundStyle(.white.opacity(0.9))
                    )
                    .shadow(color: .black.opacity(0.35), radius: 0, x: size.width * 0.012, y: size.width * 0.016)
                    .offset(x: cos(angle * .pi / 180) * size.width * 0.24,
                            y: sin(angle * .pi / 180) * size.width * 0.24)
            }
        }
        .frame(width: size.width * 0.72, height: size.width * 0.72)
    }

    // MARK: Corner indices

    private var cornerIndices: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) { cornerIndex; Spacer(minLength: 0) }
            Spacer(minLength: 0)
            if showSecondCorner {
                HStack(spacing: 0) { Spacer(minLength: 0); cornerIndex.rotationEffect(.degrees(180)) }
            }
        }
        .padding(size.width * 0.045)
    }

    private var cornerIndex: some View {
        VStack(spacing: size.height * 0.004) {
            printedMark {
                Text(cornerLabel)
                    .font(.system(size: max(9, size.width * 0.17), weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6).lineLimit(1)
            }
            if let colour = card.colour {
                SuitSymbol(colour: colour, lineWidth: max(1, size.width * 0.024))
                    .frame(width: size.width * 0.12, height: size.width * 0.12)
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .fixedSize()
    }

    private var cornerLabel: String {
        if case .number(let v) = card.type { return "\(v)" }
        return card.type.abbreviation
    }

    /// Action cards caption their name; in colour-blind mode every card captions its colour.
    /// Hidden on the smallest cards (partner strip) where it would be unreadable.
    private var centreCaption: String? {
        guard size.width >= 56 else { return nil }
        if showColourName, let colour = card.colour { return colour.displayName.uppercased() }
        if case .number = card.type { return nil }
        return card.type.readableName
    }

    /// Suit-coloured glow on playable/selected cards; falls back to a subtle resting shadow
    /// (and under Reduced Visual Effects, since glow is a pure decoration with no information).
    private var hasGlow: Bool { (isPlayable || isSelected) && !reducedMotion }
    private var glowTint: Color { Theme.Element.scene(for: displayColour).glow }
    private var shadowColor: Color { hasGlow ? glowTint.opacity(0.55) : .black.opacity(isSelected ? 0.45 : 0.32) }
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

/// Fine two-tone speckle that reads as printed card stock instead of flat vector colour.
/// Deterministic (fixed LCG seed) so cards never shimmer between renders.
private struct PrintGrain: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func random() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 1000) / 1000
            }
            for i in 0..<140 {
                let x = random() * size.width
                let y = random() * size.height
                let dot = CGRect(x: x, y: y, width: 0.7, height: 0.7)
                context.fill(Path(ellipseIn: dot),
                             with: .color(i.isMultiple(of: 2) ? .white.opacity(0.5) : .black.opacity(0.5)))
            }
        }
        .opacity(0.16)
        .allowsHitTesting(false)
    }
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
    var ink: Color = .white

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
            context.stroke(path, with: .color(ink), lineWidth: 1)
            y += 4
        }
    }

    private func drawVerticalLines(context: GraphicsContext, size: CGSize) {
        var x: CGFloat = 0
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(ink), lineWidth: 1)
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
            context.stroke(path, with: .color(ink), lineWidth: 1)
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
                context.fill(Path(ellipseIn: rect), with: .color(ink))
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

// A face-down card back in the same physical language: white die-cut border, deep indigo
// lacquered face, embossed monogram medallion, and the four suit marks in the corners.
struct CardBackView: View {
    var size: CGSize = Theme.CardSize.opponentBack

    private var isCompact: Bool { size.width < 56 }
    private var borderWidth: CGFloat { size.width * 0.062 }
    private var faceRadius: CGFloat { max(3, Theme.Radius.card - size.width * 0.03) }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(
                    LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xE8E4DA)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.9), .black.opacity(0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: max(0.8, size.width * 0.012))

            ZStack {
                RoundedRectangle(cornerRadius: faceRadius)
                    .fill(
                        LinearGradient(colors: [Color(hex: 0x1A1242), Color(hex: 0x0D0820)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                if !isCompact {
                    ForEach(Array(CardColour.allCases.enumerated()), id: \.offset) { index, colour in
                        SuitSymbol(colour: colour, lineWidth: max(1, size.width * 0.02))
                            .frame(width: size.width * 0.12, height: size.width * 0.12)
                            .foregroundStyle(colour.highlightColor(.dark).opacity(0.7))
                            .offset(x: (index % 2 == 0 ? -1 : 1) * size.width * 0.28,
                                    y: (index < 2 ? -1 : 1) * size.height * 0.3)
                    }
                    Circle()
                        .strokeBorder(Theme.Palette.accent.opacity(0.5), lineWidth: max(0.8, size.width * 0.014))
                        .frame(width: size.width * 0.5, height: size.width * 0.5)
                }
                Text("WP")
                    .font(.system(size: size.width * (isCompact ? 0.36 : 0.2), weight: .black, design: .rounded))
                    .foregroundStyle(Theme.Palette.accent)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: size.width * 0.014, y: size.width * 0.018)
                    .shadow(color: Theme.Palette.accent.opacity(0.5), radius: size.width * 0.06)
                Color.clear
                    .overlay(
                        Ellipse()
                            .fill(
                                LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.04), .clear],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: size.width * 1.7, height: size.height * 0.85)
                            .rotationEffect(.degrees(-22))
                            .offset(x: -size.width * 0.12, y: -size.height * 0.34)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: faceRadius))
                RoundedRectangle(cornerRadius: faceRadius)
                    .strokeBorder(.black.opacity(0.3), lineWidth: max(0.6, size.width * 0.008))
            }
            .padding(borderWidth)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1.5)
        .accessibilityHidden(true)
    }
}

#Preview("Gloss print deck") {
    let colours: [CardColour?] = [.crimson, .cobalt, .jade, .amber, nil]
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: Theme.Space.s3) {
            ForEach(Array(colours.enumerated()), id: \.offset) { _, colour in
                CardView(card: Card(type: .number(7), colour: colour), size: CGSize(width: 90, height: 135), isPlayable: true)
                CardView(card: Card(type: .skip, colour: colour), size: CGSize(width: 90, height: 135))
                CardView(card: Card(type: .changeColour, colour: nil), size: CGSize(width: 90, height: 135))
            }
            CardBackView(size: CGSize(width: 90, height: 135))
        }
        .padding()
    }
    .background(TableBackground())
    .preferredColorScheme(.dark)
}
