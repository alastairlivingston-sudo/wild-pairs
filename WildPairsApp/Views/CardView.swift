import SwiftUI
import WildPairsCore

// A single playing card (§6 structure). Colour-coded face, corner abbreviations, centre
// glyph, suit emblem, and an optional colour-name label for colour-blind mode. Always shows
// its suit symbol so the design is colour-blind safe by default (§8).

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

    @Environment(\.colorScheme) private var scheme

    private var faceColor: Color {
        card.colour?.fillColor(scheme) ?? Theme.Palette.surface
    }
    private var inkColor: Color {
        card.isWild ? .primary : .white
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .fill(faceColor)
            if showPattern, let colour = card.colour {
                CardPatternFill(colour: colour)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r3))
            }
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .strokeBorder(borderColor, lineWidth: isPlayable ? 3 : 1)

            VStack {
                corner(alignment: .leading)
                Spacer()
                centre
                Spacer()
                corner(alignment: .trailing).rotationEffect(.degrees(180))
            }
            .padding(size.width * 0.08)
        }
        .frame(width: size.width, height: size.height)
        .shadow(color: .black.opacity(isSelected ? 0.15 : 0.08),
                radius: isSelected ? 8 : 3, x: 0, y: isSelected ? 2 : 1)
        .scaleEffect(isSelected ? 1.05 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(announcePlayability ? (isPlayable ? "Double tap to select" : "Double tap for more information") : "")
        .accessibilityAddTraits(isPlayable ? .isButton : [])
    }

    private func corner(alignment: HorizontalAlignment) -> some View {
        HStack {
            if alignment == .trailing { Spacer() }
            VStack(alignment: alignment == .leading ? .leading : .trailing, spacing: 0) {
                Text(card.type.abbreviation)
                    .font(.caption).fontWeight(.bold)
                if let colour = card.colour {
                    Image(systemName: colour.symbolName).font(.caption2)
                }
            }
            if alignment == .leading { Spacer() }
        }
        .foregroundStyle(inkColor)
    }

    @ViewBuilder private var centre: some View {
        VStack(spacing: Theme.Space.s1) {
            if case .number(let v) = card.type {
                Text("\(v)").font(.system(size: size.height * 0.34, weight: .bold))
            } else if let symbol = card.type.centerSymbol {
                Image(systemName: symbol).font(.system(size: size.height * 0.26, weight: .semibold))
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
        if isPlayable { return Theme.Palette.success }
        return card.isWild ? .secondary.opacity(0.4) : .white.opacity(0.5)
    }

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
private struct CardPatternFill: View {
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
    var patternName: String {
        switch self {
        case .crimson: return "diagonal hatching"
        case .cobalt: return "horizontal lines"
        case .jade: return "vertical lines"
        case .amber: return "dot grid"
        }
    }
}

// A face-down card back for opponent/partner zones.
struct CardBackView: View {
    var size: CGSize = Theme.CardSize.opponentBack
    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.r3)
            .fill(Theme.Palette.accent.gradient)
            .overlay(
                Image(systemName: "suit.club.fill")
                    .foregroundStyle(.white.opacity(0.35))
                    .font(.system(size: size.width * 0.4))
            )
            .frame(width: size.width, height: size.height)
            .accessibilityHidden(true)
    }
}
