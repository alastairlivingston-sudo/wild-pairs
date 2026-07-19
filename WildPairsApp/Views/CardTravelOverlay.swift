import SwiftUI
import WildPairsCore

// Cross-table card travel. The reducer remains authoritative: these are short-lived visual
// echoes of effects already emitted by the engine. Played cards follow a readable arc, and
// drawn cards arrive as a staggered physical sequence instead of fading through the whole path.

/// A logical spot on the table whose on-screen frame is reported for travel animation.
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

/// A quadratic path expressed as a geometry effect so the card's position is continuously
/// interpolated by SwiftUI. The bend is perpendicular to the source→destination vector, which
/// gives every seat a natural table arc rather than a straight UI translation.
private struct QuadraticFlightEffect: GeometryEffect {
    var progress: CGFloat
    let delta: CGSize
    let bend: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let distance = max(1, hypot(delta.width, delta.height))
        let normalX = -delta.height / distance
        let normalY = delta.width / distance
        let control = CGPoint(
            x: delta.width * 0.5 + normalX * bend,
            y: delta.height * 0.5 + normalY * bend
        )
        let inverse = 1 - progress
        let x = 2 * inverse * progress * control.x + progress * progress * delta.width
        let y = 2 * inverse * progress * control.y + progress * progress * delta.height
        return ProjectionTransform(CGAffineTransform(translationX: x, y: y))
    }
}

/// A single ghost card flying from the acting seat to the discard. `GameTableView` hides the
/// newly published top discard until this flight completes, preventing the old duplicate/
/// teleport frame where the same card was visible both in flight and already on the pile.
struct FlyingCardView: View {
    let flight: CardFlight
    let cardSize: CGSize
    let reducedMotion: Bool
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0

    private var delta: CGSize {
        CGSize(width: flight.to.x - flight.from.x, height: flight.to.y - flight.from.y)
    }

    private var bend: CGFloat {
        let distance = hypot(delta.width, delta.height)
        let magnitude = min(96, max(30, distance * 0.18))
        // Alternate the side of the curve according to horizontal travel, keeping the arc away
        // from the centre card stack in the common left/right opponent paths.
        return flight.from.x <= flight.to.x ? -magnitude : magnitude
    }

    var body: some View {
        CardView(card: flight.card, size: cardSize, reducedMotion: reducedMotion)
            .shadow(color: .black.opacity(0.38), radius: 12, y: 5)
            .scaleEffect(0.86 + 0.14 * progress)
            .rotationEffect(.degrees(Double((1 - progress) * (bend < 0 ? -5 : 5))))
            .position(flight.from)
            .modifier(QuadraticFlightEffect(progress: progress, delta: delta, bend: bend))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(Theme.Motion.playArc) { progress = 1 }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + Theme.Motion.cardFlightDuration,
                    execute: onComplete
                )
            }
    }
}

/// One drawn card-back travelling from the draw pile to a hand. `destination` already includes
/// a small lane offset, so multi-card penalties arrive as a sequence rather than eight identical
/// backs occupying one path.
struct DrawFlight: Identifiable, Equatable {
    let id = UUID()
    let from: CGPoint
    let destination: CGPoint
    let delay: Double
    let bend: CGFloat
    let landingRotation: Double
}

struct FlyingBackView: View {
    let flight: DrawFlight
    let cardSize: CGSize
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var vanished = false

    private var delta: CGSize {
        CGSize(
            width: flight.destination.x - flight.from.x,
            height: flight.destination.y - flight.from.y
        )
    }

    var body: some View {
        CardBackView(size: cardSize)
            .shadow(color: .black.opacity(0.34), radius: 8, y: 4)
            .scaleEffect(0.74 + 0.20 * progress)
            .rotationEffect(.degrees(flight.landingRotation * Double(progress)))
            .opacity(vanished ? 0 : 1)
            .position(flight.from)
            .modifier(
                QuadraticFlightEffect(
                    progress: progress,
                    delta: delta,
                    bend: flight.bend
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + flight.delay) {
                    withAnimation(Theme.Motion.draw) { progress = 1 }
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + flight.delay + Theme.Motion.drawFlightDuration
                ) {
                    withAnimation(.easeOut(duration: 0.10)) { vanished = true }
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + flight.delay + Theme.Motion.drawFlightDuration + 0.12,
                    execute: onComplete
                )
            }
    }
}
