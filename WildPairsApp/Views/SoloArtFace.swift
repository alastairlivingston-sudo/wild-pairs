import SwiftUI
import WildPairsCore

// MARK: - Solo asset-pack card art (Phase 17 E)
//
// The "Solo" skin renders pre-drawn card art from SoloCards.xcassets instead of drawing the
// face procedurally. The art bakes in the rim, hero mark, corner indices and colour-blind
// pattern, so this face adds none of those — only the two things the pack doesn't provide: a
// colour chip on a resolved wild, and a procedural stand-in for Draw Eight (no supplied art).

enum SoloCardArt {
    /// The asset-catalogue name for a card, or nil when the pack has no art for it (Draw Eight,
    /// which falls back to a procedural stand-in).
    static func assetName(for card: Card) -> String? {
        if card.isWild {
            switch card.type {
            case .changeColour: return "solo_card_wild_change_colour"
            case .drawFour:     return "solo_card_wild_draw_four"
            case .discardAll:   return "solo_card_wild_discard_all"
            default:            return nil
            }
        }
        guard let suit = suitName(card.colour) else { return nil }
        switch card.type {
        case .number(let v): return "solo_card_\(suit)_\(v)"
        case .skip:          return "solo_card_\(suit)_skip"
        case .skipTwo:       return "solo_card_\(suit)_skip_two"
        case .reverse:       return "solo_card_\(suit)_reverse"
        case .drawTwo:       return "solo_card_\(suit)_draw_two"
        case .targetedDraw:  return "solo_card_\(suit)_targeted_draw"
        case .forcedSwap:    return "solo_card_\(suit)_forced_swap"
        case .teamPlay:      return "solo_card_\(suit)_team_play"
        case .discardColour: return "solo_card_\(suit)_colour_burst"
        case .drawEight:     return nil   // no supplied art — procedural stand-in
        case .drawFour, .changeColour, .discardAll: return nil   // wilds handled above
        }
    }

    static func suitName(_ colour: CardColour?) -> String? {
        switch colour {
        case .crimson: return "fire"
        case .cobalt:  return "rain"
        case .jade:    return "earth"
        case .amber:   return "wind"
        case .none:    return nil
        }
    }
}

struct SoloArtFace: View {
    let context: CardFaceContext

    private var w: CGFloat { context.size.width }
    private var h: CGFloat { context.size.height }

    var body: some View {
        Group {
            if let name = SoloCardArt.assetName(for: context.card) {
                Image(name)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                    .overlay(resolvedWildChip, alignment: .topTrailing)
            } else {
                drawEightStandIn
            }
        }
        .frame(width: w, height: h)
    }

    /// A resolved wild (colour chosen) has no per-colour art, so mark the chosen colour with a
    /// small chip in the corner — mainly for the discard's top card.
    @ViewBuilder private var resolvedWildChip: some View {
        if context.isWild, let tint = context.wildTint {
            Circle()
                .fill(tint.fillColor(context.scheme))
                .frame(width: w * 0.22, height: w * 0.22)
                .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: max(1, w * 0.02)))
                .shadow(color: .black.opacity(0.4), radius: 2)
                .padding(w * 0.08)
        }
    }

    /// Draw Eight (Phase 17 B4b) has no supplied art — a "+8" face in the pack's dark-glass,
    /// coloured-rim style (reusing the Ink & Foil stock tokens) so it sits seamlessly in the deck.
    private var drawEightStandIn: some View {
        let element = (context.displayColour ?? .crimson).fillColor(context.scheme)
        let rr = RoundedRectangle(cornerRadius: Theme.Radius.card)
        return ZStack {
            rr.fill(LinearGradient(colors: [InkFoil.stockTop, InkFoil.stockBottom],
                                   startPoint: .top, endPoint: .bottom))
            if context.showPattern, let colour = context.displayColour {
                CardPatternFill(colour: colour).clipShape(rr).opacity(0.12)
            }
            Text("+8")
                .font(.system(size: w * 0.44, weight: .heavy, design: .rounded))
                .foregroundStyle(element)
                .shadow(color: element.opacity(0.5), radius: w * 0.04)
            cornerIndices(colour: element)
        }
        .overlay(rr.strokeBorder(element.opacity(0.85), lineWidth: max(1, w * 0.022)))
    }

    @ViewBuilder private func cornerIndices(colour: Color) -> some View {
        let mark = Text("+8").font(.system(size: max(9, w * 0.16), weight: .heavy, design: .rounded))
            .foregroundStyle(colour)
        VStack {
            HStack { mark; Spacer() }
            Spacer()
            if context.showSecondCorner {
                HStack { Spacer(); mark.rotationEffect(.degrees(180)) }
            }
        }
        .padding(w * 0.08)
    }
}
