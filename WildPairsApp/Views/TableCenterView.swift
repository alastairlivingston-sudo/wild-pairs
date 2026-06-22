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
    let onDraw: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: Theme.Space.s5) {
            drawPile
            discardPile
            VStack(spacing: Theme.Space.s3) {
                colourIndicator
                directionArrow
            }
        }
    }

    private var drawPile: some View {
        Button(action: onDraw) {
            ZStack {
                CardBackView(size: Theme.CardSize.regularHand)
                Text("\(drawPileCount)")
                    .font(.caption).fontWeight(.bold).monospacedDigit()
                    .padding(4).background(.ultraThinMaterial, in: Capsule())
                    .offset(y: Theme.CardSize.regularHand.height * 0.32)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canDraw)
        .opacity(canDraw ? 1 : 0.5)
        .accessibilityLabel("Draw pile, \(drawPileCount) cards")
        .accessibilityHint(canDraw ? "Double tap to draw a card" : "")
        .accessibilityIdentifier("game-draw-card-button")
    }

    @ViewBuilder private var discardPile: some View {
        if let top = topDiscard {
            CardView(card: top, size: Theme.CardSize.regularHand, showColourName: showColourName)
                .accessibilityLabel("Top of discard pile")
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(width: Theme.CardSize.regularHand.width, height: Theme.CardSize.regularHand.height)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current colour: \(currentColour.displayName)")
    }

    private var directionArrow: some View {
        Image(systemName: turnDirection == .clockwise ? "arrow.clockwise" : "arrow.counterclockwise")
            .foregroundStyle(.secondary)
            .accessibilityLabel(turnDirection == .clockwise ? "Play direction clockwise" : "Play direction counter-clockwise")
    }
}
