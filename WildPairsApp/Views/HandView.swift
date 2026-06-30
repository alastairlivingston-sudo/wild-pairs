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
                // `.offset(x:)` is a render-time transform that does NOT contribute to layout, so
                // the ZStack's intrinsic width is a single card — not the full fan. The inner
                // frame must therefore be **leading-anchored**: that pins the offset origin (and
                // card 0) to the fan's true left edge, so the fan occupies exactly [0, fanWidth].
                // A default (centre) alignment here centres a one-card-wide box inside the wider
                // fanWidth frame, shifting the whole fan right by (fanWidth − cardWidth)/2 and
                // clipping the trailing cards off the right edge (the bug fixed here). The outer
                // frame then centres the real fan width within the reader with symmetric margins.
                ZStack(alignment: .leading) {
                    ForEach(Array(hand.enumerated()), id: \.element.id) { index, item in
                        card(item, index: index)
                            .offset(x: CGFloat(index) * step)
                            .zIndex(item.isPlayable ? Double(index) + 100 : Double(index))
                    }
                }
                .frame(width: fanWidth(step: step), height: cardSize.height + Theme.Space.s3 * 2, alignment: .leading)
                .frame(width: geo.size.width, height: cardSize.height + Theme.Space.s3 * 2, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s2) {
                        ForEach(Array(hand.enumerated()), id: \.element.id) { index, item in card(item, index: index) }
                    }
                    .padding(.horizontal, Theme.Space.s4)
                    .padding(.vertical, Theme.Space.s3)
                }
            }
        }
        .frame(height: cardSize.height + Theme.Space.s3 * 2)
        // `GeometryReader` has no view identity of its own, so an `.accessibilityLabel` applied
        // directly to it "leaks" down and overwrites each card's own label instead of labelling
        // a single container (regression found via the UI test suite — every hand card was
        // reporting "Your hand, N cards" instead of its real label). `.accessibilityElement
        // (children: .contain)` is the documented fix: it gives this container its own summary
        // label while keeping every card individually reachable with its own label/hint.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your hand, \(hand.count) cards")
    }

    private func fanWidth(step: CGFloat) -> CGFloat {
        guard hand.count > 0 else { return cardSize.width }
        return cardSize.width + step * CGFloat(hand.count - 1)
    }

    /// The per-card horizontal advance: a ~44% overlap (neon-final.html spec) when everything
    /// fits, shrinking (overlapping further) only as far as needed to keep the whole fan
    /// inside `available`.
    private func fanStep(available: CGFloat) -> CGFloat {
        guard hand.count > 1 else { return cardSize.width }
        let comfortable = cardSize.width * 0.56
        let neededForComfortable = cardSize.width + comfortable * CGFloat(hand.count - 1)
        if neededForComfortable <= available { return comfortable }
        let step = (available - cardSize.width) / CGFloat(hand.count - 1)
        return max(step, 1)
    }

    private func card(_ item: CardViewModel, index: Int) -> some View {
        CardView(card: item.card, size: cardSize,
                 isPlayable: item.isPlayable, showColourName: showColourName,
                 showPattern: showPattern, announcePlayability: true, reducedMotion: reducedMotion)
            .offset(y: item.isPlayable ? -cardSize.height * 0.18 : 0)
            .modifier(ShakeEffect(animatableData: shakingCardID == item.id ? 1 : 0))
            .onTapGesture { tap(item) }
            .animation(Theme.Motion.cardPlay, value: item.isPlayable)
            // A9: a played card scales/fades away and a drawn card scales/fades in, instead
            // of snapping — skipped under Reduced Motion (A12).
            .transition(reducedMotion ? .identity : .scale(scale: 0.5).combined(with: .opacity))
            // Deal-in stagger (Phase 11 B): each new card (a fresh deal, or one drawn mid-round)
            // fades/scales in with a per-index delay instead of every card popping at once.
            .modifier(DealStaggerModifier(index: index, reducedMotion: reducedMotion))
    }

    private func tap(_ item: CardViewModel) {
        if !item.isPlayable {
            withAnimation(Theme.Motion.fast) { shakingCardID = item.id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakingCardID = nil }
        }
        onPlay(item)
    }
}

/// Fades/scales a card in with a per-index delay (`Theme.Motion.dealStagger`) on appearance —
/// covers both the initial round deal (every card appears at once, staggered) and a single
/// drawn card joining the hand mid-round.
private struct DealStaggerModifier: ViewModifier {
    let index: Int
    let reducedMotion: Bool
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.6)
            .onAppear {
                guard !reducedMotion else { visible = true; return }
                withAnimation(Theme.Motion.deal.delay(Double(index) * Theme.Motion.dealStagger)) {
                    visible = true
                }
            }
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
