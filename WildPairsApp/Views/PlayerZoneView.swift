import SwiftUI
import WildPairsCore

// A non-local player's seat: name, fanned card backs, a count badge, and status badges
// (current turn, Solo!, Out!). When the seat owes a Solo! call the local player can tap to
// catch them for a penalty.

struct PlayerZoneView: View {
    let seat: PlayerSeatViewState
    var showColourName: Bool = false
    var showPattern: Bool = false
    var cardBackSize: CGSize = Theme.CardSize.opponentBack
    /// Size for the partner's face-up cards. CardView's corner/centre layout needs more
    /// room than a solid CardBackView does, so this must not reuse the tiny cardBackSize —
    /// at that size CardView's internal content overflows its frame and corrupts the
    /// enclosing VStack's layout (the name/badge row above silently fails to render).
    var openHandCardSize: CGSize = Theme.CardSize.partnerHand
    /// Maximum width the card fan may occupy before it must overlap more tightly (A6) —
    /// callers pass the seat's allotted slice of the table so the fan never clips.
    var maxFanWidth: CGFloat? = nil
    var reducedMotion: Bool = false
    var isThinking: Bool = false
    var thinkingDotCount: Int = 3
    /// Element-tinted chrome accent (design-plan.md §3.1): the active seat's ring and glow
    /// follow the table's current-colour scene rather than the fixed teal.
    var accent: Color = Theme.Palette.accent
    /// A transient feedback stamp for this seat (skip / forced draw) — Phase 17 C3. The parent
    /// sets it briefly and clears it, so it pops in and fades out.
    var cue: SeatCueKind? = nil
    var onCatchSolo: (() -> Void)? = nil

    /// Drives the active-player glow pulse (ux-spec.md §10 "Active player highlight": a
    /// soft glow that pulses on a ~2s period; static border instead under Reduced Motion).
    @State private var glowPulse = false
    /// One-shot scale pop when the turn lands on this seat — the per-seat half of the turn
    /// hand-off choreography (Phase 16), so the eye is drawn to whoever's go it now is.
    @State private var arrivalPop = false

    private var isOpponentAvatar: Bool { seat.visiblePartnerHand == nil }

    /// How close this seat is to going out — drives the count badge's urgency colour so
    /// "who's about to win" reads at a glance (1 card = critical, 2 = caution).
    private var countTint: Color {
        switch seat.handCount {
        case 0, 1: return Theme.Palette.error
        case 2:    return Theme.Palette.warning
        default:   return Theme.Palette.accent
        }
    }
    private var countUrgent: Bool { seat.handCount <= 2 }

    var body: some View {
        seatChrome
            .overlay(cueOverlay)
            .shadow(color: glowColor, radius: glowRadius)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: cue)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: seat.needsSoloCall)
            .onAppear { updateGlow(seat.isCurrentPlayer) }
            .onChange(of: seat.isCurrentPlayer) { _, isCurrent in
                updateGlow(isCurrent)
                if isCurrent { triggerArrivalPop() }
            }
            // `.combine` merges the whole zone into a single VoiceOver element, which would
            // otherwise swallow the catch-out button (it stops being independently reachable
            // by swipe navigation). Forward the same action to the combined element's double
            // tap instead, so catching a Solo! call still works for VoiceOver users.
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(catchSoloHint)
            .accessibilityAddTraits(canCatchSolo ? .isButton : [])
            .onTapGesture { if canCatchSolo { onCatchSolo?() } }
            .accessibilityIdentifier("seat-\(seat.seatPosition)")
    }

    /// Opponent avatars float on the scene (prototype 04); only the partner's open-hand
    /// panel gets the boxed glass surface — a box around a lone avatar read as dead weight.
    @ViewBuilder private var seatChrome: some View {
        if isOpponentAvatar {
            seatContent
        } else {
            seatContent
                .wpGlass(cornerRadius: Theme.Radius.r3, tint: seat.isCurrentPlayer ? accent : nil)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.r3)
                        .strokeBorder(seat.isCurrentPlayer ? accent : .clear, lineWidth: 2)
                )
        }
    }

    private var seatContent: some View {
        VStack(spacing: Theme.Space.s1) {
            if !isOpponentAvatar {
                HStack(spacing: Theme.Space.s2) {
                    Text(seat.name)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(seat.isCurrentPlayer ? accent : .secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    countBadge
                }
            }

            if isThinking {
                ThinkingDotsView(dotCount: thinkingDotCount, isStatic: reducedMotion)
            }

            if let partnerHand = seat.visiblePartnerHand {
                openHandFan(partnerHand)
            } else {
                opponentPile
                Text(seat.name)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(seat.isCurrentPlayer ? accent : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            statusBadges
        }
        .padding(Theme.Space.s2)
        .frame(maxWidth: maxFanWidth.map { $0 + Theme.Space.s2 * 2 })
    }

    /// The transient skip / forced-draw stamp (Phase 17 C3), centred over the seat.
    @ViewBuilder private var cueOverlay: some View {
        if let cue {
            Group {
                switch cue {
                case .skipped:
                    Text("SKIPPED")
                        .font(.caption).fontWeight(.heavy)
                        .foregroundStyle(Theme.Palette.onAccent)
                        .padding(.horizontal, Theme.Space.s2).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.Palette.warning))
                        .rotationEffect(.degrees(-8))
                case .drew(let n):
                    Text("+\(n)")
                        .font(.title3).fontWeight(.heavy).monospacedDigit()
                        .foregroundStyle(Theme.Palette.onAccent)
                        .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
                        .background(Capsule().fill(Theme.Palette.error))
                }
            }
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
            .transition(reducedMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
            .accessibilityHidden(true)
        }
    }

    private var glowColor: Color {
        guard seat.isCurrentPlayer else { return .clear }
        return accent.opacity(reducedMotion ? 0.45 : (glowPulse ? 0.85 : 0.35))
    }
    private var glowRadius: CGFloat {
        guard seat.isCurrentPlayer else { return 0 }
        return reducedMotion ? 6 : (glowPulse ? 18 : 8)
    }
    private func updateGlow(_ isCurrent: Bool) {
        guard isCurrent, !reducedMotion else { glowPulse = false; return }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }

    /// A quick scale pop when the turn arrives at this seat, then settle back.
    private func triggerArrivalPop() {
        guard !reducedMotion else { return }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.45)) { arrivalPop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { arrivalPop = false }
        }
    }

    private var canCatchSolo: Bool { seat.needsSoloCall && onCatchSolo != nil }
    private var catchSoloHint: String { canCatchSolo ? "Double tap to call them out" : "" }

    /// Solid teal chip (neon-final.html spec: `background:accent;color:onAccent`) for the
    /// partner's visible card count.
    private var countBadge: some View {
        Text("\(seat.handCount)")
            .font(.caption).fontWeight(.heavy).monospacedDigit()
            .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
            .foregroundStyle(Theme.Palette.onAccent)
            .background(Capsule().fill(countTint))
            .overlay(countUrgent ? Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1) : nil)
    }

    /// Width-aware overlap so a fan of `count` cards at `cardWidth` never exceeds
    /// `maxFanWidth` (falls back to the comfortable default overlap when there's room).
    private func fanStep(count: Int, cardWidth: CGFloat, comfortableOverlap: CGFloat) -> CGFloat {
        guard count > 1 else { return cardWidth }
        let comfortableStep = cardWidth - comfortableOverlap
        guard let maxWidth = maxFanWidth else { return comfortableStep }
        let comfortableTotal = cardWidth + comfortableStep * CGFloat(count - 1)
        if comfortableTotal <= maxWidth { return comfortableStep }
        let step = (maxWidth - cardWidth) / CGFloat(count - 1)
        return max(step, cardWidth * 0.15)
    }

    private var countChip: some View {
        Text("\(seat.handCount)")
            .font(.caption).fontWeight(.heavy).monospacedDigit()
            .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
            .background(Capsule().fill(countTint))
            .overlay(countUrgent ? Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1) : nil)
            .foregroundStyle(Theme.Palette.onAccent)
    }

    /// Opponent's hand as a stacked pile of card-backs whose footprint grows with the card
    /// count (Phase 17 C4), so "who's holding a lot" reads at a glance; the exact number stays
    /// on the count chip. The active seat / thinking state gets an accent ring + the arrival pop.
    private var opponentPile: some View {
        let visible = min(seat.handCount, 7)
        let stepX = cardBackSize.width * 0.09
        let stepY = cardBackSize.height * 0.05
        let pileWidth = cardBackSize.width + CGFloat(max(visible - 1, 0)) * stepX
        let pileHeight = cardBackSize.height + CGFloat(max(visible - 1, 0)) * stepY
        return ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .bottomLeading) {
                if visible == 0 {
                    // Out of the round — a faint empty slot; the "Out!" badge carries the state.
                    RoundedRectangle(cornerRadius: Theme.Radius.r2)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                        .frame(width: cardBackSize.width, height: cardBackSize.height)
                } else {
                    ForEach(0..<visible, id: \.self) { i in
                        CardBackView(size: cardBackSize)
                            .offset(x: CGFloat(i) * stepX, y: -CGFloat(i) * stepY)
                            .transition(reducedMotion ? .identity
                                        : .scale(scale: 0.6).combined(with: .opacity))
                    }
                }
            }
            .frame(width: pileWidth, height: pileHeight, alignment: .bottomLeading)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.r2)
                    .strokeBorder((seat.isCurrentPlayer || isThinking) ? accent : .clear, lineWidth: 2)
                    .padding(-3)
            )
            .shadow(color: (isThinking && !reducedMotion) ? accent.opacity(0.5) : .clear, radius: 10)

            countChip.offset(x: 8, y: 8)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: seat.handCount)
        .scaleEffect(arrivalPop ? 1.1 : 1)
    }

    /// Partner's hand, face-up — partner hands are open by design (game-rules.md Team
    /// Communication Rules). Not tappable: only the local player's own hand is playable.
    private func openHandFan(_ hand: [Card]) -> some View {
        let count = hand.count
        let step = fanStep(count: count, cardWidth: openHandCardSize.width, comfortableOverlap: openHandCardSize.width * 0.4)
        return ZStack(alignment: .leading) {
            if count == 0 {
                Color.clear.frame(width: openHandCardSize.width, height: openHandCardSize.height)
            } else {
                ForEach(Array(hand.enumerated()), id: \.element.id) { index, card in
                    CardView(card: card, size: openHandCardSize, showColourName: showColourName,
                             showPattern: showPattern, reducedMotion: reducedMotion)
                        .offset(x: CGFloat(index) * step)
                        .transition(reducedMotion ? .identity : .scale(scale: 0.5).combined(with: .opacity))
                }
            }
        }
        // Leading-anchored for the same `.offset(x:)` layout reason as the backs fan above.
        .frame(width: count > 0 ? openHandCardSize.width + step * CGFloat(count - 1) : openHandCardSize.width,
               height: openHandCardSize.height, alignment: .leading)
    }

    @ViewBuilder private var statusBadges: some View {
        if seat.hasFinishedRound {
            badge("Out!", system: "checkmark.circle.fill", tint: Theme.Palette.success)
        } else if seat.needsSoloCall {
            Button { onCatchSolo?() } label: {
                badge("Solo?", system: "exclamationmark.circle.fill", tint: Theme.Palette.warning)
            }
            .buttonStyle(.plain)
            .disabled(onCatchSolo == nil)
            // ux-spec.md §10 "Solo! call": badge pops in via a spring scale (skipped under
            // Reduced Motion, where it should simply appear).
            .transition(reducedMotion ? .identity : .scale(scale: 0.3).combined(with: .opacity))
        }
    }

    private func badge(_ text: String, system: String, tint: Color) -> some View {
        Label(text, systemImage: system)
            .font(.caption2).fontWeight(.semibold)
            .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
            .background(Capsule().fill(tint.opacity(0.2)))
            .foregroundStyle(tint)
    }

    private var accessibilityLabel: String {
        var parts = ["\(seat.name), \(seat.handCount) cards"]
        if let partnerHand = seat.visiblePartnerHand, !partnerHand.isEmpty {
            parts.append("your partner, hand visible: \(partnerHandSummary(partnerHand))")
        }
        if seat.isCurrentPlayer { parts.append("their turn") }
        if seat.hasFinishedRound { parts.append("out of the round") }
        else if seat.needsSoloCall { parts.append("has one card and has not called Solo") }
        return parts.joined(separator: ", ")
    }

    private func partnerHandSummary(_ hand: [Card]) -> String {
        hand.map { card -> String in
            let colour = card.colour?.displayName ?? "Wild"
            if case .number(let v) = card.type { return "\(colour) \(v)" }
            return "\(colour) \(card.type.abbreviation)"
        }.joined(separator: ", ")
    }
}
