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

    private var accessibilityLabel: String {
        let colour = card.colour?.displayName ?? "Wild"
        let type: String
        switch card.type {
        case .number(let v): type = "\(v)"
        case .skip: type = "Skip"
        case .skipTwo: type = "Skip Two"
        case .reverse: type = "Reverse"
        case .drawTwo: type = "Draw Two"
        case .drawFour: type = "Draw Four"
        case .changeColour: type = "Change Colour"
        case .discardAll: type = "Discard All"
        case .targetedDraw: type = "Targeted Draw"
        case .forcedSwap: type = "Forced Swap"
        case .teamPlay: type = "Team Play"
        }
        let playable = isPlayable ? ", playable" : ""
        let pattern = (showPattern && !card.isWild) ? ", \(card.colour?.patternName ?? "") pattern" : ""
        return card.isWild ? "\(type)\(playable)" : "\(colour) \(type)\(playable)\(pattern)"
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
