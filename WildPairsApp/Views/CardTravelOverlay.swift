import SwiftUI
import WildPairsCore

// Cross-table played-card travel (Phase 17 Stage 3.1). Every play — the local hand's, the
// partner's, an opponent's — animates a "ghost" card flying from the acting seat's position
// to the discard pile, so who-played-what is *seen* rather than inferred from a silent discard
// swap. Positions are resolved at run time from anchors each seat and the discard report into a
// shared table coordinate space; the ghost is a plain overlay, skipped entirely under Reduced
// Motion (the discard just updates, as before).

/// A logical spot on the table whose on-screen frame is reported for the travel animation.
enum TableAnchor: Hashable {
    case seat(Int)   // tablePosition 0 (you) … 3
    case discard
}

/// Collects `[TableAnchor: CGRect]` from every reporter up the tree into one dictionary.
struct TableAnchorPreference: PreferenceKey {
    static let defaultValue: [TableAnchor: CGRect] = [:]
    static func reduce(value: inout [TableAnchor: CGRect], nextValue: () -> [TableAnchor: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Report this view's frame (in the named table space) as `anchor`. No-op when `space` is
    /// nil, so the reporter can be plumbed through views that aren't always inside the overlay.
    @ViewBuilder func reportTableAnchor(_ anchor: TableAnchor, in space: String?) -> some View {
        if let space {
            background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: TableAnchorPreference.self,
                        value: [anchor: geo.frame(in: .named(space))])
                }
            )
        } else {
            self
        }
    }
}

/// One in-flight played card with resolved endpoints in the table coordinate space.
struct CardFlight: Identifiable, Equatable {
    let id = UUID()
    let card: Card
    let from: CGPoint
    let to: CGPoint
}

/// A single ghost card flying from the acting seat to the discard, removing itself on arrival.
struct FlyingCardView: View {
    let flight: CardFlight
    let cardSize: CGSize
    let reducedMotion: Bool
    let onComplete: () -> Void

    @State private var arrived = false

    var body: some View {
        CardView(card: flight.card, size: cardSize, reducedMotion: reducedMotion)
            .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
            .scaleEffect(arrived ? 1.0 : 0.86)
            .opacity(arrived ? 1 : 0.9)
            .position(arrived ? flight.to : flight.from)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(Theme.Motion.playArc) { arrived = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: onComplete)
            }
    }
}
