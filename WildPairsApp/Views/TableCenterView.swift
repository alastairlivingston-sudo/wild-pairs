import SwiftUI
import WildPairsCore

// The centre of the table: a real tappable stacked draw pile with a visible count chip, the
// discard top, and a prominent felt-inset colour chip (bespoke suit symbol + name) plus the
// turn-direction arrow. Phase 9 A7: the draw pile and colour indicator were previously
// near-invisible/clipped — both are now first-class, legible elements.

struct TableCenterView: View {
    let topDiscard: Card?
    let currentColour: CardColour
    let drawPileCount: Int
    /// Draw stacking (Phase 11 F): when non-nil, the badge shows "Stack N" instead of the
    /// plain pile count, so the looming penalty is visible even when it isn't your turn.
    var pendingDrawCount: Int? = nil
    let turnDirection: TurnDirection
    let canDraw: Bool
    /// The local player has no playable card — drawing is their only move. Lights up the
    /// draw pile so "you must pick up" is unmissable (Phase 15).
    var mustDraw: Bool = false
    /// The pending stack cannot be answered and is being drawn automatically — the pile
    /// shows a "picking up" state instead of asking for a tap.
    var forcedPickup: Bool = false
    let showColourName: Bool
    var showPattern: Bool = false
    var reducedMotion: Bool = false
    var cardSize: CGSize = Theme.CardSize.regularHand
    /// True while a wild on top still awaits its colour choice — the resolved-wild tint
    /// (Phase 13) is held back until the colour is actually chosen.
    var colourChoicePending: Bool = false
    let onDraw: () -> Void

    /// Escalating "+N" pop shown when the pending draw stack grows (Phase 13).
    @State private var stackPop: Int?

    @Environment(\.colorScheme) private var scheme
    // ux-spec.md §8 "Current colour indicator": pulses (scale 1.0 → 1.08 → 1.0) when the
    // active colour changes; the direction arrow does a 180° turn when Reverse is played.
    @State private var colourPulse = false
    @State private var arrowAngle: Double?

    /// Draw pile back — slightly smaller than the discard so the discard stays the focal
    /// element, but large enough to read as a real, tappable deck (the previous 38pt back was
    /// an illegible chip). Kept in 2:3 ratio relative to the discard.
    private var drawCardSize: CGSize {
        CGSize(width: cardSize.width * 0.85, height: cardSize.height * 0.85)
    }

    var body: some View {
        // ux-spec.md §game-table: draw pile left of centre, discard right of centre — a single
        // row of two comparable cards with the colour pill above and the direction arrow below,
        // instead of the old top-heavy vertical stack that buried the draw pile.
        VStack(spacing: Theme.Space.s3) {
            colourIndicator
            HStack(alignment: .center, spacing: Theme.Space.s4) {
                drawPile
                discardPile
            }
            directionArrow
        }
        .onChange(of: currentColour) { _, _ in pulseColour() }
        .onChange(of: turnDirection) { _, _ in rotateArrow() }
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
        .onAppear { if arrowAngle == nil { arrowAngle = turnDirection == .clockwise ? 0 : 180 } }
    }

    private var drawPile: some View {
        Button(action: onDraw) {
            ZStack {
                // Real stacked-deck illusion: two faint offset backs beneath the top card.
                CardBackView(size: drawCardSize).offset(x: 3, y: 3).opacity(0.5)
                CardBackView(size: drawCardSize).offset(x: 1.5, y: 1.5).opacity(0.75)
                CardBackView(size: drawCardSize)
                Text(badgeText)
                    .font(.caption2.bold()).monospacedDigit()
                    .foregroundStyle(pendingDrawCount != nil ? Theme.Palette.onAccent : .white)
                    .padding(.horizontal, Theme.Space.s1).padding(.vertical, 2)
                    .background(Capsule().fill(pendingDrawCount != nil ? Theme.Palette.warning : Color.black.opacity(0.55)))
                    .overlay(Capsule().strokeBorder(Theme.Palette.accent.opacity(0.6), lineWidth: 1))
                    .offset(y: drawCardSize.height * 0.42)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canDraw)
        .opacity(canDraw ? 1 : 0.5)
        .frame(minHeight: 50)
        .overlay {
            if mustDraw && canDraw {
                DrawAttentionRing(size: CGSize(width: drawCardSize.width + 10,
                                               height: drawCardSize.height + 10),
                                  reducedMotion: reducedMotion)
            }
        }
        .overlay(alignment: .top) {
            if mustDraw && canDraw {
                Text(forcedPickup ? "Picking up…" : "Tap to draw")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Palette.onAccent)
                    .padding(.horizontal, Theme.Space.s2).padding(.vertical, 3)
                    .background(Capsule().fill(Theme.Palette.warning))
                    .offset(y: -(drawCardSize.height * 0.075 + 26))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(pendingDrawCount.map { "Draw pile. Stack pending: \($0) cards" }
            ?? "Draw pile, \(drawPileCount) cards")
        .accessibilityValue(forcedPickup ? "Picking up automatically"
            : (mustDraw && canDraw ? "You must draw" : ""))
        .accessibilityHint(canDraw ? "Double tap to draw a card" : "")
        .accessibilityIdentifier("game-draw-card-button")
    }

    private var badgeText: String {
        guard let pendingDrawCount else { return "\(drawPileCount)" }
        return "+\(pendingDrawCount)"
    }

    @ViewBuilder private var discardPile: some View {
        if let top = topDiscard {
            // Ghost cards under the top discard so the pile reads as a real stack of played
            // cards rather than a lone floating card (Phase 12b).
            ZStack {
                discardGhost(rotation: -6, x: -3, y: 2)
                discardGhost(rotation: 4, x: 3, y: 1)
                // A resolved wild re-prints in the chosen colour (Phase 13) — the tint is
                // held back while the colour choice is still pending.
                CardView(card: top, size: cardSize, showColourName: showColourName, showPattern: showPattern,
                         reducedMotion: reducedMotion,
                         wildTint: (top.isWild && !colourChoicePending) ? currentColour : nil)
                    .scaleEffect(colourPulse ? 1.08 : 1.0)
                    .animation(reducedMotion ? nil : Theme.Motion.moderate, value: colourChoicePending)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Discard pile. Top card: \(discardCardLabel(top)). Current colour: \(currentColour.displayName).")
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .strokeBorder(Theme.Palette.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(width: cardSize.width, height: cardSize.height)
        }
    }

    private func discardGhost(rotation: Double, x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .fill(
                LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xE8E4DA)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).strokeBorder(.black.opacity(0.2), lineWidth: 1))
            .frame(width: cardSize.width, height: cardSize.height)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            .accessibilityHidden(true)
    }

    /// Filled with the actual suit colour + glow (neon-final.html spec), not a dark pill with
    /// a coloured stroke — the chip itself reads as the colour, with high-contrast ink on top.
    private var colourIndicator: some View {
        HStack(spacing: Theme.Space.s2) {
            SuitSymbol(colour: currentColour, lineWidth: 2)
                .frame(width: 16, height: 16)
                .foregroundStyle(colourInk)
            Text(currentColour.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(colourInk)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Space.s3).padding(.vertical, Theme.Space.s2)
        .background(
            Capsule().fill(
                LinearGradient(colors: [currentColour.highlightColor(scheme), currentColour.fillColor(scheme)],
                               startPoint: .top, endPoint: .bottom))
        )
        .overlay(Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 1))
        .shadow(color: Theme.Element.scene(for: currentColour).glow.opacity(reducedMotion ? 0 : 0.55), radius: 18)
        .scaleEffect(colourPulse ? 1.08 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current colour: \(currentColour.displayName)")
    }

    /// High-contrast ink for the filled colour chip — amber's pale fill needs dark ink while
    /// the other three suits stay legible with white.
    private var colourInk: Color {
        currentColour == .amber ? Color(hex: 0x3A2A02) : .white
    }

    private func discardCardLabel(_ card: Card) -> String {
        guard let colour = card.colour else { return "\(card.type.spokenName), wild card" }
        if case .number(let v) = card.type { return "\(colour.displayName) \(v), number card" }
        return "\(colour.displayName) \(card.type.spokenName), action card"
    }

    private var directionArrow: some View {
        Image(systemName: "arrow.clockwise")
            .foregroundStyle(Theme.Palette.accent.opacity(0.8))
            .rotationEffect(.degrees(arrowAngle ?? (turnDirection == .clockwise ? 0 : 180)))
            .accessibilityLabel(turnDirection == .clockwise ? "Play direction clockwise" : "Play direction counter-clockwise")
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

    private func rotateArrow() {
        let target = turnDirection == .clockwise ? 0.0 : 180.0
        guard !reducedMotion else { arrowAngle = target; return }
        withAnimation(.easeInOut(duration: 0.3)) { arrowAngle = target }
    }
}

/// Pulsing warning ring around the draw pile while drawing is the only legal move — the
/// "where do I tap" cue the prompt banner alone never delivered (Phase 15). Static ring
/// under Reduced Motion; the information is the ring, not the pulse.
private struct DrawAttentionRing: View {
    let size: CGSize
    let reducedMotion: Bool
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card + 3)
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

/// The escalating draw-stack callout: "+4", "+8"… pops over the table centre as the
/// pending penalty grows, so a stacking war reads as one at a glance (Phase 13).
private struct StackPopBadge: View {
    let count: Int
    let reducedMotion: Bool

    var body: some View {
        Text("+\(count)")
            .font(.system(size: 40, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 0, x: 1.5, y: 2)
            .padding(.horizontal, Theme.Space.s4).padding(.vertical, Theme.Space.s1)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [Theme.Palette.warning, Color(hex: 0xB56A00)],
                                   startPoint: .top, endPoint: .bottom))
            )
            .shadow(color: reducedMotion ? .clear : Theme.Palette.warning.opacity(0.6), radius: 14)
            .accessibilityLabel("Draw stack is now \(count) cards")
            .allowsHitTesting(false)
    }
}
