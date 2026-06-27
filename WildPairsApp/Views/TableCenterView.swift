import SwiftUI
import WildPairsCore

// The centre of the table: a real tappable stacked draw pile with a visible count chip, the
// discard top, and a prominent felt-inset colour chip (bespoke suit symbol + name) plus the
// turn-direction arrow. Phase 9 A7: the draw pile and colour indicator were previously
// near-invisible/clipped — both are now first-class, legible elements.

struct TableCenterView: View {
    let topDiscard: Card?
    let currentColour: CardColour
    let drawPileCount: Int
    let turnDirection: TurnDirection
    let canDraw: Bool
    let showColourName: Bool
    var showPattern: Bool = false
    var reducedMotion: Bool = false
    var cardSize: CGSize = Theme.CardSize.regularHand
    let onDraw: () -> Void

    @Environment(\.colorScheme) private var scheme
    // ux-spec.md §8 "Current colour indicator": pulses (scale 1.0 → 1.08 → 1.0) when the
    // active colour changes; the direction arrow does a 180° turn when Reverse is played.
    @State private var colourPulse = false
    @State private var arrowAngle: Double?

    /// Draw pile back — smaller than the discard so the discard reads as the focal element
    /// (neon-final.html spec: discard 50px, draw-back 32px).
    private var drawCardSize: CGSize { Theme.CardSize.tableDraw }

    var body: some View {
        // Spec layout: colour pill above the row; discard on top; draw-back + direction
        // arrow beside it below the discard.
        VStack(spacing: Theme.Space.s2) {
            colourIndicator
            discardPile
            HStack(spacing: Theme.Space.s3) {
                drawPile
                directionArrow
            }
        }
        .onChange(of: currentColour) { _, _ in pulseColour() }
        .onChange(of: turnDirection) { _, _ in rotateArrow() }
        .onAppear { if arrowAngle == nil { arrowAngle = turnDirection == .clockwise ? 0 : 180 } }
    }

    private var drawPile: some View {
        Button(action: onDraw) {
            ZStack {
                // Real stacked-deck illusion: two faint offset backs beneath the top card.
                CardBackView(size: drawCardSize).offset(x: 3, y: 3).opacity(0.5)
                CardBackView(size: drawCardSize).offset(x: 1.5, y: 1.5).opacity(0.75)
                CardBackView(size: drawCardSize)
                Text("\(drawPileCount)")
                    .font(.caption2.bold()).monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Space.s1).padding(.vertical, 2)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .overlay(Capsule().strokeBorder(Theme.Palette.accent.opacity(0.6), lineWidth: 1))
                    .offset(y: drawCardSize.height * 0.42)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canDraw)
        .opacity(canDraw ? 1 : 0.5)
        .frame(minHeight: 50)
        .accessibilityLabel("Draw pile, \(drawPileCount) cards")
        .accessibilityHint(canDraw ? "Double tap to draw a card" : "")
        .accessibilityIdentifier("game-draw-card-button")
    }

    @ViewBuilder private var discardPile: some View {
        if let top = topDiscard {
            CardView(card: top, size: cardSize, showColourName: showColourName, showPattern: showPattern,
                     reducedMotion: reducedMotion)
                .scaleEffect(colourPulse ? 1.08 : 1.0)
                .accessibilityLabel("Discard pile. Top card: \(discardCardLabel(top)). Current colour: \(currentColour.displayName).")
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .strokeBorder(Theme.Palette.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(width: cardSize.width, height: cardSize.height)
        }
    }

    /// Filled with the actual suit colour + glow (neon-final.html spec), not a dark pill with
    /// a coloured stroke — the chip itself reads as the colour, with high-contrast ink on top.
    private var colourIndicator: some View {
        HStack(spacing: Theme.Space.s2) {
            SuitSymbol(colour: currentColour, lineWidth: 2)
                .frame(width: 16, height: 16)
                .foregroundStyle(colourInk)
            Text(currentColour.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(colourInk)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s2)
        .background(Capsule().fill(currentColour.fillColor(scheme)))
        .shadow(color: currentColour.fillColor(scheme).opacity(reducedMotion ? 0 : 0.4), radius: 16)
        .scaleEffect(colourPulse ? 1.08 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current colour: \(currentColour.displayName)")
    }

    /// High-contrast ink for the filled colour chip — amber's pale fill needs dark ink while
    /// the other three suits stay legible with white.
    private var colourInk: Color {
        currentColour == .amber ? Color(hex: 0x3A2A02) : .white
    }

    private func discardCardLabel(_ card: Card) -> String {
        guard let colour = card.colour else { return "\(card.type.spokenName), wild card" }
        if case .number(let v) = card.type { return "\(colour.displayName) \(v), number card" }
        return "\(colour.displayName) \(card.type.spokenName), action card"
    }

    private var directionArrow: some View {
        Image(systemName: "arrow.clockwise")
            .foregroundStyle(Theme.Palette.accent.opacity(0.8))
            .rotationEffect(.degrees(arrowAngle ?? (turnDirection == .clockwise ? 0 : 180)))
            .accessibilityLabel(turnDirection == .clockwise ? "Play direction clockwise" : "Play direction counter-clockwise")
    }

    private func pulseColour() {
        guard !reducedMotion else { return }
        withAnimation(.easeInOut(duration: 0.15)) { colourPulse = true }
        withAnimation(.easeInOut(duration: 0.15).delay(0.15)) { colourPulse = false }
    }

    private func rotateArrow() {
        let target = turnDirection == .clockwise ? 0.0 : 180.0
        guard !reducedMotion else { arrowAngle = target; return }
        withAnimation(.easeInOut(duration: 0.3)) { arrowAngle = target }
    }
}
