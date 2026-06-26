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
    var openHandCardSize: CGSize = Theme.CardSize.compactHand
    var reducedMotion: Bool = false
    var isThinking: Bool = false
    var thinkingDotCount: Int = 3
    var onCatchSolo: (() -> Void)? = nil

    /// Drives the active-player glow pulse (ux-spec.md §10 "Active player highlight": a
    /// soft glow that pulses on a ~2s period; static border instead under Reduced Motion).
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: Theme.Space.s1) {
            HStack(spacing: Theme.Space.s2) {
                Text(seat.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(seat.isCurrentPlayer ? Theme.Palette.accent : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                countBadge
            }

            if isThinking {
                ThinkingDotsView(dotCount: thinkingDotCount, isStatic: reducedMotion)
            }

            if let partnerHand = seat.visiblePartnerHand {
                openHandFan(partnerHand)
            } else {
                backsFan
            }

            statusBadges
        }
        .padding(Theme.Space.s2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .fill(Theme.Palette.surface)
                .opacity(seat.isCurrentPlayer ? 1 : 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.r3)
                .strokeBorder(Theme.Palette.accent, lineWidth: seat.isCurrentPlayer ? 2 : 0)
        )
        .shadow(color: glowColor, radius: glowRadius)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: seat.needsSoloCall)
        .onAppear { updateGlow(seat.isCurrentPlayer) }
        .onChange(of: seat.isCurrentPlayer) { _, isCurrent in updateGlow(isCurrent) }
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

    private var glowColor: Color {
        guard seat.isCurrentPlayer else { return .clear }
        return Theme.Palette.accent.opacity(reducedMotion ? 0.3 : (glowPulse ? 0.6 : 0.15))
    }
    private var glowRadius: CGFloat {
        guard seat.isCurrentPlayer else { return 0 }
        return reducedMotion ? 4 : (glowPulse ? 10 : 4)
    }
    private func updateGlow(_ isCurrent: Bool) {
        guard isCurrent, !reducedMotion else { glowPulse = false; return }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
    }

    private var canCatchSolo: Bool { seat.needsSoloCall && onCatchSolo != nil }
    private var catchSoloHint: String { canCatchSolo ? "Double tap to call them out" : "" }

    private var countBadge: some View {
        Text("\(seat.handCount)")
            .font(.caption).fontWeight(.bold).monospacedDigit()
            .padding(.horizontal, Theme.Space.s2).padding(.vertical, 2)
            .background(Capsule().fill(Theme.Palette.accent.opacity(0.15)))
    }

    private var backsFan: some View {
        HStack(spacing: -cardBackSize.width * 0.55) {
            ForEach(0..<min(seat.handCount, 5), id: \.self) { _ in
                CardBackView(size: cardBackSize)
            }
            if seat.handCount == 0 {
                Color.clear.frame(width: cardBackSize.width, height: cardBackSize.height)
            }
        }
    }

    /// Partner's hand, face-up — partner hands are open by design (game-rules.md Team
    /// Communication Rules). Not tappable: only the local player's own hand is playable.
    private func openHandFan(_ hand: [Card]) -> some View {
        HStack(spacing: -openHandCardSize.width * 0.4) {
            ForEach(hand) { card in
                CardView(card: card, size: openHandCardSize, showColourName: showColourName,
                         showPattern: showPattern)
            }
            if hand.isEmpty {
                Color.clear.frame(width: openHandCardSize.width, height: openHandCardSize.height)
            }
        }
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
