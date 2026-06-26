import SwiftUI
import WildPairsCore

// The centre of the table: the draw pile (tap to draw on your turn), the discard top, the
// active-colour indicator (chip + name, always — colour-blind safe), and the turn-direction
// arrow.

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

    var body: some View {
        HStack(spacing: Theme.Space.s5) {
            drawPile
            discardPile
            VStack(spacing: Theme.Space.s3) {
                colourIndicator
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
                CardBackView(size: cardSize)
                Text("\(drawPileCount)")
                    .font(.caption).fontWeight(.bold).monospacedDigit()
                    .padding(Theme.Space.s1).background(.ultraThinMaterial, in: Capsule())
                    .offset(y: cardSize.height * 0.32)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canDraw)
        .opacity(canDraw ? 1 : 0.5)
        .frame(minHeight: 56)
        .accessibilityLabel("Draw pile, \(drawPileCount) cards")
        .accessibilityHint(canDraw ? "Double tap to draw a card" : "")
        .accessibilityIdentifier("game-draw-card-button")
    }

    @ViewBuilder private var discardPile: some View {
        if let top = topDiscard {
            CardView(card: top, size: cardSize, showColourName: showColourName, showPattern: showPattern)
                .scaleEffect(colourPulse ? 1.08 : 1.0)
                .accessibilityLabel("Discard pile. Top card: \(discardCardLabel(top)). Current colour: \(currentColour.displayName).")
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(width: cardSize.width, height: cardSize.height)
        }
    }

    private var colourIndicator: some View {
        VStack(spacing: 2) {
            Image(systemName: currentColour.symbolName)
                .foregroundStyle(currentColour.fillColor(scheme))
            Text(currentColour.displayName)
                .font(.caption2).fontWeight(.semibold)
        }
        .padding(Theme.Space.s2)
        .background(Capsule().fill(Theme.Palette.surface))
        .scaleEffect(colourPulse ? 1.08 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current colour: \(currentColour.displayName)")
    }

    private func discardCardLabel(_ card: Card) -> String {
        guard let colour = card.colour else { return "\(card.type.spokenName), wild card" }
        if case .number(let v) = card.type { return "\(colour.displayName) \(v), number card" }
        return "\(colour.displayName) \(card.type.spokenName), action card"
    }

    private var directionArrow: some View {
        Image(systemName: "arrow.clockwise")
            .foregroundStyle(.secondary)
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
