import SwiftUI
import WildPairsCore

// The local player's hand: a width-aware overlapping fan that always fits the available
// screen width (no edge clipping, A5). Tapping a card plays it (the ViewModel rejects illegal
// taps with a shake + tooltip). Playable cards are lifted and green-bordered so the player
// always knows their options.

struct HandView: View {
    let hand: [CardViewModel]
    let cardSize: CGSize
    let showColourName: Bool
    var showPattern: Bool = false
    var reducedMotion: Bool = false
    let onPlay: (CardViewModel) -> Void

    @State private var shakingCardID: UUID?

    /// Below this overlap step, cards become unreadable / untappable — fall back to a
    /// scrollable row instead of compressing further (A5 "extreme counts" fallback).
    private let minimumStep: CGFloat

    init(hand: [CardViewModel], cardSize: CGSize, showColourName: Bool, showPattern: Bool = false,
         reducedMotion: Bool = false, onPlay: @escaping (CardViewModel) -> Void) {
        self.hand = hand
        self.cardSize = cardSize
        self.showColourName = showColourName
        self.showPattern = showPattern
        self.reducedMotion = reducedMotion
        self.onPlay = onPlay
        self.minimumStep = cardSize.width * 0.32
    }

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width - Theme.Space.s4 * 2
            let step = fanStep(available: available)
            if step >= minimumStep || hand.count <= 1 {
                // Centre the fan within the *full* GeometryReader width, not within an
                // already-full-width HStack plus extra padding on top of it — `available`
                // (and therefore `fanWidth`) already reserves the `Theme.Space.s4` margin on
                // each side, so re-adding that padding here would push the fan `s4` further
                // past the reader's own bounds and clip the trailing card off-screen.
                ZStack(alignment: .leading) {
                    ForEach(Array(hand.enumerated()), id: \.element.id) { index, item in
                        card(item)
                            .offset(x: CGFloat(index) * step)
                            .zIndex(item.isPlayable ? Double(index) + 100 : Double(index))
                    }
                }
                .frame(width: fanWidth(step: step), height: cardSize.height + Theme.Space.s3 * 2)
                .frame(width: geo.size.width, height: cardSize.height + Theme.Space.s3 * 2, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s2) {
                        ForEach(hand) { item in card(item) }
                    }
                    .padding(.horizontal, Theme.Space.s4)
                    .padding(.vertical, Theme.Space.s3)
                }
            }
        }
        .frame(height: cardSize.height + Theme.Space.s3 * 2)
        .accessibilityLabel("Your hand, \(hand.count) cards")
    }

    private func fanWidth(step: CGFloat) -> CGFloat {
        guard hand.count > 0 else { return cardSize.width }
        return cardSize.width + step * CGFloat(hand.count - 1)
    }

    /// The per-card horizontal advance: full card width + gap when everything fits, shrinking
    /// (overlapping) only as far as needed to keep the whole fan inside `available`.
    private func fanStep(available: CGFloat) -> CGFloat {
        guard hand.count > 1 else { return cardSize.width }
        let comfortable = cardSize.width + Theme.Space.s2
        let neededForComfortable = cardSize.width + comfortable * CGFloat(hand.count - 1)
        if neededForComfortable <= available { return comfortable }
        let step = (available - cardSize.width) / CGFloat(hand.count - 1)
        return max(step, 1)
    }

    private func card(_ item: CardViewModel) -> some View {
        CardView(card: item.card, size: cardSize,
                 isPlayable: item.isPlayable, showColourName: showColourName,
                 showPattern: showPattern, announcePlayability: true)
            .offset(y: item.isPlayable ? -Theme.Space.s3 : 0)
            .modifier(ShakeEffect(animatableData: shakingCardID == item.id ? 1 : 0))
            .onTapGesture { tap(item) }
            .animation(Theme.Motion.cardPlay, value: item.isPlayable)
            // A9: a played card scales/fades away and a drawn card scales/fades in, instead
            // of snapping — skipped under Reduced Motion (A12).
            .transition(reducedMotion ? .identity : .scale(scale: 0.5).combined(with: .opacity))
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
