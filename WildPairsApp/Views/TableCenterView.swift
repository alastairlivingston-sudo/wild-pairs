import SwiftUI
import WildPairsCore

// The centre-stage table object: a physical face-down draw deck, a separate played-card pile,
// and an always-visible direction orbit behind them. The active colour/turn owner now live in
// GameTableView's single state rail, avoiding duplicate pills around the centre.
struct TableCenterView: View {
    let topDiscard: Card?
    let currentColour: CardColour
    let drawPileCount: Int
    var pendingDrawCount: Int? = nil
    let turnDirection: TurnDirection
    let canDraw: Bool
    var mustDraw: Bool = false
    var forcedPickup: Bool = false
    let showColourName: Bool
    var showPattern: Bool = false
    var reducedMotion: Bool = false
    var cardSize: CGSize = Theme.CardSize.regularHand
    var colourChoicePending: Bool = false
    var recentDiscards: [Card] = []
    var flightSpace: String? = nil
    /// Exposed for compact device tuning; the production default is 24pt and must not fall below 16pt.
    var pileSpacing: CGFloat = Theme.Table.drawDiscardGap
    let onDraw: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var stackPop: Int?
    @State private var colourPulse = false
    @State private var directionRotation: Double = 0
    @State private var showReversed = false

    private var drawCardSize: CGSize {
        CGSize(width: cardSize.width * 0.85, height: cardSize.height * 0.85)
    }

    private var resolvedPileSpacing: CGFloat {
        max(Theme.Space.s4, pileSpacing)
    }

    private var orbitSize: CGFloat {
        max(
            cardSize.height * 1.28,
            drawCardSize.width + resolvedPileSpacing + cardSize.width + Theme.Space.s4
        )
    }

    var body: some View {
        VStack(spacing: Theme.Space.s2) {
            HStack(alignment: .center, spacing: resolvedPileSpacing) {
                drawPile
                discardPile
            }
            .padding(.vertical, Theme.Space.s2)
            // A background does not change the HStack's measured width, so the direction orbit
            // can extend into the inter-seat breathing room without breaking the centre-row fit.
            .background(alignment: .center) {
                directionOrbit
            }

            directionReadout
        }
        .onChange(of: currentColour) { _, _ in pulseColour() }
        .onChange(of: turnDirection) { _, _ in animateDirectionChange() }
        .onChange(of: pendingDrawCount) { old, new in
            guard let new, new > (old ?? 0) else { return }
            popStack(to: new)
        }
        .overlay {
            if let count = stackPop {
                StackPopBadge(count: count, reducedMotion: reducedMotion)
                    .transition(reducedMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
            }
        }
    }

    private var directionOrbit: some View {
        Image("solo_table_direction_ring_clockwise")
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .foregroundStyle(currentColour.highlightColor(scheme).opacity(Theme.Table.directionOrbitOpacity))
            .frame(width: orbitSize, height: orbitSize)
            // A 3D mirror communicates a genuine reversal rather than merely spinning the same
            // arrows. Reduced Motion gets the final mirrored state immediately.
            .rotation3DEffect(
                .degrees(turnDirection == .clockwise ? 0 : 180),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.35
            )
            .rotationEffect(.degrees(directionRotation))
            .animation(
                reducedMotion ? nil : .spring(response: 0.48, dampingFraction: 0.72),
                value: turnDirection
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var drawPile: some View {
        Button(action: onDraw) {
            ZStack {
                // Small rotational and positional differences make this read as a real deck rather
                // than three duplicated icons. The top back remains the interaction surface.
                CardBackView(size: drawCardSize)
                    .rotationEffect(.degrees(-2.2))
                    .offset(x: -3.5, y: 4)
                    .opacity(0.46)
                CardBackView(size: drawCardSize)
                    .rotationEffect(.degrees(1.1))
                    .offset(x: 2, y: 2.5)
                    .opacity(0.72)
                CardBackView(size: drawCardSize)
            }
            .overlay(alignment: .bottomLeading) {
                Text(badgeText)
                    .font(.caption2.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(pendingDrawCount != nil ? Theme.Palette.onAccent : .white)
                    .padding(.horizontal, Theme.Space.s2)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(
                            pendingDrawCount != nil
                                ? Theme.Palette.warning
                                : Color.black.opacity(0.82)
                        )
                    )
                    .overlay(Capsule().strokeBorder(.white.opacity(0.62), lineWidth: 1))
                    // The badge sits on the outer deck edge, never in the visual gap between piles.
                    .offset(x: -8, y: 8)
                    .shadow(color: .black.opacity(0.36), radius: 3, y: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canDraw)
        .opacity(canDraw ? 1 : 0.72)
        .frame(minWidth: drawCardSize.width, minHeight: drawCardSize.height)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay {
            if mustDraw && canDraw {
                DrawAttentionRing(
                    size: CGSize(width: drawCardSize.width + 12, height: drawCardSize.height + 12),
                    reducedMotion: reducedMotion
                )
            }
        }
        .overlay(alignment: .top) {
            if forcedPickup {
                drawHint("Picking up…", emphatic: true)
            } else if canDraw, let pending = pendingDrawCount {
                drawHint(mustDraw ? "Tap to draw +\(pending)" : "Or draw +\(pending)", emphatic: mustDraw)
            } else if mustDraw && canDraw {
                drawHint("Tap to draw", emphatic: true)
            }
        }
        .accessibilityLabel(
            pendingDrawCount.map { "Draw pile. Stack pending: \($0) cards" }
                ?? "Draw pile, \(drawPileCount) cards"
        )
        .accessibilityValue(
            forcedPickup
                ? "Picking up automatically"
                : mustDraw && canDraw
                    ? "You must draw"
                    : (canDraw && pendingDrawCount != nil)
                        ? "You may draw to skip stacking"
                        : ""
        )
        .accessibilityHint(
            canDraw
                ? pendingDrawCount.map { "Double tap to draw the pending \($0) cards" }
                    ?? "Double tap to draw a card"
                : ""
        )
        .accessibilityIdentifier("game-draw-card-button")
        .reportTableAnchor(.drawPile, in: flightSpace)
    }

    @ViewBuilder private func drawHint(_ text: String, emphatic: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(emphatic ? Theme.Palette.onAccent : .white)
            .padding(.horizontal, Theme.Space.s2)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(emphatic ? Theme.Palette.warning : Color.black.opacity(0.78))
            )
            .overlay(
                Capsule().strokeBorder(
                    Theme.Palette.accent.opacity(0.58),
                    lineWidth: emphatic ? 0 : 1
                )
            )
            .offset(y: -(drawCardSize.height * 0.075 + 26))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var badgeText: String {
        guard let pendingDrawCount else { return "\(drawPileCount)" }
        return "+\(pendingDrawCount)"
    }

    @ViewBuilder private var discardPile: some View {
        if let top = topDiscard {
            ZStack {
                ForEach(Array(recentDiscards.enumerated()), id: \.element.id) { index, card in
                    let depth = recentDiscards.count - 1 - index
                    CardView(card: card, size: cardSize, reducedMotion: reducedMotion)
                        .scaleEffect(0.96)
                        .rotationEffect(.degrees(memoryRotation(depth)))
                        .offset(x: memoryOffset(depth), y: 2 + CGFloat(depth) * 1.5)
                        .opacity(0.5)
                        .accessibilityHidden(true)
                }

                CardView(
                    card: top,
                    size: cardSize,
                    showColourName: showColourName,
                    showPattern: showPattern,
                    reducedMotion: reducedMotion,
                    wildTint: (top.isWild && !colourChoicePending) ? currentColour : nil
                )
                .scaleEffect(colourPulse ? 1.08 : 1)
                .animation(reducedMotion ? nil : Theme.Motion.moderate, value: colourChoicePending)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Played-card pile. Top card: \(discardCardLabel(top)). Current colour: \(currentColour.displayName)."
            )
            .reportTableAnchor(.discard, in: flightSpace)
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.r3, style: .continuous)
                .strokeBorder(
                    Theme.Palette.accent.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [4])
                )
                .frame(width: cardSize.width, height: cardSize.height)
                .accessibilityLabel("Played-card pile is empty")
                .reportTableAnchor(.discard, in: flightSpace)
        }
    }

    private func memoryRotation(_ depth: Int) -> Double {
        (depth % 2 == 0 ? -1.0 : 1.0) * (5.0 + Double(depth) * 3.0)
    }

    private func memoryOffset(_ depth: Int) -> CGFloat {
        (depth % 2 == 0 ? -1.0 : 1.0) * (3.0 + CGFloat(depth) * 2.0)
    }

    private func discardCardLabel(_ card: Card) -> String {
        guard let colour = card.colour else { return "\(card.type.spokenName), wild card" }
        if case .number(let value) = card.type {
            return "\(colour.displayName) \(value), number card"
        }
        return "\(colour.displayName) \(card.type.spokenName), action card"
    }

    /// Text and icon beneath the orbit are intentionally small. They make direction explicit for
    /// low-vision and first-time players without becoming a third centre-stage object.
    private var directionReadout: some View {
        HStack(spacing: Theme.Space.s1) {
            Image(systemName: turnDirection == .clockwise ? "arrow.clockwise" : "arrow.counterclockwise")
                .font(.caption2.weight(.black))
            Text(turnDirection == .clockwise ? "CLOCKWISE" : "COUNTER-CLOCKWISE")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.45)
        }
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, Theme.Space.s2)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.44)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .overlay(alignment: .top) {
            if showReversed {
                Text("REVERSED")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(Theme.Palette.onAccent)
                    .padding(.horizontal, Theme.Space.s2)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.Palette.warning))
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                    .offset(y: -24)
                    .transition(reducedMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            turnDirection == .clockwise
                ? "Play direction clockwise"
                : "Play direction counter-clockwise"
        )
    }

    private func pulseColour() {
        guard !reducedMotion else { return }
        withAnimation(.easeInOut(duration: 0.15)) { colourPulse = true }
        withAnimation(.easeInOut(duration: 0.15).delay(0.15)) { colourPulse = false }
    }

    private func popStack(to count: Int) {
        withAnimation(reducedMotion ? nil : Theme.Motion.celebration) { stackPop = count }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if stackPop == count {
                withAnimation(reducedMotion ? nil : Theme.Motion.moderate) { stackPop = nil }
            }
        }
    }

    private func animateDirectionChange() {
        if !reducedMotion {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
                directionRotation += turnDirection == .clockwise ? 180 : -180
            }
        }

        withAnimation(reducedMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
            showReversed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(reducedMotion ? nil : .easeOut(duration: 0.25)) {
                showReversed = false
            }
        }
    }
}

/// Warning ring around the draw deck while drawing is the only legal move. The static stroke is
/// the information; pulse and glow are optional reinforcement and disappear under Reduced Motion.
private struct DrawAttentionRing: View {
    let size: CGSize
    let reducedMotion: Bool
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card + 3, style: .continuous)
            .strokeBorder(Theme.Palette.warning, lineWidth: 2.5)
            .frame(width: size.width, height: size.height)
            .shadow(color: Theme.Palette.warning.opacity(0.7), radius: pulse ? 12 : 4)
            .opacity(reducedMotion ? 1 : (pulse ? 1 : 0.45))
            .scaleEffect(reducedMotion ? 1 : (pulse ? 1.05 : 1))
            .onAppear {
                guard !reducedMotion else { return }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct StackPopBadge: View {
    let count: Int
    let reducedMotion: Bool

    var body: some View {
        Text("+\(count)")
            .font(.system(size: 40, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 0, x: 1.5, y: 2)
            .padding(.horizontal, Theme.Space.s4)
            .padding(.vertical, Theme.Space.s1)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Theme.Palette.warning, Color(hex: 0xB56A00)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .shadow(color: reducedMotion ? .clear : Theme.Palette.warning.opacity(0.6), radius: 14)
            .accessibilityLabel("Draw stack is now \(count) cards")
            .allowsHitTesting(false)
    }
}
