import SwiftUI
import WildPairsCore

// The local player's hand: a horizontally scrollable row of cards. Tapping a card plays it
// (the ViewModel rejects illegal taps with a shake + tooltip). Playable cards are lifted and
// green-bordered so the player always knows their options.

struct HandView: View {
    let hand: [CardViewModel]
    let cardSize: CGSize
    let showColourName: Bool
    var showPattern: Bool = false
    let onPlay: (CardViewModel) -> Void

    @State private var shakingCardID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.s2) {
                ForEach(hand) { item in
                    CardView(card: item.card, size: cardSize,
                             isPlayable: item.isPlayable, showColourName: showColourName,
                             showPattern: showPattern)
                        .offset(y: item.isPlayable ? -Theme.Space.s3 : 0)
                        .modifier(ShakeEffect(animatableData: shakingCardID == item.id ? 1 : 0))
                        .onTapGesture { tap(item) }
                        .animation(Theme.Motion.cardPlay, value: item.isPlayable)
                }
            }
            .padding(.horizontal, Theme.Space.s4)
            .padding(.vertical, Theme.Space.s3)
        }
        .accessibilityLabel("Your hand, \(hand.count) cards")
    }

    private func tap(_ item: CardViewModel) {
        if !item.isPlayable {
            withAnimation(Theme.Motion.fast) { shakingCardID = item.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakingCardID = nil }
        }
        onPlay(item)
    }
}

// Spring-shake used to reject an illegal card tap (§ux-spec invalid-move).
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let travel = 6 * sin(animatableData * .pi * 3)
        return ProjectionTransform(CGAffineTransform(translationX: travel, y: 0))
    }
}
