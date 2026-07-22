import SwiftUI
import WildPairsCore

// The centre-stage table object: a physical face-down draw deck, a separate played-card pile,
// the current element, and an always-visible direction orbit behind them.
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
    /// The freshly played top card stays invisible while its flight ghost crosses the table.
    /// The previous discard remains visible underneath, then the new card settles on arrival.
    var hiddenTopCardIDs: Set<UUID> = []
    let onDraw: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var stackPop: Int?
    @State private var colourPulse = false
    @State private var showReversed = false
    /// Brief confirmation shown only when a pending wild colour choice resolves. Normal
    /// number-card colour changes do not trigger it, so it remains a meaningful event.
    @State private var confirmedWildColour: CardColour?

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
        HStack(alignment: .center, spacing: resolvedPileSpacing) {
            drawPile
            discardPile
        }
        .padding(.top, Theme.Space.s5)
        .padding(.bottom, Theme.Space.s2)
        .background(alignment: .center) {
            directionOrbit
        }
        .overlay(alignment: .top) {
            currentElementChip
        }
        .onChange(of: currentColour) { _, _ in pulseColour() }
        .onChange(of: colourChoicePending) { old, new in
            if old, !new, topDiscard?.isWild == true { confirmWildColour() }
        }
        .onChange(of: turnDirection) { _, _ in animateDirectionChange() }
        .onChange(of: pendingDrawCount) { old, new in
            guard let new, new > (old ?? 0) else { return }
            popStack(to: new)
        }
        .overlay {
            ZStack {
                if let count = stackPop {
                    StackPopBadge(count: count, reducedMotion: reducedMotion)
                        .transition(reducedMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
                }

                if let colour = confirmedWildColour {
                    WildColourLockBadge(colour: colour)
                        .offset(y: -(cardSize.height * 0.48))
                        .transition(reducedMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
        .overlay(alignment: .bottom) {
            directionChangeConfirmation
                .offset(y: Theme.Space.s3)
        }
    }

    private var directionOrbit: some View {
        DirectionPlayRing(
            colour: currentColour,
            clockwise: turnDirection == .clockwise,
            emphasised: showReversed,
            reducedMotion: reducedMotion,
            diameter: orbitSize
        )
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
                        .opacity(hiddenTopCardIDs.contains(card.id) ? 0 : 0.5)
                        .accessibilityHidden(true)
                }

                let isTravelling = hiddenTopCardIDs.contains(top.id)
                CardView(
                    card: top,
                    size: cardSize,
                    showColourName: showColourName,
                    showPattern: showPattern,
                    reducedMotion: reducedMotion,
                    wildTint: (top.isWild && !colourChoicePending) ? currentColour : nil
                )
                .opacity(isTravelling ? 0 : 1)
                .scaleEffect(isTravelling ? 0.92 : (colourPulse ? 1.08 : 1))
                .animation(reducedMotion ? nil : Theme.Motion.cardSettle, value: isTravelling)
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

    private var currentElementChip: some View {
        HStack(spacing: Theme.Space.s1) {
            SuitSymbol(colour: currentColour, lineWidth: 1.8)
                .frame(width: 15, height: 15)
            Text(currentColour.displayName.uppercased())
                .font(.caption2.weight(.black))
                .tracking(0.45)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Space.s2)
        .padding(.vertical, 5)
        .background(Capsule().fill(currentColour.fillColor(scheme).opacity(0.92)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.76), lineWidth: 1))
        .shadow(color: currentColour.highlightColor(scheme).opacity(0.24), radius: 5)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current element: \(currentColour.displayName)")
    }

    @ViewBuilder private var directionChangeConfirmation: some View {
        if showReversed {
            Text("REVERSED")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(Theme.Palette.onAccent)
                .padding(.horizontal, Theme.Space.s2)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.Palette.warning))
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                .transition(reducedMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
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


    private func confirmWildColour() {
        withAnimation(reducedMotion ? nil : Theme.Motion.cardSettle) {
            confirmedWildColour = currentColour
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Theme.Motion.actionConfirmationDisplayDuration
        ) {
            guard confirmedWildColour == currentColour else { return }
            withAnimation(reducedMotion ? nil : .easeOut(duration: 0.18)) {
                confirmedWildColour = nil
            }
        }
    }

    private func animateDirectionChange() {
        withAnimation(reducedMotion ? nil : Theme.Motion.reverseImpact) {
            showReversed = true
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Theme.Motion.actionConfirmationDisplayDuration
        ) {
            withAnimation(reducedMotion ? nil : .easeOut(duration: 0.25)) {
                showReversed = false
            }
        }
    }
}


/// The always-visible direction-of-play indicator: a prominent ring of arrowheads circling the
/// table centre, flowing the way play travels. Direction is carried by arrow *geometry* (never
/// colour alone), so it stays legible in colour-blind and grayscale modes; the HUD holds the
/// spoken direction, so this ring is `accessibilityHidden`. A Reverse flips the arrowheads with a
/// 3D-mirror impact. Under Reduced Motion the flow freezes to a still frame that is still clearly
/// directional. Uses `.periodic` rather than `.animation` so the app still reports idle to
/// XCUITest between frames.
private struct DirectionPlayRing: View {
    let colour: CardColour
    let clockwise: Bool
    let emphasised: Bool
    let reducedMotion: Bool
    let diameter: CGFloat

    @Environment(\.colorScheme) private var scheme

    private let chevronCount = 12
    private var radius: CGFloat { diameter / 2 }
    private var chevronSize: CGFloat { max(12, diameter * 0.12) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(colour.highlightColor(scheme).opacity(0.18),
                        lineWidth: max(1.5, diameter * 0.014))
                .frame(width: diameter * 0.9, height: diameter * 0.9)

            if reducedMotion {
                arrowRing(phase: 0)
            } else {
                TimelineView(.periodic(from: .now, by: 1.0 / 12.0)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    // The bright head laps the ring every ~2.4s, in the play direction.
                    let phase = (t / 2.4).truncatingRemainder(dividingBy: 1)
                    arrowRing(phase: phase)
                }
            }
        }
        .frame(width: diameter, height: diameter)
        // The 3D Y-mirror flips the arrowheads themselves for counter-clockwise, and gives a
        // Reverse its physical "flip" impact rather than a decorative spin.
        .rotation3DEffect(
            .degrees(clockwise ? 0 : 180),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.35
        )
        .scaleEffect(emphasised ? 1.06 : 1)
        .shadow(color: emphasised ? colour.highlightColor(scheme).opacity(0.55) : .clear,
                radius: emphasised ? 16 : 0)
        .animation(reducedMotion ? nil : Theme.Motion.reverseImpact, value: clockwise)
        .animation(reducedMotion ? nil : Theme.Motion.reverseImpact, value: emphasised)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func arrowRing(phase: Double) -> some View {
        ZStack {
            ForEach(0..<chevronCount, id: \.self) { i in
                let frac = Double(i) / Double(chevronCount)
                let lead = reducedMotion ? staticLead(frac) : travellingLead(frac, phase: phase)
                chevron(lead: lead)
                    .offset(y: -radius * 0.86)
                    .rotationEffect(.degrees(frac * 360))
            }
        }
    }

    /// Brightness as a comet chasing the head around the ring in the play direction.
    private func travellingLead(_ frac: Double, phase: Double) -> Double {
        let behind = (frac - phase + 1).truncatingRemainder(dividingBy: 1)
        return pow(1 - behind, 2.2)
    }

    /// Reduced Motion: no travelling head, but a fixed bright leading arc so the arrowheads still
    /// read as flowing one way.
    private func staticLead(_ frac: Double) -> Double {
        let d = min(frac, 1 - frac)          // 0 at the top … 0.5 opposite
        return 0.5 + 0.5 * pow(1 - d * 2, 2)
    }

    private func chevron(lead: Double) -> some View {
        // Base points right = the clockwise tangent at the top of the ring; rotating each copy
        // around the centre keeps every arrowhead tangential.
        Image(systemName: "chevron.right")
            .font(.system(size: chevronSize, weight: .black))
            .foregroundStyle(.white)
            .opacity(0.28 + 0.72 * lead)
            .shadow(color: colour.highlightColor(scheme).opacity(0.45 + 0.45 * lead),
                    radius: 2 + 5 * lead)
    }
}

/// Confirms the result of a wild colour decision with symbol + name + checkmark. It appears only
/// after the pending choice resolves, providing the causal closure that a background tint alone
/// cannot guarantee for colour-blind players.
private struct WildColourLockBadge: View {
    let colour: CardColour
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: Theme.Space.s1) {
            SuitSymbol(colour: colour, lineWidth: 2)
                .frame(width: 16, height: 16)
            Text("\(colour.displayName.uppercased()) SET")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.45)
                .lineLimit(1)
            Image(systemName: "checkmark")
                .font(.caption2.weight(.black))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Space.s2)
        .padding(.vertical, 5)
        .background(Capsule().fill(colour.fillColor(scheme).opacity(0.96)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.86), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.38), radius: 6, y: 3)
        .accessibilityLabel("Colour set to \(colour.displayName)")
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
