import SwiftUI
import WildPairsCore

// The Ink & Foil card skin (Phase 16). Parity reference:
// docs/phase-16-design/05-ink-and-foil.html. A collector's black-glass deck where colour is
// jewellery: a luminous foil frame and gradient-foil marks on near-black gloss stock, with a
// giant tone-on-tone embossed suit mark. Reuses the shared glyph vocabulary from CardView.swift
// (SuitSymbol + the pictorial action glyphs) — it restyles them in foil, never redraws them.
struct InkFoilFace: View {
    let context: CardFaceContext

    private var w: CGFloat { context.size.width }
    private var h: CGFloat { context.size.height }
    private var radius: CGFloat { Theme.Radius.card }
    private var glyphUnit: CGFloat { w * 0.56 }

    var body: some View {
        ZStack {
            // 1. Black-glass stock + faint outer rim so the card separates from the dark table.
            RoundedRectangle(cornerRadius: radius)
                .fill(LinearGradient(colors: [InkFoil.stockTop, InkFoil.stockBottom],
                                     startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(InkFoil.rim, lineWidth: max(0.6, w * 0.008))

            // 2. Giant embossed suit mark, tone-on-tone, anchored off the bottom-right corner.
            if let colour = context.displayColour, !context.isWild {
                SuitSymbolShape(colour: colour)
                    .fill(InkFoil.glow(colour).opacity(0.16))
                    .frame(width: w * 0.95, height: w * 0.95)
                    .offset(x: w * 0.18, y: h * 0.12)
            }

            // 3. Colour-blind pattern, printed in the element's own foil light.
            if context.showPattern, let colour = context.card.colour {
                CardPatternFill(colour: colour)
                    .opacity(0.10)
                    .clipShape(RoundedRectangle(cornerRadius: radius))
            }

            // 4. The foil frame — the jewellery.
            foilFrame

            // 5. Hero mark.
            heroContent

            // 6. Corner indices (both corners once large enough).
            cornerIndices

            // 7. Colour-blind colour-name foot plate (the only face text).
            if context.showColourName, let colour = context.displayColour {
                colourNamePlate(colour)
            }

            // 8. A single quiet gloss sheen — the production finish.
            if !context.reducedMotion {
                RoundedRectangle(cornerRadius: radius)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.14), .white.opacity(0.02), .clear],
                        startPoint: .topLeading, endPoint: .bottom))
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    // MARK: Frame

    private var foilFrame: some View {
        let inset = w * 0.055
        let line = max(1, w * 0.02)
        return Group {
            if context.isWild {
                RoundedRectangle(cornerRadius: radius - inset)
                    .strokeBorder(InkFoil.wildConic, lineWidth: line)
            } else if let colour = context.displayColour {
                RoundedRectangle(cornerRadius: radius - inset)
                    .strokeBorder(InkFoil.foil(colour), lineWidth: line)
                    .shadow(color: context.reducedMotion ? .clear : InkFoil.glow(colour).opacity(0.45),
                            radius: w * 0.05)
            }
        }
        .padding(inset)
    }

    // MARK: Hero content

    @ViewBuilder private var heroContent: some View {
        switch context.card.type {
        case .number(let v):
            foilText("\(v)", size: w * 0.6)
        case .drawTwo:
            foilText("+2", size: w * 0.46)
        case .drawEight:
            foilText("+8", size: w * 0.46)
        case .drawFour:
            VStack(spacing: h * 0.012) {
                wildChips(w * 0.4)
                foilText("+4", size: w * 0.3, gradient: InkFoil.wildFoil)
            }
        case .changeColour:
            wildChips(w * 0.68)
        case .skip:
            foiled(suitGrad) { SkipGlyph(unit: glyphUnit, pips: 1) }
        case .skipTwo:
            VStack(spacing: h * 0.012) {
                foiled(suitGrad) { SkipGlyph(unit: w * 0.5, pips: 2) }
                foilText("×2", size: w * 0.15)
            }
        case .reverse:
            foiled(suitGrad) { ChasingArrowsGlyph(unit: glyphUnit) }
        case .targetedDraw:
            foiled(suitGrad) { TargetedDrawGlyph(unit: w * 0.6) }
        case .forcedSwap:
            foiled(suitGrad) { ForcedSwapGlyph(unit: w * 0.6) }
        case .teamPlay:
            foiled(suitGrad) { TeamPlayGlyph(unit: w * 0.58) }
        case .discardAll:
            foiled(InkFoil.wildFoil) { DiscardBurstGlyph(unit: w * 0.62) }
        case .discardColour:
            // Colour Burst: the same sweep silhouette as Discard All, but printed in this
            // card's own foil — the coloured cousin. Frame + glyph colour distinguish them.
            foiled(suitGrad) { DiscardBurstGlyph(unit: w * 0.62) }
        }
    }

    // MARK: Corner indices

    @ViewBuilder private var cornerIndices: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) { cornerIndex; Spacer(minLength: 0) }
            Spacer(minLength: 0)
            if context.showSecondCorner {
                HStack(spacing: 0) { Spacer(minLength: 0); cornerIndex.rotationEffect(.degrees(180)) }
            }
        }
        .padding(w * 0.075)
    }

    private var cornerIndex: some View {
        VStack(spacing: h * 0.004) {
            cornerRank
            if context.isWild {
                miniChips(w * 0.12)
            } else if let colour = context.displayColour {
                SuitSymbol(colour: colour, lineWidth: max(1, w * 0.022))
                    .foregroundStyle(InkFoil.glow(colour))
                    .frame(width: w * 0.1, height: w * 0.1)
            }
        }
        .fixedSize()
    }

    @ViewBuilder private var cornerRank: some View {
        let font = Font.system(size: max(9, w * 0.16), weight: .heavy, design: .rounded)
        switch context.card.type {
        case .number(let v): rankText("\(v)", font)
        case .drawTwo:       rankText("+2", font)
        case .drawEight:     rankText("+8", font)
        case .drawFour:      rankText("+4", font)
        default:             EmptyView()
        }
    }

    @ViewBuilder private func rankText(_ s: String, _ font: Font) -> some View {
        if let colour = context.displayColour {
            Text(s).font(font).foregroundStyle(InkFoil.glow(colour))
        } else {
            Text(s).font(font).foregroundStyle(.white)
        }
    }

    // MARK: Foil helpers

    private var suitGrad: LinearGradient {
        InkFoil.foil(context.displayColour ?? .crimson)
    }

    private func foilText(_ s: String, size: CGFloat) -> some View {
        foilText(s, size: size, gradient: suitGrad)
    }

    private func foilText(_ s: String, size: CGFloat, gradient: LinearGradient) -> some View {
        Text(s)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(gradient)
    }

    /// Recolours a shared white glyph into a foil gradient while preserving its intrinsic size:
    /// the hidden glyph reserves the frame, the gradient fills it, masked to the glyph shape.
    private func foiled<G: View>(_ gradient: LinearGradient, @ViewBuilder _ glyph: () -> G) -> some View {
        glyph()
            .opacity(0)
            .overlay(gradient.mask(glyph()))
    }

    // MARK: Wild motif

    /// The four element chips set in a diamond — the deck's "plays on anything" trade dress.
    private func wildChips(_ u: CGFloat) -> some View {
        let chip = u * 0.42
        return ZStack {
            Circle()
                .strokeBorder(.white.opacity(0.28), lineWidth: max(0.6, u * 0.02))
                .frame(width: u * 0.72, height: u * 0.72)
            ForEach(Array(CardColour.allCases.enumerated()), id: \.offset) { index, colour in
                let angle = Double(index) * 90.0 - 90.0
                RoundedRectangle(cornerRadius: chip * 0.28)
                    .fill(InkFoil.foil(colour))
                    .overlay(
                        SuitSymbol(colour: colour, lineWidth: max(1, u * 0.03))
                            .foregroundStyle(InkFoil.stockBottom)
                            .frame(width: chip * 0.56, height: chip * 0.56)
                    )
                    .frame(width: chip, height: chip)
                    .shadow(color: context.reducedMotion ? .clear : InkFoil.glow(colour).opacity(0.5),
                            radius: u * 0.05)
                    .offset(x: cos(angle * .pi / 180) * u * 0.34,
                            y: sin(angle * .pi / 180) * u * 0.34)
            }
        }
        .frame(width: u, height: u)
    }

    /// A compact wild-chip cluster for the corner index.
    private func miniChips(_ u: CGFloat) -> some View {
        let chip = u * 0.5
        return ZStack {
            ForEach(Array(CardColour.allCases.enumerated()), id: \.offset) { index, colour in
                let angle = Double(index) * 90.0 - 90.0
                RoundedRectangle(cornerRadius: chip * 0.28)
                    .fill(InkFoil.foil(colour))
                    .frame(width: chip, height: chip)
                    .offset(x: cos(angle * .pi / 180) * u * 0.3,
                            y: sin(angle * .pi / 180) * u * 0.3)
            }
        }
        .frame(width: u, height: u)
    }

    // MARK: Colour name plate

    private func colourNamePlate(_ colour: CardColour) -> some View {
        VStack {
            Spacer()
            Text(colour.displayName.uppercased())
                .font(.system(size: max(7, w * 0.1), weight: .heavy, design: .rounded))
                .tracking(w * 0.006)
                .foregroundStyle(InkFoil.glow(colour))
                .padding(.horizontal, w * 0.08)
                .padding(.vertical, w * 0.028)
                .background(Capsule().fill(InkFoil.stockBottom.opacity(0.85)))
                .overlay(Capsule().strokeBorder(InkFoil.glow(colour).opacity(0.5),
                                                lineWidth: max(0.5, w * 0.006)))
                .padding(.bottom, h * 0.055)
        }
    }
}
