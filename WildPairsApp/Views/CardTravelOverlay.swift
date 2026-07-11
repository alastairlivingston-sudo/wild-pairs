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
    case drawPile
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

/// One drawn card-back travelling from the draw pile to a hand (Phase 17 Stage 3.5). A penalty
/// draw launches several of these with staggered `delay`s, so the pickup reads longer the more
/// cards it is; each fades as it lands so the real card taking its place in the hand shows.
struct DrawFlight: Identifiable, Equatable {
    let id = UUID()
    let from: CGPoint
    let to: CGPoint
    let delay: Double
}

struct FlyingBackView: View {
    let flight: DrawFlight
    let cardSize: CGSize
    let onComplete: () -> Void

    @State private var arrived = false

    var body: some View {
        CardBackView(size: cardSize)
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
            .scaleEffect(arrived ? 0.92 : 0.72)
            .opacity(arrived ? 0 : 1)
            .position(arrived ? flight.to : flight.from)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(Theme.Motion.draw.delay(flight.delay)) { arrived = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + flight.delay + 0.5, execute: onComplete)
            }
    }
}

/// The turn hand-off spotlight (Phase 17 Stage 3.3): a glowing orb sweeps from the seat that
/// just finished to the seat whose turn it now is, so *which way the turn went, and to whom* is
/// felt rather than only inferred from the destination seat lighting up.
struct TurnSpotlight: Identifiable, Equatable {
    let id = UUID()
    let from: CGPoint
    let to: CGPoint
}

struct TurnSpotlightView: View {
    let spotlight: TurnSpotlight
    let tint: Color
    let onComplete: () -> Void

    @State private var arrived = false
    @State private var faded = false

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [tint.opacity(0.95), tint.opacity(0)],
                                 center: .center, startRadius: 1, endRadius: 30))
            .frame(width: 60, height: 60)
            .scaleEffect(arrived ? 1.0 : 0.55)
            .opacity(faded ? 0 : 0.9)
            .position(arrived ? spotlight.to : spotlight.from)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.34)) { arrived = true }
                withAnimation(.easeOut(duration: 0.14).delay(0.26)) { faded = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.44, execute: onComplete)
            }
    }
}
